function Y = p4b_augment(X, aug, crop, seed, maxShift)
% P4B_AUGMENT  One random augmented copy of raw 128x128 chips -> 88x88 chips (not yet normalised).
%   aug.noiseL   [] or [Lmin Lmax]: multiplicative gamma speckle-like noise with integer looks L per chip (unit mean)
%   aug.blurSet  [] or vector of boxcar windows (random choice per chip; 1 = no blur)
%   aug.shift    true: random crop position within +/- maxShift px, false: centre crop
%   Deterministic given seed.
rng(seed); [H, ~, ~, N] = size(X);
if ~isempty(aug.noiseL)
    Ls = aug.noiseL(1) + floor(rand(1, 1, 1, N) * (aug.noiseL(2) - aug.noiseL(1) + 1));
    acc = zeros(size(X), 'single');
    for k = 1:aug.noiseL(2)
        acc = acc + single(Ls >= k) .* single(-log(rand(size(X), 'single')));
    end
    X = X .* sqrt(acc ./ single(Ls));
end
if ~isempty(aug.blurSet)
    w = aug.blurSet(randi(numel(aug.blurSet), 1, N));
    Xb = X;
    for ww = unique(w(:)).'
        if ww <= 1, continue; end
        j = find(w == ww);
        Xb(:,:,:,j) = sqrt(max(convn(X(:,:,:,j).^2, ones(ww) / ww^2, 'same'), 0));
    end
    X = Xb;
end
c0 = (H - crop) / 2; Y = zeros(crop, crop, 1, N, 'single');
if aug.shift, d = randi([-maxShift maxShift], 2, N); else, d = zeros(2, N); end
for i = 1:N
    Y(:,:,1,i) = X(c0+d(1,i)+1 : c0+d(1,i)+crop, c0+d(2,i)+1 : c0+d(2,i)+crop, 1, i);
end
end
