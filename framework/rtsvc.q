.boot.include (gdrive_root, "/framework/rt.q");


.sp.rtsvc.load_config:{[] // load params from cfg lib 
    func:"[.sp.rtsvc.load_config] : "; 
    .sp.log.info func,"Loading configuration parameters ... "; 
    .sp.log.info func, "configurations loaded successfully ... "; 
  } ; 
  
load_new_rules:{ [] .sp.cron.add_timer[ 1000; 1; { [id_;tm_] .sp.rtsvc.load_rules[]; }]; }; 

.sp.rtsvc.load_rules: {[] 
    func: "[.sp.rtsvc.load_rules] : "; 
    .sp.rtsvc.rules_svc : .sp.alias.get_svc[`rules_svc]; 
    // wait for the rules svc to come up. if not found, no rules 
    present : .[.sp.ns.client.wait_for_svc; (.sp.rtsvc.rules_svc; `; 5000; 1000); 0b] ;
    if[ not present; .sp.log.info func, "No" (string .sp.rtsvc.rules_svc), " found. So NO rules this session"; :0]; 
    
    // get the rules from rules svc if any to override upd_modify and schema_modify funcs 
    cmd: (`.sp.rules.get_rules; .sp.ns.client.zone; .sp.cfg.current_service_name; `; `upd_modify; `); 
    r:. [.sp.rexec.exec; (.sp.rtsvc.rules_svc; `; cmd; .sp.consts[`DEF_EXEC_TO]); -1] ; 
    if[ (type r) in (98h; 99h); upd_modify::exec rules from r]; 
    
    cmd: (`.sp.rules.get_rules; .sp.ns.client.zone; .sp.cfg.current_service_name; `; `schema_modify; `); 
    r: . [.sp.rexec.exec; (.sp.rtsvc.rules_svc; `; cmd; .sp.consts[`DEF_EXEC_TO]); -1] ; 
    if[ (type r) in (98h; 99h); schema_modify::exec rules from r]; 
  } ; 
  
.sp.rtsvc.on_comp_start: {[] 
    func : "[.sp.rtsvc.on_comp_start] : "; 
    // tp svc name and inst are required arguments for rt svc 
    .sp.rtsvc.tp_svc::.sp.arg.required[`tpsvc]; 
    .sp.rtsvc.tp_inst::$[.sp.arg.is_present `tpinst; .sp.arg.required[`tpinst]; (), "0"] ; 
    .sp.rtsvc.hdb_path::$[.sp.arg.is_present `hdbpath; .sp.arg.required[`hdbpath]; (), ""] ; 
    
    .sp.rtsvc.hist_svc_name::`$($[.sp.arg.is_present `histsvc; .sp.arg.required[`histsvc]; ""]); 
    .sp.rtsvc.hist_svc_inst::`$($[.sp.arg.is_present `histinst;.sp.arg.required[`histinst]; ""]); 
    .sp.rtsvc.save_to_hdb_at:: "T"$.sp.arg.optional[`save_to_hdb; 23:50]; // will save rt to hist db at this time 
    
    if[ ""~ .sp.rtsvc.tp_svc; .sp.exception func, "Invalid args: tpsvc arg can not be empty";]; 
    if[ ""~ .sp.rtsvc.tp_inst; .sp.log.info func, "tpinst arg is empty. will try looking for tpsvc with accessible txn logs";]; 
   / if[ ""~ .sp.rtsvc.hdb_path; .sp.exception func, "Invalid args: hdbpath arg can not be empty";]; 
    // log all the variables 
    {func : "[.sp.rtsvc.on_comp_start] : "; xx: `$(".sp.rtsvc."),(string x); a:value xx; if[10h <> type a; a:string a]; .sp.log.debug func,(string x)," =" a; } each system "v .sp.rtsvc"; 
    
    .sp.cfg.set_change_callback_list .sp.rtsvc.load_config; 
    .sp.rtsvc.load_config[]; 
    
/    .sp.rtsvc.load_rules[]; 
    .sp.rt.setup[.sp.rtsvc.tp_svc; .sp.rtsvc.tp_inst; .sp.rtsvc.hdb_path]; 
    
    if[ .sp.arg.is_present `histsvc; 
        .sp.rt.set_hist_svc[.sp.rtsvc.hist_svc_name; .sp.rtsvc.hist_svc_inst]; 
        .sp.rt.save_to_hdb_at[.sp.rtsvc.save_to_hdb_at] ];
    .sp.log.info func, "rtsvc is ready now."; 
    :1b; 
  }; 
  
.sp.comp.register_component[`rtsvc; `rt; .sp.rtsvc.on_comp_start]; 

