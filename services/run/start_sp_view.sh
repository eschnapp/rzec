#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
	-target $SP_ROOT/services/sp_view.q \
	-start \
	-config_data_dir $SP_ROOT/config \
	-zone $ZONE \
	-in_port 23466 \
	-svc_name SP_VIEW \
	-nameservers localhost:23400 \
	-sp_server SP_SERVER \
	 > $LOGPATH/sp_view.$DATE.log &

