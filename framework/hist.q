.boot.include (gdrive_root, "/framework/service.q");

.sp.hist.reload_hdb: {[] 
    func:"[.sp.hist.reload_hdb] : "; 
    system "l ", (string .sp.hist.hdb_path); 
    .sp.log.info func, "HIST svc has been refreshed. reload of hdb under ", (string .sp.hist.hdb_path), " completed"; 
  } ; 
  
.sp.hist.setup:{[hdb_path_] 
    .sp.hist.hdb_path::hdb_path_; 
    .sp.hist.reload_hdb[]; 
  } ; 

.sp.hist.on_comp_start: {[] 
    func:"[.sp.hist.on_comp_start] : "; 
    .sp.log.info func,"hist is ready now"; 
    :1b; 
  } ; 

.sp.comp.register_component[`hist;`core; .sp.hist.on_comp_start];
