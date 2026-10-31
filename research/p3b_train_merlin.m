%% P3B_TRAIN_MERLIN  Train the MERLIN-type despeckler on the complex MSTAR TRAINING chips (17 deg, no labels used).
% Run p3b_selftest first. Needs mstar_soc.mat (ptr), mstar_read.m, p3b_*.m. Time: reading chips 1-3 min (cached in
% p3b_chips_train.mat), training roughly 15-40 min depending on the GPU. Output: p3b_merlin.mat (net, s, history).
% 300 training chips are held out for the validation loss (best-validation network is kept). Test chips are never used.
clear; close all; clc; rng(11);
M = load('mstar_soc.mat', 'ptr');
S = 128; N = numel(M.ptr); cache = 'p3b_chips_train.mat';
if isfile(cache)
    C = load(cache); Zr = C.Zr; Zi = C.Zi;
else
    Zr = zeros(S, S, N, 'single'); Zi = Zr;
    for k = 1:N
        [mg, ph] = mstar_read(char(M.ptr(k)));
        r0 = floor((size(mg,1)-S)/2) + 1; c0 = floor((size(mg,2)-S)/2) + 1;
        z = mg(r0:r0+S-1, c0:c0+S-1) .* exp(1j * ph(r0:r0+S-1, c0:c0+S-1));
        Zr(:,:,k) = real(z); Zi(:,:,k) = imag(z);
    end
    save(cache, 'Zr', 'Zi', '-v7.3');
end
% amplitude scale: mean power of the four 32 x 32 corners (clutter) -> clutter power about 1 after division
P = 32; cr = {1:P, S-P+1:S}; pw = 0; cnt = 0;
for a = 1:2, for b = 1:2
    q = Zr(cr{a}, cr{b}, :).^2 + Zi(cr{a}, cr{b}, :).^2; pw = pw + sum(q(:)); cnt = cnt + numel(q);
end, end
s = sqrt(pw / cnt); fprintf('amplitude scale s = %.4g (clutter mean power -> 1)\n', s);
Zr = Zr / s; Zi = Zi / s;
perm = randperm(N); iv = perm(1:300); it = perm(301:end);
mk = @(idx) deal(cat(4, p3b_input(reshape(Zr(:,:,idx), S, S, 1, [])), p3b_input(reshape(Zi(:,:,idx), S, S, 1, []))), ...
                 cat(4, reshape(Zi(:,:,idx), S, S, 1, []), reshape(Zr(:,:,idx), S, S, 1, [])));
[Xt, Tt] = mk(it); [Xv, Tv] = mk(iv);
net = dlnetwork(p3b_unet(S, 16));
opts = trainingOptions('adam', 'InitialLearnRate', 1e-3, 'MaxEpochs', 40, 'MiniBatchSize', 16, 'Shuffle', 'every-epoch', ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.3, 'LearnRateDropPeriod', 12, ...
    'ValidationData', {Xv, Tv}, 'ValidationFrequency', 300, 'OutputNetwork', 'best-validation', ...
    'ExecutionEnvironment', 'auto', 'Verbose', true, 'VerboseFrequency', 100, 'Plots', 'none');
tic; [net, info] = trainnet(Xt, Tt, net, @p3b_merlin_loss, opts); tTrain = toc;
save('p3b_merlin.mat', 'net', 's', 'info', 'tTrain', '-v7.3');
% quick sanity on 100 held-out chips: mean preservation and ENL gain in the clutter corners
Ib = 0; Ia = 0; cv0 = nan(1, 100); cv1 = cv0;
for k = 1:100
    z = complex(Zr(:,:,iv(k)), Zi(:,:,iv(k))) * s; Rh = p3b_denoise(net, z, s); I = abs(z).^2;
    qa = I([1:P, S-P+1:S], [1:P, S-P+1:S]); qb = Rh([1:P, S-P+1:S], [1:P, S-P+1:S]);
    Ia = Ia + sum(qa(:)); Ib = Ib + sum(qb(:));
    cv0(k) = std(qa(:)) / mean(qa(:)); cv1(k) = std(qb(:)) / mean(qb(:));
end
fprintf('\ntraining time %.0f s\nclutter mean bias of Rhat vs |z|^2 on 100 held-out chips: %+.2f %%\n', tTrain, 100*(Ib/Ia - 1));
fprintf('corner intensity CV: raw %.3f, despeckled %.3f  (ENL gain %.1fx; the corner mask also contains the chip centre cross, an approximation)\n', median(cv0), median(cv1), median(cv0).^2 / median(cv1).^2);
fprintf('saved p3b_merlin.mat. Paste this whole output.\n');
