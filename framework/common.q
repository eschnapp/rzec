.boot.include (gdrive_root, "/framework/config_library.q");
.boot.include (gdrive_root, "/framework/svc.q");
// .boot.include (gdrive_root, "/framework/cache.q");
/ This file has to be included in all clients. This will wait for all services this svc depends on . 
.sp.com.on_comp_start:{ [] 
    func : "[.qf.com.on_comp_start] : "; 
    deps : .sp.cfg.lookup `dependency; 
    if[ any not null deps; 
        .sp.log.info func, "There are total of : ", (string (count deps)), " dependencies we have to wait for"; 
    { if[null x; :0]; .sp.log.info "[.qf.com.on_comp_start] : waiting for svc - ", (string x); .qf.ns.client.wait_for_ever[x] } each deps; ]; 
    if[ (any null deps) and ((count deps) = 1); .sp.log.info func, "No depencies found in config DB for this svc" ]; 
    .sp.log.info func, "All done. component common is ready now!"; 
    :1b; 
  };
 
/ register_component 
.sp.comp.register_component[`common;`config_library`svc; .sp.com.on_comp_start]; 
