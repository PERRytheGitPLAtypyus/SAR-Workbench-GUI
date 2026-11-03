function [pred, scores, info] = predict(chips, modelPath, normType)
% SAR.ATR.PREDICT  Classify MSTAR vehicle chips using trained deep CNN
%   [pred, scores, info] = sar.atr.predict(chips, modelPath, normType)
%
%   chips     : H x W x 1 x N single amplitude chips (e.g. 128x128 or 88x88)
%   modelPath : path to trained classifier model (default models/cnn_mstar.mat)
%   normType  : 'N' (default) | 'none'
%               Normalisation N: 88x88 centre crop, per-chip 99.5th percentile scaling.
%               WARNING: Omitting Normalisation N or testing on mismatched preprocessing
%               causes catastrophic classification degradation (15% - 50% accuracy).

if nargin < 2 || isempty(modelPath)
    cfg = sar.env.config();
    modelPath = fullfile(cfg.modelsPath, 'cnn_mstar.mat');
end
if nargin < 3 || isempty(normType)
    normType = 'N';
end

if ~exist(modelPath, 'file')
    error('sar:atr:modelNotFound', 'Classifier model not found: %s', modelPath);
end

loaded = load(modelPath);
net = loaded.net;
cls = loaded.cls;

info = struct();
info.modelPath = modelPath;
info.normType = normType;
info.classes = cls;
info.numChips = size(chips, 4);

% Check preprocessing shift
if ~strcmpi(normType, 'N')
    warning('sar:atr:distributionShift', ...
        ['Model was trained strictly under Normalisation N. Evaluating with normType="%s" ' ...
         'induces extreme distribution shift (expected test accuracy collapses to 15-50%%).'], normType);
end

% Preprocess chips
sz = size(chips, 1);
if strcmpi(normType, 'N')
    if sz > 88
        chips88 = p4b_crop(chips, 88);
    else
        chips88 = chips;
    end
    X = p4b_norm(chips88, 99.5);
else
    if sz > 88
        X = p4b_crop(chips, 88);
    else
        X = chips;
    end
end

% Inference
pred = p4b_predict(net, X, cls);
if nargout > 1
    scores = minibatchpredict(net, X, 'MiniBatchSize', 256);
end
end
