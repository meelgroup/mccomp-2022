#!/bin/bash

file=$1
mc=`grep "^c t " $file`
echo "c o found header: $mc"

solfile=$(mktemp)
cleancnffile=$(mktemp)
indfile=$(mktemp)
cleanfile=$(mktemp)
preprocessed_cnf_file=$(mktemp)
echo "c o solfile: $solfile  indfile: $indfile  cleanfile: $cleanfile cleancnffile: $cleancnffile preprocessed_cnf_file: $preprocessed_cnf_file"

timeout_value=$(( STAREXEC_WALLCLOCK_LIMIT ))
tout_be=110

echo "c o This script is for regular model counting track"
grep -v "^c" $file > $cleanfile
echo "c o Running Arjun with timeout: ${tout_be}"
./doalarm ${tout_be} ./arjun $cleanfile --elimtofile $preprocessed_cnf_file
found=`grep "^p cnf" $preprocessed_cnf_file`
if [[ $found == *"p cnf"* ]]; then
   echo "c o OK, Arjun succeeded"
   grep -v "^c" $preprocessed_cnf_file > $cleancnffile
   multi=`grep "^c MUST MUTIPLY BY" $preprocessed_cnf_file| awk '{print $5}'`
else
   echo "c o WARNING Arjun did NOT succeed"
   grep -v "^c" $file > $cleancnffile
   multi=1
fi
cache_size=$(( STAREXEC_MAX_MEM/2 ))
echo "c o Trying to run Ganak, cache_size: ${cache_size}"
./ganak -cs ${cache_size} $cleancnffile > $solfile
solved_by_ganak=`grep "^s .*SATISFIABLE" $solfile`
if [[ $solved_by_ganak == *"SATISFIABLE"* ]]; then
    sed -E "s/^(.)/c o \1/" $solfile
    sat=`grep "^s .*SATISFIABLE" $solfile`
    count=`grep "^s .*mc" $solfile | awk '{print $3}'`
    count=`echo "$count*$multi" | bc -l`
    log_10_count=`echo "scale=15; l($count)/l(10)" | bc -l `

    echo $sat
    echo "c s type mc"
    echo "c s log10-estimate $log_10_count"
    echo "c s exact arb int $count"
    exit 0
else
    echo "c o Ganak did NOT work"
    exit -1
fi
