%% RUN_P3B_GATE1  Phase 3b gate 1 (revised): can real and imaginary parts of MSTAR clutter serve as independent noisy copies?
% Run from the project root (needs mstar_soc.mat, mstar_read.m, p3b_whiten.m, p3b_noise_stats.m). Time: about 1 min.
% REVISION NOTE (the first version of this gate failed, and the failure was my criterion's fault):
%   Real/imaginary self-supervised training (MERLIN type) needs only that Im(z_i) is independent of the whole real field
%   given the reflectivity.  For a circular complex Gaussian this holds iff cross-covariances cov(Re z_j, Im z_i) vanish
%   (they equal -Im(C_ij)/2, i.e. they vanish for a spectrum symmetric about zero frequency) and var(Re) = var(Im).
%   Spatial correlation of the speckle itself does NOT break this (the network simply learns the posterior mean given a
%   correlated field).  The first version also demanded white speckle, which whitening could not deliver without inflating CV.
% PASS (raw, unwhitened chips): xmax < 0.05 (lags up to 4) and 0.9 < var(Re)/var(Im) < 1.1.
% Whitened rows are printed for information only.
clear; close all; clc; rng(1);
M = load('mstar_soc.mat', 'ptr');
n = 400; S = 128; P = 32; sel = randperm(numel(M.ptr), n);
Z = zeros(S, S, n, 'single');
for k = 1:n
    [mg, ph] = mstar_read(char(M.ptr(sel(k))));
    r0 = floor((size(mg,1)-S)/2) + 1; c0 = floor((size(mg,2)-S)/2) + 1;
    Z(:,:,k) = mg(r0:r0+S-1, c0:c0+S-1) .* exp(1j * ph(r0:r0+S-1, c0:c0+S-1));
end
fprintf('%-14s %8s %8s %8s %8s %8s %8s\n', 'condition', 'rho_rng', 'rho_az', 'xmax', 'rr_az1', 'CV(I)', 'varRatio');
r0s = p3b_noise_stats(double(Z), P); row('raw', r0s);
for lam = [1e-4 1e-3 1e-2]
    row(sprintf('whiten %.0e', lam), p3b_noise_stats(p3b_whiten(double(Z), lam), P));
end
pass = r0s.xmax < 0.05 && r0s.vratio > 0.9 && r0s.vratio < 1.1;
if pass, fprintf('\nGATE 1 (revised) PASS: real and imaginary parts are usable as independent noisy copies on raw chips (no whitening needed).\n');
else, fprintf('\nGATE 1 (revised) FAIL: use the sub-look Noise2Noise route.\n'); end
fprintf('Paste this whole output.\n');
function row(lbl, r), fprintf('%-14s %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f\n', lbl, r.rho_r, r.rho_a, r.xmax, r.rr1, r.cvI, r.vratio); end
