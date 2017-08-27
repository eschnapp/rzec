#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
        -target $SP_ROOT/framework/rtsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name TRX_RT \
        -sp_server SP_SERVER \
        -tpsvc TRX_TP \
        -histsvc TRX_HIST \
        -hdbpath $SP_ROOT/hdb/trx/ \
        -nameservers localhost:23400 \
        -c 500 500 \
        > $LOGPATH/trx_rt.$DATE.log &

