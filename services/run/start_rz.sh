#!/bin/bash
set -e

# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

#remove users and samples txn log files since RT gets loaded from HIST
# rm /sp/txn/users_tp*.log&
# rm /sp/txn/samples_tp*.log&

# start the jobs now
echo "Starting discovery server..."
nohup $SP_BIN_PATH/start_rz_server.sh > $LOGPATH/start_rz_server.log 2>&1 &
sleep 1s

# start all TPs
echo "Starting Tickerplants..."
nohup $SP_BIN_PATH/start_servers_tp.sh > $LOGPATH/start_servers_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_rcon_tp.sh > $LOGPATH/start_rcon_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_users_tp.sh > $LOGPATH/start_users_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_events_tp.sh > $LOGPATH/start_events_tp.log 2>&1 &

sleep 5s
echo "Starting HDBs...."
nohup $SP_BIN_PATH/start_servers_hist.sh > $LOGPATH/start_servers_hist.log 2>&1 &
nohup $SP_BIN_PATH/start_rcon_hist.sh > $LOGPATH/start_rcon_hist.log 2>&1 &
nohup $SP_BIN_PATH/start_users_hist.sh > $LOGPATH/start_users_hist.log 2>&1 &
nohup $SP_BIN_PATH/start_events_hist.sh > $LOGPATH/start_events_hist.log 2>&1 &

sleep 5s
echo "Starting RT Services..."
#start all RT svcs
nohup $SP_BIN_PATH/start_servers_rt.sh > $LOGPATH/start_servers_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_rcon_rt.sh > $LOGPATH/start_rcon_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_users_rt.sh > $LOGPATH/start_users_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_events_rt.sh > $LOGPATH/start_events_rt.log 2>&1 &

sleep 3s
echo "Sarting all APP servers..."
# start all other svcs now
nohup $SP_BIN_PATH/start_rust_fh.sh > $LOGPATH/start_rust_fh.log 2>&1 &
 
