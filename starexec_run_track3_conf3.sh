#!/bin/bash

file=$1
mc=`grep "^c t " $file`
echo "c o found header: $mc"

solfile=$(mktemp)
indfile=$(mktemp)
cleanfile=$(mktemp)
preprocessed_cnf_file=$(mktemp)
cleanfile2=$(mktemp)
tout_be=210
echo "c o solfile: $solfile  indfile: $indfile  cleanfile: $cleanfile preprocessed_cnf_file: $preprocessed_cnf_file"
echo "c o This script is for projected model counting track"


grep "c p show" $file | sed -E "s/c p show (.*)/c ind \1 0/" > $indfile
grep -v "^c" $file > $cleanfile2
cat $cleanfile2 $indfile > $cleanfile
grep -v "^c" $file > $cleanfile
echo "c o Running Arjun with timeout: ${tout_be}"
./doalarm ${tout_be} ./arjun --backbone 1 $cleanfile --elimtofile $preprocessed_cnf_file | sed "s/^/c o /"
found=`grep "^p cnf" $preprocessed_cnf_file`
if [[ $found == *"p cnf"* ]]; then
   echo "c o OK, Arjun succeeded"
   multi=`grep "^c MUST MUTIPLY BY" $preprocessed_cnf_file| sed "s/2\*\*//" | awk '{print $5}'`
else
   echo "c o WARNING Arjun did NOT succeed"
   cp $cleanfile $preprocessed_cnf_file
   multi=0
fi
echo "c c MULTI will be 2**$multi"
cache_size=25000

echo "c o Trying to run ganak, cache_size: ${cache_size} MB"
./ganak $preprocessed_cnf_file | tee $solfile | sed "s/^/c o /"
solved_by_ganak=`grep "^s .*SATISFIABLE" $solfile`
if [[ $solved_by_ganak == *"SATISFIABLE"* ]]; then
    sat=`grep "^s .*SATISFIABLE" $solfile`
    count=`grep "^c s exact arb int" $solfile | awk '{print $6}'`
    export BC_LINE_LENGTH=99999000000
    if [[ $count -eq "0" ]]; then
        log_10_count="-inf"
    else
        log_10_count=`echo "scale=15; l($count)/l(10)" | bc -l `
        count=`echo "$count*(2^$multi)" | bc -l`
    fi

    echo $sat
    echo "c s type mc"
    echo "c s log10-estimate $log_10_count"
    echo "c s exact arb int $count"
    exit 0
else
    echo "c o Ganak did NOT work"
    exit -1
fi
