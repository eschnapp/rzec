.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/data_convert.q");

.sp.cache.on_comp_start:{[]
    func: "[.sp.cache.on_comp_start]: ";
    .sp.log.info func, "Initializing the RT Cache";
    .sp.cache.tables:: ()!();
    .sp.cache.tables[`test]:([]sym:10?`3; sz:10?255);


    .sp.cache.last_upd:: ()!();
    .sp.cache.last_upd[`test]:([]sym:10?`3; sz:10?255);

    .sp.cache.clients:: ([svc: `$(); topic: `$()] paused: `boolean$(); upd_f: (); rec_f: (); upd_params: (); rec_params:(); ready: `boolean$());
    .sp.cache.client_callbacks:: ([source: `$(); svc: `$(); topic: `$()] upd_cb: (); ready_cb:(); upd_time: `time$());
    .sp.cache.add_clients ./: flip value flip (select svc, topic, upd_f, rec_f, upd_params, rec_params from .sp.cache.get_startup_clients[]);
    .sp.log.info func, "RT Cache initialization complete!";
    :1b;
    };
    
.sp.cache.get_startup_clients:{ []
    : ([svc: `$(); topic: `$()] paused: `boolean$(); upd_f: (); rec_f: (); upd_params: (); rec_params:(); ready: `boolean$());
    };        
                
.sp.cache.add_clients:{[svc_; topic_; upd_f_; rec_f_; upd_params_; rec_params_]
    func: "[.sp.cache.add_clients]: ";
    tbl: ([svc: (),svc_; topic: (),topic_] paused: 0b; upd_f: (),upd_f_; rec_f: (),rec_f_; upd_params: enlist upd_params_; rec_params: enlist rec_params_);
    ret:{ [svc_;topic_;upd_f_;rec_f_;upd_params_;rec_params_]
        func: "[.sp.cache.add_clients#1]: ";
        .sp.ns.client.wait_for_ever[svc_;`];
        .sp.log.debug func, "svc: ", (string svc_), " topic: ", (string topic_);
        if[ 0 < (exec count i from .sp.cache.clients where svc = svc_, topic = topic_);
            .sp.log.warn func, "Allready subscribed to RT ", (string svc_);
            .sp.exception "ALLREADY SUBSCRIBED";
            ];
        .sp.log.info func, "Adding new client for " ,(string svc_), ":",(string topic_);
        
        subparams: `update_callback`update_filter`recovery_callback`recovery_filter`update_filter_params`recovery_filter_params`recovery_complete_callback!(.sp.cache.p.on_upd[svc_;;];upd_f_; .sp.cache.p.on_rec[svc_;;]; rec_f_; upd_params_; rec_params_; .sp.cache.p.on_rec_complete[svc_;]);
        sub_ret: .sp.sub.subscribe[svc_;`;topic_;subparams];
        if[ ((type .sp.cache.tables[topic_]) in (98h;99h))   and (count .sp.cache.tables[topic_] ) <= 0;
            .sp.cache.tables[topic_]:: $[ (type sub_ret) in (98h;99h); upd_f_[sub_ret;upd_params_]; ()] ];
        tbl: ([svc: (),svc_; topic: (),topic_] paused: 0b; upd_f: (),upd_f_; rec_f: (),rec_f_; upd_params: enlist upd_params_; rec_params: enlist rec_params_; ready: (),0b);
        .sp.cache.clients:: .sp.cache.clients upsert tbl;
        .sp.consts[`OK];
        } ./: flip value flip (select svc, topic, upd_f, rec_f, upd_params, rec_params from tbl);
    .sp.log.info func, "Completed.";
    ret;  
    };
        
.sp.cache.p.on_rec_complete:{[svc_;topic_]
    func: "[.sp.cache.p.on_rec_complete]: ";
    .sp.log.info func, "called for ", (string svc_), ":", (string topic_);
    update ready: 1b from `.sp.cache.clients where svc = svc_, topic = topic_;
    if[not .sp.cache.is_paused[svc_;topic_];
        handlers: exec ready_cb from .sp.cache.client_callbacks where svc = svc_, topic = topic_;
        handlers .\: (svc_;topic_)];
    };            
    
.sp.cache.is_ready:{[svc_;topic_]
    : all (exec ready from .sp.cache.clients where svc in svc_, topic in topic_);
    };    
    
.sp.cache.p.on_rec:{[svc_;topic_;data_]
    func: "[.sp.cache.p.on_rec]: ";
    .sp.log.debug func, "svc: ", (string svc_), ", topic: ", (string topic_), ", and data rc: ", (string (count data_));
    $[any (keys data_) in cols data_;
        .sp.cache.tables[topic_]:: .sp.cache.tables[topic_] upsert data_;
        .sp.cache.tables[topic_]:: .sp.cache.tables[topic_], (cols .sp.cache.tables[topic_]) xcols data_ ] ;
    
    if[ not .sp.cache.is_paused[svc_;topic_];
        handlers: exec upd_cb from .sp.cache.client_callbacks where svc = svc_, topic = topic_;
        handlers .\: (svc_;topic_;data_;`recover) ];
    };
    
