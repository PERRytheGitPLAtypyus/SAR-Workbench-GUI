%% P3B_TRAIN_GOTCHA  Train the MERLIN-type despeckler on AFRL Gotcha backprojection images (the in-domain fix for the failed transfer test).
% WHY: the MSTAR-trained network blurred and overshot the Gotcha point targets (peak ratio 1.54, widths 1.72 / 1.54). Remedy: train on
% Gotcha complex images (0.3 m pixels, 3-degree apertures, HH), then rerun the point-target test with p3b_gotcha_test_G.
% HOLD-OUT (no test aperture is ever trained on): training apertures start at 11, 23, 35 ... deg and are kept only if they are at least
%   5 deg away from the four test apertures (az 1-3, 86-88, 176-178, 266-268 of pass 8).
%   - If Gotcha passes other than 8 exist in the data folder: train on those (every second aperture, to bound the BP time), pass 8 stays untouched.
%   - If only pass 8 exists: train on the pass-8 apertures far from the test ones.  This is a WEAKER hold-out (same scene, other look
%     angles) and must be reported as such.
% GATE (fixed before running): the real/imaginary cross-covariance and circularity of the Gotcha clutter must satisfy the MERLIN
%   assumptions: xmax < 0.05 and 0.9 <= vratio <= 1.1 (p3b_noise_stats on tile corners).  Otherwise the script stops before training.
% Needs gotcha_find, gotcha_load, bp_gotcha, p3b_*.m.  Time: BP about 30 s per aperture (cached per pass: p3b_gotcha_cache_pass*.mat),
%   about 25-45 min for the images, then 5-10 min training.  Output: p3b_merlin_gotcha.mat.
clear; close all; clc; rng(21);
root = pwd; pol = 'HH'; dx = 0.3; Sz = 128; P = 32; nCrop = 8;
testAps = [1 86 176 266];
starts = 11:12:347;
keep = false(size(starts));
for i = 1:numel(starts), keep(i) = all(starts(i) + 2 < testAps - 5 | starts(i) > testAps + 7); end
starts = starts(keep);
avail = [];
for p = 1:8
    try
        [f, ~] = gotcha_find(root, p, pol, 1:3);
        if ~isempty(f), avail(end+1) = p; end %#ok<AGROW>
    catch
    end
end
fprintf('Gotcha passes found for %s: %s\n', pol, mat2str(avail));
assert(any(avail == 8), 'pass 8 (the test pass) not found in %s', root);
if numel(avail) > 1, trainPass = avail(avail ~= 8); starts = starts(1:2:end); mode = 'held-out passes'; else, trainPass = 8; mode = 'pass 8 only, held-out azimuths'; end
fprintf('training mode: %s; passes %s; %d apertures per pass\n', mode, mat2str(trainPass), numel(starts));

