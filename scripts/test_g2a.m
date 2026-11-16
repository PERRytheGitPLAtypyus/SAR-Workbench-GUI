% scripts/test_g2a.m
% Verification of Gate G2a Despeckle Tab functionality
clear; clc;
fprintf('==================== GATE G2A DESPECKLE TAB VERIFICATION ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

% 1. Launch App
fprintf('\n--- 1. App Launch & Tab Initialization ---\n');
app = SARWorkbench();
assert(~isempty(app) && isvalid(app.UIFigure), 'SARWorkbench must launch cleanly');
app.TabGroup.SelectedTab = app.DespeckleTab;
drawnow;
fprintf('[PASS] App launched and DespeckleTab selected.\n');

% 2. Verify initial MSTAR chip loaded
assert(~isempty(app.CurrentRawData), 'Initial MSTAR chip must be loaded');
assert(~isreal(app.CurrentRawData), 'Initial MSTAR chip must be complex');
fprintf('[PASS] Default MSTAR chip loaded: %s\n', app.CurrentSourceInfo.name);

% 3. Test Lee Filter GUI vs Script Numerical Equivalence
fprintf('\n--- 2. Lee Filter Numerical Equivalence (GUI vs Script) ---\n');
app.DropdownMethod.Value = 'lee';
app.SpinnerWin.Value = 7;
app.SpinnerLooks.Value = 1;
app.onMethodChanged();
drawnow;

app.runDespeckleFilter();
guiFiltLee = app.CurrentFilteredData;
assert(~isempty(guiFiltLee), 'Filtered data must be generated');

% Direct script reference execution
rawAmp = single(abs(app.CurrentRawData));
scriptFiltLee = despeckle_filters(rawAmp, 'lee', 7, 1);
diffLee = max(abs(guiFiltLee(:) - scriptFiltLee(:)));
fprintf('   Max absolute difference (GUI vs Script Lee): %e\n', diffLee);
assert(diffLee < 1e-6, 'GUI Lee filter output must match despeckle_filters within 1e-6');
fprintf('[PASS] Lee filter numerical equivalence verified (< 1e-6).\n');

% 4. Test MERLIN GUI vs Script Numerical Equivalence
fprintf('\n--- 3. MERLIN Filter Numerical Equivalence (GUI vs Script) ---\n');
app.DropdownMethod.Value = 'merlin_mstar';
app.onMethodChanged();
drawnow;

app.runDespeckleFilter();
guiFiltMerlin = app.CurrentFilteredData;
assert(~isempty(guiFiltMerlin), 'MERLIN filtered data must be generated');

% Direct script reference execution
cfg = sar.env.config();
M = load(fullfile(cfg.modelsPath, 'p3b_merlin.mat'), 'net', 's');
scriptR = p3b_denoise(M.net, app.CurrentRawData, M.s);
scriptFiltMerlin = sqrt(max(scriptR, 0));
diffMerlin = max(abs(guiFiltMerlin(:) - scriptFiltMerlin(:)));
fprintf('   Max absolute difference (GUI vs Script MERLIN): %e\n', diffMerlin);
assert(diffMerlin < 1e-6, 'GUI MERLIN output must match p3b_denoise within 1e-6');
fprintf('[PASS] MERLIN numerical equivalence verified (< 1e-6).\n');

% 5. Test Amplitude Source & MERLIN Boundary Enforcement
fprintf('\n--- 4. Amplitude Source Boundary Enforcement ---\n');
app.DropdownSourceType.Value = 'Sentinel-1 GRD (Real Amplitude)';
app.onSourceTypeChanged();
drawnow;

assert(isreal(app.CurrentRawData), 'Sentinel-1 source must be real amplitude');
fprintf('   Loaded Amplitude Source: %s (isreal=%d)\n', app.CurrentSourceInfo.name, isreal(app.CurrentRawData));

% Select MERLIN and verify it is disabled
app.DropdownMethod.Value = 'merlin_mstar';
app.onMethodChanged();
drawnow;

assert(strcmp(app.ButtonRunFilter.Enable, 'off'), 'Run Filter must be DISABLED for MERLIN on amplitude source');
assert(contains(app.LabelDespeckleBanner.Text, 'SCIENTIFIC LIMIT'), 'Banner must display SCIENTIFIC LIMIT');
fprintf('[PASS] MERLIN Run button correctly disabled for amplitude source.\n');
fprintf('       Banner: "%s"\n', app.LabelDespeckleBanner.Text);

% 6. Negative Control: Attempting to invoke MERLIN on amplitude data directly
fprintf('\n--- 5. Negative Control: Forcing MERLIN on Amplitude Data ---\n');
try
    sar.despeckle.apply(app.CurrentRawData, 'merlin_mstar');
    error('sar:negativeControl:failed', 'MERLIN failed to reject amplitude data');
catch ME
    assert(strcmp(ME.identifier, 'sar:despeckle:invalidInputType'), ...
        'Expected sar:despeckle:invalidInputType error');
    fprintf('[EXPECTED FAIL] Caught rejection: "%s"\n', ME.message);
    fprintf('[PASS] Negative control passed: direct MERLIN invocation rejected.\n');
end

% 7. Test Show Failed Methods Toggle & Banner
fprintf('\n--- 6. Failed-Validation Gotcha MERLIN Toggle ---\n');
app.DropdownSourceType.Value = 'MSTAR Complex Test Chip';
app.onSourceTypeChanged();
app.CheckShowFailed.Value = true;
app.onShowFailedChanged();
drawnow;

assert(any(strcmp(app.DropdownMethod.ItemsData, 'merlin_gotcha')), 'merlin_gotcha must appear when CheckShowFailed is true');
app.DropdownMethod.Value = 'merlin_gotcha';
app.onMethodChanged();
drawnow;

assert(contains(app.LabelDespeckleBanner.Text, 'FAILED VALIDATION'), 'Banner must display FAILED VALIDATION');
assert(app.BannerDespeckle.BackgroundColor(1) > 0.9, 'Banner background must be red');
fprintf('[PASS] Failed-validation Gotcha MERLIN displayed with RED warning banner.\n');
fprintf('       Banner: "%s"\n', app.LabelDespeckleBanner.Text);

% 8. Switch back to MSTAR + MERLIN and Export Screenshot
fprintf('\n--- 7. Screenshot Export ---\n');
app.DropdownMethod.Value = 'merlin_mstar';
app.onMethodChanged();
app.runDespeckleFilter();
drawnow;

screenshotPath = fullfile(cfg.rootDir, 'docs', 'despeckle_tab.png');
app.saveScreenshot(screenshotPath, app.DespeckleTab);
assert(exist(screenshotPath, 'file') ~= 0, 'despeckle_tab.png must be created');
fprintf('[PASS] Despeckle tab screenshot exported to: %s\n', screenshotPath);

delete(app);
fprintf('\n>>> GATE G2A RESULT: PASS <<<\n');
fprintf('==============================================================================\n');
