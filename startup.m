function startup()
% STARTUP  Initialize SAR Workbench paths and environment
repoRoot = fileparts(mfilename('fullpath'));
addpath(repoRoot);
addpath(fullfile(repoRoot, 'app'));
addpath(fullfile(repoRoot, 'research'));
addpath(fullfile(repoRoot, 'models'));
fprintf('SAR Workbench environment initialized from: %s\n', repoRoot);
end
