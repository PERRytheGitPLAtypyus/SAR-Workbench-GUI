function pha = simulatePointTargetPhaseHistory(targetPositions, opts)
%SIMULATEPOINTTARGETPHASEHISTORY Generate synthetic spotlight SAR phase
% history for one or more ideal point targets. This is your GROUND TRUTH
% generator: since you command the exact target positions, the
% reconstructed image from backprojection2D.m has a known correct answer
% you can check pixel-for-pixel. Do NOT skip this validation step and
% jump straight to real data - if this doesn't produce clean sharp points
% exactly where you placed them, your backprojection math has a bug that
% will be MUCH harder to spot once real clutter/noise is involved.
%
% INPUTS:
%   targetPositions - Nx2 matrix of [x, y] positions in meters, relative
%                      to scene center. E.g. [0 0; 5 5; -5 -5] for a
%                      center point plus two diagonal offsets.
%   opts (optional struct) with fields:
%       .fc        - center frequency, Hz (default 10e9, X-band)
%       .bw        - bandwidth, Hz (default 640e6, matches Gotcha spec)
%       .numFreq   - number of frequency samples per pulse (default 128)
%       .apertureDeg - total synthetic aperture angle, degrees (default 10)
%       .numAz     - number of azimuth pulses across the aperture (default 128)
%       .standoffM - radar standoff range, meters (default 5000)
%
% OUTPUT: pha struct with fields matching what backprojection2D.m expects:
%   .data   [numFreq x numAz] complex phase history
%   .freq   [numFreq x 1] frequency vector, Hz
%   .az     [1 x numAz] azimuth angles, radians
%   .AntX, .AntY, .AntZ  [1 x numAz] antenna position per pulse, meters
%   .R0     [1 x numAz] range to scene center per pulse, meters

if nargin < 2, opts = struct(); end
fc         = getOpt(opts, 'fc', 10e9);
bw         = getOpt(opts, 'bw', 640e6);
numFreq    = getOpt(opts, 'numFreq', 128);
apertureDeg= getOpt(opts, 'apertureDeg', 10);
numAz      = getOpt(opts, 'numAz', 128);
standoffM  = getOpt(opts, 'standoffM', 5000);

c = physconst('LightSpeed');

freq = linspace(fc - bw/2, fc + bw/2, numFreq).';   % [numFreq x 1]
az = linspace(-apertureDeg/2, apertureDeg/2, numAz) * pi/180;  % radians

% Antenna flies a circular arc at constant standoff range around scene center
AntX = standoffM * sin(az);
AntY = standoffM * cos(az);
AntZ = zeros(1, numAz);
R0   = sqrt(AntX.^2 + AntY.^2 + AntZ.^2);

data = zeros(numFreq, numAz);
for t = 1:size(targetPositions,1)
    tx = targetPositions(t,1);
    ty = targetPositions(t,2);
    tz = 0;
    % Range from each antenna position to this target
    R = sqrt((AntX - tx).^2 + (AntY - ty).^2 + (AntZ - tz).^2);  % [1 x numAz]
    % Phase history: standard SAR model, phase proportional to 2*R*f/c
    % (two-way propagation). Broadcast freq [numFreq x 1] against R [1 x numAz]
    data = data + exp(-1j * 4*pi * freq * R / c);
end

pha.data = data;
pha.freq = freq;
pha.az   = az;
pha.AntX = AntX;
pha.AntY = AntY;
pha.AntZ = AntZ;
pha.R0   = R0;
pha.fc   = fc;
pha.bw   = bw;

fprintf('Simulated phase history: %d targets, %d freq bins, %d pulses, %.1f deg aperture\n', ...
    size(targetPositions,1), numFreq, numAz, apertureDeg);
end

function v = getOpt(opts, field, default)
if isfield(opts, field)
    v = opts.(field);
else
    v = default;
end
end
