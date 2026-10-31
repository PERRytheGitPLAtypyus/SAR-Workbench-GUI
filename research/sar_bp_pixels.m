function img = sar_bp_pixels(S, f, th, R0, X, Y, wf, wa, c)
% SAR_BP_PIXELS  Time-domain backprojection for an arbitrary list of pixels.
%   S  : K x N deskewed phase history  (K frequencies, N pulses)
%   f  : K x 1 frequency vector (Hz);  th : 1 x N platform angles (rad)
%   R0 : platform-to-scene-centre range (m);  X,Y : pixel coordinates (m), same size
%   wf : K x 1 frequency window;  wa : 1 x N pulse window;  c : speed of light
% Platform is on a circular arc: position = R0*[cos(th), sin(th)], looking at the origin.
    [~, N] = size(S);
    fc = mean(f);
    rg = -20:0.01:20;                          % fine differential-range grid (m)
    E  = exp(1j*4*pi*((f - fc)*rg)/c);         % K x Nr
    img = zeros(size(X));
    px = R0*cos(th);  py = R0*sin(th);
    for n = 1:N
        rc  = (wf .* S(:,n)).' * E;            % 1 x Nr  range-compressed pulse
        dR  = sqrt((px(n) - X).^2 + (py(n) - Y).^2) - R0;
        val = interp1(rg, rc, dR(:), 'linear', 0);
        val = reshape(val, size(X)) .* exp(1j*4*pi*fc*dR/c);   % remove carrier phase
        img = img + wa(n) * val;
    end
end
