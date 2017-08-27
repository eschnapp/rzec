#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_DIR/env.sh"
echo "Starting cleanup process..."

find $SP_ROOT/txn/ -type f -mtime +1 -exec rm {} \;
find $SP_ROOT/log/ -type f -mtime +1 -exec rm {} \;

echo "cleanup completed!"

