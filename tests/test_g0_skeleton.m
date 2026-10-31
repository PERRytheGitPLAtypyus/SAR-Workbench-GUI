function test_g0_skeleton()
% TEST_G0_SKELETON  Verification test for Gate G0
fprintf('==================== GATE G0 VERIFICATION ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

root = fileparts(fileparts(mfilename('fullpath')));
cd(root);
startup;

%% 1. Check directory skeleton
reqDirs = {'app', '+sar', 'models', 'tests', 'research', 'docs'};
for i = 1:numel(reqDirs)
    d = fullfile(root, reqDirs{i});
    assert(exist(d, 'dir') ~= 0, 'Missing directory: %s', reqDirs{i});
    fprintf('[PASS] Skeleton directory exists: %s\n', reqDirs{i});
end

%% 2. Check configuration files
cfgFile = fullfile(root, 'sarconfig.json');
cfgExFile = fullfile(root, 'sarconfig.example.json');
assert(exist(cfgFile, 'file') ~= 0, 'Missing sarconfig.json');
assert(exist(cfgExFile, 'file') ~= 0, 'Missing sarconfig.example.json');
fprintf('[PASS] Configuration files exist: sarconfig.json, sarconfig.example.json\n');

%% 3. Run sar.env.check
st = sar.env.check();
assert(isstruct(st), 'sar.env.check must return a status struct');
assert(strcmp(st.overall, 'PASS'), 'sar.env.check overall status must be PASS');
fprintf('[PASS] sar.env.check returned PASS\n');

%% 4. Instantiate SARWorkbench GUI
fprintf('Launching programmatic UI figure: SARWorkbench...\n');
gui = SARWorkbench();
assert(isvalid(gui.UIFigure), 'UIFigure was not created');
assert(numel(gui.TabGroup.Children) == 6, 'Expected 6 tabs in TabGroup, found %d', numel(gui.TabGroup.Children));

% Check that Home tab status lamps match reality
green = [0.15 0.75 0.25];
assert(isequal(gui.LampMatlab.Color, green), 'MATLAB version lamp must be green');
assert(isequal(gui.LampToolboxes.Color, green), 'Toolboxes lamp must be green');
assert(isequal(gui.LampGPU.Color, green), 'GPU lamp must be green');
assert(isequal(gui.LampMstar.Color, green), 'MSTAR data lamp must be green');
assert(isequal(gui.LampGotcha.Color, green), 'Gotcha data lamp must be green');
fprintf('[PASS] App opened and Home status lights match reality.\n');

% Safely delete GUI
delete(gui);
fprintf('[PASS] GUI safely closed.\n');

fprintf('\n>>> GATE G0 RESULT: PASS <<<\n');
fprintf('==============================================================\n');
end
