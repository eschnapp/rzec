.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");
.boot.include (gdrive_root, "/services/gae_prxy_lib.q");
.boot.include (gdrive_root, "/framework/utils.q");
.boot.include (gdrive_root, "/algo/model/model.q");

.gae_proxy.on_comp_start:{
    gae_local:: ([trx_id: `long$()] time: `time$();func_type: `$(); func_name: `$(); svc_name: `$(); input_data: ();output_data: ();
           request_time: `time$();
           response_time: `time$());

    .sp.cache.add_clients[`USERS_RT; `sources; {[d;p] select from d}; {[t;p] select from (value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`USERS_RT; `domain; {[d;p] select by fq_name from d}; {[t;p] select by fq_name from (value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`USERS_RT; `user_permissions; {[d;p] select by user_id, domain, role from d}; {[t;p] select by user_id, domain, role from (value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`USERS_RT; `devices; {[d;p] select from d}; {[t;p] select from (value t) where deleted = 0b}; `; `];
//    .sp.cache.add_clients[`USERS_RT; `users; {[d;p] select from d}; {[t;p] select from (value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`USERS_RT; `users; {[d;p] delete allowed_sources from select from d}; {[t;p] delete allowed_sources from select from (value t) where deleted = 0b}; `; `];


    .sp.cache.add_clients[`SAMPLES_RT; `samples; {[d;p] select from d}; {[t;p] select from (value t)}; `; `];
    .sp.cache.add_clients[`SAMPLES_RT; `sample_status; {[d;p] update dt: .z.D from select by sample_id from d}; {[t;p] update dt: .z.D from select by sample_id from (value t) where deleted = 0b }; `; `];

    .sp.cache.add_clients[`FEATURES_RT; `features; {[d;p] update dt: .z.D from select by sample_id from d}; {[t;p] update dt: .z.D from select by sample_id from (value t) }; `; `];
    .sp.cache.add_clients[`REQUESTS_RT; `requests; {[d;p] select from d}; {[t;p] select from (value t)  }; `; `];

    .auth_svc.states:: (`pending`completed`expired`rejected!`int$(0 1 2 3));

    .gae_proxy.load_historical_data[];

    .gae_proxy.samples_fh:: `SAMPLES_FH;
    .gae_proxy.admin_svc:: `ADMIN_SVC;
    .gae_proxy.auth_svc:: `AUTH_SVC;
    .gae.pending_requests:: (`dummy;1)!(`;0Ni);
    :1b;
    };

.gae_proxy.load_historical_data: {[]
    func: "[.gae_proxy.load_historical_data]: ";
    .sp.log.info func, "loading data from hist...";
    users_hst: `USERS_HIST;
    up:(); s:();

    .sp.ns.client.wait_for_ever[`USERS_HIST; `];
    .sp.ns.client.wait_for_ever[`SAMPLES_HIST; `];
    .sp.ns.client.wait_for_ever[`REQUESTS_HIST; `];
    .sp.ns.client.wait_for_ever[`FEATURES_HIST; `];

    .sp.log.info func, "Detecting tables for USERS TP";
    tbls: .sp.re.exec[users_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "Detecting tables for SAMPLES TP";
    tbls,: .sp.re.exec[`SAMPLES_HIST;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];

    .sp.log.info func, "Detecting tables for FEATURES TP";
    tbls,: .sp.re.exec[`FEATURES_HIST;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];

    .sp.log.info func, "Detecting tables for REQUESTS TP";
    tbls,: .sp.re.exec[`REQUESTS_HIST;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];

    if[ `sources in tbls;
        s: .sp.re.exec[users_hst;`;"delete date from select from (select from sources) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `user_permissions in tbls;
        up: .sp.re.exec[users_hst;`;"delete date from select from (select by user_id, domain, role from user_permissions) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `devices in tbls;
        d: .sp.re.exec[users_hst;`;"delete date from select from (select from devices) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `users in tbls;
            usrs: .sp.re.exec[users_hst;`;"delete date, allowed_sources from select from (select from users) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
//            usrs: .sp.re.exec[users_hst;`;"delete date from select from (select from users) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];


    if[ `samples in tbls;
        smp: .sp.re.exec[`SAMPLES_HIST;`;"delete date from select from samples"; .sp.consts[`DEF_EXEC_TO]] ];
    if[ `sample_status in tbls;
        smp_stat: .sp.re.exec[`SAMPLES_HIST;`;"delete date from (update dt: date from select by sample_id from sample_status where deleted = 0b)"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `features in tbls;
        ftrs: .sp.re.exec[`FEATURES_HIST;`;"delete date from (update dt: date from select by sample_id from features)"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `requests in tbls;
        req: .sp.re.exec[`REQUESTS_HIST;`;"delete date from (select from requests)"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `domain in tbls;
        dom: .sp.re.exec[`USERS_HIST;`;"delete date from (select by fq_name from domain)"; .sp.consts[`DEF_EXEC_TO]] ];

    .sp.log.info func, "HIST sources count: ", (raze string (count s));
    if[ (count s) > 0;
        .sp.cache.tables[`sources]: s];
    .sp.log.info func, "HIST user_permissions count: ", (raze string (count up));
    if[ (count up) > 0;
        .sp.cache.tables[`user_permissions]: up];

    .sp.log.info func, "HIST devices count: ", (raze string (count up));
    if[ (count d) > 0;
        .sp.cache.tables[`devices]: d];

    if[ (count smp) > 0;
        .sp.cache.tables[`samples]: smp];
    if[ (count smp_stat) > 0;
        .sp.cache.tables[`sample_status]: smp_stat];
    if[ (count ftrs) > 0;
        .sp.cache.tables[`features]: ftrs];
    if[ (count req) > 0;
        .sp.cache.tables[`requests]: req];
    if[ (count usrs) > 0;
        .sp.cache.tables[`users]: usrs];
    if[ (count dom) > 0;
        .sp.cache.tables[`domain]: dom];

    .sp.log.info func, "Done loading historical data...";
  };


update_trx_tp:{ [data]
    func: "[update_trx_tp]: ";
    .sp.log.info func, "Sending transaction gae update";
    cmd: (`.sp.tp.upd;`gae;data);
    .sp.re.request[`TRX_TP;`;cmd;.sp.consts[`DEF_EXEC_TO]];
 };

process_response:{[hdl_k;trx_id;res]
    func: "[process_response]: ";
    .sp.log.info func, "starting... trx_id = ", (string trx_id);
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "starting...1";
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error msg;
        .sp.exception to_json[ API_ERRORS[`FAIL_TO_LOCATE_RET_HDL]; msg ];
        ];

    `gae_local upsert ([trx_id:`long$ (),trx_id] output_data:enlist res; response_time:`time$(),.z.T);
    update_trx_tp[ ((),`trx_id) _(0!select from gae_local where trx_id = trx_id)  ];
    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    (neg hdl) (hdl_k;res);

    .sp.log.info func, "generic request complete";
    :0b;
  };

request_connection_handle:{[]
    func: "[request_connection_handle]: ";
    hdl: `$(string first -1?0ng);
    .sp.log.info "Generating new request handle: ", (string hdl), " for connection handle ", (string .z.w);
    .gae.pending_requests[hdl]: .z.w;
    :hdl;
    };

//Eli's dashBoard functions.
get_all_data:{[hdl_k; rid; fltrs; bidx]
    func: "[.gae_proxy_admin.get_all_data]: ";

    // add permission check stuff here
    .sp.log.info func, "started get all data";

    substring: fltrs[`substring];
    only_success: fltrs[`only_success];
    date_range: fltrs[`date_range];
    dateF: `datetime$date_range[0];
    dateT: `datetime$date_range[1];
    sources: fltrs[`sig_sources];

    .sp.log.info func,"sources: ",string  type (sources) ;
    .sp.log.info func,"sources: ", string (`LOCAL in sources) ;

    /.sp.log.info func,"start date: ",(string dateF) ;
    /.sp.log.info func,"end date: ",(string dateT) ;
    /.sp.log.info func,"substring count: ",(string (count (string substring))) ;
    /.sp.log.info func,"substring: ",(string substring) ;
    /.sp.log.info func,"substring type: ",string type(substring) ;
    

    batchSize: 25;

    // get sample_id, validity, user_name
    a : select  user_id:  last account_id , last valid by sample_id from .sp.cache.tables[`sample_status];
    // get success rate
    b : a lj  (select success_rate:  last p by sample_id from .sp.cache.tables[`requests] where status = 1);
    // get signature timestamp.
    $[(type sources) > 0;
        c : (select last sample_type, last created_at by sample_id from .sp.cache.tables[`samples] where sample_type in sources) lj b;
        c : (select last sample_type, last created_at by sample_id from .sp.cache.tables[`samples]) lj b
    ];
    // get fr,bp,op
    d : c lj (.sp.re.exec[`MODEL_RESULTS_HIST;`; "select last fr, last op, last bp by sample_id from verify"; 1000]);
    
    //applay filters
    //date filter
    if[not (`year$dateF) = 1900; d:select from d where created_at>dateF, created_at<dateT];
    //substring filter
    if[(count string substring)>1; d: select from d where user_id like ("*",(string substring),"*")]; //("*",(string substring),"*")];
    d: `created_at xdesc d;
    totalQuerySize: count d;
    if[ (count d) > bidx ; d: bidx _d];
    if[ (count d) > batchSize; d: batchSize# d];
    res: (totalQuerySize; 0!d);
    .sp.log.info func,"total found: ",string  (totalQuerySize) ;

    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg] ];

    (neg hdl) (hdl_k;res);
    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    .sp.log.info func, "complete";
}


get_users_data:{[hdl_k; rid; userids; fltrs; bidx]
    func: "[.gae_proxy_admin.get_users_data]: ";
    // add permission check stuff here
    .sp.log.info func, "started get all data";

    batchSize: 25;

    a : select  user_id:  last account_id , last valid by sample_id from .sp.cache.tables[`sample_status] where account_id in userids;
    // get success rate
    b : a lj (select success_rate:  last p by sample_id from .sp.cache.tables[`requests] where status = 1);
    b : select from b where not success_rate= 0n;
    // get signature timestamp.
    c : b lj (select last created_at by sample_id from .sp.cache.tables[`samples]);
    // get fr,bp,op
    d : c lj (.sp.re.exec[`MODEL_RESULTS_HIST;`; "select last fr, last op, last bp by sample_id from verify"; 1000]);
    d: `created_at xdesc d;
    e : `user_id xgroup d;
    params: select curFr: last fr , curBp:last bp ,curOp:last  op by user_id:name from .sp.cache.tables[`users] where name in userids;
    e: e lj params;
    res: 0!e;

    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg] ];

    (neg hdl) (hdl_k;res);
    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    .sp.log.info func, "complete";
}

