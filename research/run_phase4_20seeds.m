%% RUN_PHASE4_20SEEDS  Phase 4 low-data regime with 20 seeds (the 5-seed run was underpowered).
% PROTOCOL (fixed before running; same as run_phase4_classical.m except the seed count):
%   10 % stratified training subset (same subset for raw and filtered models of one seed; the subset seed is
%   2000 + seed, identical to the one used for fraction 0.1 in run_phase4_classical.m, so seeds 1..5 repeat that run),
%   300 epochs, Lee / Frost / Gamma-MAP, window 7, L = 1 (nominal single look; the CV-based estimate 0.65 is
%   inflated by clutter texture and is not used), seeds 1..20.
%   PRIMARY outcome: FF - RR per filter (Bonferroni over the 3 filters). RF and FR are reported as secondary.
% Time: about 45-60 min (80 trainings, each about the cost of a 30-epoch full-data run).
clear; close all; clc;
L = 1; win = 7; filters = {'lee', 'frost', 'gammamap'}; seeds = 1:20; frac = 0.1; crop = 88; epochs = round(30/frac);

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

R = nan(numel(seeds), 1 + 3*nf);
tAll = tic;
for s = 1:numel(seeds)
    seed = seeds(s);
    idx = subset(S.Ytr, frac, 2000 + seed);
    [R(s,1), ~, netR] = train1_cnn(XtrR(:,:,:,idx), S.Ytr(idx), XteR, S.Yte, seed, epochs, false);
    for f = 1:nf
        accRF = mean(predict_cnn(netR, XteF{f}, cls) == S.Yte);
        [accFF, ~, netF] = train1_cnn(XtrF{f}(:,:,:,idx), S.Ytr(idx), XteF{f}, S.Yte, seed, epochs, false);
        accFR = mean(predict_cnn(netF, XteR, cls) == S.Yte);
        R(s,1+3*(f-1)+(1:3)) = [accRF accFF accFR];
    end
    fprintf('seed %2d done (RR %.2f %%), %.0f s elapsed\n', seed, 100*R(s,1), toc(tAll));
    save('phase4_10pct_20seeds.mat', 'R', 'seeds', 'filters', 'L', 'win', 'frac');
end

fprintf('\n=== 10 %% training subset (%d chips), %d seeds ===\n', numel(subset(S.Ytr, frac, 1)), numel(seeds));
paired_report(R, filters);
fprintf('\nsaved phase4_10pct_20seeds.mat. Paste this whole output.\n');

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
