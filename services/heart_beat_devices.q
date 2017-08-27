.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/data_convert.q");
.boot.include (gdrive_root, "/framework/cache.q");

.hb_svc.on_comp_start:{
    func : "[.hb_svc.on_comp_start] : ";
    .sp.cache.add_clients[`USERS_RT; `users; {[d;p] select by name from d}; {[t;p] select from (select by name from (value t)) where deleted = 0b}; `; `];

    .sp.cache.add_callback_handler[`hb_svc;`REQUESTS_RT;`requests;.hb_svc.on_update;.hb_svc.on_ready];
    .sp.cache.add_clients[`REQUESTS_RT; `requests; {[d;p] select distinct uid by gcm_reg_ids from d}; {[t;p] select distinct uid by gcm_reg_ids from requests}; `; `];

    .sp.log.info func, "ready..";
    :1b;
  };

.hb_svc.on_update:{[svc;topic;data; type_]
    func: "[.hb_svc.on_update]: ";
    .sp.log.info func, (string svc), ":", (string topic), ":", (string type_), " - row count = ", (string (count data));
    if[topic = `requests;
        .hb_svc.prv.send_heart_beat ./: (flip value flip select gcm_reg_ids, uid from data) ];
  };

.hb_svc.on_ready:{[svc;topic]
    .sp.log.info "[.hb_svc.on_ready]: ", (raze string svc), " - ", (raze string topic);
 };

.hb_svc.prv.send_heart_beat: {[gcm_reg_ids; uids]
    .hb_svc.publish_heart_beat[; uids] each gcm_reg_ids;
  };


.hb_svc.send_heart_beats: {
    func: "[.hb_svc.send_heart_beats] : ";
    // get all gcm_reg_ids 
    t: select gcm_reg_id from (select last gcm_reg_id, last deleted  by user  from .sp.cache.tables.devices) where deleted = 0b;
    .hb_svc.publish_heart_beat each t`gcm_reg_id;
    .sp.log.info func, "sending heart beat completed...";
  };


.hb_svc.publish_heart_beat: {[gcm_reg_id; uids]
    func: "[.hb_svc.publish_heart_beat]: ";

    .sp.log.info func, "Sending GCM request for gcm_reg_id ", (raze string gcm_reg_id);
    // make packet
    packet:: (.z.Z; uids);
    api_key: .sp.cfg.get_value[`api_key;`$("AIzaSyDaLgwHG9Fa7gWRLtYGH4cdrIdfZ1in53g")];
    project_id: .sp.cfg.get_value[`project_id; `155670482643];

    // serialize
    .sp.log.info func, "Serializing packet...";
    data:: .sp.dc.serialize packet;
    pld:: .sp.dc.b64_enc[`long$data];
    // prepare cmd
    cmd:: gdrive_root, "/development/python/gcm_notify/send_update.sh --api_key ",(string api_key), " --project ", (string project_id);
    cmd:: cmd, (" --reg_id ", (string gcm_reg_id), " ");
    cmd:: cmd, " --param \"{\\\"type\\\":\\\"U1\\\",\\\"payload\\\":\\\"",(pld),"\\\"}\"";

    // send gcm
    .sp.log.info "Sending GCM update: [", cmd, "]";
    res: system cmd;
    .sp.log.info "GCM Update sent, result: ", (raze res);
    };

.sp.comp.register_component[`hb_svc;`cache`common;.hb_svc.on_comp_start];
