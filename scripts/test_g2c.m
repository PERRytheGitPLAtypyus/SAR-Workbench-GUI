% scripts/test_g2c.m
% Verification of Gate G2c: Gotcha Imaging Tab
fprintf('==================== GATE G2C GOTCHA IMAGING TAB VERIFICATION ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('Reference: Frozen research functions gotcha_find.m, gotcha_load.m, bp_gotcha.m, and p3b_gotcha_test.m\n');

cfg = sar.env.config();

% 1. Launch App and Select Gotcha Tab
fprintf('\n--- 1. App Launch & Gotcha Tab Initialization ---\n');
app = SARWorkbench();
assert(~isempty(app) && isvalid(app.UIFigure), 'SARWorkbench must launch cleanly');
app.TabGroup.SelectedTab = app.GotchaTab;
drawnow;
fprintf('[PASS] App launched and GotchaTab initialized.\n');

% 2. Verify Control Defaults and Polarization Validation Labels
fprintf('\n--- 2. Control Defaults & Polarization Labels ---\n');
assert(strcmp(app.DropdownGotchaPol.Value, 'HH'), 'Default polarization must be HH');
polItems = app.DropdownGotchaPol.Items;
assert(any(contains(polItems, 'VV (not validated)')), 'VV must be labeled "(not validated)"');
assert(any(contains(polItems, 'HV (not validated)')), 'HV must be labeled "(not validated)"');
assert(any(contains(polItems, 'VH (not validated)')), 'VH must be labeled "(not validated)"');
fprintf('   Polarization options: %s\n', strjoin(polItems, ', '));

assert(app.SpinnerGotchaAzStart.Value == 1, 'Default Az Start must be 1');
assert(app.SpinnerGotchaAzWidth.Value == 3, 'Default Az Width must be 3');
assert(abs(app.SpinnerGotchaDx.Value - 0.30) < 1e-4, 'Default dx must be 0.30 m');
assert(abs(app.SpinnerGotchaZ.Value - (-0.3)) < 1e-4, 'Default height z must be -0.3 m');
fprintf('[PASS] Control defaults and validation labels verified.\n');

% 3. Numerical Equivalence Against Frozen bp_gotcha (Az 1-3 HH)
fprintf('\n--- 3. Numerical Equivalence Against Frozen bp_gotcha (Az 1-3 HH) ---\n');
app.DropdownGotchaPol.Value = 'HH';
app.SpinnerGotchaAzStart.Value = 1;
app.SpinnerGotchaAzWidth.Value = 3;
app.SpinnerGotchaDx.Value = 0.30;
app.SpinnerGotchaZ.Value = -0.30;
app.formGotchaImage();
drawnow;

guiImg = app.GotchaImage;
guiXv  = app.GotchaXv;
guiYv  = app.GotchaYv;

% Compute independent reference using frozen research functions directly
refFiles = gotcha_find(cfg.dataPath.gotcha, 8, 'HH', 1:3);
refG = gotcha_load(refFiles);
refOpts = struct('xlim', [-44 6], 'ylim', [10 58], 'dx', 0.30, 'z', -0.3, ...
    'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
[refImg, refXv, refYv] = bp_gotcha(refG, refOpts);

diffImg = max(abs(guiImg(:) - single(refImg(:))));
diffXv  = max(abs(guiXv(:) - refXv(:)));
diffYv  = max(abs(guiYv(:) - refYv(:)));

fprintf('   GUI vs Reference Image Max Diff: %e\n', diffImg);
fprintf('   X-grid max diff: %e, Y-grid max diff: %e\n', diffXv, diffYv);
assert(diffImg < 1e-6, 'Gotcha backprojection output must match bp_gotcha (< 1e-6)');
assert(diffXv < 1e-6 && diffYv < 1e-6, 'Grid coordinates must match bp_gotcha');
fprintf('[PASS] Numerical equivalence against frozen bp_gotcha confirmed.\n');

% 4. Equivalence Negative Control (Aperture Discrepancy Detection)
fprintf('\n--- 4. Equivalence Negative Control (Aperture Discrepancy Detection) ---\n');
mismatchFiles = gotcha_find(cfg.dataPath.gotcha, 8, 'HH', 86:88);
mismatchG = gotcha_load(mismatchFiles);
[mismatchImg, ~, ~] = bp_gotcha(mismatchG, refOpts);
diffNegative = max(abs(guiImg(:) - single(mismatchImg(:))));
fprintf('   Negative control diff (Az 1-3 vs Az 86-88): %e\n', diffNegative);
assert(diffNegative > 1.0, 'Negative control must catch aperture discrepancy');
fprintf('[PASS] Negative control passed: backprojection image is strictly aperture-sensitive.\n');

% 5. Calibration Target 2 (15TR03C) Resolution & Survey Offset
fprintf('\n--- 5. Calibration Target 2 (15TR03C) Resolution & Offset Check ---\n');
app.DropdownGotchaTarget.Value = 2;
app.inspectCurrentTarget();
drawnow;

st = app.GotchaTargetStats;
fprintf('   Target 2 (15TR03C) Measured Resolution:\n');
fprintf('     Range -3 dB Width (wx):  %.4f m (Nominal: 0.30 m +/- 10%%)\n', st.widthX);
fprintf('     Azimuth -3 dB Width (wy): %.4f m\n', st.widthY);
fprintf('     Mean Resolution:         %.4f m\n', st.meanWidth);
fprintf('     Offset from Survey:      %.4f m (Nominal range: 0.15 - 0.75 m)\n', st.offsetMeters);
fprintf('     Peak Intensity:          %.2e\n', st.peakIntensity);

% Assert width within 0.30 m +/- 10% [0.27, 0.33 m]
assert(st.widthX >= 0.27 && st.widthX <= 0.33, ...
    sprintf('Target 2 range width (%.4f m) must be within 0.30 m +/- 10%% [0.27, 0.33 m]', st.widthX));
% Assert offset within 0.15 - 0.75 m
assert(st.offsetMeters >= 0.15 && st.offsetMeters <= 0.75, ...
    sprintf('Target 2 offset (%.4f m) must be within 0.15 - 0.75 m', st.offsetMeters));
assert(contains(app.LabelGotchaCalibStatus.Text, 'CALIBRATION TARGET STATUS: PASS'), ...
    'Calibration status label must report PASS');
fprintf('[PASS] Calibration target resolution (%.3f m) and offset (%.3f m) verified.\n', ...
    st.widthX, st.offsetMeters);

% 6. Reflector Catalog & Visibility Across 4 Cardinal Test Apertures
fprintf('\n--- 6. Reflector Catalog & Visibility Across 4 Test Apertures ---\n');
[visCount, pairDetails] = sar.imaging.gotcha.findVisibleTargets({1:3, 86:88, 176:178, 266:268}, cfg.rootDir);
fprintf('   Total Visible Pairs Detected: %d / 13 expected\n', visCount);
for k = 1:numel(pairDetails)
    fprintf('     Pair %2d: Ap az %s -> Tgt %2d (%s) at (%.2f, %.2f) m | Peak/Med: %.1f dB | wx=%.3f m, wy=%.3f m\n', ...
        k, mat2str(pairDetails(k).aperture), pairDetails(k).targetIdx, pairDetails(k).name, ...
        pairDetails(k).pos(1), pairDetails(k).pos(2), pairDetails(k).peakRatioDb, ...
        pairDetails(k).widthX, pairDetails(k).widthY);
end
assert(visCount == 13, sprintf('Must detect exactly 13 visible reflector pairs across the 4 apertures (got %d)', visCount));
fprintf('[PASS] All 13 visible reflector pairs confirmed across test apertures.\n');

% 7. Scientific Domain Advisory Banner Verifications
fprintf('\n--- 7. Scientific Advisory Banner Verification ---\n');
bannerText = app.LabelGotchaBanner.Text;
fprintf('   Gotcha Banner Text: "%s"\n', bannerText);
assert(contains(bannerText, 'planar backprojection (z = -0.3 m)', 'IgnoreCase', true), 'Banner must state planar backprojection (z = -0.3 m)');
assert(contains(bannerText, '0.15 - 0.75 m'), 'Banner must document 0.15 - 0.75 m offsets');
assert(contains(bannerText, 'afr=afp=0'), 'Banner must document autofocus disabled (afr=afp=0)');
assert(contains(bannerText, 'PGA') && contains(bannerText, 'not implemented'), 'Banner must document PGA not implemented');
fprintf('[PASS] Mandatory scientific banners verified.\n');

% 8. Screenshot Export
fprintf('\n--- 8. Screenshot Export ---\n');
screenshotPath = fullfile(cfg.rootDir, 'docs', 'gotcha_tab.png');
app.saveScreenshot(screenshotPath, app.GotchaTab);
assert(exist(screenshotPath, 'file') ~= 0, 'gotcha_tab.png must be created');
fprintf('[PASS] Gotcha tab screenshot exported to: %s\n', screenshotPath);

delete(app);
fprintf('\n>>> GATE G2C RESULT: PASS (All Gotcha Image Formation Requirements Satisfied) <<<\n');
fprintf('===================================================================================\n');
