
.sp.file.is_string : {[x] if[ (type x) in (10h; -10h); : 1b ]; :0b };

// dir_ and file_ can be symbol or string and nothing else 
.sp.file.get_handle:{[dir_;file_] 
    func: "[.sp.file.get_handle] : "; 
    if[ not .sp.file.is_string dir_ ; 
        $[(neg llh) <> type dir_; .sp.exception func, "invalid type for dir passed"; dir_:string dir_]]; 
        
    if[ not .sp.file.is_string file_ ; 
        $[ (neg llh) <> type file_;.sp.exception func, "invalid type for file passed"; file_:string file_]]; 
        
    if[""~file_; 
        $[""~dir_; .sp.exception func, "Invalid args. Both file and dir is empty!"; :hsym `$dir_] ]; 
        
    $[""~dir_; :file_; :hsym `$(dir_,"/",file_);]; 
  } ; 

// file_ arg should be symbol and file should be present in current directory or full path+file name 
// if file_ exists, will return true else false 
.sp.file.exists:{[file_] 
    :$[0h <> type key hsym file_; 1b; 0b]; 
  } ; 
  
// loads the file from the directory specified 
// TODO: add logic to add paths to look for file under 
.sp.file.loadfile:{[dir_; file_] 
    func: "[.sp.file.loadfile] : "; 
    .sp.log.debug func, "dir = ", dir_, " and file = ", file_; 
    if[ not .sp.file.is_string dir_ ; dir_:string dir_]; 
    if[ not .sp.file.is_string file_ ; file_:string file_]; 
    
    hdl:.sp.file.get_handle[dir_; file_]; 
    .sp.log.debug func, "hdl = ", (string hdl); 
    
    if[ .sp.file.exists hdl; system "l ", 1_string hdl; .sp.log.info func, 1_(string hdl), " file load complete."; ]; 
    if[ not (.sp.file.exists hdl); .sp.exception (func, ("load failed! File , "), (file_) ,(" not found under "), dir_); ]; 
  } ;
   
// this function returns what hsym returns except it also checks if the type is string and if not will cast it to string 
.sp.file.format:{[type_;val_] 
    if[not .sp.file.is_string[val_]; val_:string val_]; // make it a string 
    if[type_~`file; :`$ $[":"~first val_;1_ val_; val_]]; //file name should not have : at the start 
    if[type_~`dir ; :`$$[":"~first val_; val_; ":",val_]] // for dir, it MUST have : at the start ( hsym does just this) 
  } ; 
  
  
.sp.file.on_comp_start: {[] 
    func : "[.sp.file.on_comp_start] : "; 
    .sp.log.info func, "component file is ready."; 
    :1b; 
  } ; 
    
// This function will be used to save RT tables to Hist DB, normally with date partition as splayed tables. 
// dir_ - directory under which data has to be saved 
// tbl_name - name of the table. will be a directory like dir_l<partition>l<tbl_name>l<col files go here> 
// att_ - a list with 2 lists. (attributes; cols that should have those attributes) 
// append_ - if data has to be appended rather than assigned to tables. if true, old data will not be lost. can be used for intra day saves. 
// part_ - partition, like date or sym. if this is date, a directory with that date will be created under the hdb directory 
// ne_cols_ - a list of non enumerated columns. These are `$ type columns which should NOT be indexed 
// data_ - a table that has data that needs to be saved to hist db 
.sp.file.save_partition:{[dir_; tbl_name_; att_; append_; part_; ne_cols_; data_]
    func: "[.sp.file.save_partition] : "; 
    if[att_~(); att_:2#`]; 
    acol: att_[1]; // attribute cols 
    att:att_[0]; // attribute list 
    if[ att in `p`s; data_:acol xasc data_;]; // sort the table if needed 
    dir_: .sp.file.format[`dir; dir_]; 
    tbl_name_: .sp.file.format[`file; tbl_name_]; 
    
    // get a handle to the directory where the data has to be written to 
    handle: .Q.par [dir_; part_; `$(string tbl_name_),"/"]; 
    // get the type of the partition column 
    part_col :key (),part_; 
    if[part_col=`symbol; part_col:`sym];
     
    // remove the keys if any and remove the partition column from data table 
    data_:(enlist part_col) _ 0!data_; 
    .sp.log.debug func, "will be saving ", (string tbl_name_), " on partition" (string part_), " to disk ", string handle; 
    
    / if there are columns with no type meaning generic lists, they can not be saved in hdb using splayed tables 
   if[(" " in exec t from meta data_); 
        .sp.log.error func, "untyped columns: ",(.Q.s exec c from meta[data_] where t=" "), ". unable to save."; :0b; ]; 
        
    ne_cols_ : (),ne_cols_; 
    
    // enumerate the data for all sym columns 
    endata: .Q.en[dir_; ne_cols_ _ data_]; 
    
    // if there are any non enumerated cols, and data needs to be appended, first get the cols to match by removing the cols in .d file 
    if[ append_; if[ not any null ne_cols_; @[ handle; `.d; :; (cols data_) except ne_cols_] ] ]; 
    
    // save it to disk now. Refer: http://code.kx.com/wiki/cookbook/PerformanceTips scroll down to end -> disk io section 
    // append (2 3) to file - .[`:file.test;();,;2 3J and assign (2 3) to file - .[`: file.test; (); : ; 2 3] 
    $[append_; .[handle; (); ,; endata ]; .[handle; (); :; endata ] ]; 
    
    / save the non enumerated cols seperately now and change schema file to have all columns 
    if[ not any null ne_cols_; 
        // ' is used to apply itemwise to the func. In this case ne_cols and data_ (ne_cols) should be of same count 
        // so for eg: nbbo (`sym`bid`ask) will have count 3 and necols should have (`sym`bid`ask). They are applied itemwise to handle 
        @[ handle; ; $[append_; ,; :]; ]'[ne_cols_; data_ ne_cols_]; 
        @[ handle; `.d; :; cols data_] ]; 
    
    / now apply attribute to attribute columns 
    if[not null acol; @[handle; acol; att#] ]; 
    .sp.log.info func, (string tbl_name_), " has been saved to disk with partion on ", (string part_), ". path on disk", (string handle); 
    :handle; 
  } ;
  
.sp.comp.register_component[`file; enlist `core; .sp.file.on_comp_start];


