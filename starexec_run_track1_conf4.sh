#!/bin/bash

file=$1
mc=`grep "^c t " $file`
echo "c o found header: $mc"

cache_size=3500
echo "c o This script is for regular model counting"
./sharpSAT-td -decot 120 -decow 100 -tmpdir . -cs ${cache_size} $1

