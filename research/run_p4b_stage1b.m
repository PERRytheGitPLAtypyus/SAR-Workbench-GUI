%% RUN_P4B_STAGE1B  Stage 1 part b: validation-only selection, then the tuned raw-data arm B4 (needs stage 1a finished).
%   1. B3: dropout {0, 0.25, 0.5} x weight decay {0, 1e-4, 1e-3} on RAW chips, seeds 1-5, VALIDATION only (no test evaluation).
%   2. Pick the dropout/weight-decay pair with the best mean validation accuracy.
%   3. Pick the augmentation among {none, B1, B2} with the best mean validation accuracy over the stage 1a seeds.
%   4. B4 = chosen augmentation + chosen dropout/decay, seeds 1-20, test condition raw.
%   5. Pick the boxcar window among {5, 7, 9} by pooled validation accuracy (reported; all three are already run).
% The choices use validation chips only (275 per seed, disjoint from the train subset). Time about 45 min.
clear; close all; clc;
cfg = p4b_config(); S = load(cfg.mat); frac = 0.1;
drops = [0 0.25 0.5]; wds = [0 1e-4 1e-3]; gseeds = 1:5;

G = nan(numel(drops), numel(wds));
for i = 1:numel(drops)
    for j = 1:numel(wds)
        v = nan(1, numel(gseeds));
        for s = 1:numel(gseeds)
            a = p4b_arm(sprintf('B3_d%03d_w%d', round(100*drops(i)), round(-log10(max(wds(j), 1e-9)))), 'raw');
            a.drop = drops(i); a.wd = wds(j); a.evalTest = false;
            r = p4b_run_arm(S, a, frac, gseeds(s), cfg); v(s) = r.accVal;
        end
        G(i, j) = mean(v);
    end
end
fprintf('\nB3 validation accuracy (rows dropout %s, columns weight decay %s), mean of %d seeds:\n', mat2str(drops), mat2str(wds), numel(gseeds));
disp(100*G);
[~, ib] = max(G(:)); [bi, bj] = ind2sub(size(G), ib);
sel.drop = drops(bi); sel.wd = wds(bj);
fprintf('chosen on validation: dropout %.2f, weight decay %g (grid noise is about +/-1.5 pp, so a close call is a coin flip)\n', sel.drop, sel.wd);

augKeys = {'A0', 'B1', 'B2'}; V = nan(1, 3);
for k = 1:3, V(k) = meanval(cfg, augKeys{k}, 1:20, frac); end
fprintf('mean validation accuracy over seeds 1-20: A0 (no aug) %.2f %% | B1 (shift) %.2f %% | B2 (shift+noise) %.2f %%\n', 100*V);
[~, ia] = max(V); sel.aug = ternary(ia == 1, 'none', augKeys{ia});
fprintf('chosen augmentation: %s\n', sel.aug);

for s = 1:20, p4b_run_arm(S, p4b_arms('B4', sel), frac, s, cfg); end

W = nan(1, 3); wk = {'A2_w5', 'A1', 'A2_w9'};
for k = 1:3, W(k) = meanval(cfg, wk{k}, 1:20, frac); end
fprintf('boxcar window by pooled validation accuracy: 5 -> %.2f %% | 7 -> %.2f %% | 9 -> %.2f %%\n', 100*W);
save('p4b_stage1b_selection.mat', 'sel', 'G', 'V', 'W');
fprintf('\nStage 1b done. Next: p4b_stats  (paste its whole output).\n');

function m = meanval(cfg, name, seeds, frac)
v = nan(1, numel(seeds));
for s = 1:numel(seeds)
    f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', name, round(1000*frac), seeds(s)));
    if isfile(f), t = load(f); v(s) = t.r.accVal; end
end
v = v(~isnan(v)); if isempty(v), m = NaN; else, m = mean(v); end
end

function o = ternary(c, a, b)
if c, o = a; else, o = b; end
end
