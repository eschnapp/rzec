.boot.include (gdrive_root, "/framework/html.q");^

.sp.h.sdk.on_comp_start:{[]
	:1b;
	};

.sp.comp.register_component[`htmlsdk;`html`common;.sp.h.sdk.on_comp_start];
.sp.h.sdk.create:{[otype_]
        func: "[.sp.h.sdk.create]: ";
        oid_: last `$( raze ("oid_", (string 1?0Ng)));
        .sp.log.debug func, "NEW ID:", (string oid_);
        //objs: .sp.html.response[`items];
        //o: (`oid xkey objs) upsert ([]oid: enlist oid_; otype: enlist otype_);
        //tmp_o:: o;
        //.sp.html.response[`items]:: (0!tmp_o);
        `.sp.html.response.items upsert ([]oid: enlist oid_; otype: enlist otype_);
        :oid_;
    };

.sp.h.sdk.pos:{[t_;l_;b_;r_; oid_]
    item: (select from .sp.html.response[`items] where oid = oid_)[0];
    st_name: ((string item[`otype]),"#",(string oid_));
    if[ not all null t_;
        `.sp.html.stylez insert ((enlist st_name); enlist "top"; enlist t_) ];
    if[ not all null l_;
        `.sp.html.stylez insert ((enlist st_name); enlist "left"; enlist l_) ];
    if[ not all null b_;
        `.sp.html.stylez insert ((enlist st_name); enlist "bottom"; enlist b_) ];
    if[ not all null r_;
        `.sp.html.stylez insert ((enlist st_name); enlist "right"; enlist r_) ];
    `.sp.html.stylez insert ((enlist st_name); enlist "position"; enlist "absolute");
    :oid_;
    };

.sp.h.sdk.size:{[w_;h_;oid_]
    item: (select from .sp.html.response[`items] where oid = oid_)[0];
    st_name: ((string item[`otype]),"#",(string oid_));
    if[ not all null w_;
        `.sp.html.stylez insert ((enlist st_name); enlist "width"; enlist w_) ];
    if[ not all null h_;
        `.sp.html.stylez insert ((enlist st_name); enlist "height"; enlist h_) ];
    :oid_;
    };

.sp.h.sdk.style:{[pairlist;oid_]
    item: (select from .sp.html.response.items where oid = oid_)[0];
    st_name: ((string item[`otype]),"#",(string oid_));
    yy: count pairlist;
    xx: flip pairlist;
    `.sp.html.stylez insert ( yy#(enlist st_name); xx[0]; xx[1]);
    :oid_;
    };

.sp.h.sdk.name:{[n_;i_;oid_]
    .sp.html.response.items:: (.sp.html.response.items lj ([oid: enlist oid_]; name: enlist n_; id: enlist i_));
    :oid_;
    };

.sp.h.sdk.inner_html:{[html_;oid_]
    .sp.html.response.items:: (.sp.html.response.items lj ([oid: enlist oid_]; innerText: enlist html_));
    :oid_;
    };


.sp.h.sdk.add_item:{[oid_;item_oid_]
    .sp.html.response.items:: (.sp.html.response.items lj ([oid: enlist item_oid_]; pid: enlist oid_));
    .sp.html.response.items;
    :item_oid_;
    };

.sp.h.sdk.add_attrib:{[name;val;oid_]
    if[ (type name) = (-10h); name: enlist name];
    if[ (type val) = (-10h); val: enlist val];

    if[ (type name) = 10h; name: `$(name)];
    `.sp.html.attribs insert ( enlist oid_; enlist name; enlist val );
    :oid_;
    };

.sp.h.sdk.add_event:{[name;func;oid_]
    `.sp.html.events insert ( enlist oid_; enlist name; enlist func );
    :oid_;
    };


.sp.h.sdk.create_ex:{[otype;t;l;w;h]
    :    .sp.h.sdk.position[t;l;`;`] .sp.h.sdk.size[w;h] .sp.h.sdk.create[otype];
    };


.sp.h.sdk.define_func:{[name;body]
    `.sp.html.internal_scripts insert (enlist name; enlist body);
    };

.sp.h.sdk.define_style:{[class;pairlist]
    c: count pairlist;
    x: flip pairlist;
    `.sp.html.stylez insert ( c#(enlist class); x[0]; x[1]);
    };

.sp.h.sdk.page_params:{[params]
    .sp.html.response:: (.sp.html.response, params);
    };

.sp.h.sdk.body_attribs:{[attribs]
      .sp.html.response.body_attribs:: (.sp.html.response.body_attribs, attribs);
    };

.sp.h.sdk.create_chart:{[name;tbl;options]
    ttt:: options;

    if[ not (type tbl) = 98h; .sp.exception "not a table!";];

    odiv:
        .sp.h.sdk.add_attrib["data-type";"chart"]
        .sp.h.sdk.add_attrib["data-name";(string name)]
        .sp.h.sdk.create[`div];
    chtype: "ColumnChart";

    if[not `op.title in (key options);
        options[`op.title]: (raze string name);
        ];

    if[`type in (key options);
        chtype: options[`type]];

    fname:: "draw_", (string name), "()";
    fbody:: raze "
        var data = google.visualization.arrayToDataTable([
          [",
           ( "," sv ({ "'",(string x),"'" } each (cols tbl)))
          ,"]\n\t,",
          ("," sv {[row]
            "[",("," sv { if[(type x) > 0h; x: first x; ];
                          $[((type x) = 0h);
                            ("'",(" " sv ( raze string x )), "'");
                            $[(abs type x) > 9h;
                                raze ("'",ssr[(trim string x);`char$10;""],"'") ;
                                ssr[(trim raze string x);`char$10;""]]]
                        } each (value row)),"]\n\t"
          } each tbl)
        ,"]);

        var options = {\n\t",
         (",\n\t" sv ({[options;x] opval: options[x]; opname: 3_(raze string x);  :raze (opname,": ",$[(abs type opval) = 10h; raze ("'",string opval,"'"); raze string opval]) }[options;] each ((key options) where ((key options) like "op.*"))))

        ,"\n\t};

        var chart = new google.visualization.",(raze string chtype),"(document.getElementById('",(raze string odiv),"'));
        all_charts['",(raze string name),"'] = chart;
        all_data_tables['",(raze string name),"'] = data;
        var formatter;
        ",
        ($[(`formatter in (key options));
            {[options]
                tp: options[`formatter][0][0];
                cls: "," vs (raze string options[`formatter][0][1]);
               :
                (raze {[options;tp;x]
                    :"formatter = new google.visualization.",tp,"();\n\t",
                    (raze {[x] :"formatter.",x,"\n\t"; } each (1_(options[`formatter])))
                    ,"formatter.format(data,",x," );\n\t";
                }[options;tp;] each cls);
            }[options]
         ;""])
        ,"

        chart.draw(data, options);";


    .sp.h.sdk.define_func[fname;fbody];


    fname:: "redraw_", (string name), "()";
    fbody:: raze "
        if( !('", (string name), "' in all_data_tables) ) {
            console.log('ERROR: cannot redraw ", (string name), ", no data table in memory');
            return;
        }
        if( !('", (string name), "' in all_charts) ) {
            console.log('ERROR: cannot redraw ", (string name), ", no chart in memory');
            return;
        }


        var data = all_data_tables['", (string name), "'];
        var view;

        if( '", (string name), "' in all_data_views ) {
            view = all_data_views['", (string name), "'];
        } else {
            view = new google.visualization.DataView(data);
        }

        var options = {\n\t",
         (",\n\t" sv ({[options;x] opval: options[x]; opname: 3_(raze string x);  :raze (opname,": ",$[(abs type opval) = 10h; raze ("'",string opval,"'"); raze string opval]) }[options;] each ((key options) where ((key options) like "op.*"))))

        ,"\n\t};

        var chart = all_charts['", (string name), "'];
        chart.draw(view, options);";


    .sp.h.sdk.define_func[fname;fbody];

    : odiv;
    };

.sp.h.sdk.add_sub:{[uri;svc;topic;filter]
    .sp.h.sdk.add_attrib["service";svc]
    .sp.h.sdk.add_attrib["topic";topic]
    .sp.h.sdk.add_attrib["uri";uri]
    .sp.h.sdk.add_attrib["filter";filter]
    .sp.h.sdk.create[`$"x-sub"];
    };

.sp.h.sdk.create_toggle:{[onlbl;offlbl;clr]

    olbl:
      .sp.h.sdk.style[(("position";"relative");
                      ("display";"inline-block");
                      ("vertical-align";"top");
                      ("width";"56px");
                      ("height";"20px");
                      ("padding";"3px");
                      ("background-color";"white");
                      ("border-radius";"18px");
                      ("box-shadow";"inset 0 -1px white, inset 0 1px 1px rgba(black, .05)");
                      ("cursor";"pointer\n @include linear-gradient(top, #eee, white 25px)"))]
      .sp.h.sdk.create[`label];

    oin:
      .sp.h.sdk.add_item[olbl]
      .sp.h.sdk.style[(("position";"absolute");
                      ("top";"0");
                      ("left";"0");
                      ("opacity";"0"))]
      .sp.h.sdk.add_attrib["type";"checkbox"]
      .sp.h.sdk.add_attrib["checked";"true"]
      .sp.h.sdk.create[`input];

    ospn1:
      .sp.h.sdk.add_item[olbl]
      .sp.h.sdk.add_attrib["data-on";onlbl]
      .sp.h.sdk.add_attrib["data-off";offlbl]


      .sp.h.sdk.style[(("position";"relative");
                      ("display";"block");
                      ("height";"inherit");
                      ("font-size";"10px");
                      ("text-transform";"uppercase");
                      ("background";"#eceeef");
                      ("border-radius";"inherit");
                      ("box-shadow";"inset 0 1px 2px rgba(black, .12),
                                    inset 0 0 2px rgba(black, .15)
                                    @include transition(.15s ease-out);
                                    @include transition-property(opacity background);

                                    &:before, &:after {
                                    position: absolute;
                                    top: 50%;
                                    margin-top: -.5em;
                                    line-height: 1;
                                    @include transition(inherit);
                                    }

                                    &:before {
                                    content: attr(data-off);
                                    right: 11px;
                                    color: #aaa;
                                    text-shadow: 0 1px rgba(white, .5);
                                    }

                                    &:after {
                                    content: attr(data-on);
                                    left: 11px;
                                    color: white;
                                    text-shadow: 0 1px rgba(black, .2);
                                    opacity: 0;
                                    }

                                    .switch-input:checked ~ & {
                                    background: #47a8d8;
                                    box-shadow: inset 0 1px 2px rgba(black, .15),
                                    inset 0 0 3px rgba(black, .2);

                                    &:before { opacity: 0; }
                                    &:after { opacity: 1; }
                                    }"))]

      .sp.h.sdk.create[`span];

    ospn2:
      .sp.h.sdk.add_item[olbl]

      .sp.h.sdk.style[(("position";"absolute");
                      ("top";"4px");
                      ("left";"4px");
                      ("width";"18px");
                      ("height";"18px");
                      ("background";"white");
                      ("border-radius";"10px");
                      ("box-shadow";"1px 1px 5px rgba(black, .2);
                        @include linear-gradient(top, white 40%, #f0f0f0);
                        @include transition(left #{.15sec ease-out});

                        &:before {
                        content: '';
                        position: absolute;
                        top: 50%;
                        left: 50%;
                        margin: -6px 0 0 -6px;
                        width: 12px;
                        height: 12px;
                        background: #f9f9f9;
                        border-radius: 6px;
                        box-shadow: inset 0 1px rgba(black, .02);
                        @include linear-gradient(top, #eee, white);
                        }

                        .switch-input:checked ~ & {
                        left: 40px;
                      box-shadow: -1px 1px 5px rgba(black, .2);
                        }"))]
      .sp.h.sdk.create[`span];


      :olbl;

    };
