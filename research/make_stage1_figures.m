%% MAKE_STAGE1_FIGURES  Reference simulation -> Fig. A.1, A.2, A.3 + metrics table
% Self-contained (base MATLAB only). Put this file together with sar_bp_pixels.m,
% profile_metrics.m and save_sar_image.m in the SAR project folder, then run it.
% Outputs go to .\figures  (PNG, 300 dpi) and .\figures\stage1_metrics.txt
clear; clc; close all;
outDir = fullfile(pwd, 'figures');  if ~exist(outDir, 'dir'), mkdir(outDir); end
set(groot, 'defaultAxesFontName', 'Times New Roman', 'defaultAxesFontSize', 12, ...
           'defaultTextFontName', 'Times New Roman', 'defaultTextFontSize', 12);

%% 1) Parameters  -- EDIT to match your own simulator settings
c = 299792458;   fc = 9.6e9;   B = 600e6;   K = 128;   N = 181;
apert = 30;      R0 = 5000;    snr_dB = 30;
tgt = [  0   0  1;        % x (m)  y (m)  amplitude  -> replace with YOUR four target positions
         4   3  1;
        -4   2  1;
         2  -4  1];
f  = fc + ((0:K-1)' - (K-1)/2) * (B/(K-1));        % K x 1
th = linspace(-apert/2, apert/2, N) * pi/180;      % 1 x N
px = R0*cos(th);  py = R0*sin(th);
wf = 0.54 - 0.46*cos(2*pi*(0:K-1)'/(K-1));         % Hamming over frequency
wa = 0.54 - 0.46*cos(2*pi*(0:N-1) /(N-1));         % Hamming over pulses

%% 2) Phase history (point-scatterer model), deskewed to the scene centre
simph = @(t) local_sim(t, f, px, py, R0, c);
S  = simph(tgt);                                    % four targets, noise-free
S1 = simph(tgt(1,:));                               % isolated target for metrics
rng(1);
nPow = mean(abs(S(:)).^2) / 10^(snr_dB/10);
Sn = S + sqrt(nPow/2) * (randn(K,N) + 1j*randn(K,N));

%% 3) Fig. A.1  target layout, phase history, one range-compressed pulse
ang = th*180/pi;
rg  = -20:0.01:20;  E = exp(1j*4*pi*((f - mean(f))*rg)/c);
n0  = (N+1)/2;  rc0 = (wf .* Sn(:,n0)).' * E;
fig = figure('Color','w','Position',[100 100 900 700]);
subplot(2,2,1); plot(tgt(:,1), tgt(:,2), 'ko', 'MarkerFaceColor','k', 'MarkerSize',7);
grid on; axis equal; xlim([-6 6]); ylim([-6 6]); xlabel('x (m)'); ylabel('y (m)'); title('(a) Target layout');
subplot(2,2,2); imagesc(ang, f/1e9, 20*log10(abs(Sn)/max(abs(Sn(:))))); axis xy; colorbar;
xlabel('Aperture angle (deg)'); ylabel('Frequency (GHz)'); title('(b) Phase-history magnitude (dB)');
subplot(2,2,3); imagesc(ang, f/1e9, angle(Sn)); axis xy; colorbar;
xlabel('Aperture angle (deg)'); ylabel('Frequency (GHz)'); title('(c) Phase-history phase (rad)');
subplot(2,2,4); plot(rg, 20*log10(abs(rc0)/max(abs(rc0))), 'k'); grid on; xlim([-8 8]); ylim([-70 3]);
xlabel('Differential range (m)'); ylabel('Magnitude (dB)'); title('(d) Range profile, centre pulse');
exportgraphics(fig, fullfile(outDir,'fig_A1_phase_history.png'), 'Resolution', 300);