get_samples_data:{[hdl_k; request_id; sample_ids]
    func: "[.gae_proxy_admin.get_samples_data]: ";
    .sp.log.info func, "started get samples data";
    a:`sample_id xgroup select sample_id, x, neg y, stroke_index from .sp.cache.tables[`samples] where sample_id in sample_ids;
    res: a;

    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg] ];

    (neg hdl) (hdl_k;res);
    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    .sp.log.info func, "complete";

}


// RESEARCH API HERE... SHOULD ADD TOKEN LATER ON!!!
.research.get_distinct_users:{[]
    a: .sp.re.exec[`USERS_HIST;`;"exec name from select distinct name from users";1000];
    b: .sp.re.exec[`USERS_RT;`;"exec name from select distinct name from users";1000];
    : asc (distinct(a,b) except ``default_user);
    };

.research.get_user_sample_ids:{[user]
    data: select from .sp.cache.tables[`samples] where account_id = user;
    :exec distinct sample_id from data;
    };

.research.get_user_samples:{[user;uparams]
    
    // get the raw sample data
    //a: .sp.re.exec[`SAMPLES_HIST;`;({[xx] select from samples where account_id = xx}; user);1000];
    //b: update date: .z.D from .sp.re.exec[`SAMPLES_RT;`;({[xx] select from samples where account_id = xx}; user);1000];
    //data: a,b;
    data: select from .sp.cache.tables[`samples] where account_id = user;

    if[ .sp.model.validate_samples[data] = 0b;
        .sp.exception "Validate samle failed for samples ", (raze string (exec distinct sample_id from data))];


    tg_thresh: uparams[`tm_gap_thresh];
    ln_thresh: uparams[`len_thresh];

    dd: select first time: created_at by sample_id from data;
    f:  update sample_time: time, auth_token: (first exec auth_token from data) from .research.extract_feature[data;tg_thresh;ln_thresh];
    z:(f lj dd);
    : (data;z);
    };

