function test_interactive_launch(conditionName)
% TEST_INTERACTIVE_LAUNCH  Verify SARWorkbench launch and button interactions
if nargin < 1, conditionName = 'default'; end
fprintf('================ TESTING LAUNCH: CONDITION %s ================\n', conditionName);
fprintf('Current Directory: %s\n', pwd);
fprintf('Launching SARWorkbench...\n');

app = SARWorkbench();
assert(~isempty(app) && isvalid(app.UIFigure), 'UIFigure must be created and valid');
assert(~isempty(app.EnvStatus), 'EnvStatus must be populated');
fprintf('[PASS] App launched. Overall status: %s\n', app.EnvStatus.overall);

fprintf('Programmatically triggering Refresh button...\n');
app.ButtonRefresh.ButtonPushedFcn(app.ButtonRefresh, []);
drawnow;

assert(~isempty(app.EnvStatus), 'EnvStatus must remain populated after refresh');
fprintf('[PASS] Refresh button executed successfully. Status: %s\n', app.EnvStatus.overall);

delete(app);
fprintf('[PASS] App closed cleanly.\n');
fprintf('>>> CONDITION %s RESULT: PASS <<<\n\n', conditionName);
end
