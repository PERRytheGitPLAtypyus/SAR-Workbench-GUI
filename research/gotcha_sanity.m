function ok = gotcha_sanity(G)
% GOTCHA_SANITY  Pre-imaging checks. Returns true only if all hard checks pass.
c = 299792458; ok = true;
K = numel(G.freq); N = size(G.fp,2);
df = mean(diff(G.freq)); fc = mean(G.freq); B = G.freq(end)-G.freq(1);
fprintf('\n=== GOTCHA SANITY ===\n');
fprintf('pulses N=%d, freqs K=%d\n', N, K);
fprintf('fc=%.4f GHz, B=%.1f MHz, df=%.4f MHz\n', fc/1e9, B/1e6, df/1e6);
fprintf('range resolution c/2B   = %.3f m\n', c/(2*B));
fprintf('unambiguous range c/2df = %.1f m  (keep image half-extent well below %.1f m)\n', c/(2*df), c/(4*df));

nn = nnz(~isfinite(G.fp)); fprintf('NaN/Inf in fp: %d  -> %s\n', nn, tf(nn==0)); ok = ok && nn==0;

u = max(abs(diff(G.freq) - df))/df; fprintf('freq uniformity (max rel dev): %.2e -> %s\n', u, tf(u<1e-4)); ok = ok && u<1e-4;

rn = vecnorm(G.pos, 2, 1); e = max(abs(rn - G.r0));
fprintf('|platform pos| vs r0: max diff %.3f m (median r0 %.1f m) -> %s\n', e, median(G.r0), tf(e<1));
if e >= 1, fprintf('   NOTE: scene centre may not be the origin, or r0 includes an offset. Do not image until understood.\n'); ok = false; end

amp = mean(abs(G.fp),1); fprintf('per-pulse mean |fp|: min/median/max = %.3g / %.3g / %.3g\n', min(amp), median(amp), max(amp));
if max(amp)/median(amp) > 10 || min(amp)/median(amp) < 0.1, fprintf('   WARNING: large per-pulse amplitude variation.\n'); end

az = unwrap(atan2(G.pos(2,:), G.pos(1,:)));
dphi = diff(az); mono = all(dphi>0) || all(dphi<0);
fprintf('azimuth sweep: %.3f deg total, monotonic=%d, grazing angle ~ %.1f deg\n', ...
    rad2deg(abs(az(end)-az(1))), mono, rad2deg(asin(median(G.pos(3,:))/median(rn))));
if ~mono, fprintf('   WARNING: pulses not monotonic in azimuth (files out of order?).\n'); end
fprintf('expected cross-range res ~ %.2f m\n', (c/fc)/(2*abs(az(end)-az(1))));

figure('Name','gotcha sanity');
subplot(1,3,1); plot3(G.pos(1,:),G.pos(2,:),G.pos(3,:),'.'); grid on; axis equal; title('platform track');
subplot(1,3,2); imagesc(20*log10(abs(G.fp)+eps)); title('|fp| dB (freq x pulse)'); colorbar;
subplot(1,3,3); plot(rn - G.r0); title('|pos| - r0 (m)');
fprintf('RESULT: %s\n', tf(ok));
end
function s = tf(b), if b, s = 'PASS'; else, s = 'FAIL'; end, end
