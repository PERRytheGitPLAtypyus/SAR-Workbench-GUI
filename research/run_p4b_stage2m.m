%% RUN_P4B_STAGE2M  MERLIN learning curve: where does the MERLIN gain over shift augmentation disappear?
% Arms: B1 = shift augmentation on RAW chips, M1 = shift augmentation on MERLIN-despeckled chips (train and test), C1 = random-blur
% augmentation (reused from run_p4b_stage2). Fractions 2, 5, 10, 20, 50, 100 %; 10 seeds each (5 at 100 %). Same splits for all arms.
% The 10 % runs of B1 / M1 / C1 already exist (p4b_runs) and are reused. Resumable: rerun after any interruption.
% Needs mstar_merlin.mat (made by run_p4b_stage3m) and the C1 runs of run_p4b_stage2. Time: about 1 h (B1 + M1 = 2 x 50 runs).
% READING (fixed before running):
%   - per fraction, M1 - B1 CI lower bound > 0 -> MERLIN adds something on top of augmentation at that data size.
%   - CAVEAT: for fraction < 100 % the despeckler saw ALL 2747 unlabelled training chips, the classifier only the labelled subset.
%     The 100 % row has no such gap, so a gain there is a pure despeckling effect; gains at small fractions must be read together
%     with run_p3b_matched (despeckler trained on the labelled subset only).
%   - expected (a guess, not a result): gain largest at 2-10 %, shrinking towards 0 at 50-100 % as for the classical filters.
clear; close all; clc; clear functions;
cfg = p4b_config(); S = load(cfg.mat);
assert(isfile('mstar_merlin.mat'), 'mstar_merlin.mat missing: run run_p4b_stage3m first');
fracs = [0.02 0.05 0.1 0.2 0.5 1.0]; nSeeds = [10 10 10 10 10 5]; tAll = tic;
b1 = p4b_arms('B1');
for q = 1:numel(fracs)
    for s = 1:nSeeds(q), p4b_run_arm(S, b1, fracs(q), s, cfg); end
    fprintf('== B1 fraction %.2f done, %.0f min elapsed ==\n', fracs(q), toc(tAll)/60);
end
clear functions;                                   % empties the test-set cache (raw test chips) inside p4b_run_arm
Mm = load('mstar_merlin.mat'); S2 = S; S2.Xtr = Mm.Xtr_m; S2.Xte = Mm.Xte_m; clear Mm;
m1 = p4b_arm('M1', 'raw'); m1.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', 10);
for q = 1:numel(fracs)
    for s = 1:nSeeds(q), p4b_run_arm(S2, m1, fracs(q), s, cfg); end
    fprintf('== M1 fraction %.2f done, %.0f min elapsed ==\n', fracs(q), toc(tAll)/60);
end
clear functions;

%% report
keys = {'B1', 'C1', 'M1'};
fprintf('\n%-6s %-3s %-15s %-15s %-15s | %-30s %-30s\n', 'frac', 'n', 'B1 shift aug', 'C1 blur aug', 'M1 MERLIN+shift', 'M1 - B1 [95% CI]', 'M1 - C1 [95% CI]');
M = nan(numel(fracs), 3); SE = M;
for q = 1:numel(fracs)
    ns = nSeeds(q); A = nan(ns, 3);
    for k = 1:3
        for s = 1:ns
            f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', keys{k}, round(1000*fracs(q)), s));
            if isfile(f), t = load(f); A(s, k) = 100 * t.r.accTest(1); end
        end
    end
    if any(isnan(A(:, 2))), fprintf('  (warning: C1 runs missing at fraction %.2f: run run_p4b_stage2 first)\n', fracs(q)); end
    M(q,:) = mean(A, 1, 'omitnan'); sd = std(A, 0, 1, 'omitnan'); SE(q,:) = sd / sqrt(ns);
    [s1, lo1] = ci(A(:,3) - A(:,1)); [s2, lo2] = ci(A(:,3) - A(:,2)); %#ok<ASGLU>
    fprintf('%-6.2f %-3d %6.2f +/- %-5.2f %6.2f +/- %-5.2f %6.2f +/- %-5.2f | %-30s %-30s\n', fracs(q), ns, M(q,1), sd(1), M(q,2), sd(2), M(q,3), sd(3), s1, s2);
end
fig = figure('Visible', 'off', 'Position', [50 50 760 480]);
errorbar(100*fracs, M(:,1), SE(:,1), 'o-', 'LineWidth', 1.4); hold on;
errorbar(100*fracs, M(:,2), SE(:,2), '^-', 'LineWidth', 1.4);
errorbar(100*fracs, M(:,3), SE(:,3), 's-', 'LineWidth', 1.4);
set(gca, 'XScale', 'log'); grid on; xlabel('training data (% of 17 deg set)'); ylabel('test accuracy (%)');
legend({'shift aug (raw)', 'random-blur aug', 'MERLIN + shift aug'}, 'Location', 'southeast');
title('MSTAR SOC: MERLIN preprocessing vs augmentation (mean +/- s.e.m.)');
exportgraphics(fig, 'p4b_stage2m.png', 'Resolution', 150); close(fig);
save('p4b_stage2m.mat', 'fracs', 'nSeeds', 'M', 'SE', 'keys');
fprintf('\nsaved p4b_stage2m.png and p4b_stage2m.mat. Paste this whole output and attach the PNG.\n');

function [s, lo] = ci(d)
d = d(~isnan(d)); n = numel(d); lo = NaN;
if n < 3, s = 'n/a'; return; end
m = mean(d); sd = std(d); a = 0; b = 100;
for i = 1:80, mid = (a+b)/2; if betainc((n-1)/((n-1)+mid^2), (n-1)/2, 0.5) > 0.05, a = mid; else, b = mid; end, end
h = (a+b)/2 * sd / sqrt(n); lo = m - h;
s = sprintf('%+.2f [%+.2f, %+.2f]', m, m-h, m+h);
end
