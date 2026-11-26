classdef gotcha
    % SAR.IMAGING.GOTCHA  Adapters for AFRL Gotcha planar backprojection (z = -0.3 m)
    %   Wraps gotcha_find, gotcha_load, bp_gotcha, and point-target resolution profiling.

    methods (Static)
        function G = loadAperture(rootDir, passNum, pol, azList)
            % Load Gotcha phase history for specified pass, polarization, and azimuth range
            if nargin < 1 || isempty(rootDir)
                cfg = sar.env.config();
                rootDir = cfg.dataPath.gotcha;
            end
            if nargin < 2 || isempty(passNum), passNum = 8; end
            if nargin < 3 || isempty(pol), pol = 'HH'; end
            if nargin < 4 || isempty(azList), azList = 1:3; end
            
            files = gotcha_find(rootDir, passNum, pol, azList);
            if isempty(files)
                error('sar:gotcha:filesNotFound', 'No Gotcha files found for pass %d, pol %s, az %s in %s', ...
                    passNum, pol, mat2str(azList), rootDir);
            end
            G = gotcha_load(files);
        end

        function [img, xv, yv] = backproject(G, options)
            % Form planar 2D image slice from Gotcha phase history via time-domain backprojection
            if nargin < 2, options = struct(); end
            [img, xv, yv] = bp_gotcha(G, options);
        end

        function [img, xv, yv, wasCancelled] = backprojectWithProgress(G, options, progressFn, cancelFn)
            % Backprojection with interactive progress reporting and cancellation support
            if nargin < 2, options = struct(); end
            if nargin < 3, progressFn = []; end
            if nargin < 4, cancelFn = []; end
            
            c = 299792458;
            d = struct('xlim',[-30 30],'ylim',[-30 30],'dx',0.15,'z',-0.3,'pad',8,'conj',0,'af',0,'afr',0,'afp',0);
            fn = fieldnames(d);
            for i = 1:numel(fn)
                if ~isfield(options, fn{i}), options.(fn{i}) = d.(fn{i}); end
            end
            if options.af ~= 0, options.afr = options.af; options.afp = options.af; end

            K = numel(G.freq); N = size(G.fp, 2);
            df = mean(diff(G.freq)); f0 = G.freq(1);
            M = K * options.pad; dstep = c / (2 * M * df);
            xv = options.xlim(1):options.dx:options.xlim(2);
            yv = options.ylim(1):options.dx:options.ylim(2);
            [X, Y] = meshgrid(xv, yv); Z = options.z * ones(size(X));
            img = zeros(size(X));
            haveAF = ~isempty(G.af_r);
            wasCancelled = false;

            stepUpdate = max(1, round(N / 50));
            for n = 1:N
                if ~isempty(cancelFn) && cancelFn()
                    wasCancelled = true;
                    return;
                end

                s = G.fp(:, n);
                if options.conj, s = conj(s); end
                r0 = G.r0(n);
                if haveAF
                    if options.afr ~= 0, r0 = r0 + options.afr * G.af_r(n); end
                    if options.afp ~= 0, s = s .* exp(1j * options.afp * G.af_ph(n)); end
                end
                prof = fftshift(ifft(s, M)) * M;
                dR = sqrt((X - G.pos(1, n)).^2 + (Y - G.pos(2, n)).^2 + (Z - G.pos(3, n)).^2) - r0;
                idx = dR / dstep + M / 2 + 1;
                ok = idx >= 1 & idx < M;
                i0 = floor(idx); i0(~ok) = 1; fr = idx - i0;
                v = prof(i0) .* (1 - fr) + prof(i0 + 1) .* fr;
                v(~ok) = 0;
                img = img + v .* exp(1j * 4 * pi * f0 / c * dR);

                if ~isempty(progressFn) && (mod(n, stepUpdate) == 0 || n == N)
                    progressFn(n / N);
                end
            end
        end

        function stats = pointTargetResolution(img, xv, yv, targetPos)
            % Compute peak height and -3 dB width using exact halfwidth logic of p3b_gotcha_test
            if nargin < 4 || isempty(targetPos)
                targetPos = [-28.09, 38.67]; % 15TR03C
            end
            
            Q = abs(img).^2; % Intensity
            [~, ix] = min(abs(xv - targetPos(1)));
            [~, iy] = min(abs(yv - targetPos(2)));
            
            dx = mean(diff(xv));
            h = 40;
            cx = max(1, ix-h):min(size(Q,2), ix+h);
            cy = max(1, iy-h):min(size(Q,1), iy+h);
            
            subQ = Q(cy, cx);
            [pkVal, maxIdx] = max(subQ(:));
            [subY, subX] = ind2sub(size(subQ), maxIdx);
            py = cy(subY);
            px = cx(subX);
            
            % Exact halfwidth from research/p3b_gotcha_test.m
            wx = sar.imaging.gotcha.halfwidth(Q(py, cx), px - cx(1) + 1, dx);
            wy = sar.imaging.gotcha.halfwidth(Q(cy, px).', py - cy(1) + 1, dx);
            
            stats = struct();
            stats.peakValue = sqrt(pkVal);
            stats.peakIntensity = pkVal;
            stats.peakPos = [xv(px), yv(py)];
            stats.offsetMeters = hypot(xv(px) - targetPos(1), yv(py) - targetPos(2));
            stats.widthX = wx;
            stats.widthY = wy;
            stats.meanWidth = 0.5 * (wx + wy);
        end

        function w = halfwidth(p, i0, dx)
            % Linear interpolation -3 dB width from research/p3b_gotcha_test.m
            pk = p(i0);
            hlf = pk / 2;
            l = i0;
            r = i0;
            while l > 1 && p(l) > hlf, l = l - 1; end
            while r < numel(p) && p(r) > hlf, r = r + 1; end
            if p(l) > hlf || p(r) > hlf, w = NaN; return; end
            xl = l + (hlf - p(l)) / (p(l+1) - p(l));
            xr = (r - 1) + (p(r-1) - hlf) / (p(r-1) - p(r));
            w = (xr - xl) * dx;
        end

        function [mk, hd, names] = reflectorTable()
            % Known trihedral corner reflector ground truth coordinates and headings
            % from research/p3b_gotcha_test.m and stage 1 surveys
            mk = [ -32.14 42.54; -28.09 38.67; -13.86 37.70; -24.39 32.96; -32.50 33.41; -5.12 22.98;
                   -7.51 51.47; -15.55 42.96; -26.16 45.64; -18.58 33.53; -20.88 27.10; -13.24 32.09;
                   -29.27 24.48; -26.15 17.50 ];
            hd = [180 90 0 270 0 270 180 0 90 90 0 270 0 180].';
            names = {'15TR01W', '15TR03C', '15TR02E', '15TR04S', '15TR05E', '15TR07S', ...
                     '15TR06W', '15TR08E', '15TR09N', '15TR10N', '15TR11E', '15TR12S', ...
                     '15TR13E', '15TR14W'};
        end

        function expHead = expectedHeadingForAperture(azStart, azEnd)
            % Determine matching reflector heading for an aperture look azimuth
            azMid = mod(0.5 * (azStart + azEnd), 360);
            if azMid >= 315 || azMid < 45
                expHead = 90;
            elseif azMid >= 45 && azMid < 135
                expHead = 0;
            elseif azMid >= 135 && azMid < 225
                expHead = 270;
            else
                expHead = 180;
            end
        end

        function [visCount, pairDetails] = findVisibleTargets(aps, rootDir)
            % Detect visible reflector/aperture pairs across test apertures
            % matching research/p3b_gotcha_test.m
            if nargin < 1 || isempty(aps)
                aps = {1:3, 86:88, 176:178, 266:268};
            end
            if nargin < 2 || isempty(rootDir)
                cfg = sar.env.config();
                rootDir = cfg.rootDir;
            end
            
            [mk, hd, names] = sar.imaging.gotcha.reflectorTable();
            expHeads = [90 0 270 180];
            dx = 0.3; winM = 2.0;
            passNum = 8; pol = 'HH';

            visCount = 0;
            pairDetails = struct('aperture', {}, 'targetIdx', {}, 'name', {}, ...
                'pos', {}, 'peakRatioDb', {}, 'widthX', {}, 'widthY', {});

            for a = 1:numel(aps)
                files = gotcha_find(rootDir, passNum, pol, aps{a});
                G = gotcha_load(files);
                o = struct('xlim', [-44 6], 'ylim', [10 58], 'dx', dx, 'z', -0.3, ...
                    'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
                [img, xv, yv] = bp_gotcha(G, o);
                I = abs(img).^2; med = median(I(:));

                for t = find(hd == expHeads(a)).'
                    [~, ix] = min(abs(xv - mk(t,1))); [~, iy] = min(abs(yv - mk(t,2)));
                    w = round(winM / dx);
                    ry = max(1, iy-w):min(size(I,1), iy+w);
                    rx = max(1, ix-w):min(size(I,2), ix+w);
                    [pk, li] = max(reshape(I(ry, rx), [], 1));
                    if 10*log10(pk / med) < 20, continue; end
                    
                    [pyy, pxx] = ind2sub([numel(ry) numel(rx)], li);
                    py = ry(pyy); px = rx(pxx);
                    
                    h = 40; cx = max(1, px-h):min(size(I,2), px+h); cy = max(1, py-h):min(size(I,1), py+h);
                    wx = sar.imaging.gotcha.halfwidth(I(py, cx), px - cx(1) + 1, dx);
                    wy = sar.imaging.gotcha.halfwidth(I(cy, px).', py - cy(1) + 1, dx);

                    visCount = visCount + 1;
                    k = numel(pairDetails) + 1;
                    pairDetails(k).aperture = aps{a};
                    pairDetails(k).targetIdx = t;
                    pairDetails(k).name = names{t};
                    pairDetails(k).pos = [xv(px), yv(py)];
                    pairDetails(k).peakRatioDb = 10*log10(pk / med);
                    pairDetails(k).widthX = wx;
                    pairDetails(k).widthY = wy;
                end
            end
        end
    end
end
