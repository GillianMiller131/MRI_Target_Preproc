#!/bin/bash
#SBATCH --job-name=xcp_all
#SBATCH --time=03:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=8

subid=$1
sesid=$2
bids_dir=$3
chain_off=$4

bids_dir="${bids_dir%/}"


# DO NOT include 'module load apptainer'

XCPDIR=$bids_dir/derivatives/xcpOut_ALL
SCRATCHDIR=$SCRATCH/$USER/xcp_work/${subid}_${sesid}
COHORT=$XCPDIR/cohort_files/Control_all_cohort_${subid}_${sesid}.csv

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

echo "${subid} ${sesid} XCP-All $timestamp"

mkdir -p ${bids_dir}/code/logs/${subid}_${sesid}/

progress_file=${bids_dir}/code/logs/${subid}_${sesid}_progress.txt

echo "XCP-All Starting" >> $progress_file

if [ -d "$XCPDIR/${subid}/${sesid}" ] && [ "$(ls -A "$XCPDIR/${subid}/${sesid}")" ]; then
  echo "$XCPDIR/${subid}/${sesid} exists and is not empty. Exiting." >> $progress_file
  exit 1
fi


# Redirect stdout/stderr to logfile
exec > ${bids_dir}/code/logs/${subid}_${sesid}/xcp-all_${subid}_${sesid}.out 2>&1

mkdir -p ${bids_dir}/derivatives/xcpOut_ALL/cohort_files
mkdir -p $SCRATCHDIR

if [[ ! -f "$COHORT" ]]; then
    echo "Generating cohort file for ${subid}_${sesid}" 

    tasks='rest navonlow navonhigh aut'
    run='run-1'
    echo -e "id0,id1,study,run,img" > "$COHORT"

    for task in $tasks; do
        img="${bids_dir}/derivatives/fmriprep/${subid}/${sesid}/func/${subid}_${sesid}_task-${task}_${run}_space-T1w_desc-preproc_bold.nii.gz"
        
        if [ -f "$img" ]; then
            echo "$img exists. Adding to cohort file."            
            echo -e "${subid},${sesid},${task},${run},${img}" >> "$COHORT"
        else
            echo "$img does not exist."
        fi
    done

    # After loop: exit if file is empty or contains only the header
    if [ ! -s "$COHORT" ] || [ "$(wc -l < "$COHORT")" -le 1 ]; then
        echo "$COHORT is empty or contains only the header. Exiting."
        # rm -f "$COHORT"  
        exit 1
    fi
elif [ -s "$COHORT" ] || [ "$(wc -l < "$COHORT")" -gt 1 ]; then
    echo "$COHORT exists and is not empty. Using this file."
fi

apptainer run \
  --bind $XCPDIR:/data \
  --bind $SCRATCHDIR:/tmp \
  --bind /home/dh1097/GeorgetownTMSfMRI/xcpEngine:/git_repo \
  /home/dh1097/containers/xcpengine_1.2.3.sif \
  -c $COHORT \
  -d /git_repo/designs/fc-36p_despike.dsn \
  -o /data/ \
  -i /tmp/ \
  -r /data/

apptainer_exit_code=$? 

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

if [ "$apptainer_exit_code" -ne 0 ]; then
    echo "XCP-All  failed. $timestamp" >> "$progress_file"
    exit 1  
elif [ "$apptainer_exit_code" -eq 0 ]; then
    slurm_file=${bids_dir}/code/xcp-all_slurm.txt
    echo "$SLURM_JOB_ID" >> "$slurm_file"
    if [ "$chain_off" == "True" ]; then
        echo "Chaining is disabled. Exiting script. $timestamp" >> "$progress_file"
    else
        echo "XCP-All finished. Submitting Surface Projection $timestamp" >> "$progress_file"
        sbatch Run_surfaceProjection_Job_GNM.sh "$subid" "$sesid" "$bids_dir" 
    fi
fi

