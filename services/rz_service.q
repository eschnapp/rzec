.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/data_convert.q");
.boot.include (gdrive_root, "/framework/cache.q");

.rz.on_comp_start:{
    :1b;
    };

.sp.comp.register_component[`rzscv;`common`cache;.rz.on_comp_start];