%% images (complex, divided by the per-image amplitude scale sg = sqrt(median(I)/log 2), exactly as p3b_gotcha_test applies it)
Zs = {}; meta = [];
for p = trainPass
    cf = sprintf('p3b_gotcha_cache_pass%d.mat', p);
    if isfile(cf), c = load(cf); Zs = [Zs, c.Zc]; meta = [meta; c.mt]; continue; end %#ok<AGROW>
    Zc = {}; mt = [];
    for a0 = starts
        try
            [files, ~] = gotcha_find(root, p, pol, a0:a0+2); G = gotcha_load(files);
            o = struct('xlim', [-44 6], 'ylim', [10 58], 'dx', dx, 'z', -0.3, 'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
            img = bp_gotcha(G, o);
            sg = sqrt(median(abs(img(:)).^2) / log(2));
            Zc{end+1} = single(img / sg); mt = [mt; p a0 sg]; %#ok<AGROW>
            fprintf('  pass %d az %d-%d formed (%dx%d)\n', p, a0, a0+2, size(img, 1), size(img, 2));
        catch ME
            fprintf('  pass %d az %d skipped: %s\n', p, a0, ME.message);
        end
    end
    save(cf, 'Zc', 'mt'); Zs = [Zs, Zc]; meta = [meta; mt]; %#ok<AGROW>
end
nImg = numel(Zs); assert(nImg >= 8, 'only %d Gotcha images formed - too few to train', nImg);
isVal = mod(1:nImg, 7) == 0;
Ztr = crops(Zs(~isVal), nCrop, Sz); Zva = crops(Zs(isVal), nCrop, Sz);
fprintf('%d images (%d validation) -> %d training tiles, %d validation tiles\n', nImg, nnz(isVal), size(Ztr, 3), size(Zva, 3));

%% gate on CLEAN-CLUTTER blocks (32 x 32 blocks of ALL images with mean power in [0.3, 1.5] and max power < 20; same rule as p3b_gotcha_diag).
% The first version measured tile corners, which contained targets/texture (CV 1.36, xmax 0.093) - a measurement-region error; the 0.05 limit is unchanged.
Zg = zeros(32, 32, 0);
for i = 1:nImg
    [H, W] = size(Zs{i});
    for r = 1:32:H-31
        for c = 1:32:W-31
            z = double(Zs{i}(r:r+31, c:c+31)); I = abs(z).^2;
            if mean(I(:)) >= 0.3 && mean(I(:)) <= 1.5 && max(I(:)) < 20, Zg = cat(3, Zg, z); end
        end
    end
end
g = p3b_noise_stats(Zg, 16);
fprintf('\nGATE (%d clean clutter blocks): xmax %.3f | vratio %.3f | rho_range %.2f | rho_az %.2f | intensity CV %.2f (fully developed speckle = 1)\n', size(Zg, 3), g.xmax, g.vratio, g.rho_r, g.rho_a, g.cvI);
if ~(g.xmax < 0.05 && g.vratio >= 0.9 && g.vratio <= 1.1)
    error('p3b_train_gotcha:gate', 'GATE FAIL: real/imaginary parts of Gotcha clutter violate the MERLIN assumptions - paste this output, do not train.');
end
fprintf('GATE PASS\n');

%% train
mk = @(Z) deal(cat(4, p3b_input(reshape(real(Z), Sz, Sz, 1, [])), p3b_input(reshape(imag(Z), Sz, Sz, 1, []))), ...
               cat(4, reshape(imag(Z), Sz, Sz, 1, []), reshape(real(Z), Sz, Sz, 1, [])));
[Xt, Tt] = mk(Ztr); [Xv, Tv] = mk(Zva);
net = dlnetwork(p3b_unet(Sz, 16));
opts = trainingOptions('adam', 'InitialLearnRate', 1e-3, 'MaxEpochs', 100, 'MiniBatchSize', 16, 'Shuffle', 'every-epoch', ...
    'LearnRateSchedule', 'piecewise', 'LearnRateDropFactor', 0.3, 'LearnRateDropPeriod', 30, ...
    'ValidationData', {Xv, Tv}, 'ValidationFrequency', 50, 'OutputNetwork', 'best-validation', ...
    'ExecutionEnvironment', 'auto', 'Verbose', true, 'VerboseFrequency', 100, 'Plots', 'none');
tic; [net, info] = trainnet(Xt, Tt, net, @p3b_merlin_loss, opts); tTrain = toc;
save('p3b_merlin_gotcha.mat', 'net', 'info', 'tTrain', 'meta', 'trainPass', 'starts', 'mode', '-v7.3');

%% sanity on validation tiles (data are already scaled, so s = 1): mean preservation and ENL gain in the tile corners
nv = min(100, size(Zva, 3)); Ia = 0; Ib = 0; cv0 = nan(1, nv); cv1 = cv0; cr = {1:P, Sz-P+1:Sz};
for k = 1:nv
    z = double(Zva(:,:,k)); Rh = p3b_denoise(net, z, 1); I = abs(z).^2;
    qa = I([cr{1} cr{2}], [cr{1} cr{2}]); qb = Rh([cr{1} cr{2}], [cr{1} cr{2}]);
    Ia = Ia + sum(qa(:)); Ib = Ib + sum(qb(:)); cv0(k) = std(qa(:)) / mean(qa(:)); cv1(k) = std(qb(:)) / mean(qb(:));
end
fprintf('\ntraining time %.0f s; best validation loss %.4f\n', tTrain, min(info.ValidationHistory.Loss));
fprintf('clutter mean bias of Rhat vs |z|^2 on %d held-out tiles: %+.2f %% (MSTAR network on MSTAR: -0.73 %%)\n', nv, 100*(Ib/Ia - 1));
fprintf('corner intensity CV: raw %.3f, despeckled %.3f (ENL gain %.1fx, corners are four pooled 32 x 32 blocks)\n', median(cv0), median(cv1), median(cv0)^2 / median(cv1)^2);
fprintf('saved p3b_merlin_gotcha.mat. Next: run p3b_gotcha_test_G. Paste this whole output.\n');

function Z = crops(Zs, n, Sz)
Z = zeros(Sz, Sz, 0, 'single');
for i = 1:numel(Zs)
    [H, W] = size(Zs{i}); Q = complex(zeros(Sz, Sz, n, 'single'));
    for k = 1:n
        r0 = randi(H - Sz + 1); c0 = randi(W - Sz + 1); Q(:,:,k) = Zs{i}(r0:r0+Sz-1, c0:c0+Sz-1);
    end
    Z = cat(3, Z, Q);
end
end
