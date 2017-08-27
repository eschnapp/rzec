.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");
.boot.include (gdrive_root, "/services/fbm_dynamic.q");
.boot.include (gdrive_root, "/algo/model/model.q");

.bfg.on_comp_start:{
    func: "[.bfg.on_comp_start]: ";
    .sp.cache.tbl_names:: ()!();
    :1b;
    };

.prv.get_disco: { [remote_ns; remote_zone]
    h : hopen remote_ns;
    disco: h (`.sp.ns.server.discover_all;  remote_zone);
    hclose h;
    :disco;
  };

.prv.get_users: { [remote_host; remote_port; ctx]
    h : hopen hsym `$ ( (string remote_host),":", (string remote_port) );
    users: h ("select from (select by name from users) where deleted = 0b");
    hclose h;
    if[ `include_users in key ctx; users: select from users where name in ctx`include_users ];
    if[ `exclude_users in key ctx; users: delete from users where name in ctx`exclude_users ];
    :users;
  };

.prv.get_samples: { [remote_host; remote_port; uids]
    h : hopen hsym `$ ( (string remote_host),":", (string remote_port) );
    smpl_status: h ({select from (select by sample_id from sample_status where account_id in x) where deleted = 0b};uids);
    samples: h ({select from samples where sample_id in exec sample_id from (select by sample_id from sample_status where account_id in x) where deleted = 0b }; uids);
    hclose h;
    :samples;
  };

.prv.get_remote_verify: { [uids; ctx ]
    disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];
    remote_MR_RT: exec last address, last port from disco where svc=`MODEL_RESULTS_RT;
    remote_MR_HIST: exec last address, last port from disco where svc=`MODEL_RESULTS_HIST;

    h : hopen hsym `$ ( (string remote_MR_HIST`address),":", (string remote_MR_HIST`port) );
    verifyH: h ( { :select last pass, last pass_n, last v, last account_id  by sample_id from verify where account_id in x}; uids);
    hclose h;
    h : hopen hsym `$ ( (string remote_MR_RT`address),":", (string remote_MR_RT`port) );
    verifyRT: h ( { :select last pass, last pass_n, last v  by sample_id from verify where account_id in x}; uids);
    :verify: verifyRT, verifyH;
  };


// ctx is a dictionary
// eg: ctx: (`target_ns`target_zone`test`global_overrides)!(`$":research.c.forget-your-passwords.internal:23400:";`research;222j;`op`bp`fr`len_thresh`tm_gap_thresh!(0.3;0.2;20;30;50) )
// ctx[`user_overrides]: ([ name: (`$"1@1";`$"aa@aa11")]; bp: 0.1 0.2f; op: 0.3 0.4f; len_thresh: 50 60; auto_calib: 2#1b)
// ctx[`include_users] : `$"etay@12";
.bfg.start_whatif: { [ctx]
    func: "[.bfg.start_whatif] : ";
    need: `target_ns`target_zone;
    passed: key ctx;
    if[ not all need in passed; .sp.exception func, "not all required params in the context passed" ];
   
    .sp.log.info func, "Discovering target system services...";
     disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];

    remote_usrs_rt: exec last address, last port from disco where svc=`USERS_RT;
    remote_usrs_hist: exec last address, last port from disco where svc=`USERS_HIST;

    .sp.log.info func, "Getting current and historical active users from remote system...";
    users_r:: .prv.get_users [ remote_usrs_rt[`address]; remote_usrs_rt[`port]; ctx ];
    users_h:: .prv.get_users [ remote_usrs_hist[`address]; remote_usrs_hist[`port]; ctx ];

    .bfg.users:: select by name from ((delete date from users_h) , users_r);
    
    // process overrides if any...
    
    // global_overides should be a dictionary of param name and param value (same as col names in users table)
    // for example: ctx[`global_overrides]: `op`bp`fr`len_thresh`tm_gap_thresh!(0.3;0.2;20;30;50)
    if[ `global_overrides in passed;
        .sp.log.info func, "Applying global overrides...";
        .bfg.users:: ![.bfg.users;();0b;ctx[`global_overrides]] ];

    // user overrides sholud be a table keyed by col name with overrides in cols same as users table
    // for example: ctx[`user_overrides]: ([ name: `user1`user2]; bp: 0.1 0.2f; op: 0.3 0.4f; len_thresh: 50 60)
    if[ `user_overrides in passed ;
        .sp.log.info func, "Applying user specific overrides...";
        uo: delete auto_calib from ctx[`user_overrides];
        .bfg.users:: .bfg.users lj (`name xkey uo)    ];
  

    .bfg.clear_cache[`users];
    .bfg.clear_cache[`samples];
    .bfg.clear_cache[`sample_status];
    .bfg.clear_cache[`features];
    .bfg.clear_cache[`train];
    .bfg.clear_cache[`verify];

    // now insert the users into the cache...
    .bfg.cache_upsert[`users; .bfg.users];

    // we can now process the whatif for each user...
    .sp.log.info func, "Processing user-level whatif profile data....";
    .bfg.process_user [; ctx] each (exec distinct name from .bfg.users);

    // whatif is complete now need to review the results........
  };

