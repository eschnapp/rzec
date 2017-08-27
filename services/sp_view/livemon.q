.view.livemon:{[request]

    f: { a:(select from (select by sample_id from .sp.cache.tables.sample_status) where deleted = 0b);  select  account_id, total,  today, rate, pass from (update rate: 0^(pass % total), pass: 0^pass, total: 0^total, today: 0^today from (((select total: count i by account_id from a) lj (select pass: count i by account_id from a where valid = 1b)) lj (select today: count i by account_id from a where date = .z.D)))};

    hname: "146.148.51.210";
    if[ (`$( last (system "hostname"))) = `research; hname: "104.154.58.235"];
    .sp.h.sdk.add_sub[("ws://",hname,":23466");"SAMPLES_RT";"sample_status";(string f)];

//    tbl: 0!.sp.cache.tables[`sample_status];
    tbl: 0!(f[]);

   .sp.h.sdk.size["100vw";"100vh"]
   .sp.h.sdk.add_attrib["data-sub";"SAMPLES_RT.sample_status"]
   .sp.h.sdk.create_chart[`sample_stat;0!tbl;(`op.colorAxis`op.hAxis`op.vAxis`op.sizeAxis`op.width`op.height`type)!(`$"{colors: ['red', 'green']}";`$"{title: 'total'}";`$"{title: 'today'}";"{minValue: 0,  maxSize: 20}";"100vw";"100vh";"BubbleChart")];

    };

.sp.html.handlers[`livemon.q]: `.view.livemon;