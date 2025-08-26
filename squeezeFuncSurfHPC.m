function squeezeFuncSurfHPC(surfTsIn, surfTsOut, FREESURFER_HOME)
    % Make sure Freesurfer Dependency is set
    addpath(FREESURFER_HOME);  % Use the input FREESURFER_HOME path
    
    % Read mri and template in
    mri = MRIread(surfTsIn);
    
    % Squeeze mri.vol, transpose it, add to new mri structure and write file,
    % also repeat with template header
    dat = squeeze(mri.vol);
    datT = transpose(dat);
    
    mriSqueezed = mri;
    mriSqueezed.vol = datT;
    
    % Ensure the output path is created before writing
    [outputDir, ~, ~] = fileparts(surfTsOut);
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);  % Create the directory if it doesn't exist
    end
    
    % Write the modified MRI data to the output path
    MRIwrite(mriSqueezed, surfTsOut);
end