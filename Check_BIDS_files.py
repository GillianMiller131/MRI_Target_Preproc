import os
import pandas as pd

# Set your BIDS directory
bids_dir = "/home/cnglab/TMS_fMRI/bids_directory"

# Define the types of files to check
modalities = {
    "T1w": "anat/*_T1w.nii*",
    "task-aut": "func/*task-aut*_bold.nii*",
    "task-navon high": "func/*task-navonhigh*_bold.nii*",
    "task-navonlow": "func/*task-navonlow*_bold.nii*",
    "task-rest": "func/*task-rest*_bold.nii*",
    "fmap AP": "fmap/*dir-AP*_epi.nii*",
    "fmap PA": "fmap/*dir-PA*_epi.nii*",
    "mag1": "fmap/*magnitude1.nii*",
    "mag2": "fmap/*magnitude2.nii*",
    "phasediff": "fmap/*phasediff.nii*",
}

# Initialize list for CSV rows
rows = []

# Traverse BIDS directory
for subj in sorted(os.listdir(bids_dir)):
    if not subj.startswith("sub-"):
        continue
    subj_path = os.path.join(bids_dir, subj)
    for ses in sorted(os.listdir(subj_path)):
        if not ses.startswith("ses-"):
            continue
        ses_path = os.path.join(subj_path, ses)

        row = {"subject": subj, "session": ses}

        for modality, pattern in modalities.items():
            full_path = os.path.join(ses_path, pattern)
            matches = list(sorted(os.path.expanduser(p) for p in 
                        os.popen(f"ls {full_path} 2>/dev/null").read().splitlines()))
            row[modality] = "Y" if matches else "N"

        rows.append(row)

# Convert to DataFrame
df = pd.DataFrame(rows)

# Save to CSV
df.to_csv("bids_inventory.csv", index=False)

print("Inventory saved to bids_inventory.csv")
