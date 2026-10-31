%% P3B_GOTCHA_DIAG  Why did the Gotcha clutter fail the MERLIN gate (xmax 0.093)?  Three competing explanations, one run:
%   H1  the tile corners were not clean clutter (targets / texture)            -> xmax of CLEAN clutter blocks is already < 0.05
%   H2  the BP image spectrum is off baseband (carrier left in the image)      -> xmax drops below 0.05 after spectral recentring
%   H3  a genuine violation of the real/imaginary independence assumption      -> xmax stays >= 0.05 in both
% Uses the cached pass-8 images (p3b_gotcha_cache_pass8.mat, made by p3b_train_gotcha before the gate stopped it). No BP, no training. About 1 min.
% Clean clutter block = 32 x 32 block with mean power in [0.3, 1.5] and max power < 20 (units: per-image clutter power = 1).
% Recentring multiplies each image's blocks by exp(-j 2 pi (fr*row + fa*col)) with (fr, fa) the circular spectral centroid of that image's
%   clutter blocks. |z|^2 is unchanged by it, so a despeckler applied after recentring still estimates the same intensity.
% PRE-SET gate (unchanged): xmax < 0.05 and 0.9 <= vratio <= 1.1.
clear; close all; clc;
C = load('p3b_gotcha_cache_pass8.mat'); Zs = C.Zc; B = 32; P = 16; nImg = numel(Zs);
Zb = cell(1, nImg); nAll = 0;
for i = 1:nImg
    [H, W] = size(Zs{i}); Q = zeros(B, B, 0);
    for r = 1:B:H-B+1
        for c = 1:B:W-B+1
            z = double(Zs{i}(r:r+B-1, c:c+B-1)); I = abs(z).^2; nAll = nAll + 1;
            if mean(I(:)) >= 0.3 && mean(I(:)) <= 1.5 && max(I(:)) < 20, Q = cat(3, Q, z); end
        end
    end
    Zb{i} = Q;
end
nKeep = sum(cellfun(@(q) size(q, 3), Zb));
fprintf('%d images, %d blocks of %dx%d, %d kept as clean clutter\n', nImg, nAll, B, B, nKeep);
Zc = cat(3, Zb{:});

%% centroid and recentring (per image, images with >= 3 clean blocks)
fr = nan(1, nImg); fa = fr; occ = fr; wr = exp(1j*2*pi*(0:B-1).' / B);
Zr = cell(1, nImg);
for i = 1:nImg
    q = Zb{i}; if size(q, 3) < 3, Zr{i} = zeros(B, B, 0); continue; end
    Pw = mean(abs(fft2(q)).^2, 3);
    fr(i) = angle(sum(sum(Pw, 2) .* wr)) / (2*pi); fa(i) = angle(sum(sum(Pw, 1).' .* wr)) / (2*pi);
    occ(i) = mean(Pw(:) > 0.1 * max(Pw(:)));
    [rr, cc] = ndgrid(0:B-1, 0:B-1); mod_ = exp(-1j*2*pi*(fr(i)*rr + fa(i)*cc));
    Zr{i} = q .* mod_;
end
Zrc = cat(3, Zr{:}); Zc = cat(3, Zb{cellfun(@(q) size(q,3), Zr) > 0});
fprintf('spectral centroid (cycles/pixel, median over images): range %+.3f, azimuth %+.3f; band occupancy (bins above 10%% of peak): %.2f\n', ...
    median(fr, 'omitnan'), median(fa, 'omitnan'), median(occ, 'omitnan'));
fprintf('centroid spread across images (IQR): range %.3f, azimuth %.3f\n', iqr(fr(~isnan(fr))), iqr(fa(~isnan(fa))));

%% statistics
s0 = p3b_noise_stats(Zc, P); s1 = p3b_noise_stats(Zrc, P);
fprintf('\n%-26s %8s %8s %9s %9s %7s\n', 'condition', 'xmax', 'vratio', 'rho_rng', 'rho_az', 'CV');
fprintf('%-26s %8.3f %8.3f %9.2f %9.2f %7.2f\n', 'clean blocks, as formed', s0.xmax, s0.vratio, s0.rho_r, s0.rho_a, s0.cvI);
fprintf('%-26s %8.3f %8.3f %9.2f %9.2f %7.2f\n', 'clean blocks, recentred', s1.xmax, s1.vratio, s1.rho_r, s1.rho_a, s1.cvI);
M0 = xmap(Zc); M1 = xmap(Zrc);
[~, i0] = max(abs(M0(:))); [a0, b0] = ind2sub(size(M0), i0); [~, i1] = max(abs(M1(:))); [a1, b1] = ind2sub(size(M1), i1);
fprintf('largest cross-correlation lag (dr, da): as formed (%+d,%+d) = %+.3f | recentred (%+d,%+d) = %+.3f\n', a0-5, b0-5, M0(a0,b0), a1-5, b1-5, M1(a1,b1));
fprintf('corr(Re z(i), Im z(i+lag)), as formed, rows = dr -4..4, cols = da -4..4:\n'); disp(round(M0, 3));
fprintf('same after recentring:\n'); disp(round(M1, 3));
ok = @(s) s.xmax < 0.05 && s.vratio >= 0.9 && s.vratio <= 1.1;
fprintf('\nGATE as formed: %s | GATE recentred: %s\n', tf(ok(s0)), tf(ok(s1)));
if ok(s0), fprintf('-> H1: the earlier tile corners were contaminated; clean clutter passes. Train with a clean-clutter gate.\n');
elseif ok(s1), fprintf('-> H2: spectrum offset. Recentre every Gotcha image before denoising (intensity is unchanged); retrain with recentred tiles.\n');
else, fprintf('-> H3: genuine violation (or something I have not thought of). Do not train; descope MERLIN to MSTAR-type data in the Workbench.\n'); end
fprintf('Paste this whole output.\n');

function M = xmap(Z)
M = zeros(9, 9); S = size(Z, 1);
for dr = -4:4
    for da = -4:4
        a = real(Z(max(1,1-dr):min(S,S-dr), max(1,1-da):min(S,S-da), :)); b = imag(Z(max(1,1+dr):min(S,S+dr), max(1,1+da):min(S,S+da), :));
        M(dr+5, da+5) = sum(a(:) .* b(:)) / sqrt(sum(a(:).^2) * sum(b(:).^2));
    end
end
end
function s = tf(x), if x, s = 'PASS'; else, s = 'FAIL'; end, end
