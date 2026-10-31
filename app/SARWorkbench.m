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
        LampModels          matlab.ui.control.Lamp
        LabelModels         matlab.ui.control.Label
        LabelOverall        matlab.ui.control.Label
    end

    methods
        function app = SARWorkbench()
            % Constructor: Build UI and refresh environment status
            createComponents(app);
            refreshEnvironment(app);
            if nargout == 0
                % Do not assign if called without LHS
            end
        end

        function refreshEnvironment(app)
            % Query system environment via adapter
            app.EnvStatus = sar.env.check();
            updateHomeStatus(app);
        end

        function delete(app)
            % Destructor: close figure safely
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            % Main Figure Window
            app.UIFigure = uifigure('Name', 'SAR Workbench - Phase 5', ...
                'Position', [100 100 1100 720], ...
                'Color', [0.95 0.95 0.96]);

            % Top tab group
            app.TabGroup = uitabgroup(app.UIFigure, ...
                'Position', [10 10 1080 700]);

            % Create Tabs
            app.HomeTab      = uitab(app.TabGroup, 'Title', ' Home & Environment ');
            app.DespeckleTab = uitab(app.TabGroup, 'Title', ' Despeckling ');
            app.AtrTab       = uitab(app.TabGroup, 'Title', ' MSTAR ATR ');
            app.GotchaTab    = uitab(app.TabGroup, 'Title', ' Gotcha Backprojection ');
            app.SimulateTab  = uitab(app.TabGroup, 'Title', ' Simulation ');
            app.ResultsTab   = uitab(app.TabGroup, 'Title', ' Research Results ');

            % Populate Tab Contents
            buildHomeTab(app);
            buildDespeckleTabPlaceholder(app);
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
                'Position', [30 625 600 30]);

            uilabel(parent, 'Text', 'Phase 5 release verification for synthetic simulation, Gotcha backprojection, classical/MERLIN filtering, and MSTAR ATR.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.3 0.3 0.3], ...
                'Position', [30 600 800 22]);

            % Left Panel: Environment Status Lights
            pnlStatus = uipanel(parent, 'Title', 'Hardware & Environment Status', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 13, ...
                'Position', [30 180 500 400]);

            rowY = 320;
            stepY = 44;

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

            % 7. Trained Models
            app.LampModels = uilamp(pnlStatus, 'Position', [25 rowY 20 20], 'Color', [0.7 0.7 0.7]);
            uilabel(pnlStatus, 'Text', 'Trained Models:', 'FontWeight', 'bold', 'Position', [55 rowY 120 20]);
            app.LabelModels = uilabel(pnlStatus, 'Text', 'Checking...', 'Position', [180 rowY 300 20]);
            rowY = rowY - stepY;

            % Overall Status summary banner
            app.LabelOverall = uilabel(pnlStatus, 'Text', 'Evaluating environment...', ...
                'FontName', 'Segoe UI', 'FontSize', 13, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', [0.9 0.9 0.9], ...
                'Position', [25 15 450 30]);

            % Refresh Button
            uibutton(parent, 'push', 'Text', 'Re-run Environment Check', ...
                'FontWeight', 'bold', 'Position', [30 130 200 36], ...
                'ButtonPushedFcn', @(~,~) refreshEnvironment(app));

            % Right Panel: Mandatory Scientific Limits & Domain Advisory
            pnlLimits = uipanel(parent, 'Title', 'Scientific Limits & Physical Domain Boundaries', ...
                'FontName', 'Segoe UI', 'FontWeight', 'bold', 'FontSize', 13, ...
                'Position', [550 130 500 450]);

            advisoryText = sprintf([ ...
                '• MERLIN Deep Despeckling:\n' ...
                '   - Requires COMPLEX single-look SAR imagery (H x W >= 128x128).\n' ...
                '   - Disabled for amplitude-only data (e.g. Sentinel-1 GRD).\n' ...
                '   - Validated on MSTAR chips: classification gain strictly at <= 10%% labels; no gain at >= 20%%.\n' ...
                '   - Does NOT preserve point targets on Gotcha (peak ratio ~1.54 MSTAR net, ~0.39 Gotcha net).\n\n' ...
                '• Classical Filters (Lee, Frost, Boxcar, Gamma-MAP):\n' ...
                '   - Provide no ATR accuracy gain beyond standard spatial augmentation.\n' ...
                '   - Gamma-MAP exhibits an intrinsic -3.8%% negative intensity bias.\n\n' ...
                '• AFRL Gotcha Volumetric Backprojection:\n' ...
                '   - Exhibits unexplained look-dependent offsets of 0.15 - 0.75 m.\n' ...
                '   - Phase Gradient Autofocus (PGA) is not implemented in this baseline.\n\n' ...
                '• Distribution Shift Collapse in MSTAR ATR:\n' ...
                '   - Classifiers are trained on per-chip 99.5th-percentile scaled chips (Normalisation N).\n' ...
                '   - Evaluating on mismatched preprocessing collapses accuracy to 15%% - 50%%.' ...
            ]);

            uitextarea(pnlLimits, 'Value', splitlines(advisoryText), ...
                'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11, ...
                'Position', [15 15 470 395]);
        end

        function updateHomeStatus(app)
            st = app.EnvStatus;
            cPass = [0.15 0.75 0.25];   % Bright green
            cWarn = [0.95 0.70 0.05];   % Yellow/amber
            cFail = [0.85 0.20 0.15];   % Red

            % MATLAB Version
            if isfield(st, 'matlab') && isfield(st.matlab, 'ok') && st.matlab.ok
                app.LampMatlab.Color = cPass;
                app.LabelMatlab.Text = sprintf('%s (%s)', st.matlab.release, st.matlab.version);
            else
                app.LampMatlab.Color = cFail;
                app.LabelMatlab.Text = 'Incompatible MATLAB version';
            end

            % Toolboxes
            if isfield(st, 'toolboxes') && isfield(st.toolboxes, 'allRequired') && st.toolboxes.allRequired
                app.LampToolboxes.Color = cPass;
                app.LabelToolboxes.Text = 'All required toolboxes installed';
            else
                app.LampToolboxes.Color = cFail;
                app.LabelToolboxes.Text = 'Missing required toolboxes';
            end

            % GPU
            if isfield(st, 'gpu') && isfield(st.gpu, 'available') && st.gpu.available
                app.LampGPU.Color = cPass;
                app.LabelGPU.Text = sprintf('%s (%.1f GB free)', st.gpu.name, st.gpu.availMemGB);
            else
                app.LampGPU.Color = cWarn;
                app.LabelGPU.Text = 'GPU unavailable (CPU mode only)';
            end

            % MSTAR Data
            if isfield(st, 'data') && isfield(st.data, 'mstar') && strcmp(st.data.mstar.state, 'pass')
                app.LampMstar.Color = cPass;
                app.LabelMstar.Text = sprintf('Found (%d raw folders, soc mat=%d)', ...
                    st.data.mstar.numDirs, st.data.mstar.hasSocMat);
            else
                app.LampMstar.Color = cFail;
                app.LabelMstar.Text = 'Dataset not found';
            end

            % Gotcha Data
            if isfield(st, 'data') && isfield(st.data, 'gotcha') && strcmp(st.data.gotcha.state, 'pass')
                app.LampGotcha.Color = cPass;
                app.LabelGotcha.Text = sprintf('Found (%d .mat files)', st.data.gotcha.numFiles);
            else
                app.LampGotcha.Color = cFail;
                app.LabelGotcha.Text = 'Dataset not found';
            end

            % Sentinel-1
            if isfield(st, 'data') && isfield(st.data, 'sentinel1') && strcmp(st.data.sentinel1.state, 'pass')
                app.LampSentinel.Color = cPass;
                app.LabelSentinel.Text = sprintf('Found (%d SAFE folders)', st.data.sentinel1.numSafe);
            else
                app.LampSentinel.Color = cWarn;
                app.LabelSentinel.Text = 'Optional dataset missing';
            end

            % Models
            if isfield(st, 'models') && isfield(st.models, 'merlinMstar') && st.models.merlinMstar.exists
                if st.models.cnnMstar.exists
                    app.LampModels.Color = cPass;
                    app.LabelModels.Text = 'MERLIN & ATR CNN ready';
                else
                    app.LampModels.Color = cWarn;
                    app.LabelModels.Text = 'MERLIN ready (ATR CNN pending G2b)';
                end
            else
                app.LampModels.Color = cFail;
                app.LabelModels.Text = 'Required models missing';
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

        function buildDespeckleTabPlaceholder(app)
            parent = app.DespeckleTab;
            uilabel(parent, 'Text', 'Despeckling Suite: Classical Filters & Self-Supervised MERLIN', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 630 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2a verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 600 500 20]);
        end

        function buildAtrTabPlaceholder(app)
            parent = app.AtrTab;
            uilabel(parent, 'Text', 'MSTAR Automatic Target Recognition (ATR)', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 630 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2b verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 600 500 20]);
        end

        function buildGotchaTabPlaceholder(app)
            parent = app.GotchaTab;
            uilabel(parent, 'Text', 'AFRL Gotcha Volumetric Backprojection Image Formation', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 630 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2c verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 600 500 20]);
        end

        function buildSimulateTabPlaceholder(app)
            parent = app.SimulateTab;
            uilabel(parent, 'Text', 'Synthetic Spotlight SAR Simulation & Backprojection', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 630 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2d verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 600 500 20]);
        end

        function buildResultsTabPlaceholder(app)
            parent = app.ResultsTab;
            uilabel(parent, 'Text', 'Experimental Results & Data Dose Learning Curves', ...
                'FontName', 'Segoe UI', 'FontSize', 16, 'FontWeight', 'bold', ...
                'Position', [30 630 650 30]);
            uilabel(parent, 'Text', 'Feature implementation scheduled for Gate G2e verification.', ...
                'FontName', 'Segoe UI', 'FontSize', 12, 'FontColor', [0.4 0.4 0.4], ...
                'Position', [30 600 500 20]);
        end
    end
end
