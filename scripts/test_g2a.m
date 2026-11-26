% scripts/test_g2a.m
% Verification of Gate G2a Despeckle Tab functionality & Backfill Requirements
clc;
fprintf('==================== GATE G2A DESPECKLE TAB VERIFICATION ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('Reference: Frozen research functions despeckle_filters.m and p3b_denoise.m, executed independently.\n');

cfg = sar.env.config();

% 1. Launch App
fprintf('\n--- 1. App Launch & Tab Initialization ---\n');
app = SARWorkbench();
assert(~isempty(app) && isvalid(app.UIFigure), 'SARWorkbench must launch cleanly');
app.TabGroup.SelectedTab = app.DespeckleTab;
drawnow;
fprintf('[PASS] App launched and DespeckleTab selected.\n');

% 2. Multi-Chip, Multi-Parameter Equivalence (5 classes x 2 settings)
fprintf('\n--- 2. Multi-Chip, Multi-Parameter Equivalence Checks ---\n');
testClasses = {'2s1_gun', 'bmp2_tank', 'btr70_transport', 't72_tank', 'brdm2_truck'};
M_merlin = load(fullfile(cfg.modelsPath, 'p3b_merlin.mat'), 'net', 's');

for c = 1:numel(testClasses)
    clsName = testClasses{c};
    fprintf('Testing Class: %s\n', clsName);
    
    app.DropdownSourceType.Value = 'MSTAR Complex Test Chip';
    app.onSourceTypeChanged();
    app.DropdownMstarClass.Value = clsName;
    app.SpinnerChipIdx.Value = 1;
    app.onMstarClassChanged();
    drawnow;
    
    rawZ = app.CurrentRawData;
    rawAmp = single(abs(rawZ));
    
    % Parameter Setting A: Lee win=7, looks=1
    app.DropdownMethod.Value = 'lee';
    app.SpinnerWin.Value = 7;
    app.SpinnerLooks.Value = 1;
    app.onMethodChanged();
    app.runDespeckleFilter();
    refLee7 = despeckle_filters(rawAmp, 'lee', 7, 1);
    diffLee7 = max(abs(app.CurrentFilteredData(:) - refLee7(:)));
    assert(diffLee7 < 1e-6, 'Lee win=7 diff must be < 1e-6');
    fprintf('   Lee win=7 looks=1 max diff: %e (PASS)\n', diffLee7);
    
    % Parameter Setting B: Lee win=5, looks=1
    app.SpinnerWin.Value = 5;
    app.SpinnerLooks.Value = 1;
    app.runDespeckleFilter();
    refLee5 = despeckle_filters(rawAmp, 'lee', 5, 1);
    diffLee5 = max(abs(app.CurrentFilteredData(:) - refLee5(:)));
    assert(diffLee5 < 1e-6, 'Lee win=5 diff must be < 1e-6');
    fprintf('   Lee win=5 looks=1 max diff: %e (PASS)\n', diffLee5);
    
    % Parameter Setting C: MERLIN auto scale (loaded.s)
    app.DropdownMethod.Value = 'merlin_mstar';
    app.EditMerlinScale.Value = 'auto';
    app.onMethodChanged();
    app.runDespeckleFilter();
    refR_auto = p3b_denoise(M_merlin.net, rawZ, M_merlin.s);
    refMerlin_auto = sqrt(max(refR_auto, 0));
    diffMerlin_auto = max(abs(app.CurrentFilteredData(:) - refMerlin_auto(:)));
    assert(diffMerlin_auto < 1e-6, 'MERLIN auto scale diff must be < 1e-6');
    fprintf('   MERLIN auto scale max diff: %e (PASS)\n', diffMerlin_auto);
    
    % Parameter Setting D: MERLIN explicit scale (0.06)
    app.EditMerlinScale.Value = '0.06';
    app.runDespeckleFilter();
    refR_06 = p3b_denoise(M_merlin.net, rawZ, single(0.06));
    refMerlin_06 = sqrt(max(refR_06, 0));
    diffMerlin_06 = max(abs(app.CurrentFilteredData(:) - refMerlin_06(:)));
    assert(diffMerlin_06 < 1e-6, 'MERLIN scale=0.06 diff must be < 1e-6');
    fprintf('   MERLIN scale=0.06 max diff: %e (PASS)\n', diffMerlin_06);
end
fprintf('[PASS] All 5 classes and 4 parameter settings numerically verified against frozen research.\n');

% 3. Equivalence Negative Control (Parameter Perturbation)
fprintf('\n--- 3. Negative Control: Parameter Perturbation Detection ---\n');
app.DropdownMethod.Value = 'lee';
app.SpinnerWin.Value = 7;
app.SpinnerLooks.Value = 1;
app.onMethodChanged();
app.runDespeckleFilter();
guiLee7 = app.CurrentFilteredData;

% Compare against perturbed parameter (win=5 instead of win=7)
refLee5_mismatch = despeckle_filters(rawAmp, 'lee', 5, 1);
diffPerturb = max(abs(guiLee7(:) - refLee5_mismatch(:)));
fprintf('   Perturbed parameter diff (GUI Lee 7 vs Ref Lee 5): %e\n', diffPerturb);
assert(diffPerturb > 0.01, 'Negative control failed: perturbed parameter must produce significant diff');
fprintf('[PASS] Negative control passed: equivalence check correctly catches parameter discrepancy.\n');

% 4. Metrics Panel Verification (Lee & MERLIN on 5 chips from different classes)
fprintf('\n--- 4. Metrics Panel Verification (Lee & MERLIN across 5 Classes) ---\n');
for c = 1:numel(testClasses)
    clsName = testClasses{c};
    app.DropdownSourceType.Value = 'MSTAR Complex Test Chip';
    app.onSourceTypeChanged();
    app.DropdownMstarClass.Value = clsName;
    app.SpinnerChipIdx.Value = 1;
    app.onMstarClassChanged();
    drawnow;
    
    rawZ = app.CurrentRawData;
    rawAmp = single(abs(rawZ));
    I_raw = double(rawAmp).^2;
    
    % Test 4.1: Lee 7x7 metrics
    app.DropdownMethod.Value = 'lee';
    app.SpinnerWin.Value = 7;
    app.SpinnerLooks.Value = 1;
    app.onMethodChanged();
    app.runDespeckleFilter();
    
    I_filtLee = double(app.CurrentFilteredData).^2;
    mRefLee = p3b_metrics(I_raw, I_filtLee, 32, 41:88);
    
    valRawENL  = sscanf(app.LabelMetricRawENL.Text, 'Raw Clutter ENL: %f');
    valFiltENL = sscanf(app.LabelMetricFiltENL.Text, 'Filtered ENL: %f');
    valGain    = sscanf(app.LabelMetricENLGain.Text, 'ENL Gain: %f x');
    valBias    = sscanf(app.LabelMetricBias.Text, 'Intensity Bias: %f %%');
    valPeak    = sscanf(app.LabelMetricPeakRatio.Text, 'Peak Ratio: %f');
    
    assert(abs(valRawENL - mRefLee.enlRaw) < 0.05, 'Lee Raw ENL must match p3b_metrics');
    assert(abs(valFiltENL - mRefLee.enl) < 0.05, 'Lee Filtered ENL must match p3b_metrics');
    assert(abs(valGain - mRefLee.gain) < 0.05, 'Lee ENL Gain must match p3b_metrics');
    assert(abs(valBias - 100*mRefLee.bias) < 0.05, 'Lee Bias must match p3b_metrics');
    assert(abs(valPeak - mRefLee.peak) < 0.05, 'Lee Peak ratio must match p3b_metrics');
    
    % Test 4.2: MERLIN metrics
    app.DropdownMethod.Value = 'merlin_mstar';
    app.EditMerlinScale.Value = 'auto';
    app.onMethodChanged();
    app.runDespeckleFilter();
    
    I_filtMerlin = double(app.CurrentFilteredData).^2;
    mRefMerlin = p3b_metrics(I_raw, I_filtMerlin, 32, 41:88);
    
    valRawENL_m  = sscanf(app.LabelMetricRawENL.Text, 'Raw Clutter ENL: %f');
    valFiltENL_m = sscanf(app.LabelMetricFiltENL.Text, 'Filtered ENL: %f');
    valGain_m    = sscanf(app.LabelMetricENLGain.Text, 'ENL Gain: %f x');
    valBias_m    = sscanf(app.LabelMetricBias.Text, 'Intensity Bias: %f %%');
    valPeak_m    = sscanf(app.LabelMetricPeakRatio.Text, 'Peak Ratio: %f');
    
    assert(abs(valRawENL_m - mRefMerlin.enlRaw) < 0.05, 'MERLIN Raw ENL must match p3b_metrics');
    assert(abs(valFiltENL_m - mRefMerlin.enl) < 0.05, 'MERLIN Filtered ENL must match p3b_metrics');
    assert(abs(valGain_m - mRefMerlin.gain) < 0.05, 'MERLIN ENL Gain must match p3b_metrics');
    assert(abs(valBias_m - 100*mRefMerlin.bias) < 0.05, 'MERLIN Bias must match p3b_metrics');
    assert(abs(valPeak_m - mRefMerlin.peak) < 0.05, 'MERLIN Peak ratio must match p3b_metrics');
    
    fprintf('   Class %-15s: Lee (gain=%.2fx, bias=%+.2f%%) | MERLIN (gain=%.2fx, bias=%+.2f%%) [MATCH]\n', ...
        clsName, mRefLee.gain, 100*mRefLee.bias, mRefMerlin.gain, 100*mRefMerlin.bias);
end
fprintf('[PASS] Metrics panel matches p3b_metrics across all 5 classes for both Lee and MERLIN.\n');

% 4.3 Negative Control: Clutter Mask Perturbation
fprintf('   --- Metrics Panel Negative Control (Clutter Mask Perturbation) ---\n');
mRefPerturb = p3b_metrics(I_raw, I_filtMerlin, 16, 20:60);
diffGain = abs(mRefMerlin.gain - mRefPerturb.gain);
diffBias = abs(mRefMerlin.bias - mRefPerturb.bias);
fprintf('     Clutter mask shift: Gain diff = %.2f, Bias diff = %.4f\n', diffGain, diffBias);
assert(diffGain > 0.5 || diffBias > 0.01, 'Negative control must detect clutter mask shift');
fprintf('[PASS] Metrics negative control passed: metric calculation is strictly sensitive to clutter region.\n');

% B. Unsegmented Gotcha Source metrics check
app.DropdownSourceType.Value = 'Gotcha Pass 8 (Complex)';
app.onSourceTypeChanged();
app.DropdownMethod.Value = 'lee';
app.onMethodChanged();
app.runDespeckleFilter();
drawnow;

assert(contains(app.LabelMetricRawENL.Text, 'n/a'), 'Unsegmented source must display n/a for Raw ENL');
assert(contains(app.LabelMetricPeakRatio.Text, 'n/a'), 'Unsegmented source must display n/a for Peak Ratio');
fprintf('[PASS] Unsegmented Gotcha source displays n/a for undefined clutter/target metrics.\n');

% 5. MERLIN-on-Gotcha Banner Check
fprintf('\n--- 5. MERLIN (MSTAR Net) on Gotcha Source Banner Check ---\n');
app.DropdownMethod.Value = 'merlin_mstar';
app.onMethodChanged();
drawnow;

fprintf('   Banner: "%s"\n', app.LabelDespeckleBanner.Text);
assert(contains(app.LabelDespeckleBanner.Text, 'peak ratio 1.54'), 'Banner must note peak ratio 1.54');
assert(contains(app.LabelDespeckleBanner.Text, '1.72 / 1.54'), 'Banner must note widths 1.72 / 1.54');
assert(app.BannerDespeckle.BackgroundColor(1) > 0.95, 'Banner background must be amber/red alert');
fprintf('[PASS] MERLIN on Gotcha triggers specific point-target distortion banner.\n');

% 6. Amplitude Source Boundary & Direct Negative Control
fprintf('\n--- 6. Amplitude Source Boundary Enforcement ---\n');
app.DropdownSourceType.Value = 'Sentinel-1 GRD (Real Amplitude)';
app.onSourceTypeChanged();
app.DropdownMethod.Value = 'merlin_mstar';
app.onMethodChanged();
drawnow;

assert(strcmp(app.ButtonRunFilter.Enable, 'off'), 'Run Filter must be DISABLED for MERLIN on amplitude source');
assert(contains(app.LabelDespeckleBanner.Text, 'SCIENTIFIC LIMIT'), 'Banner must display SCIENTIFIC LIMIT');
fprintf('[PASS] MERLIN Run button disabled on amplitude source.\n');

try
    sar.despeckle.apply(app.CurrentRawData, 'merlin_mstar');
    error('sar:negativeControl:failed', 'Direct apply failed to reject amplitude data');
catch ME
    assert(strcmp(ME.identifier, 'sar:despeckle:invalidInputType'), 'Expected invalidInputType');
    fprintf('[PASS] Direct invocation negative control rejected with: "%s"\n', ME.message);
end

% 7. Failed-Validation Gotcha MERLIN Toggle Check
fprintf('\n--- 7. Failed-Validation Gotcha MERLIN Toggle Check ---\n');
app.DropdownSourceType.Value = 'MSTAR Complex Test Chip';
app.onSourceTypeChanged();
app.CheckShowFailed.Value = true;
app.onShowFailedChanged();
app.DropdownMethod.Value = 'merlin_gotcha';
app.onMethodChanged();
drawnow;

assert(contains(app.LabelDespeckleBanner.Text, 'FAILED VALIDATION'), 'Banner must display FAILED VALIDATION');
assert(app.BannerDespeckle.BackgroundColor(1) > 0.95 && app.BannerDespeckle.BackgroundColor(2) < 0.9, ...
    'Banner background must be red');
fprintf('[PASS] Failed-validation Gotcha MERLIN displayed with RED warning banner.\n');

% 8. Switch back to Nominal MSTAR + MERLIN and Export Screenshot
fprintf('\n--- 8. Screenshot Export ---\n');
app.DropdownMethod.Value = 'merlin_mstar';
app.EditMerlinScale.Value = 'auto';
app.onMethodChanged();
app.runDespeckleFilter();
drawnow;

screenshotPath = fullfile(cfg.rootDir, 'docs', 'despeckle_tab.png');
app.saveScreenshot(screenshotPath, app.DespeckleTab);
assert(exist(screenshotPath, 'file') ~= 0, 'despeckle_tab.png must be created');
fprintf('[PASS] Despeckle tab screenshot exported to: %s\n', screenshotPath);

delete(app);
fprintf('\n>>> GATE G2A RESULT: PASS (All Backfill Conditions Satisfied) <<<\n');
fprintf('==============================================================================\n');
