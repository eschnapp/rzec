/ kfw.q main fw file just include everything else
/ pragma debug file

.boot.include (gdrive_root, "/framework/const.q");
.boot.include (gdrive_root, "/framework/comp.q");
.boot.include (gdrive_root, "/framework/logging.q");
.boot.include (gdrive_root, "/framework/arg.q");
.boot.include (gdrive_root, "/framework/cron.q");
.boot.include (gdrive_root, "/framework/io.q");
.boot.include (gdrive_root, "/framework/file.q");
    
.sp.on_start: {[]
    / called here after all dependencies are ready and core is ready for use...
    .sp.log.info "CORE Is Ready to go!";
    :1b;
  };
whoami:{ inst:$[-10h = type .sp.arg.arguments[`instance]; .sp.arg.arguments[`instance]; .sp.arg.arguments[`instance][0] ];
    iam : .sp.arg.arguments[`zone][0],":",.sp.arg.arguments[`svc_name][0],":",inst; .sp.log.info iam; :iam };

.sp.comp.register_component[`core;`log`arg`cron`io;.sp.on_start];
