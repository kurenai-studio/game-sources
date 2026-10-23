/* Neon Sudoku — tuşa basma efekti (V1.46): basılı kararma, kor kıvılcımları, kenar parlaması ve yeni tık sesi */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_DOKUNUS) return;
  NS.V1_DOKUNUS = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const PR = [];
  let lastTap = 0;

  function rr(c, x, y, w, h, r) { r = Math.min(r, w / 2, h / 2); c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); }

  /* ses: tok bir "tunk" + metalik çınlama + kor çıtırtısı */
  function tone(ac, dst, t, d, type, f0, f1, pk) { const o = ac.createOscillator(), e = ac.createGain(); o.type = type; o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(f1, t + d); e.gain.setValueAtTime(0, t); e.gain.linearRampToValueAtTime(pk, t + .004); e.gain.exponentialRampToValueAtTime(.001, t + d); o.connect(e); e.connect(dst); o.start(t); o.stop(t + d + .03); }
  let NB = null;
  function crackle(ac, dst, t, d, f, pk) { if (!NB || NB.sampleRate !== ac.sampleRate) { NB = ac.createBuffer(1, ac.sampleRate * .2 | 0, ac.sampleRate); const x = NB.getChannelData(0); for (let i = 0; i < x.length; i++) x[i] = Math.random() * 2 - 1; } const s = ac.createBufferSource(), fl = ac.createBiquadFilter(), e = ac.createGain(); s.buffer = NB; fl.type = 'bandpass'; fl.frequency.value = f; fl.Q.value = 1.4; e.gain.setValueAtTime(pk, t); e.gain.exponentialRampToValueAtTime(.001, t + d); s.connect(fl); fl.connect(e); e.connect(dst); s.start(t); s.stop(t + d + .02); }
  function tapSound(g, small) {
    const ac = g.audio; if (!ac || g.record.muted) return;
    const dst = g.fxGain || g.master || ac.destination, t = ac.currentTime + .005, v = .9 + Math.random() * .2;
    if (small) {
      tone(ac, dst, t, .07, 'sine', 420 * v, 190, .22);
      tone(ac, dst, t, .045, 'triangle', 2400 * v, 1900, .07);
      crackle(ac, dst, t, .035, 4200, .12);
    } else {
      tone(ac, dst, t, .16, 'sine', 190 * v, 62, .5);
      tone(ac, dst, t, .05, 'square', 95, 60, .07);
      tone(ac, dst, t, .22, 'triangle', 1760 * v, 1650, .09);
      tone(ac, dst, t, .14, 'sine', 2640 * v, 2580, .05);
      crackle(ac, dst, t, .06, 3200, .2);
      crackle(ac, dst, t + .05, .05, 5200, .08);
    }
  }

  const inputPrev = P.input;
  P.input = function (x, y) {
    const h = !this.__cine && this.hits && this.hits.find(a => x >= a.x && x <= a.x + a.w && y >= a.y && y <= a.y + a.h);
    if (h) {
      const small = h.w < 140 && h.h < 140;
      PR.push({ x: h.x, y: h.y, w: h.w, h: h.h, tx: x, ty: y, t0: now(), small, seed: Math.random() * 1e9 | 0 });
      if (PR.length > 5) PR.shift();
      lastTap = now();
      this.ensureAudio && this.ensureAudio();
      try { tapSound(this, small); } catch (_) {}
    }
    return inputPrev.apply(this, arguments);
  };
  /* eski ince "select" bip sesini tık sesiyle çakışmasın diye bastır */
  const sfxPrev = P.sfx;
  P.sfx = function (kind) {
    if (kind === 'select' && now() - lastTap < .15) return;
    return sfxPrev.apply(this, arguments);
  };

  const renderPrev = P.render;
  P.render = function () {
    const r = renderPrev.apply(this, arguments);
    if (!PR.length || this.__cine) return r;
    const c = this.ctx, T = now(), d = this.canvas.width / 540, lite = NS.LITE;
    c.save(); c.setTransform(d, 0, 0, d, 0, 0); c.shadowBlur = 0;
    for (let i = PR.length - 1; i >= 0; i--) {
      const p = PR[i], a = T - p.t0;
      if (a > .5) { PR.splice(i, 1); continue; }
      const rad = p.small ? 12 : 18;
      /* 1) basılma: kısa kararma (tuş içe gömülür) */
      if (a < .12) { c.globalAlpha = .32 * (1 - a / .12); c.fillStyle = '#000'; rr(c, p.x + 3, p.y + 3, p.w - 6, p.h - 6, rad); c.fill(); }
      c.globalCompositeOperation = 'lighter';
      /* 2) kenarda kor parlaması */
      const e1 = Math.min(1, a / .28);
      if (e1 < 1) { c.globalAlpha = .85 * (1 - e1); c.strokeStyle = '#ffb054'; c.lineWidth = 3; rr(c, p.x + 2, p.y + 2, p.w - 4, p.h - 4, rad); c.stroke(); }
      /* 3) dışa yayılan ince halka */
      const e2 = Math.min(1, a / .38), inf = 16 * (1 - Math.pow(1 - e2, 3));
      if (e2 < 1) { c.globalAlpha = .55 * (1 - e2); c.strokeStyle = '#ffd48a'; c.lineWidth = 2; rr(c, p.x - inf, p.y - inf, p.w + inf * 2, p.h + inf * 2, rad + inf); c.stroke(); }
      /* 4) dokunulan noktada sıcak parıltı */
      if (a < .22) { const gr = c.createRadialGradient(p.tx, p.ty, 0, p.tx, p.ty, 46); gr.addColorStop(0, 'rgba(255,190,110,' + (.45 * (1 - a / .22)) + ')'); gr.addColorStop(1, 'rgba(255,120,40,0)'); c.globalAlpha = 1; c.fillStyle = gr; c.fillRect(p.tx - 46, p.ty - 46, 92, 92); }
      /* 5) kor kıvılcımları */
      let s = p.seed >>> 0; const rnd = () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296;
      const n = lite ? 7 : (p.small ? 9 : 14);
      for (let k = 0; k < n; k++) {
        const an = -Math.PI / 2 + (rnd() - .5) * 2.6, v = 90 + rnd() * 190, life = .3 + rnd() * .2;
        if (a > life) continue;
        const q = a / life, px = p.tx + Math.cos(an) * v * a, py = p.ty + Math.sin(an) * v * a + 420 * a * a, sz = (2.2 + rnd() * 2.8) * (1 - q * .6);
        c.globalAlpha = 1 - q; c.fillStyle = rnd() < .35 ? '#fff1c4' : (rnd() < .5 ? '#ffb347' : '#ff7a2a');
        c.fillRect(px - sz / 2, py - sz / 2, sz, sz);
      }
      c.globalCompositeOperation = 'source-over';
    }
    c.restore();
    return r;
  };
})();
