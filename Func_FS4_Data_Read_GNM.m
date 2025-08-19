function [] = Func_FS4_Data_Read_GNM(InPath,OutPath,SubIDs)

% Preprocessed files should be projected on fsaverage4
mkdir([OutPath '/OrganizedData']);


for s = 1:length(SubIDs)
     sub = SubIDs{s}; 
     fprintf(['Reading data ' num2str(s) ':' sub '\n']);
     lhData = [];
     rhData = [];

     Files_LH = dir([InPath '/' sub '/surf/lh.*_fsaverage6_sm6_fsaverage4.nii.gz']);
     Files_RH = dir([InPath '/' sub '/surf/rh.*_fsaverage6_sm6_fsaverage4.nii.gz']);

   col_offset = 0;
   for i = 1:length(Files_LH)

        filename_bold_lh = [Files_LH(i).name];
        filename_bold_rh = [Files_RH(i).name];
        
        
        fullfilename_bold_lh = [InPath '/'  sub '/surf/' filename_bold_lh];
        fullfilename_bold_rh = [InPath '/' sub '/surf/' filename_bold_rh];

        lh_hdr = MRIread(fullfilename_bold_lh);
        %keyboard
        % NOTE: This line assumes a particular data-shape - commented out
        % by JPZ 10/8/2019 because our data has already been reshaped
        %lhData_tmp = reshape(lh_hdr.vol,[size(lh_hdr.vol,1)*size(lh_hdr.vol,2)*size(lh_hdr.vol,3), size(lh_hdr.vol,4)]);
        lhData_tmp = transpose(squeeze(lh_hdr.vol)); % JPZ added squeeze for ADHD data 1/17/2020
        
        rh_hdr = MRIread(fullfilename_bold_rh);  
        % NOTE: This line assumes a particular data-shape - commented out
        % by JPZ 10/8/2019 because our data has already been reshaped
        %rhData_tmp = reshape(rh_hdr.vol,[size(rh_hdr.vol,1)*size(rh_hdr.vol,2)*size(rh_hdr.vol,3), size(rh_hdr.vol,4)]);
        rhData_tmp = transpose(squeeze(rh_hdr.vol)); % JPZ added squeeze for ADHD data 1/17/2020
       
        lhData = [lhData lhData_tmp]; % JPZ 10/8/2019 - switched to account for commented out lines
        rhData = [rhData rhData_tmp]; % JPZ 10/8/2019 - switched to account for commented out lines  

        % Record which columns belong to this task
        nCols = size(lhData_tmp, 2);
        clean_name = regexpi(filename_bold_lh, 'task-[^_]+_run-\d+', 'match', 'once'); % e.g., 'task-aut_run-1'
        task_info(i).taskname = clean_name;   % or strip extensions if you want cleaner names
        task_info(i).col_start = col_offset + 1;
        task_info(i).col_end = col_offset + nCols;

     col_offset = col_offset + nCols;   
   end

   save([OutPath '/OrganizedData/' sub '_timeframes_fs4.mat'],'lhData','rhData', 'task_info');

   % Now create & save separate files per task
   for i = 1:length(task_info)
     cols = task_info(i).col_start : task_info(i).col_end;
    
     lh_task = lhData(:, cols);
     rh_task = rhData(:, cols);
    
     % Create a clean filename for the task mat file
     task_mat_name = fullfile(OutPath, 'OrganizedData', ...
        sprintf('%s_%s_fs4.mat', sub, task_info(i).taskname));
    
     % Save the separate task data
     save(task_mat_name, 'lh_task', 'rh_task');
   end
end
