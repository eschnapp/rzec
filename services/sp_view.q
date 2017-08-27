.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/algo/model/model.q");
.boot.include (gdrive_root, "/framework/htmlsdk.q");
.boot.include (gdrive_root, "/framework/cache.q");

.sp.view.on_comp_start:{
    func : "[.sp.view.on_comp_start] : ";
    .sp.log.info func, "Starting...";
   //  system "l doth.k";

    fnames:: `vavg`vmax`vmaxt`tmove1`ts`tw`vxmin`vxmint`numpoint`tavg`numstroke`etdown2`dir1`dirdown1down2`dirdown1up2`dir2`dirdown1uplast`vxpost`vxnegt`vypost`vynegt`vxposavg`vxnegavg`vyposavg`vynegavg`vxzeroc`vyzeroc`vxmaxavg`vymaxavg`vxmaxmin`vymaxmin`vxmaxvymin`tminx`tmaxx`area`lenarearatio`xstartmin`xendmax`xendmin`aspectratio`xstddev`ystddev;


//    .sp.html.handlers[`mainframe.q]: .view.mainframe;
//    .sp.html.handlers[`welcome.q]: .view.welcome;
//    .sp.html.handlers[`model_exec.q]: .view.model_exec;
//    .sp.html.handlers[`model.q]: .view.model;
//    .sp.html.handlers[`useredit.q]: .view.useredit;
//    .sp.html.handlers[`user.q]: .view.user;
//    .sp.html.handlers[`fo.q]: .view.fo;
//    .sp.html.handlers[`sig.q]: .view.sig;
//    .sp.html.handlers[`main.q]: .view.main;
//    .sp.html.handlers[`testsub.q]: .view.testsub;
//    .sp.html.handlers[`cfgedit.q]: `.view.cfgedit;

    .boot.include (gdrive_root, "/services/sp_view/mainframe.q");
    .boot.include (gdrive_root, "/services/sp_view/welcome.q");
    .boot.include (gdrive_root, "/services/sp_view/model_exec.q");
    .boot.include (gdrive_root, "/services/sp_view/model.q");
    .boot.include (gdrive_root, "/services/sp_view/useredit.q");
    .boot.include (gdrive_root, "/services/sp_view/user.q");
    .boot.include (gdrive_root, "/services/sp_view/fo.q");
    .boot.include (gdrive_root, "/services/sp_view/sig.q");
    .boot.include (gdrive_root, "/services/sp_view/main.q");
    .boot.include (gdrive_root, "/services/sp_view/livemon.q");
    .boot.include (gdrive_root, "/services/sp_view/cfgedit.q");

    .view.features_rt:: `FEATURES_RT;
    .view.samples_rt:: `SAMPLES_RT;
    .view.users_rt:: `USERS_RT;
    .view.model_results_rt:: `MODEL_RESULTS_RT;
    .view.load_historical_data[];

    //    .sp.cache.add_callback_handler[`auth_svc;.auth_svc.features_rt;`features;.auth_svc.on_update;.auth_svc.on_ready]
    // users
    .sp.cache.add_clients[.view.users_rt; `users; {[d;p] select by name from d}; {[t;p] select from (select by name from (value t)) where deleted = 0b}; `; `];
    .sp.cache.add_clients[.view.users_rt; `devices; {[d;p] select by user from d}; {[t;p] select from (select by user from (value t)) where deleted = 0b}; `; `];

    // samples
    .sp.cache.add_clients[.view.features_rt; `features; {[d;p] 0! select by sample_id from d}; {[t;p] 0! select by sample_id from (value t)}; `; `];
    .sp.cache.add_clients[.view.samples_rt; `samples; {[d;p] select from d}; {[t;p] select from (value t)}; `; `];
    .sp.cache.add_clients[.view.samples_rt; `sample_status; {[d;p] update date : .z.D from (select by sample_id from d)}; {[t;p] update date : .z.D from select from (select by sample_id from (value t)) where deleted = 0b}; `; `];

    // model_results
    .sp.cache.add_clients[.view.model_results_rt; `verify; {[d;p] 0! select by sample_id from d}; {[t;p] 0! select by sample_id from (value t)}; `; `];

    `.sp.html.external_scripts insert (enlist `$"text/javascript"; enlist `$"https://apis.google.com/js/client:plusone.js?onload=init"; enlist "");
    `.sp.html.external_scripts insert (enlist `$"text/javascript"; enlist `$"https://www.google.com/jsapi"; enlist "");
    `.sp.html.external_scripts insert (enlist `; enlist `$"chart.js"; enlist "init_script()");
    `.sp.html.external_scripts insert (enlist `; enlist `$"c.js"; enlist "");
    `.sp.html.external_scripts insert (enlist `; enlist `$"kxipc.js"; enlist "init_kx_ipc()");
    `.sp.html.external_scripts insert (enlist `; enlist `$"spapi.js"; enlist "init_sp_api()");


    `.sp.html.links insert ( enlist `$("text/css"); enlist `; rel: enlist `$("stylesheet"); href: enlist `$("btn.css"));
    .sp.log.info func, "Completed...";
    :1b;
    };


.view.load_historical_data:{[]
    func: "[.view.load_historical_data]: ";
    .sp.log.info func, "loading data from hist...";
    users_hst: `USERS_HIST; // .sp.alias.get_svc[`users_hist];
    samples_hst: `SAMPLES_HIST; //.sp.alias.get_svc[`samples_hist];
    features_hst: `FEATURES_HIST; //.sp.alias.get_svc[`samples_hist];
    model_res_hst: `MODEL_RESULTS_HIST; //.sp.alias.get_svc[`samples_hist];

    .sp.ns.client.wait_for_ever[`USERS_HIST; `];
    .sp.ns.client.wait_for_ever[`SAMPLES_HIST; `];
    .sp.ns.client.wait_for_ever[`MODEL_RESULTS_HIST; `];
    .sp.ns.client.wait_for_ever[`FEATURES_HIST; `];

    wsize: .sp.cfg.get_value[`window_size;200];
    u:(); d:(); smpl_stat:(); f:(); s:();mr:();

    // users
    tbls: .sp.re.exec[users_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    if[ `users in tbls;
        u: .sp.re.exec[users_hst;`;"delete date from select from ( select by name from users) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
    // devices
    if[ `devices in tbls;
        d: .sp.re.exec[users_hst;`;"delete date from select from (select by user from devices) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
    // sample_status
    tbls: .sp.re.exec[samples_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    if[ `sample_status  in tbls;
        smpl_stat: .sp.re.exec[samples_hst;`;"select from (select by sample_id from sample_status) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];

    // samples
    if[ `samples in tbls;
        s: .sp.re.exec[samples_hst;`;"delete date from select from samples where sample_id in exec distinct sample_id from select by sample_id from sample_status where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]]  ];

    // features
    tbls: .sp.re.exec[features_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    if[ `features in tbls;
        sids: exec distinct sample_id from smpl_stat;
        f: .sp.re.exec[features_hst;`;({delete date from 0! select by sample_id from features where sample_id in x}; sids); .sp.consts[`DEF_EXEC_TO]]  ];

    // model_resutls
    tbls: .sp.re.exec[model_res_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    if[ `verify in tbls;
        sids: exec distinct sample_id from smpl_stat;
        mr: .sp.re.exec[model_res_hst;`;({delete date from 0! select by sample_id from verify where sample_id in x}; sids); .sp.consts[`DEF_EXEC_TO]]  ];


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
    .sp.log.info func, "HIST model_res count: ", (raze string (count mr));
    if[ (count mr) > 0;
        .sp.cache.tables[`verify]: mr];

    .sp.log.info func, "Done loading historical data...";
    };


.view.p.save_user:{[req]
   func: "[.view.p.save_user]: ";
   .sp.log.info func, "Processing new user updated data...";
   kz:: (key req[`args]) except `user_id`dosave`date`time;
   mm:: meta (.sp.cache.tables[`users]);
   mta:: ({a:x; a[0]!a[1] } flip ( flip exec( c; upper t) from mm));
   erow::  {[req;mta;x]
      v: (req[`args])[x];
      if[ (count (raze string v)) <= 0; :()!();
        ];
      :(enlist x)!(enlist (mta[x]$(raze string v)));
    }[req;mta;] each kz;

   rrow:: update time:.z.T from (flip enlist each raze erow);
   .sp.log.info func, "Sending new update to TP: ";
   show rrow;
   cls: exec c from (select from mm where c in (cols rrow));
   .sp.re.exec[`USERS_TP;`;(`.sp.tp.upd;`users;0!( cls xcols rrow));.sp.consts[`DEF_EXEC_TO]];

  };


.view.p.sample_chart:{[sample;w;h;st;op]

   //if[ ((type st) <> 0h) or (count st <= 0);  st: ();];
   //if[ ((type op) <> 0h) or (count op <= 0);  op: ();];
  tsid: first exec sample_id from sample;
  dtbl: select X_Pos: x, Y_Pos: neg y from sample;
  owrp:
    .sp.h.sdk.style[(("padding";"50px");("width";w);("height";h);("display";"inline-block"))]
    .sp.h.sdk.create[`div];

  dnm: `$(ssr[string tsid;"-";"_"]);
  ochrt:
     .sp.h.sdk.add_item[owrp]
     .sp.h.sdk.style[(("border";"1px none black");
             ("border";"1px solid black");
             ("border-radius";"10px");
             ("width";"100%");
             ("height";"100%");
             ("padding";"10px");
             ("display";"inline-block")),st]
     .sp.h.sdk.create_chart[dnm;dtbl;((`type`title`op.pointSize)!("ScatterChart";string tsid;2)),op];
  : owrp;
  };


extractFeatureSeries:{[feature;sample]
    if[ ((`$feature) in (key .feature)) = 0b;
        :();
      ];
    : ([] x: (); y: ()) , .feature[`$(feature)][sample];
    };


.feature.vavg:{[sample]
      :();
    };

.feature.area:{[sample]
    ssd:: sample;
    minx:: exec min x from sample;
    maxx:: exec max x from sample;
    miny:: neg exec min y from sample;
    maxy:: neg exec max y from sample;

    :([] x: enlist (minx;minx;maxx;maxx); y: enlist  (maxy;miny;maxy;miny));

    };

.sp.comp.register_component[`sp_view;`cache`common`htmlsdk;.sp.view.on_comp_start];

//     .sp.html.handlers[`model_exec.q]: .view.model_exec;
