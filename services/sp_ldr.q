.boot.include (gdrive_root, "/framework/common.q");

.sp.ldr.on_comp_start:{
    func : "[.sp.ldr.on_comp_start] : ";
    .sp.log.info func, "Starting...";
    .sp.ldr.load_data[];
    .sp.log.info func, "Completed...";
    :1b;
    };

.sp.ldr.load_data:{ []
    .sp.ldr.load_users[];
    .sp.ldr.load_samples[];
  };

.sp.ldr.load_users: { []
    func:"[.sp.ldr.load_users] : ";
    cmd : "update time:.z.T from delete date from select from (cols users) xcols 0!select by name from users where date = max date";
    res: .[.sp.re.exec;(`USERS_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]);{ [x;cmd;func]
       .sp.log.error func, "query [", cmd, "] failed due to : - ", (raze string x)}[;cmd; func] ];
    .sp.re.exec[`USERS_TP; `; (`.sp.tp.upd;`users;res); .sp.consts[`DEF_EXEC_TO] ];
    .sp.log.info func, "published ", (string (count res)), " rows to users table";
    
    cmd : "update time:.z.T from delete date from select from devices where date = max date";
    res: .[.sp.re.exec;(`USERS_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]);{ [x;cmd;func]
       .sp.log.error func, "query [", cmd, "] failed due to : - ", (raze string x)}[;cmd; func] ];
    .sp.re.exec[`USERS_TP; `; (`.sp.tp.upd;`devices;res); .sp.consts[`DEF_EXEC_TO] ];
    .sp.log.info func, "published ", (string (count res)), " rows to devices table";
       
    cmd : "update time:.z.T from delete date from select from sources where date = max date";
    res: .[.sp.re.exec;(`USERS_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]);{ [x;cmd;func]
       .sp.log.error func, "query [", cmd, "] failed due to : - ", (raze string x)}[;cmd; func] ];
    .sp.re.exec[`USERS_TP; `; (`.sp.tp.upd;`sources;res); .sp.consts[`DEF_EXEC_TO] ];
    .sp.log.info func, "published ", (string (count res)), " rows to sources table";
    .sp.log.info func, "All done!";   
    };

.sp.ldr.load_samples: { [] 
    func:"[.sp.ldr.load_samples] : ";

    cmd : "update time : .z.T from delete date from select from sample_status where date = max date, valid = 1b";
    res: .[.sp.re.exec;(`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]);{ [x;cmd;func]
       .sp.log.error func, "query [", cmd, "] failed due to : - ", (raze string x)}[;cmd; func] ];
    .sp.re.exec[`SAMPLES_TP; `; (`.sp.tp.upd;`sample_status;res); .sp.consts[`DEF_EXEC_TO] ];
    .sp.log.info func, "published ", (string (count res)), " rows to sample_status table";
       
    cmd : "update time : .z.T from delete date from select from samples where date = max date, sample_id in (select sample_id from sample_status where date = max date, valid = 1b)[`sample_id]";
    res: .[.sp.re.exec;(`SAMPLES_HIST;`;cmd;.sp.consts[`DEF_EXEC_TO]);{ [x;cmd;func]
       .sp.log.error func, "query [", cmd, "] failed due to : - ", (raze string x)}[;cmd; func] ];
    .sp.re.exec[`SAMPLES_TP; `; (`.sp.tp.upd;`samples;res); .sp.consts[`DEF_EXEC_TO] ];
    .sp.log.info func, "published ", (string (count res)), " rows to samples table";
    .sp.log.info func, "All done!";   
  };

.sp.comp.register_component[`sp_ldr;enlist `common;.sp.ldr.on_comp_start];

