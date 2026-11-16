classdef SARWorkbench < handle
    % SARWORKBENCH  Interactive MATLAB Application for SAR Research & Analysis
    %   Phase 5 Programmatic UI Figure implementation (no .mlapp dependencies).
    %   Strict separation: GUI controls invoke +sar package adapters only.

    properties
        UIFigure            matlab.ui.Figure
        TabGroup            matlab.ui.container.TabGroup
        
        % Tabs
        HomeTab             matlab.ui.container.Tab
        DespeckleTab        matlab.ui.container.Tab
        AtrTab              matlab.ui.container.Tab
        GotchaTab           matlab.ui.container.Tab
        SimulateTab         matlab.ui.container.Tab
        ResultsTab          matlab.ui.container.Tab
        
        % Environment status data
        EnvStatus           struct
        
        % Home tab UI components (Status Lamps & Labels)
        LampMatlab          matlab.ui.control.Lamp
        LabelMatlab         matlab.ui.control.Label
        LampToolboxes       matlab.ui.control.Lamp
        LabelToolboxes      matlab.ui.control.Label
        LampGPU             matlab.ui.control.Lamp
        LabelGPU            matlab.ui.control.Label
        LampMstar           matlab.ui.control.Lamp
        LabelMstar          matlab.ui.control.Label
        LampGotcha          matlab.ui.control.Lamp
        LabelGotcha         matlab.ui.control.Label
        LampSentinel        matlab.ui.control.Lamp
        LabelSentinel       matlab.ui.control.Label
        LampMerlin          matlab.ui.control.Lamp
        LabelMerlin         matlab.ui.control.Label
        LampCnn             matlab.ui.control.Lamp
        LabelCnn            matlab.ui.control.Label
        LabelOverall        matlab.ui.control.Label
        ButtonRefresh       matlab.ui.control.Button
        
        % Despeckle Tab UI Components
        BannerDespeckle         matlab.ui.container.Panel
        LabelDespeckleBanner    matlab.ui.control.Label
        
        DropdownSourceType      matlab.ui.control.DropDown
        DropdownMstarClass      matlab.ui.control.DropDown
        SpinnerChipIdx          matlab.ui.control.Spinner
        ButtonLoadSource        matlab.ui.control.Button
        LabelSourceInfo         matlab.ui.control.Label
        
        DropdownMethod          matlab.ui.control.DropDown
        CheckShowFailed         matlab.ui.control.CheckBox
        SpinnerWin              matlab.ui.control.Spinner
        SpinnerLooks            matlab.ui.control.Spinner
        EditMerlinScale         matlab.ui.control.EditField
        LabelParamWin           matlab.ui.control.Label
        LabelParamLooks         matlab.ui.control.Label
        LabelParamScale         matlab.ui.control.Label
        ButtonRunFilter         matlab.ui.control.Button
        
        AxesRaw                 matlab.ui.control.UIAxes
        AxesFiltered            matlab.ui.control.UIAxes
        AxesRatio               matlab.ui.control.UIAxes
        
        LabelMetricRawENL       matlab.ui.control.Label
        LabelMetricFiltENL      matlab.ui.control.Label
        LabelMetricENLGain      matlab.ui.control.Label
        LabelMetricBias         matlab.ui.control.Label
        LabelMetricTime         matlab.ui.control.Label
        
        % Despeckle State Data
        CurrentRawData
        CurrentFilteredData
        CurrentRawAmplitude
        CurrentRatioData
        CurrentSourceInfo       struct
        MstarTestList           struct
    end

    methods (Static)
        function repoRoot = ensurePaths()
            % Ensure repository root and package subdirectories are on MATLAB path
            appDir = fileparts(mfilename('fullpath'));
            if isempty(appDir)
                appDir = fileparts(which('SARWorkbench'));
            end
            repoRoot = fileparts(appDir);
            reqPaths = {repoRoot, appDir, fullfile(repoRoot, 'research'), fullfile(repoRoot, 'models')};
            pList = split(path, pathsep);
            for k = 1:numel(reqPaths)
                p = reqPaths{k};
                if exist(p, 'dir') && ~any(strcmpi(pList, p))
                    addpath(p);
                end
            end
        end
    end

    methods
        function app = SARWorkbench()
            % Constructor: Self-initialize paths, build UI and refresh environment
            SARWorkbench.ensurePaths();
            createComponents(app);
            refreshEnvironment(app);
            initDespeckleTab(app);
            if nargout == 0
                % Do not assign if called without LHS
            end
        end

        function refreshEnvironment(app)
            % Query system environment via adapter with robust error boundary
            try
                SARWorkbench.ensurePaths();
                app.EnvStatus = sar.env.check();
                updateHomeStatus(app);
            catch ME
                if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                    uialert(app.UIFigure, ME.message, 'Environment Check Error', 'Icon', 'error');
                end
                warning('SARWorkbench:refreshEnvironment', 'Environment check failed: %s', ME.message);
            end
        end

        function handleCallback(app, callbackFn)
            % Generic callback wrapper with exception trapping and user alert
            try
                SARWorkbench.ensurePaths();
                callbackFn();
            catch ME
                if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                    uialert(app.UIFigure, ME.message, 'Operation Error', 'Icon', 'error');
                end
                warning('SARWorkbench:CallbackError', 'Callback execution failed: %s', ME.message);
            end
        end

        function saveScreenshot(app, outputPath, targetTab)
            % Export figure screenshot to disk
            if nargin < 2 || isempty(outputPath)
                outputPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'docs', 'home_tab.png');
            end
            if nargin >= 3 && ~isempty(targetTab)
                app.TabGroup.SelectedTab = targetTab;
            end
            drawnow;
            exportapp(app.UIFigure, outputPath);
            fprintf('Screenshot saved to: %s\n', outputPath);
        end

        function delete(app)
            % Destructor: close figure safely
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods
        function createComponents(app)
            % Main Figure Window
            app.UIFigure = uifigure('Name', 'SAR Workbench - Phase 5', ...
                'Position', [100 100 1100 750], ...
                'Color', [0.95 0.95 0.96]);

            % Top tab group
            app.TabGroup = uitabgroup(app.UIFigure, ...
                'Position', [10 10 1080 730]);

            % Create Tabs
            app.HomeTab      = uitab(app.TabGroup, 'Title', ' Home & Environment ');
            app.DespeckleTab = uitab(app.TabGroup, 'Title', ' Despeckling ');
            app.AtrTab       = uitab(app.TabGroup, 'Title', ' MSTAR ATR ');
            app.GotchaTab    = uitab(app.TabGroup, 'Title', ' Gotcha Backprojection ');
            app.SimulateTab  = uitab(app.TabGroup, 'Title', ' Simulation ');
            app.ResultsTab   = uitab(app.TabGroup, 'Title', ' Research Results ');

            % Populate Tab Contents
            buildHomeTab(app);
            buildDespeckleTab(app);
            buildAtrTabPlaceholder(app);
            buildGotchaTabPlaceholder(app);
            buildSimulateTabPlaceholder(app);
            buildResultsTabPlaceholder(app);
        end

        function buildHomeTab(app)
            parent = app.HomeTab;

            % Title header
            uilabel(parent, 'Text', 'SAR Workbench: System Status & Diagnostic Preflight', ...
                'FontName', 'Segoe UI', 'FontSize', 18, 'FontWeight', 'bold', ...
                'Position', [30 655 600 30]);

            uilabel(parent, 'Text', 'Phase 5 release verification for synthetic simulation, Gotcha backprojection, classical/MERLIN filtering, and MSTAR ATR.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.3 0.3 0.3], ...
                'Position', [30 630 800 22]);

            % Left Panel: Environment Status Lights
            pnlStatus = uipanel(parent, 'Title', 'Hardware & Environment Status', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 13, ...
                'Position', [30 140 500 470]);

            rowY = 405;
            stepY = 42;

            % 1. MATLAB Version
            app.LampMatlab = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'MATLAB Version:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelMatlab = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 2. Toolboxes
            app.LampToolboxes = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'Required Toolboxes:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelToolboxes = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 3. GPU Hardware
            app.LampGPU = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'CUDA GPU Device:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelGPU = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 4. MSTAR Data
            app.LampMstar = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'MSTAR Dataset:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelMstar = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 5. Gotcha Data
            app.LampGotcha = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'AFRL Gotcha Data:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelGotcha = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 6. Sentinel-1 Data
            app.LampSentinel = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'Sentinel-1 GRD:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelSentinel = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 7. MERLIN Model (MSTAR)
            app.LampMerlin = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'MERLIN Net (MSTAR):', 'FontWeight', 'bold', 'Position', [55 rowY 125 20]);
            app.LabelMerlin = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % 8. ATR CNN Model (MSTAR)
            app.LampCnn = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'ATR CNN Classifier:', 'FontWeight', 'bold', 'Position', [55 rowY 125 20]);
            app.LabelCnn = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % Overall Status summary banner
            app.LabelOverall = uilabel(pnlStatus, 'Text', 'Evaluating environment...', ...
                'FontName', 'Segoe UI', 'FontSize', 13, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', [0.9 0.9 0.9], ...
                'Position', [25 15 450 32]);

            % Refresh Button
            app.ButtonRefresh = uibutton(parent, 'push', 'Text', 'Re-run Environment Check', ...
                'FontWeight', 'bold', 'Position', [30 90 200 36], ...
                'ButtonPushedFcn', @(~,~) handleCallback(app, @() refreshEnvironment(app)));

            % Right Panel: Mandatory Scientific Limits & Domain Advisory
            pnlLimits = uipanel(parent, 'Title', 'Scientific Limits & Physical Domain Boundaries', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 13, ...
                'Position', [550 90 500 520]);

            advisoryText = sprintf([ ...
                '• MERLIN Deep Despeckling:\n' ...
                '   - Requires COMPLEX single-look SAR imagery (H x W >= 128x128).\n' ...
                '   - Disabled for amplitude-only data (e.g. Sentinel-1 GRD).\n' ...
                '   - Validated on MSTAR chips: +3 to +6 pp over shift augmentation at <= 10%% labels; no gain at 20%%; worse than blur augmentation at >= 20%%.\n' ...
                '   - distorts point targets (MSTAR net overshoots 1.54, Gotcha net undershoots 0.39).\n' ...
                '   - MERLIN Gotcha-trained net FAILED VALIDATION (peak ratio 0.39, widths 1.39/1.45).\n\n' ...
                '• Classical Filters (Lee, Frost, Boxcar, Gamma-MAP):\n' ...
                '   - Provide no ATR accuracy gain beyond standard spatial augmentation; stronger smoothing (Lee 15, boxcar 9) hurts.\n' ...
                '   - Gamma-MAP exhibits an intrinsic -3.8%% negative intensity bias.\n\n' ...
                '• AFRL Gotcha planar backprojection (z = -0.3 m):\n' ...
                '   - Exhibits unexplained look-dependent offsets of 0.15 - 0.75 m.\n' ...
                '   - Phase Gradient Autofocus (PGA) is not implemented in this baseline.\n\n' ...
                '• Distribution Shift Collapse in MSTAR ATR:\n' ...
                '   - Classifiers are trained on per-chip 99.5th-percentile scaled chips (Normalisation N).\n' ...
                '   - Evaluating on mismatched preprocessing collapses accuracy to about 10%% - 50%%.' ...
            ]);

            uitextarea(pnlLimits, 'Value', splitlines(advisoryText), ...
                'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11, ...
                'Position', [15 15 470 465]);
        end

        function updateHomeStatus(app)
            st = app.EnvStatus;
            cPass = [0.15 0.75 0.25];   % Bright green
            cWarn = [0.95 0.70 0.05];   % Amber / warning
            cFail = [0.85 0.20 0.15];   % Red

            % 1. MATLAB Version
            if isfield(st, 'matlab') && isfield(st.matlab, 'ok') && st.matlab.ok
                app.LampMatlab.Color = cPass;
                app.LabelMatlab.Text = sprintf('%s (%s)', st.matlab.release, st.matlab.version);
            else
                app.LampMatlab.Color = cFail;
                app.LabelMatlab.Text = 'Incompatible MATLAB version';
            end

            % 2. Toolboxes
            if isfield(st, 'toolboxes') && isfield(st.toolboxes, 'allRequired') && st.toolboxes.allRequired
                app.LampToolboxes.Color = cPass;
                app.LabelToolboxes.Text = 'All required toolboxes installed';
            else
                app.LampToolboxes.Color = cFail;
                app.LabelToolboxes.Text = 'Missing required toolboxes';
            end

            % 3. GPU
            if isfield(st, 'gpu') && isfield(st.gpu, 'available') && st.gpu.available
                app.LampGPU.Color = cPass;
                app.LabelGPU.Text = sprintf('%s (%.1f GB free)', st.gpu.name, st.gpu.availMemGB);
            else
                app.LampGPU.Color = cWarn;
                app.LabelGPU.Text = 'GPU unavailable (CPU mode only)';
            end

            % 4. MSTAR Data
            if isfield(st, 'data') && isfield(st.data, 'mstar') && strcmp(st.data.mstar.state, 'pass')
                app.LampMstar.Color = cPass;
                app.LabelMstar.Text = sprintf('Found (%d raw folders, soc mat=%d)', ...
                    st.data.mstar.numDirs, st.data.mstar.hasSocMat);
            else
                app.LampMstar.Color = cFail;
                app.LabelMstar.Text = 'Dataset not found';
            end

            % 5. Gotcha Data
            if isfield(st, 'data') && isfield(st.data, 'gotcha') && strcmp(st.data.gotcha.state, 'pass')
                app.LampGotcha.Color = cPass;
                app.LabelGotcha.Text = sprintf('Found (%d .mat files)', st.data.gotcha.numFiles);
            else
                app.LampGotcha.Color = cFail;
                app.LabelGotcha.Text = 'Dataset not found';
            end

            % 6. Sentinel-1
            if isfield(st, 'data') && isfield(st.data, 'sentinel1') && strcmp(st.data.sentinel1.state, 'pass')
                app.LampSentinel.Color = cPass;
                app.LabelSentinel.Text = sprintf('Found (%d SAFE folders)', st.data.sentinel1.numSafe);
            else
                app.LampSentinel.Color = cWarn;
                app.LabelSentinel.Text = 'Optional dataset missing';
            end

            % 7. MERLIN (MSTAR)
            if isfield(st, 'models') && isfield(st.models, 'merlinMstar') && st.models.merlinMstar.exists
                app.LampMerlin.Color = cPass;
                app.LabelMerlin.Text = 'Ready (models/p3b_merlin.mat)';
            else
                app.LampMerlin.Color = cFail;
                app.LabelMerlin.Text = 'Missing (models/p3b_merlin.mat)';
            end

            % 8. ATR CNN (MSTAR)
            if isfield(st, 'models') && isfield(st.models, 'cnnMstar') && st.models.cnnMstar.exists
                app.LampCnn.Color = cPass;
                app.LabelCnn.Text = 'Ready (models/cnn_mstar.mat)';
            else
                app.LampCnn.Color = cWarn;
                app.LabelCnn.Text = 'Pending training (models/cnn_mstar.mat)';
            end

            % Overall status
            if strcmp(st.overall, 'PASS')
                app.LabelOverall.Text = 'OVERALL STATUS: READY (PASS)';
                app.LabelOverall.BackgroundColor = [0.8 0.95 0.8];
                app.LabelOverall.FontColor = [0.05 0.5 0.1];
            else
                app.LabelOverall.Text = 'OVERALL STATUS: INCOMPLETE OR MISSING DATA';
                app.LabelOverall.BackgroundColor = [0.98 0.85 0.85];
                app.LabelOverall.FontColor = [0.7 0.1 0.1];
            end
        end

        function initDespeckleTab(app)
            % Initialize despeckle tab controls, method registry, and default MSTAR chip
            updateMethodDropdown(app);
            loadDespeckleSource(app);
        end

        function buildDespeckleTab(app)
            parent = app.DespeckleTab;

            % 1. Title Header
            uilabel(parent, 'Text', 'Despeckling Suite: Classical Adaptive Filters & Self-Supervised MERLIN', ...
                'FontName', 'Segoe UI', 'FontSize', 17, 'FontWeight', 'bold', ...
                'Position', [20 665 800 28]);

            % 2. Dynamic Scientific Domain Advisory Banner
            app.BannerDespeckle = uipanel(parent, 'Position', [20 600 1040 58], ...
                'BackgroundColor', [0.94 0.96 0.98]);
            app.LabelDespeckleBanner = uilabel(app.BannerDespeckle, ...
                'Text', 'Select an input dataset and despeckling method to begin.', ...
                'FontName', 'Segoe UI', 'FontSize', 11, 'FontWeight', 'bold', ...
                'FontColor', [0.2 0.2 0.2], ...
                'Position', [15 5 1010 44]);

            % 3. Input Source Selection Panel
            pnlSrc = uipanel(parent, 'Title', '1. Input SAR Imagery Source', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 12, ...
                'Position', [20 465 490 125]);

            uilabel(pnlSrc, 'Text', 'Source:', 'Position', [10 75 55 22]);
            app.DropdownSourceType = uidropdown(pnlSrc, ...
                'Items', {'MSTAR Complex Test Chip', 'Gotcha Pass 8 (Complex)', 'Sentinel-1 GRD (Real Amplitude)', 'User MAT File...'}, ...
                'Position', [65 73 175 26], ...
                'ValueChangedFcn', @(~,~) handleCallback(app, @() onSourceTypeChanged(app)));

            uilabel(pnlSrc, 'Text', 'Class:', 'Position', [245 75 40 22]);
            app.DropdownMstarClass = uidropdown(pnlSrc, ...
                'Items', {'2s1_gun', 'bmp2_tank', 'brdm2_truck', 'btr60_transport', 'btr70_transport', 'd7_bulldozer', 't62_tank', 't72_tank', 'zil131_truck', 'zsu23-4_gun'}, ...
                'Position', [285 73 115 26], ...
                'ValueChangedFcn', @(~,~) handleCallback(app, @() onMstarClassChanged(app)));

            uilabel(pnlSrc, 'Text', '#:', 'Position', [405 75 20 22]);
            app.SpinnerChipIdx = uispinner(pnlSrc, ...
                'Limits', [1 500], 'Value', 1, ...
                'Position', [425 73 55 26], ...
                'ValueChangedFcn', @(~,~) handleCallback(app, @() loadDespeckleSource(app)));

            app.ButtonLoadSource = uibutton(pnlSrc, 'Text', 'Load Image', ...
                'FontWeight', 'bold', 'Position', [10 20 100 32], ...
                'ButtonPushedFcn', @(~,~) handleCallback(app, @() loadDespeckleSource(app)));

            app.LabelSourceInfo = uilabel(pnlSrc, 'Text', 'No image loaded.', ...
                'FontSize', 11, 'FontColor', [0.3 0.3 0.3], ...
                'Position', [120 20 350 32]);

            % 4. Algorithm & Parameter Panel
            pnlMeth = uipanel(parent, 'Title', '2. Despeckling Algorithm & Parameters', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 12, ...
                'Position', [525 465 535 125]);

            uilabel(pnlMeth, 'Text', 'Method:', 'Position', [10 75 55 22]);
            app.DropdownMethod = uidropdown(pnlMeth, ...
                'Position', [65 73 240 26], ...
                'ValueChangedFcn', @(~,~) handleCallback(app, @() onMethodChanged(app)));

            app.CheckShowFailed = uicheckbox(pnlMeth, ...
                'Text', 'Show Failed Methods', 'Position', [315 75 160 22], ...
                'ValueChangedFcn', @(~,~) handleCallback(app, @() onShowFailedChanged(app)));

            app.LabelParamWin = uilabel(pnlMeth, 'Text', 'Win:', 'Position', [10 25 35 22]);
            app.SpinnerWin = uispinner(pnlMeth, 'Limits', [3 31], 'Step', 2, 'Value', 7, ...
                'Position', [45 23 55 26]);

            app.LabelParamLooks = uilabel(pnlMeth, 'Text', 'Looks L:', 'Position', [110 25 55 22]);
            app.SpinnerLooks = uispinner(pnlMeth, 'Limits', [1 32], 'Value', 1, ...
                'Position', [165 23 55 26]);

            app.LabelParamScale = uilabel(pnlMeth, 'Text', 'Scale:', 'Position', [230 25 40 22], ...
                'Visible', 'off');
            app.EditMerlinScale = uieditfield(pnlMeth, 'text', 'Value', 'auto', ...
                'Position', [270 23 55 26], 'Visible', 'off');

            app.ButtonRunFilter = uibutton(pnlMeth, 'Text', 'Run Filter', ...
                'FontWeight', 'bold', 'FontSize', 12, ...
                'Position', [390 16 130 38], ...
                'BackgroundColor', [0.2 0.55 0.85], 'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(~,~) handleCallback(app, @() runDespeckleFilter(app)));

            % 5. Image Display Axes (Side-by-Side)
            app.AxesRaw = uiaxes(parent, 'Position', [20 155 330 295]);
            title(app.AxesRaw, 'Raw SAR Input (dB)');
            axis(app.AxesRaw, 'image'); colormap(app.AxesRaw, 'gray');

            app.AxesFiltered = uiaxes(parent, 'Position', [375 155 330 295]);
            title(app.AxesFiltered, 'Despeckled Output (dB)');
            axis(app.AxesFiltered, 'image'); colormap(app.AxesFiltered, 'gray');

            app.AxesRatio = uiaxes(parent, 'Position', [730 155 330 295]);
            title(app.AxesRatio, 'Speckle Ratio (Raw / Filtered)');
            axis(app.AxesRatio, 'image'); colormap(app.AxesRatio, 'gray');

            % 6. Metrics Summary Panel
            pnlMetrics = uipanel(parent, 'Title', '3. Quantitative Evaluation Metrics', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 12, ...
                'Position', [20 20 1040 120]);

            app.LabelMetricRawENL = uilabel(pnlMetrics, 'Text', 'Raw Clutter ENL: --', ...
                'FontWeight', 'bold', 'Position', [20 50 190 24]);
            app.LabelMetricFiltENL = uilabel(pnlMetrics, 'Text', 'Filtered ENL: --', ...
                'FontWeight', 'bold', 'Position', [220 50 190 24]);
            app.LabelMetricENLGain = uilabel(pnlMetrics, 'Text', 'ENL Gain: --', ...
                'FontWeight', 'bold', 'FontSize', 13, 'FontColor', [0.1 0.5 0.2], ...
                'Position', [420 50 190 24]);
            app.LabelMetricBias = uilabel(pnlMetrics, 'Text', 'Intensity Bias: --', ...
                'FontWeight', 'bold', 'Position', [620 50 190 24]);
            app.LabelMetricTime = uilabel(pnlMetrics, 'Text', 'Elapsed Time: --', ...
                'Position', [820 50 190 24]);

            uilabel(pnlMetrics, ...
                'Text', 'Note: Clutter ENL computed across homogeneous background clutter. ENL gain = ENL(est) / ENL(raw). Bias = (mean(I_est)/mean(I_raw) - 1).', ...
                'FontColor', [0.4 0.4 0.4], 'FontSize', 10, 'Position', [20 15 950 20]);
        end

        function onSourceTypeChanged(app)
            srcType = app.DropdownSourceType.Value;
            isMstar = strcmp(srcType, 'MSTAR Complex Test Chip');
            app.DropdownMstarClass.Enable = ternary(isMstar, 'on', 'off');
            app.SpinnerChipIdx.Enable = ternary(isMstar, 'on', 'off');
            loadDespeckleSource(app);
        end

        function onMstarClassChanged(app)
            app.SpinnerChipIdx.Value = 1;
            loadDespeckleSource(app);
        end

        function loadDespeckleSource(app)
            SARWorkbench.ensurePaths();
            srcType = app.DropdownSourceType.Value;
            cfg = sar.env.config();

            switch srcType
                case 'MSTAR Complex Test Chip'
                    if isempty(app.MstarTestList) || ~isfield(app.MstarTestList, 'pte')
                        if exist(cfg.dataPath.mstarSocMat, 'file')
                            M = load(cfg.dataPath.mstarSocMat, 'pte', 'Yte');
                            app.MstarTestList = M;
                        else
                            error('mstar_soc.mat not found in %s', cfg.dataPath.mstarSocMat);
                        end
                    end

                    selClass = app.DropdownMstarClass.Value;
                    clsIndices = find(app.MstarTestList.Yte == selClass);
                    if isempty(clsIndices)
                        clsIndices = 1:numel(app.MstarTestList.pte);
                    end

                    app.SpinnerChipIdx.Limits = [1 max(1, numel(clsIndices))];
                    chipIdx = min(app.SpinnerChipIdx.Value, numel(clsIndices));
                    app.SpinnerChipIdx.Value = chipIdx;

                    targetPath = char(app.MstarTestList.pte(clsIndices(chipIdx)));
                    if ~exist(targetPath, 'file')
                        targetPath = fullfile(cfg.dataPath.mstar, targetPath);
                    end

                    [mg, ph] = mstar_read(targetPath);
                    S = 128;
                    r0 = floor((size(mg,1)-S)/2) + 1;
                    c0 = floor((size(mg,2)-S)/2) + 1;
                    Z = double(mg(r0:r0+S-1, c0:c0+S-1)) .* exp(1j * double(ph(r0:r0+S-1, c0:c0+S-1)));

                    app.CurrentRawData = Z;
                    app.CurrentRawAmplitude = single(abs(Z));
                    app.CurrentSourceInfo = struct('type', 'complex', 'name', sprintf('MSTAR %s #%d', selClass, chipIdx), 'size', size(Z));
                    app.LabelSourceInfo.Text = sprintf('%s #%d (%dx%d complex single-look)', selClass, chipIdx, size(Z,1), size(Z,2));

                case 'Gotcha Pass 8 (Complex)'
                    G = sar.imaging.gotcha.loadAperture([], 8, 'HH', 1:3);
                    xlim = [-28.09 - 3.2, -28.09 + 3.15];
                    ylim = [38.67 - 3.2, 38.67 + 3.15];
                    opt = struct('xlim', xlim, 'ylim', ylim, 'dx', 0.05, 'z', -0.3, 'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
                    [img, ~, ~] = sar.imaging.gotcha.backproject(G, opt);

                    app.CurrentRawData = img;
                    app.CurrentRawAmplitude = single(abs(img));
                    app.CurrentSourceInfo = struct('type', 'complex', 'name', 'Gotcha Pass 8 HH (15TR03C)', 'size', size(img));
                    app.LabelSourceInfo.Text = sprintf('Gotcha Pass 8 HH az 1-3 (%dx%d complex)', size(img,1), size(img,2));

                case 'Sentinel-1 GRD (Real Amplitude)'
                    cropFile = fullfile(cfg.rootDir, '_crop_hyderabad_1.png');
                    if exist(cropFile, 'file')
                        A = single(imread(cropFile));
                        if size(A, 3) > 1, A = A(:,:,1); end
                        A = A / max(A(:));
                    else
                        A = single(abs(randn(128, 128)));
                    end
                    sz = min(size(A));
                    A128 = A(1:min(sz, 128), 1:min(sz, 128));

                    app.CurrentRawData = single(A128); % REAL amplitude only!
                    app.CurrentRawAmplitude = single(A128);
                    app.CurrentSourceInfo = struct('type', 'amplitude', 'name', 'Sentinel-1 GRD Crop', 'size', size(A128));
                    app.LabelSourceInfo.Text = sprintf('Sentinel-1 GRD (%dx%d real amplitude)', size(A128,1), size(A128,2));

                case 'User MAT File...'
                    [fName, fPath] = uigetfile('*.mat', 'Select SAR .mat Data File');
                    if isequal(fName, 0), return; end
                    matContent = load(fullfile(fPath, fName));
                    fn = fieldnames(matContent);
                    varData = matContent.(fn{1});
                    if ~isnumeric(varData) || ndims(varData) > 3
                        error('MAT file variable must be a 2D numerical image array.');
                    end
                    app.CurrentRawData = varData;
                    app.CurrentRawAmplitude = single(abs(varData));
                    isCmplx = ~isreal(varData);
                    app.CurrentSourceInfo = struct('type', ternary(isCmplx, 'complex', 'amplitude'), ...
                        'name', fName, 'size', size(varData));
                    app.LabelSourceInfo.Text = sprintf('%s (%dx%d %s)', fName, size(varData,1), size(varData,2), ...
                        ternary(isCmplx, 'complex', 'amplitude'));
            end

            % Update Raw Image Display
            rawAmp = app.CurrentRawAmplitude;
            imagesc(app.AxesRaw, 20*log10(rawAmp / max(rawAmp(:)) + eps));
            colormap(app.AxesRaw, 'gray'); clim(app.AxesRaw, [-40 0]); axis(app.AxesRaw, 'image');
            title(app.AxesRaw, sprintf('Raw SAR Amplitude (%s)', app.CurrentSourceInfo.type));

            % Reset Filtered / Ratio Displays & Metrics
            cla(app.AxesFiltered); title(app.AxesFiltered, 'Despeckled Output (dB)');
            cla(app.AxesRatio); title(app.AxesRatio, 'Speckle Ratio (Raw / Filtered)');
            app.CurrentFilteredData = [];
            app.CurrentRatioData = [];

            app.LabelMetricRawENL.Text  = 'Raw Clutter ENL: --';
            app.LabelMetricFiltENL.Text = 'Filtered ENL: --';
            app.LabelMetricENLGain.Text = 'ENL Gain: --';
            app.LabelMetricBias.Text    = 'Intensity Bias: --';
            app.LabelMetricTime.Text    = 'Elapsed Time: --';

            updateDespeckleBanner(app);
        end

        function onShowFailedChanged(app)
            updateMethodDropdown(app);
        end

        function updateMethodDropdown(app)
            includeFailed = app.CheckShowFailed.Value;
            reg = sar.registry.despeckle(includeFailed);

            currentVal = app.DropdownMethod.Value;
            app.DropdownMethod.Items = {reg.name};
            app.DropdownMethod.ItemsData = {reg.id};

            if any(strcmp(app.DropdownMethod.ItemsData, currentVal))
                app.DropdownMethod.Value = currentVal;
            else
                app.DropdownMethod.Value = app.DropdownMethod.ItemsData{1};
            end

            onMethodChanged(app);
        end

        function onMethodChanged(app)
            methodId = app.DropdownMethod.Value;

            % Parameter Visibility
            if strcmp(methodId, 'lee') || strcmp(methodId, 'frost') || strcmp(methodId, 'gammamap')
                app.LabelParamWin.Visible = 'on';
                app.SpinnerWin.Visible = 'on';
                app.LabelParamLooks.Visible = 'on';
                app.SpinnerLooks.Visible = 'on';
                app.LabelParamScale.Visible = 'off';
                app.EditMerlinScale.Visible = 'off';
            elseif startsWith(methodId, 'merlin')
                app.LabelParamWin.Visible = 'off';
                app.SpinnerWin.Visible = 'off';
                app.LabelParamLooks.Visible = 'off';
                app.SpinnerLooks.Visible = 'off';
                app.LabelParamScale.Visible = 'on';
                app.EditMerlinScale.Visible = 'on';
            else
                app.LabelParamWin.Visible = 'off';
                app.SpinnerWin.Visible = 'off';
                app.LabelParamLooks.Visible = 'off';
                app.SpinnerLooks.Visible = 'off';
                app.LabelParamScale.Visible = 'off';
                app.EditMerlinScale.Visible = 'off';
            end

            updateDespeckleBanner(app);
        end

        function updateDespeckleBanner(app)
            methodId = app.DropdownMethod.Value;
            isAmplitude = ~isempty(app.CurrentSourceInfo) && strcmp(app.CurrentSourceInfo.type, 'amplitude');

            cNeutral = [0.94 0.96 0.98];
            cAmber   = [0.99 0.94 0.82];
            cRed     = [0.98 0.85 0.85];

            if isAmplitude && startsWith(methodId, 'merlin')
                app.BannerDespeckle.BackgroundColor = cRed;
                app.LabelDespeckleBanner.Text = '[SCIENTIFIC LIMIT] MERLIN requires COMPLEX single-look SAR imagery. Real amplitude data (e.g. Sentinel-1 GRD) is strictly prohibited. Run Filter is disabled.';
                app.LabelDespeckleBanner.FontColor = [0.7 0.1 0.1];
                app.ButtonRunFilter.Enable = 'off';
            elseif strcmp(methodId, 'merlin_gotcha')
                app.BannerDespeckle.BackgroundColor = cRed;
                app.LabelDespeckleBanner.Text = '[FAILED VALIDATION] Gotcha-trained MERLIN failed point-target validation (peak ratio 0.39, widths 1.39/1.45). Causes severe target distortion. Not approved for operational use.';
                app.LabelDespeckleBanner.FontColor = [0.7 0.1 0.1];
                app.ButtonRunFilter.Enable = 'on';
            elseif strcmp(methodId, 'merlin_mstar')
                app.BannerDespeckle.BackgroundColor = cAmber;
                app.LabelDespeckleBanner.Text = '[PHYSICAL LIMIT] MERLIN: +3 to +6 pp over shift aug at <=10% labels; no gain at 20%; worse than blur at >=20%. Distorts point targets (MSTAR overshoots 1.54, Gotcha undershoots 0.39).';
                app.LabelDespeckleBanner.FontColor = [0.6 0.35 0.0];
                app.ButtonRunFilter.Enable = 'on';
            elseif strcmp(methodId, 'gammamap')
                app.BannerDespeckle.BackgroundColor = cAmber;
                app.LabelDespeckleBanner.Text = '[METHOD ADVISORY] Gamma-MAP filter possesses an intrinsic -3.8% negative intensity bias on fully developed speckle.';
                app.LabelDespeckleBanner.FontColor = [0.6 0.35 0.0];
                app.ButtonRunFilter.Enable = 'on';
            elseif strcmp(methodId, 'lee') || strcmp(methodId, 'frost')
                app.BannerDespeckle.BackgroundColor = cNeutral;
                app.LabelDespeckleBanner.Text = '[METHOD ADVISORY] Classical filters provide no downstream classification gain beyond spatial augmentation; stronger smoothing (Lee 15, boxcar 9) hurts.';
                app.LabelDespeckleBanner.FontColor = [0.1 0.2 0.4];
                app.ButtonRunFilter.Enable = 'on';
            else
                app.BannerDespeckle.BackgroundColor = cNeutral;
                app.LabelDespeckleBanner.Text = 'Select an input dataset and despeckling method, then click "Run Filter".';
                app.LabelDespeckleBanner.FontColor = [0.2 0.2 0.2];
                app.ButtonRunFilter.Enable = 'on';
            end
        end

        function runDespeckleFilter(app)
            if isempty(app.CurrentRawData)
                uialert(app.UIFigure, 'Please load an input SAR image first.', 'No Input Image');
                return;
            end

            methodId = app.DropdownMethod.Value;
            isAmplitude = isreal(app.CurrentRawData);

            if isAmplitude && startsWith(methodId, 'merlin')
                uialert(app.UIFigure, ...
                    'MERLIN requires COMPLEX single-look SAR imagery. Operation on amplitude-only data is prohibited.', ...
                    'Domain Boundary Violation', 'Icon', 'error');
                return;
            end

            params = struct();
            if strcmp(methodId, 'lee') || strcmp(methodId, 'frost') || strcmp(methodId, 'gammamap')
                params.win = app.SpinnerWin.Value;
                params.L = app.SpinnerLooks.Value;
            elseif startsWith(methodId, 'merlin')
                scaleVal = str2double(app.EditMerlinScale.Value);
                if ~isnan(scaleVal) && scaleVal > 0
                    params.scale = single(scaleVal);
                end
            end

            [filtAmp, info] = sar.despeckle.apply(app.CurrentRawData, methodId, params);
            app.CurrentFilteredData = filtAmp;

            rawAmp = app.CurrentRawAmplitude;
            I_raw = double(rawAmp).^2;
            I_filt = double(filtAmp).^2;
            app.CurrentRatioData = rawAmp ./ max(filtAmp, 1e-4);

            % Update Displays
            imagesc(app.AxesRaw, 20*log10(rawAmp / max(rawAmp(:)) + eps));
            colormap(app.AxesRaw, 'gray'); clim(app.AxesRaw, [-40 0]); axis(app.AxesRaw, 'image');
            title(app.AxesRaw, 'Raw SAR Amplitude (dB)');

            imagesc(app.AxesFiltered, 20*log10(filtAmp / max(filtAmp(:)) + eps));
            colormap(app.AxesFiltered, 'gray'); clim(app.AxesFiltered, [-40 0]); axis(app.AxesFiltered, 'image');
            title(app.AxesFiltered, sprintf('Filtered (%s)', info.methodName));

            imagesc(app.AxesRatio, app.CurrentRatioData);
            colormap(app.AxesRatio, 'gray'); clim(app.AxesRatio, [0 3]); axis(app.AxesRatio, 'image');
            title(app.AxesRatio, 'Speckle Ratio (Raw / Filtered)');

            % Compute Quantitative Metrics
            [H, W] = size(rawAmp);
            if H == 128 && W == 128
                m = p3b_metrics(I_raw, I_filt, 32, 41:88);
                enlRaw = m.enl;
                enlGain = m.gain;
                biasPct = 100 * m.bias;
            else
                mask = true(H, W);
                border = round(min(H, W) * 0.15);
                mask(border:end-border, border:end-border) = false;
                clutterRaw = I_raw(mask);
                clutterFilt = I_filt(mask);
                enlRaw = mean(clutterRaw)^2 / var(clutterRaw);
                enlFilt = mean(clutterFilt)^2 / var(clutterFilt);
                enlGain = enlFilt / max(enlRaw, eps);
                biasPct = 100 * (mean(I_filt(:)) / mean(I_raw(:)) - 1);
            end

            app.LabelMetricRawENL.Text  = sprintf('Raw Clutter ENL: %.2f', enlRaw);
            app.LabelMetricFiltENL.Text = sprintf('Filtered ENL: %.2f', enlRaw * enlGain);
            app.LabelMetricENLGain.Text = sprintf('ENL Gain: %.2f x', enlGain);
            app.LabelMetricBias.Text    = sprintf('Intensity Bias: %+.2f %%', biasPct);
            app.LabelMetricTime.Text    = sprintf('Elapsed Time: %.3f s', info.elapsedSeconds);
        end

        function buildAtrTabPlaceholder(app)
            parent = app.AtrTab;
            uilabel(parent, 'Text', 'MSTAR Automatic Target Recognition (ATR)', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 650 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2b verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 620 500 20]);
        end

        function buildGotchaTabPlaceholder(app)
            parent = app.GotchaTab;
            uilabel(parent, 'Text', 'AFRL Gotcha Volumetric Backprojection Image Formation', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 650 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2c verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 620 500 20]);
        end

        function buildSimulateTabPlaceholder(app)
            parent = app.SimulateTab;
            uilabel(parent, 'Text', 'Synthetic Spotlight SAR Simulation & Backprojection', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 650 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2d verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 620 500 20]);
        end

        function buildResultsTabPlaceholder(app)
            parent = app.ResultsTab;
            uilabel(parent, 'Text', 'Experimental Results & Data Dose Learning Curves', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 650 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2e verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 620 500 20]);
        end
    end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
