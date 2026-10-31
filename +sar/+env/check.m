function status = check()
% SAR.ENV.CHECK  Comprehensive environment and requirement verification
%   Checks MATLAB version, toolboxes, GPU, data folders, and models.
%   Returns a struct with details and pass/warn/fail status for each subsystem.

cfg = sar.env.config();
status = struct();

fprintf('================ SAR Workbench Environment Check ================\n');
fprintf('Timestamp: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('Root Dir : %s\n\n', cfg.rootDir);

%% 1. MATLAB Version
v = ver('matlab');
matlabVer = v.Release;
vNum = sscanf(v.Version, '%d.%d');
vMajor = vNum(1);
% R2023b is 23.2, R2026a is 26.1
status.matlab = struct();
status.matlab.version = v.Version;
status.matlab.release = matlabVer;
if vMajor >= 24 || (vMajor == 23 && vNum(2) >= 2)
    status.matlab.ok = true;
    status.matlab.state = 'pass';
    fprintf('[PASS] MATLAB Version: %s (%s)\n', matlabVer, v.Version);
else
    status.matlab.ok = false;
    status.matlab.state = 'fail';
    fprintf('[FAIL] MATLAB Version: %s (requires R2023b or later for trainnet/minibatchpredict)\n', matlabVer);
end

%% 2. Toolboxes
tbList = {
    'nnet',     'Deep Learning Toolbox',              true;
    'images',   'Image Processing Toolbox',           true;
    'signal',   'Signal Processing Toolbox',          true;
    'stats',    'Statistics and Machine Learning',   true;
    'phased',   'Phased Array System Toolbox',        false;
    'parallel', 'Parallel Computing Toolbox',         false
};

status.toolboxes = struct();
tbAllReq = true;
fprintf('\n--- Toolboxes ---\n');
for i = 1:size(tbList, 1)
    code = tbList{i, 1};
    name = tbList{i, 2};
    req  = tbList{i, 3};
    installed = ~isempty(ver(code));
    
    st = struct('name', name, 'required', req, 'installed', installed);
    status.toolboxes.(code) = st;
    
    if installed
        fprintf('[PASS] %-35s : Installed\n', name);
    elseif req
        tbAllReq = false;
        fprintf('[FAIL] %-35s : Missing (Required)\n', name);
    else
        fprintf('[WARN] %-35s : Missing (Optional)\n', name);
    end
end
status.toolboxes.allRequired = tbAllReq;
if tbAllReq
    status.toolboxes.state = 'pass';
else
    status.toolboxes.state = 'fail';
end

%% 3. GPU Hardware
status.gpu = struct();
fprintf('\n--- GPU Acceleration ---\n');
try
    nGpu = gpuDeviceCount();
catch
    nGpu = 0;
end

if nGpu > 0
    try
        dev = gpuDevice();
        status.gpu.available = true;
        status.gpu.name = dev.Name;
        status.gpu.totalMemGB = dev.TotalMemory / (1024^3);
        status.gpu.availMemGB = dev.AvailableMemory / (1024^3);
        status.gpu.computeCapability = dev.ComputeCapability;
        status.gpu.state = 'pass';
        fprintf('[PASS] GPU Detected: %s (%.2f GB total, %.2f GB free, CC %s)\n', ...
            dev.Name, status.gpu.totalMemGB, status.gpu.availMemGB, dev.ComputeCapability);
    catch err
        status.gpu.available = false;
        status.gpu.error = err.message;
        status.gpu.state = 'warn';
        fprintf('[WARN] GPU detected but cannot be initialized: %s\n', err.message);
    end
else
    status.gpu.available = false;
    status.gpu.state = 'warn';
    fprintf('[WARN] No compatible NVIDIA CUDA GPU detected (CPU fallback will be slow)\n');
end

%% 4. Data Directories
status.data = struct();
fprintf('\n--- Data Paths ---\n');

% MSTAR chips & clutter
mstarRoot = cfg.dataPath.mstar;
hasMstarMat = exist(cfg.dataPath.mstarSocMat, 'file') ~= 0;
mstarDirs = dir(fullfile(mstarRoot, 'MSTAR*'));
status.data.mstar = struct();
status.data.mstar.path = mstarRoot;
status.data.mstar.hasSocMat = hasMstarMat;
status.data.mstar.numDirs = numel(mstarDirs);
if hasMstarMat || numel(mstarDirs) > 0
    status.data.mstar.state = 'pass';
    fprintf('[PASS] MSTAR Data: found (%d raw folders, mstar_soc.mat=%d)\n', numel(mstarDirs), hasMstarMat);
else
    status.data.mstar.state = 'fail';
    fprintf('[FAIL] MSTAR Data: Not found in %s\n', mstarRoot);
end

% AFRL Gotcha
gotchaPath = cfg.dataPath.gotcha;
gotchaFiles = dir(fullfile(gotchaPath, '**', '*.mat'));
status.data.gotcha = struct();
status.data.gotcha.path = gotchaPath;
status.data.gotcha.numFiles = numel(gotchaFiles);
if numel(gotchaFiles) > 0
    status.data.gotcha.state = 'pass';
    fprintf('[PASS] Gotcha Data: found (%d .mat files in %s)\n', numel(gotchaFiles), gotchaPath);
else
    status.data.gotcha.state = 'fail';
    fprintf('[FAIL] Gotcha Data: No .mat files found in %s\n', gotchaPath);
end

% Sentinel-1
s1Path = cfg.dataPath.sentinel1;
s1Safe = dir(fullfile(s1Path, '**', '*.SAFE'));
s1Zip = dir(fullfile(s1Path, '**', '*.zip'));
status.data.sentinel1 = struct();
status.data.sentinel1.path = s1Path;
status.data.sentinel1.numSafe = numel(s1Safe);
status.data.sentinel1.numZip = numel(s1Zip);
if numel(s1Safe) > 0 || numel(s1Zip) > 0
    status.data.sentinel1.state = 'pass';
    fprintf('[PASS] Sentinel-1 Data: found (%d SAFE dirs, %d zip files)\n', numel(s1Safe), numel(s1Zip));
else
    status.data.sentinel1.state = 'warn';
    fprintf('[WARN] Sentinel-1 Data: none found in %s\n', s1Path);
end

%% 5. Trained Models
status.models = struct();
fprintf('\n--- Trained Models ---\n');

% MERLIN MSTAR
merlinMstar = fullfile(cfg.modelsPath, 'p3b_merlin.mat');
status.models.merlinMstar = struct('path', merlinMstar, 'exists', exist(merlinMstar, 'file') ~= 0);
if status.models.merlinMstar.exists
    status.models.merlinMstar.state = 'pass';
    fprintf('[PASS] MERLIN (MSTAR): %s\n', merlinMstar);
else
    status.models.merlinMstar.state = 'fail';
    fprintf('[FAIL] MERLIN (MSTAR): Missing from %s\n', merlinMstar);
end

% MERLIN Gotcha
merlinGotcha = fullfile(cfg.modelsPath, 'p3b_merlin_gotcha.mat');
status.models.merlinGotcha = struct('path', merlinGotcha, 'exists', exist(merlinGotcha, 'file') ~= 0);
if status.models.merlinGotcha.exists
    status.models.merlinGotcha.state = 'pass';
    fprintf('[PASS] MERLIN (Gotcha): %s\n', merlinGotcha);
else
    status.models.merlinGotcha.state = 'fail';
    fprintf('[FAIL] MERLIN (Gotcha): Missing from %s\n', merlinGotcha);
end

% ATR CNN (MSTAR)
cnnMstar = fullfile(cfg.modelsPath, 'cnn_mstar.mat');
status.models.cnnMstar = struct('path', cnnMstar, 'exists', exist(cnnMstar, 'file') ~= 0);
if status.models.cnnMstar.exists
    status.models.cnnMstar.state = 'pass';
    fprintf('[PASS] ATR CNN (MSTAR): %s\n', cnnMstar);
else
    status.models.cnnMstar.state = 'warn';
    fprintf('[WARN] ATR CNN (MSTAR): Not trained yet (run research_new/train_final_mstar.m for G2b)\n');
end

%% Summary Verdict
allPass = strcmp(status.matlab.state, 'pass') && ...
          strcmp(status.toolboxes.state, 'pass') && ...
          strcmp(status.data.mstar.state, 'pass') && ...
          strcmp(status.data.gotcha.state, 'pass') && ...
          strcmp(status.models.merlinMstar.state, 'pass');

if allPass
    status.overall = 'PASS';
    fprintf('\n>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<\n');
else
    status.overall = 'FAIL';
    fprintf('\n>>> OVERALL STATUS: INCOMPLETE / FAIL <<<\n');
end
fprintf('=================================================================\n\n');
end
