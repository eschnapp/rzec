/ constants - const values
.sp.const.OK::  0;
.sp.const.ERR:: 1;

.sp.consts:(`OK; `ERR)!(0; 1);
.sp.consts[`DEF_EXEC_TO]:2000;
.sp.consts[`DEF_SLEEP_PERIOD]:5000;
.sp.consts[`DEF_OPEN_PORT_TO]:5000;
.sp.consts[`DEF_RETRY_CONN_TIMES]:5;
.sp.consts[`DEF_WFS_TO]:5000;
.sp.consts[`DEF_EXEC_INTERVAL]:500;
.sp.consts[`DEF_WFS_INTERVAL]:500;

API_ERRORS:()!();
API_ERRORS[`BAD_MSG_TYPE]:50000;
API_ERRORS[`NO_FUNC_MAP]:50001;
API_ERRORS[`FAIL_TO_CALL_BACKEND]:50002;
API_ERRORS[`NO_RET_HDL]:50003;
API_ERRORS[`USR_NOT_PERMISSIONED]:50004;
API_ERRORS[`ALLREADY_EXISTS]:50005;
API_ERRORS[`DOSENT_EXISTS]:50006;
API_ERRORS[`FAIL_TO_LOCATE_RET_HDL]:50007;
API_ERRORS[`COUNT_MISMATCH]:50008;
API_ERRORS[`UNKNOWN_DOMAINS]:50009;

.sp.exception:{ [msg] 
    -1 "EXCEPTION: " msg;
    'msg;
    };
    
.sp.critical: {[msg]
    -1 "CRITICAL: ", msg;
    exit -1;
    };


