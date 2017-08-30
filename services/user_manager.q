.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");

.rz.userman.on_comp_start:{[]

     func: "[.rz.userman.on_comp_start]: ";

    .sp.log.info func "Adding all the user level cache clients ...";
    .sp.cache.add_clients[`USERS_RT;`users;{[d;p] select by user_id from d }; {[t;p] select from (select by user_id from (value t)) where deleted = 0b};`; `];
    .sp.cache.add_clients[`USERS_RT;`user_roles;{[d;p] select by user_id from d }; {[t;p] select from (select by user_id from (value t)) where deleted = 0b};`; `];
    .sp.cache.add_clients[`USERS_RT;`roles;{[d;p] select by role, access_level from d}; {[t;p] select from (select by role, access_level from (value t)) where deleted = 0b};`; `];
    .sp.cache.add_clients[`USERS_RT;`points;{[d;p] select by user_id from d}; {[t;p] select from (select by user_id from (value t)) where deleted = 0b };`; `];

    .sp.log.info func, "User Manager is ready...";
    };
    
               
.rz.userman.get_user_by_steamid:{[steamid]

  r: select from .sp.cache.tables[`users] where 


  }; 
.sp.comp.register_component[`user_mgr;enlist `common`cache;.sp.cache.on_comp_start];

