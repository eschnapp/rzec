#! /bin/bash
# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."
$SP_BIN_PATH/boot_core.sh -target $SP_ROOT/framework/sp_server.q \
	-start -config_data_dir $SP_ROOT/config \
	-zones $ZONE \
	-in_port 33400 \
	-zone $ZONE \
	-svc_name RZ_SERVER \
	-c 500 500 \
	> $LOGPATH/sp_server.$DATE.log &
 
