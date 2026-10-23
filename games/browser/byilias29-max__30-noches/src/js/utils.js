/* ==========================================================================
   30 NOCHES - utils.js
   Utilidades matematicas, aleatoriedad reproducible, colisiones y eventos.
   ========================================================================== */
window.TN = window.TN || {};

TN.Utils = (function () {
  const TAU = Math.PI * 2;

  function clamp(v, a, b) { return v < a ? a : (v > b ? b : v); }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function dist(ax, ay, bx, by) { const dx = bx - ax, dy = by - ay; return Math.sqrt(dx * dx + dy * dy); }
  function dist2(ax, ay, bx, by) { const dx = bx - ax, dy = by - ay; return dx * dx + dy * dy; }
  function angleTo(ax, ay, bx, by) { return Math.atan2(by - ay, bx - ax); }
  function lerpAngle(a, b, t) {
    let d = ((b - a + Math.PI) % TAU + TAU) % TAU - Math.PI;
    return a + d * t;
  }
  function sign(v) { return v < 0 ? -1 : 1; }

  /* --- Aleatoriedad reproducible (mulberry32) --------------------------- */
  function mulberry32(seed) {
    let a = seed >>> 0;
    return function () {
      a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function makeRng(seed) {
    const next = mulberry32(seed);
    return {
      next: next,
      range: (a, b) => a + next() * (b - a),
      int: (a, b) => Math.floor(a + next() * (b - a)),
      pick: (arr) => arr[Math.floor(next() * arr.length)],
      chance: (p) => next() < p,
      angle: () => next() * TAU,
      shuffle: (arr) => {
        const a = arr.slice();
        for (let i = a.length - 1; i > 0; i--) {
          const j = Math.floor(next() * (i + 1));
          const tmp = a[i]; a[i] = a[j]; a[j] = tmp;
        }
        return a;
      }
    };
  }

  /* Hash determinista para variaciones de terreno (0..1). */
  function hash2(x, y, seed) {
    let h = (x * 374761393 + y * 668265263 + (seed | 0) * 2147483647) | 0;
    h = (h ^ (h >>> 13)) * 1274126177;
    return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
  }

  /* --- Colisiones ------------------------------------------------------- */
  function circleVsCircle(ax, ay, ar, bx, by, br) {
    const r = ar + br;
    return dist2(ax, ay, bx, by) <= r * r;
  }

  function circleVsRect(cx, cy, cr, rx, ry, rhw, rhh) {
    const nx = clamp(cx, rx - rhw, rx + rhw);
    const ny = clamp(cy, ry - rhh, ry + rhh);
    return dist2(cx, cy, nx, ny) <= cr * cr;
  }

  function rectsOverlap(a, b) {
    return Math.abs(a.x - b.x) * 2 < (a.hw + b.hw) && Math.abs(a.y - b.y) * 2 < (a.hh + b.hh);
  }

  function pointInRect(px, py, r) {
    return px >= r.x - r.hw && px <= r.x + r.hw && py >= r.y - r.hh && py <= r.y + r.hh;
  }

  /* --- Varios ----------------------------------------------------------- */
  function formatTime(sec) {
    sec = Math.max(0, Math.ceil(sec));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m + ':' + (s < 10 ? '0' : '') + s;
  }

  function fmt(n) {
    return Math.round(n).toString();
  }

  function uid(prefix) {
    uid._n = (uid._n || 0) + 1;
    return (prefix || 'id') + '_' + uid._n;
  }

  function deepClone(obj) {
    if (obj === null || typeof obj !== 'object') return obj;
    if (Array.isArray(obj)) return obj.map(deepClone);
    const out = {};
    for (const k in obj) out[k] = deepClone(obj[k]);
    return out;
  }

  /* Emisor de eventos minimalista usado para comunicar modulos. */
  class Emitter {
    constructor() { this._h = {}; }
    on(evt, fn) {
      (this._h[evt] = this._h[evt] || []).push(fn);
      return () => this.off(evt, fn);
    }
    off(evt, fn) {
      const list = this._h[evt];
      if (!list) return;
      const i = list.indexOf(fn);
      if (i !== -1) list.splice(i, 1);
    }
    emit(evt, payload) {
      const list = this._h[evt];
      if (!list) return;
      for (let i = 0; i < list.length; i++) {
        try { list[i](payload); }
        catch (e) { console.error('[TN] error en listener de "' + evt + '"', e); }
      }
    }
    clear() { this._h = {}; }
  }

  /* Aproximacion de circulos a partir de un rectangulo (para colisiones). */
  function rectToCircle(x, y, hw, hh) {
    return { x: x, y: y, r: Math.hypot(hw, hh) };
  }

  return {
    TAU: TAU,
    clamp: clamp,
    lerp: lerp,
    dist: dist,
    dist2: dist2,
    angleTo: angleTo,
    lerpAngle: lerpAngle,
    sign: sign,
    mulberry32: mulberry32,
    makeRng: makeRng,
    hash2: hash2,
    circleVsCircle: circleVsCircle,
    circleVsRect: circleVsRect,
    rectsOverlap: rectsOverlap,
    pointInRect: pointInRect,
    formatTime: formatTime,
    fmt: fmt,
    uid: uid,
    deepClone: deepClone,
    Emitter: Emitter,
    rectToCircle: rectToCircle
  };
})();
