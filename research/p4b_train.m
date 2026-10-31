function net = p4b_train(Xtr, Ytr, seed, epochs, drop, wd, arch)
% P4B_TRAIN  Classifier for Phase 4b WITHOUT internal max-scaling (inputs are already normalised by N), with dropout and L2.
%   arch = 'cnn4'  (default) the 4-block CNN of train_cnn.m: 4 x [conv5 + BN + ReLU + maxpool], dropout, FC.
%   arch = 'aconv' A-ConvNets-style all-convolutional net (Chen et al. 2016, designed for 88 x 88 MSTAR chips):
%                  conv5x16, pool, conv5x32, pool, conv6x64, pool, conv5x128, dropout, conv3xC (no FC layer); BN added after
%                  each conv for stable training from small subsets. Needs input size 88.
%   Needs Deep Learning Toolbox (trainnet, R2023b+).
if nargin < 7 || isempty(arch), arch = 'cnn4'; end
rng(seed);
cls = categories(Ytr); nc = numel(cls); sz = size(Xtr, 1);
switch arch
    case 'cnn4'
        layers = [
            imageInputLayer([sz size(Xtr,2) 1], 'Normalization', 'none')
            blk(16); blk(32); blk(64); blk(128)
            dropoutLayer(drop)
            fullyConnectedLayer(nc)
            softmaxLayer ];
    case 'aconv'
        assert(sz == 88 && size(Xtr, 2) == 88, 'aconv needs 88 x 88 input (cfg.crop)');
        layers = [
            imageInputLayer([88 88 1], 'Normalization', 'none')
            cbr(5, 16); maxPooling2dLayer(2, 'Stride', 2)       % 84 -> 42
            cbr(5, 32); maxPooling2dLayer(2, 'Stride', 2)       % 38 -> 19
            cbr(6, 64); maxPooling2dLayer(2, 'Stride', 2)       % 14 -> 7
            cbr(5, 128)                                         % 3 x 3 x 128
            dropoutLayer(drop)
            convolution2dLayer(3, nc)                           % 1 x 1 x nc
            flattenLayer
            softmaxLayer ];
    otherwise
        error('p4b_train: unknown arch "%s"', arch);
end
opts = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, 'MaxEpochs', epochs, 'MiniBatchSize', 64, ...
    'Shuffle', 'every-epoch', 'L2Regularization', wd, ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.2, 'LearnRateDropPeriod', max(1, round(epochs/2)), ...
    'ExecutionEnvironment', 'auto', 'Verbose', false, 'Plots', 'none');
net = trainnet(Xtr, Ytr, layers, 'crossentropy', opts);
end

function L = blk(n)
L = [convolution2dLayer(5, n, 'Padding', 'same'); batchNormalizationLayer; reluLayer; maxPooling2dLayer(2, 'Stride', 2)];
end

function L = cbr(k, n)
L = [convolution2dLayer(k, n); batchNormalizationLayer; reluLayer];
end
