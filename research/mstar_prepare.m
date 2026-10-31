%% MSTAR_PREPARE  Build the SOC arrays from mstar_index.csv (10 classes, train 17 deg, test 15 deg).
% Run from the project root after run_phase2a. Needs mstar_read.m / mstar_header.m.
% Writes mstar_soc.mat (~340 MB) and mstar_class_means.png.
% Why this exists: run_phase2a's SOC filter looked for "slicy", but the headers spell the
% calibration target "slicey", so SLICY (298 train / 548 test) leaked into its counts.
% Matching on 'slic' removes it; train/test then equal the literature (2747 / 2425).
% Chips are centre-cropped to 128x128 (the smallest SOC chip is 128x128; the larger chips are
% bigger only because of extra clutter around the same centred target), raw magnitude, single.
rng(0);
opts = detectImportOptions('mstar_index.csv');
opts = setvartype(opts, {'path','type','serial','status'}, 'string');
T = readtable('mstar_index.csv', opts);

tl = lower(T.type); sl = lower(T.serial);
isChip = T.status == "ok" & T.rows .* T.cols <= 200*200;
okSer = true(height(T), 1);
m = contains(tl, 'bmp');   okSer(m) = contains(sl(m), '9563');
m = contains(tl, 'btr70'); okSer(m) = contains(sl(m), 'c71');
m = contains(tl, 't72');   okSer(m) = contains(sl(m), '132');
base = isChip & okSer & ~contains(tl, 'slic');
iTr = find(base & abs(T.depr - 17) < 1);
iTe = find(base & abs(T.depr - 15) < 1);
fprintf('train (17 deg) %d, test (15 deg) %d   literature: 2747 / 2425\n', numel(iTr), numel(iTe));
if numel(iTr) ~= 2747 || numel(iTe) ~= 2425
    error('counts differ from the literature SOC split - stop and paste this output to me');
end
classNames = sort(unique(tl(iTr)));
if numel(classNames) ~= 10 || ~isequal(classNames, sort(unique(tl(iTe))))
    error('expected the same 10 classes in train and test');
end
Ytr = categorical(tl(iTr), classNames); Yte = categorical(tl(iTe), classNames);

S = 128;
fprintf('loading training chips...\n'); Xtr = loadset(T, iTr, S);
fprintf('loading test chips...\n');     Xte = loadset(T, iTe, S);
ptr = T.path(iTr); pte = T.path(iTe);
aztr = T.az(iTr); azte = T.az(iTe);
origTr = [T.rows(iTr) T.cols(iTr)]; origTe = [T.rows(iTe) T.cols(iTe)];

%% sanity
fprintf('\nfinite: train %d, test %d | magnitude min/mean/max: %.3g / %.3g / %.3g\n', ...
    all(isfinite(Xtr(:))), all(isfinite(Xte(:))), min(Xtr(:)), mean(Xtr(:)), max(Xtr(:)));
fprintf('path overlap between train and test: %d\n', numel(intersect(ptr, pte)));
fprintf('\n%-18s %6s %6s   original chip sizes in train (before cropping)\n', 'class', 'train', 'test');
[xx, yy] = meshgrid(1:S, 1:S);
figure('Name', 'class means', 'Position', [100 100 1300 600]); tiledlayout(2, 5, 'TileSpacing', 'compact');
for q = 1:numel(classNames)
    mt = Ytr == classNames(q);
    sz = unique(string(origTr(mt,1)) + "x" + string(origTr(mt,2)));
    fprintf('%-18s %6d %6d   %s\n', classNames(q), nnz(mt), nnz(Yte == classNames(q)), strjoin(sz, ', '));
    A = mean(Xtr(:,:,1,mt), 4); w = A.^2;
    fprintf('    centre of mass of the mean image: dx %+.1f px, dy %+.1f px from the chip centre\n', ...
        sum(xx(:).*w(:))/sum(w(:)) - (S+1)/2, sum(yy(:).*w(:))/sum(w(:)) - (S+1)/2);
    nexttile; imagesc(sqrt(A)); axis image off; colormap gray; title(char(classNames(q)), 'Interpreter', 'none');
end
exportgraphics(gcf, 'mstar_class_means.png', 'Resolution', 150);

save('mstar_soc.mat', 'Xtr', 'Ytr', 'Xte', 'Yte', 'classNames', 'ptr', 'pte', 'aztr', 'azte', 'origTr', 'origTe', '-v7.3');
fprintf('\nwrote mstar_soc.mat. Attach mstar_class_means.png and paste this whole output.\n');

%% local functions
function X = loadset(T, idx, S)
n = numel(idx); X = zeros(S, S, 1, n, 'single');
for k = 1:n
    mg = mstar_read(char(T.path(idx(k))));
    r = size(mg, 1); c = size(mg, 2);
    if r < S || c < S, error('chip %s is %dx%d, smaller than %d', T.path(idx(k)), r, c, S); end
    r0 = floor((r-S)/2) + 1; c0 = floor((c-S)/2) + 1;
    X(:,:,1,k) = mg(r0:r0+S-1, c0:c0+S-1);
    if mod(k, 500) == 0, fprintf('  %d / %d\n', k, n); end
end
end
