# MRI_Target_Preproc
This is a pipeline to preprocess MRI data for functional connectivity driven targeting (TMS, etc.) and analysis. The steps are as follows: 

1. HeuDiConv
2. MRIQC?
3. fMRIPrep
4. XCP de-spiking(?)
5. Surface Projection
6. Li Parcellation
7. Surfacne and volume projection back to native space

These scripts expect a BIDs formatted directory, including folders such as code, derivatives, and sourcedata. The root or base directory of this will be referred to as the "bids directory" or "bids dir". 

## HeuDiConv - Run_Heudiconv_Job_GNM.sh
Heuristic Dicom Conversion creates a BIDs dataset from DICOMs. 

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
-Data will be output into the bids directory as a subject folder containing anat, func, and fmap folders (depenging on which scans you have)

