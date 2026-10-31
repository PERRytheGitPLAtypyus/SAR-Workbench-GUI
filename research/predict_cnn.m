function pred = predict_cnn(net, X, cls)
% PREDICT_CNN  Classify chips with a network from train_cnn (same per-chip scaling).
%   X: H x W x 1 x N single, cls: cellstr of class names (categories of the training labels).
m = max(X, [], [1 2]); m(m == 0) = 1;
X = X ./ m;
scores = minibatchpredict(net, X, 'MiniBatchSize', 256);
[~, i] = max(scores, [], 2);
pred = categorical(cls(i), cls);
end
