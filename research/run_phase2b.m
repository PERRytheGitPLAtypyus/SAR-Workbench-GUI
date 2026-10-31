%% RUN_PHASE2B  MSTAR SOC baseline CNN + a background-only control.
% Run from the project root after mstar_prepare (needs mstar_soc.mat) and with train_cnn.m present.
% A. baseline: centre 88x88 chips, no augmentation, 30 epochs, seed 1.
% B. control : the CNN only sees four 32x32 CORNER patches of each chip (no target in view).
%    If B is far above chance, class information leaks through the background (clutter, site,
%    collection conditions), which matters for the despeckling experiment later.
% Gate for A: test accuracy in the high 90s (the AAAI-SS paper cited below notes >95% is typical).
clear; close all; clc;
if ~isfile('mstar_soc.mat'), error('run mstar_prepare first'); end
S = load('mstar_soc.mat');
seed = 1; epochs = 30; crop = 88; P = 32;
c0 = (size(S.Xtr,1) - crop)/2; ix = c0+1:c0+crop;

%% A. baseline
tic;
[accA, predA] = train_cnn(S.Xtr(ix,ix,:,:), S.Ytr, S.Xte(ix,ix,:,:), S.Yte, seed, epochs);
fprintf('\nA. BASELINE: seed %d, test accuracy %.2f %% (%d/%d), %.0f s\n', seed, 100*accA, nnz(predA == S.Yte), numel(S.Yte), toc);
cls = categories(S.Yte);
for q = 1:numel(cls)
    m = S.Yte == cls{q};
    fprintf('   %-18s %5.1f %%  (%d/%d)\n', cls{q}, 100*mean(predA(m) == S.Yte(m)), nnz(predA(m) == S.Yte(m)), nnz(m));
end
figure('Name', 'baseline confusion'); cm = confusionchart(S.Yte, predA);
cm.Title = sprintf('MSTAR SOC baseline, seed %d: %.2f %%', seed, 100*accA);
exportgraphics(gcf, 'baseline_confusion.png', 'Resolution', 150);

%% B. background-only control (corner patches)
[Xp, Yp] = corners(S.Xtr, S.Ytr, P);
[Xq, Yq] = corners(S.Xte, S.Yte, P);
tic;
[accB, predB] = train_cnn(Xp, Yp, Xq, Yq, seed, epochs);
chance = max(histcounts(S.Yte)) / numel(S.Yte);
fprintf('\nB. BACKGROUND-ONLY: four %dx%d corner patches per chip, patch accuracy %.1f %% (always guessing the largest class = %.1f %%), %.0f s\n', ...
    P, P, 100*accB, 100*chance, toc);
n = numel(S.Yte); votes = reshape(double(predB), n, 4);
chipPred = categorical(cls(mode(votes, 2)), cls);
fprintf('   chip-level accuracy by majority vote of the 4 corners: %.1f %%\n', 100*mean(chipPred == S.Yte));

save('baseline_seed1.mat', 'accA', 'predA', 'accB', 'predB', 'seed', 'epochs', 'crop', 'P');
fprintf('\nGATE A: %s (%.2f %%). Control B: %.1f %% vs chance %.1f %%.\n', tern(accA >= 0.95, 'PASS', 'BELOW 95 %'), 100*accA, 100*accB, 100*chance);
fprintf('Attach baseline_confusion.png and paste this whole output (including the training log lines).\n');

%% local functions
function [Xp, Yp] = corners(X, Y, P)
N = size(X, 1); n = size(X, 4);
Xp = zeros(P, P, 1, 4*n, 'single'); k = 0;
rr = {1:P, N-P+1:N};
for a = 1:2
    for b = 1:2
        Xp(:,:,1,k*n+(1:n)) = X(rr{a}, rr{b}, 1, :);
        k = k + 1;
    end
end
Yp = repmat(Y, 4, 1);
end

function s = tern(c, a, b)
if c, s = a; else, s = b; end
end
