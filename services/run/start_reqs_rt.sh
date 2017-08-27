#! /bin/bash
echo "Sourcing Environemnt..."
source $SP_ROOT/services/run/env.sh

echo "Starting Process..."


$SP_ROOT/services/run/boot_core.sh \
        -target $SP_ROOT/framework/rtsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name REQUESTS_RT \
        -sp_server SP_SERVER \
        -tpsvc REQUESTS_TP \
        -histsvc REQUESTS_HIST \
        -hdbpath $SP_ROOT/hdb/reqs/ \
        -nameservers localhost:23400 \
        -c 500 500 \
        > $LOGPATH/requests_rt.$DATE.log &

