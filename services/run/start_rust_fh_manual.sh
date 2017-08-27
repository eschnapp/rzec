#! /bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo "Starting Process..."

$SP_ROOT/services/run/boot_core.sh \
	-target $SP_ROOT/services/rust_fh.q  \
	-start \
	-config_data_dir $SP_ROOT/config \
	-zone $ZONE \
	-svc_name RUST_FH  \
        -log_level debug \
	-nameservers localhost:33400 \
	-sp_server RZ_SERVER  \

