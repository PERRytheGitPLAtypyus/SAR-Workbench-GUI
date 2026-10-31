function R = p3b_denoise(net, Z, s)
% P3B_DENOISE  MERLIN-type despeckling of a complex single-look image Z (H x W >= 128 x 128, any size).
%   Returns the estimated reflectivity INTENSITY R (same size as Z): mean of exp(u(Re)) and exp(u(Im)), tiles of 128 x 128
%   with stride 64 averaged where they overlap. s: amplitude scale used in training (clutter power about 1 after /s).
%   Amplitude estimate = sqrt(R).
[H, W] = size(Z); T = 128;
assert(H >= T && W >= T, 'p3b_denoise: image must be at least 128 x 128');
z = single(Z) / s;
rs = unique([1:64:H-T+1, H-T+1]); cs = unique([1:64:W-T+1, W-T+1]);
nt = numel(rs) * numel(cs); X = zeros(T, T, 1, 2*nt, 'single'); pos = zeros(nt, 2); k = 0;
for r = rs
    for c = cs
        k = k + 1; tile = z(r:r+T-1, c:c+T-1); pos(k, :) = [r c];
        X(:,:,1,k) = p3b_input(real(tile)); X(:,:,1,nt+k) = p3b_input(imag(tile));
    end
end
U = minibatchpredict(net, X, 'MiniBatchSize', 32);
U = max(min(U, 12), -12);
acc = zeros(H, W, 'single'); cnt = acc;
for k = 1:nt
    Rk = 0.5 * (exp(U(:,:,1,k)) + exp(U(:,:,1,nt+k)));
    r = pos(k,1); c = pos(k,2);
    acc(r:r+T-1, c:c+T-1) = acc(r:r+T-1, c:c+T-1) + Rk; cnt(r:r+T-1, c:c+T-1) = cnt(r:r+T-1, c:c+T-1) + 1;
end
R = s^2 * acc ./ cnt;
end
