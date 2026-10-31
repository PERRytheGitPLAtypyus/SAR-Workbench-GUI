%% PHASE0_CHECK  Close-out checks for the data layer. Run from the project root.
%  Prints everything; paste the full Command Window output back.
root = pwd;
fprintf('=== PHASE 0 CHECK  (%s) ===\n\n', root);

%% 1. Sentinel-1 crop PNG sanity (objective check, not just eyeballing)
fprintf('--- 1. Crop PNG ---\n');
f = dir(fullfile(root, '**', '_crop_hyderabad_1.png'));
if isempty(f)
    fprintf('NOT FOUND: _crop_hyderabad_1.png\n');
else
    p = fullfile(f(1).folder, f(1).name);
    I = imread(p);
    if ndims(I) == 3, I = rgb2gray(I); end
    D = double(I);
    fprintf('file   : %s\n', p);
    fprintf('size   : %d x %d, class %s, range [%g %g]\n', size(I,1), size(I,2), class(I), min(D(:)), max(D(:)));
    fprintf('mean/std: %.2f / %.2f\n', mean(D(:)), std(D(:)));
    fprintf('pct at min value (no-data/black): %.1f %%\n', 100*mean(D(:)==min(D(:))));
    pc = prctile(D(:), [1 5 25 50 75 95 99]);
    fprintf('percentiles 1/5/25/50/75/95/99: %s\n', mat2str(round(pc,1)));
    % local contrast: urban SAR should have strong local variation
    k = ones(7)/49; mu = conv2(D,k,'same'); sd = sqrt(max(conv2(D.^2,k,'same')-mu.^2,0));
    fprintf('median local std (7x7): %.2f   (near 0 => blank/flat image)\n', median(sd(:)));
    if std(D(:)) < 1 || mean(D(:)==min(D(:))) > 0.5
        fprintf('VERDICT: SUSPECT (flat or mostly empty) - crop window probably outside the swath.\n');
    else
        fprintf('VERDICT: plausible content. Confirm by eye: bright speckled city, dark water/tanks.\n');
    end
    figure('Name','crop'); imshow(imadjust(I, stretchlim(I,[0.01 0.99])));
    title('Sentinel-1 crop (1-99% stretch)');
    figure('Name','crop hist'); histogram(D(:), 64); title('crop histogram');
end

%% 2. Toolbox licenses
fprintf('\n--- 2. Licenses ---\n');
lic = {'Phased_Array_System_Toolbox','Neural_Network_Toolbox','Image_Toolbox', ...
       'Signal_Toolbox','Statistics_Toolbox','Distrib_Computing_Toolbox'};
for i = 1:numel(lic)
    fprintf('%-30s checkout=%d\n', lic{i}, license('checkout', lic{i}));
end
v = ver; names = {v.Name};
fprintf('Deep Learning Toolbox installed: %d\n', any(strcmp(names,'Deep Learning Toolbox')));
try
    fprintf('GPU: %s, %.1f GB\n', gpuDevice().Name, gpuDevice().TotalMemory/1e9);
catch ME
    fprintf('GPU unavailable: %s\n', ME.message);
end

%% 3. Gotcha file structure (esp. the af field)
fprintf('\n--- 3. Gotcha structure ---\n');
[files, ~] = gotcha_find(root, 8, 'HH', 1);
if ~isempty(files)
    S = load(files{1});
    fprintf('top-level vars: %s\n', strjoin(fieldnames(S), ', '));
    d = S.data;
    fn = fieldnames(d);
    for i = 1:numel(fn)
        x = d.(fn{i});
        fprintf('  data.%-8s class=%-8s size=%s\n', fn{i}, class(x), mat2str(size(x)));
    end
    if isfield(d, 'af')
        fprintf('\nfields of data.af:\n');
        afn = fieldnames(d.af);
        for i = 1:numel(afn)
            x = d.af.(afn{i});
            if isnumeric(x) && ~isempty(x)
                fprintf('  af.%-12s size=%-10s min=%.4g max=%.4g\n', afn{i}, mat2str(size(x)), min(abs(x(:))), max(abs(x(:))));
            else
                fprintf('  af.%-12s class=%s size=%s\n', afn{i}, class(x), mat2str(size(x)));
            end
        end
    end
end

%% 4. Zips to delete (asks before deleting)
fprintf('\n--- 4. Sentinel-1 zips ---\n');
Z = dir(fullfile(root, '**', 'S1*.zip'));
tot = 0;
for i = 1:numel(Z)
    fprintf('  %s  (%.2f GB)\n', fullfile(Z(i).folder, Z(i).name), Z(i).bytes/1e9);
    tot = tot + Z(i).bytes;
end
if ~isempty(Z)
    a = input(sprintf('Delete these %d zip(s), freeing %.2f GB? (y/N) ', numel(Z), tot/1e9), 's');
    if strcmpi(a, 'y')
        for i = 1:numel(Z), delete(fullfile(Z(i).folder, Z(i).name)); end
        fprintf('deleted.\n');
    end
end
fprintf('\n=== done ===\n');
