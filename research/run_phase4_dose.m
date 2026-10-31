%% RUN_PHASE4_DOSE  Why does a boxcar beat Lee at 10 % data?  Dose-response + normalisation control + full-data check.
% PROTOCOL (fixed before running):
%   A. 10 % regime, seeds 1..10 (subset seed 2000 + seed, 300 epochs, as before), train and test both transformed:
%        boxcar 3, boxcar 9, boxcar 11 (intensity mean, then sqrt)   -> dose-response with the 5 and 7 already run
%        raw_clip: RAW chips scaled by their own 99.5th percentile and clipped at 1.
%          train_cnn divides every chip by its maximum; a smoothed chip has a much lower maximum than a raw chip
%          (single bright speckle spike), so smoothing also changes the effective input contrast. raw_clip gives raw
%          chips a robust normalisation (the spike no longer sets the scale) without any smoothing.
%   B. Full training set, boxcar 7, seeds 1..5: does the smoothing gain survive when data is plentiful?
%   References (RR, boxcar 5/7) come from phase4_10pct_20seeds.mat, phase4_smooth.mat, phase4_classical.mat.
%   Reading: gain growing with window size                -> low-pass regularisation, not speckle statistics.
%            raw_clip gaining most of the boxcar gain      -> the 'smoothing' gain was largely a normalisation effect.
%            raw_clip about equal to RR                    -> normalisation is not the explanation.
% Needs: mstar_soc.mat and the three .mat files above, train_cnn.m, predict_cnn.m. Time: about 50 min.
clear; close all; clc;
seedsA = 1:10; fracA = 0.1; epochsA = 300; winsA = [3 9 11]; crop = 88; seedsB = 1:5;

S = load('mstar_soc.mat'); P = load('phase4_10pct_20seeds.mat'); Sm = load('phase4_smooth.mat'); P4 = load('phase4_classical.mat');
c0 = (size(S.Xtr, 1) - crop)/2; ix = c0+1 : c0+crop;
cropf = @(X) X(ix, ix, :, :);
box = @(X, w) sqrt(max(convn(X.^2, ones(w)/w^2, 'same'), 0));

%% A. dose-response at 10 %
names = [arrayfun(@(w) sprintf('boxcar%d', w), winsA, 'UniformOutput', false), {'raw_clip'}];
XtrA = cell(1, numel(names)); XteA = XtrA;
for k = 1:numel(winsA)
    XtrA{k} = cropf(box(S.Xtr, winsA(k))); XteA{k} = cropf(box(S.Xte, winsA(k)));
end
XtrA{end} = clip_norm(cropf(S.Xtr)); XteA{end} = clip_norm(cropf(S.Xte));
QA = nan(numel(seedsA), numel(names)); tAll = tic;
for s = 1:numel(seedsA)
    seed = seedsA(s); idx = subset(S.Ytr, fracA, 2000 + seed);
    for k = 1:numel(names)
        QA(s, k) = train1_cnn(XtrA{k}(:,:,:,idx), S.Ytr(idx), XteA{k}, S.Yte, seed, epochsA, false);
    end
    msg = '';
    for k = 1:numel(names), msg = [msg sprintf('%s %.2f  ', names{k}, 100*QA(s,k))]; end %#ok<AGROW>
    fprintf('A: seed %2d done (%s), %.0f s elapsed\n', seed, strtrim(msg), toc(tAll));
    save('phase4_dose.mat', 'QA', 'names', 'seedsA');
end

%% B. full data, boxcar 7
XtrB = cropf(box(S.Xtr, 7)); XteB = cropf(box(S.Xte, 7));
QB = nan(numel(seedsB), 1);
for s = 1:numel(seedsB)
    QB(s) = train1_cnn(XtrB, S.Ytr, XteB, S.Yte, seedsB(s), 30, false);
    fprintf('B: seed %d done (boxcar7 full data %.2f %%), %.0f s elapsed\n', seedsB(s), 100*QB(s), toc(tAll));
    save('phase4_dose.mat', 'QA', 'QB', 'names', 'seedsA', 'seedsB');
end

%% report
RR = P.R(seedsA, 1);
fprintf('\n=== A. 10 %% data, seeds 1..10, paired differences to raw (RR %.2f %%) ===\n', 100*mean(RR));
fprintf('boxcar  5 (from 20-seed run): %.2f %%  diff %+.2f pp\n', 100*mean(Sm.Q(seedsA,1)), 100*mean(Sm.Q(seedsA,1) - RR));
fprintf('boxcar  7 (from 20-seed run): %.2f %%  diff %+.2f pp\n', 100*mean(Sm.Q(seedsA,3)), 100*mean(Sm.Q(seedsA,3) - RR));
fprintf('Lee FF    (from 20-seed run): %.2f %%  diff %+.2f pp\n', 100*mean(P.R(seedsA,3)), 100*mean(P.R(seedsA,3) - RR));
for k = 1:numel(names)
    d = 100*(QA(:,k) - RR); n = numel(d); [~, p] = ttest(d);
    ci = mean(d) + tinv(0.975, n-1)*std(d)/sqrt(n)*[-1 1];
    fprintf('%-9s %.2f +/- %.2f %%  diff to RR %+.2f pp  95%% CI [%+.2f, %+.2f]  p = %.4f\n', names{k}, 100*mean(QA(:,k)), 100*std(QA(:,k)), mean(d), ci(1), ci(2), p);
end
RRb = P4.R(1, seedsB, 1).';
d = 100*(QB - RRb); n = numel(d); [~, p] = ttest(d);
ci = mean(d) + tinv(0.975, n-1)*std(d)/sqrt(n)*[-1 1];
fprintf('\n=== B. full data, seeds 1..5 ===\nRR %.2f %%   boxcar7 %.2f +/- %.2f %%   diff %+.2f pp  95%% CI [%+.2f, %+.2f]  p = %.4f\n', ...
    100*mean(RRb), 100*mean(QB), 100*std(QB), mean(d), ci(1), ci(2), p);
fprintf('\nsaved phase4_dose.mat. Paste this whole output.\n');

%% local functions
function Y = clip_norm(X)
% scale each chip by its own 99.5th percentile and clip at 1 (robust normalisation; train_cnn's max-scaling then leaves it unchanged)
N = size(X, 4); p = prctile(reshape(X, [], N), 99.5, 1); p = max(p, eps('single'));
Y = min(X ./ reshape(p, 1, 1, 1, N), 1);
end

function idx = subset(Y, frac, sd)
rng(sd); idx = []; cl = categories(Y);
for c = 1:numel(cl)
    ii = find(Y == cl{c}); ii = ii(randperm(numel(ii)));
    idx = [idx; ii(1:max(1, round(frac*numel(ii))))]; %#ok<AGROW>
end
idx = sort(idx);
end