%% RUN_P3B_MATCHED  Information-matched control for the MERLIN classification result (10 % data, seeds 1-10).
% WHY: the MERLIN network used in run_p4b_stage3m was trained (without labels) on ALL 17 deg training chips, while the classifier
%   sees only 275 labelled chips. The +1.6 pp over the augmentation bar could therefore be a semi-supervised effect (a prior learned
%   from unlabelled target imagery) instead of a better speckle filter.
% CONTROL: for every seed, train a fresh despeckler on ONLY that seed's 275 labelled chips (same architecture, 60 epochs, no
%   validation set), despeckle those 275 chips and the 15 deg test chips with it, then train the classifier with shift augmentation
%   (arm Mm1, same protocol as M1 / B1). Same splits and seeds as B1 / M1 / C1, so the contrasts are paired.
% PRE-SET READING: Mm1 - B1 CI lower bound > 0 -> a despeckler that never saw unlabelled data still helps (genuine despeckling gain);
%   Mm1 - B1 CI includes 0 while M1 - B1 > 0 -> the M1 gain came from the unlabelled data (semi-supervised), not from despeckling.
% Needs p3b_chips_train.mat (made by p3b_train_merlin), p3b_merlin.mat, mstar_soc.mat (pte), p4b_*.m, p3b_*.m.
% Time: about 4-5 min per seed (despeckler training about 3 min, the rest despeckling + classifier), about 45 min for 10 seeds; resumable.
% NOTE: validation accuracy printed by p4b_run_arm uses raw validation chips here (only training and test chips are despeckled) - ignore it.
% CAVEAT: 275 chips x 60 epochs is a much smaller training budget than the full despeckler (2447 chips x 40 epochs); a null result here
%   may partly reflect an under-trained despeckler, a positive result cannot.  Both are reported as such.
clear; close all; clc; clear functions;
cfg = p4b_config(); S = load(cfg.mat); Ms = load('p3b_merlin.mat', 's'); s = Ms.s;
C = load('p3b_chips_train.mat', 'Zr', 'Zi'); Sz = 128; frac = 0.1; seeds = 1:10;
if ~isfile('p3b_chips_test.mat')
    D = load('mstar_soc.mat', 'pte'); Nte = numel(D.pte); Tr = zeros(Sz, Sz, Nte, 'single'); Ti = Tr;
    for k = 1:Nte
        [mg, ph] = mstar_read(char(D.pte(k)));
        r0 = floor((size(mg,1)-Sz)/2) + 1; c0 = floor((size(mg,2)-Sz)/2) + 1;
        z = mg(r0:r0+Sz-1, c0:c0+Sz-1) .* exp(1j * ph(r0:r0+Sz-1, c0:c0+Sz-1)); Tr(:,:,k) = real(z); Ti(:,:,k) = imag(z);
    end
    save('p3b_chips_test.mat', 'Tr', 'Ti', '-v7.3');
end
T = load('p3b_chips_test.mat'); Nte = size(T.Tr, 3);
% self-check of the batch despeckler against the per-chip one (the control depends on them being the same function)
Mg = load('p3b_merlin.mat', 'net'); Rb = p3b_denoise_batch(Mg.net, C.Zr(:,:,1:5), C.Zi(:,:,1:5), s);
for q = 1:5
    R1 = single(p3b_denoise(Mg.net, complex(double(C.Zr(:,:,q)), double(C.Zi(:,:,q))), s));
    assert(max(abs(Rb(:,:,q) - R1), [], 'all') <= 1e-3 * max(R1, [], 'all'), 'p3b_denoise_batch disagrees with p3b_denoise on chip %d', q);
