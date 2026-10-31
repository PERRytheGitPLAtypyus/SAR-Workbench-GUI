%% RUN_P4B_STAGE1C  Does filtering add anything ON TOP of augmentation?  (the question a despeckler has to answer)
% Arms (10 % data, seeds 1-20, same subsets): E1_lee = shift augmentation on Lee-7 filtered chips, train and test filtered;
%       E1_box5 = the same with boxcar 5.  Compare with B1 (shift augmentation on raw chips), already run.
% Time: 40 runs x about 32 s = 20-25 min. Then run p4b_stats and read the last 'E1' rows.
clear; close all; clc;
cfg = p4b_config(); S = load(cfg.mat); frac = 0.1; tAll = tic;
for s = 1:20
    p4b_run_arm(S, p4b_arms('E1_lee'), frac, s, cfg);
    p4b_run_arm(S, p4b_arms('E1_box5'), frac, s, cfg);
end
fprintf('\nStage 1c done (%.0f min). Run p4b_stats and paste the whole output.\n', toc(tAll)/60);
