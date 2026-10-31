function paired_report(A, filters)
% PAIRED_REPORT  A: seeds x (1 + 3*numel(filters)) accuracies, columns RR then [RF FF FR] per filter.
%   Prints mean +/- std, paired difference to RR with 95 % t-interval, paired t-test p, Bonferroni over all
%   comparisons (3 per filter) and, for the primary comparison FF, Bonferroni over the filters only.
nS = size(A, 1); nf = numel(filters); cond = {'RF', 'FF', 'FR'};
fprintf('RR (reference)             %.2f +/- %.2f %%   (n = %d seeds)\n', 100*mean(A(:,1)), 100*std(A(:,1)), nS);
for f = 1:nf
    for k = 1:3
        col = 1 + 3*(f-1) + k;
        d = 100 * (A(:,col) - A(:,1));
        [~, p] = ttest(d);
        ci = mean(d) + tinv(0.975, nS-1) * std(d) / sqrt(nS) * [-1 1];
        extra = '';
        if k == 2, extra = sprintf('  [primary, Bonferroni over %d filters: %.3f]', nf, min(1, nf*p)); end
        fprintf('%-9s %s  %.2f +/- %.2f %%   diff to RR %+.2f pp  95%% CI [%+.2f, %+.2f]  p = %.3f (Bonf %d: %.3f)%s\n', ...
            filters{f}, cond{k}, 100*mean(A(:,col)), 100*std(A(:,col)), mean(d), ci(1), ci(2), p, 3*nf, min(1, 3*nf*p), extra);
    end
end
end
