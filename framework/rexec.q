.boot.include (gdrive_root, "/framework/core.q");
.boot.include (gdrive_root, "/framework/nsclient.q");

.sp.re.get_handle: { [zone_; svc_; inst_; to_]
	func: "[.sp.re.get_handle] : ";
	h : 0h;
	in_cache : .sp.re.get_connections[zone_; svc_; inst_];
	if[ (count in_cache) > 0; : exec first handle from in_cache];
	
	disco : $[null inst_; .sp.ns.client.discover_next[svc_]; .sp.ns.client.discover[.sp.ns.client.zone; svc_; `inst; inst_] ];
	if[ 0 = count disco; .sp.log.warn func, "Failed to discover svc. zone = [", (string zone_), "] svc = [", (string svc_), "] inst = [", (string inst_), "]"; :-1 ];

	addr : first disco[`address];
	port : first disco[`port];
	addr : `$((string addr), ":", (string port));
	hdl: .[.sp.io.open_port; (addr; to_); {.sp.exception "[.sp.re.get_handle] : .sp.io.open_port failed due to : ", x } ];
	if[null inst_; inst_:first disco[`inst] ];
	if[ 1b = .sp.re.cache_connections; .sp.re.add_connections[zone_; svc_; inst_; hdl] ];
	:hdl;
  };
  
.sp.re.request: { [svc_; inst_; cmd_; to_]
    handle : .sp.re.get_handle[.sp.ns.client.zone; svc_; inst_; to_];
    :.sp.io.async[handle; cmd_];
  };
  
.sp.re.exec: { [svc_; inst_; cmd_; to_]
    handle : .sp.re.get_handle[.sp.ns.client.zone; svc_; inst_; to_];
    :.sp.io.sync[handle; cmd_];
  };

.sp.re.get_connections:{ [zone_; svc_; inst_]
	if[ 1b = (null inst_); :select from .sp.re.cached_connections where zone = zone_, service = svc_ ];
	if[ 0b = (null inst_); :select from .sp.re.cached_connections where zone = zone_, service = svc_, inst = inst_ ];
  };
  
.sp.re.remove_connections:{ [hdl_]
    .sp.log.debug "[.sp.re.remove_connections] : Removing the handle ", (string hdl_), " from cached connections table";
	delete from `.sp.re.cached_connections where handle = hdl_;
  };
  
.sp.re.add_connections:{ [zone_; svc_; inst_; hdl_]
	if[ hdl_ < 0; :-1];
	`.sp.re.cached_connections insert (zone_; svc_; inst_; hdl_ );
	.sp.log.debug "[.sp.re.add_connections] : Added zone :", (string zone_), " svc :", (string svc_), " inst : ", (string inst_), " and hdl : ", (string hdl_);	
  };
  
.sp.re.on_comp_start:{ []
	func: "[.sp.re.on_comp_start] : ";
	.sp.re.cache_connections :: "B"$.sp.arg.optional[`cache_connections; 1];
	.sp.re.cached_connections :: ([zone:`$(); service:`$(); inst:`$()] handle:`int$() );
	.sp.log.info func, "component rexec ready";
	:1b;
  };
  
.sp.comp.register_component[`rexec; `core`nsclient; .sp.re.on_comp_start];
  
  
  
  
  
  
  
  
  
  
  
