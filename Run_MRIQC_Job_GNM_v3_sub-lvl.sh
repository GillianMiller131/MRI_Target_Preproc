#!/bin/bash
#SBATCH --job-name=mriqc
#SBATCH --time=04:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2

subid=$1
sesid=$2
bids_dir=$3 
chain_off=$4


mkdir -p $SCRATCH/$USER

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

echo "${subid} MRIQC $timestamp"

log_files=(logs/${subid}_ses-*_progress.txt)

for log in "${log_files[@]}"; do
    echo "MRIQC Starting $timestamp" >> "$log"
done

exec > logs/mriqc_${subid}.out 2>&1

apptainer run \
  --cleanenv \
  --bind $bids_dir:/base \
  --bind $SCRATCH/$USER:/scratch \
  /home/dh1097/containers/mriqc_22.0.6.sif \
  /base \
  /base/derivatives/mriqc/${subid} \
  participant \
  --participant_label ${subid} \
  --n_procs 8 \
  --ants-nthreads 4 \
  --work-dir /scratch/mriqc_work/${subid}

apptainer_exit_code=$? 


timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

if [ "$apptainer_exit_code" -ne 0 ]; then
    echo "MRIQC failed. $timestamp" 
elif [ "$apptainer_exit_code" -eq 0 ]; then
    #Delete scratch
    if [ "$chain_off" == "True" ]; then
        echo "Chaining is disabled. Exiting script. $timestamp" 
    # else 
    #   echo "MRIQC finished. Running fMRIPrep. $timestamp" 
    #   bash Run_fMRIPrep_GNM_v3-sublvl.sh $subid $bids_dir # Keep here?
    fi
fi

for log in "${log_files[@]}"; do
    if [ "$apptainer_exit_code" -eq 0 ]; then
        echo "MRIQC finished. $timestamp" >> "$log"
    else
        echo "MRIQC failed. $timestamp" >> "$log"
    fi
done
fi

slurm_file=${bids_dir}/code/mriqc_slurm.txt
echo "$SLURM_JOB_ID" >> "$slurm_file"