.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");
.boot.include (gdrive_root, "/services/gae_prxy_lib.q");
.boot.include (gdrive_root, "/framework/utils.q");

.gae_proxy.on_comp_start:{
    gae_local:: ([trx_id: `long$()] time: `time$();func_type: `$(); func_name: `$(); svc_name: `$(); input_data: ();output_data: ();
           request_time: `time$();
           response_time: `time$());

    .sp.cache.add_clients[`USERS_RT; `domain; {[d;p] 0!(select by fq_name from d)}; {[t;p] select from 0!(select by fq_name from value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`USERS_RT; `user_permissions; {[d;p] 0!(select by user_id, domain, role  from d)}; {[t;p] select from 0!(select by user_id, domain, role from value t) where deleted = 0b}; `; `];
    .sp.cache.add_clients[`REQUESTS_RT; `requests; {[d;p] select by request_id from d}; {[t;p] select by request_id from (value t)  }; `; `];

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
    .sp.ns.client.wait_for_ever[`REQUESTS_HIST; `];

    tbls: .sp.re.exec[users_hst;`; "tables `."; .sp.consts[`DEF_EXEC_TO]];

    if[ `sources in tbls;
        s: .sp.re.exec[users_hst;`;"delete date from select from (select from sources) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
    if[ `user_permissions in tbls;
        up: .sp.re.exec[users_hst;`;"delete date from select from (select from user_permissions) where deleted = 0b"; .sp.consts[`DEF_EXEC_TO]] ];
    if[ `requests in tbls;
        req: .sp.re.exec[`REQUESTS_HIST;`;"delete date from (select by request_id from requests)"; .sp.consts[`DEF_EXEC_TO]] ];
    if[ `domain in tbls;
        dom: .sp.re.exec[`USERS_HIST;`;"delete date from (select by fq_name from domain)"; .sp.consts[`DEF_EXEC_TO]] ];


    .sp.log.info func, "HIST sources count: ", (raze string (count s));
    if[ (count s) > 0;
        .sp.cache.tables[`sources]: s];
    .sp.log.info func, "HIST user_permissions count: ", (raze string (count up));
    if[ (count up) > 0;
        .sp.cache.tables[`user_permissions]: up];
    if[ (count req) > 0;
        .sp.cache.tables[`requests]: req];
    if[ (count dom) > 0;
        .sp.cache.tables[`domain]: dom];


    .sp.log.info func, "Done loading historical data...";
  };


