%% RUN_P4B_STAGE2  Reduced learning curve (hypothesis H4): where does the benefit of filtering / augmentation shrink?
% Arms: A0 raw, A3_lee (Lee 7, train+test filtered), C1 (random-blur augmentation, raw test), all under normalisation N.
% Fractions of the 17 deg training set: 2, 5, 10, 20, 50, 100 %.  Seeds: 10 per fraction (5 at 100 %).
% The 10 % runs already exist (p4b_runs/), so they are reused.  Resumable: rerun after any interruption.
% Time: about 1.5 h.  Needs about 4 GB of RAM at 100 % for C1 (10 augmented copies of 2747 chips).
clear; close all; clc;
cfg = p4b_config(); S = load(cfg.mat);
fracs = [0.02 0.05 0.1 0.2 0.5 1.0]; nSeeds = [10 10 10 10 10 5];
keys = {'A0', 'A3_lee', 'C1'}; tAll = tic;
for q = 1:numel(fracs)
    for s = 1:nSeeds(q)
        for k = 1:numel(keys), p4b_run_arm(S, p4b_arms(keys{k}), fracs(q), s, cfg); end
    end
    fprintf('== fraction %.2f done, %.0f min elapsed ==\n', fracs(q), toc(tAll)/60);
end

%% report: mean +/- SD per fraction and paired differences (t-interval, no toolbox needed)
fprintf('\n%-8s %-6s %-16s %-16s %-16s | %-26s %-26s\n', 'frac', 'n', 'A0 raw', 'Lee 7', 'C1 blur aug', 'Lee - A0 [95% CI]', 'C1 - Lee [95% CI]');
M = nan(numel(fracs), 3); SD = M; SE = M;
for q = 1:numel(fracs)
    ns = nSeeds(q); A = nan(ns, 3);
    for k = 1:3
        for s = 1:ns
            f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', keys{k}, round(1000*fracs(q)), s));
            if isfile(f), t = load(f); A(s, k) = 100 * t.r.accTest(1); end
        end
    end
    M(q,:) = mean(A, 1); SD(q,:) = std(A, 0, 1); SE(q,:) = SD(q,:) / sqrt(ns);
    fprintf('%-8.2f %-6d %6.2f +/- %-6.2f %6.2f +/- %-6.2f %6.2f +/- %-6.2f | %s %s\n', fracs(q), ns, M(q,1), SD(q,1), M(q,2), SD(q,2), M(q,3), SD(q,3), ...
        ci(A(:,2) - A(:,1)), ci(A(:,3) - A(:,2)));
end
fig = figure('Visible', 'off', 'Position', [50 50 760 480]);
errorbar(100*fracs, M(:,1), SE(:,1), 'o-', 'LineWidth', 1.4); hold on;
errorbar(100*fracs, M(:,2), SE(:,2), 's-', 'LineWidth', 1.4);
errorbar(100*fracs, M(:,3), SE(:,3), '^-', 'LineWidth', 1.4);
set(gca, 'XScale', 'log'); grid on; xlabel('training data (% of 17 deg set)'); ylabel('test accuracy (%)');
legend({'raw', 'Lee 7 filtered', 'random-blur augmentation (raw test)'}, 'Location', 'southeast');
title('MSTAR SOC: accuracy vs training size (mean +/- s.e.m.)');
exportgraphics(fig, 'p4b_learning_curve.png', 'Resolution', 150); close(fig);
save('p4b_stage2.mat', 'fracs', 'nSeeds', 'M', 'SD', 'SE', 'keys');
fprintf('\nsaved p4b_learning_curve.png and p4b_stage2.mat. Paste this whole output and attach the PNG.\n');

function s = ci(d)
d = d(~isnan(d)); n = numel(d);
if n < 3, s = 'n/a'; return; end
m = mean(d); sd = std(d); lo = 0; hi = 100;
for i = 1:80, mid = (lo+hi)/2; if betainc((n-1)/((n-1)+mid^2), (n-1)/2, 0.5) > 0.05, lo = mid; else, hi = mid; end, end
h = (lo+hi)/2 * sd / sqrt(n);
s = sprintf('%+.2f [%+.2f, %+.2f]', m, m-h, m+h);
end
