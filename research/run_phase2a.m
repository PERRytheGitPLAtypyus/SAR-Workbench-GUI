%% RUN_PHASE2A  MSTAR: verify the reader, build the index CSV, check the standard-split counts.
% Run from the project root. Needs mstar_header.m and mstar_read.m.
% MSTAR files are found by CONTENT (a PhoenixHeader in the first bytes), not by name, so
% extensionless clutter files and numeric extensions (.000, .001, ...) are all picked up.
% Gate: (1) reader size checks pass on every sampled chip, (2) SOC counts match the literature
% (train 17 deg = 2747, test 15 deg = 2425), (3) the montage shows real vehicles.
clear; close all; clc; rng(0);
root = pwd;

%% 1. find MSTAR files by header sniffing
fprintf('listing files under %s ...\n', root);
L = dir(fullfile(root, '**', '*')); L = L(~[L.isdir]);
L = L(~contains({L.folder}, '.venv') & ~contains({L.folder}, 'site-packages') & ~contains({L.folder}, [filesep '.git']));
skipExt = {'.mat','.zip','.tif','.tiff','.png','.jpg','.m','.py','.pyc','.csv','.docx','.txt','.xml','.json','.jp2','.dll','.pyd','.safe','.md','.pdf'};
isM = false(numel(L), 1); exts = cell(numel(L), 1);
for i = 1:numel(L)
    if mod(i, 4000) == 0, fprintf('  sniffed %d / %d\n', i, numel(L)); end
    [~, ~, ext] = fileparts(L(i).name); exts{i} = ext;
    if L(i).bytes < 4096 || any(strcmpi(ext, skipExt)), continue; end
    fid = fopen(fullfile(L(i).folder, L(i).name), 'r');
    if fid < 0, continue; end
    b = fread(fid, 1024, 'uint8=>char').'; fclose(fid);
    isM(i) = contains(b, 'PhoenixHeader');
