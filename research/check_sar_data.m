function report = check_sar_data(rootDir)
% CHECK_SAR_DATA  Pre-flight check for the SAR Workbench data folder.
%
%   check_sar_data                 -> checks the default folder below
%   check_sar_data('D:\other')     -> checks another folder
%   r = check_sar_data;            -> also returns a struct (r.overall, r.rows)
%
% Checks (recursively, whatever your sub-folder layout is):
%   1. Folder exists / writable / file inventory by extension
%   2. Zero-byte files, over-long Windows paths, OneDrive cloud-only risk
%   3. MSTAR target chips + clutter  (numeric extensions .000-.999, Phoenix header)
%   4. Sentinel-1 GRD  (.SAFE folders: manifest, annotation, measurement tiff)
%   5. Gotcha          (.mat files readable, variables listed)
%   6. Un-extracted archives
% Writes the same text to <root>\_data_check_report.txt
%
% Works in MATLAB (no toolboxes needed except base imfinfo) and Octave.

global SARLOG
SARLOG = {};
if nargin < 1 || isempty(rootDir)
    rootDir = 'C:\Users\sruja\OneDrive\Documents\SARorsmthn';
end

SAMPLE_N = 200;   % max MSTAR files whose headers are opened per group
report = struct('overall', 'FAIL', 'rows', {{}});

