/ cron relates stuff (timers)
 

.sp.cron.on_timer_event: {[t]
    func: "[.sp.cron.on_timer_event]: ";
   {[i_;t]
        func: "[.sp.cron.on_timer_event#1]: ";
        ival: .sp.cron.events[i_][`ival];
        func: .sp.cron.events[i_][`func];
        rpt: .sp.cron.events[i_][`repeats];
        lexec: .sp.cron.events[i_][`lastexec];
        if[ ival < `long$(`time$t - `time$lexec) ;
        .sp.log.spam func, ".sp.cron.on_timer_event : will execute - timer id: ", (string i_);
            if[ rpt <> 0;
                (.[func;(i_;t); {
                    func: "[.sp.cron.on_timer_event#2]: ";
                    .sp.log.error func, "Timer event threw exception - ", (raze string x);
                    }]);
                if[ rpt > 0; .sp.cron.events:: update repeats: (rpt - 1) from .sp.cron.events where id = i_];
                .sp.cron.events:: update lastexec: t from .sp.cron.events where id = i_]];             
        }[;t] each (exec id from .sp.cron.events where id > 0);
    .sp.cron.events:: delete from .sp.cron.events where repeats = 0, id > 0;    
    };

.sp.cron.add_timer:{[ival_ms;repeats;func]
    maxid: (exec max id from .sp.cron.events);
    maxid: $[0 > maxid; 0; maxid] + 1;
    .sp.log.debug "Adding timer event (", (string maxid), ") every ", (string ival_ms), " ms and repeating ", (string repeats), " times.";
    `.sp.cron.events insert (maxid;`long$ival_ms;repeats;func;`timestamp$.z.Z);
    / if system timer is not running, start it...
    if[ 0h >= (system "t"); 
        .sp.log.debug "Starting system timer on resolution of ", (raze string .sp.cron.resolution);
        system ("t ", (.sp.cron.resolution))];
        
    :(maxid);
  };
    
.sp.cron.remove_timer: {[i]
    
    .sp.log.debug "Removing timer ", (string i);
    delete from `sp.cron.events where id = i;
    / if no more timers, stop the system timer...
    if[ 0 >= count .sp.cron.events; .sp.log.debug "Last timer removed, stopping system timer..."; system "t 0"];
    };

.sp.cron.on_comp_start: {[]
    .sp.cron.events::       ([id: enlist 0]; ival: enlist 0; repeats: enlist 0; func: enlist {[]}; lastexec: enlist 0Np);
    .sp.cron.resolution::   .sp.arg.optional[`cron_resolution;"500"]; 
    .z.ts:: .sp.cron.on_timer_event;
    :1b;
    };

.sp.comp.register_component[`cron;`arg`log;.sp.cron.on_comp_start];