end
F = L(isM); n = numel(F);
fprintf('files with a PhoenixHeader: %d\n', n);
if n == 0
    fprintf('None found. First bytes of 5 random candidate files (paste these to me):\n');
    cand = find(~ismember(lower(exts), skipExt) & [L.bytes].' > 4096);
    for q = cand(randperm(numel(cand), min(5, numel(cand)))).'
        fid = fopen(fullfile(L(q).folder, L(q).name), 'r'); b = fread(fid, 80, 'uint8=>char').'; fclose(fid);
        fprintf('  %s : %s\n', L(q).name, regexprep(b, '[^\x20-\x7e]', '.'));
    end
    return;
end

%% 2. parse every header
pth = strings(n,1); typ = strings(n,1); ser = strings(n,1); sts = strings(n,1);
dep = nan(n,1); azm = nan(n,1); rws = nan(n,1); cls = nan(n,1); byt = nan(n,1);
firstH = [];
for i = 1:n
    p = fullfile(F(i).folder, F(i).name); pth(i) = string(p); byt(i) = F(i).bytes;
    try
        H = mstar_header(p);
        if isempty(firstH), firstH = H; end
        typ(i) = string(pickfield(H, {'^TargetType$', 'Target.*Type'}));
        ser(i) = string(pickfield(H, {'^TargetSerNum$', 'Ser'}));
        dep(i) = tonum(pickfield(H, {'^DesiredDepression$', 'Depression'}));
        azm(i) = tonum(pickfield(H, {'^TargetAz$', 'Azimuth', 'Az$'}));
        rws(i) = H.rows; cls(i) = H.cols; sts(i) = "ok";
    catch ME
        sts(i) = "ERR " + string(ME.message);
    end
end
T = table(pth, typ, ser, dep, azm, rws, cls, byt, sts, 'VariableNames', ...
    {'path','type','serial','depr','az','rows','cols','bytes','status'});
fprintf('header errors: %d\n', nnz(T.status ~= "ok"));
bad = find(T.status ~= "ok");
for q = bad(1:min(5, numel(bad))).'
    fprintf('  %s -> %s\n', T.path(q), T.status(q));
end
if isempty(firstH), fprintf('no header could be parsed\n'); return; end
fprintf('\n--- header fields of the first file (check the key names I guessed) ---\n');
fk = fieldnames(firstH);
for q = 1:min(numel(fk), 60)
    v = firstH.(fk{q}); if isnumeric(v), v = num2str(v); end
    fprintf('  %-28s = %s\n', fk{q}, v);
end

%% 3. what is in the index
ok = T.status == "ok";
isChip = ok & T.rows .* T.cols <= 200*200;
fprintf('\nMSTAR files %d | chips (<=200x200) %d | larger scenes (clutter) %d\n', nnz(ok), nnz(isChip), nnz(ok & ~isChip));
[u, ~, g] = unique(T.rows(isChip)*10000 + T.cols(isChip));
cnt = accumarray(g, 1);
[cnt, ix] = sort(cnt, 'descend'); u = u(ix);
fprintf('chip sizes (rows x cols : count):');
for q = 1:min(10, numel(u)), fprintf('  %dx%d:%d', floor(u(q)/10000), mod(u(q), 10000), cnt(q)); end
fprintf('\n');

C = T(isChip, :); C.d = round(C.depr);
[gg, tp, sn, dd] = findgroups(C.type, C.serial, C.d);
nn = splitapply(@numel, C.rows, gg);
S = sortrows(table(tp, sn, dd, nn), {'tp','sn','dd'});
fprintf('\n--- chips per (type, serial, depression) ---\n');
for q = 1:height(S), fprintf('  %-22s %-8s %4d deg %6d\n', S.tp(q), S.sn(q), S.dd(q), S.nn(q)); end

%% 4. standard operating condition (SOC) split: 10 classes, train 17 deg / test 15 deg, no SLICY
tl = lower(C.type); sl = lower(C.serial);
okSer = true(height(C), 1);
m = contains(tl, 'bmp');   okSer(m) = contains(sl(m), '9563');
m = contains(tl, 'btr70'); okSer(m) = contains(sl(m), 'c71');
m = contains(tl, 't72');   okSer(m) = contains(sl(m), '132');
base = ~contains(tl, 'slicy') & okSer;
trn = C(base & abs(C.depr - 17) < 1, :);
tst = C(base & abs(C.depr - 15) < 1, :);
fprintf('\nSOC subset: train(17 deg) = %d, test(15 deg) = %d     literature: 2747 / 2425\n', height(trn), height(tst));
cl = unique([trn.type; tst.type]);
fprintf('%-22s %7s %7s\n', 'class', 'train', 'test');
for q = 1:numel(cl)
    fprintf('%-22s %7d %7d\n', cl(q), nnz(trn.type == cl(q)), nnz(tst.type == cl(q)));
end
fprintf('literature per class (train/test): BMP2 233/195, BTR70 233/196, T72 232/196, BTR60 256/195, 2S1 299/274,\n');
fprintf('                                   BRDM2 298/274, D7 299/274, T62 299/273, ZIL131 299/274, ZSU23/4 299/274\n');
T.split = strings(height(T), 1);
T.split(ismember(T.path, trn.path)) = "train";
T.split(ismember(T.path, tst.path)) = "test";

%% 5. read-check 8 random chips, then montage of 20 random SOC training chips
fprintf('\n--- reader check (8 random chips) ---\n');
pick = C.path(randperm(height(C), min(8, height(C))));
allOK = true;
for q = 1:numel(pick)
    try
        [mg, ph, H] = mstar_read(char(pick(q)));
        good = all(isfinite(mg(:))) && min(mg(:)) >= 0;
        allOK = allOK && good && strcmp(H.offsetMethod, 'marker');
        fprintf('  %dx%d  method=%-14s mag min/mean/max = %.3g / %.3g / %.3g  phase %s  %s\n', size(mg,1), size(mg,2), ...
            H.offsetMethod, min(mg(:)), mean(mg(:)), max(mg(:)), mat2str(size(ph)), tern(good, 'finite, non-negative', 'BAD VALUES'));
    catch ME
        allOK = false; fprintf('  ERROR %s\n', ME.message);
    end
end
if ~isempty(trn)
    sel = trn.path(randperm(height(trn), min(20, height(trn))));
    figure('Name', 'MSTAR montage', 'Position', [100 100 1200 800]);
    tiledlayout(4, 5, 'TileSpacing', 'compact');
    for q = 1:numel(sel)
        mg = mstar_read(char(sel(q)));
        nexttile; imagesc(sqrt(mg)); axis image off; colormap gray;
        title(char(trn.type(trn.path == sel(q))), 'Interpreter', 'none', 'FontSize', 8);
    end
    exportgraphics(gcf, 'mstar_montage.png', 'Resolution', 150);
end
writetable(T, 'mstar_index.csv');
fprintf('\nwrote mstar_index.csv (%d rows, split column = train/test for the SOC subset)\n', height(T));
fprintf('GATE: reader check %s | SOC counts %d/%d vs 2747/2425.\n', tern(allOK, 'PASS', 'FAIL'), height(trn), height(tst));
fprintf('Attach mstar_montage.png and paste this whole output.\n');

%% local functions
function v = pickfield(H, pats)
fn = fieldnames(H);
for p = 1:numel(pats)
    i = find(~cellfun('isempty', regexpi(fn, pats{p}, 'once')), 1);
    if ~isempty(i), v = H.(fn{i}); return; end
end
v = NaN;
end

function x = tonum(v)
if isnumeric(v), x = v; else, x = str2double(v); end
end

function s = tern(c, a, b)
if c, s = a; else, s = b; end
end
