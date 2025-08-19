#!/bin/bash
#SBATCH --job-name=li_parcellation
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4


bids_dir=$1
bids_dir="${bids_dir%/}"  

# Define base paths
li_dir=$bids_dir/derivatives/li_parcellation 


# Load MATLAB module
module load matlab
module load freesurfer
  

# Define requested networks
requested_networks=("DMN_dorsal" "FPCN_B")

# Define task list
taskList=("rest" "aut" "navonhigh" "navonlow")

# Output CSV path
outputCSV="${li_dir}/${requested_networks[0]}_${requested_networks[1]}_connectivity.csv"

mat_requested_networks="{'${requested_networks[0]}','${requested_networks[1]}'}"
mat_taskList="{'${taskList[0]}','${taskList[1]}','${taskList[2]}','${taskList[3]}'}"

matlab -batch "extract_selected_networks_GNM('$li_dir', '$mat_requested_networks', '$outputCSV','$mat_taskList');


