#!/bin/bash
#SBATCH --job-name=surface_projection
#SBATCH --time=1:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

set -e

# Load MATLAB
module load matlab

# Load Freesurfer
module load freesurfer

# Parse inputs
subID=$1
sesh=$2
bids_dir=$3

bids_dir="${bids_dir%/}"  

tasks='rest aut navonhigh navonlow'

OutDir=${bids_dir}/derivatives/surface_projection
xcpDir=${bids_dir}/derivatives/xcpOut_ALL
subDir=${bids_dir}/derivatives/fmriprep/sourcedata/freesurfer 
liDir=${bids_dir}/derivatives/surface_projection/copies_for_li2019
fwhm=12
matlabScriptPath=${bids_dir}/code
outputDir=${bids_dir}/derivatives/surface_projection
fmriprepDir=${bids_dir}/derivatives/fmriprep
run='run-1'

export SUBJECTS_DIR=${subDir}  # Set the Freesurfer directory for the subject

# Hemispheres
hemis=(lh rh)


# Navigate to the output directory for the subject/session

mkdir -p ${OutDir}/${subID}/${sesh}/surf

cd ${OutDir}/${subID}/${sesh} 



# Surface registration with bbregister (native BOLD to Freesurfer surface)
if [[ ! -f ${subDir}/${subID}/mri/register.dat ]]; then 
    bbregister --s ${subID} \
      --mov ${fmriprepDir}/${subID}/ses-01/func/${subID}_ses-01_task-rest_${run}_space-T1w_boldref.nii.gz \
      --reg ${subDir}/${subID}/mri/register.dat \
      --init-fsl --bold
else
    echo "Surface registration transform already exists"
fi


for task in ${tasks[@]}; do
  if [ ! -f ${fmriprepDir}/${subID}/${sesh}/func/${subID}_${sesh}_task-${task}_${run}_space-T1w_boldref.nii.gz ]; then
    echo "${fmriprepDir}/${subID}/${sesh}/func/${subID}_${sesh}_task-${task}_${run}_space-T1w_boldref.nii.gz Does Not Exist"
    continue
  fi
  
  

# Loop over hemispheres and perform surface projection and downsampling
  for hemi in ${hemis[@]}; do

    if [ -f ${liDir}/surf/${subID}/${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised_fsaverage6_sm6_fsaverage4.nii.gz ]; then
      echo "${liDir}/surf/${subID}/${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised_fsaverage6_sm6_fsaverage4.nii.gz already exists. Skipping"
      continue
    fi

      # Resample from native volume to native surface using mri_vol2surf
      echo "*** ${task} ${hemi} ***"
      echo "Resampling from native volume to native surface using mri_vol2surf"
      mri_vol2surf --mov ${xcpDir}/${subID}/${sesh}/${task}/regress/*residualised.nii.gz \
        --reg ${subDir}/${subID}/mri/register.dat \
        --hemi ${hemi} \
        --o ${OutDir}/${subID}/${sesh}/surf/${hemi}.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised.mgh \
        --projfrac 0.5 \
        --interp trilinear \
        --noreshape --surf-fwhm ${fwhm}

      # Downsample to fsaverage4 using mri_surf2surf (using ico)
      echo "Downsampling to fsaverage4 using mri_surf2surf"
      mri_surf2surf --srcsubject ${subID} \
        --srcsurfval ${OutDir}/${subID}/${sesh}/surf/${hemi}.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised.mgh \
        --trgsubject ico \
        --trgicoorder 4 \
        --trgsurfval ${OutDir}/${subID}/${sesh}/surf/${hemi}.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised.mgh \
        --hemi ${hemi}

      # MATLAB function to reshape the surface data matrix 
      echo "Reshaping the surface data matrix"               
      matlab -nodisplay -nojvm \
        -r "addpath('${matlabScriptPath}'); \
        squeezeFuncSurfHPC('${OutDir}/${subID}/${sesh}/surf/${hemi}.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised.mgh', \
        '${OutDir}/${subID}/${sesh}/surf/${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised.mgh', \
        '${FREESURFER_HOME}'); exit"

      # Convert the surface projection file to NIfTI format using mri_convert
      echo "Converting the surface projection file to NIfTI format"
      cd ${OutDir}/${subID}/${sesh}/surf/
      mri_convert ${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised.mgh \
      ${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised_fsaverage6_sm6_fsaverage4.nii.gz

      # Copy the NIfTI file to the output directory
      mkdir -p ${liDir}/${sesh}/${subID}/surf
      echo "Copying ${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised_fsaverage6_sm6_fsaverage4.nii.gz to ${liDir}/${sesh}/${subID}/surf"
      scp ${hemi}.squeezed.fs4.sm${fwhm}.${subID}_${sesh}_task-${task}_${run}_residualised_fsaverage6_sm6_fsaverage4.nii.gz ${liDir}/${sesh}/${subID}/surf/
  done
done
