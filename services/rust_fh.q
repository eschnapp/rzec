.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/data_convert.q");
.boot.include (gdrive_root, "/framework/cache.q");

.rz.rust.fh.on_comp_start:{
    func : "[.rz.rust.fh.on_comp_start] : ";
    .sp.log.info func, "Starting...";
    .rz.rust.fh.connections:: ([server_id: `$()]; handle: `int$());
    .rz.rust.fh.ready:: 0b;
    .sp.log.info func, "Setting up the websocket handler";
    .z.ws: .rz.rust.fh.on_remote_update;
	
    .sp.log.info func, "Subscribing to servers tickerplant data";
    .rz.rust.fh.servers_rt:: `SERVERS_RT;
    .sp.cache.add_callback_handler[`sfh;.rz.rust.fh.servers_rt;`server_defs;.rz.rust.fh.on_serverdef_update;.rz.rust.fh.on_serverdef_ready];
    .sp.cache.add_clients[.rz.rust.fh.servers_rt;`server_defs;{[d;p] select by server_id from d}; {[t;p] select by server_id from (value t)};`; `];

    //.sp.log.info func, "Adding the expiration timer...";
    //.rz.rust.fh.timer_id:: .sp.cron.add_timer[1000;-1;.rz.rust.fh.on_timer];

    .sp.log.info func, "Completed...";
    :1b;
    };

.rz.rust.fh.on_serverdef_ready:{[svc;topic]
    func: "[.rz.rust.fh.on_serverdef_ready]: ";
    .sp.log.debug func, "Server definitions synchronized, opening sockets to all rust servers...";
    svrs: select from .sp.cache.tables[`server_defs] where game_type = `rust;
    show svrs;
    .rz.rust.fh.open_connection ./: (flip value flip (select server_id, hostname, rcon_port, rcon_pwd from svrs));
	
    };

.rz.rust.fh.on_serverdef_update:{[svc;topic;data;upd_type]
    func: "[.rz.rust.fh.on_serverdef_update]: ";
    .sp.log.debug func, "SERVERDEF UPDATE...!";   
    if[ upd_type = `update;
        .rz.rust.fh.open_connection ./: (flip value flip (select server_id, hostname, rcon_port, rcon_pwd from data))];
  };


.rz.rust.fh.open_connection:{ [sid;hname;rcport;rcpwd]
	func: "[.rz.rust.fh.open_connection]: ";
	r:(`$":ws://",(string hname),":",(string rcport))"GET /",(string rcpwd)," HTTP/1.1\r\nHost: ",(string hname),":",(string rcport),"\r\n\r\n";
	if[ (type r) <> 0h; 
		.sp.log.error func, "Failed to open handle to remote server...";
		show r;
		.sp.exception "bad response"];
		
	if[ r[0] = 0Ni; 
		.sp.log.error func, "Received bad response: ", r[1];
		.sp.exception "failed to open"];
		
	`.rz.rust.fh.connections upsert ([server_id: enlist sid]; handle: enlist r[0]);
	:1b;
  };

.rz.rust.fh.on_remote_update:{[data]
	func: "[.rz.rust.fh.on_remote_update]: ";
	.sp.log.info func, "Remote Update...";
        res: .j.k data;
        show res;

        hdl: .z.w;
        sid: first exec server_id from .rz.rust.fh.connections where handle = hdl;
        if[ null sid;
            .sp.log.error func "Failed to locate the server id for the remote update!";
            :0b];
 
        record: ([] time: enlist .z.T; server_id: enlist sid; msg: enlist (res[`Message]); identifier: enlist `int$(res[`Identifier]); msg_type: enlist `$(res[`Type]); stack_trace: enlist (res[`Stacktrace]));

       .sp.re.exec[`RCON_TP;`;(`.sp.tp.upd; `rust; record);3000]; 
  };
  
.sp.comp.register_component[`rust_fh;`common`cache;.rz.rust.fh.on_comp_start];

