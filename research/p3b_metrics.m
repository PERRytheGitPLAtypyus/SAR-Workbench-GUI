function m = p3b_metrics(I, R, P, tgt)
% P3B_METRICS  Quality metrics of a despeckled intensity estimate R against the raw single-look intensity I (both S x S x n).
%   Clutter = the four P x P chip corners (per-patch statistics); target box = rows/cols tgt (e.g. 41:88).
%   m.gain    ENL(R)/ENL(I) in clutter, ENL = 1/median(CV^2) over patches.   m.bias  sum(R)/sum(I) - 1 in clutter
%   m.rmean   mean of the ratio image I./R in clutter (want 1)               m.rcorr median per-patch corr(ratio, R) (want 0)
%   m.rac     median per-patch lag-1 azimuth autocorrelation of the ratio    m.racRaw  the same for raw I (speckle reference)
%   m.peak    median over chips of q99(R)/q99(I) in the target box            m.energy  median sum(R)/sum(I) in the target box
%   m.conc    median of [top-1% share of box energy in R] / [same in I]  (1 = scatterer concentration preserved)
Ic = corners(I, P); Rc = corners(R, P);
m.enlRaw = 1 / median(cv2(Ic, P)); m.enl = 1 / median(cv2(Rc, P)); m.gain = m.enl / m.enlRaw;
m.bias = sum(Rc(:)) / sum(Ic(:)) - 1;
r = Ic ./ max(Rc, eps('double'));
m.rmean = mean(r(:));
a = reshape(r, P*P, []); b = reshape(Rc, P*P, []);
a = a - mean(a, 1); b = b - mean(b, 1);
c = sum(a .* b, 1) ./ sqrt(sum(a.^2, 1) .* sum(b.^2, 1)); c = c(isfinite(c)); if isempty(c), m.rcorr = 0; else, m.rcorr = median(c); end
m.rac = lagcorr(r, P); m.racRaw = lagcorr(Ic, P);
Ib = reshape(I(tgt, tgt, :), [], size(I, 3)); Rb = reshape(R(tgt, tgt, :), [], size(R, 3));
nb = size(Ib, 1); k = max(1, round(0.01 * nb)); iq = ceil(0.99 * nb);
sI = sort(Ib, 1); sR = sort(Rb, 1);
m.peak = median(sR(iq, :) ./ sI(iq, :));
m.energy = median(sum(Rb, 1) ./ sum(Ib, 1));
m.conc = median((sum(sR(end-k+1:end, :), 1) ./ sum(Rb, 1)) ./ (sum(sI(end-k+1:end, :), 1) ./ sum(Ib, 1)));
end

function v = cv2(Q, P)
q = reshape(Q, P*P, []); v = var(q, 0, 1) ./ mean(q, 1).^2;
end

function ac = lagcorr(Q, P)
q = Q - mean(mean(Q, 1), 2);
num = sum(sum(q(:, 1:end-1, :) .* q(:, 2:end, :), 1), 2); den = sum(sum(q.^2, 1), 2);
ac = median(num(:) ./ den(:));
end

function C = corners(X, P)
S = size(X, 1); n = size(X, 3); C = zeros(P, P, 4*n, 'like', X); k = 0;
rr = {1:P, S-P+1:S};
for a = 1:2
    for b = 1:2
        C(:,:,k*n+(1:n)) = X(rr{a}, rr{b}, :); k = k + 1;
    end
end
end