.bfg.process_user: { [user_id; ctx] 
    func: "[.bfg.process_user]: ";
    if[null user_id; :0];
    
    .sp.log.info func, "Clearing all caches before new user process starts...";
    smpl_arrival::()!(); // dictionary to hold sample ids arrival

    .sp.log.info func, "Discovering target system services...";
     disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];

    remt_smpls_rt: exec last address, last port from disco where svc=`SAMPLES_RT;
    remt_smpls_hist: exec last address, last port from disco where svc=`SAMPLES_HIST;

    .sp.log.info func, "Getting current and historical active users from remote system...";
    smpls_r: .prv.get_samples [ remt_smpls_rt[`address]; remt_smpls_rt[`port]; user_id ];
    smpls_h: .prv.get_samples [ remt_smpls_hist[`address]; remt_smpls_hist[`port]; user_id ];
    .bfg.samples:: smpls_r, delete date from smpls_h;
    // processing a user...
    // 1. get the samples for this users from remote system
    // 2. sort the results based on sample time ( created_at and time_index)
    // 3. upd into samples_to by time unit from sample_status

    cur_context:: ctx; // For use in do_request

    tsort: `created_at xasc select last created_at, last  sample_type by sample_id from .bfg.samples;
    regs: select from tsort where sample_type = `REGISTRATION;
    if[ 11 < count regs; .sp.exception func, "Num of registration samples can NOT exceed 11. We need to have 11 or less registration samples" ];
    sids_reg: (0!select by created_at from regs)`sample_id;    
    { [sid;uid]
	.sp.log.info "[.bfg.process_user]: Updating status for REGISTRATION sample: ", (string sid);
        sample: `time_index xasc select from .bfg.samples where sample_id = sid;
	//.bfg.update_state[sid;uid; 1b]; 
        .bfg.sample_update sample;
    }[; user_id] each sids_reg; 

    .sp.log.info func, "REGISTRATION samples completed!";

    if[ 11 = count regs; 
        dup_created_at : exec first created_at from (select ct: count i by created_at from regs) where ct = 2;
        sid_def_login: exec first sample_id from tsort where created_at = dup_created_at, not sample_id in sids_reg;
        { [sid]
            sample: `time_index xasc select from .bfg.samples where sample_id = sid;
	    .sp.log.info "[.bfg.process_user]: Updating status for AUTO LOGIN sample: ", (string sid);
	    smpl_arrival[sid]: 0b;
            .bfg.sample_update sample;
        } each sid_def_login 
    ];
    show smpl_arrival;
    .sp.log.info func, "AUTO LOGIN samples completed!";
    
    all_other_smpls:: select from .bfg.samples where not sample_id in (sids_reg,sid_def_login);

    a: asc exec distinct created_at from all_other_smpls;
    { [ca] 
        sids: exec distinct sample_id from all_other_smpls where created_at = ca;
        { [sid]
            sample: `time_index xasc select from .bfg.samples where sample_id = sid;
	    .sp.log.info "[.bfg.process_user]: Updating status for all other samples - : ", (string sid);
	    smpl_arrival[sid]: 0b;
            .bfg.sample_update sample;
        } each sids; 
    } each a;

    .sp.log.info func, "completed!";
  };
    