%% 4) Fig. A.2  backprojection image (noisy data), x = range direction, y = cross-range
x = -6:0.04:6;  y = -6:0.01:6;  [X, Y] = meshgrid(x, y);
tic; img = sar_bp_pixels(Sn, f, th, R0, X, Y, wf, wa, c); tBP = toc;
save_sar_image(img, x, y, fullfile(outDir,'fig_A2_focused_image.png'), 40);
hold on; plot(tgt(:,1), tgt(:,2), 'ro', 'MarkerSize', 12, 'LineWidth', 1.2);   % true positions
exportgraphics(gcf, fullfile(outDir,'fig_A2_focused_image_marked.png'), 'Resolution', 300);

%% 5) Fig. A.3  range and cross-range cuts through the isolated target + metrics
xr = -2:0.002:2;     yr = -0.4:0.0005:0.4;
ar = sar_bp_pixels(S1, f, th, R0, xr, zeros(size(xr)), wf, wa, c);
ac = sar_bp_pixels(S1, f, th, R0, zeros(size(yr)), yr, wf, wa, c);
mr = profile_metrics(xr, ar);   mc = profile_metrics(yr, ac);
fig = figure('Color','w','Position',[100 100 900 380]);
subplot(1,2,1); plot(xr, 20*log10(abs(ar)/max(abs(ar))), 'k'); hold on; plot([xr(1) xr(end)], [-3 -3], 'r--');
grid on; ylim([-80 3]); xlabel('Range offset (m)'); ylabel('Magnitude (dB)');
title(sprintf('(a) Range cut: IRW %.3f m, PSLR %.1f dB', mr.IRW, mr.PSLR_dB));
subplot(1,2,2); plot(yr, 20*log10(abs(ac)/max(abs(ac))), 'k'); hold on; plot([yr(1) yr(end)], [-3 -3], 'r--');
grid on; ylim([-80 3]); xlabel('Cross-range offset (m)'); ylabel('Magnitude (dB)');
title(sprintf('(b) Cross-range cut: IRW %.4f m, PSLR %.1f dB', mc.IRW, mc.PSLR_dB));
exportgraphics(fig, fullfile(outDir,'fig_A3_quality_plots.png'), 'Resolution', 300);

%% 6) Metrics table for the report (copy into Word)
lam = c/fc;  dth = apert*pi/180;
fid = fopen(fullfile(outDir,'stage1_metrics.txt'), 'w');
fprintf(fid, 'Parameters: fc=%.2f GHz, B=%.0f MHz, K=%d freq steps, N=%d pulses, aperture=%d deg, R0=%d m, SNR=%d dB, Hamming windows\n', fc/1e9, B/1e6, K, N, apert, R0, snr_dB);
fprintf(fid, 'Reference: c/(2B) = %.3f m ; lambda/(2*dtheta) = %.4f m (unwindowed approximations)\n', c/(2*B), lam/(2*dth));
fprintf(fid, 'Range cut      : IRW = %.3f m, PSLR = %.1f dB, ISLR = %.1f dB\n', mr.IRW, mr.PSLR_dB, mr.ISLR_dB);
fprintf(fid, 'Cross-range cut: IRW = %.4f m, PSLR = %.1f dB, ISLR = %.1f dB\n', mc.IRW, mc.PSLR_dB, mc.ISLR_dB);
fprintf(fid, 'Backprojection time (%d x %d pixels, %d pulses): %.1f s\n', numel(y), numel(x), N, tBP);
fclose(fid);  type(fullfile(outDir,'stage1_metrics.txt'));

%% -- local function (MUST stay at the end of the script in MATLAB) --
function S = local_sim(t, f, px, py, R0, c)
    S = zeros(numel(f), numel(px));
    for m = 1:size(t,1)
        R = sqrt((px - t(m,1)).^2 + (py - t(m,2)).^2);        % 1 x N
        S = S + t(m,3) * exp(-1j*4*pi*(f*R)/c);               % K x N
    end
    S = S .* exp(1j*4*pi*f*R0/c);                             % deskew to scene centre
end
