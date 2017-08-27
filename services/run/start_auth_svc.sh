#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
	-target $SP_ROOT/services/auth_svc.q  \
	-start \
	-config_data_dir $SP_ROOT/config \
	-zone $ZONE \
	-svc_name AUTH_SVC  \
	-nameservers localhost:23400 \
	-sp_server SP_SERVER \
	-q \
	-c 500 500 \
	 > $LOGPATH/auth_svc.$DATE.log &

