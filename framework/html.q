.sp.html.on_comp_start:{[]
	.sp.html.requests:: ([] method: `int$(); time: `datetime$(); request: (); Host: `$());
	.sp.html.external_scripts:: ([] tp: `$(); src: `$(); init_func: ());
	.sp.html.internal_scripts:: ([] func: ();  code: ());
	.sp.html.links:: ([] tp: `$(); trgt: `$(); rel: `$(); href: `$());
	.sp.html.stylez:: ([] name: (); pname: (); pval: ());
	.sp.html.attribs:: ([] oid: `d1`d2; aname: `d1`d2; aval: (`;"foo"));
	.sp.html.events:: ([] oid: `d1`d2; ename: `d1`d2; func: (`;"foo"));
	.sp.html.item_def:: ([]oid: `d1`d2; otype: `t1`t2; pid: `d1`d2; html: ("foo";"foo"); name: `d1`d2; id: `d1`d2; innerText: ("bar";"bar"));
	.sp.html.response_def:: (`dummy`title`body_attribs)!(();"DEAULT TITLE";((enlist `onload)!(enlist "load_the_page();")));
	.sp.html.response:: .sp.html.response_def;
	.sp.html.response[`items]: .sp.html.item_def;

	.sp.html.handlers::()!();
	:1b;
	};

.sp.comp.register_component[`html;`common;.sp.html.on_comp_start];

.sp.html.on_websock_data: {[data]
    func: "[.sp.html.on_websock_data]: ";
    if[ (abs type data) = 10h;
        .sp.log.warn func, "Received text message via websocket! Returning error to client";
        neg[.z.w] "ASCII not supported!! are u hacking??!! We know where u live!";
        :0b;
        ];

    .sp.log.info func, "Websock update receivd, de-serializing data...";
    ws_packet:: @[.sp.dc.de_serialize;data; {
                    func: "[.sp.html.on_websock_data#1]: ";
                    .sp.log.error func, "Failed to de-serialize the input packet due to - ", (raze string x);
                    :();
                }];

    if[(type ws_packet) <> 0h;
        .sp.log.error func, "Cannot process non generic list!, received: ", (string type ws_packet);
        :0b;
        ];

    if[(count ws_packet) <= 0;
        .sp.log.error func, "Empty list from client! cannot process update!";
        :0b;
        ];

    cmd: `$(raze string ws_packet[0]);
        
    .sp.log.info func, "Executing remote command: ", (string cmd);
    fname: `$(".sp.html.ws.", (string cmd));
    res: .[(value fname);.z.w, (1_ (ws_packet)); {
                    func: "[.sp.html.on_websock_data#2]: ";
                    .sp.log.error func, "Failed to execute the remote command due to -", (raze string x);
                    :0b;
                }];
    .sp.log.info func, "sending result back to client";
    neg[.z.w] `byte$(.sp.dc.serialize res);
    };

.sp.html.do_process_request:{[request] };

.sp.html.ws.sub:{[hdl;svc;topic;filter]

    func: "[.sp.html.ws.sub]: ";
    .sp.log.info func, "subscribing over the web!!";
    svc: `$(raze string svc);
    topic: `$(raze string topic);
    f: value filter;
    ws_params:: (`$("websock-",(string hdl));svc;topic;{[fltr;hdl;svc;topic;data;upd_type] 
            func: "[.sp.html.ws.sub#1]: ";
            if[ not hdl in (key .z.W);
                .sp.log.error func, "Connection is dropped, stopping subscription to ", (raze string svc), ":", (raze string topic);
                .sp.cache.remove_callback_handler[`$("websock-",(string hdl));svc;topic];
                :0b;];
            cosmic_pkg:: `byte$(.sp.dc.serialize (upd_type;svc;topic;(0!fltr[data])));
            neg[hdl] cosmic_pkg;
            }[f;hdl];{[]  });

    ret: .[.sp.cache.add_callback_handler;ws_params;{[func;x] .sp.log.error func, "Failed to perform web-subscribe due to - ", (raze string x); :0b; }[func]];
    .sp.log.info func, "web subscription complete...";
    :ret;
    };


.sp.html.charfix:{[val]
  :.h.uh val;
//  v: ddval;
//  v: ssr[v;"%40";"@"];
// more here...
//  :v;
  };

.sp.html.process_header:{[x;y]

    func: "[.sp.html.process_header]: ";
    .sp.log.info func;
    a: x[0];
    b: flip enlist each `$x[1];
    c: update method: y, time: .z.Z from b;
    d: update request: enlist a, pX: enlist x from c;
    e: { a: { a: " " vs x; if[ (count a) <= 1; a: "?" vs x]; :a; } x;
      b: "." vs a[0];
      c: "&" vs a[1];
      ar: raze {v: "=" vs x; if[(count v) <= 0; :()!()]; : (enlist `$(.sp.html.charfix[v[0]]))!(enlist .sp.html.charfix[v[1]]);} each c;
      ex: "";
      if[ (count b) > 1; ex: (last b)];
      :([] resource: enlist a[0]; ext: enlist ex; args: (), (enlist ar));
     } a;

    f:: d, 'e;
    if[ (count .sp.html.requests) <= 0;
        .sp.html.requests:: f;
        : .sp.html.process_request[]];

    ttmp:  ( f lj ( `time`method`Host xkey ( .sp.html.requests lj ( `time`method`Host xkey f))));
    .sp.html.requests:: .sp.html.requests lj ( `time`method`Host xkey f);
    `.sp.html.requests insert ttmp;

    : .sp.html.process_request[];

    };

