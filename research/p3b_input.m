function y = p3b_input(x)
% P3B_INPUT  Signed log compression of the (scaled) real or imaginary part: keeps clutter-level values roughly linear and
%   tames the dynamic range of bright scatterers. The loss target stays linear.
y = sign(x) .* log1p(abs(x));
end
