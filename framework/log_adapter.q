.boot.include (gdrive_root, "/framework/rexec.q");

.sp.lg_adptr.output: {[lvl;msg]
    if[.sp.log.level_map[lvl] <= .sp.log.level_map[`warn];
	`.sp.lg_adptr.msgs insert ( `$ raze string upper lvl;  enlist raze string msg) ];
  };

.sp.lg_adptr.logpub:{ [l;m]
    m:raze m;
    st:(first m ss "[") + 1;
    ed:(first m ss "]");
    fn:`$"NA";
    if[ st < ed; fn:`$m st + til ed-st];
    sn:`$first (.Q.opt .z.x)[`svc_name];
    data:(.z.T; sn; `$m; l; fn; .z.D);
    .sp.re.exec[ `LOGS_TP; `; (`.sp.tp.upd; `backend; data); .sp.consts[`DEF_EXEC_TO] ];
  };

.sp.lg_adptr.on_timer:{ [i;t]
    { .sp.lg_adptr.logpub[ x[`level]; x[`msg] ] } @/: .sp.lg_adptr.msgs;
    .sp.lg_adptr.msgs::0#.sp.lg_adptr.msgs; 
  };

.sp.lg_adptr.on_comp_start:{[]
    func : "[.sp.lg_adptr.on_comp_start] : ";
    .sp.lg_adptr.msgs::([] level:(); msg:() ); // bucket to hold log messages to go to LOG_TP
    .sp.cron.add_timer [5000; -1; .sp.lg_adptr.on_timer]; // every half a second, see if there are any msgs to publish
    -1 func, "component ready...";
    .sp.log.pub_external::.sp.lg_adptr.output; // This func will get called from logging.q
    :1b;
  };

.sp.comp.register_component[`lg_adptr;`cron`rexec`log;.sp.lg_adptr.on_comp_start];

