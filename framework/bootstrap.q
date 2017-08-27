.sp.boot.pragmas:: (enlist `)! (enlist `);
.sp.boot.add_pragma: {[token ; func]
    .sp.boot.pragmas:: .sp.boot.pragmas, ((enlist token)!(enlist func));
    };
     
.sp.boot.pragma.include: {[x]
    .sp.boot.log "Processing include pragma";
    tmp_ptr: .sp.boot.file_ptr; 
    tmp_file: .sp.boot.file;
    .sp.boot.file_ptr: 0;
    fname: (":",(8 _x));   
    output:.sp.boot.process_file[fname]; 
    .sp.boot.file: tmp_file;
    .sp.boot.file_ptr: tmp_ptr;
    output ,: ("    .sp.dbg.file:: `", .sp.boot.file, ";"); 
    :output;     
    };
        
.sp.boot.pragma.debug: {[x]
    .sp.boot.log "Processing debug pragma";
    cmd: " " vs (6_ x);
    
    res: enlist "";
    if[ 0 >= (count cmd); .sp.boot.log "Ignoring empty debug pragma"; :enlist ""];
    if[ ((1b = ("file"~ cmd[0])) | (1b = ("context"~cmd[0]))) ;res: res, enlist ("   .sp.dbg.file:: `", cmd[1],";")];
    / if[ ((1b = ("ns"~ cmd[0])) | (1b = ("context"~cmd[0]))); res: res, enlist ("     .sp.dbg.ns:: `", cmd[1],";")];
    if[ ((1b = ("func"~cmd[0])) | (1b = ("context"~cmd[0]))); res: res, enlist("     .sp.dbg.func:: `",cmd[1],";")];
    if[ ((1b = ("line"~cmd[0])) | (1b = ("context"~cmd[0]))); res: res, enlist("     .sp.dbg.line:: \"", (string .sp.boot.file_ptr), "\";")];    
    :res;
    };
    
.sp.boot.add_pragma[`include;`.sp.boot.pragma.include];
.sp.boot.add_pragma[`debug; `.sp.boot.pragma.debug];
    
    
.sp.boot.log:{ [msg]
    -1 raze (.sp.boot.token, msg);
    };
    
