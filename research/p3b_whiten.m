function [Zw, Hs] = p3b_whiten(Z, lam)
% P3B_WHITEN  Spectral whitening of complex SAR chips (single-look, apodised / oversampled).
%   Z    S x S x n complex chips (centre crop of the MSTAR chips)
%   lam  regularisation: spectrum floor = lam * (peak mean power); 0.01 keeps edge bins from exploding
%   Hs   S x S mean amplitude spectrum (rows x cols, unshifted FFT layout) estimated over all chips
%   Zw   chips with a flat mean spectrum, rescaled to unit mean power
%   Dividing by the average spectrum turns apodised, oversampled (spatially correlated) speckle into nearly white speckle,
%   the precondition for treating real and imaginary parts as independent noisy copies of one scene (MERLIN-type training).
n = size(Z, 3);
F = fft2(Z);
Pm = mean(abs(F).^2, 3);
Hs = sqrt(Pm);
den = sqrt(Pm + lam * max(Pm(:)));
Zw = ifft2(F ./ den);
Zw = Zw ./ sqrt(mean(abs(Zw(:)).^2));
end
