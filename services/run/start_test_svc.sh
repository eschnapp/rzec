#! /bin/bash
# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"
echo "Starting Process..."
$SP_ROOT/services/run/boot_core.sh \
         -target $SP_ROOT/framework/service.q \
        -start \
        -config_data_dir $SP_ROOT/config \
        -zone $ZONE \
        -svc_name TEST_SVC \
        -sp_server SP_SERVER \
        -c 500 500 \
        -nameservers localhost:23400 \
#    > $LOGPATH/test_tp.$DATE.log &

