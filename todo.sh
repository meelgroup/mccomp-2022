#!/bin/bash

rm -f Narsimha-track*.tar.gz

rm -rf bin
mkdir -p bin
cd bin
cp ../sharpSAT-td .
cp ../approxmc .
cp ../ganak .
cp ../arjun .
cp ../doalarm .
cp ../starexec*track1*.sh .
cp ../flow_cutter_pace17 .
cd ../
rm -f Narsimha.tar.gz
tar czvf Narsimha-track1.tar.gz bin

rm -rf bin
mkdir -p bin
cd bin
cp ../sharpSAT-td .
cp ../approxmc .
cp ../ganak .
cp ../arjun .
cp ../doalarm .
cp ../starexec*track3*.sh .
cp ../flow_cutter_pace17 .
cd ../
rm -f Narsimha.tar.gz
tar czvf Narsimha-track3.tar.gz bin
