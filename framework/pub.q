.boot.include (gdrive_root, "/framework/core.q");

.sp.pub.publish: { [topic_; data_]
	func : "[.sp.pub.publish] : ";
	clients : select from .sp.pub.clients where topic = topic_;
	if[ 0 >= count clients; .sp.log.spam func, "No clients subscribed for topic ", (string topic_), ". Nothing published out."; :0 ];
	if[ not (type data_) in (98h; 99h);
	  if[ topic_ in tables `.; data_: (0#(value topic_)) upsert data_ ] ];

	res : raze { [topic_; data_; handle_; upd_callback_; upd_filter_; update_filter_params_ ]
		func:"[.pub.publish] : ";
		if [ 0 < type upd_callback_;  upd_callback_:first upd_callback_];

		// run the upd filter now
		if[ (type data_) in (98h; 99h);
			result: .[upd_filter_; (data_; update_filter_params_); -1i];
			if[ -6h = type result; .sp.log.error func, "update filter not good for topic: ", (string topic_), " on handle ", (string handle_);
				.sp.log.error func, "update-filter defined as : ", (string upd_filter_); :((enlist handle_)!(enlist (0)))];

			if[ 0 >= (count result); .sp.log.debug func, "No data returned for topic ", (string topic_), " after data passed thru the filter func";
				.sp.log.debug func, "filter params passed are :";
				.sp.log.debug each (string update_filter_params_);
				:((enlist handle_)!(enlist (0))) ]
			];

			if[ not (type data_) in (98h; 99h); result:data_]; // if not a table, publish whatever we got

			.sp.io.async[handle_; (upd_callback_; topic_; result)];
			.sp.log.spam func, "Published ", (string (count result)), " rows of data on topic ", (string topic_), " on handle ", (string handle_);
			:((enlist handle_)!(enlist (count result)));
			} [ topic_; data_; ;;;] ./: (flip value flip (select handle, update_callback, update_filter, update_filter_params from clients) );
	:res;
  };

.sp.pub.on_upd_filter_param:{ [topic_; update_filter_params_]
	func:"[.sp.pub.on_upd_filter_param] : ";

	.sp.log.spam each (func ,/: (string  each  update_filter_params_));
	if[0b = all -11h = type each (topic_); .sp.exception func, "Invalid arg type for topic passed. Must be a sym"];
	hdl:.z.w;
	.sp.log.debug func, "topic = ", (string topic_), " hdl = ", (string hdl);
	update update_filter_params:enlist update_filter_params_ from .sp.pub.clients where topic = topic_, handle = hdl;
	.sp.log.debug func, "Updated the filter params for topic ", (string topic_);
  };


.sp.pub.on_subscribe:{ [sub_id_; topic_; params_]
	func:"[.sp.pub.on_subscribe] : ";

	h : .z.w;
	.sp.log.debug func, "topic = ", (string topic_), " on handle ", (string h);
	if[ 0b = 99h = type params_; .sp.exception func, "Invalid params passed. Must be a dictionary with all required fields"];
	if[ 0b = -11h = type topic_; .sp.exception func, "Invalid arg type for topic passsed. Topic must be a symbol"];

	// update the client table
	if[ 0 < (exec count i from .sp.pub.clients where handle = h, topic = topic_);
		.sp.log.warn func, "Client with handle ", (string h), " already subscribed to topic ", (string topic_);
		.sp.exception func, "You are already subscribed to this topic ", (string topic_) ];

	// if the update filter and recovery filter are strings, convert to func and store them so they can be invoked later
	rec_fltr:params_[`recovery_filter];
	if[ not (type rec_fltr) in (10h; 100h); msg:func, "Invalid recovery filter passed. It must be a func that takes one arg."; .sp.exception msg ];
    if[ 10h = type rec_fltr; rec_fltr:value rec_fltr];

	upd_fltr:params_[`update_filter];
	if[ not (type upd_fltr) in (10h; 100h); msg:func, "Invalid update filter passed. It must be a func that takes two args."; .sp.exception msg ];
    if[ 10h = type upd_fltr; upd_fltr:value upd_fltr];

	rec_cb : params_[`recovery_callback];
	upd_cb : params_[`update_callback];
        rec_complete_cb: params_[`recovery_complete_callback];

	host:.Q.host .z.a;
	`.sp.pub.clients insert ( sub_id_; topic_; h; host; rec_cb; upd_cb; rec_fltr; upd_fltr; (),params_[`update_filter_params];params_[`recovery_filter_params]; rec_complete_cb);


	.sp.pub.pending_recovery[topic_]:h;
	.sp.cron.add_timer[10;1; .sp.pub.do_recovery_callbacks];
	.sp.log.debug func, "successfully subscribed to topic: ", (string topic_), " on handle ", (string h);

	if[ topic_ in tables `.;  :0# (value topic_)];
	:.sp.consts[`OK];
  };

.sp.pub.subscriber_handle_event:{ [hdl_; event_]
    func:"[.sp.pub.subscriber_handle_event] : ";
	.sp.log.debug func, "handle = ", (string hdl_), " and event type = ", (string event_);
	if[event_ <> `close; .sp.log.debug func, "This is NOT a close event. Nothing to be done"; :0];
	delete from `.sp.pub.clients where handle = hdl_;
  };

.sp.pub.on_unsubscribe:{ [topic_]
    func:"[.sp.pub.on_unsubscribe] : ";
	h: .z.w;
	.sp.log.debug func, "topic : ", (string topic_), " on handle ", (string h);
	delete from `.sp.pub.clients where topic=topic_, handle = h;
  };

.sp.pub.do_recovery_callbacks:{ [id_; tm_]
	func: "[.sp.pub.do_recovery_callbacks] : ";
	topics:where not null .sp.pub.pending_recovery;
	hdls:.sp.pub.pending_recovery where not null .sp.pub.pending_recovery;
	.sp.pub.make_recovery_callbacks ' [topics; hdls];
	.sp.pub.pending_recovery::0#.sp.pub.pending_recovery;
  };

.sp.pub.make_recovery_callbacks:{ [topic_; hdl_]
	func:"[.sp.pub.make_recovery_callbacks] : ";
	rec_func : first ( exec recovery_callback from .sp.pub.clients where topic = topic_, handle = hdl_);
	rec_fltr : first ( exec recovery_filter from .sp.pub.clients where topic = topic_, handle = hdl_);
    rec_params: first (exec recovery_filter_params from .sp.pub.clients where topic = topic_, handle = hdl_);
    rec_complete_cb: first (exec recovery_complete_callback from .sp.pub.clients where topic = topic_, handle = hdl_);

	data: .[rec_fltr; (topic_;rec_params); -1i];
	if[ -6h = type data; .sp.log.error func, "recovery filter not good for topic ", (string topic_), " on handle ", (string hdl_);
		.sp.log.error func, "recovery filter: ", (string rec_fltr); :0 ];

	if[ ( (type data) in (98h; 99h) ) and ((count data) > 0 );
		if[ 0 < type rec_func; rec_func:first rec_func];
		.sp.io.async[hdl_; (rec_func; topic_; data)];
		.sp.log.debug func, "recovery func called on handle ", (string hdl_), " on topic ", (string topic_), " row count = ", (string (count data));
                .sp.io.async[hdl_; (rec_complete_cb; topic_)];
		: 0;
		];

        .sp.io.async[hdl_; (rec_complete_cb; topic_)];
	.sp.log.debug func, "No data sent on handle ", (string hdl_), " on topic ", (string topic_), ". No data from rec filter!";
  };

.sp.pub.on_comp_start: { []
	func : "[.sp.pub.on_comp_start] : " ;
	.sp.pub.pending_recovery :: 0#(enlist `)!(enlist 0N);

	.sp.io.add_con_event_handler[.sp.pub.subscriber_handle_event; 0];
/	.sp.pub.clients:: ([sub_id:`$(); topic: `$(); handle: `int$()] host:`$(); recovery_callback:(); update_callback:(); recovery_filter:(); update_filter:(); filter_params:() );
    .sp.pub.clients::([sub_id:(),`test; topic:(),`test; handle:(),0i] host:(),`test; recovery_callback: (),{[t;d] :d}; update_callback: (),{[t;d] :d}; recovery_filter:(),{[topic_] :value topic_}; update_filter:(),{[d;p] :d};update_filter_params:enlist (),`test1;recovery_filter_params:enlist (),`test1; recovery_complete_callback: (), {[t] });

	.sp.log.info func, "component pub is ready";
	:1b;
  };

.sp.comp.register_component[`pub; enlist `core; .sp.pub.on_comp_start];






