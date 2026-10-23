/* Neon Sudoku — telefon performansı: yavaş cihazda otomatik hafif mod (gölge bulanıklığı kapalı, çözünürlük düşük) */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_PERF) return;
  NS.V1_PERF = true;
  const P = NS.Game.prototype;
  const mobile = /Android|iPhone|iPad|Mobile/i.test(navigator.userAgent || '');
  function lite(g, dpr) {
    if (g.__lite) return; g.__lite = true; NS.LITE = true;
    const c = g.ctx;
    try { Object.defineProperty(c, 'shadowBlur', { get() { return 0; }, set() {}, configurable: true }); } catch (_) {}
    const cv = g.canvas; if (cv) { cv.width = Math.round(540 * dpr); cv.height = Math.round(960 * dpr); c.setTransform(dpr, 0, 0, dpr, 0, 0); }
  }
  const renderPrev = P.render;
  P.render = function () {
    const t = performance.now();
    if (globalThis.NEON_LITE === true) lite(this, 1.25);
    else if (!this.__lite && globalThis.NEON_LITE !== false) {
      if (mobile && !this.__dprSet && this.canvas) { this.__dprSet = true; const d = Math.min(1.6, devicePixelRatio || 1); if (this.canvas.width > 540 * d + 1) { this.canvas.width = Math.round(540 * d); this.canvas.height = Math.round(960 * d); this.ctx.setTransform(d, 0, 0, d, 0, 0); } }
      if (this.__pt) { const dt = t - this.__pt; this.__pa = this.__pa == null ? dt : this.__pa * .95 + dt * .05; this.__pn = (this.__pn || 0) + 1; if (this.__pn > 120 && this.__pa > 24) lite(this, 1.2); }
    }
    this.__pt = t;
    return renderPrev.apply(this, arguments);
  };
})();
