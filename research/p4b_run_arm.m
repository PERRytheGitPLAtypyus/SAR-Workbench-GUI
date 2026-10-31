function r = p4b_run_arm(S, arm, frac, seed, cfg)
% P4B_RUN_ARM  Train one arm for one fraction and seed; evaluate on validation and (if arm.evalTest) on the 15 deg test
%   set for every spec in arm.tests. One .mat per run in cfg.outdir; an existing file is loaded instead (resumable).
if ~exist(cfg.outdir, 'dir'), mkdir(cfg.outdir); end
f = fullfile(cfg.outdir, sprintf('%s_f%04d_s%02d.mat', arm.name, round(1000*frac), seed));
if isfile(f), t = load(f); r = t.r; return; end
sp = p4b_make_splits(S.Ytr, frac, seed);
[Xtr, Ytr] = p4b_build_train(S, arm, sp.tr, seed, cfg);
K = arm.aug.K; hasAug = arm.aug.shift || ~isempty(arm.aug.noiseL) || ~isempty(arm.aug.blurSet);
if ~hasAug, K = 1; end
if ~isempty(arm.mix), K = numel(arm.mix); end
E = arm.epochs; if isempty(E), E = cfg.epochsFor(frac, numel(sp.tr)); end
Eeff = max(1, round(E / K));
cls = categories(S.Ytr);
arch = 'cnn4'; if isfield(arm, 'arch'), arch = arm.arch; end
tic; net = p4b_train(Xtr, Ytr, seed, Eeff, arm.drop, arm.wd, arch); tTrain = toc;
accVal = NaN;
if ~isempty(sp.va)
    Xv = p4b_norm(p4b_crop(p4b_filter(S.Xtr(:,:,:,sp.va), arm.tests{1}, cfg), cfg.crop), cfg.pct);
    accVal = mean(p4b_predict(net, Xv, cls) == S.Ytr(sp.va));
end
accTest = nan(1, numel(arm.tests));
if arm.evalTest
    for k = 1:numel(arm.tests)
        accTest(k) = mean(p4b_predict(net, testset(S, arm.tests{k}, cfg), cls) == S.Yte);
    end
end
r = struct('name', arm.name, 'frac', frac, 'seed', seed, 'epochs', E, 'epochsEff', Eeff, 'nTrain', numel(Ytr), ...
    'accVal', accVal, 'accTest', accTest, 'tTrain', tTrain, 'tests', {arm.tests});
save(f, 'r');
fprintf('%-14s frac %.3f seed %2d  val %.2f %%  test %s  (%.0f s)\n', arm.name, frac, seed, 100*accVal, mat2str(100*accTest, 4), tTrain);
end

function X = testset(S, spec, cfg)
persistent cache
if isempty(cache), cache = containers.Map('KeyType', 'char', 'ValueType', 'any'); end
key = sprintf('%s%d', spec.type, spec.win);
if ~isKey(cache, key)
    cache(key) = p4b_norm(p4b_crop(p4b_filter(S.Xte, spec, cfg), cfg.crop), cfg.pct);
end
X = cache(key);
end
