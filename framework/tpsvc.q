.boot.include (gdrive_root, "/framework/tp.q");

.sp.tpsvc.on_comp_start: {[] 
    func : "[.sp.tpsvc.on_comp_start] : ";
    // schema file should have table definitions in the root names pace 
    .sp.tpsvc.schemafile:: .sp.arg.required[`schemafile]; 
    // txn log directory and txn log file names are required arguments 
    .sp.tpsvc.logdir::.sp.arg.required[`logdir]; 
    .sp.tpsvc.logname:: .sp.arg.required[`logname]; 
    if[ ""~ .sp.tpsvc.schemafile; .sp.exception func, "Invalid args: schemafile arg can not be empty";]; 
    if[ ""~ .sp.tpsvc.logdir; .sp.exception func, "Invalid args: logdir arg can not be empty";]; 
    if[ ""~ .sp.tpsvc.logname; .sp.exception func, "Invalid args: logname arg can not be empty";]; 
 
    // log all the variables 
   { func : "[.sp.tpsvc.on_comp_start] : "; xx: `$(".sp.tpsvc.") , (string x); a:value xx; if[10h <> type a; a:string a]; .sp.log.debug func,(string x)," = ", a; } each system "v .sp.tpsvc";

    .sp.file.loadfile[gdrive_root, "/services/schemas"; .sp.tpsvc.schemafile]; 
    tbls: tables `.; 
    if[ 0 = count tbls; .sp.exception func, "No tables in root namespace. check the schema fi1e ", .sp.tpsvc.schemafile ]; 
    
    .sp.tpsvc.loghandle:: .sp.tp.setup [tbls; .sp.tpsvc.logdir; .sp.tpsvc.logname; ""] ; 
    .sp.log.info func, "tpsvc is ready now."; 
    :1b; 
  } ; 
  
.sp.comp.register_component[`tpsvc; `tp; .sp.tpsvc.on_comp_start]; 
