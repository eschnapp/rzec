#!/bin/bash

# Source the env file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"


# Stop jobs here
$SP_BIN_PATH/stop_rust_fh.sh > $LOGPATH/stop_rcon.log 2>&1 || true
$SP_BIN_PATH/stop_events.sh > $LOGPATH/stop_rcon.log 2>&1 || true
$SP_BIN_PATH/stop_users.sh > $LOGPATH/stop_rcon.log 2>&1 || true
$SP_BIN_PATH/stop_rcon.sh > $LOGPATH/stop_rcon.log 2>&1 || true
$SP_BIN_PATH/stop_servers.sh > $LOGPATH/stop_servers.log 2>&1 || true
$SP_BIN_PATH/stop_rz_service.sh > $LOGPATH/stop_sp_server.log 2>&1 || true
$SP_BIN_PATH/stop_rz_server.sh > $LOGPATH/stop_sp_server.log 2>&1 || true
