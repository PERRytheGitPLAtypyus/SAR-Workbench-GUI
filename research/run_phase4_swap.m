%% RUN_PHASE4_SWAP  Background-swap control: is the MSTAR result driven by the target or by the scene?
% PROTOCOL (fixed before running):
%   Every chip keeps only a centred box (32 px = target core, 64 px = target + shadow + near clutter) of its
%   own 128x128 pixels; everything else comes from a random other chip of the same set (swap_background.m).
%   Then exactly the Phase 4 pipeline: filter (Lee/Frost/Gamma-MAP, window 7, L = 1) -> centre 88x88 crop ->
%   train CNN (30 epochs, seeds 1..5, full training set) -> test once.  Conditions RR/RF/FF/FR as in Phase 4.
%   Reading the result (decided now):
%     RR_swap(64) and RR_swap(32) both >= ~95 %  -> classification is driven by the target; the earlier
%                                                    background-only result (27-32 %) was weak, secondary leakage.
%     RR_swap(32) clearly lower than RR_swap(64)   -> shadow / near-target clutter carries class information.
%     RR_swap far below the 98.6 % baseline (< 80 %) -> the 98.6 % baseline leaned on the scene background.
%   The paired comparison FF vs RR is repeated on the swapped data (does despeckling help once the scene cue is gone?).
% Needs: mstar_soc.mat, train_cnn.m, predict_cnn.m, despeckle_filters.m, swap_background.m, paired_report.m.
% Time: about 25-30 min.
clear; close all; clc;
L = 1; win = 7; filters = {'lee', 'frost', 'gammamap'}; seeds = 1:5; boxes = [32 64]; crop = 88; epochs = 30;

S = load('mstar_soc.mat');
c0 = (size(S.Xtr, 1) - crop)/2; ix = c0+1 : c0+crop;
cls = categories(S.Ytr); nf = numel(filters);
cropf = @(X) X(ix, ix, :, :);
fprintf('largest class share in test set (chance for a majority guesser): %.1f %%\n', 100*max(countcats(S.Yte))/numel(S.Yte));

R = nan(numel(boxes), numel(seeds), 1 + 3*nf);
tAll = tic;
for b = 1:numel(boxes)
    Xtr = swap_background(S.Xtr, boxes(b), 11); Xte = swap_background(S.Xte, boxes(b), 12);
    fig = figure('Visible', 'off', 'Position', [50 50 1200 300]); tiledlayout(1, 6, 'TileSpacing', 'none');
        for k = 1:6
            nexttile; img = Xtr(:,:,1,k*400); imagesc(img, [0 prctile(img(:), 99.5)]); axis image off; colormap gray;
        end
        exportgraphics(fig, sprintf('swap_examples_box%d.png', boxes(b)), 'Resolution', 120); close(fig);
    XtrR = cropf(Xtr); XteR = cropf(Xte);
    XtrF = cell(1, nf); XteF = cell(1, nf);
    for f = 1:nf
        XtrF{f} = cropf(despeckle_filters(Xtr, filters{f}, win, L));
        XteF{f} = cropf(despeckle_filters(Xte, filters{f}, win, L));
    end
    for s = 1:numel(seeds)
        seed = seeds(s);
        [R(b,s,1), ~, netR] = train1_cnn(XtrR, S.Ytr, XteR, S.Yte, seed, epochs, false);
        for f = 1:nf
            accRF = mean(predict_cnn(netR, XteF{f}, cls) == S.Yte);
            [accFF, ~, netF] = train1_cnn(XtrF{f}, S.Ytr, XteF{f}, S.Yte, seed, epochs, false);
            accFR = mean(predict_cnn(netF, XteR, cls) == S.Yte);
            R(b,s,1+3*(f-1)+(1:3)) = [accRF accFF accFR];
        end
        fprintf('box %d, seed %d done (RR_swap %.2f %%), %.0f s elapsed\n', boxes(b), seed, 100*R(b,s,1), toc(tAll));
        save('phase4_swap.mat', 'R', 'boxes', 'seeds', 'filters', 'L', 'win');
    end
end

%% report
ref = [];
if isfile('phase4_classical.mat')
    P4 = load('phase4_classical.mat'); ref = squeeze(P4.R(1, :, 1));
end
for b = 1:numel(boxes)
    fprintf('\n=== background swap, box %d px (full training set) ===\n', boxes(b));
    if ~isempty(ref), fprintf('unswapped RR from phase4_classical.mat: %.2f +/- %.2f %%\n', 100*mean(ref), 100*std(ref)); end
    paired_report(squeeze(R(b, :, :)), filters);
end
fprintf('\nsaved phase4_swap.mat. Attach swap_examples_box32.png and swap_examples_box64.png and paste this whole output.\n');
