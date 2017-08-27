.boot.include gdrive_root, "//development//qcore/common.q";
.boot.include gdrive_root, "//development//qcore/service.q";

.dtwm.on_comp_start:{[]

    .sp.log.info "Starting DTW Model";
    subparams: `update_callback`recovery_callback`update_filter`recovery_filter!(.dtwm.on_samples_update;.dtwm.on_samples_recover;{[data;params] :data; };{[topic] :samples; });
    .dtwm.samples_rt:: `SAMPLES_RT; // .sp.alias.get_svc[`samples_rt]
    .dtwm.results_tp:: `MODEL_RESULTS_TP;
    .sp.log.info "Subscribing to samples";
    scma: .sp.sub.subscribe[.dtwm.samples_rt;`;`samples;subparams];
    show scma;

    :1b;
    };


.dtwm.on_samples_recover:{[topic;data]
 
 .sp.log.info "BANG BANG RECOVERING DATA!!!!";
 .dtwm.train_data:: data;


 };


.dtwm.on_samples_update:{[topic;data]

 .sp.log.info "BANG BANG UPDATE!!!";
 // compare and check

 results: ([sample_id: `$()]; account_id: `$(); result: `float$());
 .sp.re.exec[.dtwm.results_tp;`;(`.sp.tp.upd;`dtw;results)];
 };







.sp.comp.register_component[`dtwm;`common`core;.dtwm.on_comp_start];