.sp.cache.p.on_upd:{[svc_;topic_;data_]
    func: "[.sp.cache.p.on_upd]: ";
    .sp.log.debug func, "svc: ", (string svc_), ", topic: ", (string topic_), ", and data rc: ", (string (count data_));
  
    .sp.cache.last_upd[topic_]: data_;

    $[any (keys data_) in cols data_;
        .sp.cache.tables[topic_]:: .sp.cache.tables[topic_] upsert data_;
        .sp.cache.tables[topic_]:: .sp.cache.tables[topic_], (cols .sp.cache.tables[topic_]) xcols data_ ] ;
    
    if[ not .sp.cache.is_paused[svc_;topic_];
        handlers: exec upd_cb from .sp.cache.client_callbacks where svc = svc_, topic = topic_;
        handlers .\: (svc_;topic_;data_;`update) ];
    };
    
.sp.cache.remove_clients:{[svc_;topic_]
    func: "[.sp.cache.remove_clients]: ";
    tbl: ([] svc:(),svc_; topic:(),topic_);
    {[svc_;topic_]
        func: "[.sp.cache.remove_clients#1]: ";
        .sp.log.info func, "Removing RT client for ", (string svc_), " on topic ", (string topic_);
        .sp.sub.unsubscribe[svc_;topic_];
        } ./: flip value flip tbl;
    
    .sp.cache.clients:: delete from .sp.cache.clients where svc = svc_, topic = topic_;
    .sp.log.info func, "complete";
    };    
    
.sp.cache.resume_client:{[svc_;topic_]
    func: "[.sp.cache.resume_client]: ";
    .sp.log.info func, "resuming client ", (string svc_), " and topic ", (string topic_);
    .sp.cache.clients:: update paused: 0b from .sp.cache.clients where svc = svc_, topic = topic_;
    .sp.log.info func, "complete";
    };    
    
.sp.cache.pause_client:{[svc_;topic_]
    func: "[.sp.cache.pause_client]: ";
    .sp.log.info func, "pausing client ", (string svc_), " and topic ", (string topic_);
    .sp.cache.clients:: update paused: 1b from .sp.cache.clients where svc = svc_, topic = topic_;
    .sp.log.info func, "complete";
    };        
       
.sp.cache.is_paused:{ [svc;topic]
    : first exec paused from .sp.cache.clients where svc = svc, topic = topic;
  }; 

.sp.cache.add_callback_handler:{[src_;svc_;topic_;upd_cb_;ready_cb_]
    maxi: exec max i from .sp.cache.client_callbacks;
    `.sp.cache.client_callbacks upsert ([source: (), src_; svc: (),svc_; topic: (),topic_] upd_cb: (), upd_cb_; ready_cb: (), ready_cb_; upd_time: (), .z.T);
    : exec i from .sp.cache.client_callbacks where i > maxi;
    };        
    
.sp.cache.remove_callback_handler:{[src_;svc_;topic_]
    .sp.cache.client_callbacks:: delete from .sp.cache.client_callbacks where source = src_, svc = svc_, topic = topic_;
    };
        
.sp.cache.clear_table:{[topic_]
    func: "[.sp.cache.clear_table]: ";
    .sp.log.info func, "clearing table ", (string topic_);
    if[ topic_ in (key .sp.cache.tables);
        .sp.cache.tables[topic_]: 0#.sp.cache.tables[topic_]];
    };
                
.sp.comp.register_component[`cache;enlist `common;.sp.cache.on_comp_start];


