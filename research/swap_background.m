function Y = swap_background(X, box, seed)
% SWAP_BACKGROUND  Keep a centred box x box window of every chip, replace everything outside it with the
%   outside of ANOTHER chip of the same set (random donor, never itself, fixed by seed).
%   Class-specific background information is destroyed (the donor is unrelated to the chip's class) while
%   realistic clutter texture and speckle statistics are kept. Run on the 128x128 chips BEFORE filtering/cropping.
%   X: H x H x 1 x N (single), box: even integer <= H.
N = size(X, 4); H = size(X, 1);
rng(seed);
q = randperm(N); p = zeros(1, N); p(q) = q([2:N 1]);    % cyclic derangement: donor(q(i)) = q(i+1), no fixed points
c0 = (H - box) / 2; ix = c0+1 : c0+box;
Y = X(:, :, :, p);
Y(ix, ix, :, :) = X(ix, ix, :, :);
end
