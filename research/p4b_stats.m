function p4b_stats(frac)
% P4B_STATS  Paired per-seed analysis of Phase 4b (reads p4b_runs/*.mat, 10 % data by default). No toolbox needed
%   (t-distribution via betainc; Wilcoxon via signrank when the Statistics Toolbox is present).
%   Primary family (Holm over 4): A1-A0, B4-A0, C1-A0, A1-B4.  Everything else is labelled exploratory.
if nargin < 1, frac = 0.1; end
cfg = p4b_config();
fprintf('Phase 4b paired analysis, training fraction %.2f\n', frac);
fprintf('\n--- arm means (test accuracy; first test condition of each arm unless stated) ---\n');
names = {'A0', 'A1', 'A2_w5', 'A2_w9', 'A3_lee', 'A3_frost', 'B1', 'B2', 'B4', 'C1', 'C3', 'E1_lee', 'E1_box5'};
for k = 1:numel(names)
    [a, n] = acc(cfg, names{k}, 1, frac);
    if n > 0, fprintf('%-9s %.2f +/- %.2f %%  (n = %d seeds)\n', names{k}, 100*mnn(a), 100*snn(a), n); end
end

fprintf('\n--- PRIMARY contrasts (paired by seed; Holm over the 4) ---\n');
P = {'A1 - A0 (boxcar 7 filtered/filtered vs raw/raw)', 'A1', 1, 'A0', 1
     'B4 - A0 (tuned raw regularisation vs raw)',         'B4', 1, 'A0', 1
     'C1 - A0 (random-blur augmentation, raw test)',      'C1', 1, 'A0', 1
     'A1 - B4 (filtering vs tuned raw regularisation)',   'A1', 1, 'B4', 1};
pv = nan(1, 4); D = cell(1, 4);
for i = 1:4
    D{i} = contrast(cfg, P{i,2}, P{i,3}, P{i,4}, P{i,5}, frac); pv(i) = D{i}.p;
end
adj = holm(pv);
for i = 1:4, report(P{i,1}, D{i}, adj(i)); end

fprintf('\n--- EXPLORATORY contrasts (no multiplicity correction) ---\n');
E = {'A2 boxcar 5 - A0', 'A2_w5', 1, 'A0', 1
     'A2 boxcar 9 - A0', 'A2_w9', 1, 'A0', 1
     'Lee 7 - A0', 'A3_lee', 1, 'A0', 1
     'Frost 7 - A0', 'A3_frost', 1, 'A0', 1
     'B1 shift aug - A0', 'B1', 1, 'A0', 1
     'B2 shift+noise aug - A0', 'B2', 1, 'A0', 1
     'C1 tested on boxcar 7 (C2) - A1', 'C1', 2, 'A1', 1
     'C3 mixed, raw test - A0', 'C3', 1, 'A0', 1
     'C3 mixed, boxcar-7 test - A1', 'C3', 2, 'A1', 1
     'best classical filter: Lee 7 - B4 (tuned raw regularisation)', 'A3_lee', 1, 'B4', 1
     'Lee 7 - C1 (random-blur augmentation)', 'A3_lee', 1, 'C1', 1
     'Lee 7 - boxcar 5', 'A3_lee', 1, 'A2_w5', 1
     'E1 Lee + shift aug - B1 (shift aug on raw): does filtering add on top of augmentation?', 'E1_lee', 1, 'B1', 1
     'E1 boxcar 5 + shift aug - B1', 'E1_box5', 1, 'B1', 1};
for i = 1:size(E, 1), report(E{i,1}, contrast(cfg, E{i,2}, E{i,3}, E{i,4}, E{i,5}, frac), NaN); end

fprintf('\n--- 2x2: train x test (A0 = train raw, A1 = train boxcar 7) ---\n');
[a1, ~] = acc(cfg, 'A0', 1, frac); [a2, ~] = acc(cfg, 'A0', 2, frac); [a3, ~] = acc(cfg, 'A1', 2, frac); [a4, ~] = acc(cfg, 'A1', 1, frac);
fprintf('                test raw          test boxcar 7\n');
fprintf('train raw       %6.2f +/- %.2f   %6.2f +/- %.2f\n', 100*mnn(a1), 100*snn(a1), 100*mnn(a2), 100*snn(a2));
fprintf('train boxcar 7  %6.2f +/- %.2f   %6.2f +/- %.2f\n', 100*mnn(a3), 100*snn(a3), 100*mnn(a4), 100*snn(a4));

fprintf('\n--- pre-set decision rules ---\n');
d = D{4};
if d.ci(1) > 0, fprintf('Rule 1: A1 - B4 CI lower bound %+.2f > 0 -> filtering gives something beyond ordinary augmentation; Phase 3b target = beat A1.\n', d.ci(1));
else, fprintf('Rule 2: A1 - B4 CI [%+.2f, %+.2f] includes 0 or is negative -> the gain is generic regularisation; reframe Phase 3b as a despeckling-quality contribution.\n', d.ci(1), d.ci(2)); end
dc = contrast(cfg, 'C1', 1, 'A1', 1, frac);
if dc.ci(1) > -1, r3 = 'HOLDS (CI lower bound above -1 pp): no filter is needed at inference'; else, r3 = 'does not hold (C1 is more than 1 pp below A1 or the CI is too wide to say)'; end
fprintf('Rule 3: C1 (raw test) minus A1 = %+.2f pp (95%% CI [%+.2f, %+.2f]); %s.\n', dc.md, dc.ci(1), dc.ci(2), r3);
m = [mnn(acc(cfg, 'A1', 1, frac)), mnn(acc(cfg, 'B4', 1, frac)), mnn(acc(cfg, 'C1', 1, frac))];
fprintf('Rule 4: Phase 3b must beat max(A1, B4, C1) = %.2f %% at 10 %% data (A1 %.2f, B4 %.2f, C1 %.2f).\n', 100*max(m), 100*m);
end

function [a, n] = acc(cfg, name, k, frac)
a = nan(1, 20);
for s = 1:20
    f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', name, round(1000*frac), s));
    if isfile(f), t = load(f); if numel(t.r.accTest) >= k, a(s) = t.r.accTest(k); end, end
end
n = nnz(~isnan(a));
end

function c = contrast(cfg, nA, kA, nB, kB, frac)
a = acc(cfg, nA, kA, frac); b = acc(cfg, nB, kB, frac);
ok = ~isnan(a) & ~isnan(b); d = 100 * (a(ok) - b(ok)); n = numel(d);
c.n = n; c.md = mean(d); c.sd = std(d);
if n < 3, c.ci = [NaN NaN]; c.p = NaN; c.pw = NaN; return; end
t = c.md / (c.sd / sqrt(n)); c.p = betainc((n-1) / ((n-1) + t^2), (n-1)/2, 0.5);
c.ci = c.md + tcrit(n-1) * c.sd / sqrt(n) * [-1 1];
try, c.pw = signrank(d); catch, c.pw = NaN; end
end

function report(lbl, c, padj)
if isnan(padj), ps = ''; else, ps = sprintf('  Holm-adjusted p = %.4f', padj); end
fprintf('%-62s %+.2f pp  95%% CI [%+.2f, %+.2f]  SD of diffs %.2f  n = %d  p = %.4f  Wilcoxon p = %.4f%s\n', lbl, c.md, c.ci(1), c.ci(2), c.sd, c.n, c.p, c.pw, ps);
end

function q = tcrit(df)
lo = 0; hi = 100;
for i = 1:80
    mid = (lo + hi) / 2; p = betainc(df / (df + mid^2), df/2, 0.5);
    if p > 0.05, lo = mid; else, hi = mid; end
end
q = (lo + hi) / 2;
end

function adj = holm(p)
[ps, ix] = sort(p); m = numel(p); a = zeros(1, m);
for i = 1:m, a(i) = (m - i + 1) * ps(i); end
a = min(1, cummax(a)); adj = zeros(1, m); adj(ix) = a;
end

function m = mnn(x)
x = x(~isnan(x)); if isempty(x), m = NaN; else, m = mean(x); end
end

function s = snn(x)
x = x(~isnan(x)); if numel(x) < 2, s = NaN; else, s = std(x); end
end
