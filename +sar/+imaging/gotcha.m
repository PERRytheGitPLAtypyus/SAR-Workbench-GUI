classdef gotcha
    % SAR.IMAGING.GOTCHA  Adapters for AFRL Gotcha volumetric SAR data and image formation
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
            % Form 2D image slice from Gotcha phase history struct G via time-domain backprojection
            if nargin < 2, options = struct(); end
            [img, xv, yv] = bp_gotcha(G, options);
        end

        function stats = pointTargetResolution(img, xv, yv, targetPos)
            % Compute peak height and -3 dB width using exact halfwidth logic of p3b_gotcha_test
            if nargin < 4 || isempty(targetPos)
                % Default to 15TR03C at az 1-3
                targetPos = [-28.09, 38.67];
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
    end
end
