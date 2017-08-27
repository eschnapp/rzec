.boot.include (gdrive_root, "/services/fbm_dynamic.q");
.boot.include (gdrive_root, "/framework/common.q");
.sp.fbm.on_comp_start:{
    
    .sp.log.info "FBM (Feature Base Model) Starting...";
    .sp.fbm.features_rt:: `FEATURES_RT; //.sp.alias.get_svc[`features_rt];
    .sp.fbm.model_results_tp:: `MODEL_RESULTS_TP;
    //.sp.fbm.features_hist:: .sp.alias.get_svc[`features_hist];
    .sp.fbm.threshold:: 31; // threshold
    .sp.fbm.window_size:: 100; // sample window size
    
    .sp.log.info "Fetching historical profile infomation...";
    .sp.fbm.features:: .sp.fbm.denormalize_features (.sp.re.exec[.sp.fbm.features_rt;`;({[t] 
                           tmp: exec account_id from (select c:  count distinct sample_id by account_id from features) where c >= t;  // get all accts with enough samples to train
			   tmp2: raze value (exec (neg t)# distinct sample_id by account_id from features where account_id in tmp); // get the last N samples to train 
			   :select from features where sample_id in tmp2; // return the data for the selected samples...
			   };.sp.fbm.threshold);-1]);
    .sp.log.info "Historical data received, training initial user profiles";
    .sp.fbm.profiles:: .sp.fbm.train[.sp.fbm.features;.sp.fbm.threshold];
    .sp.log.info "Done computing profile for ", (raze string (exec count distinct account_id from .sp.fbm.profiles)), " accounts";
    .sp.log.info "Subscribing to features tickerplant";
    sub_params: `recovery_callback`update_callback`recovery_filter`update_filter!(.sp.fbm.on_update;.sp.fbm.on_update;{[t] select from features};{[d;p] :d;});
    scma: .sp.sub.subscribe[.sp.fbm.features_rt;`;`features;sub_params];
    .sp.log.info "Subscription Successful, Schema:";
    show meta scma;
    :1b;    
    };


.sp.fbm.denormalize_features:{[data]
    res:`account_id`sample_id xkey raze {[aid;sid;fname;f] update account_id: aid, sample_id: sid from (flip raze  {[x;y] (enlist x)!enlist (enlist y)} ./: ((fname),'f)) } ./: ( flip value ( flip 0!(select feature_name, feature by account_id, sample_id from data)));
    :res;
    };

.sp.fbm.on_update:{[topic;data]
    show  data;
    .sp.log.info "Received new feature-set update, executing vaildation against all samples";
    .sp.log.info "Total Samples to be validated: ", (raze string (exec count distinct sample_id from data));

    features: .sp.fbm.denormalize_features data;

    samples: (exec distinct sample_id from features);
    res: raze {[f;sid] update sample_id: sid from .sp.fbm.verify[(select from f where sample_id = sid);.sp.fbm.profiles] }[features;] each samples;
    tmp: update threshold: .sp.fbm.threshold from (select passcount: count i by account_id, sample_id from res where pass = 1b);
    total: count samples;
    passed: exec count i from tmp where passcount >= .sp.fbm.threshold;
    .sp.log.info "Finished validating all samples. ", (string passed), " samples passed out of ", (string total);
    .sp.fbm.publish_results[ update time: .z.T, target_feature: `float$target_feature, mn: `float$mn, mx: `float$mx  from res; update time: .z.T, passcount: `int$passcount, threshold: `int$threshold  from tmp];
    };
    
.sp.fbm.publish_results:{[res;tmp]
    .sp.log.info "Publishing model results... count: ", (raze string count res);
    show meta res;
    .sp.re.exec[.sp.fbm.model_results_tp;`;(`.sp.tp.upd;`fbm_details;0!res);-1];
    .sp.re.exec[.sp.fbm.model_results_tp;`;(`.sp.tp.upd;`fbm;0!tmp);-1];

    };
    
.sp.fbm.train_core:{[features;feature_required;fail_rate;threshold_buffer] 
    if[ 0 >= count features;
        .sp.exception "Cannot train empty sample set!!"];
 
    extract: features; //.sp.fbm.dynamic.extractfeature samples;

    tt:
    tt lj
    update v:(1+threshold_buffer)*{x[y]}'[vn;{min[(x-1),(`int$(1-y)*x)]}[count each vn;fail_rate]] from 
    select vn:vn0 by account_id from 
    `account_id`vn0 xasc 
    tt:
    update vn0:v0[;feature_required-1] from 
    update v0:asc each abs[f-m]%s from 
    tt ij 
    update s:{x[where -9 <> type each x]:0f;?[x<1e-10;1e-10;x]} each sqrt s-m*m from select s:avg f*f,m:avg f by account_id from 
    tt:update f:flip value flip value extract from extract;

    outlier: select account_id,sample_id from tt where vn0 > v;
    if[0<count outlier; :.sp.fbm.train_core[delete ii from features ij select ii:i by account_id,sample_id from tt where vn0 <= v;feature_required;0;threshold_buffer]];

    feature: ?[extract;();((enlist `account_id)!(enlist `account_id));((cols value extract)!(cols value extract))];
    mean: .sp.fbm.dynamic.feature_mean extract;
    sigma: .sp.fbm.dynamic.feature_sigma extract;
    mx: .sp.fbm.dynamic.feature_max extract;
    mn: .sp.fbm.dynamic.feature_min extract;
     
    tbl: (.sp.fbm.inner_train[`feature;feature]) lj (.sp.fbm.inner_train[`mean;mean]) lj (.sp.fbm.inner_train[`sigma;sigma]) lj (.sp.fbm.inner_train[`mx;mx]) lj (.sp.fbm.inner_train[`mn;mn]);
    /tbl: update nv: asc 1.0^((0^ abs(feature-mean)) % sigma) from tbl;
    /tbl: update  v: avg each nv from tbl;
    tbl lj 1!select account_id,v from tt
    /: tbl;
    };

.sp.fbm.train:{[features;feature_required] 
    fail_rate:0.1;
    threshold_buffer:0.1;
    // feature_required:31;
        
    .sp.fbm.train_core[features;feature_required;fail_rate;threshold_buffer]
    };

.sp.fbm.inner_train: {[col;data]
         tbl: data;
         t:(flip (`account_id`feature_name!flip raze (flip value flip key tbl) ,/:\: (cols value tbl)),(0^(enlist col)!enlist raze flip value flip value tbl));
         :2!t;
         };

.sp.fbm.verify:{[sample;train]
    extract: sample; //.sp.fbm.dynamic.extractfeature sample;
    target_feature: ?[extract;();((enlist `account_id)!(enlist `account_id));((cols value extract)!last ,/: (cols value extract))];
    res: (.sp.fbm.inner_train[`target_feature;target_feature]) lj train;
    res: update pass: (abs(target_feature - mean)) <= sigma * v from res;
    : res;
    // :(exec count i from res where pass = 1b);
    };
            
.sp.comp.register_component[`fbm;`common`fbm_dynamic;.sp.fbm.on_comp_start];
