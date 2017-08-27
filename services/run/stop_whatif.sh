#!/bin/bash
set -e

# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

# Will shut down SP Server
echo Will shutdown WHATIF  service
kill -9 `ps -ef | grep -e "-svc_name WHATIF" | grep $SP_ROOT | awk '{print $2}'`


