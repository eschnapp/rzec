.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");

.gae_proxy.on_comp_start:{
    gae_local:: ([trx_id: `long$()] time: `time$();func_type: `$(); func_name: `$(); svc_name: `$(); input_data: ();output_data: ();
           request_time: `time$();
           response_time: `time$());

    .sp.cache.add_clients[`USERS_RT; `sources; {[d;p] select from d}; {[t;p] select from (value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`USERS_RT; `user_permissions; {[d;p] select from d}; {[t;p] select from (value t) where deleted = 0b}; `; `];
    .auth_svc.states:: (`pending`completed`expired`rejected!`int$(0 1 2 3));

    .gae_proxy.load_historical_data[];

    .gae_proxy.samples_fh:: `SAMPLES_FH;
    .gae_proxy.admin_svc:: `ADMIN_SVC;
    .gae_proxy.auth_svc:: `AUTH_SVC;
    .gae.message_types::
        ((enlist `T1)!enlist (.gae_proxy.admin_svc;`tls_register)),
        ((enlist `T2)!enlist (.gae_proxy.admin_svc;`tls_request_cert)),
        ((enlist `T3)!enlist (.gae_proxy.admin_svc;`tls_dh_xchange)),
        ((enlist `M1)!enlist (.gae_proxy.admin_svc;`.admin_svc.register_new_user)),
        ((enlist `M2)!enlist (.gae_proxy.admin_svc;`.admin_svc.register_new_device)),
        ((enlist `M3)!enlist (.gae_proxy.samples_fh;`.sp.sfh.sample_update)),
        ((enlist `M4)!enlist (.gae_proxy.auth_svc;`.auth_svc.auth_request)),
        ((enlist `M5)!enlist (.gae_proxy.admin_svc;`.admin_svc.check_user_id)),
        ((enlist `M6)!enlist (.gae_proxy.admin_svc;`.admin_svc.mobile_sync)),
        ((enlist `M7)!enlist (.gae_proxy.auth_svc;`.auth_svc.security_rank)),
        ((enlist `M8)!enlist (.gae_proxy.auth_svc;`.auth_svc.add_signs_batch)),
        ((enlist `M9)!enlist (.gae_proxy.auth_svc;`.auth_svc.reject_sample));
    .gae.pending_requests:: (`dummy;1)!(`;0Ni);
    :1b;
    };

.gae_proxy.load_historical_data: {[]
    func: "[.gae_proxy.load_historical_data]: ";
    .sp.log.info func, "loading data from hist...";    
    users_hst: `USERS_HIST; 
    .sp.ns.client.wait_for_ever[users_hst; `];


    up:(); s:();
    tbls: .sp.re.exec[users_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];
    if[ `sources in tbls;
        s: .sp.re.exec[users_hst;`;"delete date from select from (select from sources) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];

    if[ `user_permissions in tbls;
        up: .sp.re.exec[users_hst;`;"delete date from select from (select from user_permissions) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];

    .sp.log.info func, "HIST sources count: ", (raze string (count s));
    if[ (count s) > 0; 
        .sp.cache.tables[`sources]: s];
    .sp.log.info func, "HIST user_permissions count: ", (raze string (count up));
    if[ (count up) > 0; 
        .sp.cache.tables[`user_permissions]: up];
    .sp.log.info func, "Done loading historical data...";
  };


auth_request:{[hdl_k;uid;sid;extra]
    func: "[auth_request]: ";
    .sp.log.info func, "Received auth request for handle key: ", (raze string hdl_k);
    
    if[ not last exec last allow_any_user from .sp.cache.tables.sources where source_name = sid;
	.sp.log.info func, "allow_any_user is set to false for source ", (string sid), ". so will check further.";
	ct: count select from .sp.cache.tables.user_permissions where func = `auth_request, deleted = 0b, user_id = uid, source_name = sid;
	$[ 0 < ct; 
		.sp.log.info func, "we found the src and user in user_permission table. so all good"; 
		.sp.exception func, "User NOT permissioned. user = ", (string uid), " and source = ", (string sid) ] ];

    .sp.log.info func, "Initiating auth process for ", (raze string uid);
     res: .[.sp.re.exec;(.gae_proxy.auth_svc;`;(`.auth_svc.authenticate;uid;sid;extra);.sp.consts[`DEF_EXEC_TO]);{
       .sp.log.error "Failed to call auth func - ", (raze string x);
       .sp.exception "failed to call back-end: ", (raze string x)}];

   hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception msg];

    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    (neg hdl) (hdl_k;res);

    .sp.log.info func, "generic request complete for handle ", (string .z.w);
    :0b;
    };

auth_status_request:{[hdl_k;rid]
    func: "[auth_status_request]: ";
    .sp.log.info func, "Received auth status request for handle key: ", (raze string hdl_k), " and request_id: ", (raze string rid);
    res: .[.sp.re.exec;(.gae_proxy.auth_svc;`;(`.auth_svc.check_request;rid);.sp.consts[`DEF_EXEC_TO]);{
       .sp.log.error "Failed to call auth status func - ", (raze string x);
       .sp.exception "failed to call back-end: ", (raze string x)}];

    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception msg];

    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    (neg hdl) (hdl_k;res);

    .sp.log.info func, "generic request complete for handle ", (string .z.w);
    :0b;
    };

generic_request:{[hdl_k;x;y]
    func: "[generic_request]: ";
    if[ not (type x) in (10h;-11h);
      .sp.exception "bad message type - ", (raze string x)];

    fstr:  x;
    if[ (type x) = 10h; fstr: `$(x)];

    .sp.log.info func, "Received Request! Handle:", (string .z.w), " HKey: ",(raze string hdl_k) ," Type: ", (raze string x), " and data (type= ",(string type y),": [", (raze string (count y)), "]";
    last_update:: y;
    fname: .gae.message_types[fstr];
    if[ 1b = all (null fname);
      .sp.exception "Failed to locate function mapping"];

    $[0 = count gae_local; new_trx_id:1; new_trx_id: `long$1 + exec max trx_id from gae_local ];
    `gae_local insert (new_trx_id; .z.T; fstr; fname[1]; fname[0]; enlist -8!y; enlist -8!`NA; .z.T; .z.T)

    .sp.log.info func, "Calling specific func: ", (string fname[1]), " on service - ", (string fname[0]);
    .[.sp.re.exec;(fname[0];`;(fname[1];y;callback[hdl_k; new_trx_id]);.sp.consts[`DEF_EXEC_TO]);{
              .sp.log.error "Failed to call the specific func - ", (raze string x);
              .sp.exception "failed to call back-end: ", (raze string x)}];
     :0b;
  };

