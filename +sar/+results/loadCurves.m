function res = loadCurves(resultsMatPath)
% SAR.RESULTS.LOADCURVES  Load sample-complexity curves and summary table
%   Loads p4b_stage2m.mat results comparing raw shift aug (B1), blur aug (C1),
%   and MERLIN + shift aug (M1) across fractions [2%, 5%, 10%, 20%, 50%, 100%].

if nargin < 1 || isempty(resultsMatPath)
    cfg = sar.env.config();
    resultsMatPath = cfg.resultsPath;
end

if ~exist(resultsMatPath, 'file')
    error('sar:results:fileNotFound', 'Results file not found: %s', resultsMatPath);
end

S = load(resultsMatPath);
res = struct();
res.fracs = S.fracs;
res.keys = S.keys;
res.M = S.M;
res.SE = S.SE;
res.nSeeds = S.nSeeds;
end
