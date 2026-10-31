function G = gotcha_load(files)
% GOTCHA_LOAD  Load and concatenate Gotcha azimuth files (one pass, one pol).
% Output G:
%   fp   [K x N] complex phase history      freq [K x 1] Hz, ascending
%   pos  [3 x N] platform xyz (m)           r0   [1 x N] range to scene centre (m)
%   af_r, af_ph  per-pulse autofocus corrections if found, else []
%   fileIdx [1 x N] which file each pulse came from
% Orientation of fp is auto-detected from numel(freq).
if ischar(files), files = {files}; end
FP = []; POS = []; R0 = []; AFR = []; AFP = []; FI = []; freq = [];
for i = 1:numel(files)
    S = load(files{i}); d = S.data;
    fr = double(d.freq(:));
    fp = double(d.fp);
    if size(fp,1) ~= numel(fr)
        if size(fp,2) == numel(fr), fp = fp.'; else
            error('fp size %s does not match numel(freq)=%d in %s', mat2str(size(fp)), numel(fr), files{i});
        end
    end
    [fr, ix] = sort(fr); fp = fp(ix,:);            % force ascending frequency
    % Files store freq as single (~1 kHz resolution at 9.6 GHz). Snap to the ideal
    % uniform grid in double, but only if the deviation is pure float32 rounding.
    kk = (0:numel(fr)-1).'; pf = polyfit(kk, fr - fr(1), 1);
    frLin = fr(1) + polyval(pf, kk);
    devHz = max(abs(fr - frLin));
    fprintf('  file %d: freq deviation from linear grid = %.0f Hz (float32 rounding is <= ~1024 Hz)\n', i, devHz);
    if devHz > 2048, error('freq axis is genuinely non-uniform in %s (%.0f Hz)', files{i}, devHz); end
    fr = frLin;
    N = size(fp,2);
    if isempty(freq), freq = fr;
    elseif max(abs(fr-freq)) > 2048, error('frequency axis differs in %s', files{i}); end
    pos = double([d.x(:).'; d.y(:).'; d.z(:).']);
    r0  = double(d.r0(:).'); if isscalar(r0), r0 = repmat(r0,1,N); end
    FP = [FP, fp]; POS = [POS, pos]; R0 = [R0, r0]; FI = [FI, i*ones(1,N)]; %#ok<AGROW>
    % autofocus corrections (names guessed case-insensitively; semantics UNVERIFIED)
    ar = []; ap = [];
    if isfield(d,'af') && isstruct(d.af)
        nm = fieldnames(d.af);
        ir = find(strcmpi(nm,'r_correct'),1); ip = find(strcmpi(nm,'ph_correct'),1);
        if ~isempty(ir), ar = double(d.af.(nm{ir})); end
        if ~isempty(ip), ap = double(d.af.(nm{ip})); end
        if ~isempty(ar) && isscalar(ar), ar = repmat(ar(:).',1,N); end
        if ~isempty(ap) && isscalar(ap), ap = repmat(ap(:).',1,N); end
        if ~isempty(ar) && numel(ar) ~= N, ar = []; end   % unknown shape -> skip
        if ~isempty(ap) && numel(ap) ~= N, ap = []; end
    end
    if isempty(ar) || isempty(ap), AFR = []; AFP = []; af_ok = false; else, af_ok = true; end
    if af_ok && (i == 1 || ~isempty(AFR)), AFR = [AFR, ar(:).']; AFP = [AFP, ap(:).']; end %#ok<AGROW>
end
G.fp = FP; G.freq = freq; G.pos = POS; G.r0 = R0; G.fileIdx = FI;
G.af_r = AFR; G.af_ph = AFP;
if ~isempty(G.af_r) && numel(G.af_r) ~= size(FP,2), G.af_r = []; G.af_ph = []; end
fprintf('gotcha_load: %d pulses x %d freqs from %d files; af corrections: %d\n', ...
    size(FP,2), size(FP,1), numel(files), ~isempty(G.af_r));
end