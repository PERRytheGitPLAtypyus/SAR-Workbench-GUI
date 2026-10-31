%% RUN_P4B_STAGE3M  Downstream check: does MERLIN despeckling add anything on top of augmentation? (10 % data, seeds 1-20)
% Arms: M0 = MERLIN-despeckled chips, no augmentation; M1 = MERLIN-despeckled chips + shift augmentation (compare with B1 = shift
% augmentation on raw chips, and with C1 / A0 / Lee). Train AND test chips are despeckled, as for every filtering arm.
% PRE-SET RULE: M1 - B1 CI lower bound > 0 -> MERLIN adds something on top of augmentation; otherwise: null, as for Lee / boxcar.
%   Rule 4 bar for a classification claim: M1 must also beat C1 (85.40 %).
% First run builds mstar_merlin.mat (complex chips are read once and cached: p3b_chips_test.mat). Time: 5-8 min + 40 runs x 32 s.
clear; close all; clc; clear functions;          % 'clear functions' empties the test-set cache inside p4b_run_arm
cfg = p4b_config(); S = load(cfg.mat);
if ~isfile('mstar_merlin.mat')
    Mg = load('p3b_merlin.mat', 'net', 's'); net = Mg.net; s = Mg.s; Sz = 128;
    C = load('p3b_chips_train.mat', 'Zr', 'Zi'); Ntr = size(C.Zr, 3);
    Xtr_m = zeros(Sz, Sz, 1, Ntr, 'single');
    for k = 1:Ntr, Xtr_m(:,:,1,k) = sqrt(single(p3b_denoise(net, complex(double(C.Zr(:,:,k)), double(C.Zi(:,:,k))), s))); end
    clear C;
    D = load('mstar_soc.mat', 'pte'); Nte = numel(D.pte); Xte_m = zeros(Sz, Sz, 1, Nte, 'single'); Xte_raw = Xte_m;
    for k = 1:Nte
        [mg, ph] = mstar_read(char(D.pte(k)));
        r0 = floor((size(mg,1)-Sz)/2) + 1; c0 = floor((size(mg,2)-Sz)/2) + 1;
        z = double(mg(r0:r0+Sz-1, c0:c0+Sz-1)) .* exp(1j * double(ph(r0:r0+Sz-1, c0:c0+Sz-1)));
        Xte_m(:,:,1,k) = sqrt(single(p3b_denoise(net, z, s))); Xte_raw(:,:,1,k) = single(abs(z));
    end
    fprintf('consistency: max |chip magnitude - mstar_soc.mat| on test chips = %.3g (should be ~0)\n', max(abs(Xte_raw(:) - S.Xte(:))));
    save('mstar_merlin.mat', 'Xtr_m', 'Xte_m', '-v7.3');
end
Mm = load('mstar_merlin.mat'); S2 = S; S2.Xtr = Mm.Xtr_m; S2.Xte = Mm.Xte_m; clear Mm;
a0 = p4b_arm('M0', 'raw');
a1 = p4b_arm('M1', 'raw'); a1.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', 10);
tAll = tic;
for sd = 1:20
    p4b_run_arm(S2, a0, 0.1, sd, cfg); p4b_run_arm(S2, a1, 0.1, sd, cfg);
end
clear functions;                                  % do not leave MERLIN test chips in the cache for later runs
fprintf('\n%.0f min. Paired contrasts (test accuracy, 20 seeds):\n', toc(tAll)/60);
C = {'M0 - A0 (MERLIN vs raw)', 'M0', 'A0'; 'M1 - B1 (MERLIN + shift aug vs shift aug on raw)  <- PRIMARY', 'M1', 'B1';
     'M1 - C1 (vs random-blur augmentation, the Rule 4 bar)', 'M1', 'C1'; 'M1 - E1_lee (vs Lee + shift aug)', 'M1', 'E1_lee';
     'M0 - A3_lee (MERLIN vs Lee, no augmentation)', 'M0', 'A3_lee'};
for i = 1:size(C, 1)
    a = acc(cfg, C{i,2}); b = acc(cfg, C{i,3}); ok = ~isnan(a) & ~isnan(b); d = 100 * (a(ok) - b(ok)); n = numel(d);
    t = mean(d) / (std(d) / sqrt(n)); p = betainc((n-1) / ((n-1) + t^2), (n-1)/2, 0.5); h = tcrit(n-1) * std(d) / sqrt(n);
    try, pw = signrank(d); catch, pw = NaN; end
    fprintf('%-66s %+.2f pp  95%% CI [%+.2f, %+.2f]  n = %d  p = %.4f  Wilcoxon p = %.4f\n', C{i,1}, mean(d), mean(d)-h, mean(d)+h, n, p, pw);
end
fprintf('arm means: M0 %.2f %% | M1 %.2f %% | B1 %.2f %% | C1 %.2f %% | A0 %.2f %%\n', 100*nanm(acc(cfg,'M0')), 100*nanm(acc(cfg,'M1')), 100*nanm(acc(cfg,'B1')), 100*nanm(acc(cfg,'C1')), 100*nanm(acc(cfg,'A0')));
fprintf('Paste this whole output.\n');

function a = acc(cfg, name)
a = nan(1, 20);
for s = 1:20
    f = fullfile(cfg.outdir, sprintf('%s_f0100_s%02d.mat', name, s));
    if isfile(f), t = load(f); a(s) = t.r.accTest(1); end
end
end
function m = nanm(x), x = x(~isnan(x)); m = mean(x); end
function q = tcrit(df)
lo = 0; hi = 100;
for i = 1:80, mid = (lo+hi)/2; if betainc(df/(df+mid^2), df/2, 0.5) > 0.05, lo = mid; else, hi = mid; end, end
q = (lo+hi)/2;
end
