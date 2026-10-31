function pred = p4b_predict(net, X, cls)
% P4B_PREDICT  X already normalised by N (no further scaling).
scores = minibatchpredict(net, X, 'MiniBatchSize', 256);
[~, i] = max(scores, [], 2);
pred = categorical(cls(i), cls);
end
