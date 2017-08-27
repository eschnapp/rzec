/ This is the client part to get aliases to the application services from the server 
.boot.include (gdrive_root, "/framework/svc.q");

.sp.alias.get_svc:{ [alias_] :first exec svc_name from .sp.alias.alias_table where alias = alias_ }; 

.sp.alias.set_change_callback_list:{[callback_list] .sp.alias.user_callback_list,::callback_list; }; 

.sp.alias.run_user_callbacks:{ {x[]} each .sp.alias.user_callback_list }; 

.sp.alias.recovery_callback:{[topic_; data_] 
    func : "[.sp.alias.recovery_callback] : "; 
    .sp.log.info func, "Recovery callback called on topic: ", (string topic_), ". setting local alias data to incoming data. row count ", (string (count data_)); 
    : .sp.alias.alias_table::data_; 
  } ; 
  
.sp.alias.update_callback:{ [topic_;data_] 
    func : "[.sp.alias.update_callback] : "; 
    .sp.log.debug func, "Received update on topic :", (string topic_), " row count: ", (string (count data_)), ". updating local cache."; 
    / combine the new data with the old, overwriting if necessary . 
    .sp.alias.alias_table::data_; 
    / Run the local change callbacks. This is a no-op if the user hasn't reassigned it . 
    .sp.alias.run_user_callbacks[]; 
  } ; 
  
.sp.alias.subparams: { [] 
    rec_callback:`.sp.alias.recovery_callback; 
    rec_filter:{[topic_; p] :.sp.alias.svc.alias_table }; 
    upd_filter:{ [data_; params_] :data_ }; 
    upd_callback: `.sp.alias.update_callback; 
    fp: `; 
    params:`recovery_callback`recovery_filter`filter_params`update_callback`update_filter!(rec_callback;rec_filter;fp;upd_callback;upd_filter); 
    :params; 
  } ; 
  
.sp.alias.on_comp_start:{ [] 
    func : "[.sp.alias.on_comp_start] : ";
    .sp.alias.user_callback_list::(); 
    .sp.alias.alias_table::( [svc_name: `$()] alias: `$() ); 
    sp_server_name:$[`; .sp.arg.required[`sp_server] ]; 
    .sp.log.info func, "waiting on SP Server: ", (string sp_server_name), " to come up ... "; 
    if[ not .sp.ns.client.wait_for_svc[ sp_server_name; `; .sp.consts[`DEF_WFS_TO]; .sp.consts[`DEF_WFS_INTERVAL]]; 
        .sp.critical func, "QF Server ", (string sp_server_name), " not up. Failing hard." ];
        
    .sp.log.info func, "SP Server: ", (string sp_server_name), " is up. Resuming ... "; 
    / Get the config data synchronously 
    .sp.alias.alias_table::.sp.re.exec[ sp_server_name; `; ".sp.alias.svc.alias_table"; 10000]; 
    .sp.sub.subscribe[ sp_server_name; `; `alias; .sp.alias.subparams[] ]; 
    .sp.log.info func, "component alias is ready."; 
    :1b; 
  }; 
  
.sp.comp.register_component[`alias; `svc; .sp.alias.on_comp_start]; 

