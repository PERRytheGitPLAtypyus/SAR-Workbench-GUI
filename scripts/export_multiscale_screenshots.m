% scripts/export_multiscale_screenshots.m
% Export high-fidelity GUI screenshots at 100%, 125%, and 150% display scaling
fprintf('==================== MULTI-SCALE SCREENSHOT EXPORT ====================\n');
fprintf('Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

cfg = sar.env.config();
docDir = fullfile(cfg.rootDir, 'docs');

app = SARWorkbench();
assert(~isempty(app) && isvalid(app.UIFigure), 'SARWorkbench must launch cleanly');

scales = [1.00, 1.25, 1.50];
scalePct = [100, 125, 150];
baseW = 1100;
baseH = 750;

tabs = {
    'despeckle_tab', app.DespeckleTab;
    'atr_tab',       app.AtrTab;
    'gotcha_tab',    app.GotchaTab
};

for s = 1:numel(scales)
    sc = scales(s);
    pct = scalePct(s);
    w = round(baseW * sc);
    h = round(baseH * sc);
    
    fprintf('\nApplying scale %d%% [%dx%d px]...\n', pct, w, h);
    app.UIFigure.Position = [50 50 w h];
    drawnow;
    
    for t = 1:size(tabs, 1)
        name = tabs{t, 1};
        tabObj = tabs{t, 2};
        
        app.TabGroup.SelectedTab = tabObj;
        drawnow;
        pause(0.5); % Allow graphics pipeline to stabilize
        
        outFile = fullfile(docDir, sprintf('%s_%d.png', name, pct));
        exportapp(app.UIFigure, outFile);
        assert(exist(outFile, 'file') ~= 0, 'Screenshot file must exist');
        fprintf('   Exported: %s\n', outFile);
    end
end

delete(app);
fprintf('\n>>> MULTI-SCALE SCREENSHOT EXPORT COMPLETE <<<\n');
fprintf('========================================================================\n');
