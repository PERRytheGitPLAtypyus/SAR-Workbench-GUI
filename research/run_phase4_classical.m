%% RUN_PHASE4_CLASSICAL  Does classical despeckling change MSTAR SOC classification accuracy?
% PRE-REGISTERED PROTOCOL (fixed before any result was seen; do not edit after running):
%   data       mstar_soc.mat: train 17 deg (2747), test 15 deg (2425), 10 classes, centre 88x88 crop
%   filters    Lee, Frost, Gamma-MAP, window 7, L = the value printed by run_phase3a (set below).
%              Parameters come from the speckle statistics, never from classification accuracy.
%   conditions RR train raw / test raw (reference)      FF train filtered / test filtered
%              RF train raw / test filtered             FR train filtered / test raw
%   regimes    full training set (fraction 1.0) and a 10 % stratified subset (fraction 0.1; same subset
%              for raw and filtered models of one seed)
%   seeds      1..5
%   outcome    test accuracy; per-seed paired difference to RR -> mean, 95 % t-interval, paired t-test,
%              Bonferroni over the 9 comparisons of a regime (3 filters x RF/FF/FR)
%   CNN        train_cnn.m, 30 epochs (scaled by 1/fraction), no augmentation, test set used once per model
% Run from the project root with mstar_soc.mat, train_cnn.m, predict_cnn.m and despeckle_filters.m present.
% Time: roughly 20-30 minutes.
clear; close all; clc;
L = 1;                      % <-- set to the L printed by run_phase3a (section 1)
win = 7; filters = {'lee', 'frost', 'gammamap'}; seeds = 1:5; fracs = [1 0.1]; crop = 88;

S = load('mstar_soc.mat');
c0 = (size(S.Xtr, 1) - crop)/2; ix = c0+1 : c0+crop;
cls = categories(S.Ytr); nf = numel(filters);
cropf = @(X) X(ix, ix, :, :);
XtrR = cropf(S.Xtr); XteR = cropf(S.Xte);
XtrF = cell(1, nf); XteF = cell(1, nf);
for f = 1:nf
    XtrF{f} = cropf(despeckle_filters(S.Xtr, filters{f}, win, L));
    XteF{f} = cropf(despeckle_filters(S.Xte, filters{f}, win, L));
end
fprintf('filtered all chips (window %d, L = %.2f)\n', win, L);

R = nan(numel(fracs), numel(seeds), 1 + 3*nf);   % columns: RR, then [RF FF FR] for each filter
tAll = tic;
for q = 1:numel(fracs)
    frac = fracs(q); epochs = round(30 / frac);
    for s = 1:numel(seeds)
        seed = seeds(s);
        idx = subset(S.Ytr, frac, 1000*q + seed);
        [R(q,s,1), ~, netR] = train1_cnn(XtrR(:,:,:,idx), S.Ytr(idx), XteR, S.Yte, seed, epochs, false);
        for f = 1:nf
            accRF = mean(predict_cnn(netR, XteF{f}, cls) == S.Yte);
            [accFF, ~, netF] = train1_cnn(XtrF{f}(:,:,:,idx), S.Ytr(idx), XteF{f}, S.Yte, seed, epochs, false);
            accFR = mean(predict_cnn(netF, XteR, cls) == S.Yte);
            R(q,s,1+3*(f-1)+(1:3)) = [accRF accFF accFR];
        end
        fprintf('fraction %.1f, seed %d done (RR %.2f %%), %.0f s elapsed\n', frac, seed, 100*R(q,s,1), toc(tAll));
        save('phase4_classical.mat', 'R', 'fracs', 'seeds', 'filters', 'L', 'win');
    end
end

%% report
nS = numel(seeds); cond = {'RF', 'FF', 'FR'};
for q = 1:numel(fracs)
    A = squeeze(R(q, :, :));
    fprintf('\n=== training fraction %.1f (%d chips), %d seeds ===\n', fracs(q), numel(subset(S.Ytr, fracs(q), 1)), nS);
    fprintf('RR (reference)             %.2f +/- %.2f %%\n', 100*mean(A(:,1)), 100*std(A(:,1)));
    for f = 1:nf
        for k = 1:3
            col = 1 + 3*(f-1) + k;
            d = 100 * (A(:,col) - A(:,1));
            [~, p] = ttest(d);
            ci = mean(d) + tinv(0.975, nS-1) * std(d) / sqrt(nS) * [-1 1];
            fprintf('%-9s %s  %.2f +/- %.2f %%   diff to RR %+.2f pp  95%% CI [%+.2f, %+.2f]  p = %.3f (Bonferroni %.3f)\n', ...
                filters{f}, cond{k}, 100*mean(A(:,col)), 100*std(A(:,col)), mean(d), ci(1), ci(2), p, min(1, 9*p));
        end
    end
end
fprintf('\nsaved phase4_classical.mat. Paste this whole output.\n');

%% local functions
function idx = subset(Y, frac, sd)
% stratified training subset (all chips when frac >= 1)
if frac >= 1, idx = (1:numel(Y)).'; return; end
rng(sd); idx = []; cl = categories(Y);
for c = 1:numel(cl)
    ii = find(Y == cl{c}); ii = ii(randperm(numel(ii)));
    idx = [idx; ii(1:max(1, round(frac*numel(ii))))]; %#ok<AGROW>
end
idx = sort(idx);
end
