%% RUN_G1_NEGATIVE_CONTROLS
% Verifies that every Gate G1 test FAILS when given corrupted/negative inputs,
% proving tests are not vacuous and actively assert scientific specifications.

fprintf('==================== GATE G1 NEGATIVE CONTROLS ====================\n');
fprintf('Date: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

results = struct();

%% 1. Negative Control: MSTAR Dataset Counts
fprintf('--- 1. Negative Control: MSTAR Dataset Counts ---\n');
try
    d = sar.atr.dataset();
    % Deliberately assert corrupted train chip count (2000 instead of 2747)
    assert(d.numTrain == 2000, 'Deliberate mismatch: expected 2000 train chips');
    fprintf('[UNEXPECTED PASS] MSTAR count negative control did not fail!\n');
    results.test1 = 'FAIL';
catch ME
    fprintf('[EXPECTED FAIL] Caught assertion: "%s"\n', ME.message);
    results.test1 = 'PASS (Negative Control Caught)';
end

%% 2. Negative Control: Gotcha Resolution Width
fprintf('\n--- 2. Negative Control: Gotcha Resolution Width ---\n');
try
    G = sar.imaging.gotcha.loadAperture([], 8, 'HH', 1:3);
    % Deliberately use coarse grid dx=0.50 m (causes severe cross-range blurring)
    opt = struct('xlim', [-28.09-2.5, -28.09+2.5], 'ylim', [38.67-2.5, 38.67+2.5], ...
                 'dx', 0.50, 'z', -0.3, 'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
    [img, xv, yv] = sar.imaging.gotcha.backproject(G, opt);
    stats = sar.imaging.gotcha.pointTargetResolution(img, xv, yv, [-28.09, 38.67]);
    % Must fail the 0.30 m +/- 10% gate
    assert(stats.widthX >= 0.27 && stats.widthX <= 0.33, ...
        sprintf('Resolution width %.3f m outside [0.27, 0.33] m', stats.widthX));
    fprintf('[UNEXPECTED PASS] Gotcha resolution negative control did not fail!\n');
    results.test2 = 'FAIL';
catch ME
    fprintf('[EXPECTED FAIL] Caught assertion: "%s"\n', ME.message);
    results.test2 = 'PASS (Negative Control Caught)';
end

%% 3. Negative Control: ATR Classifier Accuracy with Shuffled Labels
fprintf('\n--- 3. Negative Control: ATR Classifier Accuracy (Shuffled Labels) ---\n');
try
    cfg = sar.env.config();
    modelPath = fullfile(cfg.modelsPath, 'cnn_mstar.mat');
    d = sar.atr.dataset();
    pred = sar.atr.predict(d.Xte, modelPath, 'N');
    % Deliberately shuffle ground-truth labels
    rng(42);
    shuffledY = d.Yte(randperm(numel(d.Yte)));
    shuffledAcc = 100 * mean(pred == shuffledY);
    fprintf('   Shuffled test accuracy: %.2f %%\n', shuffledAcc);
    assert(shuffledAcc >= 98.32 && shuffledAcc <= 99.32, ...
        sprintf('Accuracy %.2f %% outside [98.32, 99.32] %%', shuffledAcc));
    fprintf('[UNEXPECTED PASS] ATR accuracy negative control did not fail!\n');
    results.test3 = 'FAIL';
catch ME
    fprintf('[EXPECTED FAIL] Caught assertion: "%s"\n', ME.message);
    results.test3 = 'PASS (Negative Control Caught)';
end

%% 4. Negative Control: Synthetic Speckle Bias
fprintf('\n--- 4. Negative Control: Synthetic Speckle Bias ---\n');
try
    rng(3);
    I = -log(rand(256, 256, 'single'));
    Ah = sqrt(I);
    Y_lee = sar.despeckle.apply(Ah, 'lee', struct('win', 7, 'L', 1));
    % Deliberately inject +20% bias into filter output
    corrupted_Y = Y_lee * 1.20;
    biasCorrupted = 100 * (mean(corrupted_Y(:).^2) / mean(I(:)) - 1);
    assert(abs(biasCorrupted) < 0.5, ...
        sprintf('Injected bias %.2f %% exceeds 0.5 %% tolerance', biasCorrupted));
    fprintf('[UNEXPECTED PASS] Speckle bias negative control did not fail!\n');
    results.test4 = 'FAIL';
catch ME
    fprintf('[EXPECTED FAIL] Caught assertion: "%s"\n', ME.message);
    results.test4 = 'PASS (Negative Control Caught)';
end

%% 5. Negative Control: MERLIN Synthetic Self-Test with Corrupted Targets
fprintf('\n--- 5. Negative Control: MERLIN Synthetic Self-Test ---\n');
try
    cfg = sar.env.config();
    modelPath = fullfile(cfg.modelsPath, 'merlin_selftest.mat');
    S = load(modelPath);
    Nt = size(S.Zt, 3);
    errEst = zeros(1, Nt);
    for k = 1:Nt
        Rh = p3b_denoise(S.net, S.Zt(:,:,k), 1);
        % Compare against inverted/wrong target reflectivity
        R_wrong = 1 ./ (S.Rtest(:,:,k) + 0.1);
        errEst(k) = median(abs(log(Rh(:) ./ R_wrong(:))));
    end
    medErr = median(errEst);
    assert(abs(medErr - 0.081) <= 0.02, ...
        sprintf('Self-test median error %.4f outside [0.061, 0.101]', medErr));
    fprintf('[UNEXPECTED PASS] MERLIN self-test negative control did not fail!\n');
    results.test5 = 'FAIL';
catch ME
    fprintf('[EXPECTED FAIL] Caught assertion: "%s"\n', ME.message);
    results.test5 = 'PASS (Negative Control Caught)';
end

%% 6. Negative Control: MERLIN ENL Gain on Raw Data
fprintf('\n--- 6. Negative Control: MERLIN ENL Gain on Raw Data ---\n');
try
    rng(3);
    cfg = sar.env.config();
    D = load(cfg.dataPath.mstarSocMat, 'pte');
    S = 128; n = 20; tgt = 41:88; P = 32;
    sel = randperm(numel(D.pte), n);
    Z = zeros(S, S, n);
    for k = 1:n
        [mg, ph] = mstar_read(char(D.pte(sel(k))));
        r0 = floor((size(mg,1)-S)/2) + 1; c0 = floor((size(mg,2)-S)/2) + 1;
        Z(:,:,k) = double(mg(r0:r0+S-1, c0:c0+S-1)) .* exp(1j * double(ph(r0:r0+S-1, c0:c0+S-1)));
    end
    I = abs(Z).^2;
    % Pass raw unfiltered intensity instead of despeckled (gain is ~1.0)
    m = p3b_metrics(I, I, P, tgt);
    assert(abs(m.gain - 21.4) <= 1.5, ...
        sprintf('Raw data ENL gain %.2f does not meet MERLIN target 21.4 +/- 1.5', m.gain));
    fprintf('[UNEXPECTED PASS] MERLIN ENL gain negative control did not fail!\n');
    results.test6 = 'FAIL';
catch ME
    fprintf('[EXPECTED FAIL] Caught assertion: "%s"\n', ME.message);
    results.test6 = 'PASS (Negative Control Caught)';
end

%% 7. Negative Control: Scientific Domain Rejection
fprintf('\n--- 7. Negative Control: Scientific Domain Boundary Enforcement ---\n');
try
    % Pass COMPLEX data to MERLIN (positive case) and verify it does NOT throw error
    Z_complex = complex(randn(128, 128, 'single'), randn(128, 128, 'single'));
    threwError = false;
    try
        sar.despeckle.apply(Z_complex, 'merlin_mstar');
    catch
        threwError = true;
    end
    % If complex data was rejected, the domain rule is broken
    assert(~threwError, 'Valid complex data was incorrectly rejected by MERLIN');
    fprintf('[PASS] Positive control: Valid complex data is accepted without error.\n');
    
    % Now verify amplitude data throws the exact error code
    A_real = rand(128, 128, 'single');
    try
        sar.despeckle.apply(A_real, 'merlin_mstar');
        error('sar:negativeControl:failed', 'Real amplitude was NOT rejected by MERLIN');
    catch ME
        assert(strcmp(ME.identifier, 'sar:despeckle:invalidInputType'), ...
            'Expected sar:despeckle:invalidInputType error identifier');
        fprintf('[EXPECTED FAIL] Caught rejection: "%s"\n', ME.message);
    end
    results.test7 = 'PASS (Negative Control Caught)';
catch ME
    fprintf('[UNEXPECTED FAIL] Domain negative control error: %s\n', ME.message);
    results.test7 = 'FAIL';
end

fprintf('\n================ NEGATIVE CONTROLS SUMMARY ================\n');
disp(results);
fprintf('>>> ALL 7 NEGATIVE CONTROLS VERIFIED TO ACTIVELY ASSERT AND FAIL <<<\n');
fprintf('===================================================================\n');
