.boot.include (gdrive_root, "/framework/core.q");
.boot.include (gdrive_root, "/framework/rexec.q");

.sp.sub.log_discovery_data:{ [ rec] 
	{ [k_; v_] : .sp.log.debug "[.sp.sub.log_discovery_data] : column = ", (string k_), " and value = ", (string first v_) }'[key flip rec; value flip rec];
  };
  
.sp.sub.subscribe:{ [svc_; inst_; topic_; params_]
	func: "[.sp.sub.subscribe] : ";
	.sp.log.debug func, " svc = ", (string svc_), " inst = ", ($[null inst_; "null"; string inst_]), " topic = ", (string topic_);
	
	if[ 0b = 99h = type params_; .sp.exception func, "Invalid params passed"];
	if[ 0b = all -11h = type each (svc_; inst_; topic_); .sp.exception func, "Invalid arg type passed"];
	
	ct : $[null inst_; (exec count i from .sp.sub.services where svc = svc_, topic = topic_);
		(exec count i from .sp.sub.services where svc = svc_, topic = topic_, inst = inst_) ];
	.sp.log.debug func, "num of rows matched to this svc = ", (string svc_), " = ", (string ct);
	if[ 0 < ct;
		.sp.log.info func, "There is already an existing subscription to svc [", (string svc_), "] inst [", (string inst_), "] and topic [", (string topic_), "]";
		:0 ];
		
	disco: $[ null inst_; .sp.ns.client.discover_next[svc_];  .sp.ns.client.discover[.sp.ns.client.zone; svc_; `inst; inst_] ];
	if[ (count disco) = 0; msg : func, "No service discovered from nameserver for svc ", (string svc_); .sp.exception msg ];
	
	inst : first disco [`inst]; 
	zone : first disco [`zone];
	h:.sp.re.get_handle[zone; svc_; inst; .sp.sub.connection_to];
	
	if[ 0h = h; .sp.exception func, "Failed to discover the service ", (string svc_), " on host ", (string (first disco[`address])), " and port ", (string (first disco[`port]))];
	
	.sp.log.debug func, "We successfully discovered the service ", (string svc_);
	.sp.sub.log_discovery_data[disco];
	
	params_:.sp.sub.get_def_sub_params[],params_;
	sub_id : `$(string .sp.ns.client.svc_name), ":", (string .sp.ns.client.inst), ":", (.sp.io.inport);
	res : .sp.io.sync[h; (`.sp.pub.on_subscribe; sub_id; topic_; params_)];
	if[ not (type res) in (98h; 99h); 
		if[ res <> .sp.const.OK; .sp.exception func, "Failed to subscribe to remote service ", (string svc_)] ];
 
	`.sp.sub.services insert (zone; svc_; inst; topic_; h; params_[`recovery_callback]; params_[`update_callback]; params_[`recovery_filter]; params_[`update_filter];  params_[`update_filter_params]; params_[`recovery_filter_params]; params_[`recovery_complete_callback]);

	.sp.log.info func, "Subscription successful. svc : ", (string svc_), " inst ", (string inst_), " topic ", (string topic_);
	
	if[(type res) in (98h; 99h); .sp.log.debug func, "schema of the table returned."; show meta res; :res];
	:.sp.consts[`OK];
  };
  
.sp.sub.unsubscribe:{ [svc_; topic_]
    func: "[.sp.sub.unsubscribe] : " ;  
	.sp.log.debug func, "Will unsubscribe from svc ", (string svc_), " and topic ", (string topic_);
	hdl : first exec handle from `.sp.sub.services where svc = svc_, topic = topic_;
	if [ null hdl; 
		msg : func, "No match founs for service ", (string svc_), " and topic ", (string topic_);
		.sp.log.error msg;
		.sp.exception msg ];
	
	.sp.io.async[hdl; (`.sp.pub.on_unsubscribe; topic_)];
	.sp.io.close_port[hdl];
	
	delete from `.sp.sub.services where svc = svc_, topic = topic_;
	ct : exec count handle from .sp.sub.services where svc = svc_, handle = hdl;
	
	if[ct = 0; .sp.re.remove_connections[hdl] ];
	
	.sp.log.info func, "unsubscribe from svc ", (string svc_), " and topic ", (string topic_), " completed";
  };

.sp.sub.publisher_handle_event: { [hdl_; event_]
	func : "[.sp.sub.publisher_handle_event] : ";
	.sp.log.debug func, "handle : ", (string hdl_), " and event type : ", (string event_);
	
	if[ event_ <> `close; .sp.log.debug func, "This is NOT a close event. Do Nothing"; :0 ];
	.sp.re.remove_connections[hdl_];
	
	svc : 0!select from .sp.sub.services where handle = hdl_;
	if[ (count svc) = 0;
		.sp.log.info func, "There is NO subscription on this handle : ", (string hdl_), ". So no re-subscription";
		:0 ] ;
	.sp.log.info func, "Publisher went down. Service : ", (string first svc[`svc]);
	
	svcs: 0!select svc, topic, handle from .sp.sub.services where handle = hdl_;
	{[svc_; topic_; hdl_]
		func : "[.sp.sub.publisher_handle_event] : ";
		.sp.ns.client.wait_for_ever[svc_; `];
		
		params: exec first recovery_callback, first update_filter, first update_callback, first recovery_filter, first update_filter_params, first recovery_filter_params, first recovery_complete_callback from .sp.sub.services where handle = hdl_, topic = topic_;
		.sp.sub.unsubscribe[svc_; topic_];
		.sp.log.debug func, "un Subscribe complete. Will re-subscribe to svc ", (string svc_), " and topic ", (string topic_), " with same params";
		
		ret : -1i;
		while [ ret = -1i;
            ret:.sp.sub.subscribe[svc_; `; topic_; params];
			//ret: .[.sp.sub.subscribe; (svc_; `; topic_; params); { .sp.log.error "[.sp.sub.publisher_handle_event] : .sp.sub.subscribe failed due to :- ", x; :-1i}];
			if[ -6h = type ret;
				if[ ret = -1i;
					.sp.log.error func, "Failed to resubscribe to svc ", (string svc_), " for topic ", (string topic_), ". Will try again";
					.sp.ns.client.sleep[.sp.consts[`DEF_SLEEP_PERIOD] ] ] ];
				if[ -6h <> type ret; .sp.log.info func, "Successfully re-subscribed to svc ", (string svc_), " for topic ", (string topic_); ret:0i];
			];
		}[;] ./: (flip value flip svcs);
		:0;
	};

.sp.sub.get_def_sub_params:{ []
	def_cb: {[t; d] };
	def_rec_fltr : { [t;p] :value t };
	def_upd_fltr : { [d;p] :d };
	def_fltr_parms: enlist `;	
        def_rec_complete_cb: {[t] };	
	def_dict:`recovery_callback`update_callback`recovery_filter`update_filter`update_filter_params`recovery_filter_params`recovery_complete_callback ! (def_cb; def_cb; def_rec_fltr; def_upd_fltr; def_fltr_parms;def_fltr_parms;def_rec_complete_cb);
	:def_dict
  };
  
.sp.sub.on_comp_start:{ []
	func:"[.sp.sub.on_comp_start] : ";
	.sp.sub.connection_to :: "I"$.sp.arg.optional[`connection_timeout; .sp.consts[`DEF_OPEN_PORT_TO] ];
	.sp.io.add_con_event_handler[.sp.sub.publisher_handle_event; 0];
	/.sp.sub.services::([zone:`$(); svc:`$(); inst:`$(); topic:`$(); handle:`int$()] recovery_callback:(); update_callback:(); recovery_filter:(); update_filter:(); filter_params:() );
    .sp.sub.services::([zone:(),`test; svc:(),`test; inst:(),`0; topic:(),`test; handle:(),-1i] recovery_callback: (),{[t;d] :d}; update_callback: (),{[t;d] :d}; recovery_filter:(),{[topic_] :value topic_}; update_filter:(),{[d;p] :d};update_filter_params:enlist (),`test1;recovery_filter_params:enlist (),`test1; recovery_complete_callback: (),{[t] });
	.sp.log.info func, "component sub is ready";
	:1b
  };
  
.sp.comp.register_component[`sub; `core`rexec; .sp.sub.on_comp_start];
  
		
		
		
		
	
	
