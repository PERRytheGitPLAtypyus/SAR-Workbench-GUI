%% P3B_SELFTEST  End-to-end check of the MERLIN-type despeckler on SYNTHETIC speckle with known reflectivity (about 2-4 min).
% Piecewise-constant reflectivity R (log-uniform 0.3 .. 30), z = sqrt(R/2) (randn + j randn). Trains the U-Net with the
% real<->imaginary loss, then compares the estimate with the TRUE R.  PASS if the median |log(Rhat/R)| is below 0.45
% (raw single-look intensity: about 0.78) and the mean of Rhat matches the mean of R within 3 %.
% Needs Deep Learning Toolbox (trainnet, minibatchpredict) and the p3b_*.m files on the path.
clear; close all; clc; rng(5);
S = 128; N = 600; Nt = 40;
[Z, Rt] = synth(N + Nt, S);
Zt = Z(:,:,N+1:end); Rtest = Rt(:,:,N+1:end); Z = Z(:,:,1:N);
Xin = cat(4, p3b_input(reshape(real(Z), S, S, 1, N)), p3b_input(reshape(imag(Z), S, S, 1, N)));
Tgt = cat(4, reshape(imag(Z), S, S, 1, N), reshape(real(Z), S, S, 1, N));
net = dlnetwork(p3b_unet(S, 16));
opts = trainingOptions('adam', 'InitialLearnRate', 1e-3, 'MaxEpochs', 12, 'MiniBatchSize', 16, 'Shuffle', 'every-epoch', ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.3, 'LearnRateDropPeriod', 6, ...
    'ExecutionEnvironment', 'auto', 'Verbose', true, 'VerboseFrequency', 50, 'Plots', 'none');
tic; net = trainnet(Xin, Tgt, net, @p3b_merlin_loss, opts); tTrain = toc;
errR = nan(1, Nt); errEst = errR; bR = nan(1, Nt); bE = bR;
for k = 1:Nt
    Rh = p3b_denoise(net, Zt(:,:,k), 1);
    I = abs(Zt(:,:,k)).^2; Rk = Rtest(:,:,k);
    errEst(k) = median(abs(log(Rh(:) ./ Rk(:)))); errR(k) = median(abs(log(I(:) ./ Rk(:))));
    bE(k) = mean(Rh(:)) / mean(Rk(:)) - 1;
end
fprintf('\ntraining time %.0f s\nmedian |log(Rhat/R)|: network %.3f vs raw intensity %.3f\nmean bias of Rhat vs true R: %+.2f %%\n', tTrain, median(errEst), median(errR), 100*median(bE));
ok = median(errEst) < 0.45 && abs(median(bE)) < 0.03;
fprintf('SELFTEST %s\n', tern(ok));

function [Z, R] = synth(n, S)
Z = zeros(S, S, n, 'single'); R = zeros(S, S, n, 'single');
for k = 1:n
    Rk = ones(S, S, 'single');
    for j = 1:25
        w = randi([16 64]); h = randi([16 64]); r0 = randi(S-h+1); c0 = randi(S-w+1);
        Rk(r0:r0+h-1, c0:c0+w-1) = exp(log(0.3) + rand * log(100));
    end
    R(:,:,k) = Rk; Z(:,:,k) = sqrt(Rk/2) .* complex(randn(S, S, 'single'), randn(S, S, 'single'));
end
end
function s = tern(c)
if c, s = 'PASS'; else, s = 'FAIL'; end
end
