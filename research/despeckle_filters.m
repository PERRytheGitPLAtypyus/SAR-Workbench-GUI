function Y = despeckle_filters(A, method, win, L)
% DESPECKLE_FILTERS  Classical adaptive speckle filters for AMPLITUDE images.
%   Y = despeckle_filters(A, 'lee' | 'frost' | 'gammamap', win, L)
%   A    any H x W x ... array of amplitudes (e.g. H x W x 1 x N). Filtering is done on intensity
%        I = A.^2 and the result is returned as amplitude sqrt(I_hat).
%   win  odd box size for the local statistics (default 7); borders are replicated.
%   L    equivalent number of looks of the speckle, intensity CV^2 = 1/L (default 1).
%   Processes at most 400 slices (4th dimension) at a time to bound memory.
%   Formulas: Lee (1980), Frost (1982, damping K = 1), Gamma-MAP (Lopes et al. 1990), all for the
%   multiplicative speckle model on intensity.
if nargin < 3 || isempty(win), win = 7; end
if nargin < 4 || isempty(L), L = 1; end
Y = zeros(size(A), 'like', single(A));
n4 = size(A, 4);
for s = 1:400:n4
    j = s:min(s+399, n4);
    Y(:,:,:,j) = filt(A(:,:,:,j), lower(method), win, L);
end
end

function Y = filt(A, method, win, L)
h = floor(win/2); H = size(A,1); W = size(A,2);
I = single(A).^2;
Ip = I([ones(1,h) 1:H H*ones(1,h)], [ones(1,h) 1:W W*ones(1,h)], :, :);   % replicate borders
k = ones(win, win, 'single') / win^2;
mu  = convn(Ip, k, 'valid');
mu2 = convn(Ip.^2, k, 'valid');
v   = max(mu2 - mu.^2, 0);
Ci2 = v ./ max(mu.^2, eps('single'));          % local squared coefficient of variation
Cu2 = single(1 / L);                           % speckle squared coefficient of variation
switch method
    case 'lee'
        Wt = max(0, 1 - Cu2 ./ max(Ci2, eps('single')));
        Ih = mu + Wt .* (I - mu);
    case 'gammamap'
        Ih = I;                                % Ci >= sqrt(2)*Cu : keep the pixel
        low = Ci2 <= Cu2;                      % homogeneous : local mean
        mid = Ci2 > Cu2 & Ci2 < 2*Cu2;         % between : MAP estimate
        alpha = (1 + Cu2) ./ max(Ci2 - Cu2, eps('single'));
        t = alpha - L - 1;
        Imap = (t .* mu + sqrt((t .* mu).^2 + 4 * alpha * L .* mu .* I)) ./ (2 * alpha);
        Ih(mid) = Imap(mid);
        Ih(low) = mu(low);
    case 'frost'
        K = 1;
        num = zeros(size(I), 'single'); den = num;
        for dy = -h:h
            for dx = -h:h
                w = exp(-K * Ci2 * sqrt(dx^2 + dy^2));
                num = num + w .* Ip(h+1+dy : h+dy+H, h+1+dx : h+dx+W, :, :);
                den = den + w;
            end
        end
        Ih = num ./ den;
    otherwise
        error('despeckle_filters: unknown method "%s"', method);
end
Y = sqrt(max(Ih, 0));
end