.bfg.sample_update:{[smpl]
    func: "[.bfg.sample_update]: ";
    samples_tp : `SAMPLES_TP;

    sid : first smpl`sample_id;
    uid : first smpl`account_id;
    did : first smpl`device_id;
    .sp.log.info func, "Processing sample update for ", (string sid);

   sample_status: ([] time:(count sid)#.z.T; account_id:(count sid)#uid;  sample_id: sid; device_id: (count sid)#did; valid:(count sid)#0b; deleted:(count sid)#0b);
    //cmd: ( `.sp.tp.upd; `sample_status; sample_status );
    .sp.log.info func, "updating stample status table";
    //.sp.re.exec[ `SAMPLES_TP; `; cmd; .sp.consts[`DEF_EXEC_TO] ];
    .bfg.cache_upsert[`sample_status; `sample_id xkey sample_status];
    smpl:update time:.z.T from smpl;
    // Now check if smpl has all columns that are needed to populate the table
    cols_needed: `account_id`sample_id`device_id`time_index`stroke_index`x`y;
    if[ not all cols_needed in cols smpl; msg: func, "All columns required to populate samples table dont exist!"; .sp.log.error msg; .sp.exception msg ];
    //cmd: ( `.sp.tp.upd; `samples; smpl );
    .sp.log.info func, "Updating samples tickerplant";
    //.sp.re.exec[ `SAMPLES_TP; `; cmd; .sp.consts[`DEF_EXEC_TO] ];
    .bfg.cache_insert[`samples; smpl];
    // extract features...
    .bfg.fex[smpl];
   // process the request...
    .sp.log.info func, "processing model... sid = ", (raze string sid);
    if[ not sid in key smpl_arrival;
        .sp.log.info func, "not in sample arrival.. will auto update state...";
        .bfg.update_state[sid;uid;1b];
	:1b;
	];
    if[ smpl_arrival[sid] <> 1b;
	.bfg.auth_request[sid];
	];
    smpl_arrival[sid]: 1b;
    .sp.log.info func, "DONE sample update for SID: ", (raze string last sid);
  };

.bfg.auth_request:{ [sid]
    func: "[.bfg.auth_request] : ";
    .sp.log.info func, "starting...";
    data: select from .sp.cache.tables.features where sample_id in (sid);
    .sp.log.info func, "Data count sent to auth request: ", (string count data), " rows and " (string count exec distinct sample_id from data), " samples...";
    .bfg.do_request[data];
    };

//.bfg.featue_upd:{ [svc;topic;data; type_]
//    func: "[.bfg.feature_upd] : ";
//    sid: exec first sample_id from data;
//    uid: exec first account_id from data;
//    .sp.log.info func, "starting... sid = ", (raze string sid);
//    if[ not sid in key smpl_arrival;
//        .sp.log.info func, "not in sample arrival.. will auto update state...";
//        .bfg.update_state[sid;uid;1b];
//	:1b;
//	];
//    if[ smpl_arrival[sid] = 1b;
//	.bfg.auth_request[svc;topic;data; type_];
//	];
//    smpl_arrival[sid]: 1b;
//    // $[ sid in key smpl_arrival; .bfg.auth_request[svc;topic;data; type_]; smpl_arrival[sid]:1b ];
//    //show smpl_arrival;
// };

//.bfg.sample_upd:{ [svc;topic;data; type_]
//    func: "[.bfg.sample_upd] : ";
//    sid: exec first sample_id from data;
//    uid: exec first account_id from data;
//    .sp.log.info func, "starting... sid = ", (raze string sid);
//    if[ not sid in key smpl_arrival;
//        .sp.log.info func, "not in sample arrival.. will auto update state...";
//        .bfg.update_state[sid;uid;1b];
//        :1b;
//        ];
//    if[ smpl_arrival[sid] = 1b;
//        .bfg.auth_request[svc;topic;data; type_]; 
//        ];
//    smpl_arrival[sid]: 1b;
//    // $[ sid in key smpl_arrival; .bfg.auth_request[svc;topic;data; type_]; smpl_arrival[sid]:1b ];
//    //show smpl_arrival;
// };

.bfg.do_request:{ [data]
    func:"[.bfg.do_request] : ";
    .sp.log.info func, "BEGIN: processing...";

    .sp.log.info func, "COUNT OF SAMPLES IN DATA: ", (string count (select distinct sample_id from data));
    sample: 0!(select by sample_id from data);
    sid: exec last sample_id from data;
    uid: exec last account_id from data;

    stp:: (exec last sample_type from .sp.cache.tables[`samples] where sample_id = (exec last sample_id from sample));
    .sp.log.info func, "processing. sid: ", (string sid), " and uid: ", (string uid), " stype - ", (string stp);


    if[ 0 >= (count sample);
        .sp.log.error func, "failed to located the sample for ", (raze string sid);   :0b];

    wsize: .sp.cfg.get_value[`window_size;200];
    sample_ids : exec distinct  sample_id from .sp.cache.tables[`sample_status] where account_id = uid, valid = 1b, deleted = 0b;
    if[ (count sample_ids) > wsize;
         sample_ids: (neg wsize)#sample_ids];

    profile:: 0!(select by sample_id from .sp.cache.tables[`features] where account_id = uid, sample_id in (sample_ids));
    if[ (count profile) = 0;
        .sp.log.error func, "Empty profile!";
        .sp.exception func, "Empty profile..." ];

    .sp.log.info func, "Step 1.. After profile check!";

    usr: (0!(select by name from .sp.cache.tables[`users] where name = uid));
    if[ (count usr) <= 0;
        .sp.log.error func, "User not found or deleted";
        :0b;];

    .sp.log.info func, "Step 2..!";
    usr: usr[0];
    fr: usr[`fr];
    op: usr[`op];
    bp: usr[`bp];

    // now call train and verify and store the results in model results svc
    train:: .sp.model.train[profile;fr;op;bp];
    res:: .sp.model.verify[sample; fr; train];
    res:: update fr: usr[`fr], op: usr[`op], bp: usr[`bp], timegap_t: usr[`tm_gap_thresh], len_t: usr[`len_thresh], score_x1: 0.9, score_p1: 5.0, score_x2: 0.9 from res;
    
    //train: update v: train[1], r: train[2], o: train[3], b: train[4] from train[0];
    //mdl_res_tp:`MODEL_RESULTS_TP;
    //cmd : ( `.sp.tp.upd; `train;  ([] time: enlist .z.T; account_id: enlist (first exec account_id from train[0]); raw: enlist (-8!train)) );
    // cmd : ( `.sp.tp.upd; `train; 0!update time:.z.T from train );
    //.sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];
    //cmd : ( `.sp.tp.upd; `verify; 0!(update time:.z.T from (update sample_time: (first exec sample_time from sample) from res)) );
    //.sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

    .bfg.cache_insert[`train; ([] time: enlist .z.T; account_id: enlist (first exec account_id from train[0]); raw: enlist (-8!train))];
    .bfg.cache_insert[`verify;0!(update time:.z.T from (update sample_time: (first exec sample_time from sample) from res))];

    passcount: first exec pass_n from res;
    .sp.log.info func, "passcount = ", (raze string passcount), " Pass = ", (raze string (exec first pass from res));
    ret:(exec first pass from res);
    .bfg.update_state[sid; uid; ret];

    .bfg.calibrate[uid];
    .sp.log.info func, "completed...";
  };

