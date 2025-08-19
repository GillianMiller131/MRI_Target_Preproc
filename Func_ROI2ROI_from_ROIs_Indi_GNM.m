function [] = Func_ROI2ROI_from_ROIs_Indi_GNM(ROIPath,DataPath,OutPath,SubIDs)

%% Create output folder
mkdir([OutPath '/ROI2ROIFC_Indi']);

%% Load template patch info
load([ROIPath '/GrpTemplate_Matched_ROIs/AllSelected_Patches_lh.mat']);
PatchNum_lh = AllSelected_Patches;
load([ROIPath '/GrpTemplate_Matched_ROIs/AllSelected_Patches_rh.mat']);
PatchNum_rh = AllSelected_Patches;

%% Create ROI-to-network mapping vector
ROI_to_Net = [];
for n = 1:length(PatchNum_lh)
    ROI_to_Net = [ROI_to_Net, repmat(n, 1, PatchNum_lh(n))];
end
for n = 1:length(PatchNum_rh)
    ROI_to_Net = [ROI_to_Net, repmat(n, 1, PatchNum_rh(n))];
end

TotalPatches = length(ROI_to_Net);

%% Load individual ROI patches for all subjects
All_ROI_Ind_Big = cell(length(SubIDs),1);

for s = 1:length(SubIDs)
    sub = SubIDs{s};
    k = 0;
    ROI_ind_Big = cell(TotalPatches,1);
    
    for n = 1:18
        % Left hemisphere
        PatchNum = PatchNum_lh(n);
        for i = 1:PatchNum
            k = k+1;
            fname = sprintf('%s/Indi_Matched_ROIs/Net_%d/%s/Net_%d_ROIs_%d_lh.mgh', ROIPath, n+1, sub, n+1, i);
            if exist(fname, 'file')
                Patch = load_mgh(fname);
                ROI_ind_Big{k} = find(Patch>0);
            else
                ROI_ind_Big{k} = [];
            end
        end
        
        % Right hemisphere
        PatchNum = PatchNum_rh(n);
        for i = 1:PatchNum
            k = k+1;
            fname = sprintf('%s/Indi_Matched_ROIs/Net_%d/%s/Net_%d_ROIs_%d_rh.mgh', ROIPath, n+1, sub, n+1, i);
            if exist(fname, 'file')
                Patch = load_mgh(fname);
                ROI_ind_Big{k} = 2562 + find(Patch>0);  % offset for right hemisphere
            else
                ROI_ind_Big{k} = [];
            end
        end
    end
    All_ROI_Ind_Big{s} = ROI_ind_Big;
end

%% Loop over subjects
for s = 1:length(SubIDs)
    sub = SubIDs{s};
    fprintf('Calculating ROI2ROI and Net2Net FC for subject %d: %s\n', s, sub);
    
    SelectedSubIndex = All_ROI_Ind_Big{s};
    
    % Get all *_fs4.mat files for this subject
    files = dir(fullfile(DataPath, sprintf('%s_*_fs4.mat', sub)));
    
    for f = 1:length(files)
        matFile = fullfile(files(f).folder, files(f).name);
        fprintf('Processing file: %s\n', files(f).name);
        
        matData = load(matFile);
        if isfield(matData, 'lhData') && isfield(matData, 'rhData')
            data = [matData.lhData; matData.rhData];
        elseif isfield(matData, 'lh_task') && isfield(matData, 'rh_task')
            data = [matData.lh_task; matData.rh_task];
        else
            warning('File %s has unexpected variables. Skipping.', files(f).name);
            continue
        end
        
        %% Compute ROI time series
        ROIs_sig = zeros(size(data,2), TotalPatches);
        for i = 1:TotalPatches
            ind = SelectedSubIndex{i};
            if ~isempty(ind)
                ROIs_sig(:,i) = nanmean(data(ind,:),1);
            end
        end
        
        %% ROI2ROI correlation
        CorrMat = corrcoef(ROIs_sig);
        CorrMat(isnan(CorrMat)) = 0;
        [~, baseName] = fileparts(files(f).name);
        save(fullfile(OutPath, 'ROI2ROIFC_Indi', sprintf('%s_corr.mat', baseName)), 'CorrMat');
        CorrMat_z = atanh(CorrMat);
        CorrMat_z(isnan(CorrMat_z)) = 0; CorrMat_z(isinf(CorrMat_z)) = 0;
        save(fullfile(OutPath, 'ROI2ROIFC_Indi', sprintf('%s_corr_z.mat', baseName)), 'CorrMat_z');
        
        %% Net2Net correlation
        numNets = 18;
        NetCorrMat = zeros(numNets,numNets);
        for n = 1:numNets
            roi_indices = find(ROI_to_Net == n);
            for m = 1:numNets
                roi_indices2 = find(ROI_to_Net == m);
                if isempty(roi_indices) || isempty(roi_indices2)
                    continue
                end
                NetCorrMat(n,m) = mean(mean(CorrMat(roi_indices, roi_indices2)));
            end
        end
        
        NetCorrMat_z = atanh(NetCorrMat);
        NetCorrMat_z(isnan(NetCorrMat_z)) = 0; NetCorrMat_z(isinf(NetCorrMat_z)) = 0;
        
        save(fullfile(OutPath, 'ROI2ROIFC_Indi', sprintf('%s_Net2Net_corr.mat', baseName)), 'NetCorrMat');
        save(fullfile(OutPath, 'ROI2ROIFC_Indi', sprintf('%s_Net2Net_corr_z.mat', baseName)), 'NetCorrMat_z');
    end
end

fprintf('ROI2ROI and Net2Net FC calculation completed for all subjects.\n');

NetNames = {'Lateral_Visual', 'Primary_Visual', 'Dorsal_Motor', 'Ventral_Motor',...
    'Visual_Association', 'Dorsal_Attention', 'Cingulo_Opercular', 'Salience',...
    'Temporal_Lobe', 'Orbitofrontal', 'Precuneus_PCC_Posterior_DMN',...
    'FPCN_B', 'FPCN_A', 'Lateral_Temporal', 'Medial_Temporal', ...
    'DMN_Canonical', 'DMN_dorsal', 'Motor_hand'};

filename = fullfile(OutPath, 'ROI2ROIFC_Indi','Net2Net_corr_Network-Names.mat');

    if ~(exist(filename, 'file') == 2)
        save(filename, 'NetCorrMat', 'NetNames');
    end

end
