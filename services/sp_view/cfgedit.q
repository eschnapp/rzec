.view.cfgedit:{[request]

    func: "[.view.cfgedit]: ";

    if[ all `param_name`param_value`param_type in (key request[`args]);
        sname: `$(request[`args][`service_name]);
        pname: `$(request[`args][`param_name]);
        ptype: last `$(request[`args][`param_type]);
        pval: (request[`args][`param_value]);
        pval: .h.uh pval;
        .sp.log.info func, "Found params in arg, processing parameter ", (":" sv ( string sname;string pname;string ptype;pval ));

        $[ ptype = (upper ptype);
            [ // upper case - list
                .sp.log.info func, "Processing vector param type...";
                pval: "+" vs pval;
                pval: $[last (string upper ptype);] each pval;
            ];
            [ // lower case - single or raw
              $[ ptype = `raw;
                [
                    .sp.log.info func, "Processing raw param type...";
                    pval : value pval;
                ];
                [
                    .sp.log.info func, "Processing scalar param type...";
                    pval : $[last (string upper ptype);pval];
                ]];

            ]];

        // now save...
        .sp.log.info func, "Saving data to cfg service...";
        cmd: (`.sp.cfgsvc.set_value;sname;pname;pval);
        show cmd;
        .sp.re.exec[`SP_SERVER;`;cmd;.sp.consts[`DEF_EXEC_TO]];

        ];

    .sp.log.info func, "Extracting service params...";
    cmd: "0!.sp.cfgsvc.get_all[]";
    tbl: .sp.re.exec[`SP_SERVER;`;cmd;.sp.consts[`DEF_EXEC_TO]];
    mmm:: tbl;
    allsvcs: exec distinct service_name from tbl;
    .sp.html.response[`title]: "Config Viewer";
    .sp.h.sdk.define_style["html, body";
             (("border";"1px none  black");
             ("height";"80vh");
              ("width";"95vw"))];

    .sp.h.sdk.define_func["filterSvc()"] "{
                var tmp = document.getElementsByName('filter')[0];
                if( tmp.length <= 0 )
                    return;

                var uid = tmp[tmp.selectedIndex].value;
                if( uid.length > 0 ) {
                    var view = new google.visualization.DataView(all_data_tables['cfg_list']);
                    view.setRows(view.getFilteredRows([{column: 0, value: uid}]));
                    all_data_views['cfg_list'] = view;
                } else {
                    delete all_data_views['cfg_list'];
                }
           redraw_cfg_list();
         }";

    ofrm:
            .sp.h.sdk.add_attrib["action";"cfgedit.q"]
            .sp.h.sdk.add_attrib["method";"post"]
            .sp.h.sdk.create[`form];

    otbl:   .sp.h.sdk.add_item[ofrm]
            .sp.h.sdk.create[`table];

    ohdr:   .sp.h.sdk.add_item[otbl]
            .sp.h.sdk.create[`tr];

    o1:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.inner_html["SERVICE NAME"]
            .sp.h.sdk.create[`td];

    o2:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.inner_html["PARAM NAME"]
            .sp.h.sdk.create[`td];

    o3:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.inner_html["PARAM VALUE"]
            .sp.h.sdk.create[`td];

    o4:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.inner_html["PARAM TYPE"]
            .sp.h.sdk.create[`td];

    ohdr:   .sp.h.sdk.add_item[otbl]
            .sp.h.sdk.create[`tr];

    o1:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.create[`td];

    o2:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.create[`td];

    o3:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.create[`td];

    o4:    .sp.h.sdk.add_item[ohdr]
            .sp.h.sdk.create[`td];

    osvc:   .sp.h.sdk.add_item[o1]
            .sp.h.sdk.add_attrib["name";"service_name"]
            .sp.h.sdk.add_attrib["type";"input"]
            .sp.h.sdk.create[`input];

    oparam: .sp.h.sdk.add_item[o2]
            .sp.h.sdk.add_attrib["name";"param_name"]
            .sp.h.sdk.add_attrib["type";"input"]
            .sp.h.sdk.create[`input];

    oval:   .sp.h.sdk.add_item[o3]
            .sp.h.sdk.add_attrib["name";"param_value"]
            .sp.h.sdk.add_attrib["type";"input"]
            .sp.h.sdk.create[`input];

    otype:
      .sp.h.sdk.add_item[o4]
      .sp.h.sdk.add_attrib["name";"param_type"]
      .sp.h.sdk.create[`select];

    {[o;x]
      .sp.h.sdk.add_item[o]
      .sp.h.sdk.add_attrib["value";x]
      .sp.h.sdk.inner_html[(string x)]
      .sp.h.sdk.create[`option];
      }[otype;] each `b`g`x`h`i`j`e`f`c`s`p`m`d`z`n`u`v`t`B`G`X`H`I`J`E`F`C`S`P`M`D`Z`N`U`V`T`raw;

    o1: .sp.h.sdk.add_item[ofrm]
        .sp.h.sdk.create[`div];
    o2:
      .sp.h.sdk.add_item[o1]
      .sp.h.sdk.add_event[`onchange; "filterSvc()"]
      .sp.h.sdk.add_attrib["name";"filter"]
      .sp.h.sdk.create[`select];

    .sp.h.sdk.add_item[o2] .sp.h.sdk.add_attrib["value";""] .sp.h.sdk.inner_html["Show All"] .sp.h.sdk.create[`option];

    {[o;x]
      .sp.h.sdk.add_item[o]
      .sp.h.sdk.add_attrib["value";x]
      .sp.h.sdk.inner_html[(string x)]
      .sp.h.sdk.create[`option];
      }[o2;] each allsvcs;

    o4:
        .sp.h.sdk.add_event[`onclick; "editCfg()"]
        .sp.h.sdk.add_item[o1]
        .sp.h.sdk.name[`btn;`btn]
        .sp.h.sdk.inner_html["Apply Changes"]
        .sp.h.sdk.create[`button];

    ootbl:
       .sp.h.sdk.size["100%";"100%"]
       .sp.h.sdk.create_chart[`cfg_list;0!tbl;(`op.width`op.height`type)!("100%";"600px";"Table")];

    };

.sp.html.handlers[`cfgedit.q]: `.view.cfgedit;