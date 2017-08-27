/ dbg - debug package
.sp.dbg.functions:: ([name]: `symbol$(); body: (); file: `symbol$(); namespace: `symbol$());
.sp.dbg.variables:: ([name]: `symbol$(); val: (); file: `symbol$(); namespace: `symbol$());
.sp.dbg.runtime:: `pid`address!(.z.i;.z.a);
.sp.dbg.stack:: enlist `main;

.sp.dbg.process_var:{ [name_;val_]
    .sp.dbg.variables:: .sp.dbg.variables upsert ([name: enlist name_]; val: enlist val_; file: enlist .sp.boot.current_file; namespace: enlist .sp.boot.current_ns);
    
    // debug variables
    if[name_ ~ `.sp.boot.current_file;
        .sp.dbg.runtime[`file]:: val_];
    if[name_ ~ `.sp.boot.current_ns;
        .sp.dbg.runtime[`namespace]:: val_];
    if[name_ ~ `.sp.boot.current_line;
        .sp.dbg.runtime[`line]:: val_];
    if[name_ ~ `.sp.boot.current_func;
        .sp.dbg.runtime[`func]:: val_];
            
    .sp.dbg.runtime[`vs_name]:: name_;
    .sp.dvf.runtime[`vs_val]:: val_;
    };
    
.sp.dbg.process_func:{ [name_; val_]
    .sp.dbg.functions:: .sp.dbg.functions upsert ([name: enlist name_]; body: enlist val_; file: enlist .sp.boot.current_file; namespace: enlist .sp.boot.current_ns);
     
    };
    
.sp.dbg.on_value_set:{[name_;idx_]
    / process based on type of value...
    if[ 100h > type (value name_); : .sp.dbg.process_var[name_;value name_]];
    :.sp.dbg.process_func[name_;value name_];
    };

.sp.dbg.push_stack:{[func_]
    .sp.dbg.stack:: .sp.dbg.stack, func_;
    };

.sp.dbg.pop_stack:{[]
    .sp.dbg.stack:: -1_ .sp.dbg.stack;
    };        

.z.vs:: .sp.dbg.on_value_set;