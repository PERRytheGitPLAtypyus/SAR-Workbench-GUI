function [out, info] = apply(inputData, methodId, params)
% SAR.DESPECKLE.APPLY  Adapter for classical and deep MERLIN despeckling
%   [out, info] = sar.despeckle.apply(inputData, methodId, params)
%
%   inputData : H x W (or H x W x 1 x N) array. May be complex (single-look SAR)
%               or real amplitude / intensity.
%   methodId  : 'none' | 'lee' | 'frost' | 'gammamap' | 'merlin_mstar' | 'merlin_gotcha'
%   params    : (optional) struct of algorithm options:
%               .win   - window size for classical filters (default 7)
%               .L     - nominal number of looks (default 1)
%               .scale - amplitude scaling for MERLIN (default: estimated or 1.0)
%               .model - path to custom model mat file
%
%   out       : despeckled amplitude array (same spatial dimensions as input).
%   info      : diagnostic struct containing method details and execution metrics.

if nargin < 2 || isempty(methodId), methodId = 'none'; end
if nargin < 3, params = struct(); end

regAll = sar.registry.despeckle(true);
idx = find(strcmpi({regAll.id}, methodId), 1);
if isempty(idx)
    error('sar:despeckle:unknownMethod', 'Unknown despeckle method "%s".', methodId);
end
methodDef = regAll(idx);

% Check validation status
if strcmp(methodDef.status, 'FAILED_VALIDATION')
    warning('sar:despeckle:failedValidation', ...
        'Method "%s" has status FAILED_VALIDATION: %s', methodDef.name, methodDef.domainNote);
end

isComplex = ~isreal(inputData);
info = struct();
info.methodId = methodDef.id;
info.methodName = methodDef.name;
info.inputType = ternary(isComplex, 'complex', 'amplitude');
info.domainNote = methodDef.domainNote;

t0 = tic;

switch lower(methodDef.id)
    case 'none'
        if isComplex
            out = single(abs(inputData));
        else
            out = single(inputData);
        end
        
    case {'lee', 'frost', 'gammamap'}
        % Classical filters operate on AMPLITUDE images
        if isComplex
            amp = single(abs(inputData));
        else
            amp = single(inputData);
        end
        
        win = getParam(params, 'win', methodDef.params.win);
        L = getParam(params, 'L', methodDef.params.L);
        
        out = despeckle_filters(amp, methodDef.id, win, L);
        
    case {'merlin_mstar', 'merlin_gotcha'}
        % MERLIN strictly requires COMPLEX single-look input
        if ~isComplex
            error('sar:despeckle:invalidInputType', ...
                ['MERLIN requires COMPLEX single-look SAR imagery (H x W >= 128x128). ' ...
                 'Detected real amplitude input (e.g. Sentinel-1 GRD). ' ...
                 'Operation is disabled in accordance with scientific boundaries.']);
        end
        
        [H, W, ~, N] = size(inputData);
        if H < 128 || W < 128
            error('sar:despeckle:dimensionTooSmall', ...
                'MERLIN requires input dimensions at least 128 x 128 pixels. Got %d x %d.', H, W);
        end
        
        % Load model
        cfg = sar.env.config();
        defaultModel = fullfile(cfg.rootDir, methodDef.params.model);
        modelPath = getParam(params, 'model', defaultModel);
        if ~exist(modelPath, 'file')
            error('sar:despeckle:modelNotFound', 'MERLIN model file not found: %s', modelPath);
        end
        
        loaded = load(modelPath, 'net', 's');
        net = loaded.net;
        defaultScale = ternary(isfield(loaded, 's'), loaded.s, single(1));
        scale = getParam(params, 'scale', defaultScale);
        
        if N == 1
            R = p3b_denoise(net, inputData(:,:,1,1), scale);
            out = sqrt(max(R, 0));
        else
            out = zeros(H, W, 1, N, 'single');
            for i = 1:N
                R = p3b_denoise(net, inputData(:,:,1,i), scale);
                out(:,:,1,i) = sqrt(max(R, 0));
            end
        end
        
    otherwise
        error('sar:despeckle:unhandled', 'Unhandled method ID "%s".', methodDef.id);
end

info.elapsedSeconds = toc(t0);
end

function val = getParam(s, field, defaultVal)
if isfield(s, field) && ~isempty(s.(field))
    val = s.(field);
else
    val = defaultVal;
end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
