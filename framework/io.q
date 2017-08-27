/ io related sutff
.sp.io.on_comp_start: {[]
    func : "[.sp.io.on_comp_start] : ";
    .sp.io.connections::        ([handle: `int$()]; host: `symbol$(); usr: `symbol$(); bufsize: `int$(); htype: `$());
    .sp.io.con_event_handlers:: ([] id: `int$(); handle: `int$(); func: ());
    .sp.io.timer_ival::         "I"$.sp.arg.optional[`io_timer_ival;"5000"];
    .sp.io.reconnect_tries:     "J"$.sp.arg.optional[`io_reconnect;"3"];

    present : .sp.arg.exist[`in_port];
    .sp.log.debug func, "in_port present = ", (string present);
    .sp.io.inport:: .sp.arg.optional[`in_port;"1234"];

    / assign handlers for port open/close events
    .z.po:: .sp.io.on_port_open[`remote;];
    .z.pc:: .sp.io.on_port_close;
    .z.wo:: .sp.io.on_port_open[`websock;];
    .z.wc:: .sp.io.on_port_close;
    .sp.cron.add_timer[.sp.io.timer_ival;-1;.sp.io.on_timer];

    if[present = 0b;
        .sp.log.info func, " No in_port supplied, auto-detecting nearest unused port...";
        port: 23405;
        test: 1;
        while[ test > 0; ret:@[.sp.io.chng_port; port; -1]; $[ret = -1; port:port+ 1; test: 0] ];
        .sp.io.inport:: string port ];

    if[ present;
        .sp.log.info func, "Opening port ", .sp.io.inport," for incoming connections...";
        system ("p ", .sp.io.inport) ];
    .sp.log.info func, " component io ready";
    :1b;
  };

.sp.io.chng_port:{[p]
    .sp.log.info "Setting the listener port to: ", (raze string p);
    system ("p ", (raze string p));
    :p;
  };

.sp.io.prv.hopen:{ [a_; t_] $[t_ > 0; :hopen(hsym a_; `long$t_); :hopen (hsym a_)] };

// #pragma debug func open_port
.sp.io.open_port:{[a;t]
    func:"[.sp.io.open_port] : ";
    .sp.log.debug func,"Open Port: ", (string a);

    done:0b;
    retried:0;
    while[ not done;
        hdl: .[.sp.io.prv.hopen;(a;t); { .sp.log.error "[.sp.io.open_port] : .sp.io.prv.hopen failed due to - ",x; :-1i; } ];
        $[hdl > 0; done:1b; $[(retried+1) = .sp.io.reconnect_tries; done:1b; retried:retried+1] ] ];
    $[hdl > 0; .sp.log.debug func, " successful. hdl = ", (raze string hdl); .sp.log.error func, " failed" ];

    u: .z.u;
    .sp.io.connections:: .sp.io.connections upsert ([handle: enlist hdl]; host: enlist a; usr: enlist u; bufsize: enlist 0; htype: enlist `local);
    .sp.io.update_state[];
    : hdl;
  };

.sp.io.close_port: {[h]
    func:"[.sp.io.close_port] : ";
    / update connection info
    .sp.log.debug "Close Port: ", (string h);
    delete from `.sp.io.connections where handle = h;
    / call any event handlers (both generic and handle specific)
  //  handlers: (.sp.io.con_event_handlers[0]),(.sp.io.con_event_handlers[h]);
   // {[hndl;func] func[hndl;`close];}[h;] each handlers;
    .sp.io.update_state[];
    :h;
  };

.sp.io.on_port_open: {[ht_;x_]
    func:"[.sp.io.on_port_open] : ";
    / update connection info
    .sp.log.debug func,"Port Open: ", (string x_)," [ ", (string .z.u),"@",(string (.Q.host .z.a)), "]";
    `.sp.io.connections upsert ([handle: enlist x_]; host: enlist (.Q.host .z.a); usr: enlist .z.u; bufsize: enlist 0; htype: enlist ht_);
    / call any event handlers (both generic and handle specific)
    handlers: exec func from .sp.io.con_event_handlers where handle in (x_;0i);
    .sp.log.debug func, "Number of handlers to be called = ", (string (count handlers));
    {[x_;f] f[x_;`open];}[x_;] each handlers;
    .sp.io.update_state[];
  };

.sp.io.on_port_close: {[x_]
    func:"[.sp.io.on_port_close] : ";
    / update connection info
    .sp.log.debug func,"Port Close: ", (string x_)," [ ", (string .z.u),"@",(string .z.a), "]";
    delete from `.sp.io.connections where handle = x_;
    / call any event handlers (both generic and handle specific)
    handlers: exec func from .sp.io.con_event_handlers where handle in (x_;0i);
    {[x_;f] f[x_;`close];}[x_;] each handlers;
    .sp.io.update_state[];
  };

.sp.io.update_state: {[]
    func:"[.sp.io.update_state] : ";
    / first remove all the handles which dont exist anymore and notify handlers...
   opn: (key .z.W);
   bad: (exec handle from .sp.io.connections) except opn;
    {[h]
        func:"[.sp.io.update_state] : ";
        handlers: exec func from .sp.io.con_event_handlers where handle in (h;0i);
        {[hndl;f] f[hndl;`dead];} [h;] each handlers;
        .sp.log.debug func, "Removing dead connection for handle ", (string h);
        delete from `.sp.io.connections where handle = h;
      } each bad;

     / now update all the buffer sizes
    .sp.io.connections:: .sp.io.connections lj ([handle: (key .z.W)]; bufsize: `int$(value sum each .z.W));
    };

// #pragma debug func on_timer
.sp.io.on_timer: {[i;t]
    :.sp.io.update_state[];
    };

// #pragma debug func sync
.sp.io.sync: {[h;f]
    :h f;
    };

// #pragma debug func async
.sp.io.async: {[h;f]
    (neg h) f;
    };

.sp.io.add_con_event_handler:{[func_;hndl]
    func:"[.sp.io.add_con_event_handler] : ";
    id: (count .sp.io.con_event_handlers);
    if[ null func_; .sp.exception func, "Null func provided to connection event handler!"];
    h: hndl;
    if[ null hndl;
        .sp.log.info "Null handle provided - using generic handle"; h:0i];

    `.sp.io.con_event_handlers insert (id;h;func_);
    .sp.log.info func,"Added connection event handler for handle ", (raze string h);
    :id;
  };

.sp.io.remove_con_event_handler:{[id;hndl]
    func:"[.sp.io.remove_con_event_handler] : ";
    if[ null id; .sp.exception func, "No ID prodivded for remove connection handler request!"];
    $[ (null hndl) or (0i = hndl);
        [delete from `.sp.io.con_event_handlers where id = id];
        [delete from `.sp.io.con_event_handlers where id = id, handle = hndl]];
  };

/ register io with comp manager
.sp.comp.register_component[`io;`log`arg`cron;.sp.io.on_comp_start];

