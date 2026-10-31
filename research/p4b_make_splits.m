function sp = p4b_make_splits(Ytr, frac, seed)
% P4B_MAKE_SPLITS  Stratified train subset + DISJOINT validation subset of the 17 deg training chips.
%   Per class: one random permutation (rng(2000+seed), same call pattern as the earlier Phase 4 scripts, so the train
%   subsets are identical to those runs), the first k = round(frac*n) chips train, the next min(k, n-k) validate.
%   frac >= 1: all chips train, no validation set.  The 15 deg test set is never touched here.
lab = double(Ytr(:)); cl = unique(lab); n = numel(lab);
if frac >= 1, sp.tr = (1:n).'; sp.va = zeros(0, 1); return; end
rng(2000 + seed); tr = []; va = [];
for c = 1:numel(cl)
    ii = find(lab == cl(c)); ii = ii(randperm(numel(ii)));
    k = max(1, round(frac * numel(ii)));
    tr = [tr; ii(1:k)];                                   %#ok<AGROW>
    nv = min(k, numel(ii) - k);
    va = [va; ii(k+1 : k+nv)];                            %#ok<AGROW>
end
sp.tr = sort(tr); sp.va = sort(va);
end
