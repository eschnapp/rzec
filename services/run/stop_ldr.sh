#!/bin/bash
set -e

# Source the common file
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"

echo Will shutdown SP_LOADER service
kill -9 `ps -ef | grep -e "-svc_name SP_LOADER" | grep $SP_ROOT | awk '{print $2}'`


