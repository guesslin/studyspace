#!/bin/bash
if [ -z $1 ]; then
echo "usage: $0 <dir_name>"
exit;
fi
dir=$1
mkdir -p $dir
env_file="$dir/env_info.txt"
touch $env_file
