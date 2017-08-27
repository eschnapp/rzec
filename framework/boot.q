.boot.files: ();
.boot.include:{[f]
    if[  not all f  in .boot.files;
        -1 "[BOOT] Including: ", f;
        .boot.files:: .boot.files, enlist f;
        system "l ", f];
    };

// set the environment  
-1 "BOOTING...";
gdrive_root: getenv `SP_ROOT;
if[ 0 = count gdrive_root; 
    -1 "No SP_ROOT environment set, cannot start the core!";
    exit -1];
    
// load the service packages
-1 "Loading core";
.boot.include (gdrive_root, "/framework/core.q")

if[ 1b = (`target in key (.Q.opt .z.x));
    -1 "Post-Core load: ", ((.Q.opt .z.x)[`target])[0];
    .boot.include (((.Q.opt .z.x)[`target])[0])];
    
if[ 1b = (`start in key (.Q.opt .z.x)); 
    .sp.comp.start_all[]];
