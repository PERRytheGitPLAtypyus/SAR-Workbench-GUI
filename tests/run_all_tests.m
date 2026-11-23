% tests/run_all_tests.m
% Master regression harness for Phase 5 SAR Workbench
% Runs all gates: G0, Path self-containment, G1 adapters, G2a despeckle, and G2b ATR.
clc;
tMaster0 = tic;

testsDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(testsDir);
cd(repoRoot);
SARWorkbench.ensurePaths();

fprintf('==============================================================================\n');
fprintf('           SAR WORKBENCH PHASE 5 COMPREHENSIVE REGRESSION SUITE\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('Repo Root: %s\n', repoRoot);
fprintf('==============================================================================\n');

%% 1. Gate G0: Environment Verification
fprintf('\n>>> STEP 1/5: RUNNING GATE G0 (ENVIRONMENT CHECK) <<<\n');
env = sar.env.check();
assert(strcmp(env.overall, 'PASS'), 'G0 assertion failed: environment overall must be PASS');
fprintf('[PASS] Gate G0 passed cleanly.\n');

%% 2. Path Self-Containment Verification (Condition B)
fprintf('\n>>> STEP 2/5: VERIFYING PATH SELF-CONTAINMENT <<<\n');
p = path;
assert(contains(p, fullfile(repoRoot, 'app')), 'app/ must be on MATLAB path');
assert(contains(p, fullfile(repoRoot, 'research')), 'research/ must be on MATLAB path');
assert(contains(p, fullfile(repoRoot, 'models')), 'models/ must be on MATLAB path');
fprintf('[PASS] Path self-containment verified.\n');

%% 3. Gate G1: Golden Adapter Tests
fprintf('\n>>> STEP 3/5: RUNNING GATE G1 (GOLDEN ADAPTER TESTS) <<<\n');
g1Results = runtests(fullfile(repoRoot, 'tests', 'TestG1Adapters.m'));
assert(all([g1Results.Passed]), 'G1 assertion failed: all golden adapter tests must pass');
fprintf('[PASS] Gate G1 passed (%d/%d tests passed).\n', sum([g1Results.Passed]), numel(g1Results));

%% 4. Gate G2a: Despeckle Tab Verification & Backfill Requirements
fprintf('\n>>> STEP 4/5: RUNNING GATE G2A (DESPECKLE TAB) <<<\n');
run(fullfile(repoRoot, 'scripts', 'test_g2a.m'));
fprintf('[PASS] Gate G2a passed cleanly.\n');

%% 5. Gate G2b: MSTAR ATR Tab Verification
fprintf('\n>>> STEP 5/5: RUNNING GATE G2B (MSTAR ATR TAB) <<<\n');
run(fullfile(repoRoot, 'scripts', 'test_g2b.m'));
fprintf('[PASS] Gate G2b passed cleanly.\n');

elapsedTotal = toc(tMaster0);
fprintf('\n==============================================================================\n');
fprintf('>>> ALL PHASE 5 GATES AND REGRESSION TESTS PASSED IN %.2f SECONDS <<<\n', elapsedTotal);
fprintf('==============================================================================\n');
