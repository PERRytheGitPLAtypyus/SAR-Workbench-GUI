classdef simulate
    % SAR.IMAGING.SIMULATE  Adapters for synthetic spotlight SAR phase history & backprojection
    %   Wraps simulatePointTargetPhaseHistory and backprojection2D.

    methods (Static)
        function pha = targets(targetPositions, options)
            % Generate synthetic spotlight SAR phase history for point targets
            if nargin < 1 || isempty(targetPositions)
                targetPositions = [0 0; 5 5; -5 -5; 5 -5];
            end
            if nargin < 2, options = struct(); end
            pha = simulatePointTargetPhaseHistory(targetPositions, options);
        end

        function [img, xVec, yVec] = backproject(pha, sceneExtentM, numPixels)
            % Image reconstruction via 2D time-domain backprojection
            if nargin < 2 || isempty(sceneExtentM), sceneExtentM = 15; end
            if nargin < 3 || isempty(numPixels), numPixels = 256; end
            [img, xVec, yVec] = backprojection2D(pha, sceneExtentM, numPixels);
        end
    end
end
