.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");

.auto_calib.on_comp_start:{
    func: "[.auto_calib.on_comp_start] : ";
    .auto_calib.users_rt:: `USERS_RT; 
    .auto_calib.samples_rt:: `SAMPLES_RT; 
    
    // users
    .sp.cache.add_clients[.auto_calib.users_rt; `users; {[d;p] select by name from d}; {[t;p] select from (select by name from (value t)) where deleted = 0b}; `; `];
    // samples
    .sp.cache.add_clients[.auto_calib.samples_rt; `sample_status; {[d;p] select by sample_id from d}; {[t;p] select from (select by sample_id from (value t)) where deleted = 0b}; `; `];    
    
    tid: .sp.cron.add_timer[ 1000*60*60;-1;{ [t;i] .auto_calib.calibrate[] } ]; // calibrate once an hour
    .sp.log.info func, "timer setup completed. timer id: ", (raze string tid);
    :1b;
  };
   
.auto_calib.calibrate: { 
    func: "[.auto_calib.calibrate]: ";
    usrs: select from (select by name from .sp.cache.tables.users) where deleted = 0b;
    sst: select from (select by sample_id from .sp.cache.tables.sample_status where account_id in exec name from usrs) where deleted = 0b;
    sst: update num_valid: (count i ) by account_id from sst where valid = 1b;
    sst: update num_total: (count i ) by account_id from sst;
    sst: update num_valid: 0^num_valid, num_total: 0^num_total from sst;
    sst: update wnd_size: 0^num_valid from sst;
    sst: update fail_rate: num_valid%num_total from sst;
    registration_sample_size : 10;
    sst: update op : max(0; 0.12 - fail_rate * max(1; wnd_size%num_total) ) from sst;
    sst: update bp : 0.1 + fail_rate + registration_sample_size % num_total from sst;
    final: `name xkey select distinct name:account_id, op, bp from sst;
    new_usr_prms:usrs lj final; 

    .sp.log.info func, "Modified user info will be written to users tickerplant... Count = ", (raze string (count new_usr_prms));    
    cmd : ( `.sp.tp.upd; `users; new_usr_prms );
    users_tp : `USERS_TP; 
    .sp.re.exec[ users_tp; `; cmd; .sp.consts[`DEF_EXEC_TO] ];

    .sp.log.info func, "Calibration complete!";
    :new_usr_prms;
  };


.sp.comp.register_component[`auto_calib;`cache`common;.auto_calib.on_comp_start];
 
 