function [img, xVec, yVec] = backprojection2D(pha, sceneExtentM, numPixels)
%BACKPROJECTION2D Time-domain backprojection SAR image formation.
% Implements the standard backprojection algorithm (Pu et al. 2019 /
% Gorham & Moore reference formulation): for every output pixel, sum the
% phase-corrected contribution from every pulse. Slow (O(N_pixels *
% N_pulses)) but exact and the standard reference algorithm - correctness
% over speed for Stage 1. Optimize with Parallel Computing Toolbox later
% ONLY after this version is validated correct.
%
% INPUTS:
%   pha - phase history struct with fields .data, .freq, .AntX, .AntY, .AntZ
%         (matches output of simulatePointTargetPhaseHistory.m; Gotcha
%         loader must be reshaped to this same struct before calling this)
%   sceneExtentM - scalar, half-width of square scene to reconstruct, meters
%                  (e.g. 20 means image spans -20 to +20 in x and y)
%   numPixels - scalar, output image is numPixels x numPixels
%
% OUTPUT:
%   img  - [numPixels x numPixels] complex reconstructed image
%   xVec, yVec - pixel grid coordinate vectors, meters
%
% VALIDATION CHECKPOINT (do this before trusting this function on real data):
%   pha = simulatePointTargetPhaseHistory([0 0]);
%   img = backprojection2D(pha, 20, 256);
%   imagesc(abs(img)); axis image;
%   -> Must show ONE sharp bright point at the exact image center.
%      If it's smeared, off-center, or shows multiple ghosts, STOP and
%      debug this function before proceeding to real Gotcha data.

c = physconst('LightSpeed');

xVec = linspace(-sceneExtentM, sceneExtentM, numPixels);
yVec = linspace(-sceneExtentM, sceneExtentM, numPixels);
[Xg, Yg] = meshgrid(xVec, yVec);

numAz = size(pha.data, 2);
numFreq = size(pha.data, 1);

% Convert frequency-domain phase history to range-compressed pulses via IFFT
% This gives us range profiles we can interpolate against for each pixel.
rangeProfile = fftshift(ifft(pha.data, [], 1), 1);   % [numFreq x numAz]

% Range axis for the compressed profile
fs = mean(diff(pha.freq)) * numFreq;   % effective sample rate from freq spacing
rangeAxis = (-numFreq/2 : numFreq/2-1) * (c / (2*fs));

img = zeros(numPixels, numPixels);

fprintf('Backprojecting %d x %d pixels over %d pulses...\n', numPixels, numPixels, numAz);
tic;
for p = 1:numAz
    % Range from this antenna position to every pixel in the scene
    R = sqrt((Xg - pha.AntX(p)).^2 + (Yg - pha.AntY(p)).^2 + (0 - pha.AntZ(p)).^2);

    % Interpolate the range-compressed pulse at each pixel's exact range
    % (this is the "backprojection" step: project the 1D range profile
    % back into the 2D scene along the radar-to-pixel range)
    contribution = interp1(rangeAxis, rangeProfile(:,p), R, 'linear', 0);

    % Phase correction to coherently sum contributions across pulses
    phaseCorrection = exp(1j * 4*pi * pha.fc * R / c);

    img = img + contribution .* phaseCorrection;

    if mod(p, max(1,round(numAz/10))) == 0
        fprintf('  %.0f%% done\n', 100*p/numAz);
    end
end
elapsed = toc;
fprintf('Backprojection complete in %.1f seconds.\n', elapsed);

end
