#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."


$SP_ROOT/services/run/boot_core.sh \
        -target $SP_ROOT/framework/histsvc.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name MODEL_RESULTS_HIST \
        -sp_server SP_SERVER \
	-hdbpath $SP_ROOT/hdb/model_results/ \
        -nameservers localhost:23400 \
        -c 500 500 \
        > $LOGPATH/model_results_hist.$DATE.log &


