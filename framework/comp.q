/ component manager - basically make sure all components are started sequentially...
/ when creating a component, the Q script should only contain functions (with namespace)
/ and one single main script line to register the component and provide the start function...
/ the component manager will ensure to start this component only after all dependencied are done...

.sp.comp.components: ([name: `symbol$()]; started: `boolean$(); depends: (); startfunc: ());

// #pragma debug func register_component
.sp.comp.register_component: {[name_; depends_; startfunc_]

    -1 string (exec count i from .sp.comp.components );
    if[ (exec count i from .sp.comp.components where name = name_) > 0; 
        -1 "[COMP] Skipping re-registration of ", (raze string name_); :0b];
        
    if[ (type depends_) < 0; depends_: (),depends_]; //enlist depends if its a scalar
     -1 "[COMP] Registering: ", (raze string name_), " With the following dependencies: ", ("," sv (string depends_));
    `.sp.comp.components upsert ([name: enlist name_]; started: enlist 0b; depends: enlist depends_; startfunc: enlist startfunc_);
    };
    
// #pragma debug func check_depends
.sp.comp.check_depends: {[tgt;comp] 
    /-1 "Checking Component Dependencies for ", string tgt;
    a: exec depends from .sp.comp.components where name in comp; 
    if[(count a) = 0; :0b]; 
    if[tgt in a; :1b]; 
    : any (.sp.comp.check_depends[tgt;] each a);
    };

// #pragma debug func start_comp
.sp.comp.start_comp:{[comp_]

      -1 (string .z.Z), "[BOOT] Tryin to start component ", string comp_;
      if[ 1b = null comp_; -1 (string .z.Z), "[BOOT]: null component!"; :1b];
      
      deps: raze (exec depends from .sp.comp.components where name = comp_ );
      if[ (count deps) > 0 ;
            if[ not all deps in (exec name from .sp.comp.components);
                bad: deps except (exec name from .sp.comp.components);
                .sp.exception "Not all dependencied for ", (raze string comp_), " are registered components (", ("," sv (string bad)), ")!!!"];     
          if[ 1b = .sp.comp.check_depends[comp_;comp_];
            .sp.critical "Detected circular dependency for component ", (string comp_);];
          deps_finished: (exec count i from .sp.comp.components where name in deps, started = 1b);
          if[(count deps) > deps_finished; -1 (string .z.Z), "[BOOT] Still waiting for dependens on component ", string comp_; :0b]];
       
      start_func:(exec last startfunc from .sp.comp.components where name = comp_);
      -1 "Executing component start function for ", (string comp_);
      res: start_func[];
      if[ (neg 1h) <> type res; .sp.critical "Component start function did not return a boolean result: ", string comp_;];
      if[ 1b = res; 
        .sp.comp.components:: update started: 1b from .sp.comp.components where name = comp_];   
      :res;
      };
           
// #pragma debug func start_all
.sp.comp.start_all:{[]
    finished: exec count i from .sp.comp.components where started = 0b; / number of not started comps
    /initctx: ((enlist `)!enlist());
    attempts: 0;
    while[finished > 0; / do while not finished
          attempts +: 1; 
          .sp.comp.start_comp each ( exec name from .sp.comp.components where started = 0b);
          finished: (exec count i from .sp.comp.components where started = 0b);
          if[ finished > 0; -1 (string .z.Z), "[BOOT] Pending: ", string finished ];
          if[ attempts >= 25; .sp.exception "[BOOT] Unable to start system after 25 attempts!"];
          ];
    };

// Helper funcs
.sp.comp.all_comps_ready : { : 0 = exec count i from .sp.comp.components where started = 0b };
.sp.comp.get_all_components : { : .sp.comp.components };

.sp.comp.start:{[]
    .qf.comp.start_all[];
    };