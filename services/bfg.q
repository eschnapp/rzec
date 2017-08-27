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
    h : hopen  remote_ns;
    disco: h (`.sp.ns.server.discover_all;  remote_zone);
    hclose h;

    disco  : update address: string address from disco;

    disco:update address: ssr[; "spprod1.1p42rf20a2ke1hunx12ug4ii4f.bx.internal.cloudapp.net"; "sp-prod1.eastus.cloudapp.azure.com"] each address from disco;
    disco: update address: ssr[; "10.1.0.4"; "sp-prod1.eastus.cloudapp.azure.com"] each address from disco;

    disco:update address: ssr[; "spdev1.kvv1gdjeswhexdw0vrbl5vntoc.bx.internal.cloudapp.net"; "sp-dev1.eastus.cloudapp.azure.com"] each address from disco;
    disco: update address: ssr[; "10.0.0.4"; "sp-dev1.eastus.cloudapp.azure.com"] each address from disco;

    :disco;
  };

.prv.get_users: { [remote_host; remote_port; ctx]
    h : hopen hsym `$raze ( (string remote_host),":", (string remote_port) );
    users: h ("select from (select by name from users) where deleted = 0b");
    hclose h;
    if[ `include_users in key ctx; users: select from users where name in ctx`include_users ];
    if[ `exclude_users in key ctx; users: delete from users where name in ctx`exclude_users ];
    :users;
  };

.prv.get_samples: { [remote_host; remote_port; uids]
    h : hopen hsym `$ raze( (string remote_host),":", (string remote_port) );
    smpl_status: h ({select from (select by sample_id from sample_status where account_id in x) where deleted = 0b};uids);
    samples: h ({select from samples where sample_id in exec sample_id from (select by sample_id from sample_status where account_id in x) where deleted = 0b }; uids);
    hclose h;
    :samples;
  };

.prv.get_remote_features: { [sids; ctx ]
    disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];
    remote_FEAT_RT: exec last address, last port from disco where svc=`FEATURES_RT;
    remote_FEAT_HIST: exec last address, last port from disco where svc=`FEATURES_HIST;

    h : hopen hsym `$raze ( (string remote_FEAT_HIST`address),":", (string remote_FEAT_HIST`port) );
    featH: h ( { :select from features where sample_id in x}; sids);
    hclose h;
    h : hopen hsym `$raze ( (string remote_FEAT_RT`address),":", (string remote_FEAT_RT`port) );
    featRT: h ( { :update date:.z.d from select from features where sample_id in x}; sids);
    :features: featRT, featH;
  };

.prv.get_remote_verify: { [uids; ctx ]
    disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];
    remote_MR_RT: exec last address, last port from disco where svc=`MODEL_RESULTS_RT;
    remote_MR_HIST: exec last address, last port from disco where svc=`MODEL_RESULTS_HIST;

    h : hopen hsym `$ raze ( (string remote_MR_HIST`address),":", (string remote_MR_HIST`port) );
    verifyH: h ( { :select by sample_id from verify where account_id in x}; uids);

    hclose h;
    h : hopen hsym `$raze ( (string remote_MR_RT`address),":", (string remote_MR_RT`port) );
    verifyRT: h ( { :update date:.z.d from select by sample_id from verify where account_id in x}; uids);
    verifyRT: `sample_id xkey `sample_id`date xcols 0!verifyRT;
    :verify: verifyRT, verifyH;
  };

