# MRI_Target_Preproc
This is a pipeline to preprocess MRI data for functional connectivity driven targeting (TMS, etc.) and analysis. The steps are as follows: 

1. Unzipping script *Not made*
2. HeuDiConv
3. fMRIPrep
4. XCP Engine
5. Surface Projection
6. Li Parcellation

Then: 
- For baseline/neuromodulation targeting: Surface and volume projection back to native space (1 script)
- For analysis: Get group matched ROIs then extract network-level functional connectivity scores for networks of interest (2 scripts)

### Extra Scripts - details at the bottom
- File check - recommended to run before fMRIPrep (right now called find_files.py)
- example batch submission script
- HeuDiConv at the session level
- MRIQC at the session and subject level
- Slurm Resource checking script


## Overall Notes
- These scripts expect a BIDs formatted directory, including folders such as code, derivatives, and sourcedata. The root or base directory of this will be referred to as the "bids directory" or "bids dir".
- Scripts generally output to 3 logs files within the code directory:
  1. The SLURM output file, usually slurm_<jobid>.out
     - Contains the name of the job and time of submission 
  2. The logs/<subid>_<sesid>_progress.txt file
     - Notes when a job starts, ends, or fails
  3. The logs/<step-name>_<subid>_<sesid>.out (e.g. logs/heudiconv_sub-TMS032_ses-03.out)
     - The output of the actual commands being run
     - Look here for error messages about the commands run in the script
- Scratch: if containers ask for working directories, folders are created in $SCRATCH/$USER and deleted if the job runs successfully
  - If the job fails, you may want to delete this manually depending on the error


## HeuDiConv - Run_Heudiconv_Job_GNM.sh
Heuristic Dicom Conversion creates a BIDs dataset from DICOMs. 
See: https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/heudiconv.html#introduction

**Software Needs**:
- heudiconv_0.12.2.sif
- heuristic_final.py

**Script Notes**:
- The container runs at the session level, the script runs at the subject level by looping through session folders found in sourcedata
- Flags/options:
- - chaining, run fmriprep, run mriqc, etc. ## Need to do this still 

**Data Preparation**:
- Data for this will be almost directly from the scanner, but you will likely need to do some unzipping/untaring and renaming/moving files around
- The script expects to find the dicoms in: bids_dir/sourcedata/subid/sesid (sesid should be in form ses-0 or ses-00, etc.)

**Data Output**:
- Data will be output into the bids directory as a subject folder containing anat, func, and fmap folders (depenging on which scans you have)

## MRIQC - Run_MRIQC_Job_GNM.sh
Calculates Image Quality Metrics for structural and functional scans. 
See: https://mriqc.readthedocs.io/en/latest/about.html

**Software Needs**:
- mriqc_22.0.6.sif

**Script Notes**:
- MRIQC runs at the subject level; to run at the session add the `--session-id` flag. 

**Data Preparation**:
- MRIQC runs on BIDs formatted directories, run HeuDiConv or similar first and give MRIQC the bids dir and subject id. 

**Data Output**:
- Output is directed to derivatives/mriqc
- Shoud look like?????
- scratch is located at $SCRATCH/$USER/mriqc_work

## fMRIPRep - Run_fMRIPrep
Preprocesses anatomical and functional scans
See: https://fmriprep.org/en/stable/index.html
This guy takes a while!

**Software Needs**:
- Singularity or docker container, e.g. fmriprep_21.0.2.sif
- freesurfer/license.txt

