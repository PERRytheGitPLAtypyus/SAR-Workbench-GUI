%% SAVE_SELFTEST_MODEL
% Runs p3b_selftest logic once to produce and save models/merlin_selftest.mat
% so that unit tests can evaluate the synthetic self-test in < 1 second with no retraining.

clear; close all; clc; rng(5);
root = fileparts(fileparts(mfilename('fullpath')));
cd(root);
startup;

S = 128; N = 600; Nt = 40;
[Z, Rt] = synth(N + Nt, S);
Zt = Z(:,:,N+1:end); Rtest = Rt(:,:,N+1:end); Z = Z(:,:,1:N);
Xin = cat(4, p3b_input(reshape(real(Z), S, S, 1, N)), p3b_input(reshape(imag(Z), S, S, 1, N)));
Tgt = cat(4, reshape(imag(Z), S, S, 1, N), reshape(real(Z), S, S, 1, N));
net = dlnetwork(p3b_unet(S, 16));
opts = trainingOptions('adam', 'InitialLearnRate', 1e-3, 'MaxEpochs', 12, 'MiniBatchSize', 16, 'Shuffle', 'every-epoch', ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.3, 'LearnRateDropPeriod', 6, ...
    'ExecutionEnvironment', 'auto', 'Verbose', false, 'Plots', 'none');
net = trainnet(Xin, Tgt, net, @p3b_merlin_loss, opts);

modelPath = fullfile(root, 'models', 'merlin_selftest.mat');
save(modelPath, 'net', 'Zt', 'Rtest');
fprintf('Saved pre-trained selftest net to: %s\n', modelPath);

function [Z, R] = synth(n, S)
Z = zeros(S, S, n, 'single'); R = zeros(S, S, n, 'single');
for k = 1:n
    Rk = ones(S, S, 'single');
    for j = 1:25
        w = randi([16 64]); h = randi([16 64]); r0 = randi(S-h+1); c0 = randi(S-w+1);
        Rk(r0:r0+h-1, c0:c0+w-1) = exp(log(0.3) + rand * log(100));
    end
    R(:,:,k) = Rk; Z(:,:,k) = sqrt(Rk/2) .* complex(randn(S, S, 'single'), randn(S, S, 'single'));
end
end