// ctx is a dictionary
//ctx: (`target_ns`target_zone`op_values`bp_values`fr_values)!(`$":sp-prod1.eastus.cloudapp.azure.com:23400:";`prod; (0.12 0.15f); (0.1 0.3f); (15 18) );
//ctx[`include_users] : `$"batel@atp";
.bfg.start_bfg: { [ctx]
    func: "[.bfg.start_bfg] : ";
    need: `target_ns`target_zone`op_values`bp_values`fr_values;
    passed: key ctx;
    if[ not all need in passed; .sp.exception func, "not all required params in the context passed" ];
   
    .sp.log.info func, "Discovering target system services...";
     disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];

    remote_usrs_rt: exec last address, last port from disco where svc=`USERS_RT;
    remote_usrs_hist: exec last address, last port from disco where svc=`USERS_HIST;

    .sp.log.info func, "Getting current and historical active users from remote system...";
    users_r: .prv.get_users [ remote_usrs_rt[`address]; remote_usrs_rt[`port]; ctx ];
    users_h: .prv.get_users [ remote_usrs_hist[`address]; remote_usrs_hist[`port]; ctx ];

    .bfg.users:: select by name from ((delete date from users_h) , users_r) where not null name;
    // get the complete fr op bp data cross joined with users
    .bfg.input:: (select distinct name from .bfg.users) cross ( [] fr: (), ctx`fr_values) cross ( [] op: (), ctx`op_values) cross ( [] bp: (), ctx`bp_values);

    .bfg.clear_cache[`users];
    .bfg.clear_cache[`samples];
    .bfg.clear_cache[`sample_status];
    .bfg.clear_cache[`features];
    .bfg.clear_cache[`train];
    .bfg.clear_cache[`verify];

    // now insert the users into the cache...
    .bfg.cache_upsert[`users; .bfg.users];

    verify: .prv.get_remote_verify[exec distinct name from .bfg.users; ctx];
    .bfg.cache_upsert[`verify; verify];


    // we can now process the whatif for each user...
    .sp.log.info func, "Processing user-level profile data....";
    .bfg.input:: update ctx: (count .bfg.input)#enlist ctx from .bfg.input;
//    show .bfg.input;

    .bfg.process_user ./:flip value flip .bfg.input;

    // whatif is complete now need to review the results........
    r: .bfg.save_to_file[];
    .sp.log.info func, "All done. Saved result to ", (raze string r);
  };

.bfg.process_user: { [u; fr; op; bp; ctx] 
    func: "[.bfg.process_user]: ";
    .sp.log.info func, "starting : user [", (string u), "], fr [", (string fr), "], op [", (string op), "], bp [", (string bp), "]";
    .bfg.clear_cache[`samples];
    .bfg.clear_cache[`features];

    disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];
    remt_smpls_rt: exec last address, last port from disco where svc=`SAMPLES_RT;
    remt_smpls_hist: exec last address, last port from disco where svc=`SAMPLES_HIST;
    .sp.log.info func, "Getting current and historical active samples from remote system...";
    smpls_r: .prv.get_samples [ remt_smpls_rt[`address]; remt_smpls_rt[`port]; u ];
    smpls_h: .prv.get_samples [ remt_smpls_hist[`address]; remt_smpls_hist[`port]; u ];
    .bfg.samples: (update date:.z.d from smpls_r), smpls_h;
    .bfg.cache_upsert[`samples; .bfg.samples];

    sids: select distinct sample_id from .sp.cache.tables.samples where sample_type <> `REGISTRATION, account_id = u;
    features: .prv.get_remote_features[sids`sample_id; ctx];
    .bfg.cache_upsert[`features; features];
    
    fs_data:: sids lj select last fs by sample_id from .sp.cache.tables.verify where account_id = u;
    .sp.log.info func, "count fs_data =  ", (string (count fs_data));
    .bfg.process_sample[fr;op;bp;] each fs_data;
  };

.bfg.process_sample: { [fr;op;bp;fs_data] 
    func: "[.bfg.process_sample]: ";
    .sp.log.info func, "starting : fr [", (string fr), "], op [", (string op), "], bp [", (string bp), "]";
   // if[ op > bp; .sp.log.info func, "op > bp. Exiting"; :0];
    profile:: select from .sp.cache.tables.features where sample_id in fs_data[`fs];
    $[ 0 = count profile; [.sp.log.info func, "Empty profile data"; :0]; .sp.log.info func, "count profile = ", (string (count profile)) ];
    target:: select from .sp.cache.tables.features where sample_id in fs_data[`sample_id];
   
//    train:: .sp.model.train[profile;fr;op;bp];
//    show train;
    train:: .[.sp.model.train; (profile;fr;op;bp); { .sp.log.error "[.bfg.process_sample] : train failed due to : ", (raze string x); :-1 } ];
    if[ (type -1) = (type train); :0];

    .sp.log.info func, "will start verify now!";
//    res:: .sp.model.verify[target;fr;train];
    res:: .[.sp.model.verify; (target;fr;train); { .sp.log.error "[.bfg.process_sample] : verify failed due to : ", (raze string x); :-1 } ];
    if[ (type -1) = (type res); :0];

    `all_data insert (update fr: fr, op: op, bp: bp from res);
    all_data :: all_data lj select last date by sample_id from .sp.cache.tables.samples;

    // write result to big table of resutlst....
    .sp.log.info func, "completed. Verify returned rows = ", (string count res);
  };


///  BFG2 code starts here
.prv.bfg2.get_random_users: { [remote_host; remote_port; ctx]
    h : hopen hsym `$raze ( (string remote_host),":", (string remote_port) );
    users: h ("select from (select by name from users) where deleted = 0b");
    hclose h;
    if[ `include_users in key ctx; users: select from users where not name in ctx`include_users ];
    if[ `rndm_users in key ctx; users: select from users where name in ctx`rndm_users];
    if[ `rndm_smpl_count in key ctx; users: 1! (2*ctx`rndm_smpl_count)?0!users ];
    :users;
  };

