#!/bin/bash
set -e

# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

# Will shut down SP Server
echo Will shutdown USERS_TP/RT services
kill -9 `ps -ef | grep -e "-svc_name USERS_" | grep $SP_ROOT | awk '{print $2}'`