auth_request:{[hdl_k;usrid;srcid;extra]
    func: "[auth_request]: ";
    .sp.log.info func, "Received auth request for handle key: ", (raze string hdl_k);

    $[0 = count gae_local; new_trx_id:1; new_trx_id: `long$1 + exec max trx_id from gae_local ];
    `gae_local insert (new_trx_id; .z.T; `; `.auth_svc.authenticate; .gae_proxy.auth_svc; enlist -8!(usrid;srcid;extra); enlist -8!`NA; .z.T; .z.T);

    if[ last exec last secured from .sp.cache.tables.domain where fq_name = srcid;
	.sp.log.info func, "secured is set to true for source ", (string srcid), ". so will check further.";
	ct: count select from .sp.cache.tables.user_permissions where role = `role.domain.member, deleted = 0b, user_id = usrid, domain = srcid;
	$[ 0 < ct;
		.sp.log.info func, "we found the src and user in user_permission table. so all good";
		.sp.exception to_json[ API_ERRORS[`USR_NOT_PERMISSIONED];  func, "User NOT permissioned. user = ", (string usrid), " and source = ", (string srcid) ] ] ];

    // check if request allready exists for this usrid/srcid... if exists and its not expired yet, then just return the request id for that request...
    res: `bad_key;
    r:  select from (select by request_id from .sp.cache.tables.requests) where uid =  usrid, sid = srcid, status < 1;
    .sp.log.info func, "Count of exiting requests for this user/source: ", (string count r);
    $[ (count r) > 0;
        [ 
          res:  last exec request_id from r;
          .sp.log.info func, "Returning exiting valid request_id: ", (raze string res);
        ];
        [ 
           .sp.log.info func, "Initiating auth process for ", (raze string usrid);
           res: .[.sp.re.exec;(.gae_proxy.auth_svc;`;(`.auth_svc.authenticate;usrid;srcid;extra);.sp.consts[`DEF_EXEC_TO]);{
               .sp.log.error "Failed to call auth func - ", (raze string x);
               .sp.exception to_json[API_ERRORS[`FAIL_TO_CALL_BACKEND];"failed to call back-end: ", (raze string x)] }];
           .sp.log.info func, "Auth request completed...";
        ]
    ];
    .sp.log.info func, "auth_request complete, result id: ", (raze string res);
    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg] ];

    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    (neg hdl) (hdl_k;res);


    .sp.log.info func, "auth request complete for handle ", (string .z.w);
    :0b;
    };

auth_status_request:{[hdl_k;tkn]
    func: "[auth_status_request]: ";
    .sp.log.info func, "Received auth status request for handle key: ", (raze string hdl_k), " and request_id: ", (raze string tkn);

    ctx:: .gpl.validate_token tkn;

    if[ last exec last secured from .sp.cache.tables.domain where fq_name = last ctx[`sid];
	.sp.log.info func, "secured is set to true for source ", (string last ctx[`sid]), ". so will check further.";
	ct: count select from .sp.cache.tables.user_permissions where role = `role.domain.member, deleted = 0b, user_id = last ctx[`uid], domain = last ctx[`sid];
	$[ 0 < ct;
		.sp.log.info func, "we found the src and user in user_permission table. so all good";
		.sp.exception to_json[ API_ERRORS[`USR_NOT_PERMISSIONED];  func, "User NOT permissioned. user = ", (string  last ctx[`uid]), " and source = ", (string last ctx[`sid]) ] ] ];

    res: .[.sp.re.exec;(.gae_proxy.auth_svc;`;(`.auth_svc.check_request;tkn);.sp.consts[`DEF_EXEC_TO]);{
       .sp.log.error "Failed to call auth status func - ", (raze string x);
       .sp.exception to_json[API_ERRORS[`FAIL_TO_CALL_BACKEND];"failed to call back-end: ", (raze string x)] } ];

    hdl: .gae.pending_requests[hdl_k];
    if[ 1b = (null hdl);
        msg; "Failed to locate the return connection handle for key " , (raze string hdl_k);
        .sp.log.error func, msg;
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg] ];

    .sp.log.info func, "Sending result back on handle ",(string hdl)," - Result type: ", (string type res);
    (neg hdl) (hdl_k;res);

    .sp.log.info func, "complete for handle ", (string .z.w);
    :0b;
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
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg] ];

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
        .sp.exception to_json[API_ERRORS[`NO_RET_HDL]; msg]  ];

    .sp.log.info func, "calling auth svc...";
    $[0 = count gae_local; new_trx_id:1; new_trx_id: `long$1 + exec max trx_id from gae_local ];
    `gae_local insert (new_trx_id; .z.T; `; `.auth_svc.update_simulation_results; `AUTH_SVC; enlist -8!(rid;real_flag); enlist -8!`NA; .z.T; .z.T);

    cmd: (`.auth_svc.update_simulation_results;rid;real_flag);
    .sp.re.exec[`AUTH_SVC;`;cmd;.sp.consts[`DEF_EXEC_TO]];

    .sp.log.info func, "Sending result back on handle ",(string hdl);
    (neg hdl) (hdl_k;1b);

    .sp.log.info func, "generic request complete for handle ", (string .z.w);
  };

.sp.comp.register_component[`gae_sp_proxy;enlist `common;.gae_proxy.on_comp_start];