.prv.bfg2.get_random_smpls: { [remote_host; remote_port; uids]
    h : hopen hsym `$ raze( (string remote_host),":", (string remote_port) );
    smpl_status: h ({select from (select by sample_id from sample_status where account_id in x) where deleted = 0b};uids);
    samples: h ({select from samples where sample_id in exec sample_id from (select by sample_id from sample_status where account_id in x) where deleted = 0b }; uids);
    hclose h;
    :select by account_id from select from samples where not sample_type in `REGISTRATION`UNDEFINED, not null account_id;
  };

.prv.bfg2.get_random_features: { [sids; ctx ]
    disco: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];
    remote_FEAT_HIST: exec last address, last port from disco where svc=`FEATURES_HIST;

    h : hopen hsym `$raze ( (string remote_FEAT_HIST`address),":", (string remote_FEAT_HIST`port) );
    featH: h ( { :select from features where sample_id in x}; sids);
    hclose h;
    :featH;
  };

.bfg2.prv.get_usr_override: { [usr; ctx] 
  t: select from ctx`user_overrides where name = usr;
  :(ungroup select name, fr from t) cross (ungroup select op from t) cross (ungroup select bp from t) };

// ctx: ()!()
// ctx[`user_overrides]: ([ name: (`$"batel@atp";`$"demo@1234")]; op: ((0.12 0.15);(0.13 0.16) ); bp: ((0.1 0.3);(0.11  0.31) ); fr: ((15 18j);(16  19j) )   )
// ctx: ctx, (`target_ns`target_zone)!(`$":sp-prod1.eastus.cloudapp.azure.com:23400:";`prod);
// ctx[`profile_count] : 50;  -- number of samples to choose for creating profile
// ctx[`user_sample_type] : `REMOTE ;  -- can be REMOTE or RANKUP 
// ctx[`rndm_smpl_count] : 10;  -- number of random samples to choose for verification
// ctx[`rndm_users] : `$("nitsan@roeimc";"etay@6";"ee@4";"a@c.com";"israel.soriano12@gmail.com";"vv2@abc.com";"ran@1012";"s@s.com";"tamic@elimc";"shlomi@tmax")
.bfg.start_bfg2:  { [ctx]
    func: "[.bfg.start_bfg2] : ";
    need: `target_ns`target_zone`rndm_smpl_count`profile_count`user_sample_type`user_overrides;
    passed: key ctx;
    if[ not all need in passed; .sp.exception func, "not all required params in the context passed" ];
    if [ `all_bfg2_data in system ("v") ; delete all_bfg2_data  from `.];

    .sp.log.info func, "Discovering target system services...";
    disco:: .prv.get_disco[ ctx[`target_ns]; ctx[`target_zone] ];
    ctx[`include_users] :   exec distinct name from ctx`user_overrides; // override include_users with users in user_overrides

    remote_usrs_rt: exec last address, last port from disco where svc=`USERS_RT;
    remote_usrs_hist: exec last address, last port from disco where svc=`USERS_HIST;
    remt_smpls_rt: exec last address, last port from disco where svc=`SAMPLES_RT;
    remt_smpls_hist: exec last address, last port from disco where svc=`SAMPLES_HIST;

    .sp.log.info func, "Getting current and historical active users from remote system...";
    users_r: .prv.get_users [ remote_usrs_rt[`address]; remote_usrs_rt[`port]; ctx ];
    users_h: .prv.get_users [ remote_usrs_hist[`address]; remote_usrs_hist[`port]; ctx ];

    .bfg.users:: select by name from ((delete date from users_h) , users_r) where not null name;
    // get the complete fr op bp data cross joined with users
    // .bfg.input:: (select distinct name from .bfg.users) cross ( [] fr: (), ctx`fr_values) cross ( [] op: (), ctx`op_values) cross ( [] bp: (), ctx`bp_values);
    .bfg.input:: raze .bfg2.prv.get_usr_override[; ctx] each ctx[`include_users] ;

    .sp.log.info func, "creating input complete...";
    show .bfg.input;

    .bfg.clear_cache[`users];
    .bfg.clear_cache[`samples];
    .bfg.clear_cache[`sample_status];
    .bfg.clear_cache[`features];
    .bfg.clear_cache[`train];
    .bfg.clear_cache[`verify];

    // now insert the users into the cache...
    .bfg.cache_upsert[`users; .bfg.users];

    .sp.log.info func, "getting random  samples for target...";
    // get random users samples per rndm_smpl_count
    rndm_usrs: .prv.bfg2.get_random_users [ remote_usrs_hist[`address]; remote_usrs_hist[`port]; ctx ];
    rndm_smpls: .prv.bfg2.get_random_smpls [ remt_smpls_hist`address; remt_smpls_hist`port; exec distinct name from rndm_usrs];
    rndm_features:: .prv.bfg2.get_random_features [exec distinct sample_id from  rndm_smpls; ctx ];

    .sp.log.info func, "getting users samples for profile...";
    // create profile for all users = features for all users specified with profile_count samples taken of type specified (REMOTE or RANKUP)
    usrs_smpls: .prv.get_samples  [ remt_smpls_hist`address; remt_smpls_hist`port; exec distinct name from .bfg.users];
    usrs_smpls: select from usrs_smpls where sample_type <> `REGISTRATION;
    usrs_features:: .prv.bfg2.get_random_features [exec distinct sample_id from  usrs_smpls; ctx ];

    .bfg2.new_input:: (select sample_id from rndm_features) cross .bfg.input;
    .prv.bfg2.process ./:flip value flip .bfg2.new_input;

    r: .bfg2.save_to_file[];
    .sp.log.info func, "All done. Saved result to ", (raze string r);
  };

.prv.bfg2.process: { [rsid; name; fr; op; bp]
    func: "[.prv.bfg2.process_input]: ";
    .sp.log.info func, "starting : rsid [", (string rsid), "] name [", (string name), "] fr [", (string fr), "], op [", (string op), "], bp [", (string bp), "]";

    usr_profile:: select from usrs_features where account_id = name;
    $[ 0 = count usr_profile; [.sp.log.info func, "Empty usr_profile data"; :0]; .sp.log.info func, "count usr_profile = ", (string (count usr_profile)) ];

    rndm_target:: update account_id: name from select from rndm_features where sample_id =rsid;

    .sp.log.info func, "will start train now!";
    train_bfg2:: .[.sp.model.train; (usr_profile;fr;op;bp); { .sp.log.error "[.prv.bfg2.process_input]: train failed due to : ", (raze string x); :-1 } ];
    if[ (type -1) = (type train_bfg2); :0];

    .sp.log.info func, "will start verify now!";
    verify_bfg2:: .[.sp.model.verify; (rndm_target;fr;train_bfg2); { .sp.log.error "[.prv.bfg2.process_input] : verify failed due to : ", (raze string x); :-1 } ];
    if[ (type -1) = (type verify_bfg2); :0];

    `all_bfg2_data insert (update fr: fr, op: op, bp: bp from verify_bfg2);
    all_bfg2_data:: all_bfg2_data lj (`sample_id xkey select distinct date, sample_id, orig_acct_id:account_id from rndm_features);
    .sp.log.info func, "completed : rsid [", (string rsid), "] name [", (string name), "] fr [", (string fr), "], op [", (string op), "], bp [", (string bp), "] count verify_bfg2 = ", (string count verify_bfg2), "]";
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

.bfg.save_to_file: {
    func: "[.bfg.save_to_file] : ";
    nm: "/sp/data/all_data_", (raze string .z.Z);
    nm: `$ ssr[nm; ":"; "-"];
    :(hsym nm) set all_data 
  };

.bfg2.save_to_file: {
    func: "[.bfg2.save_to_file] : ";
    nm: "/sp/data/all_bfg2_data_", (raze string .z.Z);
    nm: `$ ssr[nm; ":"; "-"];
    :(hsym nm) set all_bfg2_data 
  };

.sp.comp.register_component[`whatif;`cache`common;.bfg.on_comp_start];
