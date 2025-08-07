#!/bin/bash
#SBATCH --job-name=heudiconv
#SBATCH --time=01:30:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1

subid=$1
sesid=$2
bids_dir=$3 
chain_off=$4 

bids_dir="${bids_dir%/}"


# example usage: sbatch Run_Heurdiconv_Job_GNM.sh sub-TMS2005 ses-01 /home/cnglab/TMS_fMRI/bids_directory 
# if you don't want it to automatically start MRIQC: sbatch Run_Heurdiconv_Job_GNM.sh sub-TMS2005 ses-01 /home/cnglab/TMS_fMRI/bids_directory True

subnum=${subid:4}
sesnum=${sesid:4}

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

echo "${subid} ${sesid} HeuDiConv $timestamp"

mkdir -p ${bids_dir}/code/logs/${subid}_${sesid}/

progress_file=${bids_dir}/code/logs/${subid}_${sesid}_progress.txt

echo "HeuDiConv Starting" >> $progress_file

if [ -d "${bids_dir}/${subid}/${sesid}" ] && [ "$(ls -A "$bids_dir/${subid}/${sesid}")" ]; then
  echo "BIDS directory exists and is not empty for $subid $sesid. Skipping." >> $progress_file
  exit
fi

# Redirect stdout/stderr to logfile
exec > ${bids_dir}/code/logs/${subid}_${sesid}/heudiconv_${subid}_${sesid}.out 2>&1

dcm_path="${bids_dir}/sourcedata/${subid}/${sesid}/" 

# Check if any DICOM files exist
if ! ls $dcm_path/*.dcm 1> /dev/null 2>&1; then
  echo "$dcm_path is empty. Exiting script." >> $progress_file
  exit 42
fi

apptainer run \
  --bind $bids_dir:/base \
  /home/dh1097/containers/heudiconv_0.12.2.sif \
  -d /base/sourcedata/sub-{subject}/ses-{session}/*.dcm \
  -o /base \
  -f /base/code/heuristic_final.py \
  -s $subnum -ss $sesnum \
  -c dcm2niix -b --overwrite

apptainer_exit_code=$? 

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

if [ "$apptainer_exit_code" -ne 0 ]; then
    echo "Heudiconv failed. $timestamp" >> "$progress_file"
    exit 1  
elif [ "$apptainer_exit_code" -eq 0 ]; then
  slurm_file=${bids_dir}/code/heudiconv_slurm.txt
  echo "$SLURM_JOB_ID" >> "$slurm_file"
    if [ "$chain_off" == "True" ]; then
        echo "Chaining is disabled. Exiting script. $timestamp" >> "$progress_file"
    else
        echo "Heudiconv finished. Submitting fMRIPrep. $timestamp" >> "$progress_file"
        #sbatch Run_fMRIPrep_Job_GNM_v3_ses-lvl.sh "$subid" "$bids_dir" 
    fi
fi

