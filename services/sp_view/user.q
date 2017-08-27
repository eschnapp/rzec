
.view.user: {[request]
     func: "[.view.user]: "	;

     tbl: select from 0!(select by name from .sp.cache.tables[`users]) where deleted = 0b;
     allusers: exec distinct name from tbl;
    .sp.html.response[`title]: "User Parameters Editor";
    .sp.h.sdk.define_style["html, body";
             (("border";"1px none  black");
             ("height";"80vh");
              ("width";"95vw"))];

    .sp.h.sdk.define_func["editUser()"] "{
                    var rows = all_charts['user_list'].getSelection();
                    for( x = 0; x < rows.length; x++ ) {
                        var row = rows[x];
                        var uid;
                        if( 'user_list' in all_data_views ) {
                            uid = all_data_views['user_list'].getValue(row.row,0);
                        } else {
                            uid = all_data_tables['user_list'].getValue(row.row,0);
                        }

                        console.log(\"Opening new window to edit \" + uid);
                        window.open('useredit.q?user_id='+uid,\"subframe\", \"location: 0, menubar: 0, status : 0, titlebar: 0, toolbar: 0 \");
                    }
                   }";

    .sp.h.sdk.define_func["filterUser()"] "{
                var tmp = document.getElementsByName('filter')[0];
                if( tmp.length <= 0 )
                    return;

                var uid = tmp[tmp.selectedIndex].value;
                if( uid.length > 0 ) {
                    var view = new google.visualization.DataView(all_data_tables['user_list']);
                    view.setRows(view.getFilteredRows([{column: 0, value: uid}]));
                    all_data_views['user_list'] = view;
                } else {
                    delete all_data_views['user_list'];
                }
           redraw_user_list();
         }";

     o1: .sp.h.sdk.create[`div];

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
        .sp.h.sdk.add_event[`onclick; "editUser()"]
        .sp.h.sdk.add_item[o1]
        .sp.h.sdk.name[`btn;`btn]
        .sp.h.sdk.inner_html["Edit"]
        .sp.h.sdk.create[`button];

    ootbl:
       .sp.h.sdk.size["100%";"100%"]
       .sp.h.sdk.create_chart[`user_list;0!tbl;(`op.width`op.height`type)!("100%";"600px";"Table")];

	};

.sp.html.handlers[`user.q]: `.view.user;