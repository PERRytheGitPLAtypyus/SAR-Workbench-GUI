function L = p3b_merlin_loss(Y, T)
% P3B_MERLIN_LOSS  Negative log-likelihood (up to constants) of the held-out component T ~ N(0, R/2) with R = exp(Y):
%   0.5*Y + T^2 * exp(-Y).  Its minimiser is exp(Y) = 2 E[T^2 | input] = E[R | input]: mean-preserving.
%   Y is clamped to [-12, 12] for numerical safety.
Y = max(min(Y, 12), -12);
L = mean(0.5 * Y + (T .^ 2) .* exp(-Y), 'all');
end
