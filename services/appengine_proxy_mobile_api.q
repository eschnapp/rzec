.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");
.boot.include (gdrive_root, "/framework/utils.q");

.gae_proxy.on_comp_start:{
    gae_local:: ([trx_id: `long$()] time: `time$();func_type: `$(); func_name: `$(); svc_name: `$(); input_data: ();output_data: ();
           request_time: `time$();
           response_time: `time$());

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

generic_request:{[hdl_k;x;y]
    func: "[generic_request]: ";
    if[ not (type x) in (10h;-11h);
      .sp.exception to_json[API_ERRORS[`BAD_MSG_TYPE]; "bad message type - ", (raze string x)] ];

    fstr:  x;
    if[ (type x) = 10h; fstr: `$(x)];

    .sp.log.info func, "Received Request! Handle:", (string .z.w), " HKey: ",(raze string hdl_k) ," Type: ", (raze string x), " and data (type= ",(string type y),": [", (raze string (count y)), "]";
    last_update:: y;
    fname: .gae.message_types[fstr];
    if[ 1b = all (null fname);
      .sp.exception to_json[ API_ERRORS[`NO_FUNC_MAP]; "Failed to locate function mapping"] ];

    $[0 = count gae_local; new_trx_id:1; new_trx_id: `long$1 + exec max trx_id from gae_local ];
    `gae_local insert (new_trx_id; .z.T; fstr; fname[1]; fname[0]; enlist -8!y; enlist -8!`NA; .z.T; .z.T);

    .sp.log.info func, "Calling specific func: ", (string fname[1]), " on service - ", (string fname[0]);
    .[.sp.re.exec;(fname[0];`;(fname[1];y;callback[hdl_k; new_trx_id]);.sp.consts[`DEF_EXEC_TO]);{
              .sp.log.error "Failed to call the specific func - ", (raze string x);
              .sp.exception to_json[ API_ERRORS[`FAIL_TO_CALL_BACKEND]; "failed to call back-end: ", (raze string x)] } ];
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
        .sp.exception to_json[ API_ERRORS[`NO_RET_HDL]; msg ] ];

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

.sp.comp.register_component[`gae_mob_proxy;enlist `common;.gae_proxy.on_comp_start];
