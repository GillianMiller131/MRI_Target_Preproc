#!/usr/bin/env bash
#SBATCH --job-name=resample_net2nat        # Job name
#SBATCH --time=2:00:00                    # Time limit hrs:min:sec
#SBATCH --mem=16G                          # Memory per node
#SBATCH --cpus-per-task=1                 # Number of cores to use

# This script takes the output of the Li 2019 individual parcellation
# and resamples + smooths the network confidence maps to native space.
#The resamples them from surf to vol 

# Parse inputs
sub=$1
sesid=$2
bids_dir="${3%/}"  

inDir=${bids_dir}/derivatives/li_parcellation/${sesid}
iter=10
dil=2
sm1=6
sm2=6


# Set FreeSurfer variables
subDir=${bids_dir}/derivatives/fmriprep/sourcedata/freesurfer 
export SUBJECTS_DIR=${subDir}

timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

echo "${subid} ${sesid} resample2native $timestamp"

mkdir -p ${bids_dir}/code/logs/${subid}_${sesid}/

progress_file=${bids_dir}/code/logs/${subid}_${sesid}_progress.txt

echo "resample2native Starting" >> $progress_file

exec > ${bids_dir}/code/logs/${subid}_${sesid}/resample2native_${subid}_${sesid}.out 2>&1

module load matlab
module load freesurfer

# Do NOT copy fsaverage4 — should be in fMRIPrep output


# Get list of masks and confidence maps
masks=$(find ${inDir}/IndiPar/${sub}/Iter_${iter} -iname '*Network_*.mgh')
confMaps=$(find ${inDir}/IndiPar/${sub}/Iter_${iter} -iname '*NetworkConfidence_*.mgh')

echo
echo "--------------------------------------------"
echo "-- START: resampling labels of subject ${sub} --"
echo "--------------------------------------------"
echo

# Create native directory if missing
mkdir -p ${inDir}/IndiPar/${sub}/native
cd ${inDir}/IndiPar/${sub}/native

# Loop over masks
for mask in ${masks}; do
  netMaskName=$(basename ${mask} .mgh)
  hemi=$(echo ${mask} | grep -Eo '[lr]h')

  echo
  echo "--------------------------------------------"
  echo "-- START: processing label ${mask} ${hemi}--"
  echo "--------------------------------------------"
  echo

  mri_surf2surf --srcsubject fsaverage4 \
    --srcsurfval ${mask} \
    --trgsubject ${sub} \
    --trgsurfval ${inDir}/IndiPar/${sub}/native/${netMaskName}_native.mgh \
    --hemi ${hemi} \
    --cortex

  mri_cor2label --i ./${netMaskName}_native.mgh \
    --id 1 \
    --l ./${netMaskName}_native.label \
    --surf ${sub} ${hemi} white

  mri_label2label --srclabel ./${netMaskName}_native.label \
    --s ${sub} \
    --hemi ${hemi} \
    --dilate ${dil} \
    --trglabel ${inDir}/IndiPar/${sub}/native/${netMaskName}_native_dil${dil}.label \
    --regmethod surface

  echo
  echo "--------------------------------------------"
  echo "-- FINISH: processing label ${mask} --"
  echo "--------------------------------------------"
  echo
done

# Loop over confidence maps
for net in ${confMaps}; do
  hemi=$(echo ${net} | grep -Eo '[lr]h')
  netMapName=$(basename ${net} .mgh)
  netNum=$(echo ${netMapName} | grep -Eo '[[:digit:]]{1,2}')

  label1=${inDir}/IndiPar/${sub}/native/Network_${netNum}_${hemi}_native.label
  label2=${inDir}/IndiPar/${sub}/native/Network_${netNum}_${hemi}_native_dil${dil}.label

  echo
  echo "Finished loop for ${netMapName}"
  echo "Resampling and smoothing confidence maps..."
  echo

  # Smoothing step 1 (within label)
  mri_surf2surf --srcsubject fsaverage4 \
    --srcsurfval ${net} \
    --trgsubject ${sub} \
    --trgsurfval ${netMapName}_native_sm${sm1}.mgh \
    --fwhm-trg ${sm1} \
    --hemi ${hemi} \
    --label-trg ${label1}

  echo
  echo "SMOOTHING STEP 2"
  echo

  # Smoothing step 2 (global, dilated)
  mri_surf2surf --srcsubject ${sub} \
    --srcsurfval ${netMapName}_native_sm${sm1}.mgh \
    --trgsubject ${sub} \
    --trgsurfval ${netMapName}_native_sm${sm1}_sm${sm2}dil${dil}.mgh \
    --fwhm-trg ${sm2} \
    --hemi ${hemi} \
    --label-trg ${label2}


    echo 
    echo
    echo ------------------------------------------------------
    echo -- START: resampling network ${netMapName} to volume --
    echo ------------------------------------------------------
    echo

    # If multiple T1ws, it may be preferable to use rawavg.mgz 
    mri_surf2vol --surfval ${netMapName}_native_sm${sm1}_sm${sm2}dil${dil}.mgh \
    --hemi ${hemi}  \
    --fillribbon \
    --subject ${sub} \
    --identity ${sub} \
    --template ${SUBJECTS_DIR}/${sub}/mri/orig.mgz \
    --o ${netMapName}_native_vol.nii.gz

    echo
    echo ------------------------------------------------------
    echo -- FINISH: resampling network ${netMapName} to volume --
    echo ------------------------------------------------------
    echo

    if [ -f "Network_${netNum}_lh_native_vol.nii.gz" ] && [ -f "Network_${netNum}_lh_native_vol.nii.gz" ]; then
      mri_concat \
      Network_${netNum}_lh_native_vol.nii.gz \
      Network_${netNum}_rh_native_vol.nii.gz \
      --o ${sub}_${netName}_lhrh_vol.nii.gz
    fi

done

exit_code=$?
timestamp=$(date +"%Y-%m-%d %H:%M:%S") 

if [ "$exit_code" -ne 0 ]; then
    echo "resample2native failed. $timestamp" >> "$progress_file"
    exit 1  
elif [ "$exit_code" -eq 0 ]; then
    slurm_file=${bids_dir}/code/resample2native_slurm.txt
    echo "$SLURM_JOB_ID" >> "$slurm_file"
    echo "resample2native finished. $timestamp" >> "$progress_file"
    echo "Find your vol files in ${inDir}/IndiPar/${sub}/native"
    bash net_numbers.sh
    fi
fi

