function H = mstar_header(fn)
% MSTAR_HEADER  Parse the ASCII Phoenix header of an MSTAR file (pixel data is not read).
% H holds every "key= value" line (numeric when it parses as a number) plus:
%   H.rows, H.cols   from NumberOfRows / NumberOfColumns (NaN if absent)
%   H.fsize          file size in bytes
%   H.hdrEnd         byte offset just after the line containing EndofPhoenixHeader
fid = fopen(fn, 'r');
if fid < 0, error('mstar_header:open', 'cannot open %s', fn); end
c = onCleanup(@() fclose(fid));
fseek(fid, 0, 'eof'); fsz = ftell(fid); frewind(fid);
raw = fread(fid, min(fsz, 32768), 'uint8=>uint8').';
txt = char(raw);
k = strfind(txt, 'EndofPhoenixHeader');
if isempty(k)
    error('mstar_header:nomarker', 'no EndofPhoenixHeader in first %d bytes of %s', numel(raw), fn);
end
k = k(1);
nl = find(raw(k:end) == 10, 1);
if isempty(nl)
    error('mstar_header:nonewline', 'no newline after EndofPhoenixHeader in %s', fn);
end
H = struct();
lines = regexp(txt(1:k-1), '[\r\n]+', 'split');
for i = 1:numel(lines)
    t = regexp(lines{i}, '^\s*\[?\s*([^=\s][^=]*?)\s*=\s*(.*?)\s*\]?\s*$', 'tokens', 'once');
    if isempty(t), continue; end
    key = matlab.lang.makeValidName(t{1});
    val = str2double(t{2});
    if isnan(val), val = t{2}; end
    H.(key) = val;
end
H.fsize = fsz;
H.hdrEnd = k + nl - 1;
H.rows = NaN; H.cols = NaN;
if isfield(H, 'NumberOfRows') && isnumeric(H.NumberOfRows), H.rows = H.NumberOfRows; end
if isfield(H, 'NumberOfColumns') && isnumeric(H.NumberOfColumns), H.cols = H.NumberOfColumns; end
end
