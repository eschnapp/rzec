.view.fo: {[request]
    func: "[.view.fo]: ";
    .sp.html.response[`title]: "Feature Overview";

    .sp.log.info func, "Extracting feature statistics from cache...";
    a:: {[x;y] (`account_id, y)!(x[`account_id], x[`pval]) }[;fnames] each
       select account_id, pval from
            update pval: psum % pn from
            update pn: { count each x } each  p, psum : { sum each x } each p from
            update p: flip each pass_f from
            select pass_f by account_id from
            (select account_id, sample_id, pass_f from (select from .sp.cache.tables[`verify]) where (count each pass_f) = 42);

    .sp.log.info func, "COmputing results...";
    results:: a , (0!`account_id xkey (update account_id: `TOTAL from flip enlist each  (avg each 1_ (flip a))));
    .sp.log.info func, "Processing result html elements";
    .sp.h.sdk.define_style["html, body";
             (("border";"1px none  black");
             ("height";"100%")
              ("width";"100%"))];

    otbl:
     .sp.h.sdk.size["100%";"400px"]
     .sp.h.sdk.create_chart[`otbl;results;(`type`op.width)!("Table";"100%")];

    achrt:
     .sp.h.sdk.size["100%";"400px"]
     .sp.h.sdk.create_chart[`achrt;results;(`type`op.width`op.height)!("ColumnChart";"100%";"200px")];

    res2:: flip  `feature`total!((1_ key last results);(1_ value last results));
    pchrt:
     .sp.h.sdk.size["100%";"400px"]
     .sp.h.sdk.create_chart[`ochrt;res2;(`type`op.width`op.height)!("ColumnChart";"100%";"200px")];


    };

.sp.html.handlers[`fo.q]: `.view.fo;