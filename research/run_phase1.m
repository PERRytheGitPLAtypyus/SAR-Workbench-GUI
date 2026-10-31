%% RUN_PHASE1B  Ground-truth check against the AFRL calibration-target table.
% Table 1 of the Gotcha challenge-problem paper (AFRL SDMS) lists 14 trihedrals/
% dihedrals with x,y,z in metres. The paper does NOT state the frame origin/axes,
% so this script TESTS whether the table frame == our image frame, and which
% conj/autofocus setting puts bright scatterers on those positions.
% Why this and not entropy: a wrong conj gives a point-reflected (x,y)->(-x,-y)
% image that is almost as sharp, so entropy cannot tell the two apart.
clear; close all; clc;
root = pwd; passNum = 8; pol = 'HH';
[files, az] = gotcha_find(root, passNum, pol, 1:3);
if isempty(files), return; end
G1 = gotcha_load(files(1));
G3 = gotcha_load(files);

names = {'15TR01C','15TR03C','15TR04C','15TR05C','15TR06C','15TR07C','27TR01C', ...
         'DR-01','DR-02','DR-03','DR-04','DR-05','DR-06','DR-07'};
mk = [ -32.14 42.54 -0.53; -28.09 38.67 -0.42; -13.86 37.70 -0.05; -24.39 32.96 -0.33;
       -32.50 33.41 -0.57;  -5.12 22.98 -0.05;  -7.51 51.47 -0.09; -15.55 42.96 -0.13;
       -26.16 45.64 -0.43; -18.58 33.53 -0.18; -20.88 27.10 -0.23; -13.24 32.09 -0.09;
       -29.27 24.48 -0.48; -26.15 17.50 -0.44 ];
zc = -0.3; pad = 5;
gridFor = @(M, dx) struct('xlim',[min(M(:,1))-pad max(M(:,1))+pad], ...
                          'ylim',[min(M(:,2))-pad max(M(:,2))+pad],'dx',dx,'z',zc,'pad',8);

%% 1. scan configurations on file 1 (fast)
fprintf('conj afr afp | marker dB | random dB | CONTRAST dB\n');
res = zeros(0,6);
for conj = 0:1
    M = (1-2*conj) * mk(:,1:2);                 % conj=1 -> expect point-reflected positions
    g = gridFor(M, 0.2);
    for afr = [0 1 -1]
        for afp = [0 1 -1]
            if isempty(G1.af_r) && (afr ~= 0 || afp ~= 0), continue; end
            o = g; o.conj = conj; o.afr = afr; o.afp = afp;
            [I, xv, yv] = bp_gotcha(G1, o);
            [sc, ctl] = mscore(I, xv, yv, M, 1.0);
            res(end+1,:) = [conj afr afp sc ctl sc-ctl]; %#ok<SAGROW>
            fprintf(' %d   %+d  %+d |  %6.1f   |  %6.1f   |  %6.1f\n', conj, afr, afp, sc, ctl, sc-ctl);
        end
    end
end
[~, b] = max(res(:,6));
conj = res(b,1); afr = res(b,2); afp = res(b,3);
fprintf('\nBEST: conj=%d afr=%+d afp=%+d  contrast=%.1f dB\n', conj, afr, afp, res(b,6));
fprintf('Reading it: contrast >~ 10 dB = markers sit on bright scatterers (frame confirmed).\n');
fprintf('            contrast ~ 0-3 dB for every row = table frame != image frame; use the peak list below.\n');

%% 2. full image (3 files) with the best configuration
M = (1-2*conj) * mk(:,1:2);
o = gridFor(M, 0.15); o.conj = conj; o.afr = afr; o.afp = afp;
tic; [img, xv, yv] = bp_gotcha(G3, o); fprintf('BP time %.1f s\n', toc);
A = abs(img); dB = 20*log10(A/max(A(:)) + eps);
figure('Name','Gotcha BP + table'); imagesc(xv, yv, dB); axis xy equal tight; clim([-40 0]); colormap gray; colorbar;
hold on; plot(M(:,1), M(:,2), 'go', 'MarkerSize', 14, 'LineWidth', 1.2);
text(M(:,1)+0.8, M(:,2), names, 'Color', 'g', 'FontSize', 8);
xlabel('x (m)'); ylabel('y (m)');
title(sprintf('pass %d %s az %d-%d  conj=%d afr=%+d afp=%+d (green = table targets)', passNum, pol, min(az), max(az), conj, afr, afp));
exportgraphics(gcf, 'gotcha_bp_calib.png', 'Resolution', 200);
save('gotcha_bp_calib.mat', 'img', 'xv', 'yv', 'o', 'az', 'mk');

%% 3. strongest peaks and their nearest table target
BW = imregionalmax(A) & A > 0.03*max(A(:));
[pr, pc] = find(BW); a = A(sub2ind(size(A), pr, pc));
[a, ix] = sort(a, 'descend'); pr = pr(ix); pc = pc(ix);
fprintf('\nTop peaks:   x(m)    y(m)   dB rel max   nearest table target (dist)\n');
for k = 1:min(12, numel(a))
    px = xv(pc(k)); py = yv(pr(k));
    [dm, j] = min(hypot(M(:,1)-px, M(:,2)-py));
    fprintf('          %7.2f %7.2f  %8.1f      %-8s %.2f m\n', px, py, 20*log10(a(k)/a(1)), names{j}, dm);
end

%% 4. resolution of the strongest peak (spline-interpolated, so not quantised by the grid)
xi = linspace(xv(pc(1))-1.5, xv(pc(1))+1.5, 3001);
yi = linspace(yv(pr(1))-1.5, yv(pr(1))+1.5, 3001);
ax = interp1(xv, A(pr(1),:), xi, 'spline');   ay = interp1(yv, A(:,pc(1)).', yi, 'spline');
wx = xi(ax >= max(ax)/sqrt(2));  wy = yi(ay >= max(ay)/sqrt(2));
fprintf('\nstrongest peak -3 dB width: x %.2f m, y %.2f m   (theory: range 0.24*0.89=0.21 m, cross-range ~0.27 m)\n', ...
    max(wx)-min(wx), max(wy)-min(wy));
fprintf('Attach gotcha_bp_calib.png and paste this whole output.\n');

function [sc, ctl] = mscore(I, xv, yv, M, rad)
% mean dB of the local max within rad of each marker, vs 200 random positions
A = abs(I); bg = median(A(:));
[X, Y] = meshgrid(xv, yv);
v = zeros(size(M,1), 1);
for k = 1:size(M,1)
    m = (X-M(k,1)).^2 + (Y-M(k,2)).^2 <= rad^2;
    v(k) = max(A(m));
end
sc = mean(20*log10(v/bg + eps));
rng(1); vr = zeros(200,1);
for k = 1:200
    cx = xv(1) + rand*(xv(end)-xv(1)); cy = yv(1) + rand*(yv(end)-yv(1));
    m = (X-cx).^2 + (Y-cy).^2 <= rad^2;
    vr(k) = max(A(m));
end
ctl = mean(20*log10(vr/bg + eps));
end