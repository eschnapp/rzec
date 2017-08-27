#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
	-target $SP_ROOT/services/appengine_proxy_sp_api.q  \
	-start \
	-config_data_dir $SP_ROOT/config \
	-zone $ZONE \
	-svc_name GAE_PROXY_PUBLIC  \
	-nameservers localhost:23400 \
	-in_port 23402 \
	-sp_server SP_SERVER  \
	-q \
	-c 500 500 \
	> $LOGPATH/gae_proxy_public.$DATE.log &

