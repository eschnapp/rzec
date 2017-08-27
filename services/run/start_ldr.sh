#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
	-target $SP_ROOT/services/sp_ldr.q \
	 -start \
	-config_data_dir $SP_ROOT/config \
	-zone $ZONE \
	-svc_name SP_LOADER  \
	-nameservers localhost:23400 \
	-sp_server SP_SERVER  \
	-c 500 500 \
	-q \
	> $LOGPATH/sp_loader.$DATE.log &
