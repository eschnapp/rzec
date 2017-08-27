.view.model:{[request]

  allusers: exec  account_id from (select distinct account_id from .sp.cache.tables[`samples]);

  ofrm:
    .sp.h.sdk.add_attrib["action";"model.q"]
    .sp.h.sdk.add_attrib["method";"post"]
    .sp.h.sdk.create[`form];

  oslct:
    .sp.h.sdk.add_item[ofrm]
    .sp.h.sdk.add_attrib["name";"user_id"]
    .sp.h.sdk.create[`select];

  {[o;x]
    .sp.h.sdk.add_item[o]
    .sp.h.sdk.add_attrib["value";x]
    .sp.h.sdk.inner_html[(string x)]
    .sp.h.sdk.create[`option];
    }[oslct;] each allusers;

  obtn:
    .sp.h.sdk.add_item[ofrm]
    .sp.h.sdk.inner_html["Select"]
    .sp.h.sdk.add_attrib["type";"submit"]
    .sp.h.sdk.create[`button];


  if[ (count request[`args][`user_id]) <=0; :0b; ];

  uid: request[`args][`user_id];
  smpls: select from .sp.cache.tables[`samples] where account_id  = `$uid;

  {[tbl;sid]
     dat: select from tbl where sample_id = sid;
     odv: .sp.h.sdk.create[`div];

     o:
      .sp.h.sdk.add_item[odv];
      // .sp.h.sdk.add_event[`onmouseover;"this.style.border = '1px solid green';"]
      // .sp.h.sdk.add_event[`onmouseout;"this.style.border = '1px solid black';"]
      .view.p.sample_chart[dat;"300px";"200px";(enlist ("display";"inline-block")); ()!()];

    }[smpls;] each (exec distinct sample_id from smpls);

  };

.sp.html.handlers[`model.q]: `.view.model;