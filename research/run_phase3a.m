%% RUN_PHASE3A  Speckle in MSTAR chips: statistics, sub-look independence, classical filters.
% Run from the project root after mstar_prepare. Needs mstar_soc.mat, mstar_read.m, despeckle_filters.m.
% Gate before any despeckling experiment:
%   (1) clutter (chip corners) looks like fully developed speckle: amplitude std/mean ~ 0.52, intensity ~ 1
%   (2) two non-overlapping azimuth sub-bands give nearly uncorrelated speckle (usable as independent looks)
%   (3) Lee / Frost / Gamma-MAP raise the ENL in clutter without biasing the mean or erasing the target
% Orientation: the header says RadarPosition = bottom, and shadows point up, so ROWS = range, COLUMNS = azimuth.
clear; close all; clc; rng(1);
M = load('mstar_soc.mat', 'ptr', 'Ytr', 'classNames');
n = 300; sel = randperm(numel(M.ptr), n);
S = 128; P = 32;

%% load n complex chips (centre 128x128, same crop as mstar_prepare)
Z = zeros(S, S, n, 'single');
for k = 1:n
    [mg, ph] = mstar_read(char(M.ptr(sel(k))));
    r0 = floor((size(mg,1)-S)/2) + 1; c0 = floor((size(mg,2)-S)/2) + 1;
    mg = mg(r0:r0+S-1, c0:c0+S-1); ph = ph(r0:r0+S-1, c0:c0+S-1);
    Z(:,:,k) = mg .* exp(1j*ph);
end
A = abs(Z); I = A.^2;
fprintf('loaded %d complex chips\n', n);

%% 1. speckle statistics in the four 32x32 corners
a = reshape(corners(A, P), P*P, []); b = reshape(corners(I, P), P*P, []);
cvA = std(a, 0, 1) ./ mean(a, 1); cvI = std(b, 0, 1) ./ mean(b, 1);
Lest = 1 / median(cvI)^2;
fprintf('\n--- 1. clutter statistics (%d corner patches) ---\n', size(a, 2));
fprintf('amplitude std/mean: median %.3f  (IQR %.3f-%.3f)   fully developed speckle: 0.523\n', median(cvA), prctile(cvA, 25), prctile(cvA, 75));
fprintf('intensity std/mean: median %.3f  (IQR %.3f-%.3f)   single look: 1.000\n', median(cvI), prctile(cvI, 25), prctile(cvI, 75));
fprintf('equivalent number of looks L = 1/CV^2 = %.2f   (NOT a valid single-look estimate: clutter texture inflates the CV; keep the nominal L = 1)\n', Lest);
Cz = corners(Z, P);
pw = mean(mean(abs(Cz).^2, 1), 2);
rho_r = abs(mean(mean(Cz(1:end-1,:,:) .* conj(Cz(2:end,:,:)), 1), 2) ./ pw);
rho_a = abs(mean(mean(Cz(:,1:end-1,:) .* conj(Cz(:,2:end,:)), 1), 2) ./ pw);
fprintf('complex correlation of neighbouring pixels: range (rows) %.2f, azimuth (columns) %.2f  (1 = fully correlated)\n', ...
    median(squeeze(rho_r)), median(squeeze(rho_a)));
gate1 = abs(median(cvA) - 0.523) < 0.07;

%% 2. two azimuth sub-bands: are their speckle patterns independent?
F = fft(Z, [], 2);
Pw = fftshift(squeeze(mean(mean(abs(F).^2, 1), 3)));        % 1 x S mean azimuth power spectrum
cs = cumsum(Pw) / sum(Pw); k50 = find(cs >= 0.5, 1);
db = 10*log10(Pw / max(Pw));
fprintf('\n--- 2. azimuth sub-looks ---\n');
fprintf('azimuth spectrum: %d of %d bins within 20 dB of the peak; energy median at shifted bin %d of %d (centre = %d)\n', ...
    nnz(db > -20), S, k50, S, S/2 + 1);
% Intensity correlation is inflated by shared reflectivity texture, so the gate uses the complex coherence
% between sub-bands (texture-blind), compared with its chance floor (patches shuffled across chips).
% Positive control: overlapping bands must show high coherence, otherwise the metric is blind.
Zd = double(Z);
rD = subband_metrics(Zd, P, 3);       % disjoint bands, 3-bin guard
rW = subband_metrics(Zd, P, 12);      % disjoint bands, 12-bin guard
rO = subband_metrics(Zd, P, -10);     % overlapping bands (positive control)
fprintf('sub-look coherence, guard 3 : %.3f  (chance floor %.3f)   intensity corr %.3f\n', rD.coh, rD.cohShuf, rD.corrI);
fprintf('sub-look coherence, guard 12: %.3f  (chance floor %.3f)   intensity corr %.3f\n', rW.coh, rW.cohShuf, rW.corrI);
fprintf('sub-look coherence, OVERLAP : %.3f  (positive control, must be well above the floor)   intensity corr %.3f\n', rO.coh, rO.corrI);
fprintf('(intensity corr > 0 with coherence at the floor = shared texture, not dependent speckle)\n');
cc = [1 rD.corrI; rD.corrI 1];
gate2 = rD.coh < 3*rD.cohShuf + 0.02 && rO.coh > 0.3;

