%% RUN_P4B_SMOOTH_CTRL  Is the MERLIN gain just "stronger smoothing"?  Lee 15 and boxcar 9 + shift augmentation vs MERLIN + shift augmentation.
% Arms (10 % data, seeds 1-20, same splits as B1 / M1): E1_lee15 = Lee 15 on train and test chips + shift aug, E1_box9 = boxcar 9 + shift aug.
% Lee 15 has ENL gain 5.9 and keeps peaks (0.85); boxcar 9 has ENL gain 14 but destroys peaks (0.52); MERLIN has 21 and keeps them (0.93).
% READING (fixed before running):
%   E1_lee15 - B1 CI lower bound > 0     -> plain stronger adaptive smoothing already helps on top of augmentation (then the MERLIN gain is partly generic).
%   M1 - E1_lee15 CI lower bound > 0 and M1 - E1_box9 CI lower bound > 0 -> MERLIN beats both a peak-preserving and a high-ENL smoother: not just smoothing.
%   M1 - E1_lee15 CI includes 0          -> the MERLIN advantage over a well-tuned classical filter is not established.
% Needs the M1 / B1 runs (run_p4b_stage3m).  Time: 2 arms x 20 seeds x about 35 s = about 25 min; resumable.
clear; close all; clc; clear functions;
cfg = p4b_config(); S = load(cfg.mat); frac = 0.1; K = 10; seeds = 1:20; tAll = tic;
a1 = p4b_arm('E1_lee15', 'lee', 15);    a1.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K);
a2 = p4b_arm('E1_box9', 'boxcar', 9);   a2.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K);
for sd = seeds
    p4b_run_arm(S, a1, frac, sd, cfg); p4b_run_arm(S, a2, frac, sd, cfg);
end
clear functions;
fprintf('\n%.0f min.  arm means (seeds 1-20): B1 %.2f | E1_lee (Lee 7) %.2f | E1_lee15 %.2f | E1_box9 %.2f | C1 %.2f | M1 %.2f %%\n', toc(tAll)/60, ...
    100*nanm(acc(cfg,'B1',seeds,frac)), 100*nanm(acc(cfg,'E1_lee',seeds,frac)), 100*nanm(acc(cfg,'E1_lee15',seeds,frac)), ...
    100*nanm(acc(cfg,'E1_box9',seeds,frac)), 100*nanm(acc(cfg,'C1',seeds,frac)), 100*nanm(acc(cfg,'M1',seeds,frac)));
Cn = {'E1_lee15 - B1 (Lee 15 + shift aug vs shift aug)', 'E1_lee15', 'B1'; 'E1_box9 - B1 (boxcar 9 + shift aug vs shift aug)', 'E1_box9', 'B1';
      'M1 - E1_lee15 (MERLIN vs Lee 15)  <- PRIMARY', 'M1', 'E1_lee15'; 'M1 - E1_box9 (MERLIN vs boxcar 9)', 'M1', 'E1_box9';
      'E1_lee15 - C1 (Lee 15 + shift aug vs blur aug)', 'E1_lee15', 'C1'};
for i = 1:size(Cn, 1)
    a = acc(cfg, Cn{i,2}, seeds, frac); b = acc(cfg, Cn{i,3}, seeds, frac); ok = ~isnan(a) & ~isnan(b); d = 100 * (a(ok) - b(ok)); n = numel(d);
    t = mean(d) / (std(d) / sqrt(n)); p = betainc((n-1) / ((n-1) + t^2), (n-1)/2, 0.5); h = tcrit(n-1) * std(d) / sqrt(n);
    fprintf('%-58s %+.2f pp  95%% CI [%+.2f, %+.2f]  n = %d  p = %.4f\n', Cn{i,1}, mean(d), mean(d)-h, mean(d)+h, n, p);
end
fprintf('Paste this whole output.\n');

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
