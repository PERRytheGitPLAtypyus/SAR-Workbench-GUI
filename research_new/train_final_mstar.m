%% TRAIN_FINAL_MSTAR
% Trains the final 4-block CNN on the full 17 deg MSTAR training set (2,747 chips)
% under Normalisation N (per-chip 99.5th-percentile scale, clipped at 1) for 5 seeds,
% evaluates on the 15 deg test set (2,425 chips), and saves seed 1 to models/cnn_mstar.mat.
%
% Conforms strictly to Phase 4b unaugmented baseline arm A0 specification.

clear; close all; clc;
root = fileparts(fileparts(mfilename('fullpath')));
cd(root);
startup;

fprintf('==================== MSTAR FINAL ATR TRAINING ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

cfg = p4b_config();
S = load(cfg.mat);  % mstar_soc.mat

% Prepare Test set under Normalisation N (88x88 centre crop, 99.5th percentile scale)
fprintf('Preparing 15 deg test set (%d chips)...\n', size(S.Xte, 4));
Xte = p4b_norm(p4b_crop(S.Xte, cfg.crop), cfg.pct);
Yte = S.Yte;
cls = categories(S.Ytr);

% Prepare Full 17 deg Training set under Normalisation N (2,747 chips)
fprintf('Preparing 17 deg training set (%d chips)...\n', size(S.Xtr, 4));
Xtr = p4b_norm(p4b_crop(S.Xtr, cfg.crop), cfg.pct);
Ytr = S.Ytr;

epochs = 30;
drop = 0.5;
wd = 1e-4;
arch = 'cnn4';
seeds = 1:5;
acc = zeros(1, numel(seeds));
nets = cell(1, numel(seeds));

fprintf('\nBeginning training across %d seeds (30 epochs each)...\n', numel(seeds));
for s = 1:numel(seeds)
    seed = seeds(s);
    t0 = tic;
    net = p4b_train(Xtr, Ytr, seed, epochs, drop, wd, arch);
    tTrain = toc(t0);
    
    pred = p4b_predict(net, Xte, cls);
    acc(s) = mean(pred == Yte);
    nets{s} = net;
    
    fprintf('Seed %d: Test Accuracy = %6.2f %%  (Training time: %.1f s)\n', ...
        seed, 100 * acc(s), tTrain);
end

meanAcc = mean(acc);
stdAcc = std(acc);
fprintf('\n--- Summary across 5 seeds ---\n');
fprintf('Mean Test Accuracy: %6.2f %% +/- %5.2f %%\n', 100 * meanAcc, 100 * stdAcc);
fprintf('Target Gate Range : 98.82 %% +/- 0.50 %% (98.32 %% - 99.32 %%)\n');

% Save Seed 1 model as specified by brief
net = nets{1};
accSeed1 = acc(1);
modelPath = fullfile(root, 'models', 'cnn_mstar.mat');
save(modelPath, 'net', 'accSeed1', 'acc', 'meanAcc', 'cls', 'cfg', 'epochs', 'drop', 'wd', 'arch');
fprintf('\n[PASS] Seed 1 model saved to: %s\n', modelPath);
fprintf('Seed 1 Test Accuracy: %6.2f %%\n', 100 * accSeed1);

assert(abs(100 * accSeed1 - 98.82) <= 0.50, ...
    'Seed 1 accuracy %.2f %% outside required range [98.32, 99.32] %%', 100 * accSeed1);

fprintf('==================================================================\n');