**Script Notes**:
- fMRIPrep runs at the subject level, running it at the session level is not recommended and there is no flag for this 
- fMRIPrep should run distortion correction with fieldmaps if they are in the bids directory; you can also use the `--use-syn-sdc` if you don't have fmaps or there is an issue with them
- If you have 2 T1w scans within or across sessions of a subject, it will combine them. If you have 1 it will use that one, if you have 3 or more it will use the first T1w.(See:[Longitudinal processing](https://fmriprep.org/en/stable/workflows.html#longitudinal-processing:~:text=the%20_roi%20suffix.-,Longitudinal%20processing,%EF%83%81,-In%20the%20case))
- The `--fs-subjects-dir` flag should prevent fMRIPrep from re-running recon-all if that output already exisits (say from a previous session's fMRIPrep or from running recon-all manually), which should save time when running sessions 2 and 3
  - You can also take advantage of this if you would like to select your T1w, you can run recon-all on your selected T1w and fMRIPrep will use it - particularly helpful if a few of your subjects have 2 T1w or if someone has a very low quality T1w. (example command: ` recon-all -s sub-01 -i sub-01_ses-01_T1w.nii.gz -all`)

**Data Preparation**:
- fMRIPrep runs on BIDs formatted directories, run HeuDiConv or similar first and give fMRIPrep the bids dir and subject id.
  
**Data Output**:
- Output is directed to derivatives/fmriprep

## XCP Engine - Run_XCP
Processing wrapper for various pieplines specified by the pipeline design file. 
The design file here is a pipeline for processing fMRI data, including denoising, filtering, smoothing, connectivity analysis, regional metrics extraction, normalization, and quality control.
See: https://xcpengine.readthedocs.io/#

**Software Needs**:
- A container image, e.g. xcpengine_1.2.3.sif
- a design file, e.g. fc-36p_despike.dsn (See: https://github.com/PennLINC/xcpEngine/tree/master/designs for other options)

**Script Notes**:
- So this one is a bit weird, you have to give it a ["cohort file"](https://xcpengine.readthedocs.io/config/cohort.html), which is just a csv file with some identification columns and a path to the nifti image
  - If you're using SLURM, you want a bunch of these so you can run the jobs in parallel.
  - You may also what multiple if you are want to use different design files per task etc.
  - Here, we use the same design file for all tasks, so the script is set up to create one csv per a subject/session combo that contains all their fMRI scans from that session - this seems to be more resource efficient than having one job per scan
 
Example cohort file: Control_all_cohort_sub-TMS2010_ses-01.csv

**Data Preparation**:
- Run this on the func outputs of fMRIPrep, specifically `${subid}_${sesid}_task-${study}_${run}_space-T1w_desc-preproc_bold.nii.gz`
- Cohort files are created by the script and put in derivatives/xcpOut_ALL/cohort_files
  
**Data Output**:
- Output is directed to derivatives/xcpOut_ALL

## Surface Projection - Run_surfaceProjection_GNM.sh
Projects preprocessed fMRI data onto each hemisphere's cortical surface using freesurfer command line tools

**Software Needs**:
- MATLAB
- Freesurfer
- Matlab script: squeezeFuncSurfHPC
  - put in ${bids_dir}/code

**Script Notes**:
- Registers the ses-01 rest scan to the participant's T1 from the Freesurfer directory (<Freesurfer SUBJECTS_DIR>/<subID>/mri/T1.mgz), then applies this registration/transform file to the other task scans (including other sessions)
  - This works because fMRIPrep registers all functional data to the same anatomical image, even if multiple are provided

**Data Preparation**:
- This script will look for:
  - The output of XCP, specifically ${xcpDir}/${subID}/${sesh}/${task}/regress/*residualised.nii.gz
  - The output of fMRIPrep, specifically ${fmriprepDir}/${subID}/${sesh}/func/${subID}_${sesh}_task-${task}_${run}_space-T1w_boldref.nii.gz
  - The output of recon-all (i.e. fMRIPrep), specifically ${subDir}/${subID}/mri/register.dat with subDir being the Freesurfer subject directory 

**Data Output**:
- Output is directed to derivatives/surface_projection
- Will also copy filed to session folder in the $liDir (e.g., derivatives/surface_projection/copies_for_li2019) which will be used in the next step

## Li Parcellation - Run_Li_Parcellation_Job_GNM.sh 
Uses each subject's fMRI data to create subject specific ROIs and matches them to the Yeo 17 networks 

**Software Needs**:
- [HFR_ai_li](https://nmr.mgh.harvard.edu/bid/DownLoad.html#:~:text=Wang%20D%20et%20al.2015%3A%20Parcellating%20Cortical%20Functional%20Networks%20in%20Individuals.%20Nat.%20Neurosci.)
- Copy HFR_ai_noGUI_GNM.m to HFR_ai_li folder
- Copy Func_ROI2ROI_from_ROIs_Indi_GNM.m and Func_FS4_Data_Read_GNM.m to HFR_ai_li/Subfunctions

**Script Notes**:

### Subject Level: There are 2 options at the subject level
1. individual_parcellation: use for **baseline session**; takes all the fMRI tasks in order to do the subject specific parcellation to create ROIs for targeting and analysis; will also create a time series file containing all tasks together (sub_timeframes_fs4.mat) as well as separated ones for each task (sub_taskName_FS4.mat)
2. individual_timeseries: Use for ses-02 and on (individual_parcellation will create these for the baseline); creates timeseries files for all tasks together (sub_timeframes_fs4.mat) as well as separated ones for each task (sub_taskName_FS4.mat)

**Data Preparation**:
- This pipeline is not set up for subjects with multiple sessions, so subject input and outputs are in grouped by session (i.e., session folders have subject folders), instead of each subject folder having all 3 sessions

**Data Output**:
- Example output folder path: derivatives/li_parcellation/ses-02/
- individual_parcellation folders: DiscretePatches  IndiPar  MatchMatrix  OrganizedData 
- individual_timeseries folders: OrganizedData

### Group Level: There are 2 options at the group level
  1. create_group_patches: This identifies ROIs that at least 90% of subjects have based on all baseline fMRI scans (can change this % by changing MatchRate in HFR_al_noGUI_GNM.m); run this on DiscretePatches, one of the outputs of individual_parcellation.  
  2. apply_group_patches: This applies the previously identified 90% ROIs to task timeseries files from all sessions (can change this % by changing MatchRate in HFR_al_noGUI_GNM.m) to extract ROI-ROI and network-network connectivity matrices; run this on OrganizedData.
 
**Data Preparation**:
- This should be run after you have run all your subjects through the subject level li parcellation

**Data Output**:
- Output will be derivatives/li_parcellation/MatchRate0.9
- Output for will be correlation matrices in ROI2ROIFC_Atlas and ROI2ROIFC_Indi; Net2Net the diagonal is within network connectivity

## For neuromodulation targeting - Run_resample2native_GNM.sh
This script resamples each subject's individual network parcellations to native space, then converts them from surface files to volumes to allow for viewing in Brainsight or similar softwares

**Script Notes**:
- The network numbers start at 2, so you need to take the network number that is 1 greater than the corresponding Yeo network number (e.g. Network 12 - FPCNb - would be the files with Network 13 and Network 17 - DMN dorsal - would be Network 18 files. 

**Software Needs**:
- Freesurfer

**Data Preparation**:
- This script needs the output of recon-all for the current subject as well as fsaverage4 (both should come out of the fMRIPrep script)
- This script runs on the Network and Network Confidence files from the 10th iteration, found in derivatives/li_parcellation/<session id>/IndiPar/<subject id>/Iter_10

**Data Output**:
- derivatives/li_parcellation/<session id>/IndiPar/<subject id>/native

## For data analysis - Run_Network_Connectivity_Summary_GNM.sh 
This script extracts the within and between network connectivity values for 2 selected networks for each fMRI scan (i.e. there are separate connectivity values for each task type) of the selected sessions

**Script Notes**:
- Given network names should be from this list, note this is the list in order that can be used to identify the network numbers for the native space volumes:
      - NetNames = {'Lateral_Visual', 'Primary_Visual', 'Dorsal_Motor', 'Ventral_Motor',...
        'Visual_Association', 'Dorsal_Attention', 'Cingulo_Opercular', 'Salience',...
        'Temporal_Lobe', 'Orbitofrontal', 'Precuneus_PCC_Posterior_DMN',...
        'FPCN_B', 'FPCN_A', 'Lateral_Temporal', 'Medial_Temporal', ...
        'DMN_Canonical', 'DMN_dorsal', 'Motor_hand'};

**Software Needs**:
- extract_selected_networks_GNM.m in <BIDs dir>/code
- MATLAB

**Data Preparation**:
- This script finds all of the Net2Net_corr_z.mat files in derivatives/li_parcellation/<session id>/ROI2ROIFC_Indi 

**Data Output**:
- A csv file in derivatives/li_parcellation named <sleected network 1>_<selected network 2>_connectivity.csv
