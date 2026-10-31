function [acc, pred, net] = train_cnn(Xtr, Ytr, Xte, Yte, seed, epochs)
% TRAIN_CNN  Small all-purpose CNN for the 10-class MSTAR experiments.
%   X: H x W x 1 x N single (raw magnitude), Y: categorical. Works for any square H = W >= 32.
%   Per-chip scaling (divide by the chip maximum) is applied HERE so that every experiment
%   (raw, despeckled, background-only) is normalised identically.
%   Fixed number of epochs, no validation-based selection, test set touched once at the end:
%   the reported accuracy cannot be inflated by tuning on the test set.
% Needs Deep Learning Toolbox (trainnet, R2023b+; minibatchpredict, R2024a+).
if nargin < 5 || isempty(seed), seed = 1; end
if nargin < 6 || isempty(epochs), epochs = 30; end
rng(seed);
Xtr = scale01(Xtr); Xte = scale01(Xte);
nc = numel(categories(Ytr));
layers = [
    imageInputLayer([size(Xtr,1) size(Xtr,2) 1], 'Normalization', 'none')
    block(16)
    block(32)
    block(64)
    block(128)
    dropoutLayer(0.5)
    fullyConnectedLayer(nc)
    softmaxLayer ];
opts = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, 'MaxEpochs', epochs, 'MiniBatchSize', 64, ...
    'Shuffle', 'every-epoch', 'L2Regularization', 1e-4, ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.2, 'LearnRateDropPeriod', max(1, round(epochs/2)), ...
    'ExecutionEnvironment', 'auto', 'Verbose', true, 'VerboseFrequency', 200, 'Plots', 'none');
net = trainnet(Xtr, Ytr, layers, 'crossentropy', opts);
scores = minibatchpredict(net, Xte, 'MiniBatchSize', 256);
cls = categories(Ytr);
[~, i] = max(scores, [], 2);
pred = categorical(cls(i), cls);
acc = mean(pred == Yte);
end

function L = block(n)
L = [convolution2dLayer(5, n, 'Padding', 'same'); batchNormalizationLayer; reluLayer; maxPooling2dLayer(2, 'Stride', 2)];
end

function X = scale01(X)
m = max(X, [], [1 2]); m(m == 0) = 1;
X = X ./ m;
end
