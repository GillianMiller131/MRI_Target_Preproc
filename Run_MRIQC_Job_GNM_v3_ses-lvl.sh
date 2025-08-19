#!/bin/bash
#SBATCH --job-name=mriqc
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2

subid=$1
sesid=$2
bids_dir=$3 
chain_off=$4

mkdir -p logs/${subid}_${sesid}/
mkdir -p $SCRATCH/$USER

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

echo "${subid} ${sesid} MRIQC $timestamp"

progress_file=logs/${subid}_${sesid}_progress.txt
echo "MRIQC Starting $timestamp" >> $progress_file          

exec > logs/${subid}_${sesid}/mriqc_${subid}_${sesid}.out 2>&1

apptainer run \
  --cleanenv \
  --bind $bids_dir:/base \
  --bind $SCRATCH/$USER:/scratch \
  /home/dh1097/containers/mriqc_22.0.6.sif \
  /base \
  /base/derivatives/MRIQC/${subid}/${sesid} \
  participant \
  --participant_label ${subid} \
  --session-id ${sesid} \
  --n_procs 8 \
  --ants-nthreads 4 \
  --work-dir /scratch/mriqc_work/${subid}/${sesid}

apptainer_exit_code=$? 


timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

if [ "$apptainer_exit_code" -ne 0 ]; then
    echo "MRIQC failed. $timestamp" >> "$progress_file"
    exit 1 
elif [ "$apptainer_exit_code" -eq 0 ]; then
    if [ "$chain_off" == "True" ]; then
        echo "Chaining is disabled. Exiting script. $timestamp" >> "$progress_file"
    else 
        if [ "${sesid}" == 'ses-03' ]; then #do something better here 
          echo "MRIQC finished. Running fMRIPrep. $timestamp" >> $progress_file 
          bash Run_fMRIPrep_GNM_v3.sh $subid $bids_dir 
        else
          echo "MRIQC finished. fMRIPrep should run after ses-03. $timestamp" >> $progress_file
        fi
    fi
fi

echo "Job resource usage summary:" >> "$progress_file"
sacct -j $SLURM_JOB_ID --format=JobID,Elapsed,MaxRSS,TotalCPU,State >> "$progress_file"
