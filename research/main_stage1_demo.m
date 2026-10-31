%% main_stage1_demo.m
% SAR Workbench - Stage 1 orchestration script
% Run this section-by-section (use Ctrl+Enter / "Run Section" in MATLAB),
% NOT all at once. Each section is a council checkpoint - confirm it looks
% right before moving to the next.
% Ensure this script always runs relative to its own file location,
% regardless of MATLAB's current working directory
scriptDir = fileparts(mfilename('fullpath'));
addpath(scriptDir);
cd(scriptDir);
%% SECTION 0: Environment check

run('toolbox_check.m');

%% SECTION 1: Validate backprojection against a KNOWN synthetic target
% This is the non-negotiable gate. Single point target at scene center.
pha_sim = simulatePointTargetPhaseHistory([0 0]);
[img_sim, xVec, yVec] = backprojection2D(pha_sim, 20, 256);

figure('Name','Stage 1 Checkpoint: Single Point Target');
imagesc(xVec, yVec, abs(img_sim));
axis image; colormap gray; colorbar;
title('Expect ONE sharp point at (0,0). If not - STOP, debug before continuing.');
xlabel('X (m)'); ylabel('Y (m)');

fprintf('\n>>> CHECKPOINT: Does the figure show exactly one sharp bright\n');
fprintf('>>> point at the center? If yes, proceed. If no, do not continue\n');
fprintf('>>> to real data - debug backprojection2D.m first.\n\n');

%% SECTION 1b: Multi-target validation (slightly harder test)
pha_multi = simulatePointTargetPhaseHistory([0 0; 8 8; -8 -8; 8 -8]);
[img_multi, xVec2, yVec2] = backprojection2D(pha_multi, 20, 256);

figure('Name','Stage 1 Checkpoint: Multi-Point Target');
imagesc(xVec2, yVec2, abs(img_multi));
axis image; colormap gray; colorbar;
title('Expect FOUR sharp points at commanded positions, no ghosting.');

%% SECTION 2: MSTAR chip loading sanity check
% EDIT this path to point at one file you actually downloaded
mstarFile = 'PATH_TO_YOUR_MSTAR_FILE_HERE';  % e.g. an HB03333.015-style file
if exist(mstarFile, 'file')
    [magImg, phaseImg, hdr] = loadMSTARChip(mstarFile);
    figure('Name','MSTAR Chip Sanity Check');
    imagesc(magImg); colormap gray; axis image;
    title('Should resemble a recognizable vehicle silhouette, not noise.');
else
    fprintf('Set mstarFile to a real path before running Section 2.\n');
end

%% SECTION 3: Gotcha phase history - DIAGNOSTIC first
% EDIT this path to point at one .mat file from your Gotcha download
gotchaFile = 'PATH_TO_YOUR_GOTCHA_MAT_FILE_HERE';
if exist(gotchaFile, 'file')
    rawStruct = loadGotchaPhaseHistory(gotchaFile, true);  % verbose=true: prints fields
    fprintf('\n>>> Read the field list above, then edit the fieldMap section\n');
    fprintf('>>> inside loadGotchaPhaseHistory.m to match, before Section 4.\n\n');
else
    fprintf('Set gotchaFile to a real path before running Section 3.\n');
end

%% SECTION 4: Gotcha real-data backprojection (run AFTER fieldMap is fixed)
if exist(gotchaFile, 'file')
    pha_gotcha = loadGotchaPhaseHistory(gotchaFile, false);  % verbose=false: mapped mode
    [img_gotcha, xVecG, yVecG] = backprojection2D(pha_gotcha, 15, 512);

    figure('Name','Stage 1: Gotcha Real Data Reconstruction');
    imagesc(xVecG, yVecG, 20*log10(abs(img_gotcha)+eps));
    axis image; colormap gray; colorbar;
    title('Gotcha scene reconstruction (dB scale) - expect visible vehicle/calibration targets');
end
