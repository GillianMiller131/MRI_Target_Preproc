# MRI_Target_Preproc
This is a pipeline to preprocess MRI data for functional connectivity driven targeting (TMS, etc.) and analysis. The steps are as follows: 

1. HeuDiConv
2. MRIQC?
3. fMRIPrep
4. XCP de-spiking(?)
5. Surface Projection
6. Li Parcellation
7. Surface and volume projection back to native space

*Also the slurm resource script!!!!*

## Overall Notes
- These scripts expect a BIDs formatted directory, including folders such as code, derivatives, and sourcedata. The root or base directory of this will be referred to as the "bids directory" or "bids dir".
- Scripts generally output to 3 logs files within the code directory:
  1. The SLURM output file, usually slurm_<jobid>.out
     - Should contain the name of the job and time of submission 
  2. The logs/<subid>_<sesid>_progress.txt file
     - Notes when a job starts, ends, or fails
  3. The logs/<step-name>_<subid>_<sesid>.out (e.g. logs/heudiconv_sub-TMS032_ses-03.out)
     - The output of the actual commands being run
     - Look here for error messages about the commands run in the script

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
- 

**Script Notes**:
- 

**Data Preparation**:
- 
**Data Output**:
- 


**Software Needs**:
- 

**Script Notes**:
- 

**Data Preparation**:
- 
**Data Output**:
- 


