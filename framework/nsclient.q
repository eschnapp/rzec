.sp.ns.client.connect: { [host_]
	func: "[.sp.ns.client.connect] : " ;
	if[ -11h <> (type .sp.io.inport); in_port : `$.sp.io.inport ];
	.sp.log.info func, "connecting to nameserver ", (string host_);
	client_hdl : .[.sp.io.open_port; (host_; .sp.ns.client.timeout); {.sp.log.error "[.sp.ns.client.connect] open_port failed!"; :0h } ];
	if[not 0h < client_hdl;
		.sp.ns.nameservers[host_]:0i;
		.sp.log.warn func, "Unable to open connection to nameserver ", (string host_); :-1 ];
	.sp.log.info func, "Opened a port successfully to nameserver ", (string host_), " and handle = ", (string client_hdl);
	.sp.log.info func, "Announcing identity (", (raze string .sp.ns.client.svc_name), ")";
	args : (client_hdl; (`.sp.ns.server.announce; .sp.ns.client.zone; .sp.ns.client.svc_name; .sp.ns.client.inst; in_port; `q));

	r: .[.sp.io.sync; args; { [x;h] .sp.log.error ".sp.io.sync failed due to : - ", x, " on host ", (string h); :-1i }[; host_] ];

	if[ -6h = type r;
		if[ r = -1i; .sp.log.error func, "Announce failed to nameserver ", (string host_);
			.sp.ns.nameservers[host_]:0i; :-1i; ] ];
	.sp.log.info func, "Announce successful to nameserver ", (string host_), ". Will start HB timer now";
	if[ null .sp.ns.client.hb_timer_id;
		.sp.ns.client.hb_timer_id:: .sp.cron.add_timer[ .sp.ns.client.hb_ival; -1; {[id_; tm_] .sp.ns.client.hb[]}];
			.sp.log.debug func, "heart beat function added to cron" ];
	.sp.ns.nameservers[host_]:client_hdl;
	:client_hdl;
  };

.sp.ns.client.close: { []
	func: "[.sp.ns.client.close] : ";
	if[ 0b = null .sp.ns.client.hb_timer_id;
		.sp.log.info func, "Shutting down the heartbeat timer";
		.sp.cron.remove_timer[.sp.ns.client.hb_timer_id] ];
	.sp.log.info func, "Closing connection to nameservers...";
	{[hdl_] if[ 0h <> hdl_; .sp.io.close_port[hdl_]] } each value .sp.ns.nameservers;
  };

.sp.ns.client.hb:{ []
    func: "[.sp.ns.client.hb] : ";
    if[ not .sp.comp.all_comps_ready[]; .sp.log.info func, "Not all comps ready yet. Not ready comps are: "; show select from .sp.comp,get_all_components[] where started = 0b; :0 ];
    //show .sp.ns.nameservers;
    ret:.sp.ns.client.hb_if_good_hdl'[key .sp.ns.nameservers; value .sp.ns.nameservers];
    // if [ all ret = -1; msg:func, "No good nameservers found. Exiting!"; .sp.critical msg ];
 };

.sp.ns.client.hb_if_good_hdl:{ [host_; hdl_]
	func:"[.sp.ns.client.hb_if_good_hdl] : ";
	if[ (null hdl_) and (null host_); .sp.log.warn func, "both host and handle are nulls. Nothing to connect to!"; :0 ];
	if[ null host_; .sp.log.warn func, "null host passed. Nothing to connect to!"; :0];
	if[ 0h = hdl_;
		.sp.log.warn func, "Bad handle, will try to reconnect to nameserver : ", (string host_);
		.sp.ns.client.connect host_; // try reconnecting to the name server
		];
	if[ 0h <> hdl_; .sp.io.async[hdl_; (`.sp.ns.server.hb_client; string (.sp.ns.client.svc_name))] ];
    :0;
  };

.sp.ns.client.discover_next : { [svc_]
	: .sp.ns.client.discover[.sp.ns.client.zone; svc_; .sp.ns.client.policy; `] };

.sp.ns.client.discover: { [zone_; svc_; policy_; params_]
    func:"[.sp.ns.client.discover] :";
    t:([]ns:key .sp.ns.nameservers; hdl:value .sp.ns.nameservers); // make a table
    hdl: first exec hdl from t where hdl > 0, not null ns; // remove nameservers which are down.. handle will be 0h
    if[null hdl; .sp.log.warn func, "Invalid handle for nameserver detected. NameServer is down. Can NOT do discovery."; :-1h];
	: .sp.io.sync[hdl; (`.sp.ns.server.discover; zone_; svc_; policy_; params_)] };

