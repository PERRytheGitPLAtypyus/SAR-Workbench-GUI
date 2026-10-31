%% P3B_EVAL  Despeckling quality on 15 deg MSTAR TEST chips (complex): MERLIN-type network vs Lee / Frost / boxcar, all windows listed.
% Needs p3b_merlin.mat (from p3b_train_merlin), mstar_soc.mat (pte), mstar_read.m, despeckle_filters.m, p3b_*.m. Time about 3 min.
% PRE-SET READING (written before seeing the numbers):
%   - compare methods at SIMILAR ENL gain (Lee 15 and boxcar 9/15 are included for that reason), not at equal window size
%   - a good despeckler: |bias| < 2 %, ratio mean near 1, ratio-vs-estimate corr near 0, ratio lag-1 autocorr close to the raw
%     intensity value (speckle-like ratio), and peak / energy / conc ratios near 1 at a large ENL gain
%   - posterior-mean estimators are expected to be smoother than the true reflectivity, so ENL gain alone proves nothing
clear; close all; clc; rng(3);
M = load('p3b_merlin.mat', 'net', 's'); net = M.net; s = M.s;
D = load('mstar_soc.mat', 'pte');
S = 128; n = 400; tgt = 41:88; P = 32;
sel = randperm(numel(D.pte), n);
Z = zeros(S, S, n);
for k = 1:n
    [mg, ph] = mstar_read(char(D.pte(sel(k))));
    r0 = floor((size(mg,1)-S)/2) + 1; c0 = floor((size(mg,2)-S)/2) + 1;
    Z(:,:,k) = double(mg(r0:r0+S-1, c0:c0+S-1)) .* exp(1j * double(ph(r0:r0+S-1, c0:c0+S-1)));
end
I = abs(Z).^2; A4 = reshape(single(abs(Z)), S, S, 1, n);
meth = {'raw', 'merlin', 'lee7', 'lee15', 'frost7', 'box5', 'box9', 'box15'};
res = cell(1, numel(meth));
for q = 1:numel(meth)
    switch meth{q}
        case 'raw',    R = I;
        case 'merlin', R = zeros(S, S, n); for k = 1:n, R(:,:,k) = double(p3b_denoise(net, Z(:,:,k), s)); end
        case 'lee7',   R = double(squeeze(despeckle_filters(A4, 'lee', 7, 1))).^2;
        case 'lee15',  R = double(squeeze(despeckle_filters(A4, 'lee', 15, 1))).^2;
        case 'frost7', R = double(squeeze(despeckle_filters(A4, 'frost', 7, 1))).^2;
        otherwise,     w = str2double(meth{q}(4:end)); R = max(convn(I, ones(w)/w^2, 'same'), 0);
    end
    res{q} = p3b_metrics(I, R, P, tgt);
end
fprintf('%-8s %7s %8s %7s %8s %7s %7s %7s %7s %7s\n', 'method', 'ENLgain', 'bias%', 'ratio', 'rcorr', 'rAC', 'rAC_raw', 'peak', 'energy', 'conc');
for q = 1:numel(meth)
    m = res{q};
    fprintf('%-8s %7.1f %+8.2f %7.3f %+8.3f %7.3f %7.3f %7.3f %7.3f %7.3f\n', meth{q}, m.gain, 100*m.bias, m.rmean, m.rcorr, m.rac, m.racRaw, m.peak, m.energy, m.conc);
end
save('p3b_eval.mat', 'meth', 'res');
fprintf('\nColumns: ENLgain = clutter ENL(est)/ENL(raw); ratio = mean of raw/estimate in clutter; rcorr = corr(ratio, estimate); rAC = lag-1 azimuth autocorr of the ratio (compare rAC_raw);\n peak/energy/conc = target-box 99%% pixel, total energy and top-1%% energy share relative to raw (1 = preserved).\nPaste this whole output.\n');