.bfg.update_state:{[sid;uid;state]
    update valid:state from `.sp.cache.tables.sample_status where sample_id = sid, account_id = uid;
    :1b;
    };

.bfg.cache_insert:{[tbl;data]
    func: "[.bfg.cache_insert]: ";
    .sp.log.info func, "Cache INSERT - TBL [", (raze string tbl), "] ROWS: ", (string count data);
    .sp.cache.tbl_names[tbl] : `$(".sp.cache.tables.", (string tbl));
    .sp.cache.tbl_names[tbl] insert data;
    };

.bfg.cache_upsert:{[tbl;data]
    func: "[.bfg.cache_upsert]: ";
    .sp.log.info func, "Cache UPSERT - TBL [", (raze string tbl), "] ROWS: ", (string count data);
    .sp.cache.tbl_names[tbl] : `$(".sp.cache.tables.", (string tbl));
    .sp.cache.tbl_names[tbl] upsert data;
    };

.bfg.clear_cache:{[tbl]
    func: "[.bfg.cache_clear]: ";
    .sp.log.info func, "Cache CLEAR - TBL [", (raze string tbl), "]";
    if[ tbl in key .sp.cache.tbl_names;  delete from .sp.cache.tbl_names[tbl] ];
    };

.bfg.fex:{ [data]
    func: "[.bfg.fex]: ";
    //extract the features
    if[ .sp.model.validate_samples[data] = 0b;
        .sp.log.error func, "Validate sample failed for samples ", (raze string (exec distinct sample_id from data));
        :0b];

    tg_thresh: .sp.cfg.get_value [ `user_tg_thresh; 50j];   // Default timegap threshold for all users got from cfg
    ln_thresh: .sp.cfg.get_value [ `user_ln_thresh; 20j];   // Default len theshold for all users got from cfg

    // if usr exist, override from usr defaults...
    usr: 0!(select from (select by name from .sp.cache.tables[`users]) where name = (exec first account_id from data), deleted = 0b);
    if[ (count usr) > 0;
        tg_thresh: first usr[`tm_gap_thresh];
        ln_thresh: first usr[`len_thresh];
      ];

    f::  update sample_time: time, auth_token: (first exec auth_token from data) from .sp.model.extract_feature[data;tg_thresh;ln_thresh];
    
    //update features tp with the data...
    .sp.log.info func, "Updating extracted featured into features cache...";
    .bfg.cache_insert[`features;0!(update time: .z.T from update sample_time:time from f)];
    };

.bfg.calibrate: { [usr]
    func: "[.bfg.calibrate]: ";
    ctx: cur_context;
    do_calib : 0b;
    if[ `user_overrides in key ctx;
        if[ any (98 99h) in type ctx[`user_overrides];
            ct: exec count name from ctx[`user_overrides] where name = usr, auto_calib=1b;
            if[ 0 < ct; do_calib: 1b; .sp.log.info func, "Will do auto_calib now. auto_calib override present for user ", (string usr) ] ;
            ] ];
    if[ 0b = do_calib; .sp.log.info func, "Will NOT do auto calibration to the user : ", (string usr); :0b ];

    usrs: select from (select by name from .sp.cache.tables.users) where name = usr, deleted = 0b;
    sst: select from (select by sample_id from .sp.cache.tables.sample_status where account_id = usr) where deleted = 0b;
    sst: update num_valid: (count i ) by account_id from sst where valid = 1b;
    sst: update num_total: (count i ) by account_id from sst;
    sst: update num_valid: 0^num_valid, num_total: 0^num_total from sst;
    sst: update wnd_size: 0^num_valid from sst;
    sst: update fail_rate: num_valid%num_total from sst;
    registration_sample_size : 10;
    sst: update op : max(0; 0.12 - fail_rate * max(1; wnd_size%num_total) ) from sst;
    sst: update bp : 0.1 + fail_rate + registration_sample_size % num_total from sst;
    final: `name xkey select distinct name:account_id, op, bp from sst;
    new_usr_prms:usrs lj final; 

    .sp.log.info func, "Modified user info will be written to users cache... Count = ", (raze string (count new_usr_prms));    
    .bfg.cache_upsert[`users; `name xkey new_usr_prms];

    .sp.log.info func, "Calibration complete!";
    :`name xkey new_usr_prms;
  };

.sp.comp.register_component[`whatif;`cache`common;.bfg.on_comp_start];
