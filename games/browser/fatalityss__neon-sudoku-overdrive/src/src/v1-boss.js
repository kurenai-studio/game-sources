/* Neon Sudoku — boss silahları: her boss süre çubuğuna kendi silahıyla saldırır ve süreyi kısaltır */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_BOSS) return;
  NS.V1_BOSS = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const IM = {};
  const img = n => { if (!IM[n]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[n]) || 'media/' + n; IM[n] = i; } return IM[n]; };
  const ok = i => i && i.complete && i.naturalWidth > 0;
  const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
  const ease = p => 1 - Math.pow(1 - p, 3);
  const BAR = { x: 70, y: 160, w: 400 };
  /* Boss sırası: KOR, PRİZMA, MUHAFIZ, AKI, NÖBETÇİ, TUTULMA, SARMAL, NEON ÇEKİRDEK */
  const SILAH = [
    { ad: 'Alev nefesi', tur: 'nefes', resim: 'alev-jet-1.webp', ton: 0, sn: 1, ses: 'alev' },
    { ad: 'Kristal yağmuru', tur: 'firlat', resim: 'silah-kristal.webp', sn: 1, ses: 'kristal' },
    { ad: 'Dev balta', tur: 'vur', resim: 'silah-balta.webp', sn: 2, ses: 'balta' },
    { ad: 'Buz nefesi', tur: 'nefes', resim: 'alev-jet-3.webp', ton: 0, buz: true, sn: 1.5, ses: 'buz' },
    { ad: 'Keskin nişancı', tur: 'nisan', resim: 'silah-tufek.webp', sn: 1, ses: 'tufek' },
    { ad: 'Boşluk küresi', tur: 'emme', resim: 'silah-kure.webp', sn: 1.5, ses: 'bosluk' },
    { ad: 'Lazer kolu', tur: 'lazer', resim: 'silah-kol.webp', sn: 1.5, ses: 'lazer' },
    { ad: 'Lanetli kılıç', tur: 'kes', resim: 'silah-kilic.webp', sn: 2, ses: 'kilic' }
  ];
  NS.SILAH = SILAH;
  /* Boss isimleri */
  const ISIM = ['PİROKS', 'KRİSTALİA', 'GORAK', 'BUZDİŞ', 'ZETA', 'NYX', 'RAX', 'VOLTAR'];
  const UNVAN = ['Alev Ejderi', 'Kristal Kraliçe', 'Altın Baltalı Muhafız', 'Buz Yılanı', 'Keskin Nişancı', 'Boşluk Anası', 'Lazer Kollu Titan', 'Lanetli Kral'];
  if (NS.bosses) NS.bosses.forEach((b, i) => { if (ISIM[i]) { b.eski = b.name; b.name = ISIM[i]; b.unvan = UNVAN[i]; } });
  if (NS.levels) NS.levels.forEach(l => { if (l.boss && ISIM[l.goal]) { l.title = ISIM[l.goal]; if (l.bossMechanic) l.bossMechanic.name = ISIM[l.goal]; } });
  NS.BOSS_ISIM = ISIM; NS.BOSS_UNVAN = UNVAN;

  /* ---------- Sentez sesler ---------- */
  function noise(ac, d) { const b = ac.createBuffer(1, ac.sampleRate * d | 0, ac.sampleRate), x = b.getChannelData(0); for (let i = 0; i < x.length; i++) x[i] = Math.random() * 2 - 1; const s = ac.createBufferSource(); s.buffer = b; return s; }
  function env(ac, t, a, d, peak) { const g = ac.createGain(); g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(peak, t + a); g.gain.exponentialRampToValueAtTime(.001, t + a + d); return g; }
  function play(g, name, faz) {
    const ac = g.audio; if (!ac || g.record.muted) return;
    const t = ac.currentTime + .01, out = ac.createGain(); out.gain.value = .5; out.connect(ac.destination);
    const nz = (d, type, f0, f1, q, a, dd, pk) => { const n = noise(ac, d), f = ac.createBiquadFilter(); f.type = type; f.Q.value = q; f.frequency.setValueAtTime(f0, t); f.frequency.exponentialRampToValueAtTime(f1, t + d); const e = env(ac, t, a, dd, pk); n.connect(f); f.connect(e); e.connect(out); n.start(t); };
    const tone = (type, f0, f1, a, d, pk, dt = 0) => { const o = ac.createOscillator(); o.type = type; o.frequency.setValueAtTime(f0, t + dt); o.frequency.exponentialRampToValueAtTime(f1, t + dt + a + d); const e = env(ac, t + dt, a, d, pk); o.connect(e); e.connect(out); o.start(t + dt); o.stop(t + dt + a + d + .05); };
    if (faz === 'hazir') { tone('sawtooth', 90, 180, .4, .5, .18); nz(.9, 'bandpass', 300, 1800, 3, .5, .4, .25); return; }
    switch (name) {
      case 'alev': nz(1.2, 'lowpass', 600, 2400, 1, .08, 1.1, .9); tone('sawtooth', 70, 45, .05, .9, .3); break;
      case 'buz': nz(1.1, 'highpass', 5000, 1500, 1, .05, 1, .7); for (let k = 0; k < 6; k++) tone('sine', 2200 + k * 330, 1800, .005, .25, .12, .1 + k * .07); break;
      case 'balta': nz(.3, 'bandpass', 1200, 300, 2, .2, .1, .5); tone('square', 120, 40, .002, .5, .7, .28); tone('triangle', 2400, 1800, .002, .6, .2, .28); nz(.5, 'lowpass', 800, 100, 1, .28, .5, .9); break;
      case 'kristal': for (let k = 0; k < 7; k++) tone('triangle', 2600 + Math.random() * 1500, 1200, .002, .35, .2, k * .06); break;
      case 'tufek': tone('square', 1500, 1500, .002, .4, .05); nz(.4, 'lowpass', 4000, 200, 1, .002, .35, 1, .45); tone('sine', 90, 30, .45, .4, .8); break;
      case 'bosluk': tone('sine', 300, 30, .1, 1.2, .6); nz(1.3, 'bandpass', 2000, 100, 6, .3, 1, .5); break;
      case 'lazer': tone('sawtooth', 300, 1400, .4, .1, .25); tone('square', 880, 220, .02, .9, .35, .45); nz(.8, 'highpass', 3000, 6000, 1, .45, .6, .3); break;
      case 'kilic': nz(.35, 'bandpass', 600, 6000, 4, .25, .1, .6); tone('triangle', 3200, 2400, .002, .9, .25, .32); tone('sine', 5100, 4800, .002, .7, .12, .32); break;
    }
  }

  /* ---------- Tetikleme ---------- */
  const updPrev = P.update;
  P.update = function (dt) {
    const had = this.attack > 0;
    const r = updPrev.apply(this, arguments);
    if (this.cfg && this.cfg.boss && !had && this.attack > 0) { this.__bw = { t0: now(), dur: this.attack, i: this.cfg.goal | 0 }; play(this, '', 'hazir'); }
    if (had && this.attack <= 0 && this.__bw && !this.__bw.hit) this.__bw = null; /* engellendi */
    return r;
  };
  const impPrev = P.bossImpact;
  P.bossImpact = function () {
    const before = this.time, r = impPrev.apply(this, arguments);
    const i = (this.cfg && this.cfg.goal) | 0, s = SILAH[i];
    if (globalThis.NEON_BOSS_SURE !== false) { const already = before - this.time, extra = Math.max(0, s.sn - already); this.time = Math.max(0, this.time - extra); }
    this.__bw = { t0: now(), i, hit: now(), from: before / NS_T(this), to: this.time / NS_T(this) };
    play(this, s.ses);
    if (navigator.vibrate) try { navigator.vibrate([60, 40, 120]); } catch (_) {}
    return r;
  };
  const blkPrev = P.blockBossAttack;
  P.blockBossAttack = function () { const r = blkPrev.apply(this, arguments); if (this.__bw && !this.__bw.hit) this.__bw.blocked = now(); return r; };

  /* ---------- Çizim ---------- */
  function drawImg(c, im, x, y, w, rot, a, comp, flip) { if (!ok(im)) return; const h = w * im.naturalHeight / im.naturalWidth; c.save(); c.globalAlpha = a == null ? 1 : a; c.globalCompositeOperation = comp || 'screen'; c.translate(x, y); c.rotate(rot || 0); if (flip) c.scale(-1, 1); c.drawImage(im, -w / 2, -h / 2, w, h); c.restore(); }
  function glow(c, x, y, r, col) { const g = c.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, col); g.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = g; c.fillRect(x - r, y - r, r * 2, r * 2); }

  function windup(g, k, p, t) {
    const c = g.ctx, s = SILAH[k.i], im = img(s.resim), bx = BAR.x + BAR.w * clamp(g.time / NS_T(g)), by = BAR.y, still = g.record.reduced;
    c.save(); c.globalAlpha = 1; c.globalCompositeOperation = 'source-over'; c.filter = 'none'; c.shadowBlur = 0;
    switch (s.tur) {
      case 'nefes': { const W = 120 + 60 * p; c.save(); c.translate(560 - 40 * ease(p), by - 70 + 20 * p); c.rotate(Math.PI + .35); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .35 + .4 * p; if (ok(im)) c.drawImage(im, 0, -W * .15, W * p * .6, W * .3); c.restore(); glow(c, 540, by - 70, 40 + 20 * p, s.buz ? 'rgba(140,220,255,.5)' : 'rgba(255,140,40,.5)'); break; }
      case 'firlat': for (let j = 0; j < 3; j++) drawImg(c, im, 350 + j * 30 - 30 * p, 90 + j * 10 + Math.sin(t * 6 + j) * 4, 46, -.4 + j * .3 + t * 2 * p, .6 + .4 * p); break;
      case 'vur': drawImg(c, im, bx + 30, by - 70 - 20 * p, 130, -1.2 - .5 * p + Math.sin(t * 10) * .03 * p, .9); break;
      case 'nisan': { drawImg(c, im, 372, 92, 112, -.15, 1, 0, 1); c.strokeStyle = 'rgba(255,40,40,' + (.4 + .4 * p) + ')'; c.lineWidth = 1.2; c.beginPath(); c.moveTo(335, 98); c.lineTo(bx, by); c.stroke(); const r = 14 - 6 * p; c.strokeStyle = '#ff3b3b'; c.lineWidth = 2; c.beginPath(); c.arc(bx, by, r, 0, Math.PI * 2); c.moveTo(bx - r - 5, by); c.lineTo(bx + r + 5, by); c.moveTo(bx, by - r - 5); c.lineTo(bx, by + r + 5); c.stroke(); break; }
      case 'emme': { drawImg(c, im, bx, by - 70 + 10 * Math.sin(t * 2), 70 + 40 * p, t * .8, .9, 'lighter'); if (!still) for (let j = 0; j < 10; j++) { const a = j / 10 * Math.PI * 2 + t * 3, d = 60 * (1 - (t * 1.5 + j * .1) % 1); c.fillStyle = 'rgba(200,160,255,.7)'; c.fillRect(bx + Math.cos(a) * d, by - 70 + Math.sin(a) * d * .5, 2, 2); } break; }
      case 'lazer': { drawImg(c, im, 372, 92, 118, -.2, 1, 0, 1); glow(c, 330, 98, 14 + 26 * p + (still ? 0 : 4 * Math.sin(t * 20)), 'rgba(255,60,90,.8)'); break; }
      case 'kes': drawImg(c, im, BAR.x + 60, by - 60, 130, -.2 - .3 * p + Math.sin(t * 5) * .04, .95); break;
    }
    if (!still) { c.globalAlpha = .25 + .2 * Math.sin(t * 8); c.strokeStyle = '#ff4d5e'; c.lineWidth = 3; c.strokeRect(6, 126, 528, 68); }
    c.globalAlpha = 1; c.font = '800 13px Oxanium, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#ffd2d8'; c.fillText('⚠ ' + s.ad.toUpperCase() + ' GELİYOR', 270, 118);
    c.restore();
  }
  function impact(g, k, e, t) {
    const c = g.ctx, s = SILAH[k.i], im = img(s.resim), q = clamp(e / 1.1), still = g.record.reduced;
    const x1 = BAR.x + BAR.w * k.from, x0 = BAR.x + BAR.w * k.to, y = BAR.y;
    c.save(); c.globalAlpha = 1; c.globalCompositeOperation = 'source-over'; c.filter = 'none'; c.shadowBlur = 0;
    /* kopan süre parçası */
    c.globalAlpha = 1 - q; c.fillStyle = '#ffe6a8'; c.save(); c.translate((x0 + x1) / 2 + 20 * q, y + 60 * q * q); c.rotate(q * 1.5); c.fillRect(-(x1 - x0) / 2, -6, Math.max(6, x1 - x0), 12); c.restore();
    c.globalAlpha = 1;
    switch (s.tur) {
      case 'nefes': { c.save(); c.translate(560, y); c.rotate(Math.PI); c.globalCompositeOperation = 'lighter'; c.globalAlpha = 1 - q * .8; if (ok(im)) { c.drawImage(im, 0, -55, 600 * ease(clamp(q * 2.5)), 110); c.drawImage(im, 0, -40, 560 * ease(clamp(q * 2.5)), 80); } c.restore(); if (s.buz) { c.globalAlpha = .55 * (1 - q * .6); c.fillStyle = '#bfefff'; c.fillRect(BAR.x - 60, y - 14, BAR.w + 120, 28); } break; }
      case 'firlat': for (let j = 0; j < 6; j++) { const a = clamp(q * 2 - j * .1); drawImg(c, im, 480 - (480 - x0 - j * 12) * ease(a), 60 + (y - 60) * ease(a), 28, a * 6, 1 - clamp((q - .6) / .4)); } break;
      case 'vur': drawImg(c, im, x0 + 40, y - 30 + 20 * ease(clamp(q * 4)), 150, -.2 + .1 * Math.sin(q * 30) * (1 - q), 1 - clamp((q - .6) / .4)); break;
      case 'nisan': drawImg(c, im, 372 + 14 * (1 - clamp(q * 5)), 92, 112, -.15, 1 - clamp((q - .6) / .4), 0, 1); c.globalCompositeOperation = 'lighter'; glow(c, 330, 92, 40 * (1 - q), 'rgba(160,255,120,.9)'); c.strokeStyle = 'rgba(200,255,160,' + (1 - q) + ')'; c.lineWidth = 5 * (1 - q) + 1; c.beginPath(); c.moveTo(398, 92); c.lineTo(x0, y); c.stroke(); for (let j = 0; j < 10; j++) { const a = j * .63, d = 70 * ease(q); c.fillStyle = 'rgba(200,255,160,' + (1 - q) + ')'; c.fillRect(x0 + Math.cos(a) * d, y + Math.sin(a) * d * .6, 3, 3); } break;
      case 'emme': drawImg(c, im, x0, y - 30 * (1 - q), 110 * (1 - q * .7), t * 4, 1 - q, 'lighter'); break;
      case 'lazer': c.globalCompositeOperation = 'lighter'; c.strokeStyle = 'rgba(255,60,90,' + (1 - q) + ')'; c.lineWidth = 12 * (1 - q) + 2; c.beginPath(); c.moveTo(330, 98); c.lineTo(x0, y); c.stroke(); c.strokeStyle = 'rgba(255,255,255,' + (1 - q) + ')'; c.lineWidth = 3; c.stroke(); break;
      case 'kes': { drawImg(c, im, BAR.x + BAR.w * ease(clamp(q * 3)), y - 30, 140, 1.2, 1 - clamp((q - .5) / .5)); c.globalCompositeOperation = 'lighter'; c.strokeStyle = 'rgba(255,240,200,' + (1 - q) + ')'; c.lineWidth = 8 * (1 - q) + 2; c.shadowColor = '#ffe08a'; c.shadowBlur = 20; c.beginPath(); c.moveTo(BAR.x - 20, y + 10); c.lineTo(BAR.x + BAR.w * ease(clamp(q * 3)), y - 8); c.stroke(); break; }
    }
    c.globalCompositeOperation = 'lighter'; glow(c, x0, y, 130 * (1 - q) + 10, 'rgba(255,230,190,' + (.9 * (1 - q)) + ')');
    c.globalCompositeOperation = 'source-over'; c.globalAlpha = clamp(1 - (q - .5) / .5); c.font = '800 20px Oxanium, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#ff5a6e'; c.shadowColor = '#ff2a3a'; c.shadowBlur = 12;
    c.fillText('−' + String(+(k.from * 30 - k.to * 30).toFixed(1)).replace('.', ',') + ' SN', x0, y - 26 - 20 * q);
    c.restore();
  }
  const renderPrev = P.render;
  P.render = function () {
    const k = this.__bw, t = now();
    let shake = 0; if (k && k.hit && !this.record.reduced) shake = Math.max(0, 1 - (t - k.hit) * 4) * 8;
    const c = this.ctx;
    if (shake) { c.save(); c.translate(Math.sin(t * 90) * shake, Math.cos(t * 70) * shake * .6); }
    const r = renderPrev.apply(this, arguments);
    if (shake) c.restore();
    if (!k || !this.cfg || !this.cfg.boss || !['playing', 'chain', 'timeout'].includes(this.state)) { if (k && this.state !== 'playing') this.__bw = null; return r; }
    if (k.hit) { const e = t - k.hit; if (e > 1.1) this.__bw = null; else impact(this, k, e, t); }
    else if (k.blocked) { const e = t - k.blocked; if (e > .5) this.__bw = null; else { const im = img(SILAH[k.i].resim); drawImg(c, im, 300 + 400 * e, 120 - 200 * e, 120, e * 12, 1 - e * 2); c.save(); c.font = '800 15px Oxanium, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#9dffb0'; c.globalAlpha = 1 - e * 2; c.fillText('SAVUŞTURULDU!', 270, 122); c.restore(); } }
    else if (this.attack > 0) windup(this, k, clamp(1 - this.attack / (k.dur || 3)), t);
    return r;
  };
})();
