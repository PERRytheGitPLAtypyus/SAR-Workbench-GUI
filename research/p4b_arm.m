function arm = p4b_arm(name, type, win)
% P4B_ARM  Arm with defaults: filtered train and test with the same filter, no augmentation, dropout 0.5, L2 1e-4.
%   Fields to modify afterwards: arm.aug (shift, noiseL, blurSet, K), arm.drop, arm.wd, arm.tests (cell of filter
%   specs for evaluation, first one also used for validation), arm.epochs (override), arm.evalTest.
if nargin < 3, win = 0; end
arm.name = name;
arm.train = struct('type', type, 'win', win);
arm.aug = struct('shift', false, 'noiseL', [], 'blurSet', [], 'K', 1);
arm.drop = 0.5; arm.wd = 1e-4;
arm.tests = {arm.train};
arm.mix = {};            % cell of filter specs: train on the union of all these views of every chip (mixed training)
arm.epochs = [];
arm.evalTest = true;
arm.arch = 'cnn4';        % 'cnn4' (4-block CNN) or 'aconv' (A-ConvNets-style all-conv net), see p4b_train
end
