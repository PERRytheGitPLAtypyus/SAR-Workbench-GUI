function cfg = p4b_config()
% P4B_CONFIG  Fixed settings for Phase 4b (see claude/phase4b-experiment-spec.md in the project).
cfg.mat     = 'mstar_soc.mat';     % train 17 deg (Xtr, Ytr), test 15 deg (Xte, Yte), 128x128x1xN single magnitude
cfg.crop    = 88;                  % model input size (centre crop of the 128x128 chip)
cfg.maxShift = 8;                  % random-crop shift range in pixels (window stays inside the central 104x104)
cfg.pct     = 99.5;                % normalisation N: divide every model-input chip by its own 99.5th percentile, clip at 1
cfg.L       = 1;                   % nominal looks for Lee / Frost / Gamma-MAP
cfg.batch   = 64;
cfg.updatesFloor = 600;            % minimum number of gradient updates for tiny training fractions
cfg.epochsFor = @(frac, ntr) max(round(30/frac), ceil(cfg.updatesFloor / ceil(ntr/cfg.batch)));   % 300 epochs at 10 %
cfg.outdir  = 'p4b_runs';          % one .mat per arm x fraction x seed (resumable)
end
