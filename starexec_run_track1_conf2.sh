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

timeout_value=$(( STAREXEC_WALLCLOCK_LIMIT-10 ))
tout_ganak=$(( timeout_value/3 ))
tout_be=110
SECONDS=0

echo "c o This script is for regular model counting"
grep -v "^c" $file > $cleanfile
echo "c o Running B+E with timeout: ${tout_be}"
./doalarm ${tout_be} ./B+E_linux -cpu-lim=${tout_be} $cleanfile > $preprocessed_cnf_file
found=`grep "^p cnf" $preprocessed_cnf_file`
if [[ $found == *"p cnf"* ]]; then
   echo "c o OK, B+E succeeded"
   grep -v "^c" $preprocessed_cnf_file > $cleancnffile
else
   echo "c o WARNING B+E did NOT succeed"
   grep -v "^c" $file > $cleancnffile
fi
tout_ganak=$(( tout_ganak-SECONDS ))
cache_size=$(( STAREXEC_MAX_MEM/2 ))
echo "c o Trying to run Ganak, timeout: ${tout_ganak}, cache_size: ${cache_size}"
./doalarm ${tout_ganak} ./ganak -cs ${cache_size} -t ${tout_ganak} $cleancnffile > $solfile
solved_by_ganak=`grep "^s .*SATISFIABLE" $solfile`
if [[ $solved_by_ganak == *"SATISFIABLE"* ]]; then
    sed -E "s/^(.)/c o \1/" $solfile
    sat=`grep "^s .*SATISFIABLE" $solfile`
    count=`grep "^s .*mc" $solfile | awk '{print $3}'`
    log_10_count=`echo "scale=15; l($count)/l(10)" | bc -l `

    echo $sat
    echo "c s type mc"
    echo "c s log10-estimate $log_10_count"
    echo "c s exact arb int $count"
    exit 0
else
    echo "c o Ganak did NOT work"
    tout_exact_mc=$(( 2*timeout_value/3-SECONDS ))
    total_mem_gb=$(( STAREXEC_MAX_MEM/1024-1 ))
    echo "c o Trying to run ExactMC, timeout: ${tout_exact_mc}, memo: ${total_mem_gb}"
    ./doalarm ${tout_exact_mc} ./ExactMC --memo ${total_mem_gb} $cleancnffile > $solfile
    solved_by_exactmc=`grep "^c s exact" $solfile`
    if [[ $solved_by_exactmc == *"c s exact"* ]]; then
        cat $solfile
        exit 0
    else
        echo "c o ExactMC did not work"
    fi
    tout_approxmc=$(( timeout_value-SECONDS ))
    echo "c o Trying to run ApproxMC, timeout: ${tout_approxmc}"
    ./doalarm  ${tout_approxmc} ./approxmc --epsilon 0.2 $cleancnffile > $solfile
    solved_by_approxmc=`grep "^s .*SATISFIABLE" $solfile`
    if [[ $solved_by_approxmc == *"SATISFIABLE"* ]]; then
        sed -E "s/^(.)/c o \1/" $solfile
        sat=`grep "^s .*SATISFIABLE" $solfile`
        count=`grep "^s .*mc" $solfile | awk '{print $3}'`
        log_10_count=`echo "scale=15; l($count)/l(10)" | bc -l `

        echo $sat
        echo "c s type mc"
        echo "c s log10-estimate $log_10_count"
        echo "c s approx arb int $count"
        exit 0
    else
        echo "c o ApproxMC did NOT work"
        exit -1
    fi
fi
