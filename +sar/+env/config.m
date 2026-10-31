function cfg = config()
% SAR.ENV.CONFIG  Load project configuration from sarconfig.json
%   Returns a struct with absolute paths resolved against project root.

persistent cachedConfig;
if ~isempty(cachedConfig)
    cfg = cachedConfig;
    return;
end

% Project root is two levels up from +sar/+env
thisDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(fileparts(thisDir));

configFile = fullfile(rootDir, 'sarconfig.json');
exampleFile = fullfile(rootDir, 'sarconfig.example.json');

if exist(configFile, 'file')
    raw = fileread(configFile);
elseif exist(exampleFile, 'file')
    raw = fileread(exampleFile);
else
    raw = '{}';
end

try
    json = jsondecode(raw);
catch
    json = struct();
end

cfg = struct();
cfg.rootDir = rootDir;

% Helper to resolve path
resolve = @(p) resolvePath(rootDir, p);

% Data paths
if isfield(json, 'dataPath')
    dp = json.dataPath;
    cfg.dataPath = struct();
    cfg.dataPath.mstar = resolve(getOpt(dp, 'mstar', '.'));
    cfg.dataPath.gotcha = resolve(getOpt(dp, 'gotcha', 'Gotcha-CP-Disc2'));
    cfg.dataPath.sentinel1 = resolve(getOpt(dp, 'sentinel1', 'Sentinel1'));
    cfg.dataPath.mstarSocMat = resolve(getOpt(dp, 'mstarSocMat', 'mstar_soc.mat'));
else
    cfg.dataPath = struct();
    cfg.dataPath.mstar = rootDir;
    cfg.dataPath.gotcha = fullfile(rootDir, 'Gotcha-CP-Disc2');
    cfg.dataPath.sentinel1 = fullfile(rootDir, 'Sentinel1');
    cfg.dataPath.mstarSocMat = fullfile(rootDir, 'mstar_soc.mat');
end

cfg.modelsPath = resolve(getOpt(json, 'modelsPath', 'models'));
cfg.resultsPath = resolve(getOpt(json, 'resultsPath', 'p4b_stage2m.mat'));
cfg.runsPath = resolve(getOpt(json, 'runsPath', 'p4b_runs'));

cachedConfig = cfg;
end

function out = getOpt(s, f, defaultVal)
if isfield(s, f) && ~isempty(s.(f))
    out = s.(f);
else
    out = defaultVal;
end
end

function full = resolvePath(root, p)
if isempty(p)
    full = root;
elseif startsWith(p, filesep) || (numel(p) > 1 && p(2) == ':')
    full = p;
else
    full = fullfile(root, p);
end
end
