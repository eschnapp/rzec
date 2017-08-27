.boot.include (gdrive_root, "/framework/core.q");
.boot.include (gdrive_root, "/framework/pub.q");

.sp.alias.svc.load_aliases: { 
    func: "[.sp.alias.svc.load_aliases] . "; 
    if[ .sp.file.exists[.sp.alias.svc.data_file]; 
        .sp.log.debug func, "file ", (string .sp.alias.svc.data_file), " exists. will load this file now"; 
        .sp.alias.svc.alias_table:: get hsym .sp.alias.svc.data_file; 
        .sp.log.info func, "completed loading alias file from: " , (raze string .sp.alias.svc.data_file), " row count = ", (string (count .sp.alias.svc.alias_table)); 
        :1b]; / Return after reading 
    // create an empty table otherwise 
    .sp.alias.svc.alias_table:: ( [svc_name: `$() ] alias: `$() ); 
    .sp.log.info func, "created an empty table to hold aliases"; 
  } ; 
  
.sp.alias.svc.save_alias_table:{ 
    func: "[.sp.alias.svc.save_alias_table] : "; 
    if[ .sp.file.exists[.sp.alias.svc.data_file]; 
    backup_file_name: raze (string .sp.alias.svc.data_file,".", string .z.Z ); 
    .sp.log.debug func, "file", (string .sp.alias.svc.data_file), " exists. will back it up to: ", backup_file_name; 
    backup_command: raze ("mv ", (string . qf.alias.svc.data_fi1e), " ", backup_file_name ); 
    system backup_command ]; 
    / save it to file now 
    (hsym .sp.alias.svc.data_file) set .sp.alias.svc.alias_table; 
    .sp.log.info func, "completed saving aliases to file: " , (raze string .sp.alias.svc.data_file); 
  } ; 
  
.sp.alias.svc.add_alias:{[svc_; alias_] 
    func: "[.sp.alias.svc.add_alias] : "; 
    `.sp.alias.svc.alias_table upsert ([svc_name: (),svc_] alias: (),alias_); 
    .sp.pub.publish[`alias; .sp.alias.svc.alias_table]; 
    .sp.alias.svc.save_alias_table[]; 
    .sp.log.info func, "completed. svc = ", (string svc .) , " alias = ", (string alias_); 
  } ; 
  
.sp.alias.svc.remove_alias:{[svc_] 
    func: "[.sp.alias.svc.remove_alias] : "; 
    delete from `.sp.alias.svc.alias_table where svc_name = svc_; 
    .sp.pub.publish[`alias; .sp.alias.svc.alias_table]; 
    .sp.alias.svc.save_alias_table[]; 
    .sp.log.info func, "completed. svc = ", (string svc_); 
  } ; 
  
.sp.alias.svc.on_comp_start:{ [] 
    func : "[.sp.alias.svc.on_comp_start] : "; 
    .sp.alias.svc.data_dir:: .sp.arg.required[`config_data_dir]; 
    .sp.alias.svc.data_file :: `$ (.sp.alias.svc.data_dir, "/alias"); 
    .sp.log.debug[("Attempting to load the aliases table")]; 
    .sp.alias.svc.load_aliases[]; 
    .sp.log.info func, "component alias_svc is ready."; 
    :1b; 
  } ; 
  
.sp.comp.register_component[`alias_svc;`core`pub`file; .sp.alias.svc.on_comp_start]; 

