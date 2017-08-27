.view.useredit: {[request]
    func: "[.view.useredit]: ";

    .sp.html.response[`title]: "User Edit";
    uid: request[`args][`user_id];
    if[(count uid) <= 0; .sp.exception "UserID must be supplied!"];



    if[`dosave in (key request[`args]);
        .view.p.save_user[request];
        ores: .sp.h.sdk.inner_html["User saves successfully!"] .sp.h.sdk.create[`div];
        :0b;
        ];

    .sp.h.sdk.define_func["saveChanges()"] "{
                   }";
    tbl: select from .sp.cache.tables[`users] where name = `$uid;
    usr: last 0!tbl;

    ofrm:
            .sp.h.sdk.add_attrib["action";"useredit.q"]
            .sp.h.sdk.add_attrib["method";"post"]
            .sp.h.sdk.create[`form];

    ouid:   .sp.h.sdk.add_item[ofrm]
            .sp.h.sdk.add_attrib["name";"user_id"]
            .sp.h.sdk.add_attrib["type";"hidden"]
            .sp.h.sdk.add_attrib["value";uid]
            .sp.h.sdk.create[`input];

    ohid:   .sp.h.sdk.add_item[ofrm]
            .sp.h.sdk.add_attrib["name";"dosave"]
            .sp.h.sdk.add_attrib["type";"hidden"]
            .sp.h.sdk.add_attrib["value";"true"]
            .sp.h.sdk.create[`input];

    otbl:   .sp.h.sdk.add_item[ofrm]
            .sp.h.sdk.create[`table];

    {[otbl;cl;vl]
        otr: .sp.h.sdk.add_item[otbl]
            .sp.h.sdk.create[`tr];

        otd1: .sp.h.sdk.add_item[otr]
              .sp.h.sdk.create[`td];

        otd2: .sp.h.sdk.add_item[otr]
            .sp.h.sdk.create[`td];

        otag: .sp.h.sdk.add_item[otd1]
            .sp.h.sdk.inner_html[(raze string cl)]
            .sp.h.sdk.create[`div];

       oedt: .sp.h.sdk.add_item[otd2]
            .sp.h.sdk.add_attrib["name";(raze string cl)]
            .sp.h.sdk.add_attrib["value"; (raze string vl)]
            .sp.h.sdk.create[`input];

      if[ cl in `name`date`time; .sp.h.sdk.add_attrib["readonly";"readonly";oedt]];

        }[otbl;;] ./: flip (key usr; value usr);

    osv:
        .sp.h.sdk.add_item[ofrm]
        .sp.h.sdk.inner_html["Save Changes"]
        .sp.h.sdk.add_attrib["type";"submit"]
        .sp.h.sdk.create[`button];

    };

.sp.html.handlers[`useredit.q]: `.view.useredit;