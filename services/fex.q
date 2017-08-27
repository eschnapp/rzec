.boot.include (gdrive_root, "/algo/model/model.q");
.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");


.sp.fex.on_comp_start:{
    func: "[.sp.fex.on_comp_start]: ";
    .sp.log.info "FEX (Feature Extractor) Starting...";
    .sp.log.info "Subscribing to samples";    
    
    .sp.log.info func, "Initializing the cache...";
    .sp.fex.samples_rt:: `SAMPLES_RT; //.sp.alias.get_svc[`samples_rt];
    .sp.fex.features_tp:: `FEATURES_TP; //.sp.alias.get_svc[`features_tp];
    .fex.users_hist:: `USERS_HIST; //.sp.alias.get_svc[`users_hist];
 
    show .sp.cache.tables;   

    skip:0b;
    // first fetch historical data...
    tbls: .sp.re.exec[.fex.users_hist;`; "tables `."; .sp.consts[`DEF_EXEC_TO]]; 
    if[ -7h = type tbls; .sp.log.info func, "no users hist found!"; skip:1b];
    if[not skip; 
    if[ `users in tbls;
        .sp.log.info func, "Loading USERS from HIST...";
        .sp.cache.tables[`users]: .sp.re.exec[.fex.users_hist;`;"delete date from select from (select by name from users) where deleted = 0b";.sp.consts[`DEF_EXEC_TO]];
        .sp.log.info func, "Total HIST users: ", (string count (.sp.cache.tables[`users])) ];
    if[ `devices in tbls;
        .sp.log.info func, "Loading DEVICES from HIST...";
        .sp.cache.tables[`devices]: .sp.re.exec[.fex.users_hist;`;"delete date from select from (select by user from devices) where deleted = 0b";.sp.consts[`DEF_EXEC_TO]];
        .sp.log.info func, "Total HIST devices: ", (string count (.sp.cache.tables[`devices])) ] ];

    .sp.cache.add_callback_handler[`fex;.sp.fex.samples_rt;`samples;.sp.fex.on_update;.sp.fex.on_ready]

    // subscribe to RT data
    .sp.log.info func , "Subscribing to live RT data...";
    .sp.cache.add_clients[`USERS_RT; `users; {[d;p] select by name from d}; {[t;p] select from (select by name from (value t)) where deleted = 0b}; `; `];
    .sp.cache.add_clients[.sp.fex.samples_rt; `samples; {[d;p] select from d}; {[t;p] 0#(value t)}; `; `];

    :1b;
    };
    
.sp.fex.on_update:{[svc;topic;data;upd_type]
    func: "[.sp.fex.on_update]: ";
    .sp.log.info func, "Sample Update received, topic: ", (raze string topic), " count: ", (raze string (count data));
    //extract the features
    .sp.fex.last_upd:: data;

    if[ .sp.model.validate_samples[data] = 0b;
        .sp.log.error func, "Validate samle failed for samples ", (raze string (exec distinct sample_id from data));
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
    
    // select <all cols> by account_id, sample_id from f
    //tbl:: ?[f;();((`account_id`sample_id)!(`account_id`sample_id));((cols value f)!(cols value f))]; 
    
    // normalize...
    //by_name:: update time: .z.T  from(flip (`account_id`sample_id`feature_name!flip raze (flip value flip key tbl) ,/:\: (cols value tbl)),(0^(enlist `feature)!enlist raze flip value flip value tbl)); 

    //update features tp with the data...
    .sp.log.info func, "Updating extracted featured into features tickerplant...";
    .sp.re.exec[.sp.fex.features_tp;`;(`.sp.tp.upd;`features;0!(update time: .z.T from update sample_time:time from f));.sp.consts[`DEF_EXEC_TO]];
    };
    
.sp.fex.on_ready:{[]
    func: "[.sp.fex.on_ready]: ";
    .sp.log.info func "called";
    };

    
.sp.comp.register_component[`fex;`cache`common;.sp.fex.on_comp_start];
