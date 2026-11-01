/* Small shared helpers (global, classic script). */
'use strict';

const WRUtils = {
  clamp(v, a, b) { return Math.max(a, Math.min(b, v)); },
  lerp(a, b, t) { return a + (b - a) * t; },
  /* Frame-rate independent exponential approach. */
  damp(a, b, k, dt) { return WRUtils.lerp(a, b, 1 - Math.exp(-k * dt)); },
  rand(a, b) { return a + Math.random() * (b - a); },
  pick(arr) { return arr[(Math.random() * arr.length) | 0]; },
  /* Move `v` toward `target` by at most `step`. */
  approach(v, target, step) {
    if (v < target) return Math.min(v + step, target);
    if (v > target) return Math.max(v - step, target);
    return v;
  }
};

/* "0:12.34" */
function formatTime(t) {
  const m = Math.floor(t / 60);
  const s = t - m * 60;
  return m + ':' + s.toFixed(2).padStart(5, '0');
}
