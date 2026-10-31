%% RUN_P4B_STAGE1A  Phase 4b stage 1, part a: all arms that need no selection, 10 % data, seeds 1-20.
% Arms: A0 raw, A1 boxcar 7, C1 random-blur augmentation, B1 shift aug, B2 shift + speckle-noise aug, C3 mixed raw+boxcar 7,
%       A3 Lee 7, A3 Frost 7, A2 boxcar 5 and 9. Every run is saved (p4b_runs/), so a stopped session just resumes on rerun.
% Time: about 200 runs x 30-40 s = roughly 2-2.5 h. Run it in chunks if you like: edit 'seeds' (e.g. 1:10 first).
clear; close all; clc;
cfg = p4b_config(); S = load(cfg.mat);
seeds = 1:20; frac = 0.1;
keys = {'A0', 'A1', 'C1', 'B1', 'B2', 'C3', 'A3_lee', 'A3_frost', 'A2_w5', 'A2_w9'};
tAll = tic;
for s = seeds
    for k = 1:numel(keys)
        p4b_run_arm(S, p4b_arms(keys{k}), frac, s, cfg);
    end
    fprintf('== seed %d complete for all arms, %.0f min elapsed ==\n', s, toc(tAll)/60);
end
fprintf('\nStage 1a done. Next: run_p4b_stage1b, then p4b_stats.\n');
