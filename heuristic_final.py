#!/usr/bin/env python
import os
import re

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes

# Struct
t1w = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_T1w')

# rest
rest = create_key(
    'sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_run-1_bold')

# Navon_task_low

navon_low = create_key(
    'sub-{subject}/{session}/func/sub-{subject}_{session}_task-navonlow_run-1_bold')

# Navon_task_high

navon_high = create_key(
    'sub-{subject}/{session}/func/sub-{subject}_{session}_task-navonhigh_run-1_bold')

# AUT_task

aut = create_key(
    'sub-{subject}/{session}/func/sub-{subject}_{session}_task-aut_run-1_bold')



    # field maps

fmap_run1_ph = create_key(
   'sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_run-1_phasediff')

fmap_run1_mag = create_key(
   'sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_run-1_magnitude')

fmap_SE_AP = create_key(
   'sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_dir-AP_run-1_epi')

fmap_SE_PA = create_key(
   'sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_dir-PA_run-1_epi')

def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where
    allowed template fields - follow python string module:
    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    session: session id
    """

    last_run = len(seqinfo)

    info = {
    # baseline
    t1w: [],
    # field map
    fmap_run1_ph: [], fmap_run1_mag: [], fmap_SE_AP: [], fmap_SE_PA:[],
    #bold scans
    rest: [], navon_low: [], navon_high: [], aut: [],
    }

    def get_latest_series(key, s):
        if len(info[key]) == 0:
            info[key].append(s.series_id)
        else:
            info[key] = [s.series_id]

    for s in seqinfo:
        protocol = s.protocol_name.lower()

        fileCount = s.total_files_till_now

        # Baseline Anatomicals

        if "t1w_mpr" in protocol:
            get_latest_series(t1w, s)

        #Resting task scans (Need to change according to timepoint (date))
        elif "rest" in protocol:
            get_latest_series(rest, s)
            #info[rest1].append(s.series_id)

        #Navon Low task scan
        elif "navonlow" in protocol:
            get_latest_series(navon_low, s)

        #Navon High task scan
        elif "navonhigh" in protocol:
            get_latest_series(navon_high, s)

    #AUT task scan      
        elif "aut" in protocol:
            get_latest_series(aut, s)


        #B0 maps
        elif "b0map" in protocol and "b0map_unfiltered" not in protocol and "M" in s.image_type:
            get_latest_series(fmap_run1_mag, s)
        elif "b0map" in protocol and "b0map_unfiltered" not in protocol and "P" in s.image_type:
            get_latest_series(fmap_run1_ph, s)

        elif "se_fieldmap_ap" in protocol:
           get_latest_series(fmap_SE_AP, s)

        elif "se_fieldmap_pa" in protocol:
           get_latest_series(fmap_SE_PA, s)

        else:
            print("Series not recognized!: ", s.protocol_name, s.dcm_dir_name)
    return info

MetadataExtras = {

   fmap_run1_ph: {
       "EchoTime1": 0.00412,
       "EchoTime2": 0.00658
   },
   fmap_SE_AP: {
       "PhaseEncodingDirection": "j-",
       "TotalReadoutTime": 0.032
   },
   fmap_SE_PA: {
       "PhaseEncodingDirection": "j",
       "TotalReadoutTime": 0.032
   },
}

#R>>L phase encoding direction
#From scanner protocol, Echo spacing = 0.50ms, EPI factor = 64
#Total readout time = Echo spacing x 0.001 x (EPI factor-1)

IntendedFor = {
   fmap_run1_ph: [
       '{session}/func/sub-{subject}_{session}_task-rest-run-1_bold.nii.gz'
   ],

   fmap_run1_mag: [
       '{session}/func/sub-{subject}_{session}_task-rest-run-1_bold.nii.gz'
   ],

   fmap_SE_AP: [
       '{session}/func/sub-{subject}_{session}_task-navonlow_run-1_bold.nii.gz',
       '{session}/func/sub-{subject}_{session}_task-navonhigh_run-1_bold.nii.gz',
       '{session}/func/sub-{subject}_{session}_task-aut_run-1_bold.nii.gz'
   ],

   fmap_SE_PA: [
       '{session}/func/sub-{subject}_{session}_task-navonlow_run-1_bold.nii.gz',
       '{session}/func/sub-{subject}_{session}_task-navonhigh_run-1_bold.nii.gz',
       '{session}/func/sub-{subject}_{session}_task-aut_run-1_bold.nii.gz'
   ],

}
# Function to swap out the '_' in the subIDs as they are uploaded.
def ReplaceSubject(subj_label):
    p = re.compile('-')
    return str(p.sub("", subj_label))


##Add back in once fieldmaps are collected
POPULATE_INTENDED_FOR_OPTS = {
       'matching_parameters': ['ModalityAcquisitionLabel'],
       'criterion': 'First'
}
