% scripts/test_g2b.m
% Verification of Gate G2b MSTAR + ATR Classification Tab
clc;
fprintf('==================== GATE G2B MSTAR ATR TAB VERIFICATION ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('Reference: Frozen research function p4b_predict.m and models/cnn_mstar.mat.\n');

cfg = sar.env.config();

% 1. Launch App
fprintf('\n--- 1. App Launch & Tab Initialization ---\n');
app = SARWorkbench();
assert(~isempty(app) && isvalid(app.UIFigure), 'SARWorkbench must launch cleanly');
app.TabGroup.SelectedTab = app.AtrTab;
drawnow;
fprintf('[PASS] App launched and AtrTab selected.\n');

% 2. Chip Browser and Target Navigation
fprintf('\n--- 2. Chip Browser & Metadata Navigation ---\n');
app.DropdownAtrClass.Value = 't72_tank';
app.onAtrClassChanged();
app.SpinnerAtrChipIdx.Value = 5;
app.onAtrChipChanged();
drawnow;

fprintf('   Selected: Class=%s, ChipIdx=%d\n', app.DropdownAtrClass.Value, app.SpinnerAtrChipIdx.Value);
fprintf('   Displayed Azimuth: %s\n', app.LabelAtrAzimuth.Text);
fprintf('   Target Info      : %s\n', app.LabelAtrChipInfo.Text);

assert(contains(app.LabelAtrAzimuth.Text, 'deg'), 'Azimuth label must display angle in degrees');
assert(~isempty(app.AxesAtrChip.Children), 'AxesAtrChip must contain chip image');
fprintf('[PASS] Chip browser navigation and display verified.\n');

% 3. Single-Chip Prediction Equivalence (GUI vs p4b_predict)
fprintf('\n--- 3. Single-Chip Prediction & Scores Equivalence ---\n');
app.DropdownAtrPreprocess.Value = 'raw';
app.onAtrPreprocessChanged();
app.classifyCurrentChip();
drawnow;

% Direct independent reference calculation
M = load(fullfile(cfg.modelsPath, 'cnn_mstar.mat'));
S = load(cfg.dataPath.mstarSocMat, 'Xte', 'Yte');
idxT72 = find(S.Yte == 't72_tank');
globalIdx = idxT72(5);
rawChip = S.Xte(:,:,1,globalIdx);

refX88 = p4b_crop(rawChip, 88);
refXnorm = p4b_norm(refX88, 99.5);
refPred = p4b_predict(M.net, refXnorm, M.cls);
refScores = minibatchpredict(M.net, refXnorm, 'MiniBatchSize', 256);

% Verify via sar.atr.predict adapter
[adapterPred, adapterScores, ~] = sar.atr.predict(rawChip, fullfile(cfg.modelsPath, 'cnn_mstar.mat'), 'N');

scoreDiff = max(abs(adapterScores(:) - refScores(:)));
fprintf('   Max score difference (sar.atr.predict vs p4b_predict): %e\n', scoreDiff);
assert(scoreDiff < 1e-6, 'Prediction scores must match frozen p4b_predict within 1e-6');
assert(adapterPred == refPred, 'Predicted category must match p4b_predict');

fprintf('   GUI Display: %s\n', app.LabelAtrPrediction.Text);
assert(contains(app.LabelAtrPrediction.Text, char(refPred)), 'GUI prediction label must match predicted class');
fprintf('[PASS] Single-chip prediction and scores equivalence verified (< 1e-6).\n');

% 4. Prediction Negative Control (Preprocessing & Target Shift)
fprintf('\n--- 4. Negative Control: Preprocessing Shift Detection ---\n');
% Comparing nominal raw scores against Lee-filtered chip scores
chipLee = despeckle_filters(rawChip, 'lee', 7, 1);
refX88_lee = p4b_crop(chipLee, 88);
refXnorm_lee = p4b_norm(refX88_lee, 99.5);
leeScores = minibatchpredict(M.net, refXnorm_lee, 'MiniBatchSize', 256);
diffShift = max(abs(leeScores(:) - refScores(:)));
fprintf('   Preprocessing shift diff (Raw vs Lee 7 scores): %e\n', diffShift);
assert(diffShift > 0.05, 'Negative control failed: preprocessing shift must significantly alter scores');
fprintf('[PASS] Negative control passed: preprocessing shift cleanly detected (> 0.05).\n');

% 5. Full Test Set Accuracy Recomputation & Confusion Matrix
fprintf('\n--- 5. Full Test Set Recomputation (2425 Chips) ---\n');
app.evaluateFullTestSet();
drawnow;

fprintf('   %s\n', app.LabelAtrOverallAcc.Text);
assert(contains(app.LabelAtrOverallAcc.Text, '99.30 %'), 'Recomputed test accuracy must equal 99.30 %');
assert(~isempty(app.ConfusionChartObj) && isvalid(app.ConfusionChartObj), ...
    'Confusion chart must be created on PanelConfusion');
fprintf('[PASS] Full test set accuracy recomputed = 99.30 %% (2408 / 2425).\n');

% 6. Live Measured Per-Preprocessing Table & Red Mismatch Banners
fprintf('\n--- 6. Live Preprocessing Mismatch Evaluation & Banner Enforcement ---\n');
preprocessors = {'raw', 'lee', 'boxcar', 'merlin'};
expectedAcc = [0.9930, 0.5039, 0.3332, 0.4680];
expectedBanners = { ...
    '[TRAINING DISTRIBUTION] Nominal evaluation under Normalisation N. Model achieved 99.30% test accuracy', ...
    '[PREPROCESSING MISMATCH] Model trained on RAW chips; evaluating on despeckled chips collapses test accuracy (Lee 7: 50.39%', ...
    '[PREPROCESSING MISMATCH] Model trained on RAW chips; evaluating on despeckled chips collapses test accuracy', ...
    '[PREPROCESSING MISMATCH] Model trained on RAW chips; evaluating on despeckled chips collapses test accuracy'};

fprintf('\n%-18s | %-16s | %-12s | %-10s\n', 'Preprocessing', 'Measured Accuracy', 'Degradation', 'Banner Alert');
fprintf('--------------------------------------------------------------------------------\n');
for p = 1:numel(preprocessors)
    prep = preprocessors{p};
    app.DropdownAtrPreprocess.Value = prep;
    app.onAtrPreprocessChanged();
    app.evaluateFullTestSet();
    drawnow;
    
    txtAcc = app.LabelAtrOverallAcc.Text;
    valAcc = sscanf(txtAcc, sprintf('Full Test Set [%s]:\nAccuracy: %%f %%%%', upper(prep))) / 100;
    
    assert(abs(valAcc - expectedAcc(p)) < 0.005, ...
        sprintf('Measured accuracy for %s must match expected %.4f', prep, expectedAcc(p)));
    assert(contains(app.LabelAtrBanner.Text, expectedBanners{p}), ...
        sprintf('Banner for %s must contain expected advisory text', prep));
    
    if strcmp(prep, 'raw')
        assert(app.BannerAtr.BackgroundColor(1) < 0.96, 'Raw banner must be neutral');
        degStr = 'Nominal (0.00 pp)';
        alertStr = 'Neutral';
    else
        assert(app.BannerAtr.BackgroundColor(1) > 0.95 && app.BannerAtr.BackgroundColor(2) < 0.9, ...
            'Non-raw banner must be red mismatch alert');
        assert(contains(app.LabelAtrBanner.Text, '<=10% labels is not reproduced'), ...
            'Non-raw banner must state <=10% labels is not reproduced');
        degStr = sprintf('%+.2f pp', (valAcc - 0.9930)*100);
        alertStr = 'RED Mismatch';
    end
    
    fprintf('%-18s | %6.2f %% (%4d/%4d) | %-12s | %-10s\n', ...
        prep, valAcc*100, round(valAcc*2425), 2425, degStr, alertStr);
end
fprintf('--------------------------------------------------------------------------------\n');
fprintf('[PASS] All 4 preprocessing modes live measured and banner alerts verified.\n');

% 7. Reset to Nominal Raw and Export Screenshot
fprintf('\n--- 7. Screenshot Export ---\n');
app.DropdownAtrPreprocess.Value = 'raw';
app.onAtrPreprocessChanged();
app.DropdownAtrClass.Value = '2s1_gun';
app.SpinnerAtrChipIdx.Value = 1;
app.onAtrClassChanged();
app.evaluateFullTestSet();
drawnow;

screenshotPath = fullfile(cfg.rootDir, 'docs', 'atr_tab.png');
app.saveScreenshot(screenshotPath, app.AtrTab);
assert(exist(screenshotPath, 'file') ~= 0, 'atr_tab.png must be created');
fprintf('[PASS] ATR tab screenshot exported to: %s\n', screenshotPath);

delete(app);
fprintf('\n>>> GATE G2B RESULT: PASS <<<\n');
fprintf('==============================================================================\n');