%% 3. classical filters
L = min(max(Lest, 1), 4); win = 7;
X4 = reshape(A, S, S, 1, n);
names = {'lee', 'frost', 'gammamap'};
I0 = corners(I, P);
enl0 = median(1 ./ (std(reshape(I0, P*P, []), 0, 1) ./ mean(reshape(I0, P*P, []), 1)).^2);
tgt = 41:88;
fprintf('\n--- 3. classical filters (window %d, L = %.2f) ---\n', win, L);
fprintf('%-9s %12s %10s %12s %14s %14s\n', 'filter', 'ENL gain', 'mean bias', 'ratio mean', 'target energy', 'target 99% px');
Y = cell(1, 3); gate3 = true(1, 3);
for q = 1:3
    Y{q} = squeeze(despeckle_filters(X4, names{q}, win, L));
    If = Y{q}.^2; Ic = corners(If, P);
    enl1 = median(1 ./ (std(reshape(Ic, P*P, []), 0, 1) ./ mean(reshape(Ic, P*P, []), 1)).^2);
    bias = sum(Ic(:)) / sum(I0(:)) - 1;
    Rr = I0 ./ max(Ic, eps('single'));
    rmean = median(squeeze(mean(mean(Rr, 1), 2)));
    e0 = squeeze(sum(sum(I(tgt, tgt, :), 1), 2)); e1 = squeeze(sum(sum(If(tgt, tgt, :), 1), 2));
    q0 = quantile(reshape(I(tgt, tgt, :), [], n), 0.99, 1); q1 = quantile(reshape(If(tgt, tgt, :), [], n), 0.99, 1);
    fprintf('%-9s %11.1fx %9.1f%% %12.3f %14.3f %14.3f\n', names{q}, enl1/enl0, 100*bias, rmean, median(e1 ./ e0), median(q1 ./ q0));
    gate3(q) = enl1/enl0 >= 3 && abs(bias) < 0.03;
end
fprintf('raw clutter ENL (median over corner patches): %.2f\n', enl0);

%% figure: 4 chips x (raw, lee, frost, gammamap)
pick = zeros(1, 4); cl = categories(M.Ytr(sel)); got = 0;
for c = randperm(numel(cl))
    i = find(M.Ytr(sel) == cl{c}, 1); if ~isempty(i), got = got + 1; pick(got) = i; end
    if got == 4, break; end
end
figure('Name', 'despeckle demo', 'Position', [50 50 1200 1200]); tiledlayout(4, 4, 'TileSpacing', 'none');
ttl = {'raw', 'Lee', 'Frost', 'Gamma-MAP'};
for r = 1:4
    lim = [0 prctile(reshape(A(:,:,pick(r)), [], 1), 99.5)];
    for c = 1:4
        nexttile;
        if c == 1, img = A(:,:,pick(r)); else, img = Y{c-1}(:,:,pick(r)); end
        imagesc(img, lim); axis image off; colormap gray;
        if r == 1, title(ttl{c}); end
    end
end
exportgraphics(gcf, 'despeckle_demo.png', 'Resolution', 150);
save('phase3a_results.mat', 'Lest', 'cvA', 'cvI', 'cc', 'k50');

fprintf('\nINFO 1 (clutter CV vs Rayleigh; CHECK = textured clutter, expected for MSTAR, informational only): %s | GATE 2 (sub-looks independent): %s | GATE 3 (ENL gain >= 3x, |bias| < 3%%): lee %s, frost %s, gammamap %s\n', ...
    tern(gate1), tern(gate2), tern(gate3(1)), tern(gate3(2)), tern(gate3(3)));
fprintf('Attach despeckle_demo.png and paste this whole output.\n');

%% local functions
function C = corners(X, P)
S = size(X, 1); n = size(X, 3); C = zeros(P, P, 4*n, 'like', X); k = 0;
rr = {1:P, S-P+1:S};
for a = 1:2
    for b = 1:2
        C(:,:,k*n+(1:n)) = X(rr{a}, rr{b}, :); k = k + 1;
    end
end
end

function s = tern(c)
if c, s = 'PASS'; else, s = 'CHECK'; end
end