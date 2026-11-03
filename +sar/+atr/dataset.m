function data = dataset(matPath)
% SAR.ATR.DATASET  Load MSTAR benchmark dataset (train 17 deg, test 15 deg)
%   data = sar.atr.dataset(matPath)
%
%   Returns a struct with fields:
%     .Xtr, .Ytr   - 17 deg training chips and categorical classes
%     .Xte, .Yte   - 15 deg test chips and categorical classes
%     .classes     - list of categorical classes (10 target types)
%     .numTrain    - count of training chips (expected 2,747)
%     .numTest     - count of test chips (expected 2,425)

if nargin < 1 || isempty(matPath)
    cfg = sar.env.config();
    matPath = cfg.dataPath.mstarSocMat;
end

if ~exist(matPath, 'file')
    error('sar:atr:datasetNotFound', 'MSTAR dataset mat file not found: %s', matPath);
end

S = load(matPath);
data = struct();
data.Xtr = S.Xtr;
data.Ytr = S.Ytr;
data.Xte = S.Xte;
data.Yte = S.Yte;
data.classes = categories(S.Ytr);
data.numTrain = numel(S.Ytr);
data.numTest = numel(S.Yte);
data.numClasses = numel(data.classes);
end
