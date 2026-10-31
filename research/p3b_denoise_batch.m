function R = p3b_denoise_batch(net, Zr, Zi, s, mb)
% P3B_DENOISE_BATCH  Same estimate as p3b_denoise for 128 x 128 chips, but many chips per network call (about 10x faster).
%   Zr, Zi : real and imaginary part of the complex chips, 128 x 128 x N, UNSCALED (as read from the file / p3b_chips_*.mat)
%   s      : amplitude scale used in training (clutter power about 1 after division)
%   Returns the reflectivity INTENSITY R (128 x 128 x N, single) = s^2 * mean(exp(u(Re)), exp(u(Im))); amplitude = sqrt(R).
%   A 128 x 128 chip is exactly one tile of p3b_denoise, so both functions must agree (run_p3b_matched checks this).
if nargin < 5, mb = 64; end
[H, W, N] = size(Zr);
assert(H == 128 && W == 128, 'p3b_denoise_batch: chips must be 128 x 128');
R = zeros(H, W, N, 'single');
for a = 1:mb:N
    j = a:min(a + mb - 1, N); n = numel(j);
    zr = reshape(single(Zr(:,:,j)) / s, H, W, 1, n);
    zi = reshape(single(Zi(:,:,j)) / s, H, W, 1, n);
    U = minibatchpredict(net, cat(4, p3b_input(zr), p3b_input(zi)), 'MiniBatchSize', 32);
    U = max(min(U, 12), -12);
    R(:,:,j) = s^2 * 0.5 * (exp(reshape(U(:,:,1,1:n), H, W, n)) + exp(reshape(U(:,:,1,n+1:2*n), H, W, n)));
end
end
