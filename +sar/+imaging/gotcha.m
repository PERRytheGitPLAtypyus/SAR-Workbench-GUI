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
            % Compute peak height and -3 dB width using interpolation
            % Matches the validated reference implementation from run_phase1c / p3b_gotcha_test.
            if nargin < 4 || isempty(targetPos)
                % Default to 15TR03C at az 1-3
                targetPos = [-28.09, 38.67];
            end
            
            A = abs(img);
            [~, ix] = min(abs(xv - targetPos(1)));
            [~, iy] = min(abs(yv - targetPos(2)));
            
            % Local sub-window around target
            dx = mean(diff(xv));
            winR = round(2.0 / dx);
            ry = max(1, iy-winR):min(size(A,1), iy+winR);
            rx = max(1, ix-winR):min(size(A,2), ix+winR);
            
            subA = A(ry, rx);
            [pkVal, maxIdx] = max(subA(:));
            [subY, subX] = ind2sub(size(subA), maxIdx);
            peakY = ry(subY);
            peakX = rx(subX);
            
            % Interpolate profiles for sub-pixel -3 dB width
            h = min(40, min(peakX-1, size(A,2)-peakX));
            cx = peakX-h : peakX+h;
            cy = peakY-h : peakY+h;
            
            xi = linspace(xv(cx(1)), xv(cx(end)), 2001);
            yi = linspace(yv(cy(1)), yv(cy(end)), 2001);
            
            ax = interp1(xv(cx), A(peakY, cx), xi, 'spline');
            ay = interp1(yv(cy), A(cy, peakX).', yi, 'spline');
            
            halfMaxX = pkVal / sqrt(2);
            halfMaxY = pkVal / sqrt(2);
            
            wxIdx = xi(ax >= halfMaxX);
            wyIdx = yi(ay >= halfMaxY);
            
            stats = struct();
            stats.peakValue = pkVal;
            stats.peakPos = [xv(peakX), yv(peakY)];
            stats.offsetMeters = hypot(xv(peakX) - targetPos(1), yv(peakY) - targetPos(2));
            stats.widthX = max(wxIdx) - min(wxIdx);
            stats.widthY = max(wyIdx) - min(wyIdx);
            stats.meanWidth = 0.5 * (stats.widthX + stats.widthY);
        end
    end
end
