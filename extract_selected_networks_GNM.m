function extract_selected_networks_GNM(parentDir, requested_networks, outputCSV, taskList)
% Scans all sessions under parentDir and extracts within- and between-network
% correlations for each task, saving results to a CSV.

    % Define the network names (must match NetNames in Net2Net)
    NetNames = {'Lateral_Visual', 'Primary_Visual', 'Dorsal_Motor', 'Ventral_Motor',...
        'Visual_Association', 'Dorsal_Attention', 'Cingulo_Opercular', 'Salience',...
        'Temporal_Lobe', 'Orbitofrontal', 'Precuneus_PCC_Posterior_DMN',...
        'FPCN_B', 'FPCN_A', 'Lateral_Temporal', 'Medial_Temporal', ...
        'DMN_Canonical', 'DMN_dorsal', 'Motor_hand'};
    
    NetMap = containers.Map(NetNames, 1:length(NetNames));
    
    % Find all sessions
    sessionDirs = dir(fullfile(parentDir, 'ses-*'));
    sessionDirs = sessionDirs([sessionDirs.isdir]);
    
    allRows = {};
    allData = [];
    
    % Predefine column names using full taskList
    colNames = {};
    for t = 1:length(taskList)
        colNames{end+1} = sprintf('%s_within_%s', taskList{t}, requested_networks{1});
        colNames{end+1} = sprintf('%s_within_%s', taskList{t}, requested_networks{2});
        colNames{end+1} = sprintf('%s_between_%s_%s', taskList{t}, requested_networks{1}, requested_networks{2});
    end
    
    % Loop over sessions
    for s = 1:length(sessionDirs)
        sessionName = sessionDirs(s).name;
        netDir = fullfile(parentDir, sessionName, 'ROI2ROIFC_Indi');
        files = dir(fullfile(netDir, '*_Net2Net_corr_z.mat'));
        
        % Loop over files
        for f = 1:length(files)
            matData = load(fullfile(files(f).folder, files(f).name));
            if ~isfield(matData, 'NetCorrMat_z')
                warning('File %s missing NetCorrMat_z, skipping.', files(f).name);
                continue;
            end
            NetCorrMat_z = matData.NetCorrMat_z;
            
            % Extract task name from filename
            fname = files(f).name;
            taskMatch = regexp(fname, '_task-(.*)_run-', 'tokens', 'once');
            if isempty(taskMatch)
                continue
            end
            taskName = taskMatch{1};
            
            % Skip if task not in predefined list
            if ~ismember(taskName, taskList)
                warning('Task %s not in predefined list, skipping.', taskName);
                continue;
            end
            
            % Initialize row if not already added
            subIDMatch = regexp(fname, 'sub-[^_]*', 'match', 'once');
            rowID = [subIDMatch '_' sessionName];
            rowIdx = find(strcmp(allRows, rowID));
            if isempty(rowIdx)
                allRows{end+1} = rowID;
                rowIdx = length(allRows);
                allData(rowIdx,1:length(colNames)) = NaN;
            end
            
            % Get indices for requested networks
            idx1 = NetMap(requested_networks{1});
            idx2 = NetMap(requested_networks{2});
            
            % Compute within/between
            within1 = NetCorrMat_z(idx1, idx1);
            within2 = NetCorrMat_z(idx2, idx2);
            between = NetCorrMat_z(idx1, idx2);
            
            % Find base index for this task
            col_base = (find(strcmp(taskList, taskName))-1)*3 + 1;
            allData(rowIdx, col_base)   = within1;
            allData(rowIdx, col_base+1) = within2;
            allData(rowIdx, col_base+2) = between;
        end
    end
    
    % Save as CSV
    T = array2table(allData, 'VariableNames', colNames, 'RowNames', allRows);
    writetable(T, outputCSV, 'WriteRowNames', true);
    fprintf('CSV saved to %s\n', outputCSV);
end