log_('==== SAR Workbench data check ====');
log_('Time   : %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
log_('Root   : %s', rootDir);
log_('Runtime: %s', version);
log_('');

%% 0. Root folder ---------------------------------------------------------
if ~exist(rootDir, 'dir')
    log_('[FAIL] Folder does not exist: %s', rootDir);
    log_('       Check spelling, or whether OneDrive moved "Documents" (it often does).');
    return
end
tmp = fullfile(rootDir, '_write_test.tmp');
fid = fopen(tmp, 'w');
if fid < 0
    log_('[WARN] Folder is not writable - outputs/results cannot be saved here.');
else
    fclose(fid); delete(tmp);
end

%% 1. Inventory -----------------------------------------------------------
[fp, fb, dp, skipped] = walk_(rootDir);
nF = numel(fp);
log_('Files: %d | Sub-folders: %d | Total size: %s', nF, numel(dp), hsz_(sum(fb)));
if ~isempty(skipped)
    log_('Skipped tooling folders (not data): %s', strjoin(skipped, ', '));
end
if nF == 0
    log_('[FAIL] Folder is empty - no data at all.');
    save_log_(rootDir);
    return
end
[~, nm, ex] = cellfun(@fileparts, fp, 'UniformOutput', false);
ex = lower(ex);

exk = ex; exk(cellfun(@isempty, exk)) = {'(none)'};
[ue, ~, ix] = unique(exk);
cnt = accumarray(ix(:), 1);
szs = accumarray(ix(:), fb(:));
[~, ord] = sort(szs, 'descend');
log_('');
log_('Largest file types:');
for k = 1:min(12, numel(ord))
    log_('   %-10s %7d files  %10s', ue{ord(k)}, cnt(ord(k)), hsz_(szs(ord(k))));
end
log_('');

%% 2. Generic health ------------------------------------------------------
V = {};   % rows: {check, status, detail}
nZero = sum(fb == 0);
if nZero > 0
    z = find(fb == 0);
    log_('[FAIL] %d zero-byte file(s), e.g. %s', nZero, fp{z(1)});
    V(end+1, :) = {'Zero-byte files', 'FAIL', sprintf('%d found', nZero)};
else
    V(end+1, :) = {'Zero-byte files', 'PASS', 'none'};
end
pl = cellfun(@numel, fp);
if max(pl) > 240
    log_('[WARN] %d path(s) longer than 240 chars (Windows/MATLAB trouble at 260). Longest: %d', sum(pl > 240), max(pl));
    V(end+1, :) = {'Path length', 'WARN', sprintf('%d paths > 240 chars', sum(pl > 240))};
else
    V(end+1, :) = {'Path length', 'PASS', sprintf('max %d chars', max(pl))};
end

% read-test a spread of files: catches OneDrive cloud-only stubs / locked files
nT = min(30, nF);
pick = unique(round(linspace(1, nF, nT)));
nFail = 0; t0 = tic;
for k = 1:numel(pick)
    f = fopen(fp{pick(k)}, 'r');
    if f < 0
        nFail = nFail + 1;
    else
        fread(f, 1, 'uint8'); fclose(f);
    end
end
tRead = toc(t0);
if nFail > 0
    V(end+1, :) = {'Read test', 'FAIL', sprintf('%d/%d sampled files could not be opened', nFail, numel(pick))};
    log_('[FAIL] %d of %d sampled files could not be opened.', nFail, numel(pick));
elseif tRead > 20
    V(end+1, :) = {'Read test', 'WARN', sprintf('slow (%.1f s) - files may be downloading from OneDrive', tRead)};
    log_('[WARN] Sampled reads took %.1f s - likely OneDrive downloading cloud-only files.', tRead);
else
    V(end+1, :) = {'Read test', 'PASS', sprintf('%d files opened in %.1f s', numel(pick), tRead)};
end
if ~isempty(strfind(lower(rootDir), 'onedrive'))
    log_('[NOTE] Folder is inside OneDrive. Right-click it > "Always keep on this device" so');
    log_('       MATLAB never hits a cloud-only placeholder mid-run (this also avoids sync of big');
    log_('       .SAFE/.mat files stalling while you work).');
end
log_('');

%% 3. MSTAR ---------------------------------------------------------------
low = lower(fp);
isNum = ~cellfun(@isempty, regexp(ex, '^\.\d{3}$', 'once'));
isClu = ~cellfun(@isempty, strfind(low, 'clutter'));
isNoExt = cellfun(@isempty, ex);   % MSTAR clutter/scene files have NO extension (e.g. HB06158)
V(end+1, :) = mstar_group_('MSTAR target chips', find(isNum & ~isClu),              fp, fb, SAMPLE_N, true);
V(end+1, :) = mstar_group_('MSTAR clutter',      find((isNum | isNoExt) & isClu),   fp, fb, SAMPLE_N, false);
idxS = find(isNoExt & ~isClu);   % extensionless, non-clutter: keep only real MSTAR files
okS = false(size(idxS));
for k = 1:numel(idxS)
    hS = mstar_hdr_(fp{idxS(k)}, fb(idxS(k)));
    okS(k) = hS.ok;
end
badS = find(~okS);
for k = 1:numel(badS)
    log_('[NOTE] Ignoring extensionless non-MSTAR file: %s (%s)', fp{idxS(badS(k))}, hsz_(fb(idxS(badS(k)))));
end
V(end+1, :) = mstar_group_('MSTAR scene files (no ext, non-clutter)', idxS(okS), fp, fb, SAMPLE_N, false);

%% 4. Sentinel-1 ----------------------------------------------------------
V(end+1, :) = s1_check_(dp, fp, fb, nm, ex);

%% 5. Gotcha --------------------------------------------------------------
V(end+1, :) = gotcha_check_(fp, fb, ex, low);

%% 6. Archives ------------------------------------------------------------
archExt = {'.zip', '.tar', '.gz', '.tgz', '.7z', '.rar', '.iso', '.bz2', '.xz'};
isArch = ismember(ex, archExt) & cellfun(@isempty, regexp(nm, '^S1[A-D]_', 'once'));
if any(isArch)
    a = find(isArch);
    log_('--- Archives ---');
    log_('[WARN] %d un-extracted archive(s) (MATLAB cannot read inside these):', numel(a));
    for k = 1:min(5, numel(a))
        log_('       %s (%s)', fp{a(k)}, hsz_(fb(a(k))));
    end
    log_('');
    V(end+1, :) = {'Archives', 'WARN', sprintf('%d un-extracted', numel(a))};
end

%% Summary ----------------------------------------------------------------
log_('==== SUMMARY ====');
for k = 1:size(V, 1)
    log_('%-8s %-22s %s', ['[' V{k, 2} ']'], V{k, 1}, V{k, 3});
end
st = V(:, 2);
if any(strcmp(st, 'FAIL'))
    overall = 'FAIL';
elseif any(strcmp(st, 'WARN'))
    overall = 'WARN';
else
    overall = 'PASS';
end
log_('');
log_('OVERALL: %s   (MISSING = optional dataset not present, does not fail the run)', overall);
log_('Report saved to: %s', fullfile(rootDir, '_data_check_report.txt'));
save_log_(rootDir);
report.overall = overall;
report.rows = V;
end

% ======================================================================
% MSTAR
% ======================================================================
function row = mstar_group_(label, idx, fp, fb, N, required)
log_('--- %s ---', label);
if isempty(idx)
    log_('No MSTAR-style files found (numeric extension .000-.999, or no extension for clutter/scenes).');
    log_('');
    if required, s = 'FAIL'; else s = 'MISSING'; end
    row = {label, s, 'no candidate files'};
    return
end
pick = idx(unique(round(linspace(1, numel(idx), min(N, numel(idx))))));
nOK = 0; nBad = 0; nTrunc = 0; nFull = 0;
types = {}; dims = {}; badEx = {};
for k = 1:numel(pick)
    h = mstar_hdr_(fp{pick(k)}, fb(pick(k)));
    if ~h.ok
        nBad = nBad + 1;
        if numel(badEx) < 3, badEx{end+1} = fp{pick(k)}; end %#ok<AGROW>
    else
        nOK = nOK + 1;
        if h.trunc, nTrunc = nTrunc + 1; end
        if h.full,  nFull  = nFull  + 1; end
        types{end+1} = h.type; %#ok<AGROW>
        dims{end+1}  = sprintf('%dx%d', h.rows, h.cols); %#ok<AGROW>
    end
end
low = lower(fp(idx));
n17 = sum(~cellfun(@isempty, strfind(low, '17_deg')));
n15 = sum(~cellfun(@isempty, strfind(low, '15_deg')));
log_('Candidate files        : %d  (headers opened: %d, evenly spread)', numel(idx), numel(pick));
log_('Valid Phoenix header   : %d / %d', nOK, numel(pick));
log_('Size == hdr + 2xfloat32: %d   truncated (< hdr + 1xfloat32 plane): %d', nFull, nTrunc);
log_('Chip dimensions seen   : %s', tally_(dims));
log_('TargetType in headers  : %s', tally_(types));
if n17 + n15 > 0
    log_('By folder name         : %d under "17_DEG", %d under "15_DEG"', n17, n15);
end
for k = 1:numel(badEx)
    log_('   bad header: %s', badEx{k});
end
if nOK == 0
    s = 'FAIL'; d = 'no valid headers (split archive volumes? wrong files?)';
elseif nTrunc > 0
    s = 'FAIL'; d = sprintf('%d sampled file(s) truncated', nTrunc);
elseif nBad / numel(pick) > 0.2
    s = 'FAIL'; d = sprintf('%d/%d sampled headers invalid', nBad, numel(pick));
elseif nBad > 0
    s = 'WARN'; d = sprintf('%d/%d sampled headers invalid', nBad, numel(pick));
else
    s = 'PASS'; d = sprintf('%d files, all sampled headers valid', numel(idx));
end
log_('Verdict: %s', s);
log_('');
row = {label, s, d};
end

function h = mstar_hdr_(p, nbytes)
h = struct('ok', false, 'rows', NaN, 'cols', NaN, 'type', '?', 'trunc', false, 'full', false);
fid = fopen(p, 'r');
if fid < 0, return; end
b = fread(fid, 8192, 'uint8=>uint8')';
fclose(fid);
t = char(b);
if isempty(strfind(t, 'PhoenixHeader')), return; end
hl = regexp(t, 'PhoenixHeaderLength\s*=\s*(\d+)', 'tokens', 'once');
nc = regexp(t, 'NumberOfColumns\s*=\s*(\d+)',     'tokens', 'once');
nr = regexp(t, 'NumberOfRows\s*=\s*(\d+)',        'tokens', 'once');
tt = regexp(t, 'TargetType\s*=\s*([A-Za-z0-9_\-]+)', 'tokens', 'once');
if isempty(hl) || isempty(nc) || isempty(nr), return; end
hl = str2double(hl{1}); h.cols = str2double(nc{1}); h.rows = str2double(nr{1});
if ~isempty(tt), h.type = lower(tt{1}); end
h.ok    = true;
h.trunc = nbytes < hl + 4 * h.rows * h.cols;
h.full  = nbytes == hl + 8 * h.rows * h.cols;
end

% ======================================================================
% Sentinel-1
% ======================================================================
function row = s1_check_(dp, fp, fb, nm, ex)
log_('--- Sentinel-1 GRD ---');
isSafe = ~cellfun(@isempty, regexp(dp, '\.SAFE$', 'once', 'ignorecase'));
safes = dp(isSafe);
zips = find(strcmp(ex, '.zip') & ~cellfun(@isempty, regexp(nm, '^S1[A-D]_', 'once')));
log_('.SAFE folders: %d | S1 .zip files: %d', numel(safes), numel(zips));
nGood = 0; nBadS = 0;
for k = 1:numel(safes)
    d = safes{k}; [~, sn] = fileparts(d);
    issues = {};
    if ~exist(fullfile(d, 'manifest.safe'), 'file'), issues{end+1} = 'no manifest.safe'; end %#ok<AGROW>
    tf = dir(fullfile(d, 'measurement', '*.tif*'));
    xf = dir(fullfile(d, 'annotation', '*.xml'));
    if isempty(tf), issues{end+1} = 'no measurement tiff'; end %#ok<AGROW>
    if isempty(xf), issues{end+1} = 'no annotation xml';  end %#ok<AGROW>
    if isempty(strfind(sn, '_IW_GRD')), issues{end+1} = 'not an IW GRD product'; end %#ok<AGROW>
    dim = '?'; pols = '';
    if ~isempty(tf)
        try
            info = imfinfo(fullfile(d, 'measurement', tf(1).name));
            dim = sprintf('%dx%d', info(1).Width, info(1).Height);
            need = 0.9 * info(1).Width * info(1).Height * info(1).BitDepth / 8;
            if tf(1).bytes < need
                issues{end+1} = 'tiff smaller than expected (incomplete download?)'; %#ok<AGROW>
            end
        catch ME
            issues{end+1} = ['tiff unreadable: ' ME.message]; %#ok<AGROW>
        end
        for j = 1:numel(tf)
            m = regexp(lower(tf(j).name), '-(vv|vh|hh|hv)-', 'tokens', 'once');
            if ~isempty(m), pols = [pols ' ' upper(m{1})]; end %#ok<AGROW>
        end
    end
    if isempty(issues)
        nGood = nGood + 1;
        log_('  OK    %s | %s |%s', sn, dim, pols);
    else
        nBadS = nBadS + 1;
        log_('  ISSUE %s : %s', sn, strjoin(issues, '; '));
    end
end
for k = 1:numel(zips)
    z = zips(k);
    msg = '';
    if fb(z) < 300e6, msg = '  <-- small for a GRD zip, maybe truncated'; end
    log_('  zip   %s (%s)%s', [nm{z} '.zip'], hsz_(fb(z)), msg);
end
if isempty(safes) && isempty(zips)
    s = 'FAIL'; d = 'no Sentinel-1 data found';
    log_('No Sentinel-1 products found.');
elseif isempty(safes)
    s = 'WARN'; d = 'only .zip present - unzip so .SAFE folders exist';
elseif nBadS == 0
    s = 'PASS'; d = sprintf('%d .SAFE product(s) complete', nGood);
elseif nGood > 0
    s = 'WARN'; d = sprintf('%d good, %d with issues', nGood, nBadS);
else
    s = 'FAIL'; d = sprintf('%d .SAFE product(s), all with issues', nBadS);
end
log_('Verdict: %s', s);
log_('');
row = {'Sentinel-1 GRD', s, d};
end

% ======================================================================
% Gotcha
% ======================================================================
function row = gotcha_check_(fp, fb, ex, low)
log_('--- AFRL Gotcha ---');
matIdx = find(strcmp(ex, '.mat'));
gIdx = find(~cellfun(@isempty, strfind(low, 'gotcha')));
cand = intersect(matIdx, gIdx);
label = '';
if isempty(cand) && ~isempty(matIdx)
    cand = matIdx; label = ' (no "gotcha" in path - treating all .mat as candidates)';
end
if isempty(cand)
    if isempty(gIdx)
        log_('No Gotcha data found (optional until SDMS access clears).');
        s = 'MISSING'; d = 'not present (optional)';
    else
        log_('A "gotcha" folder exists but contains no .mat files.');
        s = 'WARN'; d = 'folder present, no .mat files';
    end
    log_('');
    row = {'Gotcha', s, d};
    return
end
log_('.mat candidates: %d%s', numel(cand), label);
pick = cand(unique(round(linspace(1, numel(cand), min(10, numel(cand))))));
nBad = 0;
for k = 1:numel(pick)
    p = fp{pick(k)};
    names = '';
    try
        w = whos('-file', p);
        if isempty(w), error('no variables'); end
        for j = 1:min(6, numel(w))
            names = [names sprintf(' %s[%s]', w(j).name, mat2str(w(j).size))]; %#ok<AGROW>
        end
    catch
        try
            S = load(p);
            fn = fieldnames(S);
            names = [' ' strjoin(fn', ' ')];
        catch ME
            nBad = nBad + 1;
            log_('  BAD  %s : %s', p, ME.message);
            continue
        end
    end
    if k <= 3, log_('  ok   %s (%s):%s', p, hsz_(fb(pick(k))), names); end
end
if nBad > 0
    s = 'FAIL'; d = sprintf('%d/%d sampled .mat unreadable', nBad, numel(pick));
else
    s = 'PASS'; d = sprintf('%d .mat readable (contents NOT checked against Gotcha spec)', numel(cand));
    log_('  Files load, but check the variable names above against the Gotcha documentation yourself.');
end
log_('Verdict: %s', s);
log_('');
row = {'Gotcha', s, d};
end

% ======================================================================
% helpers
% ======================================================================
function [fp, fb, dp, skipped] = walk_(root)
fp = {}; fb = []; dp = {}; skipped = {};
stack = {root};
while ~isempty(stack)
    d = stack{end}; stack(end) = [];
    L = dir(d);
    for i = 1:numel(L)
        n = L(i).name;
        if strcmp(n, '.') || strcmp(n, '..'), continue; end
        p = fullfile(d, n);
        if L(i).isdir
            % skip tooling folders (.venv, .git, ...) - thousands of files, not data
            if n(1) == '.' || strcmp(n, '__pycache__') || strcmp(n, 'node_modules')
                skipped{end+1} = n; %#ok<AGROW>
                continue
            end
            stack{end+1} = p; %#ok<AGROW>
            dp{end+1} = p;    %#ok<AGROW>
        else
            fp{end+1, 1} = p;       %#ok<AGROW>
            fb(end+1, 1) = L(i).bytes; %#ok<AGROW>
        end
    end
end
% ignore this tool's own output
keep = cellfun(@isempty, strfind(fp, '_data_check_report.txt'));
fp = fp(keep); fb = fb(keep);
end

function s = tally_(c)
if isempty(c), s = '(none)'; return; end
[u, ~, i] = unique(c);
n = accumarray(i(:), 1);
[n, o] = sort(n, 'descend');
u = u(o);
parts = cell(1, min(12, numel(u)));
for k = 1:numel(parts), parts{k} = sprintf('%s(%d)', u{k}, n(k)); end
s = strjoin(parts, ', ');
if numel(u) > 12, s = [s ', ...']; end
end

function s = hsz_(b)
u = {'B', 'KB', 'MB', 'GB', 'TB'}; k = 1;
while b >= 1024 && k < numel(u), b = b / 1024; k = k + 1; end
s = sprintf('%.1f %s', b, u{k});
end

function log_(fmt, varargin)
global SARLOG
if isempty(varargin), s = fmt; else s = sprintf(fmt, varargin{:}); end
SARLOG{end+1} = s;
fprintf('%s\n', s);
end

function save_log_(rootDir)
global SARLOG
fid = fopen(fullfile(rootDir, '_data_check_report.txt'), 'w');
if fid < 0, return; end
for k = 1:numel(SARLOG)
    fprintf(fid, '%s\r\n', SARLOG{k});
end
fclose(fid);
end