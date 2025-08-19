% This script should be placed under the HFR_ai_li directory and allows us to run the Li parcellation without using the GUI.


function HFR_ai_noGUI_GNM(input_folder, output_folder, sub_name, mode )
global ProgramPath
stk = dbstack; 
ProgramPath = fileparts(which(stk(1).file))

addpath(genpath([ProgramPath '/Subfunctions']));
addpath(genpath([ProgramPath '/Templates']));
addpath(genpath([ProgramPath '/Utilities']));
addpath(genpath([ProgramPath '/Bash'])); 



if strcmp(mode, 'individual_timeseries')
    % timeseries data extraction 
    sub_list = { sub_name };
    Func_FS4_Data_Read_GNM(input_folder, output_folder, sub_list);
    disp('Only extracting timeseries. Not running parcellation');
    exit
end


if strcmp(mode, 'individual_parcellation')
    sub_list = { sub_name };
    Func_FS4_Data_Read_GNM(input_folder, output_folder, sub_list);
    
    numIter = 10;
    confidence_threshold = 3;
    combineLeftRight = 1;
    Func_IterativeParcellation(ProgramPath, output_folder, sub_list, numIter, confidence_threshold, combineLeftRight);
    disp("Individual Parcellation Finished");
    
    IterNumber = '10';
    dr_fold = [output_folder '/IndiPar'];
    OutDir = [output_folder '/DiscretePatches'];
    mkdir(OutDir);
    for s = 1:length(sub_list)
        sub = sub_list{s};
        eval(['! ' ProgramPath '/Bash/Get_DiscretePatches_for_EachNet.csh ' dr_fold ' ' OutDir ' ' sub ' ' IterNumber]);
    end

    out_dir = [output_folder '/MatchMatrix'];
    mkdir(out_dir);
    Func_MatchPatch_Between_IndiSub_GrpTemplate(ProgramPath,[output_folder '/DiscretePatches'],sub_list,out_dir);
end

if strcmp(mode, 'create_group_patches')
    MatchRate = 0.9;
    fid = fopen(sub_name);
    if fid == -1
        error('Cannot open file: %s', sub_name);
    end
    sub_list = textscan(fid, '%s');
    sub_list = sub_list{1}; % extract cell array
    fclose(fid);
    Func_Generate_Matched_ROIs(ProgramPath, [input_folder '/DiscretePatches'], [input_folder '/MatchMatrix'], [input_folder, '/IndiPar'], output_folder, sub_list, MatchRate)
    eval(['!rm -rf ' output_folder '/MatchRate' num2str(MatchRate) '/Indi_Matched_Patches_Splited']);
    eval(['!rm -rf ' output_folder '/MatchRate' num2str(MatchRate) '/Indi_Matched_Patches_Clean']);
end

if strcmp(mode, 'apply_group_patches')
    MatchRate = 0.9;

    fid = fopen(sub_name);
    if fid == -1
        error('Cannot open file: %s', sub_name);
    end
    sub_list = textscan(fid, '%s');
    sub_list = sub_list{1}; % extract cell array
    fclose(fid);

    ROIPath = [input_folder '/MatchRate' num2str(MatchRate)];
    DataPath = [output_folder '/OrganizedData']; 
    OutPath = output_folder;
    Func_ROI2ROI_from_ROIs_Indi_GNM(ROIPath,DataPath,OutPath,sub_list); 
    Func_ROI2ROI_from_ROIs_Atlas_GNM(ROIPath,DataPath,OutPath,sub_list);
end

