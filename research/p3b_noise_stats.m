function r = p3b_noise_stats(Z, P)
% P3B_NOISE_STATS  Speckle statistics in the four P x P chip corners (clutter) of complex chips Z (S x S x n).
%   r.rho_r, r.rho_a  median complex correlation of neighbouring pixels (range = rows, azimuth = columns); 0 = white
%   r.xmax            max over lags |dr|,|da| <= 4 of |corr(Re z(i), Im z(i+d))|  (cross-correlation that would let the
%                     real part predict the imaginary part: must be ~0 for real/imag self-supervised training)
%   r.rr1             corr(Re z(i), Re z(i+1)) along azimuth (residual spatial correlation of the noise itself)
%   r.vratio          var(Re)/var(Im) in the corners (1 = circular)
%   r.cvI             intensity std/mean (1 = fully developed single-look speckle)
C = corners(Z, P);
pw = mean(mean(abs(C).^2, 1), 2);
rr = abs(mean(mean(C(1:end-1,:,:) .* conj(C(2:end,:,:)), 1), 2) ./ pw);
ra = abs(mean(mean(C(:,1:end-1,:) .* conj(C(:,2:end,:)), 1), 2) ./ pw);
r.rho_r = median(rr(:)); r.rho_a = median(ra(:));
xm = 0;
for dr = -4:4
    for da = -4:4
        a = real(C(max(1,1-dr):min(P,P-dr), max(1,1-da):min(P,P-da), :));
        b = imag(C(max(1,1+dr):min(P,P+dr), max(1,1+da):min(P,P+da), :));
        xm = max(xm, abs(sum(a(:) .* b(:)) / sqrt(sum(a(:).^2) * sum(b(:).^2))));
    end
end
r.xmax = xm;
r.vratio = sum(real(C(:)).^2) / sum(imag(C(:)).^2);     % circularity: var(Re)/var(Im), 1 for a circular process
a = real(C(:, 1:end-1, :)); b = real(C(:, 2:end, :));
r.rr1 = sum(a(:) .* b(:)) / sqrt(sum(a(:).^2) * sum(b(:).^2));
I = abs(C).^2; I = reshape(I, P*P, []);
r.cvI = median(std(I, 0, 1) ./ mean(I, 1));
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
