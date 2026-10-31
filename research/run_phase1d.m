%% RUN_PHASE1D  Wider aperture, all 14 table targets, signed offsets, af relation.
% Run from the project root after run_phase1c. Needs gotcha_find, gotcha_load, bp_gotcha.
% Convention: conj=0 (nominal). conj=1 is the same image mirrored, so focus metrics
% cannot separate them (run_phase1c: 0.1 dB apart), so it is not scanned here.
% Runtime: a few minutes (0.05 m grid so a ~0.1 m cross-range mainlobe is sampled).
clear; close all; clc;
root = pwd; passNum = 8; pol = 'HH'; c = 299792458;
azSets = {1:3, 1:10};
afs = [0 0; 1 1; -1 -1];                 % [afr afp]; mixed signs destroyed focus last time
names = {'15TR01C','15TR03C','15TR04C','15TR05C','15TR06C','15TR07C','27TR01C', ...
         'DR-01','DR-02','DR-03','DR-04','DR-05','DR-06','DR-07'};
mk = [ -32.14 42.54; -28.09 38.67; -13.86 37.70; -24.39 32.96; -32.50 33.41;  -5.12 22.98;
        -7.51 51.47; -15.55 42.96; -26.16 45.64; -18.58 33.53; -20.88 27.10; -13.24 32.09;
       -29.27 24.48; -26.15 17.50 ];
zc = -0.3; pad = 4; dx = 0.05; win = 1.5; thr = 13;   % thr: detection threshold, dB over median
xl = [min(mk(:,1))-pad max(mk(:,1))+pad]; yl = [min(mk(:,2))-pad max(mk(:,2))+pad];

%% 0. hypothesis: af.ph_correct is the same correction as af.r_correct, in radians
f1 = gotcha_find(root, passNum, pol, 1);
if isempty(f1), return; end
S = load(f1{1}); d = S.data;
rc = double(d.af.r_correct(:)); pc = double(d.af.ph_correct(:)); fr = double(d.freq(:));
cand = [fr(1) mean(fr) fr(end)]; cn = {'f_min','f_center','f_max'};
fprintf('--- af relation: circular error between ph_correct and +/-4*pi*f*r_correct/c ---\n');
for k = 1:3
    for sg = [1 -1]
        e = abs(angle(exp(1j*(pc - sg*4*pi*cand(k)/c*rc))));
        fprintf('  sign %+d, f = %-8s (%.4f GHz): median %.3f rad, max %.3f rad\n', sg, cn{k}, cand(k)/1e9, median(e), max(e));
    end
end
fprintf('  (relation holds if median error < ~0.1 rad; unrelated phases would give ~1.6)\n\n');

%% 1. image at 3 and 10 azimuth files, three af settings each
res = cell(numel(azSets), size(afs,1)); bestScore = -inf;
for s = 1:numel(azSets)
    [files, az] = gotcha_find(root, passNum, pol, azSets{s});
    if isempty(files), return; end
    G = gotcha_load(files);
    B = G.freq(end)-G.freq(1); fc = mean(G.freq);
    psi = asin(median(G.pos(3,:))/median(vecnorm(G.pos,2,1)));
    phi = unwrap(atan2(G.pos(2,:), G.pos(1,:)));
    dphi = abs(phi(end)-phi(1));
    wr = 0.886*c/(2*B*cos(psi)); wc = 0.886*(c/fc)/(2*cos(psi)*dphi);
    fprintf('=== az %d-%d: %d pulses, sweep %.2f deg, platform azimuth %.1f deg, grazing %.1f deg ===\n', ...
        min(az), max(az), size(G.fp,2), rad2deg(dphi), rad2deg(mean(phi)), rad2deg(psi));
    fprintf('    theory -3 dB widths on the ground plane: ground-range %.2f m, cross-range %.2f m\n', wr, wc);
    for a = 1:size(afs,1)
        o = struct('xlim',xl,'ylim',yl,'dx',dx,'z',zc,'pad',8,'conj',0,'afr',afs(a,1),'afp',afs(a,2));
        tic; [img, xv, yv] = bp_gotcha(G, o); t = toc;
        A = abs(img);
        R = score_targets(A, xv, yv, mk, win);
        nf = nullrate(A, xv, yv, win, thr, 300);
        det = R(:,1) >= thr;
        w = peakwidths(A, xv, yv);
        if any(det), mo = mean(R(det,2:3),1); else, mo = [NaN NaN]; end
        fprintf('  af(%+d,%+d): %2d/14 detected, null false-alarm %.0f%%, mean offset of detected dx %+.2f dy %+.2f m | strongest %.1f dB, widths x %.2f y %.2f m | %.0f s\n', ...
            afs(a,1), afs(a,2), nnz(det), 100*nf, mo(1), mo(2), 20*log10(max(A(:))/median(A(:))), w(1), w(2), t);
        res{s,a} = R;
        if s == numel(azSets) && sum(R(:,1)) > bestScore
            bestScore = sum(R(:,1)); bImg = img; bXv = xv; bYv = yv; bAf = afs(a,:); bAz = az;
        end
    end
