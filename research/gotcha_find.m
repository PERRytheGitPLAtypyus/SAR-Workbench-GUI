function [files, az] = gotcha_find(root, passNum, pol, azList)
% GOTCHA_FIND  Locate Gotcha azimuth .mat files for one pass + polarization.
%   [files, az] = gotcha_find(root, 8, 'HH', 1:3)   % azList=[] -> all
% Matching is by regex on the full path (pass) and file name (pol, azNNN),
% so it tolerates different folder/file naming. Prints diagnostics if empty.
L = dir(fullfile(root, '**', '*.mat'));
files = {}; az = [];
passPat = sprintf('pass0*%d(?!\\d)', passNum);
polPat  = ['(^|[^A-Za-z])' pol '([^A-Za-z]|$)'];
for i = 1:numel(L)
    full = fullfile(L(i).folder, L(i).name);
    if contains(full, '.venv') || contains(full, 'site-packages'), continue; end
    if isempty(regexpi(full, passPat, 'once')), continue; end
    if isempty(regexpi(L(i).name, polPat, 'once')), continue; end
    t = regexpi(L(i).name, 'az0*(\d+)', 'tokens', 'once');
    if isempty(t), continue; end
    a = str2double(t{1});
    if isempty(azList) || ismember(a, azList)
        files{end+1} = full; %#ok<AGROW>
        az(end+1) = a;       %#ok<AGROW>
    end
end
[az, ix] = sort(az); files = files(ix);
if isempty(files)
    fprintf('gotcha_find: NO files matched (pass %d, pol %s). First .mat files seen:\n', passNum, pol);
    for i = 1:min(10, numel(L)), fprintf('   %s\n', fullfile(L(i).folder, L(i).name)); end
    fprintf('Paste these lines to me and I will fix the pattern.\n');
else
    fprintf('gotcha_find: %d files, az %d..%d\n', numel(files), min(az), max(az));
end
end
