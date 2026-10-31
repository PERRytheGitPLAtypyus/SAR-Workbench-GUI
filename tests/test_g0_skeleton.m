function test_g0_skeleton()
% TEST_G0_SKELETON  Verification test for Gate G0
fprintf('==================== GATE G0 VERIFICATION ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

root = fileparts(fileparts(mfilename('fullpath')));
cd(root);
startup;

%% 1. Check directory skeleton
reqDirs = {'app', '+sar', 'models', 'tests', 'research', 'docs', 'research_new'};
for i = 1:numel(reqDirs)
    d = fullfile(root, reqDirs{i});
    assert(exist(d, 'dir') ~= 0, 'Missing directory: %s', reqDirs{i});
    fprintf('[PASS] Skeleton directory exists: %s\n', reqDirs{i});
end

%% 2. Check configuration files
cfgExFile = fullfile(root, 'sarconfig.example.json');
assert(exist(cfgExFile, 'file') ~= 0, 'Missing sarconfig.example.json');
fprintf('[PASS] Template configuration file exists: sarconfig.example.json\n');

%% 3. Check registries
regActive = sar.registry.despeckle(false);
assert(~any(strcmp({regActive.id}, 'merlin_gotcha')), 'MERLIN Gotcha must NOT be in active despeckle registry');
regAll = sar.registry.despeckle(true);
gotchaIdx = find(strcmp({regAll.id}, 'merlin_gotcha'), 1);
assert(~isempty(gotchaIdx), 'MERLIN Gotcha must be registered in all methods');
assert(strcmp(regAll(gotchaIdx).status, 'FAILED_VALIDATION'), 'MERLIN Gotcha status must be FAILED_VALIDATION');
assert(regAll(gotchaIdx).validationMetrics.peakRatio == 0.39, 'MERLIN Gotcha peak ratio must be 0.39');
fprintf('[PASS] Despeckle registry verified: MERLIN Gotcha marked FAILED_VALIDATION.\n');

%% 4. Run sar.env.check
st = sar.env.check();
assert(isstruct(st), 'sar.env.check must return a status struct');
assert(strcmp(st.overall, 'PASS'), 'sar.env.check overall status must be PASS');
fprintf('[PASS] sar.env.check returned PASS\n');

%% 5. Instantiate SARWorkbench GUI
fprintf('Launching programmatic UI figure: SARWorkbench...\n');
gui = SARWorkbench();
assert(isvalid(gui.UIFigure), 'UIFigure was not created');
assert(numel(gui.TabGroup.Children) == 6, 'Expected 6 tabs in TabGroup, found %d', numel(gui.TabGroup.Children));

% Check that Home tab status lamps match reality:
green = [0.15 0.75 0.25];
amber = [0.95 0.70 0.05];

assert(isequal(gui.LampMatlab.Color, green), 'MATLAB version lamp must be green');
assert(isequal(gui.LampToolboxes.Color, green), 'Toolboxes lamp must be green');
assert(isequal(gui.LampGPU.Color, green), 'GPU lamp must be green');
assert(isequal(gui.LampMstar.Color, green), 'MSTAR data lamp must be green');
assert(isequal(gui.LampGotcha.Color, green), 'Gotcha data lamp must be green');
assert(isequal(gui.LampSentinel.Color, green), 'Sentinel-1 lamp must be green');
assert(isequal(gui.LampMerlin.Color, green), 'MERLIN MSTAR lamp must be green');

% ATR CNN is not trained yet -> MUST BE AMBER!
assert(isequal(gui.LampCnn.Color, amber), 'ATR CNN lamp must be AMBER when cnn_mstar.mat is missing');
fprintf('[PASS] ATR CNN lamp is AMBER (matches reality: model not trained yet).\n');
fprintf('[PASS] App opened and all Home status lights match reality.\n');

% Save screenshot of the Home tab
imgOut = fullfile(root, 'docs', 'home_tab.png');
gui.saveScreenshot(imgOut);
assert(exist(imgOut, 'file') ~= 0, 'Screenshot file was not generated');
fprintf('[PASS] Home tab screenshot exported: %s\n', imgOut);

% Safely delete GUI
delete(gui);
fprintf('[PASS] GUI safely closed.\n');

fprintf('\n>>> GATE G0 RESULT: PASS <<<\n');
fprintf('==============================================================\n');
end
