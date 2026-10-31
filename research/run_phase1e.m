%% RUN_PHASE1E  Four look directions: do the table targets light up according to their headings?
% Observation behind this (run_phase1d, platform azimuth 0-10 deg): the three brightest table
% targets (15TR03C, DR-02, DR-03) are exactly the three with heading 90. Hypothesis: heading is
% the compass bearing a reflector faces (x = east, y = north), so a platform at math-angle phi
% (measured from +x) should see heading 90 - phi.  Four 10-file apertures:
%   az 1-10 (phi~5) -> 90,  az 86-95 (phi~90) -> 0,  az 176-185 (phi~180) -> 270,  az 266-275 (phi~270) -> 180
% It also splits the remaining ~0.7 m offset to the table into
%   - the same (dx,dy) at every look angle  = translation of the frame / origin
%   - the same shift ALONG the line of sight = a range bias
% after removing layover from the target heights in the table (z).
% Run from the project root. Needs gotcha_find, gotcha_load, gotcha_sanity, bp_gotcha. ~4 min.
clear; close all; clc;
root = pwd; passNum = 8; pol = 'HH';
aps = {1:10, 86:95, 176:185, 266:275};
expHead = [90 0 270 180];
names = {'15TR01C','15TR03C','15TR04C','15TR05C','15TR06C','15TR07C','27TR01C', ...
         'DR-01','DR-02','DR-03','DR-04','DR-05','DR-06','DR-07'};
mk = [ -32.14 42.54; -28.09 38.67; -13.86 37.70; -24.39 32.96; -32.50 33.41;  -5.12 22.98;
        -7.51 51.47; -15.55 42.96; -26.16 45.64; -18.58 33.53; -20.88 27.10; -13.24 32.09;
       -29.27 24.48; -26.15 17.50 ];
zt = [-0.53 -0.42 -0.05 -0.33 -0.57 -0.05 -0.09 -0.13 -0.43 -0.18 -0.23 -0.09 -0.48 -0.44].';
hd = [180 90 0 270 0 270 180 0 90 90 0 270 0 180].';
zc = -0.3; pad = 4; dx = 0.05; win = 2.0; strong = 20;     % strong: dB over median
xl = [min(mk(:,1))-pad max(mk(:,1))+pad]; yl = [min(mk(:,2))-pad max(mk(:,2))+pad];

nA = numel(aps); R = nan(14, 3, nA); phiM = zeros(1, nA); tpsi = zeros(1, nA); imgs = cell(1, nA);
for s = 1:nA
    [files, az] = gotcha_find(root, passNum, pol, aps{s});
    if numel(files) ~= numel(aps{s}), fprintf('missing azimuth files for aperture %d\n', s); return; end
    G = gotcha_load(files);
    if ~gotcha_sanity(G), fprintf('sanity failed for az %d-%d\n', min(az), max(az)); return; end
    close(gcf);
    phi = unwrap(atan2(G.pos(2,:), G.pos(1,:)));
    phiM(s) = mean(phi);
    tpsi(s) = tan(asin(median(G.pos(3,:))/median(vecnorm(G.pos, 2, 1))));
    o = struct('xlim',xl,'ylim',yl,'dx',dx,'z',zc,'pad',8,'conj',0,'afr',0,'afp',0);
    tic; [img, xv, yv] = bp_gotcha(G, o); fprintf('az %d-%d imaged in %.0f s\n', min(az), max(az), toc);
    A = abs(img);
    R(:,:,s) = score_targets(A, xv, yv, mk, win);
    imgs{s} = 20*log10(A/max(A(:)) + eps);
end

%% table: dB over median per target and aperture
fprintf('\n--- peak dB over median (* = at least %d dB) ---\n', strong);
fprintf('%-8s %4s |', 'target', 'head');
for s = 1:nA, fprintf(' az%3d-%-3d |', min(aps{s}), max(aps{s})); end
fprintf('\n');
for k = 1:14
    fprintf('%-8s %4d |', names{k}, hd(k));
    for s = 1:nA
        fl = ' '; if R(k,1,s) >= strong, fl = '*'; end
        fprintf(' %7.1f%s  |', R(k,1,s), fl);
    end
    fprintf('\n');
end
fprintf('\nheading prediction (platform azimuth -> expected heading):\n');
for s = 1:nA
    ex = hd == expHead(s); st = R(:,1,s) >= strong;
    fprintf('  az %3d-%-3d  platform %6.1f deg -> heading %3d | expected-heading targets that are strong: %d/%d | strong targets with expected heading: %d/%d\n', ...
        min(aps{s}), max(aps{s}), mod(rad2deg(phiM(s)), 360), expHead(s), nnz(ex & st), nnz(ex), nnz(ex & st), nnz(st));
end

%% offset decomposition on the strong targets
fprintf('\n--- offset (peak minus table, m) of strong targets after removing layover ---\n');
fprintf('    layover along the line of sight = tan(grazing) * (z_target - %.1f); dx,dy in the table frame\n', zc);
for s = 1:nA
    S = R(:,1,s) >= strong;
    if nnz(S) < 2, fprintf('  az %3d-%-3d: only %d strong target(s), skipped\n', min(aps{s}), max(aps{s}), nnz(S)); continue; end
    g = [cos(phiM(s)) sin(phiM(s))]; gp = [-sin(phiM(s)) cos(phiM(s))];
    d = R(S,2:3,s) - tpsi(s)*(zt(S) - zc)*g;
    al = d*g.'; ac = d*gp.';
    fprintf('  az %3d-%-3d (%d targets): dx %+.2f +/- %.2f  dy %+.2f +/- %.2f | along line of sight %+.2f +/- %.2f  across %+.2f +/- %.2f\n', ...
        min(aps{s}), max(aps{s}), nnz(S), mean(d(:,1)), std(d(:,1)), mean(d(:,2)), std(d(:,2)), mean(al), std(al), mean(ac), std(ac));
end
fprintf('Reading it: same (dx,dy) in every row = frame translation; same "along" with dx,dy rotating = range bias.\n');

%% picture: 4 looks, markers coloured by heading
hv = [0 90 180 270]; hc = [0 1 1; 0 1 0; 1 0 1; 1 1 0];
figure('Name', 'four looks', 'Position', [50 50 1300 1000]);
tiledlayout(2, 2, 'TileSpacing', 'compact');
for s = 1:nA
    nexttile; imagesc(xv, yv, imgs{s}); axis xy equal tight; clim([-40 0]); colormap gray; hold on;
    for k = 1:14
        plot(mk(k,1), mk(k,2), 'o', 'Color', hc(hv == hd(k), :), 'MarkerSize', 12, 'LineWidth', 1.2);
    end
    title(sprintf('az %d-%d (platform %.0f deg, expect heading %d)', min(aps{s}), max(aps{s}), mod(rad2deg(phiM(s)), 360), expHead(s)));
    xlabel('x (m)'); ylabel('y (m)');
end
exportgraphics(gcf, 'gotcha_4looks.png', 'Resolution', 200);
save('gotcha_4looks.mat', 'R', 'phiM', 'aps', 'names', 'mk', 'hd', 'zt');
fprintf('\nMarker colours: heading 0 cyan, 90 green, 180 magenta, 270 yellow.\n');
fprintf('Attach gotcha_4looks.png and paste this whole output.\n');

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
