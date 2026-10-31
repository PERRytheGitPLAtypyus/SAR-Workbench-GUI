function s1_search_download()
% S1_SEARCH_DOWNLOAD  Find and download a Sentinel-1 IW GRD scene from the
% Copernicus Data Space Ecosystem (CDSE) via its OData API.
%
%   Run:  s1_search_download
%
%   1. SEARCH   anonymous, no login needed. Prints matching scenes (newest first).
%   2. PICK     you type the number of the scene you want (Enter = quit).
%   3. LOGIN    asks for your CDSE email + password (free account at
%               dataspace.copernicus.eu). Set env vars CDSE_USER / CDSE_PASS
%               first if you don't want to type them (setenv('CDSE_USER','a@b.c')).
%   4. DOWNLOAD uses curl.exe (ships with Windows 10/11), checks size + MD5, unzips.
%
% Needs: MATLAB (no toolboxes), internet, curl.exe + certutil (both built into Windows).
%
% STATUS: written from CDSE docs + forum threads; NOT run against the live API by
% the author. If the search step errors, the exact request is printed - paste it back.

%% ---------------- CONFIG (edit these) ----------------
cfg.lat      = 17.385;        % Hyderabad
cfg.lon      = 78.4867;
cfg.halfDeg  = 0.02;          % search box half-size in degrees (~2 km)
cfg.daysBack = 120;           % only scenes from the last N days
cfg.pol      = '1SDV';        % '1SDV' = VV+VH (~1.7 GB) | '1SSV' = VV only (~0.9 GB) | '' = any
cfg.top      = 40;            % how many catalogue rows to pull
cfg.outDir   = 'C:\Users\sruja\OneDrive\Documents\SARorsmthn\Sentinel1';
%% -------------------------------------------------------

base     = 'https://catalogue.dataspace.copernicus.eu/odata/v1/Products';
tokenUrl = 'https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token';

%% 1. SEARCH --------------------------------------------------------------
h = cfg.halfDeg; lat = cfg.lat; lon = cfg.lon;
% counter-clockwise closed ring, "lon lat" order
wkt = sprintf('POLYGON((%.5f %.5f,%.5f %.5f,%.5f %.5f,%.5f %.5f,%.5f %.5f))', ...
    lon-h, lat-h,  lon+h, lat-h,  lon+h, lat+h,  lon-h, lat+h,  lon-h, lat-h);
since = [datestr(now - cfg.daysBack, 'yyyy-mm-dd') 'T00:00:00.000Z'];

filt = "Collection/Name eq 'SENTINEL-1' and " + ...
       "Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq 'IW_GRDH_1S') and " + ...
       "OData.CSC.Intersects(area=geography'SRID=4326;" + string(wkt) + "') and " + ...
       "ContentDate/Start gt " + string(since);

fprintf('\n--- SEARCH ---\nURL  : %s\n$filter = %s\n\n', base, filt);
try
    r = webread(base, '$filter', char(filt), '$orderby', 'ContentDate/Start desc', ...
        '$top', cfg.top, weboptions('Timeout', 90));
catch ME
    fprintf(2, 'Search request failed:\n  %s\n', ME.message);
    fprintf(2, 'Send me this message + the $filter above.\n');
    return
end

v = r.value;
if isempty(v)
    fprintf('No scenes returned for that box/date range. Try a bigger cfg.daysBack or cfg.halfDeg, or cfg.pol = ''''.\n');
    return
end

% collect rows (jsondecode gives a struct array OR a cell, depending on the data)
rows = struct('name', {}, 'id', {}, 'bytes', {}, 'start', {}, 'md5', {});
for i = 1:numel(v)
    if iscell(v), e = v{i}; else, e = v(i); end
    if isfield(e, 'Online') && ~e.Online, continue; end
    nm = e.Name;
    if ~isempty(cfg.pol) && isempty(strfind(nm, cfg.pol)), continue; end %#ok<STREMP>
    rows(end+1).name = nm;                         %#ok<AGROW>
    rows(end).id     = e.Id;
    rows(end).bytes  = e.ContentLength;
    rows(end).start  = e.ContentDate.Start;
    rows(end).md5    = md5_of_(e);
end
if isempty(rows)
    fprintf('Catalogue returned %d rows but none matched pol "%s". Set cfg.pol = '''' to see all.\n', numel(v), cfg.pol);
    return
end

