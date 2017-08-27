#!/bin/bash
set -e

# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

#remove all txn logs for whatif process
find $SP_ROOT/txn/ -type f -exec rm {} \;

# start the jobs now
nohup $SP_BIN_PATH/start_sp_server.sh > $LOGPATH/start_sp_server.log 2>&1 &
sleep 5s

# start all TPs
nohup $SP_BIN_PATH/start_samples_tp.sh > $LOGPATH/start_samples_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_users_tp.sh > $LOGPATH/start_users_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_reqs_tp.sh > $LOGPATH/start_reqs_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_model_results_tp.sh > $LOGPATH/start_model_results_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_logs_tp.sh > $LOGPATH/start_logs_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_features_tp.sh > $LOGPATH/start_features_tp.log 2>&1 &
nohup $SP_BIN_PATH/start_trx_tp.sh > $LOGPATH/start_trx_tp.log 2>&1 &

sleep 5s

sleep 5s
#start all RT svcs
nohup $SP_BIN_PATH/start_samples_rt.sh > $LOGPATH/start_samples_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_users_rt.sh > $LOGPATH/start_users_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_reqs_rt.sh > $LOGPATH/start_reqs_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_model_results_rt.sh > $LOGPATH/start_model_results_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_logs_rt.sh > $LOGPATH/start_logs_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_features_rt.sh > $LOGPATH/start_features_rt.log 2>&1 &
nohup $SP_BIN_PATH/start_trx_rt.sh > $LOGPATH/start_trx_rt.log 2>&1 &  

sleep 1s
# start all other svcs now
nohup $SP_BIN_PATH/start_admin_svc.sh > $LOGPATH/start_admin_svc.log 2>&1 &
#nohup $SP_BIN_PATH/start_auth_svc.sh > $LOGPATH/start_auth_svc.log 2>&1 &
nohup $SP_BIN_PATH/start_samples_fh.sh > $LOGPATH/start_samples_fh.log 2>&1 &
#nohup $SP_BIN_PATH/start_sp_view.sh > $LOGPATH/start_sp_view.log 2>&1 &
nohup $SP_BIN_PATH/start_fex.sh > $LOGPATH/start_fex.log 2>&1 &

sleep 10s
nohup $SP_BIN_PATH/start_whatif.sh > $LOGPATH/start_whatif.log 2>&1 &
nohup $SP_BIN_PATH/start_bfg.sh > $LOGPATH/start_bfg.log 2>&1 &


#nohup $SP_BIN_PATH/start_sp_view.sh > $LOGPATH/start_sp_view.log 2>&1 &
#nohup $SP_BIN_PATH/start_appengine_proxy.sh > $LOGPATH/start_appengine_proxy.log 2>&1 &
#nohup $SP_BIN_PATH/start_gae_proxy_public.sh > $LOGPATH/start_gae_proxy_public.log 2>&1 &
#nohup $SP_BIN_PATH/start_gae_proxy_admin.sh > $LOGPATH/start_gae_proxy_admin.log 2>&1 &
#nohup $SP_BIN_PATH/start_gae_proxy_mobile.sh > $LOGPATH/start_gae_proxy_mobile.log 2>&1 &
#nohup $SP_BIN_PATH/start_ldr.sh > $LOGPATH/start_ldr.log 2>&1 &