.sp.boot.process_pragma: {[line_] 
    dbg: " " vs line_;
    .sp.boot.log "Found pragma ",dbg[0], " (", line_, ")";
    func: .sp.boot.pragmas[`$(dbg[0])];
    if[ 1b = null func; msg: ("/ Ignoring unknown pragma [", dbg[0],"]"); .sp.boot.log msg; :enlist msg];
    res: func[line_];
    :res;
    };
    
 

.sp.boot.process_one_line: {[line_] 
    / .sp.boot.log "Processing line: ", line_;   
    
    .sp.boot.file_ptr: .sp.boot.file_ptr+1;
    token: "#pragma";
    if[1b=(token~((count token)#(ltrim line_)));
        : .sp.boot.process_pragma[((count token) + 1)_ (ltrim line_)]];

    : enlist line_;
    };

.sp.boot.process_file: {[filename_]
    .sp.boot.log "bootstrapping file ", filename_;
    .sp.boot.file:: filename_;
    tmp: system "cd";
    src: (getenv `KFWROOT), ("\\src");
    if[ 0h = (type key hsym `$filename_);
        .sp.boot.log "Checking for file in root folder: ", src; 
        system "cd ", src];    
    file_buffer:(("**"; "\n") 0: hsym `$filename_)[0];                                       / read the q file into a list of lines
    system "cd ", tmp;
    
    output_buffer: enlist (("/ BEGING BOOTSTRAPPED CODE FOR FILE : ", filename_)
                          ;("    .sp.dbg.file:: `", filename_, ";"));
    output_buffer: raze output_buffer, (.sp.boot.process_one_line each file_buffer);              / process each source line and output into a new buffer 
    output_buffer ,: ("    .sp.dbg.file:: `", .sp.boot.file, ";");
    output_buffer: output_buffer, (enlist ("/ END BOOTSTRAPPED CODE FOR FILE: ", filename_));
    .sp.boot.log "done bootstrapping ", filename_;
    : output_buffer;
    };    

.sp.boot.write_to_file: {[filename_;stream]
    .sp.boot.log "Writing output to temp q script ", filename_;
    handle: (`$(":",filename_));
    handle 0: stream;
    :handle;
    };

.sp.boot.load: { 
    
    / check if debugger needs to be enables
    if[`debug in (key (.Q.opt .z.x));
        system "l ", kfwroot, "\\src\\dbg.q"];

    if[`debug_extreme in (key (.Q.opt .z.x));
        system "l ", kfwroot, "\\src\\dbg.q";
        .sp.dbg.extreme:: 1b;];
      
    .sp.boot.log "Loading bootstrapped handle ", .sp.boot.out_file_name
    .sp.dbg.file: "";
    .sp.dbg.func: "";
    .sp.dbg.ns: "";
    .sp.dbg.line: "";
    @[system;("l ", .sp.boot.out_file_name);{
        .sp.boot.log "Error while loading bootstrapped file ", .sp.boot.out_file_name;
        .sp.boot.log "Message: ", raze (string x);
        if[ 0 < count .sp.dbg.file; .sp.boot.log "File: ", (string .sp.dbg.file)];
        if[ 0 < count .sp.dbg.func; .sp.boot.log "Func: ", (string .sp.dbg.func)];
        if[ 0 < count .sp.dbg.ns; .sp.boot.log "Namespace: ", (string .sp.dbg.ns)];
        if[ 0 < count .sp.dbg.line; .sp.boot.log "Line: ", (string .sp.dbg.line)];
        .sp.boot.log "Variables :", raze raze (  raze {[x] tmp: (string x)," [",(string type x),"]: ",($[(count value x) > 10;(10#(raze value x)),"...~";(string value x)]),", "} each (system "v"));
        .sp.exception "Boostrap Failed";   
    }];
     .sp.boot.log "Bootstrap file loaded successfully, starting component manager...";
    /      @[.sp.comp.start_all[];;{
    /         .sp.boot.log "Error while loading bootstrapped file ", .sp.boot.out_file_name;
    /         .sp.boot.log "Message: ", raze (string x);
    /         if[ 0 < count .sp.dbg.file; .sp.boot.log "File: ", (string .sp.dbg.file)];
    /         if[ 0 < count .sp.dbg.func; .sp.boot.log "Func: ", (string .sp.dbg.func)];
    /         if[ 0 < count .sp.dbg.ns; .sp.boot.log "Namespace: ", (string .sp.dbg.ns)];
    /         if[ 0 < count .sp.dbg.line; .sp.boot.log "Line: ", (string .sp.dbg.line)];
    /         .sp.boot.log "Variables :", raze raze (  raze {[x] tmp: (string x)," [",(string type x),"]: ",($[(count value x) > 10;(10#(raze value x)),"...~";(string value x)]),", "} each (system "v"));
    /         
    /         }];
    /.sp.com.start_all[];   
    };


// MAIN SCRIPT STARTS HERE...

.sp.boot.file_ptr: 0;                                                              / file line pointer 
.sp.boot.token: "[BOOTSTRAP]: ";                                                   / debug prefix
.sp.boot.log "Starting bootstrapper process...";

kfwroot: raze (.Q.opt .z.x)[`kfwroot];                                               / get the kfwroot where the temporary bootstrapped q file will reside...
if[ 0 = count kfwroot; kfwroot: getenv `KFWROOT];
if[ 0 = count kfwroot;
    .sp.boot.log "no kfwroot supplied for the runtime to run in... aboring!";
    exit -1]; 
kfwroot
`KFWROOT setenv kfwroot;

kfwmain: raze (.Q.opt .z.x)[`kfwmain];                                          / get the main Q file to work with
if[ 0 = count kfwmain;
    .sp.boot.log "no kfwmain file supplied for the runtime bootstrap to process... aboring!";
    exit -1];                                                                   / terminate if no root Q file was supplied
    
kfwboot: raze (.Q.opt .z.x)[`kfwboot];                                               / get the kfwroot where the temporary bootstrapped q file will reside...
if[ 0 = count kfwboot;
    .sp.boot.log "no kfw boot supplied for the runtime bootstrap to run in... aboring!";
    exit -1];                                                                   / terminate if no root Q file was supplied    
                       
                                         
.sp.boot.file: kfwmain;
.sp.boot.log "Bootstrapping root file.";
outfile: .sp.boot.process_file[kfwmain];
.sp.boot.out_file_name: (string .z.i), "_bootstrap.q";
system raze("cd ", kfwboot);
.sp.boot.write_to_file[.sp.boot.out_file_name; outfile];    
.sp.boot.load[.sp.boot.out_file_name];