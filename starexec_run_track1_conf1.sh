#!/bin/bash

file=$1
echo "c o Regular track"

solfile=$(mktemp)
cleanfile=$(mktemp)
cache_size=25000
tout_ganak=1200

grep -v "^c" $file > $cleanfile

./doalarm ${tout_ganak} ./ganak -cs ${cache_size} -t ${tout_ganak} $cleanfile > $solfile
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
    ./approxmc --ignore 1 --epsilon 0.9 $1 | tee $solfile | sed "s/^/c o /"
    solved_by_approxmc=`grep "^s .*SATISFIABLE" $solfile`
    if [[ $solved_by_approxmc == *"SATISFIABLE"* ]]; then
        sat=`grep "^s .*SATISFIABLE" $solfile`
        count=`grep "^s .*mc" $solfile | awk '{print $3}'`
        export BC_LINE_LENGTH=99999000000
        if [[ $count -eq "0" ]]; then
            log_10_count="-inf"
        else
            log_10_count=`echo "scale=15; l($count)/l(10)" | bc -l `
        fi
    
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