.sp.html.process_request:{
    func: "[.sp.html.process_request]: ";
    .sp.log.info func;
    request: last .sp.html.requests;

    // if the request is not for a "" or a .q resource, then let the default q handler work there... no need to process images, htmls etc..
    if[ not (`$(request[`ext])) in (`;`q);
        : .sp.html.def_ph request[`pX]];

    .sp.html.response:    .sp.html.response_def;
    .sp.html.response[`items]: .sp.html.item_def;
    .sp.html.internal_scripts:: 0# .sp.html.internal_scripts;
    .sp.html.stylez:: 0# .sp.html.stylez;
    .sp.html.do_process_request[ request ];

    :.sp.html.finalize_request[request];
    };

.sp.html.process_ext_scripts:{
    func: "[.sp.html.process_ext_scripts]: ";
    .sp.log.info func;
       : ({ at:: raze {[x;y]
                            if[(not null (x[y])); :(enlist y)!(enlist string x[y])];
                            :()!();
                          }[x;] each (key x);

              :.h.htac[`script;at;""];
            } each ?[.sp.html.external_scripts;();0b;(`type`src)!(`tp`src)]);

    };

.sp.html.process_int_scripts:{
    func: "[.sp.html.process_int_scripts]: ";
    .sp.log.info func;

    a: raze {
        :"\r\n function ",x[`func],"{\r\n",x[`code],"}\r\n";
    } each .sp.html.internal_scripts;

    inits: exec distinct init_func from select from .sp.html.external_scripts where (count each init_func) > 0;
    b:  raze {
        :((string x), "; \r\n");
    } each inits;
    c: (("\r\nfunction load_the_page() {\r\n"), b, "};\r\n", a);
    d: .h.htac[`script;(enlist `type)!(enlist "text/javascript");c];
    :d;
  };

.sp.html.process_links:{
    func: "[.sp.html.process_links]: ";
    .sp.log.info func;
       : ({ at:: raze {[x;y]
                            if[(not null (x[y])); :(enlist y)!(enlist string x[y])];
                            :()!();
                          }[x;] each (key x);

              :.h.htac[`link;at;""];

            } each ?[.sp.html.links;();0b;(`type`target`rel`href)!(`tp`trgt`rel`href)]);
    };

.sp.html.process_stylez:{
    func: "[.sp.html.process_stylez]: ";
    .sp.log.info func;

    a: 0!select pname, pval by name from .sp.html.stylez;
    b: raze {
        tmp::  raze {[x;y]
            if[ 10h = (type y); y: enlist y];
            if[ -10h = (type y); y: enlist enlist y];
            : "    ",x,": ",(" " sv y),";\r\n";
           } ./: flip (x[`pname];x[`pval]);
        : "\r\n", x[`name], " {\r\n" , tmp, "}\r\n\r\n";
    } each a;
    : .h.htac[`style;(enlist `type)!(enlist "text/css");b];
    };

.sp.html.get_attribs:{[item]
    k: `dum1`dum2!(`;"");
    if[ not all null item[`name];
        k[`name]: item[`name]];
   // if[ not all null item[`id];
   //     k[`id]: item[`id]];
    k[`id]: (string item[`oid]);

    // generic attribs...
    t: select from .sp.html.attribs where oid = item[`oid], not aname in (`d1`d2);
    if[ (count t) > 0;
        k: k, (raze { (enlist x[`aname])!(enlist x[`aval])} each t);
        ];

    // events attribs...
    e: select from .sp.html.events where oid = item[`oid], not ename in (`d1`d2);
    if[ (count e) > 0;
        k: k, (raze { (enlist x[`ename])!(enlist x[`func])} each e);
        ];

    : delete dum1, dum2 from k;
    };



.sp.html.finalize_request:{[request]
    func: "[.sp.html.finalize_request]: ";
    .sp.log.info func;

    head:: ();
    body:: ();

    // HERE NEED TO BUILD THE ACTUAL BODY FOR THE REQUEST....
    hdl: .sp.html.handlers[`$(request[`resource])];
    if[ (null hdl);
         :.sp.html.html[head;] .h.he ("Handler NOT Defined: ", request[`resource])];

    // call the handler...
    .sp.log.info func, "Calling update handler...";
    hdl[request];

    // now take the response items and build the body...
    .sp.log.info func, "Building response body...";
    items:: select from (.sp.html.response[`items]) where not oid in (`d1`d2);
    tmp_items:: items;
    output:: "";
//    items:: 0#items;
    if[ (count items) > 0;
        tmp:: (exec distinct oid from items) except (exec distinct pid from items);
        items:: update done: 0b from items;
        .sp.log.debug func, "Entering loop...";
        ttt: 0; // safeguard... no more than 100K items...
        while[( not all (exec done from items)) and (ttt<100000);
            ttt: ttt + 1;
            .sp.log.debug func, "Loop Tick...DONE:", (":" sv string (exec done from items));
// x: items; y: first 0!items;
            ret:: {[x;y]
                func: "[.sp.html.finalize_request#1]: ";
                .sp.log.debug func, "Item Tick...";
//                .sp.html.generate_styles[y];
                pids: (exec distinct pid from x) except `;
                i: y;

                // if done, then leave here...
                if[i[`done] = 1b; :i; ];

                // if leaf, then just generate the code and done...
                if[ not i[`oid] in pids;
                    att: .sp.html.get_attribs[i];
                    i[`html]: .h.htac[i[`otype];att;i[`innerText]];
                    i[`done]: 1b;
                    .sp.log.debug func, "Leaf Process Complete...";
                    : i;
                ];
                // if not leaf, chec if children are done first...
                cids: exec distinct oid from (select from x where pid = y[`oid]);
                if[ all (exec done from x where oid in cids);
                    allhtml: raze (exec html from x where oid in cids);
                    att: .sp.html.get_attribs[i];
                    i[`html]: .h.htac[i[`otype];att;(i[`innerText], allhtml)];
                    i[`done]: 1b;
                    .sp.log.debug func, "Node Process complete...";
                    :i;
                ];
                // not all children are done... just return myself...
                //: { ?[(type x) < 0h; enlist x; x] } each i;
                .sp.log.debug func, "Node still pending...";
                :i;
            }[items;] each 0!items;
            items:: `oid xkey ret;
        ];

        output:: raze (exec html from items where null pid);
    ];


    // process head items...
    .sp.log.info func, "Processing head";
    head:: head, (enlist .h.htc[`title;.sp.html.response[`title]]); // title

    // links
    .sp.log.info func, "Processing links";
    links:: .sp.html.process_links[];
    head:: head, links;

    // styles
    .sp.log.info func, "Processing styles";
    stylez:: .sp.html.process_stylez[];
    head:: head, stylez;

    // external scripts
    .sp.log.info func, "Processing external scripts";
    escripts:: .sp.html.process_ext_scripts:[];
    body:: body, escripts;

    // internal scripts
    .sp.log.info func, "Processing internal scripts";
    iscripts:: .sp.html.process_int_scripts:[];
    body:: body, iscripts;
    // innter text
    if[ (count .sp.html.response[`innerText]) > 0; body:: (body, .sp.html.response[`innerText])];
    // elements..
    body:: raze body, output;
    : .sp.html.html[head; body];
    };

.sp.html.on_get:{
    func: "[.sp.html.on_get]: ";
    .sp.log.info func;

    : .sp.html.process_header[x;`get];
    };

.sp.html.on_post:{
    func: "[.sp.html.on_post]: ";
    .sp.log.info func;

    :.sp.html.process_header[x;`post];
    };


.sp.html.c_input:{[t;n;v]
    func: "[.sp.html.c_input]: ";
    .sp.log.info func;

    :.h.htac[`input;(`type`name`value)!(t;n;v);""];
    };

.sp.html.c_button:{[t;n;v]
    func: "[.sp.html.c_button]: ";
    .sp.log.info func;

    : .h.htac[`button;(`type`name)!(t;n); v];
    };

.sp.html.c_form:{[a;m;e]
    func: "[.sp.html.c_form]: ";
    .sp.log.info func, "a: ", (raze string a), " m: ", (raze string m), " e: ", (sv[":";e]);

    : .h.htac[`form;`action`method!(a;m);raze e];
    };

.sp.html.html:{[head;body]
    func: "[.sp.html.html]: ";
    .sp.log.info func;
    battr: .sp.html.response[`body_attribs];
    btag: .h.htc[`body;body];
    if[ (type battr) = 99h;
        btag: .h.htac[`body;battr;body]];
    : "<!DOCTYPE html>", .h.htc[`html] .h.htc[`head;raze head], btag;
    };

.sp.html.def_ph: .z.ph;
.z.ph: .sp.html.on_get;
.z.pp: .sp.html.on_post;
.z.ws: .sp.html.on_websock_data;