#!/bin/bash
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


# Load MATLAB module
module load matlab
module load freesurfer
  
# Run MATLAB-based Li parcellation script
cd $HFRDIR

if [ "$sesid" = "ses-01" ]; then
    #get time series file + patches
    matlab -batch "HFR_ai_noGUI_GNM('$surf_dir', '$out_dir', '$subid', 'individual_parcellation');"
    if [ $? -eq 0 ]; then
        sbatch Run_net2nat.sh
    else
        echo "Li parcellation script failed; not resampling to native space"
fi
else 
    #get timeseries file only
    matlab -batch "HFR_ai_noGUI_GNM('$surf_dir', '$out_dir', '$subid', 'individual_timeseries');"
fi
