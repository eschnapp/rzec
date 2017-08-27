#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."


$SP_ROOT/services/run/boot_core.sh \
        -target $SP_ROOT/framework/histsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name RCON_HIST \
        -sp_server RZ_SERVER \
	-hdbpath $SP_ROOT/hdb/rcon/ \
        -nameservers localhost:33400 \
        -c 500 500 \
        > $LOGPATH/rcon_hist.$DATE.log &

