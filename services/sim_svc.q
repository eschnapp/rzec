.boot.include (gdrive_root, "/algo/model/simulator.q");

.sim_svc.on_app_start:{[]
    .sp.log.info "SIMSVC: STARTING UP!!! CHUG CHUG...";
    .sim_svc.sources::();
    .sim_svc.max_v:: 20.0f;   
    .sim_svc.results_location:: `;
    if[ .sp.arg.exist[`results_location];
    .sim_svc.results_location:: `$(.sp.arg.required[`results_location]);
    ];
    
    .sim_svc.source_root:: `;
    if[ .sp.arg.exist[`source_root];
    .sim_svc.source_root:: `$(.sp.arg.required[`source_root]);
    .sim_svc.sources:: reload_sources[];
    ];
    
    :1b;
    
    };
    
.sim_svc.load_csv_file:{[csv_file]
    
    key_cols: `account_id`sample_id`source;
    val_cols: `time_index`stroke_index`x`y`pressure`sz`orientation`tilt`fake;
    
   tmpdb: ("SSSJJFFFFFFB";enlist",")0: hsym `$(raze string csv_file);
   tmpdb: update source: `$(raze string csv_file) from tmpdb;
     //tmpdb: update account_id: user_id, time_index: event_time from (get hsym `$file);
    
    if[ 0b = all (key_cols in cols tmpdb);
        .sp.exception "Fatal, Import table MUST have key columns !"];
    
    v: key_cols,((cols tmpdb) inter val_cols); / filter all non val columns...
    : key_cols xkey ?[tmpdb;();0b;v!v]; / functional select...
    };
    
