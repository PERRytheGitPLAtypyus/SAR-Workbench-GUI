function Y = p4b_filter(X, spec, cfg)
% P4B_FILTER  spec.type: 'raw' | 'boxcar' (intensity mean, window spec.win) | 'lee' | 'frost' | 'gammamap' (window spec.win, L = cfg.L).
%   X: 128x128x1xN amplitude (full chip, so window edge effects stay outside the 88x88 crop).
switch spec.type
    case 'raw',    Y = X;
    case 'boxcar', Y = sqrt(max(convn(X.^2, ones(spec.win) / spec.win^2, 'same'), 0));
    otherwise,     Y = despeckle_filters(X, spec.type, spec.win, cfg.L);
end
end
