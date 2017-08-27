#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
        -target $SP_ROOT/framework/rtsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name EVENTS_RT \
        -sp_server RZ_SERVER \
        -tpsvc EVENTS_TP \
        -histsvc EVENTS_HIST \
        -hdbpath $SP_ROOT/hdb/events/ \
        -nameservers localhost:33400 \
        -c 500 500 \
        > $LOGPATH/events_rt.$DATE.log &

