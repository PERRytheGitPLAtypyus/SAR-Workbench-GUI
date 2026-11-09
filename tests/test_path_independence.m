classdef test_path_independence < matlab.unittest.TestCase
    % TEST_PATH_INDEPENDENCE  Permanent regression test for Gate G0 path bug
    %   Verifies that SARWorkbench launches, runs environment check, and handles
    %   button events cleanly when executed from another folder with only app/ on the path.

    methods (Test)
        function testLaunchFromExternalFolderWithOnlyAppOnPath(testCase)
            originalDir = pwd;
            testCase.addTeardown(@() cd(originalDir));
            
            % Navigate to temporary directory outside repository
            tempFolder = tempdir;
            cd(tempFolder);
            
            % Add ONLY app directory to path
            repoRoot = 'C:\Users\sruja\OneDrive\Documents\SARorsmthn';
            appDir = fullfile(repoRoot, 'app');
            addpath(appDir);
            
            % Launch app
            app = SARWorkbench();
            testCase.addTeardown(@() delete(app));
            
            testCase.assertNotEmpty(app);
            testCase.assertTrue(isvalid(app.UIFigure), 'UIFigure must be valid');
            testCase.assertNotEmpty(app.EnvStatus, 'EnvStatus must be populated on launch');
            testCase.verifyEqual(app.EnvStatus.overall, 'PASS', 'Overall status should be PASS');
            
            % Programmatically trigger Refresh button
            app.ButtonRefresh.ButtonPushedFcn(app.ButtonRefresh, []);
            drawnow;
            
            testCase.verifyEqual(app.EnvStatus.overall, 'PASS', 'Status must remain PASS after refresh');
            fprintf('[PASS] testLaunchFromExternalFolderWithOnlyAppOnPath: Launch and refresh verified from tempdir.\n');
        end
    end
end
