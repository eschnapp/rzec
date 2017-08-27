/ nameserver 
.boot.include (gdrive_root, "/framework/core.q");

.sp.ns.server.hb_client: { [] 
    func : "[.sp.ns.server.hb_client] : "; 
    h: .z.w; 
    update lasthb: `timestamp$.z.Z, status: `live from `.sp.ns.server.services where handle = h; 
    .sp.log.debug func, "Service HB: ", (":" sv string (h; .Q.host .z.a;.z.u)); 
  }; 

// This func returns all services registered with this nameserver for a given zone 
.sp.ns.server.discover_all: {[zone_] 
    func : "[.sp.ns.server.discover_all] : ";
    if[ not zone_ in .sp.ns.server.zones; 
        msg : func, (string zone ), " is NOT one of the zones serviced by this nameserver."; .sp.exception msg; ]; 
    :select from .sp.ns.server.services where zone = zone_ ; 
  } ; 

.sp.ns.server.discover: {[zone_ ;svc_; policy_; params_ ] 
    func : "[.sp.ns.server.discover] : "; 
    if[ not zone_ in .sp.ns.server.zones; 
        msg : func, (string zone_ ), " is NOT one of the zones serviced by this nameserver."; .sp.exception msg; ]; 
        
    f: $[( (type policy_) > 99h); policy_; .sp.ns.server.policies[policy_]]; / if policy is func, run it, otherwise look for preset polcy 
    services: select from .sp.ns.server.services where zone = zone_, svc = svc_, status=`live; 
    if[0 = count services; :0!services ]; 
    result : `; 
    if[ 0b = null f; result : f[services;params_ ]]; 
    update lastdisc: `timestamp$.z.Z from `.sp.ns.server.services where handle in result [ `handle] ; 
    `.sp.ns.server.discolog insert ((count result)#.z.Z; (count result)#.z.w; (count result)#zone_; (count result)#svc_; result[`inst]); 
  	:result; 
  }; 

.sp.ns.server.d_all: {[services;params]  : 0! (select from services);  } ; 

.sp.ns.server.d_fifo: {[services;params] : -1#0! (select from services where lastdisc = min lastdisc) }; / return last row 

.sp.ns.server.d_least_busy: {[services;params] 
    q: sum each .z.W; 
    t: ([handle: (key q)]; sz: (value q)); 
    f: (`handle xkey .sp.ns.server.services) lj t; 
    : 1#0! (select from f where sz = min sz); 
  } ; 

.sp.ns.server.d_first: {[services;params] : 1#0!services; }; / return first row 

.sp.ns.server.d_inst:{ [services;params] : 1#0!select from services where inst = params } ; 

.sp.ns.server.d_not_inst:{ [services;params] : 1#0!select from services where inst <> params } ; 

.sp.ns.server.announce:{ [zone_; svc_; inst_ ; port_; type_] 
 	func: "[.sp.ns.server.announce] : "; 
	.sp.log.spam func, "Types of all arguments are "; 
	{.sp.log.spam x } each string each (type each(zone_ ;svc_;inst_;port_;type_) ); 
	if[ 0b = all (neg 11h) = type each (zone_ ;svc_;inst_;port_;type_ ); 
        .sp.exception func, "Announce failed. argument(s) type invalid. All args must be symbols." ]; 
        
    .sp.log.debug func, "zone : ", (string zone_), ", svc ", (string svc_ ), ":", (string inst_), ", port = ", (string port_), "and svc type = ", (string type_ );
    if[ not zone_ in .sp.ns.server.zones; 
        msg : func, (string zone_), " is NOT one of the zones serviced by this nameserver "; .sp.log.error msg; .sp.exception msg; ]; 
        
    h: .z.w; 
    a: .Q.host .z.a; 
    .sp.log.info func, "remote host address is : ", (string a); 
    if[ (string a) like "localhost*"; 
        a:first `$system "hostname --l"]; // have fqhn instead of localhost as address 
    
    status: `registered;
    if[ svc_ in .sp.ns.server.exclude_liveliness_chks; status : `live];
    ret:. [insert; (`.sp.ns.server.services; (zone_; svc_; inst_ ; h; a; port_; type_; `timestamp$.z.Z; `timestamp$.z.Z; status) ); -1i]; 
    .sp.log.spam func, "type of ret = ", (string (type ret)), " value = ", (string ret) ; 
    if[ -6h = type ret; 
        msg : func, "Announce failed. Service with same name and inst already exists in this zone ", (string zone_ ); 
        .sp.log.debug msg; .sp.exception msg ];
        
    if[ -6h <> type ret; 
        .sp.log.info func, "Announce completed. zone = ", (string zone_), ", svc =" (string svc_) , ", inst = ", (string inst_ ), ", port = ",(string port_), "and svc type = ", (string type_)]; 
    :1; // for success 
  };
 
.sp.ns.server.on_timer: {[id_;tm_] 
    func : "[.sp.ns.server.on_timer] : ";
    .sp.ns.server.check_liveliness ./: ( flip value flip (select zone,svc,inst,handle,address,lasthb from .sp.ns.server.services)); 
    d: exec count distinct zone from .sp.ns.server.services; 
    s: exec count distinct svc from .sp.ns.server.services; 
    i: exec count i from .sp.ns.server.services; 
    .sp.log.debug func, "Nameserver HB Timer Stats: ", (string d), " Zones ", (string s), " Services, ", (string i), " Instances."; 
    :1b; 
  }; 

.sp.ns.server.check_liveliness:{ [zone_;svc_;inst_;hdl_;adr_;lhb_] 
    func: "[.sp.ns.server.check_liveliness] : "; 
    if[ svc_ in .sp.ns.server.exclude_liveliness_chks; 
        .sp.log.spam func, "This svc ", (string svc_), " is excluded from liveliness checks."; :0 ]; 
        
    if[ not hdl_ in (key .z.W); 
        .sp.log.warn func, "Detected disconnected service [", (string svc_) , ": ", (string inst_ ), "], Removing from zone ", (string zone_ ), " and handle ", (string hdl_ ); 
        .sp.ns.server.services:: delete from .sp.ns.server.services where handle = hdl_ ]; 
    
    max_hb: .sp.ns.server.max_hb_timeout; 
    bad: 0! (select from .sp.ns.server.services where lasthb < (.z.Z - `time$ max_hb), not svc in .sp.ns.server.exclude_liveliness_chks); 
    .sp.ns.server.services:: update status: `stale from .sp.ns.server.services where lasthb < (.z.Z - `time$ max_hb), not svc in .sp.ns.server.exclude_liveliness_chks; 
    if[0 < count bad; 
        .sp.log.warn func, "Detected ", (string count bad), " stale services (", ("," sv ({ ":" sv string x} each (bad[`svc],'bad[`inst]))), ")"; ]; 
  } ; 

