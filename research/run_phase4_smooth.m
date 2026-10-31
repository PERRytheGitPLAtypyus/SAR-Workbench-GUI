%% RUN_PHASE4_SMOOTH  Is the Lee/Frost gain at 10 % data speckle removal, or just generic smoothing?
% PROTOCOL (fixed before running):
%   Same 10 % regime, seeds 1..20, subset seed 2000 + seed, 300 epochs as run_phase4_20seeds.m.
%   Control filters that know nothing about speckle: boxcar mean of the INTENSITY (5x5 and 7x7), then sqrt.
%   The reference models (RR and the Lee FF numbers) are read from phase4_10pct_20seeds.mat (same seeds/subsets).
%   Reading: if boxcar FF gains as much as Lee FF (about +2 pp), the gain is input smoothing / regularisation,
%   not speckle-aware filtering. If boxcar gains clearly less, adaptivity (edge/target preservation) matters.
% Needs: mstar_soc.mat, phase4_10pct_20seeds.mat, train_cnn.m, predict_cnn.m. Time: about 25-30 min.
clear; close all; clc;
seeds = 1:20; frac = 0.1; crop = 88; epochs = round(30/frac); wins = [5 7];

S = load('mstar_soc.mat'); P = load('phase4_10pct_20seeds.mat');
assert(isequal(P.seeds, seeds), 'seed list differs from phase4_10pct_20seeds.mat');
c0 = (size(S.Xtr, 1) - crop)/2; ix = c0+1 : c0+crop;
cropf = @(X) X(ix, ix, :, :);
XtrR = cropf(S.Xtr); XteR = cropf(S.Xte);
nw = numel(wins); XtrB = cell(1, nw); XteB = cell(1, nw);
for w = 1:nw
    K = ones(wins(w)) / wins(w)^2;
    XtrB{w} = cropf(sqrt(max(convn(S.Xtr.^2, K, 'same'), 0)));
    XteB{w} = cropf(sqrt(max(convn(S.Xte.^2, K, 'same'), 0)));
end
cls = categories(S.Ytr);

Q = nan(numel(seeds), 2*nw);      % columns: [FF FR] per window
tAll = tic;
for s = 1:numel(seeds)
    seed = seeds(s);
    idx = subset(S.Ytr, frac, 2000 + seed);
    for w = 1:nw
        [accFF, ~, netB] = train1_cnn(XtrB{w}(:,:,:,idx), S.Ytr(idx), XteB{w}, S.Yte, seed, epochs, false);
        accFR = mean(predict_cnn(netB, XteR, cls) == S.Yte);
        Q(s, 2*w-1:2*w) = [accFF accFR];
    end
    fprintf('seed %2d done (boxcar %d FF %.2f %%, boxcar %d FF %.2f %%), %.0f s elapsed\n', seed, wins(1), 100*Q(s,1), wins(2), 100*Q(s,3), toc(tAll));
    save('phase4_smooth.mat', 'Q', 'seeds', 'wins');
end

%% report (all paired by seed)
RR = P.R(:, 1); leeFF = P.R(:, 3); frostFF = P.R(:, 6);
fprintf('\n=== 10 %% training subset, 20 seeds: generic smoothing vs speckle filters ===\n');
fprintf('RR %.2f +/- %.2f %%   Lee FF %.2f %%   Frost FF %.2f %%\n', 100*mean(RR), 100*std(RR), 100*mean(leeFF), 100*mean(frostFF));
for w = 1:nw
    show('boxcar FF - RR    ', Q(:, 2*w-1) - RR, wins(w));
    show('boxcar FF - Lee FF', Q(:, 2*w-1) - leeFF, wins(w));
    fprintf('boxcar %d  FF %.2f %%  FR (train smoothed / test raw) %.2f %%\n', wins(w), 100*mean(Q(:,2*w-1)), 100*mean(Q(:,2*w)));
end
fprintf('\nsaved phase4_smooth.mat. Paste this whole output.\n');

%% local functions
function show(lbl, d, win)
d = 100 * d; n = numel(d); [~, p] = ttest(d);
ci = mean(d) + tinv(0.975, n-1) * std(d) / sqrt(n) * [-1 1];
fprintf('win %d  %s  %+.2f pp  95%% CI [%+.2f, %+.2f]  p = %.4f\n', win, lbl, mean(d), ci(1), ci(2), p);
end

function idx = subset(Y, frac, sd)
rng(sd); idx = []; cl = categories(Y);
for c = 1:numel(cl)
    ii = find(Y == cl{c}); ii = ii(randperm(numel(ii)));
    idx = [idx; ii(1:max(1, round(frac*numel(ii))))]; %#ok<AGROW>
end
idx = sort(idx);
end
