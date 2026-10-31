%% RUN_P4B_STAGE0  Phase 4b gates + timing pilot (see claude/phase4b-experiment-spec.md). Nothing here selects on the test set.
% Run from the project root with the p4b_*.m files, despeckle_filters.m, mstar_soc.mat on the path. Time: about 20 min.
%   G1 split / leakage tests          G2 pipeline unit tests (normalisation N, augmentation, determinism)
%   G3 Gamma-MAP bias (informational) G4 pilot: A0 validation accuracy vs epochs (seeds 1-3), A1 boxcar 7 timing
%   G5 replication gate: A0 under N, 300 epochs, seeds 1-5 on the test set vs the earlier raw_clip arm
clear; close all; clc;
cfg = p4b_config(); S = load(cfg.mat);
ok = struct();

%% G1 splits and leakage
fprintf('--- G1 splits ---\n'); g1 = true;
for seed = 1:20
    sp = p4b_make_splits(S.Ytr, 0.1, seed);
    g1 = g1 && isempty(intersect(sp.tr, sp.va)) && numel(sp.tr) == numel(unique(sp.tr)) && numel(sp.tr) == numel(sp.va);
    ct = histcounts(double(S.Ytr(sp.tr)), 0.5:1:10.5); cv = histcounts(double(S.Ytr(sp.va)), 0.5:1:10.5);
    g1 = g1 && all(ct == cv);
end
sp1 = p4b_make_splits(S.Ytr, 0.1, 1);
fprintf('seed 1: %d train, %d validation chips; class counts train: %s\n', numel(sp1.tr), numel(sp1.va), mat2str(histcounts(double(S.Ytr(sp1.tr)), 0.5:1:10.5)));
rng(7); w = single(randn(1, numel(S.Xtr(:,:,1,1))));
hTr = w * reshape(S.Xtr, [], size(S.Xtr, 4)); hTe = w * reshape(S.Xte, [], size(S.Xte, 4));
nDup = nnz(ismember(hTe, hTr));
fprintf('chips of the 15 deg test set that are bit-identical to a 17 deg training chip: %d\n', nDup);
ok.G1 = g1 && nDup == 0; fprintf('G1 %s\n', tern(ok.G1));

%% G2 pipeline unit tests
fprintf('\n--- G2 pipeline ---\n');
raw = S.Xtr(:, :, :, sp1.tr);
A0 = p4b_arm('A0', 'raw'); A1 = p4b_arm('A1', 'boxcar', 7);
[X0, Y0] = p4b_build_train(S, A0, sp1.tr, 1, cfg); [X1, Y1] = p4b_build_train(S, A1, sp1.tr, 1, cfg);
t1 = isequal(Y0, Y1) && isequal(size(X0), size(X1), [88 88 1 numel(sp1.tr)]);
t2 = all(X0(:) >= 0 & X0(:) <= 1) && all(X1(:) >= 0 & X1(:) <= 1);
frac1 = squeeze(mean(mean(X0 >= 1, 1), 2)); t3 = median(frac1) > 0.003 && median(frac1) < 0.02;
fprintf('same labels/shape for A0 and A1: %d | inputs in [0,1]: %d | share of clipped pixels per chip (median) %.2f %% (expect ~0.5): %d\n', t1, t2, 100*median(frac1), t3);
aug = struct('shift', true, 'noiseL', [1 4], 'blurSet', [1 3 5 7 9], 'K', 1);
Ya = p4b_augment(raw, aug, 88, 5, 8); Yb = p4b_augment(raw, aug, 88, 5, 8); Yc = p4b_augment(raw, aug, 88, 6, 8);
t4 = isequal(Ya, Yb) && ~isequal(Ya, Yc) && isequal(size(Ya), [88 88 1 numel(sp1.tr)]);
nz = struct('shift', false, 'noiseL', [1 4], 'blurSet', [], 'K', 1); Yn = p4b_augment(raw, nz, 88, 3, 8);
pw = mean(reshape(Yn.^2, [], size(Yn,4)), 1) ./ mean(reshape(p4b_crop(raw, 88).^2, [], size(raw,4)), 1);
t5 = abs(mean(pw) - 1) < 0.05;
nb = struct('shift', false, 'noiseL', [], 'blurSet', [1 3 5 7 9], 'K', 1); Yk = p4b_augment(raw, nb, 88, 3, 8);
cvr = std(reshape(Yk, [], size(Yk,4)), 0, 1) ./ mean(reshape(Yk, [], size(Yk,4)), 1);
t6 = max(cvr) > 1.2 * min(cvr);
fprintf('augmentation deterministic & seed-dependent: %d | noise preserves mean power (ratio %.3f): %d | random blur varies per chip: %d\n', t4, mean(pw), t5, t6);
ok.G2 = t1 && t2 && t3 && t4 && t5 && t6; fprintf('G2 %s\n', tern(ok.G2));

