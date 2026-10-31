function [mag, ph, H] = mstar_read(fn)
% MSTAR_READ  Read one MSTAR chip: ASCII Phoenix header, then float32 big-endian planes
% (magnitude, then phase). Returns mag/ph as rows x cols single and the header struct H.
% The pixel offset is checked against the file size:
%   H.offsetMethod = 'marker'  data starts right after the EndofPhoenixHeader line and the
%                              file size is exactly header + 2*4*rows*cols  (expected case)
%                  = 'tail'    extra bytes sit between header and data; data taken from the file end
%                  = 'marker-magonly'  only one plane is present (ph is returned empty)
H = mstar_header(fn);
R = H.rows; C = H.cols;
if ~(isfinite(R) && isfinite(C) && R > 0 && C > 0)
    error('mstar_read:size', 'NumberOfRows/NumberOfColumns missing or invalid in %s', fn);
end
nbyte = 4*R*C;
nrem = H.fsize - H.hdrEnd;
if nrem == 2*nbyte
    off = H.hdrEnd; H.offsetMethod = 'marker';
elseif nrem > 2*nbyte
    off = H.fsize - 2*nbyte; H.offsetMethod = 'tail'; H.gapBytes = off - H.hdrEnd;
elseif nrem == nbyte
    off = H.hdrEnd; H.offsetMethod = 'marker-magonly';
else
    error('mstar_read:short', '%s: %d bytes after header, need %d (2 planes) or %d (1 plane); rows=%d cols=%d', ...
        fn, nrem, 2*nbyte, nbyte, R, C);
end
fid = fopen(fn, 'r', 'ieee-be');
if fid < 0, error('mstar_read:open', 'cannot open %s', fn); end
c = onCleanup(@() fclose(fid));
fseek(fid, off, 'bof');
M = fread(fid, [C R], 'float32=>single');
mag = M.';
if strcmp(H.offsetMethod, 'marker-magonly')
    ph = [];
else
    P = fread(fid, [C R], 'float32=>single');
    ph = P.';
end
H.offset = off;
end
