.boot.include (gdrive_root, "/framework/core.q");
.boot.include (gdrive_root, "/framework/pub.q");

/ PRIVATE functions (which must come first, atypical to customs in static languages. They come first such that they're available to later public functions)) 
/ change the file name to what Q expects 
.sp.cfgsvc.format_file:{ [filename] :$[`;(":",string[filename])];}; 

/ Create the service_data variable with types specified. 
.sp.cfgsvc.create_service_data:{[] 
    .sp.cfgsvc.service_data::([service_name:`$();key_name:`$()] config_value:());}; 

/ Read the data from disk, if it exists. Otherwise, it is created. 
.sp.cfgsvc.load_service_data:{[] 
    if[ .sp.file.exists[ .sp.cfgsvc.format_file[ .sp.cfgsvc.data_path[] ] ]; 
        .sp.cfgsvc.service_data::get[ .sp.cfgsvc.format_file[ .sp.cfgsvc.data_path[] ] ]; :1b; ]; / Return after reading 
    .sp.cfgsvc.create_service_data[]; 
  };
 
/ Save the data to disk. The path can be changed in the const.q file. 
/ Save the previous file as a backup file with a timestamp. 
/ In order to prevent the backups from piling up, a cleanup script will run regularly 
.sp.cfgsvc.save_service_data:{[] 
    if[ .sp.file.exists[ .sp.cfgsvc.format_file[ .sp.cfgsvc.data_path[] ] ]; 
        backup_file_name: raze (string .sp.cfgsvc.data_path[] ,".", string .z.Z ); 
        backup_command: raze ("mv ", string .sp.cfgsvc.data_path[], " ", backup_file_name ); 
        system backup_command;]; 

    set[.sp.cfgsvc.format_file[.sp.cfgsvc.data_path[]]; .sp.cfgsvc.service_data]; 
  }; 
  
/ All args must be symbols 
/ The generic list is necessary as a column must adhere to a single type. 
.sp.cfgsvc.set_value:{ [service_name; key_name; config_value] 
    func:"[.sp.cfgsvc.set_value] : "; 
    if[ null[ service_name] or null[ key_name ]; 
        errormsg:"Invalid service name or key name args: ", (raze string service_name), ",", (raze string keyname); 
        .sp.exception[ errormsg ]; ]; 
        
    rowTOInsert: ( service_name; key_name; enlist config_value ); 
    result: upsert[ `.sp.cfgsvc.service_data; rowTOInsert]; 
    .sp.cfgsvc.save_service_data[]; 
    
    / publish this value for every subscriber, the filter should pick it out for each client. 
    tableToPublish: upsert[ 0#.sp.cfgsvc.service_data; rowTOInsert]; 
    .sp.pub.publish[ `.sp.cfg.data_update_feed; tableToPublish ]; 
    .sp.log.debug func, "completed and published cfg data. service_name = ", (raze string service_name), ", key_name = " (raze string key_name);
    svc:service_name; kkey:key_name; 
    :select from .sp.cfgsvc.service_data where service_name=svc, key_name=kkey; 
  } ; 
  
.sp.cfgsvc.remove_value:{[ service_arg; key_arg] 
    delete from `.sp.cfgsvc.service_data where service_name=service_arg, key_name=key_arg; 
    .sp.cfgsvc.save_service_data[]; 
    / update local caches of subscribers ... 
  } ; 
  
/ This function accepts two SYMBOLS, uses those as a compound key to look up a row in the table, and returns the value of arbitrary type from that row. 
/ Returns null if no value was found. 
.sp.cfgsvc.get_value:{[service_arg;key_arg] 
    result:first first .sp.cfgsvc.service_data[(service_arg;key_arg)]; 
    if[ all null result; :0N]; 
    : result; 
  }; 
  
/ Returns the table of all data corresponding to the given SYMBOL service name, and to the global service placeholder. 
.sp.cfgsvc.get_all_from_service: {[service_name_arg] 
    :select from .sp.cfgsvc.service_data where (service_name=service_name_arg) or (service_name=`global); 
  } ; 
  
/ Returns the table of all data. 
.sp.cfgsvc.get_all:{ [] : .sp.cfgsvc.service_data; }; 

.sp.cfgsvc.data_path:{ [] :$[`; raze[.sp.cfgsvc.data_file_dir, "/", .sp.cfgsvc.data_file_name] ]; }; 

/ The on_comp_start function gets called upon initialization 
.sp.cfgsvc.on_comp_start:{ [] 
    func : "[.sp.cfgsvc.on_comp_start] : "; 
    .sp.cfgsvc.data_file_name:: "config_service_data"; 
    .sp.cfgsvc.data_file_dir:: .sp.arg.required[`config_data_dir]; 
    .sp.log.debug[("Attempting to load the configuration data")]; 
    .sp.cfgsvc.load_service_data[]; 
    .sp.log.info func, "component cfgsvc is ready."; 
    :1b; 
  } ; 
  
/ register_component 
.sp.comp.register_component[`config_service;`core`pub`file;.sp.cfgsvc.on_comp_start]; 

