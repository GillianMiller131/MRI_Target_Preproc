#!/bin/bash

input_file=$1 #txt file with SLURM job ID numbers

for i in `cat ${input_file}`; do
        sacct -j $i --format=JobID,Elapsed,MaxRSS,TotalCPU,State
done
