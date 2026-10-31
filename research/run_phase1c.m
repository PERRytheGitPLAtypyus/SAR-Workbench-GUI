%% RUN_PHASE1C  Settle conj and af using targets that are actually visible.
% Last run: only 15TR03C and DR-03 (plus one very bright non-table point) showed up
% at az 1-3, so the 14-marker contrast score was diluted. Here we score ONLY those
% targets by peak height, position error and -3 dB width, for every conj/af combo.
% Expectation if conj=0 is the true convention: higher peak, smaller width, and
% offset ~0.3 m or less. Run from the project root.
clear; close all; clc;
root = pwd; passNum = 8; pol = 'HH';
[files, az] = gotcha_find(root, passNum, pol, 1:3);
if isempty(files), return; end
G3 = gotcha_load(files);

names = {'15TR01C','15TR03C','15TR04C','15TR05C','15TR06C','15TR07C','27TR01C', ...
         'DR-01','DR-02','DR-03','DR-04','DR-05','DR-06','DR-07'};
mk = [ -32.14 42.54; -28.09 38.67; -13.86 37.70; -24.39 32.96; -32.50 33.41; -5.12 22.98;
        -7.51 51.47; -15.55 42.96; -26.16 45.64; -18.58 33.53; -20.88 27.10; -13.24 32.09;
       -29.27 24.48; -26.15 17.50 ];
T  = [mk(2,:); mk(10,:); -15.87 21.22];       % 15TR03C, DR-03, and the bright non-table point
tn = {'15TR03C','DR-03','bright(non-table)'};
zc = -0.3; hw = 2.5; dx = 0.05;
afs = [0 0; 1 0; -1 0; 0 1; 0 -1; 1 1; -1 -1; 1 -1; -1 1];   % [afr afp]

fprintf('conj afr afp | %-9s peak dB / offset m / width x,y m  (x3 targets: %s)\n', '', strjoin(tn, ', '));
R = zeros(0, 3 + 3*4);
for conj = 0:1
    for a = 1:size(afs,1)
        row = [];
        for t = 1:size(T,1)
            c0 = (1-2*conj) * T(t,:);        % conj=1 images the scene point-reflected
            o = struct('xlim', c0(1)+[-hw hw], 'ylim', c0(2)+[-hw hw], 'dx', dx, 'z', zc, ...
                       'pad', 8, 'conj', conj, 'afr', afs(a,1), 'afp', afs(a,2));
            [I, xv, yv] = bp_gotcha(G3, o);
            row = [row, peakstats(I, xv, yv, c0)]; %#ok<AGROW>
        end
        R(end+1,:) = [conj afs(a,:) row]; %#ok<SAGROW>
        fprintf(' %d   %+d  %+d |', conj, afs(a,1), afs(a,2));
        for t = 1:3
            q = row(4*t-3:4*t);
            fprintf('  %5.1f / %.2f / %.2f,%.2f |', q(1), q(2), q(3), q(4));
        end
        fprintf('\n');
    end
end

score = mean(R(:,[4 8]), 2);                 % mean peak dB over the two table targets
[~, b] = max(score);
conj = R(b,1); afr = R(b,2); afp = R(b,3);
fprintf('\nBEST by mean peak height on table targets: conj=%d afr=%+d afp=%+d (%.1f dB)\n', conj, afr, afp, score(b));
base = find(R(:,1)==0 & R(:,2)==0 & R(:,3)==0);
fprintf('conj=0, no af: %.1f dB   conj=1, no af: %.1f dB   (difference %.1f dB)\n', ...
    score(base), score(R(:,1)==1 & R(:,2)==0 & R(:,3)==0), score(base) - score(R(:,1)==1 & R(:,2)==0 & R(:,3)==0));

%% full image in the TABLE frame with the best setting
Mm = (1-2*conj) * mk;
pad = 5;
o = struct('xlim',[min(Mm(:,1))-pad max(Mm(:,1))+pad], 'ylim',[min(Mm(:,2))-pad max(Mm(:,2))+pad], ...
           'dx',0.15,'z',zc,'pad',8,'conj',conj,'afr',afr,'afp',afp);
[img, xv, yv] = bp_gotcha(G3, o);
A = abs(img); dB = 20*log10(A/max(A(:)) + eps);
figure('Name','best'); imagesc(xv, yv, dB); axis xy equal tight; clim([-40 0]); colormap gray; colorbar; hold on;
plot(Mm(:,1), Mm(:,2), 'go', 'MarkerSize', 14, 'LineWidth', 1.2);
text(Mm(:,1)+0.8, Mm(:,2), names, 'Color', 'g', 'FontSize', 8);
xlabel('x (m)'); ylabel('y (m)');
title(sprintf('conj=%d afr=%+d afp=%+d (green = table targets)', conj, afr, afp));
exportgraphics(gcf, 'gotcha_bp_best.png', 'Resolution', 200);
save('gotcha_bp_best.mat', 'img', 'xv', 'yv', 'o', 'az');
fprintf('\nAttach gotcha_bp_best.png and paste this whole output.\n');

function q = peakstats(I, xv, yv, c0)
% [peak dB (absolute), offset from c0 (m), -3 dB width x, width y] of the window's strongest pixel
A = abs(I); [m, k] = max(A(:)); [r, c] = ind2sub(size(A), k);
off = hypot(xv(c)-c0(1), yv(r)-c0(2));
xi = linspace(max(xv(1), xv(c)-1), min(xv(end), xv(c)+1), 2001);
yi = linspace(max(yv(1), yv(r)-1), min(yv(end), yv(r)+1), 2001);
ax = interp1(xv, A(r,:), xi, 'spline');  ay = interp1(yv, A(:,c).', yi, 'spline');
wx = xi(ax >= max(ax)/sqrt(2));  wy = yi(ay >= max(ay)/sqrt(2));
q = [20*log10(m), off, max(wx)-min(wx), max(wy)-min(wy)];
end
