.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/data_convert.q");
.boot.include (gdrive_root, "/framework/cache.q");

.rz.rust.fh.on_comp_start:{
    func : "[.rz.rust.fh.on_comp_start] : ";
    .sp.log.info func, "Starting...";
    .rz.rust.fh.connections:: ([server_id: `$()]; handle: `int$());
    .rz.rust.fh.ready:: 0b;
    .rz.rust.fh.timer_ival:: 5000; // 5 second to start with on updates...

    .sp.log.info func, "Setting up the websocket handler";
    .z.ws: .rz.rust.fh.on_remote_update;

    .rz.rust.fh.serverdefs::
         ([] server_id: enlist 1i;hostname: enlist ("sp-devwin1.eastus.cloudapp.azure.com"); rcon_port: enlist 28016i;rcon_pwd: enlist ("none4u"));

    .rz.rust.fh.open_connection ./: (flip value flip (select server_id, hostname, rcon_port, rcon_pwd from svrs));

    // start the timer...
    .sp.cron.add_timer[.rz.rust.fh.timer_ival; -1; .rz.rust.fh.on_timer];

    .sp.log.info func, "Completed...";
    :1b;
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
        if[ res[`Type] = `Generic;
            .rz.rust.fh.process_generic_msg[sid;res]];

        if[ res[`Type] = `Chat;
            .rz.rust.fh.process_chat_msg[sid;res]];         
  };

.rz.rust.fh.process_generic_msg:{[sid;data]
        msg: data[`Message];
        id: data[`Identifier];

        record: ([] time: enlist .z.T; server_id: enlist sid; msg: enlist msg; identifier: enlist id);
        .sp.re.exec[`RUST_RT;`;(`.sp.tp.upd;`events;record);5000];
    };


.rz.rust.fh.process_chat_msg:{[sid;data]
        obj: .j.k data[`Message];
        record: ([] time: enlist .z.T;
                    msg: enlist obj[`Message];
                    userid: enlist obj[`UserId];
                    username: enlist obj[`Username];
                    color: enlist obj[`Color];
                    server_time: enlist obj[`Time]);
        .sp.re.exec[`RUST_RT;`;(`.sp.tp.upd;`chat;record);5000];
    };
  
.sp.comp.register_component[`rust_fh;`common`cache;.rz.rust.fh.on_comp_start];