.sp.ns.svcs_connection_event: { [hdl_; event_] 
    func : "[.sp.ns.svcs_connection_event] : "; 
    if[ null hdl_ ; .sp.log.warn func, "Null handle passed from io pkg in connection event callback. Something must be wrong!"; :0; ]; 
    if[ event_ <> `close; .sp.log.debug func, "Not a close event. Returning for now"; :0; ]; 
    
    .sp.log.debug func, "Detected close event on handle ", (string hdl_ ), " Will remove any svcs with this handle now unless the svcs are in exclusion list."; 
    rem_svcs : select zone, svc, inst, handle, address, port, svc_type, status from .sp.ns.server.services where handle = hdl_ , not svc in .sp.ns.server.exclude_liveliness_chks; 
    { [zone_; svc_; inst_; hdl_; addr_; port_; svc_type_ ; status_ ] 
        func : "[.sp.ns.svcs_connection_event] : "; 
        delete from `.sp.ns.server.services where handle = hdl_ ;
        .sp.log.info func, "Removed from services: zone [", (string zone_), "] service [", (string svc_ ), "] inst [", (string inst_ ), "] adddress:port [", (string addr_), ":", (string port_ ), "] and status ", (string status_ ); 
    } ./: flip value flip rem_svcs; 
  };
  
.sp.ns.server.add_svc_to_exclude_liveliness_chks: { [svc_]  
    func : "[.sp.ns.add_svc_to_exclude_liveliness_chks] : ";
    .sp.ns.server.exclude_liveliness_chks:: .sp.ns.server.exclude_liveliness_chks, svc_ ; 
    .sp.log.info func, "added the svc ", (string svc_ ), " to the liveliness check exclusion list"; 
   };

.sp.ns.server.on_start: {[] 
    func: "[.sp.ns.server.on start] : "; 
    .sp.log.info func, "Starting Nameserver ... "; 
    .sp.ns.server.exclude_liveliness_chks:: (); 
    zones:: .sp.arg.required[`zones]; // comma seperated zones: dev,qa,prod,research 
    .sp.ns.server.zones:: `$ ( " ," vs zones); 
    .sp.log.info func, "zones serviced by this nameserver are : ", ("," sv string  each .sp.ns.server.zones); 

    // in_port arg is required for name server. If not fail 
    if[not `in_port in key (.Q.opt .z.x); msg : func, "The listening port number for the nameserver, has to be passed in in_port arg."; .sp.exception msg;]; 
    
    // wait for 10 seconds by default before deciding the svc is stale 
    .sp.ns.server.max_hb_timeout:: "I"$ (.sp.arg.optional[`max_hb_timeout;"10000"] ); 
    .sp.ns.server.services:: ([ zone: `symbol$ (); svc: `symbol$ (); inst: `symbol$()]; handle: `int$(); address: `symbol$(); port:`$(); svc_type: `symbol$ (); lasthb: `timestamp$ (); lastdisc: `timestamp$ (); status: `symbol$ () ) ; 
    .sp.ns.server.policies:: (`fifo; `leastbusy;`first;`all;`inst; `not_inst)! (.sp.ns.server.d_fifo;.sp.ns.server.d_least_busy; .sp.ns.server.d_first; .sp.ns.server.d_all;.sp.ns.server.d_inst; .sp.ns.server.d_not_inst); 
    .sp.ns.server.discolog:: ([] time: `datetime$ () ; hndl: `int$ (); zone: `symbol$ () ; svc: `symbol$ (); inst: `symbol$ () ) ; 
    timer_id:: .sp.cron.add_timer[5000;-1; .sp.ns.server.on_timer]; 
    .sp.io.add_con_event_handler[.sp.ns.svcs_connection_event; `]; 
    .sp.log.info func, "Nameserver is ready ... "; 
    :1b; 
  };
 

.sp.comp.register_component [`nameserver; enlist `config_service;.sp.ns.server.on_start]; 
