.view.main: {[request]

     sids: exec sample_id from (select distinct sample_id from .sp.cache.tables[`verify]);
     tbl:  0!(select by sample_id from .sp.cache.tables[`sample_status] where sample_id in sids, deleted = 0b);
     allusers: exec distinct account_id from tbl;

//    .sp.h.sdk.body_attribs[(enlist `bgcolor)!(enlist "#27A7D1")]
    .sp.html.response[`title]: "Sample Explorer";
    .sp.h.sdk.define_style["html, body";
             (("border";"1px none  black");
             ("height";"100vh")
              ("width";"100vw"))];

    .sp.h.sdk.define_func["filterUser()"] "{
                var tmp = document.getElementsByName('filter')[0];
                if( tmp.length <= 0 ){
                    console.log('WARNing: cannot find filter element!');
                    return;
                }

                var uid = tmp[tmp.selectedIndex].value.trim();
                console.log('filtering user: [' + uid + ']');
                if( uid.length > 0 ) {
                    var view = new google.visualization.DataView(all_data_tables['sample_list']);
                    view.setRows(view.getFilteredRows([{column: 3, value: uid}]));
                    all_data_views['sample_list'] = view;
                } else {
                    delete all_data_views['sample_list'];
                }
           redraw_sample_list();
         }";

    .sp.h.sdk.define_func["viewSample()"] "{
                    var rows = all_charts['sample_list'].getSelection();
                    for( x = 0; x < rows.length; x++ ) {
                        var row = rows[x];
                        var sid;
                        if( 'sample_list' in all_data_views ) {
                            sid = all_data_views['sample_list'].getValue(row.row,0);
                        } else {
                            sid = all_data_tables['sample_list'].getValue(row.row,0);
                        }

                        console.log(\"Opening new window to view \" + sid);
                        window.open('sig.q?sample_id='+sid,\"\", \"location: 0, menubar: 0, status : 0, titlebar: 0, toolbar: 0 \");
                    }
                   }";

    .sp.h.sdk.define_func["openWnd(url)"] "{
                    // window.open(url,\"subframe\", \"location: 0, menubar: 0, status : 0, titlebar: 0, toolbar: 0 \");
                    // document.getElementsByName('subframe')[0].src = url;
                        window.location.assign(url);
                   }";


     o1:
      .sp.h.sdk.style[( ("width";"100%");
                        ("height";"95vh");
                        ("border";"2px none red");
                        ("position";"relative");
                        ("float";"left"))]
      .sp.h.sdk.create[`div];


    o2:
      .sp.h.sdk.add_item[o1]
      .sp.h.sdk.add_event[`onchange;"filterUser()"]
      .sp.h.sdk.add_attrib["name";"filter"]
      .sp.h.sdk.create[`select];

    .sp.h.sdk.add_item[o2] .sp.h.sdk.add_attrib["value";""] .sp.h.sdk.inner_html["Show All"] .sp.h.sdk.create[`option];

    {[o;x]
      .sp.h.sdk.add_item[o]
      .sp.h.sdk.add_attrib["value";x]
      .sp.h.sdk.inner_html[(string x)]
      .sp.h.sdk.create[`option];
      }[o2;] each allusers;

    obtn2:
        .sp.h.sdk.add_event[`onclick; "viewSample()"]
        .sp.h.sdk.add_item[o1]
        .sp.h.sdk.name[`btn;`btn]
        .sp.h.sdk.inner_html["Examine Sample"]
        .sp.h.sdk.create[`button];

    otbl::
       .sp.h.sdk.add_item[o1]
       //.sp.h.sdk.size["100%";"I%"]
       .sp.h.sdk.create_chart[`sample_list;tbl;(`op.width`op.height`type)!("100%";"600px";"Table")];

//    oframe:
      //.sp.h.sdk.add_event[`onload;"document.getElementsByName('subframe')[0].style.height = window.innerHeight; alert('EEE');"]
//      .sp.h.sdk.style[( ("width";"49.5%");
//                        ("border";"2px none black");
//                        ("height";"95vh");
//                        ("position";"relative");
//                        ("float";"right"))]
//      .sp.h.sdk.add_attrib["name";"subframe"]
//      .sp.h.sdk.create[`iframe];

    };

.sp.html.handlers[`main.q]: `.view.main;