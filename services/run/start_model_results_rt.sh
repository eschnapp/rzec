#! /bin/bash
echo "Sourcing Environemnt..."
source $SP_ROOT/services/run/env.sh

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
        -target $SP_ROOT/framework/rtsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name MODEL_RESULTS_RT \
        -sp_server SP_SERVER \
        -tpsvc MODEL_RESULTS_TP \
        -histsvc  MODEL_RESULTS_HIST \
        -hdbpath $SP_ROOT/hdb/model_results/ \
        -nameservers localhost:23400 \
        -c 500 500 \
        > $LOGPATH/model_results_rt.$DATE.log &
