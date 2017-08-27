.boot.include (gdrive_root, "/framework/svc.q");

/ PUBLIC functions 
/ Get the (local version of the) requested value. Prefer key/value specific to this service before a global version 
/ Returns null if nothing is found. 
.sp.cfg.lookup:{[key_arg] 
    result: first first .sp.cfg.local_service_data[(.sp.cfg.current_service_name;key_arg)]; 	/ this first gets us the list. 
    if[ not all null result; :result ]; / This first gets us the value (which may be a list). Use all null 
    result:first first .sp.cfg.local_service_data[(`global;key_arg)]; 
    if[ not all null result; :result]; 
    :0N 
  } ; 
  
/ Helper function to provide default value when the value isn't found. 
.sp.cfg.get_value:{[key_arg;default_arg] 
    result: .sp.cfg.lookup[ key_arg ]; 
    $[ 0N~ result; : default_arg; : result ]; 
  } ; 
  
/ Return all key/values associated with this service and the global service name 
.sp.cfg.get_all:{[] 
    : .sp.cfg.local_service_data; } ; 
    
/ Set a list of callbacks which will get called when an update to the config data is received 
/ If your preferred usage of config values is to simply retrieve them by name from the config library, callbacks are likely not necessary. 
/ If you prefer to pull your config values into your own variables, perhaps you should add callbacks to update the variables you're using. 
/ The callback must take no arguments and return nothing. 
/ Example: .sp.cfg.set_change_callbaclclist[enlist {[] .sp.myvariable:: .sp.cfg.get_value['myvariable;'default]}] 
.sp.cfg.set_change_callback_list:{[callback_list] .sp.cfg.user_callback_list,::callback_list; }; 

/ ///////////////////////////////////////// 
/ PRIVATE functions (as in more "verbose" languages) 
/ Run each of the user callbacks. NO op if there are none. 
.sp.cfg.run_user_callbacks:{[id_;tm_]  each[ {x[]}; .sp.cfg.user_callbaclclist]; :lb; }; 

/ Accepts the output of recovery_filter. Runs on local side. 
.sp.cfg.recovery_callback:{[topic_; data_] 
    func : "[.sp.cfg.recovery_callback] : "; 
    .sp.log.info func, "Recovery callback called on topic: ", (string topic_), ". setting local config data to incoming data. row count ", (string (count data_)); 
    : .sp.cfg.local_service_data::data_; 
  } ; 


/ The incoming data is what the config_service publishes: deltas to the config data table 
/ data_ is in the form of a table matching the schema of the config_service_data 
/ Grab all k/v pairs which correspond to this service name or the global service name 
.sp.cfg.update_filter:{[data; params] 
    : select from data where (service_name=params[0]) or (service_name=`global) }; 

.sp.cfg.recovery_filter:{[data; params] 
    : select from .sp.cfgsvc.service_data where (service_name=params[0]) or (service_name=`global) }; 
    
/ Accepts the output of the update_filter above. Runs on local side. 
/ updates the local cache and calls the user callback 
.sp.cfg.update_callback:{ [topic_;data_] 
    func : "[.sp.cfg.update_callback] : "; 
    .sp.log.debug func, "Received update from config_service on topic :" (string topic_), " row count: ", (string (count data_)), ". updating local cache."; 
    / combine the new data with the old, overwriting if necessary. 
    upsert[ `.sp.cfg.local_service_data; data_ ]; 
    / Run the local change callbacks. This is a no-op if the user hasn't reassigned it. 
    / Get cron to update to run the callbacks. It shouldn't be done here because a deadlock 
    / or other error might be created since this function itself is inside of a remote execution block . 
    .sp.cron.add_timer[ 500; 1; .sp.cfg.run_user_callbacks ]; 
  };

.sp.cfg.cfg_subparams: { [] 
    upd_filter: .sp.cfg.update_filter; 
    rec_filter: .sp.cfg.recovery_filter;
    upd_callback: `.sp.cfg.update_callback; 
    rec_callback: `.sp.cfg.recovery_callback; 
    upd_fltr_params:enlist .sp.cfg.current_service_name; 
    rec_fltr_params:enlist .sp.cfg.current_service_name; 
    params:`recovery_callback`recovery_filter`update_filter_params`update_callback`update_filter`recovery_filter_params!
        (rec_callback;rec_filter;upd_fltr_params;upd_callback;upd_filter;rec_fltr_params); 
    :params; 
  } ; 
  
/ Hook up all the necessary callbacks and parts to register this as a subscriber to the config_service. 
/ The topic subscribed to is called ".sp.cfg.data_update_feed". 
.sp.cfg.on_comp_start:{ []
    func : "[.sp.cfg.on_comp_start] : ";
    .sp.cfg.user_callback_list::(); 
    .sp.cfg.local_service_data::([service_name:`$();key_name:`$()] config_value:`$()); 
    .sp.cfg.current_service_name::$[`;.sp.arg.required[`svc_name]]; 
    .sp.cfg.sp_server_name:$[`; .sp.arg.required[`sp_server]]; 
    .sp.log.info func, "waiting on SP Server: ", (string .sp.cfg.sp_server_name), " to come up ... "; 

    if[ not .sp.ns.client.wait_for_svc[ .sp.cfg.sp_server_name; `; .sp.consts[`DEF_WFS_TO]; .sp.consts[`DEF_WFS_INTERVAL]]; 
        .sp.exception func, "SP Server ", (string .sp.cfg.sp_server_name), " not up.Failing hard." ]; 
    .sp.log.info func, "SP Server: ", (string .sp.cfg.sp_server_name), " is up. Resuming ... "; 
    
    / Get the config data synchronously 
    .sp.cfg.local_service_data::.sp.re.exec[ .sp.cfg.sp_server_name; `; ({[sname] :select from .sp.cfgsvc.get_all[] where (service_name=`global) or (service_name=sname);}; .sp.cfg.current_service_name);10000]; 
    .sp.sub.subscribe[ .sp.cfg.sp_server_name; `; `.sp.cfg.data_update_feed; .sp.cfg.cfg_subparams[] ]; 
    .sp.log.info func, "component cfgsvc is ready."; 
    :1b; 
  } ; 
  
.sp.comp.register_component[`config_library; `svc; .sp.cfg.on_comp_start]; 

