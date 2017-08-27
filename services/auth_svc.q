.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/services/fbm_dynamic.q");
.boot.include (gdrive_root, "/algo/model/model.q");
.boot.include (gdrive_root, "/framework/data_convert.q");
.boot.include (gdrive_root, "/services/schemas/model_results_schema.q"); // just to load the model_results tbl schema
.boot.include (gdrive_root, "/framework/cache.q");

.auth_svc.on_comp_start:{
    .auth_svc.features_rt:: `FEATURES_RT;
    .auth_svc.samples_rt:: `SAMPLES_RT;
    .auth_svc.users_rt:: `USERS_RT;
    .auth_svc.requests:: ([] request_id: `$(); uid: `$(); sid: `$(); token: `$(); recv: `datetime$(); send: `datetime$(); status: `int$(); gcm_reg_ids: (); p: `float$(); did: `$(); sample_id: `$(); extra_info: `$() );
    // .auth_svc.samples:: ();
    .auth_svc.states:: (`pending`completed`expired`rejected!`int$(0 1 2 3));
    .auth_svc.auth_request_timeout:: .sp.cfg.get_value[`auth_request_timeout;120];

    .auth_svc.load_historical_data[];

    .sp.cache.add_callback_handler[`auth_svc;.auth_svc.features_rt;`features;.auth_svc.on_update;.auth_svc.on_ready] ;
    // users
    .sp.cache.add_clients[.auth_svc.users_rt; `users; {[d;p] select by name from d}; {[t;p] select from (select by name from (value t)) where deleted = 0b}; `; `];
    .sp.cache.add_clients[.auth_svc.users_rt; `devices; {[d;p] select by user from d}; {[t;p] select from (select by user from (value t)) where deleted = 0b}; `; `];

    // samples
    .sp.cache.add_clients[.auth_svc.features_rt; `features; {[d;p] select from d}; {[t;p] select from (value t)}; `; `];
    .sp.cache.add_clients[.auth_svc.samples_rt; `samples; {[d;p] select from d}; {[t;p] select from (value t)}; `; `];
    .sp.cache.add_clients[.auth_svc.samples_rt; `sample_status; {[d;p] select by sample_id from d}; {[t;p] select from (select by sample_id from (value t)) where deleted = 0b}; `; `];

    .auth_svc.exp_timer: .sp.cron.add_timer[1000;-1;.auth_svc.invalidate_requests];
    :1b;
  };

.auth_svc.load_historical_data:{[]
    func: "[.auth_svc.load_historical_data]: ";
    .sp.log.info func, "loading data from hist...";
    users_hst: `USERS_HIST; // .sp.alias.get_svc[`users_hist];
    samples_hst: `SAMPLES_HIST; //.sp.alias.get_svc[`samples_hist];
    features_hst: `FEATURES_HIST; //.sp.alias.get_svc[`samples_hist];

    .sp.ns.client.wait_for_ever[`USERS_HIST; `];
    .sp.ns.client.wait_for_ever[`SAMPLES_HIST; `];
    .sp.ns.client.wait_for_ever[`FEATURES_HIST; `];

    wsize: .sp.cfg.get_value[`window_size;200];
    u:(); d:(); smpl_stat:(); f:(); s:();
    skip: 0b;

    // users
    tbls: .sp.re.exec[users_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    $[ -7h = type tbls; [.sp.log.info func, "no users hist found!"; skip:1b]; skip:0b];
    if[not skip;
    if[ `users in tbls;
        u: .sp.re.exec[users_hst;`;"delete date from select from (select by name from users) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
    // devices
    if[ `devices in tbls;
        d: .sp.re.exec[users_hst;`;"delete date from select from (select by user from devices) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ]; ];

    // sample_status
    tbls: .sp.re.exec[samples_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    $[ -7h = type tbls; [.sp.log.info func, "no users hist found!"; skip:1b]; skip:0b];
    if[not skip;
    if[ `sample_status  in tbls;
        smpl_stat: .sp.re.exec[samples_hst;`;"delete date from select from (select by sample_id from sample_status where valid = 1b) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
//    if[ (count smpl_stat) > wsize;
//        smpl_stat: (neg wsize)#smpl_stat];
    // samples
    if[ `samples in tbls;
        s: .sp.re.exec[samples_hst;`;"delete date from select from samples where sample_id in exec distinct sample_id from select by sample_id from sample_status where valid = 1b"; .sp.consts[`DEF_EXEC_TO]]  ];
    ];

    tbls: .sp.re.exec[features_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    $[ -7h = type tbls; [.sp.log.info func, "no users hist found!"; skip:1b]; skip:0b];
    if[not skip;
    if[ `features in tbls;
        sids: exec distinct sample_id from smpl_stat;
        f: .sp.re.exec[features_hst;`;({delete date from select from features where sample_id in x}; sids); .sp.consts[`DEF_EXEC_TO]]  ]; ];

    .sp.log.info func, "HIST user count: ", (raze string (count u));
    if[ (count u) > 0;
        .sp.cache.tables[`users]: u];
    .sp.log.info func, "HIST device count: ", (raze string (count d));
    if[ (count d) > 0;
        .sp.cache.tables[`devices]: d];
    .sp.log.info func, "HIST sample_status count: ", (raze string (count smpl_stat));
    if[ (count smpl_stat) > 0;
        .sp.cache.tables[`sample_status]: smpl_stat];
    .sp.log.info func, "HIST samples count: ", (raze string (count s));
    if[ (count s) > 0;
        .sp.cache.tables[`samples]: s];
    .sp.log.info func, "HIST features count: ", (raze string (count f));
    if[ (count f) > 0;
        .sp.cache.tables[`features]: f];
    .sp.log.info func, "Done loading historical data...";
    };

.auth_svc.on_ready:{[svc;topic]
    .sp.log.info "[.auth_svc.on_ready]: ", (raze string svc), " - ", (raze string topic);
    };

.auth_svc.invalidate_requests:{[t;i]
    func: "[.auth_svc.invalidate_requests]: ";
    .sp.log.spam func, "invalidating all requests older than " , (string (.z.Z - 00:00:30.000));
    rids: exec distinct request_id from .auth_svc.requests where recv <= (.z.Z - `second$(.auth_svc.auth_request_timeout)), status <> .auth_svc.states[`expired];
    .auth_svc.requests: update status: .auth_svc.states[`expired], p: 0f from .auth_svc.requests where request_id in rids;
    if[ (count rids) > 0; .auth_svc.update_request_tp[rids] ];
    };


.auth_svc.on_update:{[svc;topic;data; type_]
    func: "[.auth_svc.on_update]: ";
    .sp.log.info func, (string svc), ":", (string topic), ":", (string type_), " - row count = ", (string (count data));
    // do the auth, reutrn the result...
    last_upd:: data;

    if[ type_ = `recover;
      .sp.log.info func, "not procesing recovery updates for now...";
      :0b];

    samples: exec distinct sample_id from data where (0b = (null auth_token));
    {
        func: "[.auth_svc.on_update#1]: ";
        sid:: y;
        tkn: exec first auth_token from x where sample_id = sid;
        uid: exec first account_id from x where sample_id = sid;

        rids: exec distinct request_id from .auth_svc.requests where token = tkn;
        //if[ not sid in ( exec distinct sample_id from .auth_svc.requests where token = tkn, status < .auth_svc.states[`expired] );
        //    .sp.log.warn func, "sample received for EXPIRED or REJECTED request - not processing sample ", (raze string sid);
        //    :0b];

        .sp.log.info func, "Processing new sample ", (string sid);
        res: @[.auth_svc.process_new_sample;(select from x where sample_id = sid); {
                func: "[.auth_svc.on_update#2]: ";
                .sp.log.error func, "Failed to process new sample due to - ", (raze string x);
                :0b; }];

        fr: exec last fr from .sp.cache.tables[`users] where name = uid;
        passcount: exec first pass_n from res;
        .sp.log.info func, "Sample verification result: ", (string passcount), " with FR = ", (string fr);
        vld: exec first pass from res;

        // update the ticker-plant with sample status
        .sp.log.info func, "Updating the tickerplant with correcr status";
	    samples_tp: `SAMPLES_TP;

        smplstat:: select by sample_id from .sp.cache.tables[`sample_status] where sample_id = y;
        if[ (count smplstat) <= 0; .sp.log.error func, "Failed to locate sample status in cache! cannot update for ", (raze string y); ];
        sample_status:: smplstat lj (`sample_id xkey ([] time:(), .z.T; account_id:(),uid;  sample_id:(), sid; valid:(), vld; deleted: (), 0b));
	    cmd:: ( `.sp.tp.upd; `sample_status; 0!sample_status );

        .sp.re.exec[samples_tp;`;cmd;.sp.consts[`DEF_EXEC_TO]];
        .sp.log.info func, "Done updating tp";

        // update the status
        s: .auth_svc.states[`completed];
        // if[ vld = 1b; s: .auth_svc.states[`granted]];
        .sp.log.info func, "Setting local request status for auth token ", (string tkn), " to : ", (raze string s);
        p1: .sp.cfg.get_value [ `p1; 0.9 ];
        x1: .sp.cfg.get_value [ `x1; 5 ];
        p2: .sp.cfg.get_value [ `p2; 0.9 ];
        .auth_svc.requests: update status : s, p: .auth_svc.rank_result[p1;x1;p2;fr;passcount], sample_id: y from .auth_svc.requests where request_id in ((),rids);

        .auth_svc.update_request_tp[rids];
        .sp.log.info func, "auth request update complete for token ", (raze string tkn);
        } [data;] each samples;
    };

.auth_svc.reject_sample:{[data;cb]
    func:"[.auth_svc.reject_sample] : ";
    .sp.log.info func, "processing...";
    d:.sp.dc.de_serialize data;
    tkn: d[0];

    req: select by request_id from .auth_svc.requests where token = tkn;
    if[ (count req) <= 0;
        .sp.log.error func, "Failed to locate request for auth token: ", (raze string tkn);
         cb[ .auth_svc.reject[] ; .z.w]; :0b; ];

    if[ (last req)[`status] >= .auth_svc.states[`expired];
        .sp.log.error func, "Request is allready EXPIRED or REJECTED no need to reject again!";
         cb[ .auth_svc.reject[] ; .z.w]; :0b; ];

    rids: exec distinct request_id from req;
    .auth_svc.requests: update status: .auth_svc.states[`rejected], p: 0f from .auth_svc.requests where request_id in rids;
    if[ (count rids) > 0; .auth_svc.update_request_tp[rids] ];

    cb[ $[ret; .auth_svc.accept[]; .auth_svc.reject[]]; .z.w ];
    };

.auth_svc.process_new_sample:{[sample]
        func: "[.auth_svc.process_new_sample]: ";
        tmp_sample:: sample;
        token: exec last auth_token from sample;
        .sp.log.info func, "Validating new sample for auth_token: ", (string token);

        uid: exec first account_id from sample;
        sid: exec first sample_id from sample;
        wsize: .sp.cfg.get_value[`window_size;200];
        sample_ids: exec distinct sample_id  from .sp.cache.tables[`sample_status] where account_id = uid, valid = 1b, deleted = 0b;
	       // sample_ids : exec sample_id from (select by sample_id from .sp.cache.tables[`sample_status] where sample_id in sample_ids, valid = 1b);

        if[ ( (count sample_ids) > wsize);
             sample_ids: (neg wsize)#sample_ids];

        profile: 0!(select by sample_id from .sp.cache.tables[`features] where account_id = uid, sample_id in (sample_ids));
        if[ (count profile) = 0;
            .sp.log.error func, "Empty profile!";
            :0b];

        // fr:.sp.cfg.get_value [ `feature_req; 15];
        usr: (0!(select by name from .sp.cache.tables[`users] where name = uid, deleted = 0b));
        if[ (count usr) <= 0;
            .sp.log.error func, "User not found or deleted";
            :0b;];

        usr: usr[0];
        fr: usr[`fr];
        op: usr[`op];
        bp: usr[`bp];

        // now call train and verify and store the results in model results svc
        train:: .sp.model.train[profile;fr;op;bp];
        res:: .sp.model.verify[sample; fr; train];
        res:: update fr: usr[`fr], op: usr[`op], bp: usr[`bp], timegap_t: usr[`tm_gap_thresh], len_t: usr[`len_thresh], score_x1: 0.9, score_p1: 5.0, score_x2: 0.9 from res;
        // DO SOMETHING HERE ?????
        //train: update v: train[1], r: train[2], o: train[3], b: train[4] from train[0];
        mdl_res_tp:`MODEL_RESULTS_TP;
        cmd : ( `.sp.tp.upd; `train;  ([] time: enlist .z.T; account_id: enlist (first exec account_id from train[0]); raw: enlist (-8!train)) );
        .sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];
        cmd : ( `.sp.tp.upd; `verify; 0!update time:.z.T from (update sample_time: time from res) );
        .sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

        passcount: first exec pass_n from res;
        .sp.log.info func, "process new smmple complete: -  passcount: ", (raze string passcount), " and fr: ", (raze string fr);
        :res;
    };

// .auth_svc.validate_profile - takes in a table of samples, trains all of the samples and returs a true/false if the resulted variance
//is within the range
.auth_svc.validate_profile: { [sample_ids]
    func:"[.auth_svc.validate_profile] : ";
    .sp.log.info func, "processing...";
    samples: 0!(select by sample_id from .sp.cache.tables[`features] where sample_id in sample_ids);
    if[0 >= (count samples);
        .sp.log.error func, "failed to locate the samples requested";
        show sample_ids;
        :0b];

    outp:        .sp.cfg.get_value [ `user_op; 0.12];         // Default op for all users got from cfg
    bufp:        .sp.cfg.get_value [ `user_bp; 0.1];          // Default bp for all users got from cfg
    t_thresh:    .sp.cfg.get_value [ `user_tg_thresh; 50j];   // Default timegap threshold for all users got from cfg
    l_thresh:    .sp.cfg.get_value [ `user_ln_thresh; 20j];   // Default len theshold for all users got from cfg

    actid: first exec distinct account_id from .sp.cache.tables[`features] where sample_id in sample_ids;
    usr: select from .sp.cache.tables[`users] where name = actid, deleted = 0b;
    if[( (count usr) > 0 );
        outp: usr[`op];
        bufp: usr[`bp];
        t_thresh: usr[`tm_gap_thresh];
        l_thresh: usr[`len_thresh];
      ];

    // valid : .sp.model.validate_samples [samples];
    // .sp.log.info func, "validate samples returned : ", (raze string valid);
    // since validate profile gets called before user is created, have to get fr from cfg
    // if[ not valid; .sp.log.error func, "validate samples failed!"; :0b ];
    fr:.sp.cfg.get_value [ `feature_req; 15];
    thresh:.sp.cfg.get_value [ `threshold; 3f];
    // outp:.sp.cfg.get_value [ `outliner_p; 0.12f];
   //  bufp:.sp.cfg.get_value [ `buffer_p; 0.1f];

    r: .sp.model.train [samples; fr; outp; bufp];
    // ????????
    mdl_res_tp:`MODEL_RESULTS_TP;
    cmd : ( `.sp.tp.upd; `train;  ([] time: enlist .z.T; account_id: enlist (first exec account_id from r[0]); raw: enlist (-8!r)) );
    // cmd : ( `.sp.tp.upd; `train; 0!update time:.z.T from r );
    .sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

    if[ (type r[1]) in (98h;99h);
        .sp.log.debug func, "we have a table returned by train func";
        if[ `v in cols r[1];
            .sp.log.debug func, "the returned table has column v to compare threshold";
            // vss:asc exec v from r; ct:count vss;
            // if[ ct > fr; valid: vss[fr] < thresh;
            //    .sp.log.info func, "count of vss = ", (raze string ct), ", valid = ", (raze string valid), " vss[fr] = ", ( raze string vss[fr]), " and thresh = ", (raze string thresh);
            //    :valid ];
            vss: exec last v from r[1];
            :(vss < thresh);
        ] ];
    .sp.log.info func, "Validation Failed!";
    :0b; // Failure case here
  };

// .auth_svc.auth_request - takes in a data packet formatted as (user_id; device_id; sample_table) and validates the provided sample agains
//the users's profile
.auth_svc.auth_request:{ [data;cb]
    func:"[.auth_svc.auth_request] : ";
    .sp.log.info func, "processing...";
    tmp:: data;
    d::.sp.dc.de_serialize data;
    uid: d[0];
    did: d[1];
    c_at: d[2];
    sid: d[3];

    sample: 0!(select by sample_id from .sp.cache.tables[`features] where sample_id = sid);
    if[ 0 >= (count sample);
        .sp.log.error func, "failed to located the sample for ", (raze string sid);
        cb[ .auth_svc.reject[] ; .z.w]; :0b; ];

    // valid : .sp.model.validate_samples [sample];
    // .sp.log.info func, "validate samples returned : ", (raze string valid);
    // if[ not valid; .sp.log.error func, "validate samples failed!"; cb[.auth_svc.reject[]; .z.w]; :0b; ];

    wsize: .sp.cfg.get_value[`window_size;200];
//    sample_ids: exec distinct sample_id  from .sp.cache.tables[`samples] where account_id = uid;
    sample_ids : exec distinct  sample_id from .sp.cache.tables[`sample_status] where account_id = uid, valid = 1b, deleted = 0b;
    if[ (count sample_ids) > wsize;
         sample_ids: (neg wsize)#sample_ids];

    profile:: 0!(select by sample_id from .sp.cache.tables[`features] where account_id = uid, sample_id in (sample_ids));
    if[ (count profile) = 0;
        .sp.log.error func, "Empty profile!";
        cb[.auth_svc.reject[]; .z.w];
        :0b; ];


    //fr:.sp.cfg.get_value [ `feature_req; 15];
    usr: (0!(select by name from .sp.cache.tables[`users] where name = uid));
    if[ (count usr) <= 0;
        .sp.log.error func, "User not found or deleted";
        cb[.auth_svc.reject[]; .z.w];
        :0b;];

    usr: usr[0];
    fr: usr[`fr];
    op: usr[`op];
    bp: usr[`bp];

    // now call train and verify and store the results in model results svc
    train:: .sp.model.train[profile;fr;op;bp];
    res:: .sp.model.verify[sample; fr; train];
    res:: update fr: usr[`fr], op: usr[`op], bp: usr[`bp], timegap_t: usr[`tm_gap_thresh], len_t: usr[`len_thresh], score_x1: 0.9, score_p1: 5.0, score_x2: 0.9 from res;
    // DO SOMETHING HERE ?????
    //train: update v: train[1], r: train[2], o: train[3], b: train[4] from train[0];
    mdl_res_tp:`MODEL_RESULTS_TP;
    cmd : ( `.sp.tp.upd; `train;  ([] time: enlist .z.T; account_id: enlist (first exec account_id from train[0]); raw: enlist (-8!train)) );
    // cmd : ( `.sp.tp.upd; `train; 0!update time:.z.T from train );
    .sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];


    cmd : ( `.sp.tp.upd; `verify; 0!(update time:.z.T from (update sample_time: (first exec sample_time from sample) from res)) );
    .sp.re.exec[ mdl_res_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

    passcount: first exec pass_n from res;
    .sp.log.info func, "passcount = ", (raze string passcount), " Pass = ", (raze string (exec first pass from res));
    ret:(exec first pass from res);

    // insert the sample to samples_tp and also the sample status
    samples_tp : `SAMPLES_TP;
    smpl:update time:.z.T, auth_token:` from sample;
//    cmd: ( `.sp.tp.upd; `samples; smpl );
//    .sp.re.exec[ samples_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

    sid : first exec sample_id from smpl;
    smplstat: select by sample_id from .sp.cache.tables[`sample_status] where sample_id = sid;
    sample_status: smplstat lj (`sample_id xkey ([] time:(), .z.T; account_id:(),uid;  sample_id:(), sid; valid:(), ret));
    cmd: ( `.sp.tp.upd; `sample_status; 0!sample_status );
    .sp.re.exec[ samples_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

    cb[ $[ret; .auth_svc.accept[]; .auth_svc.reject[]]; .z.w ];
  };

// .auth_svc.authenticate - takes in a data packet formatted as (user_id; source_id;timeout), requests a sample from the user and replies once sample is returend or timeout reached.
.auth_svc.authenticate:{[uid;sid;extra]
    func: "[authenticate]: ";

    .sp.log.info func, "UID: ", (raze string uid), " | SID: ", (raze string sid), " | EXTRA: ", (raze string extra);
    .sp.log.info func, "validating user...";
    valid: uid in (exec distinct name from .sp.cache.tables[`users] where deleted = 0b);
    if[0b = valid;
        .sp.log.error func, "Unknown user: ", (raze string uid);
        .sp.exception "Unknown user: ",(raze string uid)];

    .sp.log.info func, "locating all devices...";
    //devices: .sp.re.exec[.auth_svc.users_rt;`;({select by user from devices where user = x};uid);.sp.consts[`DEF_EXEC_TO]];
    devices: select by user from .sp.cache.tables[`devices] where user = uid, deleted = 0b;
    if[ (not (type devices) in (99 98h)) or ((count devices) <= 0);
        .sp.log.error func, "Unable to locate devices for user ", (raze string uid);
        .sp.exception "Unable to locate devices for user ", (raze string uid)];

    .sp.log.info func, "extracting gcm ids...";
    gcm_ids:: last exec distinct gcm_reg_id from devices where gcm_reg_id <> `;
    if[ 1b = (null gcm_ids);
          .sp.log.error func, "GCM ID is NULL for the latest device for user ", (raze string uid);
          .sp.exception "Null GCM ID for user ", (raze string uid)];

    auth_token:: `$(string first -1?0ng);
    request_id: `$(string first -1?0ng); // different from auth token so cannot be sniffed...
    .sp.log.info func, "Generated new auth token: ", (raze string auth_token);
    .sp.log.info func, "Generated new request_id: ", (raze string request_id);
    `.auth_svc.requests insert (request_id; uid;sid;auth_token;.z.Z;.z.Z;.auth_svc.states[`pending]; gcm_ids;0f;gcm_ids;`; `$(raze string extra));
    .auth_svc.update_request_tp[request_id];
    .sp.log.info func, "Sending GCM request for a samplwe to ", (string count gcm_ids), " devices for user ", (raze string uid);
//    .auth_svc.publish_sample_request[uid;gcm_ids; auth_token; extra];
    : request_id;
    };

.auth_svc.publish_sample_request:{[uid;gcm_ids; auth_token; extra]
    func: "[.auth_svc.publish_sample_request]: ";

    .sp.log.info func, "Sending GCM request for auth token ", (raze string auth_token);
    // make packet
    packet:: (uid;auth_token; extra);
    api_key: .sp.cfg.get_value[`api_key;`$("AIzaSyDaLgwHG9Fa7gWRLtYGH4cdrIdfZ1in53g")];
    project_id: .sp.cfg.get_value[`project_id; `155670482643];

    // serialize
    .sp.log.info func, "Serializing packet...";
    data:: .sp.dc.serialize packet;
    pld:: .sp.dc.b64_enc[`long$data];
    // prepare cmd
    cmd:: gdrive_root, "/development/python/gcm_notify/send_update.sh --api_key ",(string api_key), " --project ", (string project_id);
    cmd:: cmd, (raze { " --reg_id ", (string x), " "} each gcm_ids);
    cmd:: cmd, " --param \"{\\\"type\\\":\\\"U2\\\",\\\"payload\\\":\\\"",(pld),"\\\"}\"";

    // send gcm
    .sp.log.info "Sending GCM update: [", cmd, "]";
    res: system cmd;
    .sp.log.info "GCM Update sent, result: ", (raze res);
    };

.auth_svc.check_request:{[rid]
    // s: last exec status from .auth_svc.requests where request_id = rid;
    // r: (key .auth_svc.states)[(value .auth_svc.states)?s];
    // p: last exec p from .auth_svc.requests where request_id = rid;

    func: "[.auth_svc.check_request]: ";
    .sp.log.info func, "Processing for ", (raze string rid);
    my_rid_tmp:: rid;
    // get the request data..
    sid: exec last sample_id from .auth_svc.requests where request_id = `$(raze string rid);
    res: raze exec last request_id, (key .auth_svc.states)[last status], last p from .auth_svc.requests where request_id = rid;

    // get the sample status data...
    stat: exec last account_id, last device_id, last gps_lat, last gps_long, last gps_time, first time from .sp.cache.tables[`sample_status] where sample_id = sid;

    uid: stat[`account_id];
    did: stat[`device_id];

    res: res, (stat[`account_id];stat[`device_id];stat[`gps_lat];stat[`gps_long];stat[`gps_time];stat[`time]);
    //: res;
    : `$("," sv (string res));
    };

.auth_svc.update_request_tp:{[rids]
    t: update time:.z.T from select from .auth_svc.requests where request_id in ((),rids);
    requests_tp: `REQUESTS_TP;
    cmd: (`.sp.tp.upd;`requests;t);
    .sp.re.exec[requests_tp;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    };

.auth_svc.security_rank:{ [data;cb]
    func:"[.auth_svc.security_rank] : ";
    .sp.log.info func, "processing...";
    d::.sp.dc.de_serialize data;
    uid: d[0];

    wsize: .sp.cfg.get_value[`window_size;200];
    sample_ids: exec distinct sample_id  from .sp.cache.tables[`samples] where account_id = uid;
    sample_ids : exec sample_id from (select by sample_id from .sp.cache.tables[`sample_status] where sample_id in sample_ids, valid = 1b, deleted = 0b);

     if[ ( (count sample_ids) > wsize);
        sample_ids: (neg wsize)#sample_ids];

    my_rank:(.auth_svc.get_rank[sample_ids; uid]);
    .sp.log.info func, "uid = ", (raze string uid), " and rank = ", (raze string my_rank);
    cb[ .sp.dc.serialize (enlist my_rank); .z.w ];
  };

.auth_svc.get_rank:{ [sample_ids;uid]
    func:"[.auth_svc.get_rank] : ";

    r: count sample_ids;
    if[ r > 100; r: 100];
    :`$(string r);

  };

// d[0] is uid, d[1] = sample_ids. samples will allready be in the TP. have to validate each sample then if its valid, update the status correctly
// then at the end, compute a new rank... and return the new rank or exception..
.auth_svc.add_signs_batch: { [data;cb]
    func : "[.auth_svc.add_signs_batch] : ";
    d::.sp.dc.de_serialize data;
    uid: d[0];
    sample_ids:d[1]; // list of sample ids

    {[sid; uid]
        valid: .auth_svc.validate_profile[sid]; // BUG HERE!! - this should do VERIFY NOT VALIDATE!!
        .sp.log.info func, "updating sample state for sample_id = ", (raze string sid), " for user = ", (raze string uid), " and valid = ", (raze string valid);
        cmd: (`.sp.sfg.update_state; sid;uid;valid);
        samples_fh: `SAMPLES_FH;
        res: .[.sp.re.exec;(samples_fh;`;cmd; .sp.consts[`DEF_EXEC_TO]); {.sp.exception "exception when setting sample state due to - ", (raze string x)}];
        if[ 0b = res; .sp.exception "Failed to update the profile state"];
        .sp.log.info func, "done updating state.";
    }[;uid] each sample_ids;

    sample_ids : exec sample_id from (select by sample_id from .sp.cache.tables[`sample_status] where sample_id in sample_ids, valid = 1b, deleted = 0b);
    my_rank:(.auth_svc.get_rank[sample_ids; uid]);
    .sp.log.info func, "uid = ", (raze string uid), " and rank = ", (raze string my_rank);
    cb[ .sp.dc.serialize (enlist  my_rank) ; .z.w ];
  };

.auth_svc.reject:{ .sp.dc.serialize (enlist `false) };
.auth_svc.accept:{ .sp.dc.serialize (enlist `true) };

.auth_svc.rank_result:{[p1;x1;p2;x2;fp]
    func: "[.auth_svc.rank_result]: ";
    .sp.log.info func, "Ranking result for ", ( "-" sv string (p1;x1;p2;x2;fp));
    k: (2*(log(((neg p1)-1)%(p1-1)))%x1);
    x0: ((log(((neg p2) + 1)*(exp (k*x2))%p2))%k );
    :100 * (1%(1+(exp((neg k)*(fp - x0)))));
    };

.auth_svc.update_simulation_results:{[rid;flag]
    func: "[.auth_svc.update_simulation_results]: ";

    atoken: first exec auth_token from .auth_svc.requests where request_id = rid;
    if[null atoken; .sp.exception "cant find token"];

    sid: first exec sample_id from .sp.cache.tables[`samples] where auth_token = atoken;
    if[null sid; .sp.exception "cant find sid"];

    .sp.log.info func, "Updating user resutls TP...";
    cmd: (`.sp.tp.upd;`user_results;([] time: (),.z.T; request_id: (), rid; status: (), flag; sample_id: (), sid; auth_token: (), atoken));
    .sp.re.exec[`SAMPLES_TP;`;cmd;.sp.consts[`DEF_EXEC_TO]];

    };

.sp.comp.register_component[`auth_svc;`cache`common;.auth_svc.on_comp_start];


