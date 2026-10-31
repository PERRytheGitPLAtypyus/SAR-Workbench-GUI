function m = profile_metrics(ax, a)
% PROFILE_METRICS  IRW (-3 dB, amplitude 1/sqrt(2)), PSLR and ISLR of a 1-D point-target cut.
%   ax : axis in metres (uniform, peak near the middle);  a : complex or real profile.
%   Sidelobe region = everything in the cut outside the first nulls around the peak.
    a = abs(a(:)).';  ax = ax(:).';
    [pk, ip] = max(a);  p = a / pk;
    thr = 1/sqrt(2);
    il = ip;  while il > 1 && p(il) > thr,        il = il - 1; end
    ir = ip;  while ir < numel(p) && p(ir) > thr, ir = ir + 1; end
    xl = ax(il)   + (thr - p(il))  *(ax(il+1) - ax(il))  /(p(il+1) - p(il));
    xr = ax(ir-1) + (thr - p(ir-1))*(ax(ir)   - ax(ir-1))/(p(ir)   - p(ir-1));
    nl = ip;  while nl > 1 && p(nl-1) < p(nl),          nl = nl - 1; end
    nr = ip;  while nr < numel(p) && p(nr+1) < p(nr),   nr = nr + 1; end
    side = p;  side(nl:nr) = 0;
    m.IRW     = xr - xl;
    m.PSLR_dB = 20*log10(max(side));
    m.ISLR_dB = 10*log10(sum(side.^2) / sum(p(nl:nr).^2));
    m.null_l  = ax(nl);  m.null_r = ax(nr);
end
