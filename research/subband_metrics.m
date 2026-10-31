function r = subband_metrics(Z, P, gu, seed)
% SUBBAND_METRICS  Split the azimuth (dim 2) spectrum of complex chips at its energy median into two
%   sub-bands and measure how dependent the two sub-look images are in the four P x P chip corners.
%   Z    S x S x n complex chips        P  patch size (e.g. 32)
%   gu   guard bins on each side of the split (gu >= 0: disjoint bands);
%        gu < 0 makes the bands overlap by -2*gu bins (positive control).
%   r.corrI   correlation of patch-normalised sub-look INTENSITIES (also high if both share reflectivity texture)
%   r.coh     median complex coherence |sum z1 z2*| / sqrt(sum|z1|^2 sum|z2|^2) per patch. Texture-blind:
%             ~chance floor for independent speckle whatever the texture.
%   r.cohShuf the same with z2 patches taken from different chips (chance floor of the coherence estimate)
%   r.k50     energy-median bin of the shifted azimuth spectrum
if nargin < 4, seed = 1; end
S = size(Z, 1); n = size(Z, 3);
F = fft(Z, [], 2);
Pw = fftshift(sum(sum(abs(F).^2, 1), 3));            % 1 x S
cs = cumsum(Pw) / sum(Pw); k50 = find(cs >= 0.5, 1);
m1 = false(1, S); m2 = false(1, S);
if gu >= 0
    m1(1:k50-gu-1) = true; m2(k50+gu:S) = true;
else
    ov = -gu; m1(1:k50+ov) = true; m2(k50-ov:S) = true;
end
m1 = ifftshift(m1); m2 = ifftshift(m2);
z1 = ifft(bsxfun(@times, F, reshape(double(m1), 1, S)), [], 2);
z2 = ifft(bsxfun(@times, F, reshape(double(m2), 1, S)), [], 2);
Z1 = corners(z1, P); Z2 = corners(z2, P);
I1 = abs(Z1).^2; I2 = abs(Z2).^2;
I1 = bsxfun(@rdivide, I1, mean(mean(I1, 1), 2)); I2 = bsxfun(@rdivide, I2, mean(mean(I2, 1), 2));
cc = corrcoef(I1(:), I2(:));
c = coh(Z1, Z2);
rng(seed); p = randperm(size(Z2, 3));
cs2 = coh(Z1, Z2(:,:,p));
r.corrI = cc(1,2); r.coh = median(c(:)); r.cohShuf = median(cs2(:)); r.k50 = k50;
r.cvI = std(I1(:));
end

function c = coh(A, B)
num = abs(sum(sum(A .* conj(B), 1), 2));
den = sqrt(sum(sum(abs(A).^2, 1), 2) .* sum(sum(abs(B).^2, 1), 2));
c = num ./ den;
end

function C = corners(X, P)
S = size(X, 1); n = size(X, 3); C = zeros(P, P, 4*n); k = 0;
rr = {1:P, S-P+1:S};
for a = 1:2
    for b = 1:2
        C(:,:,k*n+(1:n)) = X(rr{a}, rr{b}, :); k = k + 1;
    end
end
end
