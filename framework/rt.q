.boot.include (gdrive_root, "/framework/service.q");

// default upd function for RT
// users can modify this function to fit their needs
// upd_modify is a list of functions. BIG ASSUMPTION: only one function from the list actually does change the data for a given topic
// ALSO functions in upd_modify HAS to take 2 args .. topic and data. if not, it will fail !!
upd:{ [tbl_;data_]
    .sp.rt.last_upd:: (tbl_;data_);
    d:{ [func_; args_] . [func_; args_; -1] } ' [upd_modify; (count upd_modify)#enlist(tbl_; data_)];
    if[ 1 < count d where (type data_) = type each d; .sp.log.error "[upd] : Failed inserting data into table ", (string tbl_) , ". more than 1 funcs in upd_modify returned data."; : -1] ;
    if[ 1 = count d where (type data_) = type each d; data_:raze d where (type data_) = type each d; ];
    .[upsert; (tbl_; data_); { .sp.log.error "[upd] : Fai1ed inserting data into table ",(string y), " due to:-", x; .sp.log.error@.Q.s z; .sp.log.error@.Q.s (meta z);.sp.rt.bad_updates:: .sp.rt.bad_updates, (tbl_;data_); 'x} [;tbl_;data_]];
    .sp.pub.publish[tbl_; data_]; // also publish for subscribers if any
    .sp.log.spam "[ upd ] : table ",(string tbl_) , " and row count = ", (string (count data_));
  } ;

// dummy func that needs to be over ridden by other services
upd_modify: () ;

// if the schema of any table has to be modified, override this function
schema_modify:();

.sp.rt.def_subparams: {[]
    rec_callback:{[tbl_;data_] }; // dummy recovery callback function
    rec_filter:{[topic_;fltrparm_] :0#value topic_}; // no data sent to subscriber in recovery
    upd_callback:upd; // use the default upd function so users can modify later
    upd_filter:{[data_;fltrparm_] :data_;}; // default in RT has no filters. Gets everything from TP unfiltered
    fp:`; // no filter params
    params:`recovery_callback`recovery_filter`filter_params`update_callback`update_filter!(rec_callback;rec_filter;fp;upd_callback;upd_filter);
    :params;
  } ;

.sp.rt.save_to_hdb_at:{[time_]
    func:"[.sp.rt.save_to_hdb_at] : ";
    .sp.log.debug func,"will save data in all the tables in root namespace to HDB at ", (string time_);

    .sp.rt.tl:`time$time_ - .z.T;

    ms_hh:.sp.rt.tl.hh*60*60*1000;
    ms_mm:.sp.rt.tl.mm*60*1000;
    ms_ss: .sp.rt.tl.ss*1000;
    ms_sss:`int$.sp.rt.tl mod 1000;

    ms_add:ms_hh + ms_mm + ms_ss + ms_sss;
    .sp.log.spam func, (string ms_hh), ":", (string ms_mm), ":", (string ms_ss), ".",(string ms_sss), " = ", (string ms_add) ;

    // add a cron event that fires when its time to save to hdb
    .sp.tp.eod_cronid:: .sp.cron.add_timer[ ms_add; 1; { [id_;tm_] .sp.rt.eod[];  } ];
    .sp.log.info func,"added cron to save RT data to hdb in ", (string ms_add), "milliseconds";
  } ;

.sp.rt.do_append:{ :0b; };

// this func will be called by TP when a new log file gets created at the end of the day.
// here we have to save all the tables to H/ST db
.sp.rt.eod: {[]
    func:"[.sp.rt.eod] : ";
    .sp.log.info func, "end of day notification came in. will save tables to hdb now";
    tbls : tables `.;
    append: .sp.rt.do_append[];
    .sp.rt.save_to_hist[;append] each tables `.;
    if[ null .sp.rt.hist_svc_name; .sp.log.info func, "No known HIST svc to reload hdb. "; :0] ;

    /wait_for:5 * 60 * 1000; // 5 mins in milliseconds
    wait_for: 5000;
    // wait for 5 mins for the hist svc and give up if not found
    exists_:.sp.ns.client.wait_for_svc[.sp.rt.hist_svc_name; .sp.rt.hist_svc_inst; wait_for; 1000];
    if[exists_; .sp.re.request[.sp.rt.hist_svc_name; .sp.rt.hist_svc_inst; (`.sp.hist.reload_hdb; `); .sp.consts[`DEF_EXEC_TO]] ];
    if[exists_; .sp.log.info func," reload of hdb in the HIST svc.", (string .sp.rt.hist_svc_name), ":", (string .sp.rt.hist_svc_inst), " completed."];
    if[0b = exists_; .sp.log.info func,"could NOT reload HDB. May be the svc does not exist" ];

    .sp.rt.clean_up_rt[]; // clean up the tables now that we moved data to hdb
    .sp.log.info func, "All done!";
  } ;

.sp.rt.clean_up_rt:{[]
    func : "[.sp.rt.clean_up_rt] : ";
    // remove all data from the tables and put back g# attribute for sym cols
    tbls: tables `.; // all tables in root namespace
    { x set 0#value x } each tbls ; // purge data
    { update sym:`g#sym from x } each tbls where `sym in/: cols each tbls; // create attributes

    // release the memory to OS
    rel : .Q.gc[];
    .sp.log.info func, "released " (string rel), " bytes to OS after clearing the tables in root namespace";
  } ;

.sp.rt.save_to_hist:{[tbl_; append_]
    func : "[.sp.rt.save_to_hist] : ";
    .sp.log.debug func, "will save data in table ", (string tbl_) , " in to hist now. append_ = " (string append_);
    if[ .sp.rt.saved_to_hist[tbl_] and ( 0b = .sp.rt.force_save_to_hist);
        msg: func, "Data has already been saved to hist before. will NOT save it again unless override is set.";
        .sp.log.warn msg; :0 ];

    if[ .sp.rt.saved_to_hist[tbl_] and .sp.rt.force_save_to_hist;
        .sp.log.warn func, "Data already saved before now to hist. saving it again because of the override being set" ];

    data:value tbl_;
    ne_cols:(exec c from meta data) where (`long$( { `int$x within(65;90) } each (exec t from meta data)));
    .sp.file.save_partition[.sp.rt.hdb_path; tbl_; (); append_; .z.D; ne_cols; data];
    .sp.rt.saved_to_hist[tbl_]:1b;
    .sp.log.info func, "data in table ", (string tbl_) , " has been saved to hist.";
  } ;

.sp.rt.replay_log:{[]
    func:"[.sp.rt.replay_log] : ";
    .sp.log.info func, "Attempting to recover from the transaction log file ", (string .sp.rt.logfile);
    num_chunks:-11! .sp.rt.logfile;
    .sp.log.info func, "Finished recovery from the transaction log file" (string .sp.rt.logfile);
  } ;

fail_me:{ ' "Failed for Debug" };

// tp_svc_ - service name of the TP, tp_inst_ - instance of TP svc to get data from
// hdb_path_ - must be a valid directory to save the RT data at the end of day
.sp.rt.setup: {[tp_svc_; tp_inst_; hdb_path_]
    func:"[.sp.rt.setup] : ";
    if[ 10h = type tp_svc_; tp_svc_:`$tp_svc_;];
    if[ 10h = type tp_inst_; tp_inst_:`$ tp_inst_;];
    if[ 10h = type hdb_path_; hdb_path_:`$ hdb_path_;];

    .sp.rt.hdb_path :: hdb_path_;

    .sp.log.debug func, "tp svc to subscribe to is" (raze string tp_svc_), ":", (raze string tp_inst_);

    if[null tp_svc_; msg:func, "Invalid TP service passed."; .sp.exception msg;];

    keep_looking: 1;
    while[ keep_looking;
        .sp.ns.client.wait_for_ever[tp_svc_; tp_inst_]; // without tp svc nothing can be done, so wait till we find it
        logfile: .sp.re.exec [tp_svc_; tp_inst_; ".sp.tp.get_logfile[]" ; .sp.consts[`DEF_EXEC_TO]];
        if [.sp.file.exists [logfile]; .sp.log.info "found the tp svc and have access to its log file :", (string logfile); keep_looking:0;];
        if[keep_looking > 0; .sp.log.info "waiting for svc ", (string tp_svc_); .sp.ns.client.sleep[.sp.consts[`DEF_SLEEP_PERIOD] ] ]; // sleep for 5 seconds
       ] ;

    .sp.log.debug func, "tp svc ", (string tp_svc_), ":", (string tp_inst_), " is up and running";
    // get the tables to subscribe for from tp svc and create them in rt
    tbls:.sp.re.exec[tp_svc_;tp_inst_; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    { [x;s;i]x set .sp.re.exec[s;i; x; .sp.consts[`DEF_EXEC_TO]]}[;tp_svc_; tp_inst_] each tbls;
    {update sym:`g#sym from x} each tbls where `sym in/: cols each tbls;

    // ASSUMPTION: funcs in schema_modify has to take no args and return nothing. Just modify the schema
    { [func_] @[func_; `; -1] } each schema_modify;
    schema_modify[];

    .sp.log.debug func, "this RT svc will subscribe to following tables:" ("," sv string each tbls);

    // get the replay log file to replay the transactions
    .sp.rt.logfile::.sp.re.exec[tp_svc_; tp_inst_; ".sp.tp.get_logfile[]"; .sp.consts[`DEF_EXEC_TO]] ;

    // replay the log file
    .sp.rt.replay_log[];

    // now subscribe to end of day notification when a new txn log file will be created
    .sp.re.exec[tp_svc_; tp_inst_; (`.sp.tp.subscibe_eod; .sp.rt.eod); .sp.consts[`DEF_EXEC_TO]];

    // now subscribe to all the tables from tp
    .sp.sub.subscribe[tp_svc_; tp_inst_; ; .sp.rt.def_subparams[] ] each tbls;
    .sp.log.info func, "subscribed to following tables: ", ("," sv string each tbls);

    .sp.rt.saved_to_hist:: (tbls)!( (count tbls)#0b);
    .sp.log.info func, "RT setup completed!";
  } ;

.sp.rt.set_hist_svc: {[svc_; inst_]
    .sp.rt.hist_svc_name::svc_;
    .sp.rt.hist_svc_inst::inst_;
  } ;

.sp.rt.on_comp_start: {[]
    func:"[.sp.rt.on_comp_start] : ";
    .sp.rt.saved_to_hist::0b;
    .sp.rt.last_upd:: ();
    .sp.rt.force_save_to_hist::0b;
    .sp.rt.bad_updates:: ();
    .sp.log.info func,"rt is ready now";
    :1b;
  } ;
.sp.comp.register_component[`rt;`svc; .sp.rt.on_comp_start];