.sp.ns.client.wait_for_svc:{ [svc_; inst_; timeout_; intvl_]
	func:"[.sp.ns.client.wait_for_svc] ";
	max_sleeps: ceiling timeout_ % intvl_;
	do [ max_sleeps;
		disco : $[ null inst_; .sp.ns.client.discover_next[svc_]; .sp.ns.client.discover[.sp.ns.client.zone; svc_; `inst; inst_] ];
        if[ -5h = type disco; :0b ];
		disco : select from disco where not null svc;
		$[ (count disco) > 0;
			[:1b];
			[.sp.log.debug func, "service ", (string svc_), ":", (string inst_), " NOT available.";
				@[.sp.ns.client.sleep; intvl_; -1] ] ] ];
	:0b;
  };

.sp.ns.client.wait_for_ever:{ [svc_; inst_]
	func:"[.sp.ns.client.wait_for_ever] : ";
	not_found : 1;
	while [ not_found;
		disco: $[null inst_; .sp.ns.client.discover_next[svc_]; .sp.ns.client.discover[.sp.ns.client.zone; svc_; `inst; inst_] ];
        if[ -5h = type disco; msg: func, "No valid nameservers found to do discovery."; .sp.exception msg ];
		disco:select from disco where not null svc;
		$[ (count disco) > 0;
			[:1b];
			[.sp.log.debug func, "Service ", (string svc_), ":", (string inst_), " NOT available.";
				@[.sp.ns.client.sleep; .sp.consts[`DEF_SLEEP_PERIOD]; -1] ] ] ];
  };

.sp.ns.client.sleep:{ [millisecs_]
	.sp.log.debug "Sleeping for ", (string millisecs_), " milliseconds...";
	system "sleep ", (string (millisecs_%1000)); };

.sp.ns.client.discover_all:{[svc_]
	.sp.ns.client.discover[.sp.ns.client.zone; svc_; `all; `] };

.sp.ns.client.on_ns_change: { [hdl_; event_]
	func: "[.sp.ns.client.on_ns_change] : ";
	.sp.log.debug func, "got a notification on nameserver handle ", (string hdl_), " and event = ", (string event_);
	if[event_ = `close;
		rem_ns : .sp.ns.nameservers ? hdl_;
		if[ not null rem_ns; .sp.ns.nameservers[rem_ns] : 0i ];
		.sp.log.info func, "NameServer DOWN! Will stop heart beating to nameserver ", (string rem_ns), " with hdl = ", (string hdl_) ];
  };

.sp.ns.client.on_comp_start:{ []
    func:"[.sp.ns.client.on_comp_start] : ";
	.sp.ns.client.timeout :: "I"$.sp.arg.optional[`ns_timeout; 10000];
	.sp.ns.client.hb_ival :: "I"$.sp.arg.optional[`ns_hb_ival; 5000];
	.sp.ns.client.svc_name :: `$.sp.arg.required[`svc_name];
	.sp.ns.client.ns_hosts :: .sp.arg.required[`nameservers];
	.sp.ns.client.policy :: `$.sp.arg.optional[`ns_policy; "fifo"];
	.sp.ns.client.zone :: `$.sp.arg.required[`zone];
	.sp.ns.client.inst :: `$.sp.arg.optional[`instance; "0"];
	.sp.ns.client.hb_timer_id :: 0N;
	.sp.ns.client.handle :: 0h;
	.sp.ns.client.host :: "";

	.sp.log.info func, "Starting nameserver client... ";
	.sp.ns.client.ns_hosts:"," vs .sp.ns.client.ns_hosts;
	.sp.ns.nameservers::()!();
	.sp.ns.client.connect each `$.sp.ns.client.ns_hosts;

	if[ (count where 0<value .sp.ns.nameservers) = 0;
		.sp.exception func, "Unable to open connection to any  of the supplied nameservers! Auto Terminate!" ];
	.sp.log.debug func, "Number of nameservers connected to = ", (string (count where 0 < value .sp.ns.nameservers));

	{ [hdl_] .sp.io.add_con_event_handler[.sp.ns.client.on_ns_change; hdl_] } each ( (value .sp.ns.nameservers) where not null value .sp.ns.nameservers);
	.sp.log.info func, "NSCLIENT is ready now";
	:1b;
  };

.sp.comp.register_component[`nsclient; `core; .sp.ns.client.on_comp_start];




