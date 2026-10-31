function [X, Y] = p4b_build_train(S, arm, tr, seed, cfg)
% P4B_BUILD_TRAIN  Model-input training set of an arm (normalisation N applied last, identical for all arms).
%   Augmented arms get aug.K independent augmented copies (offline augmentation); train for round(E/K) epochs.
raw = S.Xtr(:, :, :, tr);
hasAug = arm.aug.shift || ~isempty(arm.aug.noiseL) || ~isempty(arm.aug.blurSet);
if ~isempty(arm.mix)
    X = zeros(cfg.crop, cfg.crop, 1, 0, 'single');
    for k = 1:numel(arm.mix)
        X = cat(4, X, p4b_norm(p4b_crop(p4b_filter(raw, arm.mix{k}, cfg), cfg.crop), cfg.pct));
    end
    Y = repmat(S.Ytr(tr), numel(arm.mix), 1);
elseif ~hasAug
    X = p4b_norm(p4b_crop(p4b_filter(raw, arm.train, cfg), cfg.crop), cfg.pct);
    Y = S.Ytr(tr);
else
    if ~strcmp(arm.train.type, 'raw')      % filter first, then (shift-only) augmentation of the filtered chips
        assert(isempty(arm.aug.noiseL) && isempty(arm.aug.blurSet), 'filtered arms support shift augmentation only');
        raw = p4b_filter(raw, arm.train, cfg);
    end
    X = zeros(cfg.crop, cfg.crop, 1, 0, 'single');
    for k = 1:arm.aug.K
        Xk = p4b_augment(raw, arm.aug, cfg.crop, 1000 * seed + k, cfg.maxShift);
        X = cat(4, X, p4b_norm(Xk, cfg.pct));
    end
    Y = repmat(S.Ytr(tr), arm.aug.K, 1);
end
end
