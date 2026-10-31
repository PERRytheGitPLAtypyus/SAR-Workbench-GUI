function pha = loadGotchaPhaseHistory(filepath, verbose)
%LOADGOTCHAPHASEHISTORY Load one Gotcha .mat phase history file and
% reshape it into the same struct format backprojection2D.m expects.
%
% IMPORTANT - READ BEFORE RUNNING:
% I have NOT independently verified the exact internal field names of
% Gotcha .mat files (the SDMS download page sits behind a login wall I
% can't access, so I won't fabricate field names and hand you code that
% silently does the wrong thing). This function runs in two modes:
%
%   1) DIAGNOSTIC MODE (verbose=true, or first time you ever run this):
%      Loads the file and PRINTS every field name and its size/class.
%      Do this first, on one file, and read the output before trusting
%      anything downstream.
%
%   2) MAPPED MODE: once you've confirmed the real field names from step 1,
%      edit the fieldMap section below (clearly marked) to match what your
%      file actually contains, then re-run with verbose=false for normal use.
%
% Per the Gotcha documentation (Version 1.0 overview, SDMS site):
% "Loading a file gives a single MATLAB structure with fields containing
% the k-space data, frequencies, x,y,z coordinate antenna locations,
% range to scene center, azimuth angle, and elevation angle."
% That tells us WHAT should be present conceptually - not the literal
% MATLAB field names, which is exactly why step 1 diagnostic mode exists.

if nargin < 2, verbose = true; end

raw = load(filepath);
topFields = fieldnames(raw);

if verbose
    fprintf('=== Gotcha file diagnostic: %s ===\n', filepath);
    fprintf('Top-level fields: %s\n', strjoin(topFields, ', '));
end

% Gotcha files typically load a single top-level struct - grab it
if numel(topFields) == 1
    s = raw.(topFields{1});
else
    error(['Expected exactly one top-level variable in the .mat file, found %d: %s. ', ...
           'Inspect manually with: raw = load(''%s'') and whos(''raw'')'], ...
           numel(topFields), strjoin(topFields, ', '), filepath);
end

if verbose
    fprintf('\nFields inside the struct:\n');
    innerFields = fieldnames(s);
    for i = 1:numel(innerFields)
        f = innerFields{i};
        val = s.(f);
        fprintf('  %-20s class=%-10s size=%s\n', f, class(val), mat2str(size(val)));
    end
    fprintf('\nCompare this list against the documented fields (k-space data,\n');
    fprintf('freq, x/y/z antenna position, range-to-center, azimuth, elevation)\n');
    fprintf('and edit the fieldMap section in this file to match, then re-run\n');
    fprintf('with verbose=false.\n');
end

%% ===== EDIT THIS SECTION after running diagnostic mode once =====
% Map the ACTUAL field names you saw printed above to the standard names
% backprojection2D.m expects. Placeholder guesses below based on common
% AFRL/Gotcha-adjacent naming conventions seen in third-party processing
% code - VERIFY against your own diagnostic output before trusting these.
fieldMap = struct( ...
    'data',  'data', ...   % k-space / phase history data
    'freq',  'freq', ...   % frequency vector
    'AntX',  'x', ...      % antenna x position
    'AntY',  'y', ...      % antenna y position
    'AntZ',  'z', ...      % antenna z position
    'R0',    'r0' ...      % range to scene center
);
%% ==================================================================

if ~verbose
    try
        pha.data = s.(fieldMap.data);
        pha.freq = s.(fieldMap.freq);
        pha.AntX = s.(fieldMap.AntX);
        pha.AntY = s.(fieldMap.AntY);
        pha.AntZ = s.(fieldMap.AntZ);
        pha.R0   = s.(fieldMap.R0);
        pha.fc   = mean(pha.freq);
        fprintf('Loaded Gotcha phase history: %s\n', filepath);
    catch ME
        error(['Field mapping failed (%s). This means fieldMap above doesn''t match ', ...
               'this file''s real structure. Re-run with verbose=true to see actual ', ...
               'field names and fix the mapping.'], ME.message);
    end
else
    pha = s;  % return raw struct in diagnostic mode, unmapped
end

end
