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
        -svc_name RCON_TP \
        -sp_server RZ_SERVER \
        -schemafile rcon_schema.q \
        -logdir $SP_ROOT/txn \
        -logname rcon_tp \
        -c 500 500 \
        -nameservers localhost:33400 \
    > $LOGPATH/rcon_tp.$DATE.log &

