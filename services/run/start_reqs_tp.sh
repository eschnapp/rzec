#! /bin/bash
echo "Sourcing Environemnt..."
source $SP_ROOT/services/run/env.sh

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
	-target $SP_ROOT/framework/tpsvc.q \
	-start \
	-config_data_dir $SP_ROOT/config \
	-zone $ZONE \
	-svc_name REQUESTS_TP \
	-sp_server SP_SERVER \
	-schemafile reqs_schema.q \
	-logdir $SP_ROOT/txn \
	-logname requests_tp \
	-nameservers localhost:23400 \
	-c 500 500 \
	> $LOGPATH/requests_tp.$DATE.log &