end

%% 2. per-target detail for the widest aperture
s = numel(azSets);
fprintf('\n--- per-target detail, az %d-%d  (dB over median; dx,dy = peak minus table, m; * = detected) ---\n', min(bAz), max(bAz));
fprintf('%-8s |', 'target');
for a = 1:size(afs,1), fprintf('   af(%+d,%+d):  dB     dx     dy |', afs(a,1), afs(a,2)); end
fprintf('\n');
for k = 1:numel(names)
    fprintf('%-8s |', names{k});
    for a = 1:size(afs,1)
        r = res{s,a}(k,:); fl = ' '; if r(1) >= thr, fl = '*'; end
        fprintf('  %6.1f%s  %+6.2f %+6.2f |', r(1), fl, r(2), r(3));
    end
    fprintf('\n');
end
fprintf('\nbest by summed peak dB over the 14 targets: af(%+d,%+d)\n', bAf(1), bAf(2));

%% 3. picture + data
A = abs(bImg); dB = 20*log10(A/max(A(:)) + eps);
figure('Name','wide aperture'); imagesc(bXv, bYv, dB); axis xy equal tight; clim([-40 0]); colormap gray; colorbar; hold on;
plot(mk(:,1), mk(:,2), 'go', 'MarkerSize', 14, 'LineWidth', 1.2);
text(mk(:,1)+0.8, mk(:,2), names, 'Color', 'g', 'FontSize', 8);
xlabel('x (m)'); ylabel('y (m)');
title(sprintf('az %d-%d, conj=0, af(%+d,%+d); green = table targets', min(bAz), max(bAz), bAf(1), bAf(2)));
exportgraphics(gcf, 'gotcha_bp_wide.png', 'Resolution', 200);
save('gotcha_bp_wide.mat', 'bImg', 'bXv', 'bYv', 'bAf', 'bAz');
fprintf('Attach gotcha_bp_wide.png and paste this whole output.\n');

%% local functions
function R = score_targets(A, xv, yv, mk, win)
% [peak dB over median, dx, dy] of the strongest pixel within +-win of each table target
bg = median(A(:)); R = zeros(size(mk,1), 3);
for k = 1:size(mk,1)
    ix = find(xv >= mk(k,1)-win & xv <= mk(k,1)+win);
    iy = find(yv >= mk(k,2)-win & yv <= mk(k,2)+win);
    W = A(iy, ix); [m, i] = max(W(:)); [r, cc] = ind2sub(size(W), i);
    R(k,:) = [20*log10(m/bg), xv(ix(cc))-mk(k,1), yv(iy(r))-mk(k,2)];
end
end

function f = nullrate(A, xv, yv, win, thr, n)
% fraction of random windows whose peak exceeds thr (upper bound: real targets count too)
rng(1); bg = median(A(:)); hit = 0;
for k = 1:n
    cx = xv(1)+win + rand*(xv(end)-xv(1)-2*win);
    cy = yv(1)+win + rand*(yv(end)-yv(1)-2*win);
    ix = xv >= cx-win & xv <= cx+win; iy = yv >= cy-win & yv <= cy+win;
    hit = hit + (20*log10(max(max(A(iy,ix)))/bg) >= thr);
end
f = hit/n;
end

function w = peakwidths(A, xv, yv)
% -3 dB widths (m) along image x and y of the global maximum, spline-interpolated
[~, k] = max(A(:)); [r, c] = ind2sub(size(A), k);
xi = linspace(max(xv(1), xv(c)-1), min(xv(end), xv(c)+1), 2001);
yi = linspace(max(yv(1), yv(r)-1), min(yv(end), yv(r)+1), 2001);
ax = interp1(xv, A(r,:), xi, 'spline'); ay = interp1(yv, A(:,c).', yi, 'spline');
wx = xi(ax >= max(ax)/sqrt(2)); wy = yi(ay >= max(ay)/sqrt(2));
w = [max(wx)-min(wx), max(wy)-min(wy)];
end