update_trx_tp:{ [data]
    func: "[update_trx_tp]: ";
    .sp.log.info func, "Sending transaction gae update";
    cmd: (`.sp.tp.upd;`gae;data);
    .sp.re.request[`TRX_TP;`;cmd;.sp.consts[`DEF_EXEC_TO]];
 };

callback:{[hdl_k; trx_id]
   {[hdl_k;trx_id;res;lh]
     func: "[callback(generic_request)]: ";
     .sp.log.info func, "calling result on handle ", (string lh), " for hdl_k: ", (string hdl_k), " trx_id = ", (string trx_id);
     lh (`process_response;hdl_k;trx_id;res);
     }[hdl_k; trx_id]
  };

process_response:{[hdl_k;trx_id;res]
    func: "[process_response]: ";
    .sp.log.info func, "starting... trx_id = ", (string trx_id);
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "starting...1";
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error msg;
        .sp.exception msg];

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


test_validation:{ [hdl_k;rid;real_flag]
    func: "[test_validation]: ";
    .sp.log.info func, "request validation called for rid: ", (raze string rid);
    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error msg;
        .sp.exception msg];

    .sp.log.info func, "calling auth svc...";

    cmd: (`.auth_svc.update_simulation_results;rid;real_flag);
    .sp.re.exec[`AUTH_SVC;`;cmd;.sp.consts[`DEF_EXEC_TO]];

    .sp.log.info func, "Sending result back on handle ",(string hdl);
    (neg hdl) (hdl_k;1b);

    .sp.log.info func, "generic request complete for handle ", (string .z.w);
  };

