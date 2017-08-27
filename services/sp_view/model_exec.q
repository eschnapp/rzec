.view.model_exec: {[request]

  func: "[.view.model_exec]:";

  sid: request[`args][`sid];
  tsid: request[`args][`tsid];
  fr: request[`args][`fr];
  lnt: request[`args][`lnt];
  tgt: request[`args][`tgt];
  op: request[`args][`op];
  bp: request[`args][`bp];
  if[(count sid) <= 0; .sp.exception "sid must be supplied!"];
  if[(count tsid) <= 0; .sp.exception "tsid must be supplied!"];

  tsid:: "," vs tsid;
  if[(count tsid) < 5; .sp.exception "train too small!"];

  defs: `fr`lnt`tgt`op`bp!(15;20j;50j;0.12;0.1);
  .sp.log.info func, "Fetching all data for given samples...";
  alldata:: select from .sp.cache.tables[`samples] where sample_id in `$(ssr[;"_";"-"] each (tsid, (enlist sid)));
  .sp.log.info func, "Fetching user parameters...";
  usr: select by name from .sp.cache.tables[`users] where name = (first exec account_id from alldata);


    if[ (count usr) > 0;
          .sp.log.info func, "Applying stored user params...";
        u: last 0!usr;
        defs[`fr]: u[`fr];
        defs[`lnt]: u[`len_thresh];
        defs[`tgt]: u[`tm_gap_thresh];
        defs[`op]: u[`op];
        defs[`bp]: u[`bp];
    ];

      .sp.log.info func, "Checking for manual overrides...";
    if[(count fr) > 0;
        defs[`fr]: "I"$fr;
    ];
    if[(count lnt) > 0;
        defs[`lnt]: "J"$lnt;
    ];
    if[(count tgt) > 0;
        defs[`tgt]: "J"$tgt;
    ];
    if[(count op) > 0;
        defs[`op]: "F"$op
    ];
    if[(count bp) > 0;
        defs[`bp]: "F"$bp;
    ];

    fr: defs[`fr];
    lnt: defs[`lnt];
    tgt: defs[`tgt];
    op: defs[`op];
    bp: defs[`bp];

    .sp.log.info func, "Extracting features (sample)...";
    smpl: update auth_token: `, sample_time: time from .sp.model.extract_feature[(update auth_token: `  from select from alldata where sample_id = (`$(ssr[sid;"_";"-"])));tgt;lnt];
    .sp.log.info func, "Extracting features (profile)...";
    profile: update auth_token: `, sample_time: time from .sp.model.extract_feature[(update auth_tokenn: ` from select from alldata where sample_id in `$(ssr[;"_";"-"] each tsid));tgt;lnt];
    .sp.log.info func, "Training model...";
    trn: .sp.model.train[profile;fr;op;bp];
    .sp.log.info func, "Performing validation...";
    mres: last .sp.model.verify[smpl;fr;trn];
    .sp.log.info func, "Done! displaying results...";

    ttbl: ([] feature_name: fnames; z: mres[`z]; v: (count fnames)#mres[`v]; m: mres[`m]; s: mres[`s]; pass: `int$mres[`pass_f]);
    ttbl: update pass: -1 from ttbl where pass = 0;

    achrt:
     .sp.h.sdk.size["100%";"100vh"]
     .sp.h.sdk.create_chart[`achrt;0!ttbl;(`type`op.width`op.height`formatter)!("Table";"100%";"100%";(enlist ("ArrowFormat";5)))];
  };

.sp.html.handlers[`model_exec.q]: `.view.model_exec;