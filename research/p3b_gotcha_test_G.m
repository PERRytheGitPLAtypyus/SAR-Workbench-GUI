%% P3B_GOTCHA_TEST_G  (= p3b_gotcha_test plus 'merlinG', the Gotcha-trained despeckler from p3b_train_gotcha; needs p3b_merlin_gotcha.mat)
% Original description: Point-target response on AFRL Gotcha backprojection images: does the MSTAR-trained despeckler keep corner reflectors sharp?
% Four 3-degree apertures (az 1-3, 86-88, 176-178, 266-268; pass 8 HH) so that every target is seen in its matching look direction.
% Images formed with 0.3 m pixels (MSTAR sampling). Methods: raw, MERLIN (MSTAR-trained, applied unchanged = a TRANSFER test),
% Lee 7, Lee 15, boxcar 5. Per visible target (>= 20 dB over the image median): peak ratio, -3 dB width ratios (x, y), peak-to-background change.
% Needs gotcha_find, gotcha_load, bp_gotcha, p3b_merlin.mat, p3b_denoise, despeckle_filters. Time about 2-3 min.
% PRE-SET READING: widths within 15 % of raw and peak ratio >= 0.8 = point targets preserved. A failure here is a transfer problem
% (different PSF / sampling from MSTAR), not necessarily a flaw of the method: the remedy would be training on Gotcha complex images.
clear; close all; clc;
root = pwd; passNum = 8; pol = 'HH';
aps = {1:3, 86:88, 176:178, 266:268}; expHead = [90 0 270 180];
mk = [ -32.14 42.54; -28.09 38.67; -13.86 37.70; -24.39 32.96; -32.50 33.41;  -5.12 22.98;
        -7.51 51.47; -15.55 42.96; -26.16 45.64; -18.58 33.53; -20.88 27.10; -13.24 32.09;
       -29.27 24.48; -26.15 17.50 ];
hd = [180 90 0 270 0 270 180 0 90 90 0 270 0 180].';
M = load('p3b_merlin.mat', 'net'); net = M.net; M2 = load('p3b_merlin_gotcha.mat', 'net'); netG = M2.net;
dx = 0.3; winM = 2.0; names = {'merlin', 'lee7', 'lee15', 'box5', 'merlinG'};
T = [];                                      % rows: aperture, target, method(1..4), peakRatio, wxRatio, wyRatio, pbDelta(dB)
for a = 1:numel(aps)
    [files, ~] = gotcha_find(root, passNum, pol, aps{a}); G = gotcha_load(files);
    o = struct('xlim', [-44 6], 'ylim', [10 58], 'dx', dx, 'z', -0.3, 'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
    [img, xv, yv] = bp_gotcha(G, o);
    I = abs(img).^2; sg = sqrt(median(I(:)) / log(2));
    Rm = double(p3b_denoise(net, img, sg)); RmG = double(p3b_denoise(netG, img, sg));
    A4 = single(abs(img));
    Rl7 = double(despeckle_filters(A4, 'lee', 7, 1)).^2; Rl15 = double(despeckle_filters(A4, 'lee', 15, 1)).^2;
    Rb5 = max(conv2(I, ones(5)/25, 'same'), 0);
    Rs = {Rm, Rl7, Rl15, Rb5, RmG};
    med = median(I(:));
    for t = find(hd == expHead(a)).'
        [~, ix] = min(abs(xv - mk(t,1))); [~, iy] = min(abs(yv - mk(t,2))); w = round(winM / dx);
        ry = max(1, iy-w):min(size(I,1), iy+w); rx = max(1, ix-w):min(size(I,2), ix+w);
        [pk, li] = max(reshape(I(ry, rx), [], 1)); if 10*log10(pk / med) < 20, continue; end
        [pyy, pxx] = ind2sub([numel(ry) numel(rx)], li); py = ry(pyy); px = rx(pxx);
        [wx0, wy0] = widths(I, py, px, dx);
        [yy, xx] = ndgrid(1:size(I,1), 1:size(I,2)); rr = hypot((yy - py) * dx, (xx - px) * dx);
        bg0 = median(I(rr > 3 & rr < 8));
        for q = 1:5
            R = Rs{q};
            sy = max(1, py-2):min(size(R,1), py+2); sx = max(1, px-2):min(size(R,2), px+2);
            [pq, lq] = max(reshape(R(sy, sx), [], 1)); [qy, qx] = ind2sub([numel(sy) numel(sx)], lq);
            [wx, wy] = widths(R, sy(qy), sx(qx), dx);
            bg = median(R(rr > 3 & rr < 8));
            T = [T; a t q pq / pk wx / wx0 wy / wy0 10*log10((pq / bg) / (pk / bg0))]; %#ok<AGROW>
        end
    end
    if a == 1
        fig = figure('Visible', 'off', 'Position', [50 50 2000 450]); tiledlayout(1, 4, 'TileSpacing', 'compact');
        for q = [0 1 5 3]
            nexttile; if q == 0, Q = I; ttl = 'raw'; else, Q = Rs{q}; ttl = names{q}; end
            imagesc(xv, yv, 10*log10(Q / max(Q(:)) + eps), [-45 0]); axis image xy; colormap gray; title(ttl);
        end
        exportgraphics(fig, 'p3b_gotcha_compare_G.png', 'Resolution', 120); close(fig);
    end
end
fprintf('visible target measurements: %d (target, aperture pairs)\n\n', size(T, 1) / 5);
fprintf('%-8s %6s | %10s %10s %10s %14s\n', 'method', 'n', 'peak ratio', 'width x', 'width y', 'peak/bkg (dB)');
for q = 1:5
    j = T(:,3) == q;
    fprintf('%-8s %6d | %10.2f %10.2f %10.2f %+14.2f\n', names{q}, nnz(j), median(T(j,4), 'omitnan'), median(T(j,5), 'omitnan'), median(T(j,6), 'omitnan'), median(T(j,7), 'omitnan'));
end
save('p3b_gotcha_test_G.mat', 'T', 'names');
fprintf('\nratios are method/raw (1 = unchanged; width > 1.15 = blurred). Attach p3b_gotcha_compare_G.png and paste this whole output.\n');

function [wx, wy] = widths(Q, py, px, dx)
h = 40; cx = max(1, px-h):min(size(Q,2), px+h); cy = max(1, py-h):min(size(Q,1), py+h);
wx = halfwidth(Q(py, cx), px - cx(1) + 1, dx); wy = halfwidth(Q(cy, px).', py - cy(1) + 1, dx);
end

function w = halfwidth(p, i0, dx)
pk = p(i0); hlf = pk / 2; l = i0; r = i0;
while l > 1 && p(l) > hlf, l = l - 1; end
while r < numel(p) && p(r) > hlf, r = r + 1; end
if p(l) > hlf || p(r) > hlf, w = NaN; return; end
xl = l + (hlf - p(l)) / (p(l+1) - p(l)); xr = (r - 1) + (p(r-1) - hlf) / (p(r-1) - p(r));
w = (xr - xl) * dx;
end