get_statistics:{[hdl_k;token]
    func: "[get_statistics]: ";
    .sp.log.info func, "start";
    t: .helper.validate_token token;
    usrs: .helper.get_allowed_users t;

    cmd: "select last_used: last `datetime$(date + time), success_rate: ceiling (((sum valid)%(count valid))*100), use_count: count valid by account_id from  (select from (select from ((select by sample_id from sample_status) lj (select last sample_type by sample_id from samples)) where sample_type = `REMOTE))";
    .sp.log.info func, "sending request to samples hist...";
    res: .sp.re.exec[`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";
    eee:: (hdl_k;(0!res));
    (neg hdl) eee;
    .sp.log.info func, "complete";
    :0b;
    };



get_usage_info:{[hdl_k;token]
    func: "[get_usage_info]: ";
    cmd: "select account_id, sample_id, date: `datetime$(date+time), gps_lat, gps_long, valid from (select from (select from ((select by sample_id from sample_status) lj (select last sample_type by sample_id from samples)) where sample_type = `REMOTE)) where gps_lat <> 0, gps_long <> 0";

    res: .sp.re.exec[`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";
    (neg hdl) (hdl_k;0!res);
    .sp.log.info func, "get_trends complete for handle ", (string .z.w);
    :0b;

    };

get_trends:{[hdl_k;token]
    func: "[get_trends]: ";
    cmd: "select date, 0^pass_c, 0^fail_c from ((select pass_c: count i by date from (select from ((select by sample_id from sample_status) lj (select last sample_type by sample_id from samples)) where sample_type = `REMOTE) where valid = 1b) lj (select fail_c: count i by date from (select from ((select by sample_id from sample_status) lj (select last sample_type by sample_id from samples)) where sample_type = `REMOTE) where valid = 0b))";
    
    res: .sp.re.exec[`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

    (neg hdl) (hdl_k;res);
    .sp.log.info func, "get_trends complete for handle ", (string .z.w);
    :0b;
    };

get_user_statistics:{[hdl_k;token;user_id]
    func: "[get_user_statistics]: "; 
    cmd: ({ select last_used: last `datetime$(date + time), success_rate: ceiling (((sum valid)%(count valid))*100), use_count: count valid by account_id from  (select from (select from ((select by sample_id from sample_status) lj (select last sample_type by sample_id from samples)) where sample_type = `REMOTE)) where account_id = x }; user_id);
    res1: .sp.re.exec[`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    cmd: ({ select first reg_date by account_id: name from users where name = x }; user_id);
    res2: .sp.re.exec[`USERS_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    cmd:({ `account_id xkey select account_id: user, device: {[a;b;c;d] ":" sv (a;b;c;d)}'[manufacturer;device_type;os;serial] from (select  string last manufacturer, string last device_type, string last os, string last serial by user from devices where user = x)};user_id);
    res3: .sp.re.exec[`USERS_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];

    res: ((res1 lj (`account_id xkey res2)) lj (`account_id xkey res3));
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

    (neg hdl) (hdl_k;0!res);
    .sp.log.info func, "get_trends complete for handle ", (string .z.w);
    :0b;

    };

get_user_profile:{[hdl_k;token;user_id]
    func: "[get_user_profile]: "; 

    cmd: ({ select date: `datetime$(date + time), sample_id, valid  from  (select from (select from ((select by sample_id from sample_status) lj (select last sample_type by sample_id from samples)) where sample_type = `REMOTE) where account_id = x) }; user_id);
    res: .sp.re.exec[`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

    (neg hdl) (hdl_k;res);
    .sp.log.info func, "get_trends complete for handle ", (string .z.w);
    :0b;
    
    };

get_user_sample:{[hdl_k;token;sample_id]
    func: "[get_user_sample]: "; 
    cmd: ({[xx] select x, y from samples where sample_id = (xx) }; (sample_id));

    res: .sp.re.exec[`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

    (neg hdl) (hdl_k;0!res);
    .sp.log.info func, "get_trends complete for handle ", (string .z.w);
    :0b;

    };


get_system_info:{[hdl_k;token]
    func: "[get_system_info]: "; 

    d: system "pwd";
    system raze ("cd /sp");
    version: last (" " vs ((system "git status")[0]));
    system raze ("cd ", d);
    user_count: last exec name from .sp.re.exec[`USERS_HIST;`;"select count distinct name from users";.sp.consts[`DEF_EXEC_TO]];
    daily_usage: .sp.re.exec[`SAMPLES_RT;`;"count (select by sample_id from samples where sample_type = `REMOTE)";.sp.consts[`DEF_EXEC_TO]];
    monthly_usage: daily_usage + (.sp.re.exec[`SAMPLES_HIST;`;"count (select by sample_id from samples where sample_type = `REMOTE)";.sp.consts[`DEF_EXEC_TO]]);

    res: (version;user_count;daily_usage;monthly_usage);
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

    (neg hdl) (hdl_k;res);
    .sp.log.info func, "get_trends complete for handle ", (string .z.w);
    :0b;
    };

open_issue: {[hdl_k;token;ttl;msg]
    func: "[open_issue]: "; 
    title: raze ("DASHBOARD ISSUE: ", ttl);
    body: msg;
    cmd: "curl -i -H 'Authorization: token 71da17bbafc6d50eb939d7272925bedc6d948d54' -d '{ \"title\": \"",title,"\", \"body\": \"", body ,"\", \"labels\":[\"dashboard\"]}' https://api.github.com/repos/eschnapp/signpass/issues";
    res: system cmd;
    if[ any (res[0] <> "HTTP/1.1 201 Created");
        .sp.exception "Failed"];
    res: (-1_(ssr[(res[35]); "  \"number\": "; ""]));
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

     (neg hdl) (hdl_k;res);

    };

reset_user:{[hdl_k;token;user_id]
    func: "[reset_user]: "; 

    // disable user...
    dhst: 0!.sp.re.exec[`USERS_HIST;`;({delete date from (select by name from users where name = x)}; user_id);.sp.consts[`DEF_EXEC_TO]];
    drt:  0!.sp.re.exec[`USERS_RT;`;({select by name from users where name = x}; user_id);.sp.consts[`DEF_EXEC_TO]];
    data: update deleted: 1b from ( select by name from (dhst,drt));
    cmd: (`.sp.tp.upd;`users;0!(data));
    .sp.re.exec[`USERS_TP;`;cmd;.sp.consts[`DEF_EXEC_TO]];

    // disable devices...
    dhst: 0!.sp.re.exec[`USERS_HIST;`;({delete date from (select by user, serial from devices where user = x)}; user_id);.sp.consts[`DEF_EXEC_TO]];
    drt:  0!.sp.re.exec[`USERS_RT;`;({(select by user, serial from devices where user = x)}; user_id);.sp.consts[`DEF_EXEC_TO]];
    data: update deleted: 1b from ( select by user, serial from (dhst,drt));
    cmd: (`.sp.tp.upd;`devices;0!(data));
    .sp.re.exec[`USERS_TP;`;cmd;.sp.consts[`DEF_EXEC_TO]];

    // disable samples...
    dhst: 0!.sp.re.exec[`SAMPLES_HIST;`;({delete date from (select by sample_id from sample_status where account_id = x)}; user_id);.sp.consts[`DEF_EXEC_TO]];
    drt:  0!.sp.re.exec[`SAMPLES_RT;`;({(select by sample_id from sample_status where account_id = x)}; user_id);.sp.consts[`DEF_EXEC_TO]];
    data: update deleted: 1b from ( select by sample_id from (dhst,drt));
    cmd: (`.sp.tp.upd;`sample_status;0!(data));
    .sp.re.exec[`SAMPLES_TP;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    .sp.log.info func, "looking for pending request...";
    hdl: .gae.pending_requests[hdl_k];
    .sp.log.info func, "sending async result...";

     (neg hdl) (hdl_k;1b);
    :0b;
    };

.helper.validate_token: { [tkn]
    func: "[.helper.validate_token]: ";
    t: select from .sp.cache.tables.requests where token = tkn;
    $[ 0 >= count t; .sp.exception func, "No User found with this token: ", (raze string tkn); t:last t];
    if[ (last t`status) in (.auth_svc.states`expred; .auth_svc.states`rejected); .sp.exception func, "token : ", (raze string tkn), " expired/rejected" ];
    :t;    
  };

.helper.get_allowed_users: { [uid]
    allowed_sources: exec distinct source_name from .sp.cache.tables.user_permissions where user_id = res[uid], func=`admin;
    :allowed_users: exec distinct user_id from .sp.cache.tables.user_permissions where source_name in allowed_sources, func = `auth_request;
  };

.sp.comp.register_component[`gae_proxy;enlist `common;.gae_proxy.on_comp_start];
