function lgraph = p3b_unet(sz, base)
% P3B_UNET  Small fully convolutional U-Net (3 poolings, 3x3 convs, leaky ReLU), 1 input channel (a real or imaginary
%   part), 1 output channel = log reflectivity u (R = exp(u)).  About 0.5 M parameters at base 16; sz must be divisible by 8.
if nargin < 1, sz = 128; end
if nargin < 2, base = 16; end
c = base * [1 2 4 8];
lgraph = layerGraph(imageInputLayer([sz sz 1], 'Normalization', 'none', 'Name', 'in'));
prev = 'in'; skip = cell(1, 3);
for l = 1:4
    n1 = sprintf('e%da', l); n2 = sprintf('e%db', l);
    lyr = [convolution2dLayer(3, c(l), 'Padding', 'same', 'Name', n1); leakyReluLayer(0.1, 'Name', [n1 '_r']); ...
           convolution2dLayer(3, c(l), 'Padding', 'same', 'Name', n2); leakyReluLayer(0.1, 'Name', [n2 '_r'])];
    lgraph = addLayers(lgraph, lyr); lgraph = connectLayers(lgraph, prev, n1);
    out = [n2 '_r'];
    if l < 4
        pn = sprintf('pool%d', l);
        lgraph = addLayers(lgraph, maxPooling2dLayer(2, 'Stride', 2, 'Name', pn));
        lgraph = connectLayers(lgraph, out, pn); skip{l} = out; prev = pn;
    else
        prev = out;
    end
end
for l = 3:-1:1
    un = sprintf('up%d', l); cn = sprintf('cat%d', l); n1 = sprintf('d%da', l); n2 = sprintf('d%db', l);
    lgraph = addLayers(lgraph, transposedConv2dLayer(2, c(l), 'Stride', 2, 'Name', un));
    lgraph = connectLayers(lgraph, prev, un);
    lgraph = addLayers(lgraph, depthConcatenationLayer(2, 'Name', cn));
    lgraph = connectLayers(lgraph, un, [cn '/in1']); lgraph = connectLayers(lgraph, skip{l}, [cn '/in2']);
    lyr = [convolution2dLayer(3, c(l), 'Padding', 'same', 'Name', n1); leakyReluLayer(0.1, 'Name', [n1 '_r']); ...
           convolution2dLayer(3, c(l), 'Padding', 'same', 'Name', n2); leakyReluLayer(0.1, 'Name', [n2 '_r'])];
    lgraph = addLayers(lgraph, lyr); lgraph = connectLayers(lgraph, cn, n1);
    prev = [n2 '_r'];
end
lgraph = addLayers(lgraph, convolution2dLayer(1, 1, 'Name', 'out'));
lgraph = connectLayers(lgraph, prev, 'out');
end
