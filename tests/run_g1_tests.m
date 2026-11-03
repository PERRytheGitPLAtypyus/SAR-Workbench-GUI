function res = run_g1_tests()
% RUN_G1_TESTS  Execute Gate G1 golden unit tests
fprintf('==================== GATE G1 ADAPTERS & GOLDEN TESTS ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

startup;
res = runtests('tests/TestG1Adapters.m');

fprintf('\n----------------- Test Results Summary -----------------\n');
table(res)

allPassed = all([res.Passed]);
if allPassed
    fprintf('\n>>> GATE G1 RESULT: PASS (All %d golden tests passed) <<<\n', numel(res));
else
    fprintf('\n>>> GATE G1 RESULT: FAIL (%d failures) <<<\n', sum([res.Failed]));
end
fprintf('=========================================================================\n');

if ~allPassed
    error('run_g1_tests:failed', 'Gate G1 test suite failed.');
end
end