source_root:{[]
    if[1b = (null .sim_svc.source_root);
        .sp.exception "Source root is not set! call set_source_root[location] to set...";
        ];
    : `$(raze string .sim_svc.source_root);
    };
    
set_source_root:{[location]
    if[1b = (null location);
        .sp.exception "Cannot set source root to a null location!";
        ];
    .sim_svc.source_root:: location;
    };
    
reload_sources:{[]
    root: source_root[];    
    .sp.log.info "SIMSVC: Reloading sources from ", (raze string root);
    
    stuff: key hsym root;
    tbl: ([name: stuff]; id: (count stuff)#0);
    tbl: update src: {[root;name] (raze string root),"/",(raze string name)}'[root;name] from tbl;
    tbl: select from tbl where (((count each src) - 4) <= {[src] 0^ last  (ss[src;".csv"])} each src ) = 1b;
    tbl: update id: i from tbl;
    .sim_svc.sources:: tbl;
    :tbl;
    };

start_type_i_sim: {[src_id;train_sizes;thresholds;users]      
    
    .sp.log.info "SIMSVC: Starting type_i simulation";
    if[ 1b = all (null src_id); .sp.exception "Source ID list cannot be null!";];
    
    if[ 1b = all (null train_sizes);
        .sp.log.info "SIMSVC: Null train size list provided, all valid samples per user will be used (TSZ=0)";
        train_sizes: enlist 0;
        ];
        
    if[ 1b = all (null thresholds);
        .sp.log.info "SIMSVC: Null threshold list provided, default threashold (31) will be used";
        thresholds: enlist 31;
        ];
        
    if[ 1b = all (null users);
        .sp.log.info "SIMSVC: Not user-list filter provided, will run simulaito on all users";
        users: `$();
        ];
    
    // load the correct sources...
    .sp.log.info "SIMSVC: Loading the data sources...";
    src: exec src from .sim_svc.sources where id in src_id;    
    data_sources:: raze {[s] `account_id`sample_id`source xkey (update src_db: (exec last name from .sim_svc.sources where src like s) from .sim_svc.load_csv_file[s])} each src;
    if[ (type data_sources) < 98h;
        .sp.exception "Could not load the data sources!";
        ];
        
    .sp.import.samples:: data_sources;
    
    // prepare the simulation
    .sp.log.info "SIMSVC: Preparing simulation..";
    sim_id: `$(string last -1?0Ng);
    .sp.model.sim.user_filter:: users;
    .sp.model.sim.train_size:: train_sizes;
    .sp.model.sim.t_range:: thresholds;
    
    // start sim
    .sp.log.info "SIMSVC: Initiating the algo engine...";
    result: ((update sim_id: sim_id, sim_type: `type_i, feature:  ":" sv'(string feature), target_feature: `float$target_feature, mx: `float$mx, mn: `float$mn from .sp.model.sim.type_i[]) lj (`account_id`sample_id xkey select account_id, sample_id, src_db from data_sources));
    result: select from result where v < .sim_svc.max_v;
    
    res2: update sim_id: sim_id, sample_passed: pass_count > threshold from select v: avg v, pass_count: count i by src_db, account_id, sample_id, threshold, train_size, sim_type from result where pass = 1b;
    summary: update sim_id: sim_id, pass_rate: 0^samples_passed % samples_total, samples_passed: 0^samples_passed from ((select v: avg v, samples_total: count i by src_db, account_id, threshold, train_size, sim_type from res2) lj 0^(select samples_passed: count i by src_db, account_id, threshold, train_size, sim_type from res2 where sample_passed = 1b));

    if[0b = (null .sim_svc.results_location);
        .sp.log.info "SIMSVC: Saving simulation data to: ", (raze string .sim_svc.results_location);
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "type_i_detailed_results.csv")) 0:.h.tx[`csv;result];
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "type_i_results.csv")) 0:.h.tx[`csv;res2];
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "type_i_summary.csv")) 0:.h.tx[`csv;summary];
        .sp.log.info "Save complete.";    
        ];
    
    :summary;
   
    
        
    };  
    
    
start_type_ii_simulation:{[src_id;train_sizes;thresholds;users]        
    
    .sp.log.info "SIMSVC: Starting type_ii simulation";
    if[ 1b = all (null src_id); .sp.exception "Source ID list cannot be null!";];
    
    if[ 1b = all (null train_sizes);
        .sp.log.info "SIMSVC: Null train size list provided, all valid samples per user will be used (TSZ=0)";
        train_sizes: enlist 0;
        ];
        
    if[ 1b = all (null thresholds);
        .sp.log.info "SIMSVC: Null threshold list provided, default threashold (31) will be used";
        thresholds: enlist 31;
        ];
        
    if[ 1b = all (null users);
        .sp.log.info "SIMSVC: Not user-list filter provided, will run simulaito on all users";
        users: `$();
        ];
    
    // load the correct sources...
    .sp.log.info "SIMSVC: Loading the data sources...";
    src: exec src from .sim_svc.sources where id in src_id;    
    data_sources: raze {[s] `account_id`sample_id`source xkey (update src_db: (exec last name from .sim_svc.sources where src like s) from .sim_svc.load_csv_file[s])} each src;
    .sp.import.samples:: data_sources;
    
    
    // prepare the simulation
    .sp.log.info "SIMSVC: Preparing simulation..";
    sim_id: `$(string last -1?0Ng);
    .sp.model.sim.user_filter:: users;
    .sp.model.sim.train_size:: train_sizes;
    .sp.model.sim.t_range:: thresholds;
    
    // start sim
    .sp.log.info "SIMSVC: Initiating the algo engine...";
    result: ((update sim_id: sim_id, sim_type: `type_ii, feature:  ":" sv'(string feature), target_feature: `float$target_feature, mx: `float$mx, mn: `float$mn from .sp.model.sim.type_ii[]) lj (`account_id`sample_id xkey select account_id, sample_id, src_db from data_sources));
    result: select from result where v < .sim_svc.max_v;
    
    res2: update sim_id: sim_id, sample_passed: pass_count > threshold from select v: max v, pass_count: count i by src_db, account_id, sample_id, threshold, train_size, sim_type from result where pass = 1b;
    summary: update sim_id: sim_id, pass_rate: 0^samples_passed % samples_total, samples_passed: 0^samples_passed from ((select v: max v, samples_total: count i by src_db, account_id, threshold, train_size, sim_type from res2) lj 0^(select samples_passed: count i by src_db, account_id, threshold, train_size, sim_type from res2 where sample_passed = 1b));

   
    if[0b = (null .sim_svc.results_location);
        .sp.log.info "SIMSVC: Saving simulation data to: ", (raze string .sim_svc.results_location);
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "type_ii_detailed_results.csv")) 0:.h.tx[`csv;result];
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "type_ii_results.csv")) 0:.h.tx[`csv;res2];
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "type_ii_summary.csv")) 0:.h.tx[`csv;summary];
        .sp.log.info "Save complete.";    
        ];
    
    :summary;
    };    
    
start_forgery_simulation:{[src_id;train_sizes;thresholds;users]        
    
    .sp.log.info "SIMSVC: Starting type_ii simulation";
    if[ 1b = all (null src_id); .sp.exception "Source ID list cannot be null!";];
    
    if[ 1b = all (null train_sizes);
        .sp.log.info "SIMSVC: Null train size list provided, all valid samples per user will be used (TSZ=0)";
        train_sizes: enlist 0;
        ];
        
    if[ 1b = all (null thresholds);
        .sp.log.info "SIMSVC: Null threshold list provided, default threashold (31) will be used";
        thresholds: enlist 31;
        ];
        
    if[ 1b = all (null users);
        .sp.log.info "SIMSVC: Not user-list filter provided, will run simulaito on all users";
        users: `$();
        ];
    
    // load the correct sources...
    .sp.log.info "SIMSVC: Loading the data sources...";
    src: exec src from .sim_svc.sources where id in src_id;    
    data_sources: raze {[s] `account_id`sample_id`source xkey (update src_db: (exec last name from .sim_svc.sources where src like s) from .sim_svc.load_csv_file[s])} each src;
    .sp.import.samples:: data_sources;
    
    
    // prepare the simulation
    .sp.log.info "SIMSVC: Preparing simulation..";
    sim_id: `$(string last -1?0Ng);
    .sp.model.sim.user_filter:: users;
    .sp.model.sim.train_size:: train_sizes;
    .sp.model.sim.t_range:: thresholds;
    
    // start sim
    .sp.log.info "SIMSVC: Initiating the algo engine...";
    result: ((update sim_id: sim_id, sim_type: `forgery, feature:  ":" sv'(string feature), target_feature: `float$target_feature, mx: `float$mx, mn: `float$mn from .sp.model.sim.forgery[]) lj (`account_id`sample_id xkey select account_id, sample_id, src_db from data_sources));
    result: select from result where v < .sim_svc.max_v;
    
    res2: update sim_id: sim_id, sample_passed: pass_count > threshold from select v: max v, pass_count: count i by src_db, account_id, sample_id, threshold, train_size, sim_type from result where pass = 1b;
    summary: update sim_id: sim_id, pass_rate: 0^samples_passed % samples_total, samples_passed: 0^samples_passed from ((select v: max v, samples_total: count i by src_db, account_id, threshold, train_size, sim_type from res2) lj 0^(select samples_passed: count i by src_db, account_id, threshold, train_size, sim_type from res2 where sample_passed = 1b));
   
    if[0b = (null .sim_svc.results_location);
        .sp.log.info "SIMSVC: Saving simulation data to: ", (raze string .sim_svc.results_location);
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "forgery_detailed_results.csv")) 0:.h.tx[`csv;result];
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "forgery_results.csv")) 0:.h.tx[`csv;res2];
        (hsym `$((raze string .sim_svc.results_location), "/", (raze string sim_id), "forgery_summary.csv")) 0:.h.tx[`csv;summary];
        .sp.log.info "Save complete.";    
        ];
    
    :summary;
    };    
        
.sp.comp.register_component[`sim_svc;enlist `simulator;.sim_svc.on_app_start];