.research.train_samples:{[sids;uparams]
    data: select from .sp.cache.tables[`samples] where sample_id in sids;
    if[ .sp.model.validate_samples[data] = 0b;
        .sp.exception "Validate samle failed for samples ", (raze string (exec distinct sample_id from data))];

    tg_thresh: .sp.cfg.get_value [ `user_tg_thresh; 50j];   // Default timegap threshold for all users got from cfg
    ln_thresh: .sp.cfg.get_value [ `user_ln_thresh; 20j];   // Default len theshold for all users got from cfg
    fr: 21;
    op: 0.1;
    bp: 0.12;


    // if usr exist, override from usr defaults...
    tg_thresh: uparams[`tm_gap_thresh];
    ln_thresh: uparams[`len_thresh];
    fr: uparams[`fr];
    op: uparams[`op];
    bp: uparams[`bp];

    f:  update sample_time: time, auth_token: (first exec auth_token from data) from .sp.model.extract_feature[data;tg_thresh;ln_thresh];
    train: .sp.model.train[ 0!f;fr;op;bp];
    :train;
 

    };


.research.validate_all_samples:{[usr;uparams;train]
        features: .research.get_user_samples[usr;uparams];
        sids: exec sample_id from features[1];
        res: raze {[features;sid;uparams;train]

            data: select from features[1] where sample_id = sid;
            : .sp.model.verify[data; uparams[`fr]; train];
        }[features;;uparams;train] each sids;

        :update op: uparams[`op], bp: uparams[`bp], fr: uparams[`fr] from res;
    }; 

.research.get_user_params:{[user]
    tg_thresh: .sp.cfg.get_value [ `user_tg_thresh; 50j];   // Default timegap threshold for all users got from cfg
    ln_thresh: .sp.cfg.get_value [ `user_ln_thresh; 20j];   // Default len theshold for all users got from cfg
    fr: 21;
    op: 0.1;
    bp: 0.12;


    // if usr exist, override from usr defaults...
    usr: 0!(select from (select by name from .sp.cache.tables[`users]) where name = user, deleted = 0b);
    : first usr;
    };
 

.research.calibrate: { [uparams;verify]
    iss:10;
    apr:0.88;
    afr:1-apr;
    ab:0.2;
    mb:0.1;
    final:`name xkey 
        select name:account_id, 
               bp:{[x;y;z;c;d;e;f;g] max f+(g-f)*(1-max d,y)%e,(asc x)[`int$(z*{max x,y}'[d;y])-c]}'[bp0;pr;n;iss;apr;afr;mb;ab], 
               op:{[x;y;z] min y,max 0,y+2*x-z}'[pr;afr;apr] 
        from 
               select pr:(iss+sum pass)%iss+count i, iss: iss,
                      n:iss+count i, bp0, 
                      sum pass by account_id 
               from 
                      update bp0: neg 1-(1+bp)*pv%v, iss: iss
                      from select account_id, sample_id, pass, v, bp, op, pv:{(asc abs x)[y]}'[z;fr] from verify;
    :0!((flip ( enlist each uparams)) lj final);
  };


.research.all_features:{[]
    
    // get the raw sample data
    //a: .sp.re.exec[`SAMPLES_HIST;`;({[xx] select from samples where account_id = xx}; user);1000];
    //b: update date: .z.D from .sp.re.exec[`SAMPLES_RT;`;({[xx] select from samples where account_id = xx}; user);1000];
    //data: a,b;
    data: select from .sp.cache.tables[`samples];
    if[ .sp.model.validate_samples[data] = 0b;
        .sp.exception "Validate samle failed for samples ", (raze string (exec distinct sample_id from data))];

    usrs: distinct exec account_id from data;

    ret: raze {[d;usr]
        data: select from d where account_id = usr;
        up: .research.get_user_params[usr];
        tg_thresh: up[`tm_gap_thresh];
        ln_thresh: up[`len_thresh];
        dd: select first time: created_at by sample_id from data;
        f:  update sample_time: time from .sp.model.extract_feature[data;tg_thresh;ln_thresh];
        z:(f lj dd);
        :z;
    }[data;] each usrs;
    :ret;
    };

.research.get_feature_names:{[]
     :(exec c from .sp.re.exec[`FEATURES_RT;`;"meta features";1000]) except (`time`account_id`sample_id`auth_token`sample_time);
    };

.research.get_histogram_data:{[usr;fname;bins]
        
    d: .research.all_features[];
    
    if[ not (null usr);
        d: select from d where account_id = usr;
      ];
    range: `float$(?[d;((<>;fname;0wf);(<>;fname;-0wf));(); fname]);
    bsz: ((max range) - (min range)) % bins;
    t: ([] r: range; r2: range );
    a: select binid, binsz, binval, bincnt from (update binid: i+1, binsz: bsz, bincnt: count each r from (select r by binval: bsz xbar  r2 from t));
    :a;
    };

.research.get_histogram_data_fast:{[usr;fname;bins]
   func: "[.research.get_histogram_data_fast]: ";
    d: select from .sp.cache.tables[`features] where not null account_id;
    if[ not (null usr);
        d: select from d where account_id = usr;
      ];
    range: `float$(?[d;((<>;fname;0wf);(<>;fname;-0wf));(); fname]);
    bsz: ((max range) - (min range)) % bins;
    t: ([] r: range; r2: range );
    a: select binid, binsz, binval, bincnt from (update binid: i+1, binsz: bsz, bincnt: count each r from (select r by binval: bsz xbar  r2 from t));
    :a;
    };

.research.get_histogram:{[usr;fname;bins]
    
    d1: update ubinc: 0 from select binval, bincnt from .research.get_histogram_data_fast[`;fname;bins];
    if[ not (null usr);
        d2:  update bincnt: 0 from select binval,ubinc from update ubinc: bincnt from .research.get_histogram_data_fast[usr;fname;bins];
        d1: (d1 , ( (cols d1) xcols d2));
        ];

    : d1;
    };

.research.interpolate_linear:{[h; bval]
    x0: last exec binval from (select binval from h where binval < bval);
    y0: last exec bincnt from (select bincnt from h where binval = x0);
    x1: first exec binval from (select binval from h where binval > bval);
    y1: first exec bincnt from (select bincnt from h where binval = x1);
    
    yval: y0 + ( bval - x0 ) * ( (y1 - y0) % (x1 - x0));
    :yval;
    };


.research.pdf:{[hgram;xval]
    // clean all 0 count points
    h: select from hgram where bincnt > 0;
    
    // interpolate yvalue if needed...
    yval: .research.interpolate_linear[hgram;xval];
    if[ xval in (exec binval from h);
        yval: first exec bincnt from (select from h where binval = xval);
        ];

    // compute total count
    t: exec sum bincnt from h;

    // return pobability
    : yval % t;
    };


.research.get_feature_score_linear:{[u;f;b]
    // get the histogram for the user...
    h1: .research.get_histogram_data_fast[u;f;b];

    // get the histogram for the overall feature
    h2: .research.get_histogram_data_fast[`;f;b];

    h: select  binval, bincnt from h1;

    // compute user probabilities
    h: update user_p: .research.pdf[h1;]'[binval] from h;

    // compute overall probabilities over same binvals
    h: update feature_p: .research.pdf[h2;]'[binval] from h;

    // return score as weighted sum of user_p by overall_p
    r: select score: feature_p wsum user_p from h;
    :update user: u, feature: f from r;
    };


.research.score_feature:{[u;f;b]
    if[ 0h > (type u); 
        u: enlist u;
        ];
    raze .research.get_feature_score_linear[;f;b] each u
    };

.research.score_user:{[u;f;b]
    if[ 0h > (type f); 
        f: enlist f;
        ];
    raze .research.get_feature_score_linear[u;;b] each f

    };

.research.metrics:{[f]
    ungroup f
    };


.research.extract_feature:{[s;t;l]
    /combine close strokes
    s:
    ungroup
    /update stroke_index:{idx:first x;ii:1;while[ii<count x;$[y[ii]<z[ii];x[ii]:idx;idx:x[ii]];ii+:1];x}[stroke_index;t0;t+0,(-1_t1)] from
    update stroke_index:{$[z;x;y]}\[first stroke_index;stroke_index;(t0<t+prev t1) and (sample_id=prev sample_id)] from
    update t0:first each time_index,t1:last each time_index from
    `time xasc select min time,time_index,x,y,size by account_id,sample_id,stroke_index from
    s
    ;

    /remove short strokes
    s:
    update d:{sqrt[(x*x)+y*y]}'[dx;dy] from
    update dx:{0,1_deltas x} each x,dy:{0,1_deltas x} each y from
    `time xasc select min time, action,time_index,x,y,size by account_id,sample_id,stroke_index from
    select min time, first stroke_index,avg x, avg y, avg size by account_id,sample_id,time_index,action from
    update action:{r:(count x)#2;r:?[(x<>prev x) or (y<>prev y);0;r];r:?[(x<>next x) or (y<>next y);1;r];r}[sample_id;stroke_index] from
    s
    ;
    s:
    ungroup
    delete from s where (sum each d) < l
    ;

    /extract features
    f:
    `time xasc select min time, action,time_index,x,y,size by account_id,sample_id,stroke_index from
    select min time, first stroke_index,avg x, avg y, avg size by account_id,sample_id,time_index,action from
    update action:{r:(count x)#2;r:?[(x<>prev x) or (y<>prev y);0;r];r:?[(x<>next x) or (y<>next y);1;r];r}[sample_id;stroke_index] from  s;

    f:
    select from
    update xstddev: sqrt var each x,ystddev: sqrt var each y from /41,42
    update aspectratio:(xmax - xmin)%ymax - ymin from /40
    update xstartmin:xstart-xmin,xendmax:xend-xmax,xendmin:xend-xmin from /37,38,39
    update lenarearatio:length%area from /36
    update length:sum each d from
    update area:(xmax - xmin)*ymax - ymin from /35
    update tmaxx:({first x where y=z}'[et;x;xmax])%ts from /34
    update tminx:({first x where y=z}'[et;x;xmin])%ts from /33
    update xmax:max each x,xmin:min each x,ymax:max each y,ymin:min each y,xstart:first each x, xend:last each x from
    update vxmaxvymin:vxmax-vymin from /32
    update vymaxmin:vymax-vymin from /31
    update vxmaxmin:vxmax-vxmin from /30
    update vymaxavg:vymax-vyavg from /29
    update vxmaxavg:vxmax-vxavg from /28
    update vyavg:avg each vy,vymax:max each vy,vymin:min each vy from
    update vyzeroc:{sum x=0} each vy from /27
    update vxzeroc:{sum x=0} each vx from /26
    update vynegavg:{avg x where x<0} each vy from /25
    update vyposavg:{avg x where x>0} each vy from /24
    update vxnegavg:{avg x where x<0} each vx from /23
    update vxposavg:{avg x where x>0} each vx from /22
    update vynegt:{sum x where y<0}'[dt;vy] from /21
    update vypost:{sum x where y>0}'[dt;vy] from /20
    update vxnegt:{sum x where y<0}'[dt;vx] from /19
    update vxpost:{sum x where y>0}'[dt;vx] from /18
    update dirdown1uplast:.sp.model.strokes_dir'[x;y;stroke_index;(count x)#enlist((0;first);(-1;last))] from /17
    update dir2:.sp.model.stroke_dir'[dx;dy;d;stroke_index;1;20] from /16
    update dirdown1up2:.sp.model.strokes_dir'[x;y;stroke_index;(count x)#enlist((0;first);(1;last))] from /15
    update dirdown1down2:.sp.model.strokes_dir'[x;y;stroke_index;(count x)#enlist((0;first);(1;first))] from /14
    update dir1:.sp.model.stroke_dir'[dx;dy;d;stroke_index;0;20] from /13
    update etdown2:{[x;s;i;n] si:.sp.model.stroke_idx[s;i];;if[si~`long$();:0n];first n _x[si]}'[et;stroke_index;1;0] from /12
    update numstroke:{count distinct x} each stroke_index from /11
    update tavg:{avg -1_x} each dt from /10
    update numpoint:count each et from /9
    update vxmint:{sum x where y}'[dt;vx=vxmin] from /8
    update vxavg:(sum each dx)%tw,vxmax:max each vx,vxmin:min each vx from /x,x,7
    /update tw:{sum x where y<>z}'[dt;action;1] from /6
    update ts:last each et from /5
    update tmove1:{first x where y,z}'[et;action=2;d<>0] from /4
    update vmaxt:{sum x where y}'[dt;v=vmax] from /3
    update vmin:min each v from /?
    update vmax:max each v from /2
    update vavg:length%tw from /1
    update tw:sum each dt from /6
    update length:sum each d from
    update time:first each time from
    update et:{x-first x} each time_index from
    `account_id`sample_id xgroup ungroup
    update vy:{(-1_x),0n} each dy%dt  from
    update vx:{(-1_x),0n} each dx%dt  from
    update v:{(-1_x),0n} each d%dt  from
    update dt:{(1_deltas x),0} each time_index from
    update d:{sqrt[(x*x)+y*y]}'[dx;dy] from
    update dx:{(1_deltas x),0} each x,dy:{(1_deltas x),0} each y from f;

    f: update
        vavg: `float$vavg,
        vmax: `float$vmax,
        vmaxt: `long$vmaxt,
        tmove1: `long$tmove1,
        ts: `long$ts,
        tw: `long$tw,
        vxmin: `float$vxmin,
        vxmint: `long$vxmint,
        numpoint: `long$numpoint,
        tavg: `float$tavg,
        numstroke:	 `long$numstroke,
        etdown2: `float$etdown2,
        dir1: `float$dir1,
        dirdown1down2: `float$dirdown1down2,
        dirdown1up2: `float$dirdown1up2,
        dir2: `float$dir2,
        dirdown1uplast: `float$dirdown1uplast,
        vxpost: `long$vxpost,
        vxnegt: `long$vxnegt,
        vypost: `long$vypost,
        vynegt: `long$vynegt,
        vxposavg: `float$vxposavg,
        vxnegavg: `float$vxnegavg,
        vyposavg: `float$vyposavg,
        vynegavg: `float$vynegavg,
        vxzeroc: `int$vxzeroc,
        vyzeroc: `int$vyzeroc,
        vxmaxavg: `float$vxmaxavg,
        vymaxavg: `float$vymaxavg,
        vxmaxmin: `float$vxmaxmin,
        vymaxmin: `float$vymaxmin,
        vxmaxvymin: `float$vxmaxvymin,
        tminx: `float$tminx,
        tmaxx: `float$tmaxx,
        area: `float$area,
        lenarearatio: `float$lenarearatio,
        xstartmin: `float$xstartmin,
        xendmax: `float$xendmax,
        xendmin: `float$xendmin,
        aspectratio: `float$aspectratio,
        xstddev: `float$xstddev,
        ystddev: `float$ystddev from f;

    f:2!0!f;
    f
    };


.sp.comp.register_component[`gae_admin_proxy;enlist `common;.gae_proxy.on_comp_start];
