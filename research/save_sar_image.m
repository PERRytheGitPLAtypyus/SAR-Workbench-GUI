function save_sar_image(img, x, y, outName, dyn)
% SAVE_SAR_IMAGE  Export any complex/magnitude SAR image as a report-ready PNG (300 dpi).
%   img : rows = y (cross-range), cols = x (range direction);  x, y : axis vectors in metres
%   outName : e.g. 'figures\fig_A6_gotcha_pass8.png';  dyn : dynamic range in dB (default 40)
    if nargin < 5 || isempty(dyn), dyn = 40; end
    a  = abs(img);
    db = 20*log10(a / max(a(:)) + eps);
    fig = figure('Color', 'w', 'Position', [100 100 700 600]);
    imagesc(x, y, db);  axis image;  set(gca, 'YDir', 'normal');  caxis([-dyn 0]);
    colormap(flipud(gray(256)));
    cb = colorbar;  ylabel(cb, 'Normalised intensity (dB)');
    xlabel('Range-direction x (m)');  ylabel('Cross-range y (m)');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12);
    exportgraphics(fig, outName, 'Resolution', 300);
end
