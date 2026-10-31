function inspect_sar_data(rootDir)
% INSPECT_SAR_DATA  Stage-2 checks: is everything you EXPECT there, and what is INSIDE it?
% (check_sar_data answers "are the files healthy"; this answers "is it complete and usable".)
%
%   inspect_sar_data            % uses the default folder below
%   inspect_sar_data('D:\x')
%
% Prints + saves everything to <root>\_inspect_report.txt  -> paste that back to me.
% Parts (each runs independently; one failing does not stop the rest):
%   1 top-level folder inventory     2 Gotcha completeness + what is inside a file
%   3 the stray file named ERROR     4 Sentinel-1 zip integrity (cheap truncation test)
%   5 Sentinel-1 geometry: orbit/pass, does the scene cover Hyderabad, where in pixels,
%     and a 2048x2048 crop saved as PNG so you can LOOK at it.
% STATUS: not run by the author (no MATLAB available) - paste any error message back.

if nargin < 1 || isempty(rootDir)
    rootDir = 'C:\Users\sruja\OneDrive\Documents\SARorsmthn';
end
HYD = [17.385 78.4867];            % [lat lon] to locate inside the Sentinel-1 scene

out = fullfile(rootDir, '_inspect_report.txt');
diary off
if exist(out, 'file'), delete(out); end
diary(out);
cleaner = onCleanup(@() diary('off')); %#ok<NASGU>

