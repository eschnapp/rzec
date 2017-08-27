#! /bin/bash
# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
         -target $SP_ROOT/framework/tpsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name MODEL_RESULTS_TP \
        -sp_server SP_SERVER \
        -schemafile model_results_schema.q \
        -logdir $SP_ROOT/txn \
        -logname model_results_tp \
        -c 500 500 \
        -nameservers localhost:23400 \
    > $LOGPATH/model_results_tp.$DATE.log &


