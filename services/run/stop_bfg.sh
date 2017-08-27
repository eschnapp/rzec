#!/bin/bash
set -e
# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo Will shutdown BFG service
kill -9 `ps -ef | grep -e "-svc_name BFG" | grep $SP_ROOT | awk '{print $2}'`