fprintf('==== inspect_sar_data  %s ====\nRoot: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), rootDir);
parts = {@p_inventory, @p_gotcha, @p_error, @p_zips, @p_s1};
for i = 1:numel(parts)
    try
        parts{i}(rootDir, HYD);
    catch ME
        fprintf('  [part %d FAILED] %s\n', i, ME.message);
    end
end
fprintf('\nSaved: %s\n', out);
end

% ======================================================================
function p_inventory(root, ~)
fprintf('\n=== 1. TOP-LEVEL FOLDERS ===\n');
T = dir(root);
T = T([T.isdir] & ~startsWith({T.name}, '.'));
for i = 1:numel(T)
    L = dir(fullfile(root, T(i).name, '**', '*'));
    L = L(~[L.isdir]);
    fprintf('%-45s %7d files %8.2f GB\n', T(i).name, numel(L), sum([L.bytes]) / 2^30);
end
fprintf('Compare with your SDMS list: MSTAR Public Target Chips CD1, MSTAR/IU Mixed Targets CD1+CD2,\n');
fprintf('MSTAR Public Clutter CD1+CD2, Gotcha Disc 1 & 2. Anything not above is NOT on disk (or is named differently).\n');
end

% ======================================================================
function p_gotcha(root, ~)
fprintf('\n=== 2. GOTCHA volumetric (data_3dsar_pass*_az*_*.mat) ===\n');
G = dir(fullfile(root, '**', 'data_3dsar_pass*_az*_*.mat'));
if isempty(G), fprintf('none found\n'); return; end
tok = regexp({G.name}, 'pass(\d+)_az(\d+)_([A-Za-z]+)\.mat', 'tokens', 'once');
ok = ~cellfun(@isempty, tok);
G = G(ok); tok = tok(ok);
pass = cellfun(@(t) str2double(t{1}), tok);
az   = cellfun(@(t) str2double(t{2}), tok);
pol  = cellfun(@(t) upper(t{3}), tok, 'UniformOutput', false);
key  = cellfun(@(p, q) sprintf('pass%d_%s', p, q), num2cell(pass), pol, 'UniformOutput', false);
[ukeys, ~, k] = unique(key);
for j = 1:numel(ukeys)
    a = sort(az(k == j));
    miss = setdiff(1:max(a), a);
    if isempty(miss), ms = 'none'; else, ms = mat2str(miss(1:min(numel(miss), 10))); end
    fprintf('  %-14s %4d files  az %d..%d  missing az: %s\n', ukeys{j}, numel(a), min(a), max(a), ms);
end
fprintf('  (If a full circle is 360 azimuths per pass/polarization, anything below 360 is incomplete - check the Gotcha docs.)\n');

f1 = fullfile(G(1).folder, G(1).name);
S = load(f1);
fprintf('\nInside %s :\n', G(1).name);
fn = fieldnames(S);
for i = 1:numel(fn)
    v = S.(fn{i});
    fprintf('  variable "%s": class %s, size %s\n', fn{i}, class(v), mat2str(size(v)));
    if isstruct(v)
        ff = fieldnames(v);
        for q = 1:numel(ff)
            w = v.(ff{q});
            line = sprintf('    .%-12s %-8s %-14s', ff{q}, class(w), mat2str(size(w)));
            if isnumeric(w) && numel(w) <= 3
                line = [line ' = ' mat2str(w)]; %#ok<AGROW>
            elseif isnumeric(w) && ~isempty(w)
                line = [line sprintf(' range [%.4g, %.4g]', min(abs(w(:))), max(abs(w(:))))]; %#ok<AGROW>
            end
            fprintf('%s\n', line);
        end
    end
end
end

% ======================================================================
function p_error(root, ~)
fprintf('\n=== 3. stray file named ERROR ===\n');
E = dir(fullfile(root, '**', 'ERROR'));
E = E(~[E.isdir] & cellfun(@isempty, strfind({E.folder}, '.venv')));
if isempty(E), fprintf('none found\n'); return; end
for i = 1:numel(E)
    fprintf('%s  (%d bytes)\n--- content ---\n%s\n--- end ---\n', fullfile(E(i).folder, E(i).name), E(i).bytes, fileread(fullfile(E(i).folder, E(i).name)));
end
end

% ======================================================================
function p_zips(root, ~)
fprintf('\n=== 4. Sentinel-1 zip integrity (lists the archive; a truncated zip fails) ===\n');
Z = dir(fullfile(root, '**', 'S1*.zip'));
if isempty(Z), fprintf('no S1 zips\n'); return; end
for i = 1:numel(Z)
    zp = fullfile(Z(i).folder, Z(i).name);
    [s, o] = system(sprintf('tar -tf "%s"', zp));
    if s == 0
        fprintf('  OK     %-95s %.2f GB, %d entries\n', Z(i).name, Z(i).bytes / 1e9, numel(splitlines(strtrim(o))));
    else
        fprintf('  BROKEN %s : %s\n', Z(i).name, strtrim(o(1:min(numel(o), 200))));
    end
end
fprintf('  (Listing catches truncation, not flipped bits. Full proof = MD5 vs catalogue, which s1_download.py does.)\n');
end

% ======================================================================
function p_s1(root, HYD)
fprintf('\n=== 5. Sentinel-1 geometry ===\n');
SAF = dir(fullfile(root, '**', '*.SAFE'));
SAF = SAF([SAF.isdir]);
if isempty(SAF), fprintf('no .SAFE folders\n'); return; end
for s = 1:numel(SAF)
    d = fullfile(SAF(s).folder, SAF(s).name);
    fprintf('\n%s\n', SAF(s).name);

    m = fileread(fullfile(d, 'manifest.safe'));
    g = @(tag) pick_(m, ['<\w+:' tag '[^>]*>([^<]*)<']);
    fprintf('  relative orbit %s | absolute orbit %s | pass %s\n', g('relativeOrbitNumber'), g('orbitNumber'), g('pass'));
    fprintf('  (two scenes only pair well for multi-temporal work if relative orbit AND pass match)\n');

    A = dir(fullfile(d, 'annotation', 's1*-vv-*.xml'));
    if isempty(A), fprintf('  no VV annotation xml\n'); continue; end
    x = fileread(fullfile(A(1).folder, A(1).name));
    blk = regexp(x, '<geolocationGridPointList.*?</geolocationGridPointList>', 'match', 'once');
    val = @(tag) cellfun(@(c) str2double(c{1}), regexp(blk, ['<' tag '>([^<]*)</' tag '>'], 'tokens'));
    lat = val('latitude'); lon = val('longitude'); ln = val('line'); px = val('pixel');
    fprintf('  geolocation grid: %d points | lat %.3f..%.3f | lon %.3f..%.3f\n', numel(lat), min(lat), max(lat), min(lon), max(lon));

    kh = convhull(lon(:), lat(:));
    inside = inpolygon(HYD(2), HYD(1), lon(kh), lat(kh));
    fprintf('  Hyderabad (%.4f, %.4f) inside scene footprint: %s\n', HYD(1), HYD(2), tf_(inside));
    if ~inside, fprintf('  -> scene does not cover the point; choose another scene or change HYD.\n'); continue; end

    Fl = scatteredInterpolant(lon(:), lat(:), ln(:)); Fp = scatteredInterpolant(lon(:), lat(:), px(:));
    r0 = round(Fl(HYD(2), HYD(1))); c0 = round(Fp(HYD(2), HYD(1)));
    T = dir(fullfile(d, 'measurement', 's1*-vv-*.tif*'));
    tif = fullfile(T(1).folder, T(1).name);
    info = imfinfo(tif);
    fprintf('  image %d (range/cols) x %d (azimuth/rows), %d-bit | Hyderabad ~ row %d, col %d (+/- tens of pixels)\n', ...
        info(1).Width, info(1).Height, info(1).BitDepth, r0, c0);

    hw = 1024;
    r1 = max(1, r0 - hw + 1); r2 = min(info(1).Height, r0 + hw);
    c1 = max(1, c0 - hw + 1); c2 = min(info(1).Width,  c0 + hw);
    I = imread(tif, 'PixelRegion', {[r1 r2], [c1 c2]});
    fprintf('  crop rows %d-%d, cols %d-%d (%dx%d, class %s), DN range %d..%d\n', r1, r2, c1, c2, size(I, 1), size(I, 2), class(I), min(I(:)), max(I(:)));
    fprintf('  fraction of zero pixels (no-data border): %.1f%%\n', 100 * mean(I(:) == 0));

    dB = 20 * log10(double(I) + 1);                    % amplitude DN -> dB, UNCALIBRATED, only for looking
    fig = figure('Visible', 'off'); imagesc(dB); axis image; colormap gray;
    lo = prctile(dB(:), 1); hi = prctile(dB(:), 99); if hi > lo, clim([lo hi]); end
    title(sprintf('%s\nVV crop around Hyderabad (uncalibrated, dB-like)', strrep(SAF(s).name(1:40), '_', '\_')));
    png = fullfile(root, sprintf('_crop_hyderabad_%d.png', s));
    exportgraphics(fig, png, 'Resolution', 120); close(fig);
    fprintf('  saved %s  <- open it: you should see a city, roads, dark water bodies\n', png);
end
end

% ----------------------------------------------------------------------
function s = pick_(txt, pat)
t = regexp(txt, pat, 'tokens', 'once');
if isempty(t), s = '?'; else, s = strtrim(t{1}); end
end

function s = tf_(b)
if b, s = 'YES'; else, s = 'NO'; end
end