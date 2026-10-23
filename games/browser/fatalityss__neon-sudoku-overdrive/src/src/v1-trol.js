/* Neon Sudoku — alaycı Reaktör Gremlini: hata yapınca köşeden kıkırdar, bölüm kaybedilince ortada kahkaha atar */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_TROL) return;
  NS.V1_TROL = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const KUCUK = ['Heh heh!', 'O değildi!', 'Emin miydin?', 'Yanlış!', 'Ups!', 'Gözlük lazım mı?'];
  const BUYUK = ['Hahaha! Süre bitti!', 'Saat seni yendi!', 'Bu kadar mıydı?', 'Bir dahakine belki!', 'Yine mi kaybettin?'];
  const SOZ = { error: ['heh heh', 'o değildi', 'ups', 'emin miydin'], fail: ['hahaha, süre bitti', 'kaybettin', 'bir daha dene', 'nyah nyah'] };
  const pickOf = a => a[Math.floor(Math.random() * a.length)];

  /* ---------- Ses: sentezlenmiş kahkaha ve kazu ---------- */
  function ctxOf(g) { try { return g.audio || null; } catch (_) { return null; } }
  function out(ac, g) { const m = ac.createGain(); m.gain.value = .55; m.connect(ac.destination); return m; }
  function syllable(ac, dst, t0, f0, dur, vowel) {
    const F = vowel === 'e' ? [500, 1900] : vowel === 'i' ? [320, 2300] : [800, 1250];
    const src = ac.createOscillator(); src.type = 'sawtooth';
    src.frequency.setValueAtTime(f0 * 1.15, t0); src.frequency.exponentialRampToValueAtTime(f0 * .82, t0 + dur);
    const vib = ac.createOscillator(), vg = ac.createGain(); vib.frequency.value = 26; vg.gain.value = f0 * .06; vib.connect(vg); vg.connect(src.frequency);
    const env = ac.createGain(); env.gain.setValueAtTime(0, t0); env.gain.linearRampToValueAtTime(.9, t0 + .02); env.gain.exponentialRampToValueAtTime(.001, t0 + dur);
    const mix = ac.createGain(); mix.gain.value = 1;
    for (const [f, q, gn] of [[F[0], 6, 1], [F[1], 9, .6], [2800, 8, .25]]) { const b = ac.createBiquadFilter(); b.type = 'bandpass'; b.frequency.value = f; b.Q.value = q; const gg = ac.createGain(); gg.gain.value = gn; src.connect(b); b.connect(gg); gg.connect(env); }
    /* "h" nefesi */
    const n = ac.createBufferSource(), buf = ac.createBuffer(1, ac.sampleRate * .06 | 0, ac.sampleRate), d = buf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / d.length);
    n.buffer = buf; const hf = ac.createBiquadFilter(); hf.type = 'highpass'; hf.frequency.value = 1200; const hg = ac.createGain(); hg.gain.value = .35;
    n.connect(hf); hf.connect(hg); hg.connect(mix); env.connect(mix); mix.connect(dst);
    src.start(t0); vib.start(t0); n.start(t0 - .03); src.stop(t0 + dur + .05); vib.stop(t0 + dur + .05);
  }
  function laugh(ac, dst, t0, n, f0, step, vowel) { for (let k = 0; k < n; k++) syllable(ac, dst, t0 + k * step, f0 * Math.pow(.96, k), step * .8, vowel); }
  function kazoo(ac, dst, t0, notes) {
    for (const [f, s, d] of notes) {
      const o = ac.createOscillator(); o.type = 'sawtooth'; o.frequency.setValueAtTime(f, t0 + s); o.frequency.linearRampToValueAtTime(f * .97, t0 + s + d);
      const b = ac.createBiquadFilter(); b.type = 'bandpass'; b.frequency.value = 1100; b.Q.value = 2.5;
      const buzz = ac.createOscillator(), bg = ac.createGain(); buzz.frequency.value = 38; bg.gain.value = 18; buzz.connect(bg); bg.connect(o.frequency);
      const e = ac.createGain(); e.gain.setValueAtTime(0, t0 + s); e.gain.linearRampToValueAtTime(.5, t0 + s + .03); e.gain.setValueAtTime(.5, t0 + s + d - .05); e.gain.linearRampToValueAtTime(0, t0 + s + d);
      o.connect(b); b.connect(e); e.connect(dst); o.start(t0 + s); buzz.start(t0 + s); o.stop(t0 + s + d + .02); buzz.stop(t0 + s + d + .02);
    }
  }
  function say(g, list) {
    if (g.record.muted || globalThis.NEON_TROL_KONUS !== true) return;
    try {
      const ss = globalThis.speechSynthesis; if (!ss) return;
      const u = new SpeechSynthesisUtterance(pickOf(list)); u.lang = 'tr-TR'; u.pitch = 1.9; u.rate = 1.12; u.volume = .9;
      const v = ss.getVoices().find(v => /^tr/i.test(v.lang)); if (v) u.voice = v; else return;
      ss.cancel(); ss.speak(u);
    } catch (_) {}
  }
  function soundSmall(g) {
    const ac = ctxOf(g); if (!ac || g.record.muted) return;
    const t = ac.currentTime + .05, d = out(ac, g);
    laugh(ac, d, t, 3, 520, .11, 'e');
    setTimeout(() => say(g, SOZ.error), 380);
  }
  function soundBig(g) {
    const ac = ctxOf(g); if (!ac || g.record.muted) return;
    const t = ac.currentTime + .05, d = out(ac, g);
    /* nyah-nyah kazu ezgisi (çocuk tekerlemesi) + uzun kahkaha */
    kazoo(ac, d, t, [[587, 0, .28], [494, .3, .2], [659, .52, .26], [587, .8, .2], [494, 1.02, .4]]);
    laugh(ac, d, t + 1.5, 7, 430, .13, 'a');
    setTimeout(() => say(g, SOZ.fail), 2500);
  }

  /* ---------- Yüz: özgün "Reaktör Gremlini" ---------- */
  function face(c, x, y, s, t, mouthOpen, lean) {
    c.save(); c.translate(x, y); c.rotate(lean || 0); c.scale(s, s);
    const skin = '#7dff6a', dark = '#2d9a36', line = '#0b2a10';
    c.shadowColor = '#7dff6a'; c.shadowBlur = 24;
    c.fillStyle = skin; c.beginPath(); c.moveTo(-58, -30); c.lineTo(-96, -74); c.lineTo(-44, -54); c.fill(); c.beginPath(); c.moveTo(58, -30); c.lineTo(96, -74); c.lineTo(44, -54); c.fill();
    c.beginPath(); c.ellipse(0, 0, 66, 60, 0, 0, Math.PI * 2); c.fill(); c.shadowBlur = 0;
    const sh = c.createRadialGradient(-20, -24, 6, 0, 0, 70); sh.addColorStop(0, 'rgba(255,255,255,.35)'); sh.addColorStop(1, 'rgba(0,40,0,.25)'); c.fillStyle = sh; c.beginPath(); c.ellipse(0, 0, 66, 60, 0, 0, Math.PI * 2); c.fill();
    c.strokeStyle = line; c.lineWidth = 4; c.lineCap = 'round';
    /* kaşlar: biri kalkık */
    c.beginPath(); c.moveTo(-42, -26); c.quadraticCurveTo(-28, -36, -12, -24); c.stroke();
    c.beginPath(); c.moveTo(12, -34 - 4 * Math.sin(t * 8)); c.quadraticCurveTo(28, -46, 44, -36); c.stroke();
    /* kısık, alaycı gözler */
    c.lineWidth = 5; c.beginPath(); c.arc(-26, -8, 11, Math.PI * 1.1, Math.PI * 1.9); c.stroke();
    c.fillStyle = '#fff'; c.beginPath(); c.ellipse(27, -12, 11, 8, 0, 0, Math.PI * 2); c.fill(); c.fillStyle = line; c.beginPath(); c.arc(23, -11, 4.5, 0, Math.PI * 2); c.fill();
    /* yanak */
    c.fillStyle = 'rgba(255,90,140,.45)'; c.beginPath(); c.arc(-44, 14, 9, 0, Math.PI * 2); c.arc(46, 12, 9, 0, Math.PI * 2); c.fill();
    /* kocaman sırıtış */
    const mo = 6 + 18 * mouthOpen;
    c.fillStyle = '#3a0a14'; c.beginPath(); c.moveTo(-46, 12); c.quadraticCurveTo(0, 26 + mo * 2, 48, 6); c.quadraticCurveTo(4, 22 + mo * .6, -46, 12); c.fill();
    c.fillStyle = '#fffbe8'; for (let k = 0; k < 8; k++) { const tx = -38 + k * 11; c.beginPath(); c.moveTo(tx, 13 + k * -.6); c.lineTo(tx + 5, 22 + mo * .3); c.lineTo(tx + 10, 12 + k * -.7); c.fill(); }
    if (mouthOpen > .4) { c.fillStyle = '#ff5f86'; c.beginPath(); c.ellipse(4, 24 + mo, 13, 6, 0, 0, Math.PI * 2); c.fill(); }
    c.strokeStyle = line; c.lineWidth = 3.5; c.beginPath(); c.moveTo(-50, 11); c.quadraticCurveTo(0, 28 + mo * 2, 52, 4); c.stroke();
    c.beginPath(); c.moveTo(48, 4); c.lineTo(56, -2); c.stroke();
    c.restore();
  }
  function bubble(c, x, y, txt, size, col) {
    c.save(); c.font = '800 ' + size + 'px Oxanium, sans-serif'; const w = c.measureText(txt).width + 28, h = size + 22;
    const bx = Math.max(8, Math.min(532 - w, x - w / 2));
    c.fillStyle = '#fff'; c.strokeStyle = '#0b2a10'; c.lineWidth = 3;
    c.beginPath(); c.roundRect ? c.roundRect(bx, y - h, w, h, 14) : c.rect(bx, y - h, w, h); c.fill(); c.stroke();
    c.beginPath(); c.moveTo(x - 10, y - 2); c.lineTo(x + 4, y + 16); c.lineTo(x + 12, y - 2); c.closePath(); c.fill();
    c.fillStyle = col || '#0b2a10'; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText(txt, bx + w / 2, y - h / 2 + 1); c.restore();
  }

  /* ---------- ChatGPT maskotu (3 poz): 1 sırıtma, 2 kahkaha, 3 parmakla gösterme ---------- */
  const MI = {};
  const mimg = n => { const f = 'maskot-' + n + '.webp'; if (!MI[f]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[f]) || 'media/' + f; MI[f] = i; } return MI[f]; };
  [1, 2, 3].forEach(mimg); /* önceden yükle: eski çizim bir daha görünmesin */
  /* 12 karelik animasyon: satır 0 zıplama, satır 1 kahkaha, satır 2 parmakla gösterme */
  const GF = {};
  const gfr = (r, k) => { const f = 'gremlin-' + r + k + '.webp'; if (!GF[f]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[f]) || 'media/' + f; GF[f] = i; } return GF[f]; };
  for (let r = 0; r < 3; r++) for (let k = 0; k < 4; k++) gfr(r, k);
  function frame(c, r, k, x, y, h, rot, flip, sx, sy, a) {
    const im = gfr(r, k); if (!(im.complete && im.naturalWidth)) return false;
    c.save(); if (a != null) c.globalAlpha = a; c.translate(x, y); c.rotate(rot || 0); c.scale((flip ? -1 : 1) * (sx || 1), sy || 1); c.globalCompositeOperation = 'screen'; c.drawImage(im, -h / 2, -h, h, h); c.restore(); return true;
  }
  NS.TROL_FRAME = frame;
  function mascot(c, pose, x, y, h, rot, flip, sx, sy, a) {
    const im = mimg(pose); if (!(im.complete && im.naturalWidth)) return false;
    const w = h * im.naturalWidth / im.naturalHeight; c.save(); if (a != null) c.globalAlpha = a; c.translate(x, y); c.rotate(rot || 0); c.scale((flip ? -1 : 1) * (sx || 1), sy || 1); c.globalCompositeOperation = 'screen'; c.drawImage(im, -w / 2, -h / 2, w, h); c.restore(); return true;
  }
  /* ---------- Tetikleme ---------- */
  const sfxPrev = P.sfx;
  P.sfx = function (name) {
    const r = sfxPrev.apply(this, arguments);
    if (globalThis.NEON_TROL === false) return r;
    try {
      if (name === 'error' && !(this.__trol && this.__trol.big)) { this.__trol = { big: false, t0: now(), txt: pickOf(KUCUK), side: Math.random() < .5 ? -1 : 1 }; soundSmall(this); }
      if (name === 'fail') { this.__trol = { big: true, t0: now(), txt: pickOf(BUYUK) }; soundBig(this); }
    } catch (_) {}
    return r;
  };
  const renderPrev = P.render;
  P.render = function () {
    const r = renderPrev.apply(this, arguments);
    const k = this.__trol; if (!k) return r;
    const c = this.ctx, e = now() - k.t0, t = now(), still = this.record.reduced;
    const el = p => p >= 1 ? 1 : 1 - Math.cos(p * Math.PI * 3.2) * Math.exp(-p * 5.5);
    const fps = 9, loop = (t0, n) => Math.floor((e - t0) * fps) % n;
    if (!k.big) {
      /* küçük: köşeden zıplayarak çıkar (kare 0-3), parmakla gösterip güler (satır 2), sonra aşağı kayar */
      const D = 1.9; if (e > D) { this.__trol = null; return r; }
      const left = k.side < 0, x = left ? 92 : 448, outP = Math.max(0, (e - (D - .3)) / .3);
      let row = 0, col = 0, lift = 0, sq = 1;
      if (e < .55) { const p = e / .55; col = Math.min(3, Math.floor(p * 4)); lift = Math.sin(Math.min(1, p * 1.25) * Math.PI) * 60 + 150 * Math.min(1, p * 2); sq = col === 0 ? .9 : col === 3 ? .92 : 1.06; lift = col === 3 ? 150 : lift; }
      else { row = 2; col = loop(.55, 4); lift = 150 - outP * 190; }
      if (still) { row = 2; col = 0; lift = 150; sq = 1; }
      frame(c, row, col, x, 960 + 25 - lift, 185, 0, left, 1 / sq, sq, 1 - outP * .5);
      if (e > .55 && e < D - .25) { const bs = Math.min(1, (e - .55) / .12), bx3 = left ? 210 : 330, by3 = 960 - lift - 175; c.save(); c.translate(bx3, by3); c.scale(bs, bs); c.translate(-bx3, -by3); bubble(c, bx3, by3, k.txt, 18); c.restore(); }
    } else {
      /* büyük: yukarıdan düşer (havada kare), yere iner, karnını tutup güler (satır 1), parmakla gösterir (satır 2), sonra uzaklaşır */
      const D = 3.9; if (e > D) { this.__trol = null; return r; }
      const outP = Math.max(0, (e - (D - .45)) / .45), floor = 560;
      let row = 0, col = 2, fy = floor, sq = 1;
      if (e < .45) { const p = e / .45; fy = -60 + (floor + 60) * p * p; }
      else if (e < .65) { col = 3; sq = .86 + .14 * ((e - .45) / .2); }
      else if (e < 2.65) { row = 1; col = loop(.65, 4); }
      else { row = 2; col = loop(2.65, 4); }
      if (still) { row = 1; col = 0; fy = floor; sq = 1; }
      const shake = !still && row === 1 ? Math.sin(e * 40) * 3 : 0, sc = 1 - outP * .6;
      c.save(); c.globalAlpha = .5 * Math.min(1, e * 3) * (1 - outP); c.fillStyle = '#05060a'; c.fillRect(0, 0, 540, 960); c.restore();
      if (!still && e > .45) { c.save(); c.globalCompositeOperation = 'lighter'; const lp = Math.max(0, 1 - (e - .45) * 3); c.globalAlpha = lp; c.strokeStyle = '#9dff6a'; c.lineWidth = 4; c.beginPath(); c.ellipse(270, floor, 60 + 160 * (1 - lp), 14 + 30 * (1 - lp), 0, 0, Math.PI * 2); c.stroke(); c.restore(); }
      frame(c, row, col, 270 + shake, fy - outP * 30, 330 * sc, 0, false, 1 / sq, sq, 1 - outP);
      if (e > .7 && outP < 1) { const bs = Math.min(1, (e - .7) / .12) * (1 - outP), by3 = floor - 330 * sc - 20; c.save(); c.translate(270, by3); c.scale(bs, bs); c.translate(-270, -by3); bubble(c, 270, by3, k.txt, 22, '#0b2a10'); c.restore(); }
      if (row === 1 && !still) { c.save(); c.font = '900 34px Oxanium, sans-serif'; c.fillStyle = '#9dff6a'; c.shadowColor = '#5aff3a'; c.shadowBlur = 16; c.textAlign = 'center'; for (let j = 0; j < 4; j++) { const ph = (e * 1.3 + j / 4) % 1; c.globalAlpha = (1 - ph) * (1 - outP); c.save(); c.translate(90 + j * 120 + Math.sin(e * 4 + j) * 18, floor + 40 - ph * 200); c.rotate(Math.sin(e * 6 + j) * .3); c.fillText('HA', 0, 0); c.restore(); } c.restore(); }
      this.hits = e < 1 ? [] : this.hits;
    }
    return r;
  };
  NS.TROL = { face };
})();
