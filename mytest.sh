#!/usr/bin/bash

export STAREXEC_MAX_MEM=1000
# set in MB

file=$1
filename=$(basename "$file")
cp "$1" "./$filename"

./starexec_run_track1_conf1.sh $filename
