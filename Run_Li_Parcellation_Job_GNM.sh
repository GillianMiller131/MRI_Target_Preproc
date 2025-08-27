a#!/bin/bash
#SBATCH --job-name=li_parcellation
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

subid=$1
sesid=$2
bids_dir=$3
bids_dir="${bids_dir%/}"  

# Define base paths
surf_dir=$bids_dir/derivatives/surface_projection/copies_for_li2019/${sesid} 
HFRDIR=$bids_dir/code/HFR_ai_li
out_dir=$bids_dir/derivatives/li_parcellation/${sesid}

mkdir -p $out_dir

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

echo "${subid} ${sesid} Li Parcellation $timestamp"

mkdir -p ${bids_dir}/code/logs/${subid}_${sesid}/

progress_file=${bids_dir}/code/logs/${subid}_${sesid}_progress.txt

echo "Starting Li Parcellation" >> $progress_file

exec > ${bids_dir}/code/logs/${subid}_${sesid}/li_parc_${subid}_${sesid}.out 2>&1

# Load MATLAB module
module load matlab
module load freesurfer
  
# Run MATLAB-based Li parcellation script
cd $HFRDIR

if [ "$sesid" = "ses-01" ]; then
    #get time series file + patches
    matlab -batch "HFR_ai_noGUI_GNM('$surf_dir', '$out_dir', '$subid', 'individual_parcellation');"

    timestamp=$(date +"%Y-%m-%d %H:%M:%S") 
    
    if [ $? -eq 0 ]; then
      echo "Li Parcellation finished $timestamp" >> $progress_file
      slurm_file=${bids_dir}/code/li-parc_indv-parc_slurm.txt
      echo "$SLURM_JOB_ID" >> "$slurm_file"
      if [ -d "$out_dir/IndiPar/${subid}/native" ] && [ "$(ls -A "$out_dir/IndiPar/${subid}/native}")" ]; then
        echo "$out_dir/IndiPar/${subid}/native exists and is not empty. Skipping resampling to native." >> $progress_file
      else
        cd $bids_dir/code
        sbatch Run_resample2native_GNM.sh ${subid} ${sesid} ${bids_dir}
    else
        echo "Li parcellation script failed; not resampling to native space. $timestamp"
    fi
else 
    #get timeseries file only
    matlab -batch "HFR_ai_noGUI_GNM('$surf_dir', '$out_dir', '$subid', 'individual_timeseries');"
    slurm_file=${bids_dir}/code/li-parc_indv-time_slurm.txt
    echo "$SLURM_JOB_ID" >> "$slurm_file"
    if [ $? -eq 0 ]; then
      echo "Li Parcellation finished. $timestamp" >> $progress_file
    else
      echo "Li Parcellation failed. $timestamp" >> $progress_file
fi