end
fprintf('batch despeckler agrees with p3b_denoise on 5 chips\n');
arm = p4b_arm('Mm1', 'raw'); arm.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', 10);
tAll = tic;
for sd = seeds
    f = fullfile(cfg.outdir, sprintf('Mm1_f%04d_s%02d.mat', round(1000*frac), sd));
    if isfile(f), continue; end
    sp = p4b_make_splits(S.Ytr, frac, sd); tr = sp.tr;
    net = train_small(C.Zr(:,:,tr) / s, C.Zi(:,:,tr) / s, sd);
    S2 = S;
    S2.Xtr(:,:,1,tr) = reshape(sqrt(p3b_denoise_batch(net, C.Zr(:,:,tr), C.Zi(:,:,tr), s)), 128, 128, 1, []);
    S2.Xte = reshape(sqrt(p3b_denoise_batch(net, T.Tr, T.Ti, s)), 128, 128, 1, Nte);
    clear functions;                              % test-set cache inside p4b_run_arm must not survive between seeds
    p4b_run_arm(S2, arm, frac, sd, cfg);
    fprintf('== seed %d done, %.0f min elapsed ==\n', sd, toc(tAll)/60);
end
clear functions;

fprintf('\nPaired contrasts on seeds %d-%d (test accuracy):\n', seeds(1), seeds(end));
Cn = {'Mm1 - B1 (despeckler trained on labelled chips only vs shift aug on raw)  <- PRIMARY', 'Mm1', 'B1';
      'Mm1 - M1 (labelled-only vs all-unlabelled despeckler training)', 'Mm1', 'M1';
      'Mm1 - C1 (vs random-blur augmentation, the Rule 4 bar)', 'Mm1', 'C1';
      'M1 - B1 (the earlier result on the same seeds)', 'M1', 'B1'};
for i = 1:size(Cn, 1)
    a = acc(cfg, Cn{i,2}, seeds, frac); b = acc(cfg, Cn{i,3}, seeds, frac); ok = ~isnan(a) & ~isnan(b); d = 100 * (a(ok) - b(ok)); n = numel(d);
    t = mean(d) / (std(d) / sqrt(n)); p = betainc((n-1) / ((n-1) + t^2), (n-1)/2, 0.5); h = tcrit(n-1) * std(d) / sqrt(n);
    fprintf('%-72s %+.2f pp  95%% CI [%+.2f, %+.2f]  n = %d  p = %.4f\n', Cn{i,1}, mean(d), mean(d)-h, mean(d)+h, n, p);
end
fprintf('arm means (seeds %d-%d): Mm1 %.2f %% | M1 %.2f %% | B1 %.2f %% | C1 %.2f %%\nPaste this whole output.\n', seeds(1), seeds(end), ...
    100*nanm(acc(cfg,'Mm1',seeds,frac)), 100*nanm(acc(cfg,'M1',seeds,frac)), 100*nanm(acc(cfg,'B1',seeds,frac)), 100*nanm(acc(cfg,'C1',seeds,frac)));

function net = train_small(Zr, Zi, seed)
rng(seed); S = size(Zr, 1); n = size(Zr, 3);
Xt = cat(4, p3b_input(reshape(Zr, S, S, 1, n)), p3b_input(reshape(Zi, S, S, 1, n)));
Tt = cat(4, reshape(Zi, S, S, 1, n), reshape(Zr, S, S, 1, n));
opts = trainingOptions('adam', 'InitialLearnRate', 1e-3, 'MaxEpochs', 60, 'MiniBatchSize', 16, 'Shuffle', 'every-epoch', ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.3, 'LearnRateDropPeriod', 20, ...
    'ExecutionEnvironment', 'auto', 'Verbose', false, 'Plots', 'none');
net = trainnet(Xt, Tt, dlnetwork(p3b_unet(S, 16)), @p3b_merlin_loss, opts);
end
function a = acc(cfg, name, seeds, frac)
a = nan(1, numel(seeds));
for i = 1:numel(seeds)
    f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', name, round(1000*frac), seeds(i)));
    if isfile(f), t = load(f); a(i) = t.r.accTest(1); end
end
end
function m = nanm(x), x = x(~isnan(x)); m = mean(x); end
function q = tcrit(df)
lo = 0; hi = 100;
for i = 1:80, mid = (lo+hi)/2; if betainc(df/(df+mid^2), df/2, 0.5) > 0.05, lo = mid; else, hi = mid; end, end
q = (lo+hi)/2;
end