fprintf('%d scene(s):\n', numel(rows));
for i = 1:numel(rows)
    fprintf('%3d  %s  %5.2f GB  %s\n', i, rows(i).start(1:19), rows(i).bytes/1e9, rows(i).name);
end
fprintf('\nName guide: S1A/S1C/S1D = satellite, 1SDV = dual-pol VV+VH, 1SSV = VV only, then start/stop time.\n');

%% 2. PICK ----------------------------------------------------------------
k = input(sprintf('\nNumber to download (1-%d), Enter = quit: ', numel(rows)));
if isempty(k) || k < 1 || k > numel(rows), disp('Nothing downloaded.'); return; end
sel  = rows(k);
stem = regexprep(sel.name, '\.SAFE$', '');
fprintf('Selected: %s (%.2f GB)\n', sel.name, sel.bytes/1e9);

if ~exist(cfg.outDir, 'dir'), mkdir(cfg.outDir); end
zipPath = fullfile(cfg.outDir, [stem '.zip']);

[s, ~] = system('curl.exe --version');
if s ~= 0, error('curl.exe not found. Windows 10/11 normally has it; else install curl or use the Copernicus Browser website.'); end

%% 3. LOGIN ---------------------------------------------------------------
user = getenv('CDSE_USER'); pw = getenv('CDSE_PASS');
if isempty(user), user = input('CDSE email: ', 's'); end
if isempty(pw),   pw   = input('CDSE password (VISIBLE while typing - clear the Command Window afterwards): ', 's'); end
try
    tok = webwrite(tokenUrl, 'client_id', 'cdse-public', 'username', user, ...
        'password', pw, 'grant_type', 'password', ...
        weboptions('MediaType', 'application/x-www-form-urlencoded', 'Timeout', 60));
catch ME
    fprintf(2, 'Login failed: %s\n(2FA enabled? the docs say to add a "totp" field - tell me and I will add it.)\n', ME.message);
    return
end
pw = ''; %#ok<NASGU>
at = tok.access_token;          % ONLY this field goes in the header (whole JSON -> 1 KB junk file)

%% 4. DOWNLOAD ------------------------------------------------------------
url = sprintf('https://catalogue.dataspace.copernicus.eu/odata/v1/Products(%s)/$value', sel.id);
fprintf('\nDownloading to %s\n(token lasts ~10 min; max 4 parallel downloads per account)\n\n', zipPath);
cmd = sprintf('curl.exe -f -L --location-trusted -# -H "Authorization: Bearer %s" -o "%s" "%s"', at, zipPath, url);
[st, ~] = system(cmd, '-echo');
if st ~= 0
    fprintf(2, '\ncurl exit code %d - download failed (401/403 = login/quota, 5xx = server busy, retry later).\n', st);
    return
end

%% 5. VERIFY --------------------------------------------------------------
d = dir(zipPath);
fprintf('\nSize on disk : %d bytes | catalogue says: %d bytes -> %s\n', d.bytes, sel.bytes, tf_(d.bytes == sel.bytes));
if ~isempty(sel.md5)
    [s2, out] = system(sprintf('certutil -hashfile "%s" MD5', zipPath));
    if s2 == 0
        ln = splitlines(strtrim(out)); got = lower(strrep(strtrim(ln{2}), ' ', ''));
        fprintf('MD5 on disk  : %s\nMD5 catalogue: %s -> %s\n', got, lower(sel.md5), tf_(strcmp(got, lower(sel.md5))));
    end
end
if d.bytes ~= sel.bytes
    fprintf(2, 'Size mismatch: do NOT use this file. Delete it and re-run.\n'); return
end

%% 6. UNZIP ---------------------------------------------------------------
fprintf('\nUnzipping (a few minutes)...\n');
unzip(zipPath, cfg.outDir);
fprintf('Done. Now run:  check_sar_data\n');
fprintf('Keep the .zip until the check passes, then you can delete it to save ~%.1f GB.\n', sel.bytes/1e9);
end

% ----------------------------------------------------------------------
function m = md5_of_(e)
m = '';
try
    c = e.Checksum;
    for j = 1:numel(c)
        if iscell(c), cj = c{j}; else, cj = c(j); end
        if strcmpi(cj.Algorithm, 'MD5'), m = cj.Value; return; end
    end
catch
end
end

function s = tf_(b)
if b, s = 'OK'; else, s = 'MISMATCH'; end
end