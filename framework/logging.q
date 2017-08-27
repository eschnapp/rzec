/ log.q - handle logging functions

.sp.log.output: {[lvl;msg]
    // fmt: (string .z.Z)," [",(string upper lvl),"] : ", msg;
    nm: .sp.log.level_names[lvl];
    fmt: (string .z.Z)," [",(string nm),"] : ", msg;
    .sp.log.pub_external[lvl; msg];
    -1 fmt;
  };  

.sp.log.pub_external:{ [lvl; msg] }; // no op func. Will be overridden in log_adptr to publish to LOGS_TP

.sp.log.get_level:{ 
    /@@ func .sp.log:get_level
    :(key .sp.log.level_map)[.sp.log.level] };

.sp.log.set_level:{ [lvl_] 
    if[ (lvl_ in .sp.log.levels) = 0; :.sp.const.OK];
    .sp.log.output[`always;"Setting loglevel to: ", (string lvl_)];
    .sp.log.level: .sp.log.level_map[lvl_];  
    };
    
.sp.log.on_comp_start:{[]
    .sp.log.levels::    `never`wtf`error`warn`info`debug`spam`everything;
    .sp.log.level_names:: (.sp.log.levels)!(`NEVER`CRITICAL`ERROR`WARNING`INFO`DEBUG`DEFAULT`DEFAULT);
    .sp.log.level_map:: (.sp.log.levels)!til (count .sp.log.levels);
    .sp.log.level::     .sp.log.level_map[`everything];                            / - 1 to account for `never             

    / init log
    .sp.log.output[`always;"Initializing log framework..."];
    level: `$.sp.arg.optional[`log_level;`info];
    .sp.log.set_level[ level];
    
    {[l] 
        func_name: `$(".sp.log.", (string l));
         func_def:  "{[msg] if[ .sp.log.level >= .sp.log.level_map[`",(string l),"]; .sp.log.output[`", (string l),";msg]];}";
        .sp.log.output[`debug;"Registering log funcion: [", (string func_name), "]: ", (func_def)];
        func_name set (value func_def);
        } each (1_ ( -1_ (.sp.log.levels)));
    :1b;
    };

.sp.comp.register_component[`log;enlist `arg;.sp.log.on_comp_start];    
