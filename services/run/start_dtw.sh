#! /bin/bash
echo "Sourcing Environemnt..."
source $SP_ROOT/services/run/env.sh

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh 
	-target $SP_ROOT/services/dtwm.q  
	-start 
	-config_data_dir $SP_ROOT/config 
	-zone $ZONE 
	-svc_name FBM  
	-nameservers 107.178.216.247:23400  
	-sp_server SP_SERVER  \
	> $LOGPATH/dtwm.$DATE.log &