%% G3 Gamma-MAP bias on synthetic speckle (informational: the estimator is NOT expected to be unbiased)
fprintf('\n--- G3 synthetic speckle, L = 1, window 7 ---\n'); rng(3);
I = -log(rand(256, 256, 'single')); Ah = sqrt(I);
for m = {'lee', 'frost', 'gammamap'}
    Y = despeckle_filters(Ah, m{1}, 7, 1);
    fprintf('homogeneous scene %-9s mean bias %+.2f %%\n', m{1}, 100*(mean(Y(:).^2)/mean(I(:)) - 1));
end
fprintf('G3 INFO: Gamma-MAP bias is intrinsic (mode estimate + noisy regime switching); keep it exploratory, not in the primary family.\n');

%% G4 pilot: A0 validation accuracy vs epochs, seeds 1-3; A1 timing
fprintf('\n--- G4 pilot (validation only) ---\n');
Egrid = [150 300 600]; seeds = 1:3; V = nan(numel(seeds), numel(Egrid)); T = V;
for e = 1:numel(Egrid)
    for s = 1:numel(seeds)
        a = p4b_arm(sprintf('A0_e%d', Egrid(e)), 'raw'); a.epochs = Egrid(e); a.evalTest = false;
        r = p4b_run_arm(S, a, 0.1, seeds(s), cfg); V(s, e) = r.accVal; T(s, e) = r.tTrain;
    end
end
for s = 1:numel(seeds)
    a = p4b_arm('A1_val', 'boxcar', 7); a.epochs = 300; a.evalTest = false;
    r = p4b_run_arm(S, a, 0.1, seeds(s), cfg); VA1(s) = r.accVal; TA1(s) = r.tTrain; %#ok<SAGROW>
end
fprintf('A0 validation accuracy (mean of 3 seeds) by epochs: %s -> %s\n', mat2str(Egrid), mat2str(100*mean(V, 1), 4));
fprintf('A1 (boxcar 7, 300 epochs) validation accuracy %.2f %%, A0 (300 epochs) %.2f %%\n', 100*mean(VA1), 100*mean(V(:,2)));
tRun = mean(T(:, 2)); fprintf('time per 300-epoch run at 10 %%: %.0f s -> about 725 spec runs = %.1f h (augmented arms ~ the same)\n', tRun, 725*tRun/3600);
[~, ib] = max(mean(V, 1)); fprintf('best A0 epochs on validation: %d (differences below ~1 pp are noise with 3 seeds; keep 300 unless clearly worse)\n', Egrid(ib));

%% G5 replication gate: A0 under N, 300 epochs, seeds 1-5, test set
fprintf('\n--- G5 replication ---\n');
ref = [79.46 78.23 72.74 80.25 78.35];     % raw_clip arm of run_phase4_dose.m, seeds 1-5 (same subsets and normalisation)
acc = nan(1, 5);
for s = 1:5
    a = p4b_arm('A0rep', 'raw'); a.epochs = 300;
    r = p4b_run_arm(S, a, 0.1, s, cfg); acc(s) = 100*r.accTest;
end
fprintf('A0 under N: %.2f +/- %.2f %% vs earlier raw_clip %.2f %% (seeds 1-5); difference %+.2f pp (gate: within 2.9 pp)\n', mean(acc), std(acc), mean(ref), mean(acc) - mean(ref));
ok.G5 = abs(mean(acc) - mean(ref)) <= 2.9; fprintf('G5 %s\n', tern(ok.G5));

save('p4b_stage0.mat', 'ok', 'V', 'T', 'VA1', 'TA1', 'Egrid', 'acc', 'ref');
fprintf('\nSTAGE 0: G1 %s | G2 %s | G5 %s | G3 informational. Paste this whole output.\n', tern(ok.G1), tern(ok.G2), tern(ok.G5));

function s = tern(c)
if c, s = 'PASS'; else, s = 'FAIL'; end
end
