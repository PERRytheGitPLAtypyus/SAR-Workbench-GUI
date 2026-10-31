%% RUN_P4B_ARCH  Second architecture: does the MERLIN gain survive with an A-ConvNets-style all-convolutional classifier?
% Arms (all 10 % data, seeds 1-10, same splits as the 4-block CNN runs): A0_ac raw | B1_ac shift aug | C1_ac random-blur aug |
% M1_ac MERLIN-despeckled chips + shift aug.  Needs mstar_merlin.mat (run_p4b_stage3m) and the updated p4b_train / p4b_arm / p4b_run_arm.
% READING (fixed before running):
%   - first a sanity check: A0_ac must reach a plausible accuracy (> 60 %); otherwise the network did not train, nothing below is interpretable.
%   - M1_ac - B1_ac CI lower bound > 0 -> the MERLIN gain over shift augmentation replicates on a second architecture.
%     M1_ac - C1_ac CI lower bound > 0 -> it also clears the blur-augmentation bar there.  Otherwise: the gain is specific to the 4-block CNN.
%   - absolute accuracies of the two architectures are NOT compared with each other (different capacity / regularisation).
% Time: about 10-15 min per 10 runs of each arm (about 1 h in total); resumable.
clear; close all; clc; clear functions;
cfg = p4b_config(); S = load(cfg.mat); seeds = 1:10; frac = 0.1; K = 10; tAll = tic;
assert(isfile('mstar_merlin.mat'), 'mstar_merlin.mat missing: run run_p4b_stage3m first');
keys = {'A0', 'B1', 'C1'};
for sd = seeds
    for k = 1:numel(keys)
        a = p4b_arms(keys{k}); a.name = [keys{k} '_ac']; a.arch = 'aconv';
        p4b_run_arm(S, a, frac, sd, cfg);
    end
    fprintf('== raw arms seed %d done, %.0f min elapsed ==\n', sd, toc(tAll)/60);
end
clear functions;                                   % empties the test-set cache inside p4b_run_arm
Mm = load('mstar_merlin.mat'); S2 = S; S2.Xtr = Mm.Xtr_m; S2.Xte = Mm.Xte_m; clear Mm;
for sd = seeds
    a = p4b_arm('M1_ac', 'raw'); a.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K); a.arch = 'aconv';
    p4b_run_arm(S2, a, frac, sd, cfg);
    fprintf('== M1_ac seed %d done, %.0f min elapsed ==\n', sd, toc(tAll)/60);
end
clear functions;

%% report
nm = {'A0_ac', 'B1_ac', 'C1_ac', 'M1_ac'}; ref = {'A0', 'B1', 'C1', 'M1'};
fprintf('\n--- arm means, seeds %d-%d, 10 %% data ---\n', seeds(1), seeds(end));
for k = 1:4
    a = acc(cfg, nm{k}, seeds, frac); b = acc(cfg, ref{k}, seeds, frac);
    fprintf('%-6s A-ConvNets-style %.2f +/- %.2f %%   (4-block CNN, same seeds: %.2f %%)\n', nm{k}, 100*mean(a, 'omitnan'), 100*std(a, 'omitnan'), 100*mean(b, 'omitnan'));
end
if mean(acc(cfg, 'A0_ac', seeds, frac), 'omitnan') < 0.6, fprintf('SANITY FAIL: A0_ac below 60 %% -> the all-conv net did not train; do not interpret the contrasts.\n'); end
Cn = {'B1_ac - A0_ac (shift aug vs raw)', 'B1_ac', 'A0_ac'; 'C1_ac - A0_ac (blur aug vs raw)', 'C1_ac', 'A0_ac';
      'M1_ac - B1_ac (MERLIN + shift aug vs shift aug)  <- PRIMARY', 'M1_ac', 'B1_ac'; 'M1_ac - C1_ac (vs blur aug, the Rule 4 bar)', 'M1_ac', 'C1_ac'};
fprintf('\n--- paired contrasts (test accuracy) ---\n');
for i = 1:size(Cn, 1)
    a = acc(cfg, Cn{i,2}, seeds, frac); b = acc(cfg, Cn{i,3}, seeds, frac); ok = ~isnan(a) & ~isnan(b); d = 100 * (a(ok) - b(ok)); n = numel(d);
    t = mean(d) / (std(d) / sqrt(n)); p = betainc((n-1) / ((n-1) + t^2), (n-1)/2, 0.5); h = tcrit(n-1) * std(d) / sqrt(n);
    fprintf('%-62s %+.2f pp  95%% CI [%+.2f, %+.2f]  n = %d  p = %.4f\n', Cn{i,1}, mean(d), mean(d)-h, mean(d)+h, n, p);
end
fprintf('Paste this whole output.\n');

function a = acc(cfg, name, seeds, frac)
a = nan(1, numel(seeds));
for i = 1:numel(seeds)
    f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', name, round(1000*frac), seeds(i)));
    if isfile(f), t = load(f); a(i) = t.r.accTest(1); end
end
end
function q = tcrit(df)
lo = 0; hi = 100;
for i = 1:80, mid = (lo+hi)/2; if betainc(df/(df+mid^2), df/2, 0.5) > 0.05, lo = mid; else, hi = mid; end, end
q = (lo+hi)/2;
end
