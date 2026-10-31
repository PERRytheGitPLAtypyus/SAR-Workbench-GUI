function Y = p4b_norm(X, pct)
% P4B_NORM  Normalisation N, identical for every arm: divide each chip by its own pct-th percentile, clip at 1.
%   Applied to the final model input (after filtering, augmentation and cropping). No toolbox needed.
N = size(X, 4); v = sort(reshape(X, [], N), 1);
p = v(min(size(v, 1), max(1, ceil(pct / 100 * size(v, 1)))), :);
p = max(p, eps('single'));
Y = min(X ./ reshape(single(p), 1, 1, 1, N), 1);
end
