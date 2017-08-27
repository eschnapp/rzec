#! /bin/bash
echo "setting up the sp environment...";
if [ -z "$SP_ROOT" ]; then ## Succeeds if VAR is unset or empty 
    echo "ERROR: SP_ROOT must be set!";
	exit -1;
fi

if [ -z "$SP_SYS" ]; then ## Succeeds if VAR is unset or empty 
    echo "ERROR: SP_SYS must be set!";
	exit -1;
fi

export PATH="$SP_ROOT/framework/core:$SP_ROOT/framework/q:$SP_ROOT/framework/q/$SP_SYS:$PATH"
export DATE=`date +\%Y-\%m-\%dT\%H.\%M.\%S.\%N`
export LOGPATH="$SP_ROOT/log"
export SP_BIN_PATH="$SP_ROOT/services/run"
export QHOME=$SP_ROOT/framework/q

#Set the correct zone
export ZONE=rzec; 
echo zone is set to $ZONE

echo "done"

