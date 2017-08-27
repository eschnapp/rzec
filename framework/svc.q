.boot.include (gdrive_root, "/framework/sub.q");
.boot.include (gdrive_root, "/framework/pub.q");

.sp.svc.on_comp_start: { []
    func:"[.sp.svc.on_comp_start] : ";
    .sp.log.info func, "component sub is ready";
    :1b ;
  };
.sp.comp.register_component[`svc; `pub`sub; .sp.svc.on_comp_start];    
    