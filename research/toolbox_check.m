%% toolbox_check.m
% SAR Workbench - Environment Pre-Flight Check
% Run this at the start of EVERY session, and definitely before any Stage 1
% or Stage 2 work. Produces a timestamped log so you have a dated artifact
% to show your guide as proof of diligence if licensing ever becomes an issue.
%
% Usage: just run this script. No inputs needed.

clc;
logFile = sprintf('toolbox_check_log_%s.txt', datestr(now,'yyyymmdd_HHMMSS'));
diary(logFile);
diary on;

fprintf('=== SAR Workbench Environment Check ===\n');
fprintf('Timestamp: %s\n', datestr(now));
fprintf('MATLAB Version: %s\n\n', version);

fprintf('--- Installed Products (ver) ---\n');
ver

requiredToolboxes = {
    'Image_Toolbox',            'Image Processing Toolbox'
    'Deep_Learning_Toolbox',    'Deep Learning Toolbox'
    'Video_and_Image_Blockset', 'Computer Vision Toolbox'
    'Statistics_Toolbox',       'Statistics and Machine Learning Toolbox'
    'Distrib_Computing_Toolbox','Parallel Computing Toolbox'
    'Phased_Array_System_Toolbox','Phased Array System Toolbox'
    'Radar_Toolbox',            'Radar Toolbox'
};

fprintf('\n--- License Test (license(''test'',...)) ---\n');
results = cell(size(requiredToolboxes,1),3);
for i = 1:size(requiredToolboxes,1)
    licName = requiredToolboxes{i,1};
    dispName = requiredToolboxes{i,2};
    testResult = license('test', licName);
    fprintf('%-40s : test=%d\n', dispName, testResult);
    results{i,1} = dispName;
    results{i,2} = testResult;
end

fprintf('\n--- Real Checkout Test (license(''checkout'',...)) ---\n');
fprintf('NOTE: This actually claims a seat. Run sparingly on floating licenses.\n');
for i = 1:size(requiredToolboxes,1)
    licName = requiredToolboxes{i,1};
    dispName = requiredToolboxes{i,2};
    try
        [status, errmsg] = license('checkout', licName);
        fprintf('%-40s : checkout status=%d %s\n', dispName, status, errmsg);
        results{i,3} = status;
    catch ME
        fprintf('%-40s : ERROR - %s\n', dispName, ME.message);
        results{i,3} = -1;
    end
end

fprintf('\n--- GPU Check (needed for Stage 2 despeckling training) ---\n');
try
    g = gpuDevice;
    fprintf('GPU detected: %s | Memory: %.1f GB | CUDA capability: %s\n', ...
        g.Name, g.AvailableMemory/1e9, g.ComputeCapability);
catch
    fprintf('NO GPU DETECTED via gpuDevice. Deep Learning Toolbox training for\n');
    fprintf('SAR2SAR-style despeckling will fall back to CPU - expect this to be\n');
    fprintf('very slow. Flag this now, don''t discover it mid Stage 2.\n');
end

fprintf('\n=== Summary ===\n');
allGood = true;
for i = 1:size(results,1)
    if results{i,3} ~= 1
        fprintf('BLOCKER: %s did not check out successfully.\n', results{i,1});
        allGood = false;
    end
end
if allGood
    fprintf('All required toolboxes checked out successfully. Cleared to proceed.\n');
else
    fprintf('One or more toolboxes failed checkout. Resolve before writing dependent code.\n');
end

diary off;
fprintf('\nLog saved to: %s\n', logFile);
