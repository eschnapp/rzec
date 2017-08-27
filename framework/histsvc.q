.boot.include (gdrive_root, "/framework/hist.q");
.boot.include (gdrive_root, "/framework/dbmaint.q");

.sp.histsvc.on_comp_start: {[] 
    func : "[.sp.histsvc.on_comp_start] : ";
    // valid hdb path is a required arg for hist svc 
    .sp.histsvc.hdbpath::`$.sp.arg.required[`hdbpath]; 
    system ("mkdir -p ", (string .sp.histsvc.hdbpath)); // create directory if it doesnt exist
    
    good: .sp.file.exists[.sp.histsvc.hdbpath]; 
    if[ good = 0b; msg : "Invalid HDB path passed in hdbpath argument."; .sp.exception msg; ]; 
    
    .sp.hist.setup[.sp.histsvc.hdbpath]; 
    thisdb:: hsym .sp.histsvc.hdbpath;
    
    .sp.log.info func, "histsvc is ready now."; 
    :1b; 
  } ; 

.sp.comp.register_component[`histsvc; `hist; .sp.histsvc.on_comp_start]; 
