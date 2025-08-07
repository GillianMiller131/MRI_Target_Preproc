#!/bin/bash
#SBATCH --job-name=fmriprep
#SBATCH --time=24:00:00
#SBATCH --mem=50G
#SBATCH --cpus-per-task=12
#SBATCH --output=logs/slurm_%j.out
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=gm1157@georgetown.edu

module load freesurfer/7.4.1

subid=$1
bids_dir=$2
chain_off=$3


subnum=${subid:4}

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 
log_files=(logs/${subid}_ses-*_progress.txt)

for log in "${log_files[@]}"; do
    echo "Starting fMRIPrep. $timestamp" >> "$log"
done

exec > logs/fmriprep_${subid}.out 2>&1
exec 3>&1 4>&2  # Save SLURM output

# Set base paths

BIDSDIR=$bids_dir

OUTDIR=$BIDSDIR/derivatives/fmriprep/
WORKDIR=$SCRATCH/$USER/fMRIPrep_scratch/${subid} 

FS_LICENSE_DIR=/home/dh1097/fs_license
export FS_LICENSE=$FS_LICENSE_DIR/license.txt

# Create output and work directories if they don't exist
mkdir -p $OUTDIR
mkdir -p $WORKDIR

apptainer run \
--cleanenv \
--bind $BIDSDIR:/data \
--bind $OUTDIR:/out \
--bind $WORKDIR:/scratch \
--bind $FS_LICENSE_DIR:/usr/local/freesurfer \
/home/dh1097/containers/fmriprep_21.0.2.sif \
/data /out participant \
--participant_label $subnum \
--fs-license-file /usr/local/freesurfer/license.txt \
--fs-subjects-dir /data/derivatives/freesurfer \
--output-spaces fsaverage T1w MNI152NLin6Asym MNI152NLin2009cAsym \
--cifti-output 91k \
--nthreads 12 \
--omp-nthreads 4 \
--mem_mb 50000 \
--work-dir /scratch \
--resource-monitor

apptainer_exit_code=$? 
timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

exec 1>&3 2>&4

if [ "$apptainer_exit_code" -eq 0 ]; then
    rm -rf $WORKDIR 
    slurm_file=${BIDSDIR}/code/fmriprep_slurm.txt
    echo "$SLURM_JOB_ID" >> "$slurm_file"
    echo "fMRIPrep finished. $timestamp" 
else
    echo "fMRIPrep failed. $timestamp" 
fi


for log in "${log_files[@]}"; do
    if [ "$apptainer_exit_code" -eq 0 ]; then
        echo "fMRIPrep finished. $timestamp" >> "$log"
    else
        echo "fMRIPrep failed. $timestamp" >> "$log"
    fi
done
fi





