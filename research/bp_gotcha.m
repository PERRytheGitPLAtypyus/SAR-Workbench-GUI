function [img, xv, yv] = bp_gotcha(G, o)
% BP_GOTCHA  Time-domain backprojection with per-pulse 3D platform positions.
% Image is formed on the horizontal plane z = o.z (scene centre = origin).
% Options (all optional):
%   o.xlim,o.ylim [min max] m   o.dx m   o.z m   o.pad (zero-pad factor, >=8)
%   o.conj  0/1  conjugate data (use if the file's phase convention is exp(+j..))
%   o.afr   0/+1/-1  add af_r (m) to r0 with that sign       (EXPERIMENTAL)
%   o.afp   0/+1/-1  multiply by exp(j*sign*af_ph)           (EXPERIMENTAL)
%   o.af    shorthand: sets both afr and afp to the same value
% Convention assumed: S(f)=exp(-j*4*pi*f*R/c), range-referenced to r0.
c = 299792458;
d = struct('xlim',[-30 30],'ylim',[-30 30],'dx',0.15,'z',0,'pad',8,'conj',0,'af',0,'afr',0,'afp',0);
if nargin < 2, o = struct(); end
fn = fieldnames(d); for i = 1:numel(fn), if ~isfield(o,fn{i}), o.(fn{i}) = d.(fn{i}); end, end
if o.af ~= 0, o.afr = o.af; o.afp = o.af; end

K = numel(G.freq); N = size(G.fp,2);
df = mean(diff(G.freq)); f0 = G.freq(1);
M = K*o.pad; dstep = c/(2*M*df);                 % range sample spacing of padded profile (m)
xv = o.xlim(1):o.dx:o.xlim(2); yv = o.ylim(1):o.dx:o.ylim(2);
[X, Y] = meshgrid(xv, yv); Z = o.z*ones(size(X));
img = zeros(size(X));
haveAF = ~isempty(G.af_r);
for n = 1:N
    s = G.fp(:,n);
    if o.conj, s = conj(s); end
    r0 = G.r0(n);
    if haveAF
        if o.afr ~= 0, r0 = r0 + o.afr*G.af_r(n); end
        if o.afp ~= 0, s = s .* exp(1j*o.afp*G.af_ph(n)); end
    end
    prof = fftshift(ifft(s, M)) * M;             % index j <-> m = j-1-M/2
    dR = sqrt((X-G.pos(1,n)).^2 + (Y-G.pos(2,n)).^2 + (Z-G.pos(3,n)).^2) - r0;
    idx = dR/dstep + M/2 + 1;
    ok = idx >= 1 & idx < M;
    i0 = floor(idx); i0(~ok) = 1; fr = idx - i0;
    v = prof(i0).*(1-fr) + prof(i0+1).*fr;       % linear interp of complex profile
    v(~ok) = 0;
    img = img + v .* exp(1j*4*pi*f0/c*dR);       % remove carrier phase -> coherent sum
end
end