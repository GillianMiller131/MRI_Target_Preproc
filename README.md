# MRI_Target_Preproc
This is a pipeline to preprocess MRI data for functional connectivity driven targeting (TMS, etc.) and analysis. The steps are as follows: 

1. Unzipping script *Not made*
2. HeuDiConv
3. fMRIPrep
4. XCP Engine
5. Surface Projection
6. Li Parcellation

Then: 
- For baseline/neuromodulation targeting: Surface and volume projection back to native space
- For analysis: Get Martched Li Parcellation ROIs and get functional connectivity scores 

### Extras - details at the bottom
- HeuDiConv at the session level
- MRIQC
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
 
Example cohort file:
id0,id1,id2,study,run,img
sub-TMS2010,ses-01,rest,rest,run-1,/home/cnglab/TMS_fMRI/bids_directory/derivatives/fmriprep/sub-TMS2010/ses-01/func/sub-TMS2010_ses-01_task-rest_run-1_space-T1w_desc-preproc_bold.nii.gz
sub-TMS2010,ses-01,navonlow,navonlow,run-1,/home/cnglab/TMS_fMRI/bids_directory/derivatives/fmriprep/sub-TMS2010/ses-01/func/sub-TMS2010_ses-01_task-navonlow_run-1_space-T1w_desc-preproc_bold.nii.gz
sub-TMS2010,ses-01,navonhigh,navonhigh,run-1,/home/cnglab/TMS_fMRI/bids_directory/derivatives/fmriprep/sub-TMS2010/ses-01/func/sub-TMS2010_ses-01_task-navonhigh_run-1_space-T1w_desc-preproc_bold.nii.gz
sub-TMS2010,ses-01,aut,aut,run-1,/home/cnglab/TMS_fMRI/bids_directory/derivatives/fmriprep/sub-TMS2010/ses-01/func/sub-TMS2010_ses-01_task-aut_run-1_space-T1w_desc-preproc_bold.nii.gz

**Data Preparation**:
- We run this on the func outputs of fMRIPrep, specifically ${subid}_${sesid}_task-${study}_${run}_space-T1w_desc-preproc_bold.nii.gz
- Cohort files are created by the script and put in derivatives/xcpOut_ALL/cohort_files
  
**Data Output**:
- Output is directed to derivatives/xcpOut_ALL

## Surface Projection
Projects preprocessed fMRI data onto each hemisphere's cortical surface using freesurfer command line tools

**Software Needs**:
- 

**Script Notes**:
- Registers the ses-01 rest scan to the participant's T1 from the Freesurfer directory (<Freesurfer SUBJECTS_DIR>/<subID>/mri/T1.mgz), then applies this registration/transform file to the other task scans (including other sessions)
  - This works because fMRIPrep registers all functional data to the same anatomical image, even if multiple are provided

**Data Preparation**:
- 

**Data Output**:
-  
- also the li directory 




**Software Needs**:
- 

**Script Notes**:
- 

**Data Preparation**:
- 
**Data Output**:
- 


