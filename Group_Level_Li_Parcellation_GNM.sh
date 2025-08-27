#!/bin/bash
#SBATCH --job-name=li_parcellation
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4


bids_dir=$1
bids_dir="${bids_dir%/}"  

# Define base paths
li_dir=$bids_dir/derivatives/li_parcellation 
HFRDIR=$bids_dir/code/HFR_ai_li
sessions='ses-01 ses-02 ses-03'


# Load MATLAB module
module load matlab
module load freesurfer

# Run MATLAB-based Li parcellation script
cd $HFRDIR

# when all subjects have run, calculate ROIs present in at least 90% of subjects based on ses-01
# Then apply thse patches to get ROI2ROI (and Network2Network connectivity?)

for sesid in ${sessions[@]}; do

    #Create Patches
    if [ $sesid = "ses-01" ]; then 
        if [ -s "$li_dir/subjects_patches.txt" ]; then
            echo "$li_dir/subjects_patches.txt exists and is not empty. Using this list."
        else
            echo "$li_dir/subjects_patches.txt does not exist or is empty. Creating subject list based on subjects found in $bids_dir/derivatives/li_parcellation/ses-01/DiscretePatches"
            ls $li_dir/ses-01/DiscretePatches > $li_dir/subjects_patches.txt
        fi

        input_dir=$li_dir/ses-01
        out_dir=$li_dir
        matlab -batch "HFR_ai_noGUI_GNM('$input_dir', '$out_dir', '$li_dir/subjects_patches.txt', 'create_group_patches');"
    fi

    if [ "$(find "$li_dir/MatchRate0.9/Indi_Matched_ROIs/" -mindepth 1 -print -quit 2>/dev/null)" ] && [ "$(find "$li_dir/MatchRate0.9/GrpTemplate_Matched_ROIs/" -mindepth 1 -print -quit 2>/dev/null)" ]; then

    # Apply Patches 
        if [ -s "$li_dir/subjects_$sesid.txt" ]; then
            echo "$li_dir/subjects_$sesid.txt exists and is not empty. Using this list."
        elif [ -d "$li_dir/$sesid/OrganizedData" ] && [ "$(ls -A "$li_dir/$sesid/OrganizedData")" ]; then
            echo "$li_dir/subjects_$sesid.txt does not exist or is empty. Creating subject list based on subjects found in $li_dir/$sesid/OrganizedData"
            ls $li_dir/$sesid/OrganizedData | cut -d'_' -f1 | sort | uniq > $li_dir/subjects_$sesid.txt
        else
            echo "No subjects found in $li_dir/$sesid/OrganizedData!"
            continue
        fi


        echo "Applying patches to $sesid"
        input_dir=$li_dir
        out_dir=$li_dir/$sesid
        matlab -batch "HFR_ai_noGUI_GNM('$input_dir', '$out_dir', '$li_dir/subjects_$sesid.txt', 'apply_group_patches');" 

    else
        echo "$li_dir/MatchRate0.9/Indi_Matched_ROIs and/or $li_dir/MatchRate0.9/GrpTemplate_Matched_ROIs is empty. Exiting script."
        exit
    fi
done
