.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");

.rz.rust.cep.on_comp_start:{[]
    func: "[.rz.rust.cep.on_comp_start]: ";

    .sp.log.info func, "Subscribing to RCON traffic from all rust servers...";
    .sp.cache.add_callback_handler[`rust_cep;`RCON_RT;`rust;.rz.rust.cep.on_update;.rz.rust.cep.on_ready];
    .sp.cache.add_clients[`RCON_RT;`rust;{[d;p] select from d}; {[t;p] select from (value t)};`; `];

    };
    
    
.rz.rust.cep.on_update:{[svc;topic;data;upd_type]
    func: "[.rz.rust.cep.on_ready]: ";
    
    .rz.rust.cep.process_chat_updates ./: flip value flip (select sid, msg from data where msg_type = `Chat);

    .rz.rust.cep.process_generic_updates[ (select from data where msg_type = `Generic) ];    

    };


.rz.rust.cep.on_ready:{[svc;topic]
    func: "[.rz.rust.cep.on_ready]: ";
    .sp.log.info func;
    };
                
.rz.rust.cep.process_chat_updates:{[sid;msg]
    func: "[.rz.rust.cep.process_chat_updates]: ";
    json: .j.k msg;

    :
    
    

    };
.sp.comp.register_component[`rust_cep;enlist `common`cache;.rz.rust.cep.on_comp_start];
