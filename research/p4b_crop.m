function Y = p4b_crop(X, crop)
% P4B_CROP  Centre crop of H x H x ... arrays.
c0 = (size(X, 1) - crop) / 2;
Y = X(c0+1 : c0+crop, c0+1 : c0+crop, :, :);
end
