.boot.include (gdrive_root, "/framework/config_service.q");
.boot.include (gdrive_root, "/framework/alias_svc.q");
.boot.include (gdrive_root, "/framework/nameserver.q");


.sp.server.on_comp_start: { []
    func: "[.sp.server.on_comp_start] : ";
    zone : `$ .sp.arg.required[`zone];
    name : `$ .sp.arg.required[`svc_name];
    port : `$ .sp.arg.required[`in_port];
    def_srvr_inst : `$ .sp.arg.optional[`instance; "0"];
    .sp.ns.server.add_svc_to_exclude_liveliness_chks[name];
    .sp.ns.server.announce[zone; name; def_srvr_inst; port; `q];
    
    
    .sp.log.info func, "component server is ready";
    :1b;
  };
  
  qstudio:{[]
    :([] name: `${"" sv x} each string ((flip value flip (select svc, t1: "@", address, t2: ":", port from .sp.ns.server.services))));
    };

//  qpad:{ :([] x: 
//	{
//		a: "@" vs (string x);
//		b:":" vs a[1];
//		:`$("`:",(":" sv  ( b[0];b[1];("`research`",a[0]))));
//	} each (exec name from qstudio[] )); 
  // };

qpad: { select {[a;p;z;s;inst] 
    dir: first "_" vs string s;
    : `$"`:", (string a), ":", (string p), ":`", (string z), "`", dir, "`", (string s), "_", (string inst) } ' [address; port; zone; svc; inst] from .sp.ns.server.discover_all[`$.sp.arg.required[`zone] ]
  };

  
  .sp.comp.register_component[`server; `config_service`nameserver; .sp.server.on_comp_start];
  
  
