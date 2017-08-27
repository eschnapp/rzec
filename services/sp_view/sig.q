.view.sig:{[request]

    .sp.html.response[`title]: "Signature Overview";
    sid: request[`args][`sample_id];
    if[(count sid) <= 0; .sp.exception "SampleID must be supplied!"];

    .sp.h.sdk.define_style["html, body, div";
                 (("border";"1px none black");
                  ("height";"100%")
                  ("width";"100%"))];

    mres: select from .sp.cache.tables[`verify] where sample_id = `$sid;
    if[ (count mres) < 1; .sp.exception ("cant find results for ", sid)];
    mres: mres[0];
    train_sids: mres[`fs];

    all_samples: select from .sp.cache.tables[`samples] where sample_id in (train_sids, `$sid);

    // create the container divs
    o1: .sp.h.sdk.create[`div];
    oleft:
        .sp.h.sdk.add_item[o1]
        .sp.h.sdk.style[(("float";"left");
                ("width";"30%");
                ("height";"100vh");
                ("display";"inline-block"))]
        .sp.h.sdk.create[`div];

    oright:
        .sp.h.sdk.add_item[o1]
        .sp.h.sdk.style[(("float";"right");
                ("width";"69.5%");
                ("height";"100vh");
                ("overflow";"auto");
                ("display";"inline-block"))]
        .sp.h.sdk.create[`div];

    // create the main chart
    dtbl: (select from all_samples where sample_id = `$sid);
    last_dtbl:: dtbl;
    omchrt:
       .sp.h.sdk.add_item[oleft]
       .view.p.sample_chart[dtbl;"400px";"250px";(enlist ("float";"bottom")); ()!()];

//      .sp.h.sdk.add_item[oleft]
//    .sp.h.sdk.style[(("border";"1px none black");
//                ("height";"400px");
//                ("float";"top");
//                ("width";"600px"))]
//      .sp.h.sdk.create_chart[`omchrt;dtbl]
//            (`type`title`op.width`op.height`op.pointSize)!("ScatterChart";`$sid;"600px";"400px";2);

    // prepare the feature table

    ttbl: ([] feature_name: fnames; z: mres[`z]; v: (count fnames)#mres[`v]; m: mres[`m]; s: mres[`s]; pass: `int$mres[`pass_f]);
    ttbl: update pass: -1 from ttbl where pass = 0;

    otbl:
     .sp.h.sdk.add_item[oleft]
     .sp.h.sdk.style[(("border";"1px none black");
                ("float";"bottom");
                ("width";"100%");
                ("height";"600px");
                ("display";"inline-block"))]
     .sp.h.sdk.create_chart[`otbl;ttbl;(`type`op.width`formatter)!("Table";"100%";(enlist ("ArrowFormat";5)))];

    {[smplt;o2;tsid]
        //xp: exec x from (select from smplt where sample_id = tsid);
        //yp: exec neg y from (select from smplt where sample_id = tsid);
   //     dtbl: select X_Pos: x, Y_Pos: neg y from (select from smplt where sample_id = tsid);

        ochrt:
        .sp.h.sdk.add_item[o2]
   //     .sp.h.sdk.style[(("border";"1px none black");
   //             ("width";"300px");
   //             ("height";"200px");
   //             ("display";"inline-block"))]
   //     .sp.h.sdk.create_chart[`$(ssr[string tsid;"-";"_"]);dtbl;(`type`title`op.pointSize)!("ScatterChart";string tsid;2)];
       .view.p.sample_chart[(select from smplt where sample_id = tsid);"300px";"200px";(enlist ("display";"inline-block")); ()!()];
    }[all_samples;oright;] each train_sids

   };

.sp.html.handlers[`sig.q]: `.view.sig;