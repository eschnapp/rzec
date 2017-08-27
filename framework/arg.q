/ arg.q - handle input arguments
.sp.arg.get_arg: {[name_;required_;def_val_] 
    /@@ func .sp.arg:get_arg
    if[(0b = required_) & ((null `$def_val_) = 1b); .sp.exception["Optional arg s", (raze string name_), " must have default value"]];
    if[0b = (all null `$(.sp.arg.arguments[name_])); :$[1< count .sp.arg.arguments[name_];(.sp.arg.arguments[name_]);(.sp.arg.arguments[name_])[0]]];
    
    / not found...
    if[1b = required_; .sp.exception["Required argument not found: ", (raze string name_)]];
    .sp.arg.arguments[name_]: def_val_;
     :def_val_;    
    };

.sp.arg.exist:{[name]
    : name in (key .sp.arg.arguments);
    };
.sp.arg.is_present:.sp.arg.exist;
    
.sp.arg.optional: {[name_;def_val_]
    /@@ func .sp.arg:optional
    v: raze string def_val_; 
    :.sp.arg.get_arg[name_;0b;v];
    };
    
.sp.arg.required:  {[name_]
    /@@ func .sp.arg:required
    :.sp.arg.get_arg[name_;1b;""];
    };

.sp.arg.on_comp_start:{[]
    .sp.arg.argv:: .Q.opt .z.x;
    .sp.arg.arguments:: ((enlist `arg_name)!(enlist enlist "arg_val")), .sp.arg.argv;
    show .sp.arg.arguments;
    :1b;
    };
    
// BEND_HERE: add function to list all argument options
    
.sp.comp.register_component[`arg;`symbol$();.sp.arg.on_comp_start];
