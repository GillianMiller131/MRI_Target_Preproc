while read -r subid; do
    [[ -z "$subid" ]] && continue  # skip empty lines
    echo "Processing $subid"
    sbatch Box_to_HPC.sh $subid
done < priority_subjects.txt


for i in TMS*; do 
    for j in `ls ${i}`; do 
        unzip ${j}/*zip -d ${i}
    done
done

unzip TMS2003/2023-10-24/TMS2003_2023_10_24.zip -d TMS2003/

source_dir=/home/cnglab/TMS_fMRI/bids_directory/sourcedata
#need a header for csv
for i in ${source_dir}/TMS20*; do
    sub=$(basename "$i" | cut -d _ -f1)
    count=1
    for sesdir in "$i"/TMS20*_20*; do
        if [ -d "$sesdir" ]; then
            ses=$(printf "ses-%02d" "$count")
            echo "${sub},${ses},$(basename "$sesdir")" >> ${source_dir}/scan_inventory.csv
            # mv $sesdir ${source_dir}/${sub}/sub-${sub}_${ses}
            ((count++))
        fi
    done
done
