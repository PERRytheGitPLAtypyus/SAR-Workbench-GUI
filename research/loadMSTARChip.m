function [magImg, phaseImg, header] = loadMSTARChip(filepath)
%LOADMSTARCHIP Parse an MSTAR target chip file (e.g. "HB03333.015").
% MSTAR files = variable-length ASCII "Phoenix" header, followed by a
% binary data block: NumberOfRows x NumberOfColumns magnitude values
% (big-endian float32), immediately followed by the same-sized phase
% block. This matches the documented MSTAR file format used across the
% published literature.
%
% CROSS-CHECK BEFORE TRUSTING THIS ON YOUR FULL DATASET:
% Run this on ONE known file first, then:
%   imagesc(magImg); colormap gray; axis image;
% and visually compare against a reference MSTAR chip image from any
% published paper (Chang et al. 2011 has example figures). If your image
% looks like structured noise instead of a recognizable vehicle silhouette,
% the byte order or header-length parsing below needs adjustment for your
% specific file variant - don't assume this is correct without that visual
% sanity check on real data.
%
% INPUT: filepath - full path to an MSTAR chip file
% OUTPUT:
%   magImg   - [rows x cols] magnitude image (double)
%   phaseImg - [rows x cols] phase image, radians (double)
%   header   - struct of parsed header fields (raw key-value pairs)

fid = fopen(filepath, 'r');
if fid == -1
    error('Could not open file: %s', filepath);
end

header = struct();
headerLines = {};
while true
    line = fgetl(fid);
    if ischar(line) && contains(line, '[EndofPhoenixHeader]')
        break;
    end
    if ~ischar(line)
        fclose(fid);
        error('Reached EOF without finding [EndofPhoenixHeader] marker. This file may not be a standard MSTAR Phoenix-header file - inspect it manually with a text editor first.');
    end
    headerLines{end+1} = line; %#ok<AGROW>
end

% Parse "Key= Value" style lines into the header struct where possible
for i = 1:numel(headerLines)
    parts = strsplit(headerLines{i}, '=');
    if numel(parts) == 2
        key = matlab.lang.makeValidName(strtrim(parts{1}));
        val = strtrim(parts{2});
        header.(key) = val;
    end
end

% Pull dimensions - field names per MSTAR spec
if isfield(header, 'NumberOfRows') && isfield(header, 'NumberOfColumns')
    rows = str2double(header.NumberOfRows);
    cols = str2double(header.NumberOfColumns);
else
    fclose(fid);
    error('NumberOfRows / NumberOfColumns not found in header. Print headerLines to inspect this file''s actual field names.');
end

% Binary data block: big-endian float32, magnitude block then phase block
magData = fread(fid, rows*cols, 'float32', 0, 'ieee-be');
phaseData = fread(fid, rows*cols, 'float32', 0, 'ieee-be');
fclose(fid);

if numel(magData) ~= rows*cols || numel(phaseData) ~= rows*cols
    error(['Data block size mismatch: expected %d values per block, got mag=%d phase=%d. ', ...
           'This usually means the header length was mis-parsed - double check the ', ...
           '[EndofPhoenixHeader] detection above.'], rows*cols, numel(magData), numel(phaseData));
end

magImg = reshape(magData, cols, rows).';
phaseImg = reshape(phaseData, cols, rows).';

fprintf('Loaded %s: %dx%d chip, target type field: %s\n', ...
    filepath, rows, cols, getFieldSafe(header, 'TargetType'));
end

function v = getFieldSafe(s, f)
if isfield(s, f)
    v = s.(f);
else
    v = '(not found - check header field names)';
end
end
