.boot.include (gdrive_root, "/framework/service.q");

// default upd function which gets written to log file 
.sp.tp.upd:{[tbl_; data_] 
    func:"[.sp.tp.upd] : "; 
    if[ .sp.tp.loghandle; .sp.tp.loghandle@enlist(`upd; tbl_; data_);]; 
    .sp.log.spam func, " will publish the data now. tbl = ", (string tbl_) , " and row count = ", (string (count data_)); 
    .sp.pub.publish[tbl_; data_]; 
  } ; 
  
// tbls_ is a list of symbols 
// logdir_, logname_, logfile_ must all be string type 
// recoveryfunc_ must be a function 
.sp.tp.setup: {[tbls_; logdir_; logname_; logfile_] 
    func:"[.sp.tp.setup] : "; 
    .sp.tp.tables:: tbls_; 
    .sp.tp.nextdate::(1+.z.D); 
    // adding group attribute for all sym columns in all tables 
    {update sym:`g#sym from x} each tbls_ where `sym in/: cols each tbls_; 
    // all tables must have time column. if it doesnt exist, add one 
    {update time:`time$() from x} each tbls_ where not `time in/: cols each tbls_; 
    
    // re order the cols such that time is the first column 
    { x set `time xcols value x } each tables `.; 
    
    / prepare the log file to write all transactions 
    if[""~logfile_; 
        if[""~logname_; .sp.exception func," logname arg can not be empty when logfile arg is not passed.";]; 
        .sp.tp.logfile_:: $[ logdir_~""; hsym `$logname_; hsym `$logdir_, "/",logname_] ; 
        .sp.tp.loghandle:: .sp.tp.setup_log_hndl[ .sp.tp.add_date_to_logfile [.sp.tp.logfile_;.z.D] ]; 
        .sp.tp.set_next_date[.z.D+1]; // set tomorrows date for next date 
        .sp.log.debug func, "tp.loghandle = ", (string .sp.tp.loghandle); 
      ] ; 
    if[ not(""~logfile_) ; 
        .sp.tp.loghandle:: .sp.tp.setup_log_hndl[logfile_];
        .sp.log.debug func, "tp.loghandle = ", (string .sp.tp.loghandle); ]; 
    : .sp.tp.loghandle; 
  } ; 
  
// sets the next date to be used to generate txn logs when end of day is triggered 
.sp.tp.set_next_date:{[date_] .sp.tp.next_date::date_; }; 

// name of the log generated will be as logfile-YYYYMMDD.log and returned as string 
// logfile_ - symbol type and date_ is date type 
.sp.tp.add_date_to_logfile: {[logfile_; date_]
    :(string logfile_), "-", ssr[string `date$date_; "."; ""],".log"; } ;
     
// logfile_ - must be string type and will return handle to the txn log file 
.sp.tp.setup_log_hndl: {[logfile_]
    func:"[.sp.tp.setup_log_hndl] : "; 
    .sp.tp.logfile:: hsym `$logfile_; 
    / if the txn log file doesnt exist, create one 
    if[ 0h = type key .sp.tp.logfile; 
        .sp.tp.logfile set (); 
        .sp.log.info func, "New transaction logfile created - ", (string .sp.tp.logfile) ; ] ; 
    : hopen .sp.tp.logfile; 
  } ; 
 
// this func will be fired at the end of the day. will call all subscribers the call back func they registered passing new log file 
.sp.tp.notify_eod:{ [id_;tm_] 
    func: "[.sp.tp.notify_eod] : "; 
    .sp.log.info func, "END OF DAY triggered. will notify all the clients."; 
    // create a new txn log file now 
    .sp.tp.loghand1e::.sp.tp.setup_log_hndl[ .sp.tp.add_date_to_logfile [.sp.tp.logfile_; .sp.tp.next_date] ]; 
    .sp.log.debug func, "new tp.loghandle = ", (string .sp.tp.loghand1e) ;
    
    // execute the func the rts have given us 
    { [hdl_; func_] .sp.io.async[hdl_; (func_; `)]; }'[key .sp.tp.eod_subscribers; value .sp.tp.eod_subscribers]; 
    .sp.log.info func, "all notifications to RTs complete!"; 
  } ; 
  
// this func will be called by RTS to get notified about the end of day to change the txn log fil e 
.sp.tp.subscibe_eod:{[func_] 
    func : "[.sp.tp.subscibe_eod] . "; 
    .sp.tp.eod_subscribers[.z.w] : func_; 
    .sp.log.info func, "subscribed to end of day notification. subscriber's handle = ",  (string .z.w); 
  } ; 
  
.sp.tp.rt_hand1e_event:{[hdl_; event_] 
    func: "[.sp.tp.rt_hand1e_event] : "; 
    .sp.log.debug func, " handle = ", (string hdl_) , " and event type = ", (string event_); 
    if[ event_ <> `close; .sp.log.debug func, "This is NOT a close event. Nothing to do."; :0 ]; 
    .sp.tp.eod_subscribers :: .sp.tp.eod_subscribers _hdl_; 
  } ; 
  
.sp.tp.get_logfile:{[] : .sp.tp.logfile } ; 

.sp.tp.on_comp_start: {[] 
    func:"[.sp.tp.on_comp_start] : "; 
    // global variable that holds handles to subscribers 
    .sp.tp.eod_subscribers :: ()!(); 
    // subscribe to rt closed notification 
    .sp.io.add_con_event_handler[.sp.tp.rt_hand1e_event; `]; 
 
    .sp.tp.te:23:59:59:999 ; // time to end of day 
    // time till end of day in milli seconds 
    .sp.tp.te_ms: .sp.tp.te.hh*60*60*1000 + .sp.tp.te.mm*60*1000 + .sp.tp.te.ss*1000 + `int$ .sp.tp.te mod 1000; 
    // add a cron for end of day notification 
    .sp.tp.eod_cronid:: .sp.cron.add_timer[.sp.tp.te_ms; 1; .sp.tp.notify_eod]; // add a cron event that fires at end of day 
    .sp.log.info func, "tp is ready now"; 
    :1b; 
  } ; 
  
.sp.comp.register_component[`tp;`svc;.sp.tp.on_comp_start]; 

