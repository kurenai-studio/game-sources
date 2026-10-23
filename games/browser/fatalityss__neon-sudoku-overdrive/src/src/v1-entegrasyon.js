globalThis.NS_T = globalThis.NS_T || (g => (g && g.__tmax) || 30);
/* Neon Sudoku: Overdrive — V1 görsel ve ses paketi entegrasyonu (3.3.1 oyun koduna yama). */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_PATCHED) return;
  NS.V1_PATCHED = true;
  const P = NS.Game.prototype;
  const BASE = (globalThis.NEON_V1_BASE || 'media/');

  /* ---------- Görseller ---------- */
  const img = src => { const i = new Image(); i.src = BASE + src; return i; };
  const ART = {
    bg: img('Gemini-Arka-Plan-V1.jpg'),
    digits: img('Gemini-Rakamlar-V1-Depth.jpg'),
    cells: img('Gemini-Hucre-Durumlari-V1-Depth.jpg'),
    boost: img('Gemini-Boost-Yildirim-Cubugu.jpg')
  };
  const ok = i => i && i.complete && i.naturalWidth > 0;
  const DIGIT = [[170, 240, 600, 1060], [720, 240, 620, 1060], [1345, 240, 650, 1060], [1980, 240, 710, 1060]];
  const CELL = { normal: [80, 450, 605, 620], selected: [650, 370, 800, 800], overdrive: [1290, 340, 850, 850], error: [2080, 450, 605, 620] };

  /* ---------- Yazı tipleri ---------- */
  let fontsReady = false;
  try {
    const faces = [
      new FontFace('Oxanium', 'url(' + BASE.replace(/media\/$/, '') + 'fonts/Oxanium.ttf)', { weight: '200 800' }),
      new FontFace('Barlow Condensed', 'url(' + BASE.replace(/media\/$/, '') + 'fonts/BarlowCondensed-Bold.ttf)', { weight: '700' }),
      new FontFace('Barlow Condensed', 'url(' + BASE.replace(/media\/$/, '') + 'fonts/BarlowCondensed-Medium.ttf)', { weight: '500' })
    ];
    Promise.all(faces.map(f => f.load().then(x => { document.fonts.add(x); }))).then(() => { fontsReady = true; }).catch(() => {});
  } catch (_) {}

  /* Kabartmalı metal yazı: büyük başlıklarda alt gölge + üst ışık. */
  P.text = function (t, x, y, size = 20, color = '#e8f2ff', align = 'left') {
    const c = this.ctx;
    const big = size >= 24;
    const family = fontsReady ? (big ? '"Barlow Condensed", "Oxanium", system-ui, sans-serif' : '"Oxanium", system-ui, sans-serif') : 'system-ui, sans-serif';
    c.font = (big ? '700 ' : '600 ') + (big && fontsReady ? Math.round(size * 1.12) : size) + 'px ' + family;
    c.textAlign = align;
    if (big) {
      c.save();
      c.fillStyle = 'rgba(0,0,0,.75)';
      c.fillText(t, x + 1.5, y + 2.5);
      c.fillStyle = 'rgba(255,255,255,.35)';
      c.fillText(t, x - .6, y - 1);
      c.restore();
    }
    c.fillStyle = color;
    c.fillText(t, x, y);
  };

  /* Rakam görseli */
  P.digitArt = function (n, cx, cy, h, dim) {
    if (!ok(ART.digits)) return false;
    const [sx, sy, sw, sh] = DIGIT[n - 1], w = h * sw / sh, c = this.ctx;
    c.save();
    c.globalCompositeOperation = 'screen';
    if (dim) c.globalAlpha = .82;
    c.drawImage(ART.digits, sx, sy, sw, sh, cx - w / 2, cy - h / 2, w, h);
    c.restore();
    return true;
  };

  /* Hücre çerçevesi görseli: 112×112 hull çağrıları hücredir. */
  const hull0 = P.hull;
  P.hull = function (x, y, w, h, accent, active) {
    if (w === 112 && h === 112 && ok(ART.cells) && this.cfg) {
      const i = Math.round((x - 30) / 120) + Math.round((y - 326) / 120) * 4;
      let state = 'normal';
      if (i === this.selected) state = this.errorFlash > 0 ? 'error' : this.overdrive > 0 ? 'overdrive' : 'selected';
      const [sx, sy, sw, sh] = CELL[state];
      const pad = state === 'normal' || state === 'error' ? 6 : state === 'selected' ? 16 : 22;
      const c = this.ctx;
      c.save();
      c.fillStyle = 'rgba(6,12,20,.78)';
      c.fillRect(x + 14, y + 14, w - 28, h - 28);
      c.globalCompositeOperation = 'screen';
      c.drawImage(ART.cells, sx, sy, sw, sh, x - pad, y - pad, w + pad * 2, h + pad * 2);
      c.restore();
      if (active && accent && state === 'normal') {
        c.save(); c.strokeStyle = accent; c.globalAlpha = .55; c.lineWidth = 2; c.strokeRect(x + 6, y + 6, w - 12, h - 12); c.restore();
      }
      return;
    }
    hull0.call(this, x, y, w, h, accent, active);
  };

  /* Tahtadaki ve aday düğmelerindeki 1–4 rakamları görselle. */
  const text0 = P.text;
  P.text = function (t, x, y, size, color, align) {
    if (/^[1-4]$/.test(t) && (size === 42 || size === 34)) {
      const h = size === 42 ? 66 : 52, cy = size === 42 ? y - 17 : y - 13;
      if (this.digitArt(+t, x, cy, h, color === '#dfeafa')) return;
    }
    text0.call(this, t, x, y, size, color, align);
  };

  /* Arka plan ve kırmızı son saniyeler */
  const atmos0 = P.sceneAtmosphere;
  P.sceneAtmosphere = function () {
    const c = this.ctx;
    if (ok(ART.bg)) {
      c.save();
      const play = this.cfg && ['playing', 'chain', 'brief'].includes(this.state);
      c.globalAlpha = play ? .42 : .45;
      const r = ART.bg.naturalWidth / ART.bg.naturalHeight, w = 960 * r;
      c.drawImage(ART.bg, (540 - w) / 2, 0, w, 960);
      c.restore();
    }
    atmos0.call(this);
  };
  const react0 = P.reactiveFX;
  P.reactiveFX = function () {
    react0.call(this);
    if (this.state === 'playing' && this.time <= 3 && this.time > 0) {
      const c = this.ctx, pulse = this.record.reduced ? 1 : .6 + .4 * Math.abs(Math.sin(this.clock * 6));
      c.save(); c.fillStyle = 'rgba(255,32,58,' + (0.10 + 0.10 * pulse * (1 - this.time / 3)) + ')'; c.fillRect(0, 0, 540, 960); c.restore();
    }
  };

  /* Isı çubuğu: alev ve yıldırım görseli */
  const heat0 = P.heatGauge;
  P.heatGauge = function () {
    heat0.call(this);
    if (!ok(ART.boost)) return;
    const c = this.ctx, f = Math.max(0, Math.min(1, this.heat / 100));
    if (f <= 0) return;
    c.save();
    c.beginPath(); c.rect(28, 210, 484 * f, 21); c.clip();
    c.globalCompositeOperation = 'screen';
    c.globalAlpha = this.overdrive > 0 ? 1 : .85;
    c.drawImage(ART.boost, 380, 520, 2000, 480, 28, 205, 484, 31);
    c.restore();
  };

  /* Bölüm haritası: 8 sektör, boss kartları */
  const SECTORS = ['NEON GENESIS', 'CHROME DISTRICT', 'PULSE FOUNDRY', 'VOLTAGE RIFT', 'EMBER VAULT', 'GHOST CIRCUIT', 'BLACKOUT PROTOCOL', 'SOLAR COLLAPSE'];
  const render0 = P.render;
  P.render = function () {
    if (this.state !== 'select') return render0.call(this);
    const c = this.ctx, t = [['NEON', '#55e8ef', '#ff6ba9']][0];
    this.hits = [];
    c.clearRect(0, 0, 540, 960);
    c.fillStyle = '#060a18'; c.fillRect(0, 0, 540, 960);
    this.sceneAtmosphere();
    this.text('SEKTÖRÜ SEÇ', 270, 52, 30, '#eaf8ff', 'center');
    this.text('40 BÖLÜM · 8 SEKTÖR · 8 BOSS', 270, 80, 13, '#7fd8ea', 'center');
    const levels = NS.levels;
    for (let s = 0; s < 8; s++) {
      const y = 104 + s * 92;
      this.text(SECTORS[s], 22, y + 10, 12, s < 4 ? '#7fe9f5' : '#ffb36b');
      c.save(); c.strokeStyle = 'rgba(127,233,245,.25)'; c.beginPath(); c.moveTo(22 + c.measureText(SECTORS[s]).width + 10, y + 6); c.lineTo(518, y + 6); c.stroke(); c.restore();
      for (let k = 0; k < 5; k++) {
        const i = s * 5 + k, x = 22 + k * 100, ty = y + 18, w = 92, h = 64, open = i < this.record.unlocked, boss = levels[i].boss, sel = this.mapSelection === i + 1, stars = this.record.stars[i];
        const color = boss ? NS.bosses[levels[i].goal].color : sel ? '#55e8ef' : '#4f6b80';
        c.save();
        if (boss && open && !this.record.reduced) { c.shadowColor = color; c.shadowBlur = 14 + 6 * Math.sin(this.clock * 3 + i); }
        this.hull(x, ty, w, h, color, boss || sel);
        c.restore();
        if (!open) { c.save(); c.fillStyle = 'rgba(3,6,14,.62)'; c.fillRect(x + 2, ty + 2, w - 4, h - 4); c.restore(); this.text('◆', x + w / 2, ty + 30, 14, '#3e4d63', 'center'); this.text('KİLİTLİ', x + w / 2, ty + 50, 10, '#56657c', 'center'); continue; }
        if (boss) {
          this.text(String(i + 1), x + w / 2, ty + 30, 24, color, 'center');
          this.text(levels[i].title, x + w / 2, ty + 47, 10, '#ffe6b8', 'center');
        } else this.text(String(i + 1), x + w / 2, ty + 33, 26, '#eef6ff', 'center');
        this.text(stars ? '★'.repeat(stars) + '☆'.repeat(3 - stars) : boss ? 'BOSS' : '☆☆☆', x + w / 2, ty + 59, 11, stars ? '#ffcd69' : boss ? '#ffbc6d' : '#5f728a', 'center');
        this.hits.push({ x, y: ty, w, h, name: 'Bölüm ' + (i + 1), action: () => this.launch(i + 1) });
      }
    }
    this.button('MENÜ', 120, 852, 300, 64, () => this.state = 'menu');
    this.syncControls();
  };

  /* ---------- Sesler ---------- */
  const SFX = { select: 'v1-select.wav', eliminate: 'correct-A.wav', combo: 'combo-A.wav', overdrive: 'overdrive-A.wav', error: 'v1-error.wav', tick: 'v1-countdown.wav', timeBonus: 'v1-bonus.wav', warning: 'v1-boss.wav', block: 'v1-shield.wav', chainBurst: 'v1-chain.wav', victory: 'v1-victory.wav' };
  const VOICE = { online: 'v1-voice-system-online.mp3', breach: 'v1-voice-data-breach.mp3', override: 'v1-voice-system-override.mp3', overdrive: 'v1-voice-overdrive.mp3', threat: 'v1-voice-critical-threat.mp3', denied: 'v1-voice-access-denied.mp3', cleared: 'v1-voice-system-cleared.mp3', flawless: 'v1-voice-flawless-execution.mp3', failure: 'v1-voice-system-failure.mp3', fatality: 'v1-voice-fatality.mp3', sector: 'v1-voice-sector-destroyed.mp3', obliterated: 'v1-voice-obliterated.mp3', brutal: 'v1-voice-brutal.mp3', unstoppable: 'v1-voice-unstoppable.mp3' };
  const MUSIC = { a: 'v1-reactor-pressure.mp3', b: 'v1-blackout-protocol.mp3', c: 'v1-neon-grid.mp3', d: 'v1-infernal-boss.mp3', m: 'v1-damned-menu.mp3', e: 'v1-neon-pulse.mp3', f: 'v1-hellfire-boss.mp3', g: 'v1-geri-sayim.mp3', z: 'v1-zafer.mp3' };
  const buffers = {};
  /* ses dosyaları sayfa açılır açılmaz indirilir; dokununca yalnızca çözülür (telefonda gecikme olmasın) */
  const RAW = {};
  const ALL = [...new Set([...Object.values(VOICE), ...Object.values(SFX), ...Object.values(MUSIC)])];
  ALL.forEach(f => { RAW[f] = fetch(BASE + f).then(r => r.ok ? r.arrayBuffer() : Promise.reject()).catch(() => null); });
  function loadAll(game) {
    if (game.__v1Loading) return; game.__v1Loading = true;
    const MUS = new Set(Object.values(MUSIC));
    ALL.filter(f => !MUS.has(f)).forEach(f => decodeOne(game, f));
  }
  /* Müzikler telefonda belleği doldurmasın diye yalnızca çalınacağı zaman çözülür; en fazla 2 parça bellekte tutulur */
  const DEC = {};
  function decodeOne(game, f) {
    if (buffers[f] || DEC[f]) return; DEC[f] = 1;
    RAW[f].then(b => b ? new Promise((res, rej) => game.audio.decodeAudioData(b.slice(0), res, rej)) : null).then(buf => { if (buf) buffers[f] = buf; }).catch(() => {}).then(() => { DEC[f] = 0; });
  }
  function needMusic(game, f) {
    if (!f || !game.audio) return;
    decodeOne(game, f);
    const keep = new Set([f, MUSIC.z, MUSIC.g, game.__lastMus]);
    Object.values(MUSIC).forEach(m => { if (!keep.has(m) && buffers[m] && !(game.musicSrc && game.musicSrc.buffer === buffers[m])) delete buffers[m]; });
    game.__lastMus = f;
  }
  function playBuf(game, file, bus, vol = 1) {
    const buf = buffers[file]; if (!buf || !game.audio) return null;
    const s = game.audio.createBufferSource(), g = game.audio.createGain();
    s.buffer = buf; g.gain.value = vol; s.connect(g); g.connect(bus); s.start();
    s.onended = () => { try { s.disconnect(); g.disconnect(); } catch (_) {} };
    return s;
  }
  P.say = function (id) {
    if (!this.audio || this.record.muted) return;
    if (!this.voiceGain) { this.voiceGain = this.audio.createGain(); this.voiceGain.gain.value = 1.6; this.voiceGain.connect(this.master); }
    if (this.voiceSrc) { try { this.voiceSrc.stop(); } catch (_) {} }
    this.voiceSrc = playBuf(this, VOICE[id], this.voiceGain, 1);
    if (this.voiceSrc) { this.duckUntil = Math.max(this.duckUntil || 0, this.audio.currentTime + 1.2); this.musicGain.gain.setTargetAtTime(.12, this.audio.currentTime, .03); }
  };
  const ensure0 = P.ensureAudio;
  P.ensureAudio = function () {
    ensure0.call(this);
    if (this.audio) loadAll(this);
  };
  const sfx0 = P.sfx;
  P.sfx = function (kind, value = 0) {
    if (!this.audio || !this.fxGain || this.record.muted) return;
    const file = SFX[kind];
    if (file && buffers[file]) {
      if (kind === 'eliminate' && this.lastElimSnd && this.audio.currentTime - this.lastElimSnd < .07) return;
      if (kind === 'eliminate') this.lastElimSnd = this.audio.currentTime;
      playBuf(this, file, this.fxGain, kind === 'tick' ? .7 : .9);
      const dramatic = ['overdrive', 'error', 'chainBurst', 'victory'].includes(kind);
      this.duckUntil = Math.max(this.duckUntil || 0, this.audio.currentTime + (dramatic ? .8 : .18));
    } else sfx0.call(this, kind, value);
    if (kind === 'overdrive') this.say('overdrive');
    else if (kind === 'error') this.say('denied');
    else if (kind === 'warning') this.say('threat');
    else if (kind === 'fail') this.say('failure');
    else if (kind === 'victory') this.say(this.errors === 0 && this.hints === 0 ? 'flawless' : 'cleared');
  };
  const cheer0 = P.cheer;
  P.cheer = function (text) {
    const before = this.lastCheer;
    cheer0.call(this, text);
    if (this.lastCheer !== before) this.say(text === 'GREAT!' ? 'breach' : 'override');
  };
  const start0 = P.start;
  P.start = function (n) {
    start0.call(this, n);
    if (!this.__v1Online && this.audio) { this.__v1Online = true; let n = 0; const tryOnline = () => { if (buffers[VOICE.online]) this.say('online'); else if (n++ < 40) setTimeout(tryOnline, 250); }; setTimeout(tryOnline, 150); }
  };

  /* Müzik: üretilen müzik yerine iki gerilim parçası (boss bölümlerinde B). */
  const music0 = P.music;
  P.music = function () {
    if (!this.audio) return;
    const L = this.level || 1, play = ['playing', 'chain'].includes(this.state) && this.cfg;
    const want = play ? (this.state === 'playing' && this.time > 0 && this.time <= 10 ? 'g' : this.cfg.boss ? 'bdf'[(L / 5 | 0) % 3] : (L >= 31 ? 'bdf'[L % 3] : 'ace'[L % 3])) : (this.state === 'menu' ? 'm' : null);
    if (want) needMusic(this, MUSIC[want]); if (want && want !== 'g' && this.cfg && this.state === 'playing') { decodeOne(this, MUSIC.g); decodeOne(this, MUSIC.z); }
    const ready = want && buffers[MUSIC[want]];
    if (!ready) {
      if (this.musicSrc) { try { this.musicSrc.stop(); } catch (_) {} this.musicSrc = null; this.musicId = null; }
      if (!want || !Object.keys(buffers).length) return music0.call(this);
      return music0.call(this);
    }
    this.master.gain.setTargetAtTime(this.record.muted ? 0 : .65 * (globalThis.NEON_VOL == null ? 1 : globalThis.NEON_VOL), this.audio.currentTime, .08);
    if (this.audio.currentTime > this.duckUntil) this.musicGain.gain.setTargetAtTime(want === 'm' ? .3 : this.time <= 10 ? .5 : .38, this.audio.currentTime, .12);
    if (this.musicId !== want) {
      if (this.musicSrc) { try { this.musicSrc.stop(); } catch (_) {} }
      const s = this.audio.createBufferSource(); s.buffer = buffers[MUSIC[want]]; s.loop = true; s.connect(this.musicGain); s.start();
      this.musicSrc = s; this.musicId = want;
    }
    if (this.musicSrc) this.musicSrc.playbackRate.setTargetAtTime(1, this.audio.currentTime, .3);
  };
  P.playZafer = function () { if (this.audio) decodeOne(this, MUSIC.z); if (!this.audio || this.record.muted || !buffers[MUSIC.z]) return; playBuf(this, MUSIC.z, this.musicGain, 1.1); this.musicGain.gain.setTargetAtTime(.45, this.audio.currentTime, .05); };
  const update0 = P.update;
  P.update = function (dt) {
    update0.call(this, dt);
    if (this.musicSrc && !['playing', 'chain', 'menu'].includes(this.state)) { try { this.musicSrc.stop(); } catch (_) {} this.musicSrc = null; this.musicId = null; }
  };
})();

/* ---------- 3D derinlik katmanı: kabartmalı paneller ve yazılar ---------- */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_DEPTH) return;
  NS.V1_DEPTH = true;
  const P = NS.Game.prototype;
  const shade = (hex, f) => { const n = parseInt(hex.slice(1, 7), 16); let r = n >> 16, g = n >> 8 & 255, b = n & 255; const m = v => Math.max(0, Math.min(255, Math.round(f < 0 ? v * (1 + f) : v + (255 - v) * f))); return 'rgb(' + m(r) + ',' + m(g) + ',' + m(b) + ')'; };
  const cutPath = (c, x, y, w, h, cut) => { c.beginPath(); c.moveTo(x + cut, y); c.lineTo(x + w - cut, y); c.lineTo(x + w, y + cut); c.lineTo(x + w, y + h - cut); c.lineTo(x + w - cut, y + h); c.lineTo(x + cut, y + h); c.lineTo(x, y + h - cut); c.lineTo(x, y + cut); c.closePath(); };

  const hullV1 = P.hull;
  P.hull = function (x, y, w, h, accent = '#446477', active = false) {
    if (w === 112 && h === 112 && this.cfg && ['playing', 'chain', 'paused', 'timeout', 'complete'].includes(this.state)) return hullV1.call(this, x, y, w, h, accent, active);
    const c = this.ctx, cut = Math.min(12, h / 4), d = Math.max(4, Math.min(11, h * .16)), big = h > 40;
    c.save();
    /* gölge ve yan yüz (ekstrüzyon) */
    if (!this.record.reduced) { c.shadowColor = 'rgba(0,0,0,.65)'; c.shadowBlur = 14; c.shadowOffsetY = 6; }
    cutPath(c, x, y + d, w, h, cut);
    const side = c.createLinearGradient(0, y + h - cut, 0, y + h + d);
    side.addColorStop(0, '#1b2733'); side.addColorStop(1, '#03070c');
    c.fillStyle = side; c.fill();
    c.shadowColor = 'transparent'; c.shadowBlur = 0; c.shadowOffsetY = 0;
    /* ön yüz: fırçalanmış metal */
    cutPath(c, x, y, w, h, cut);
    const face = c.createLinearGradient(x, y, x, y + h);
    face.addColorStop(0, '#4b6073'); face.addColorStop(.08, '#2b3b4b'); face.addColorStop(.5, '#152230'); face.addColorStop(1, '#0d1823');
    c.fillStyle = face; c.fill();
    c.save(); c.clip();
    c.globalAlpha = .06; c.fillStyle = '#cfe9ff';
    for (let k = 0; k < w; k += 3) c.fillRect(x + k, y, 1, h);
    c.globalAlpha = 1;
    /* parlak üst ve sol kenar, koyu alt ve sağ kenar (eğim) */
    c.lineWidth = 2;
    c.strokeStyle = 'rgba(214,240,255,.62)'; c.beginPath(); c.moveTo(x + 1, y + h - cut); c.lineTo(x + 1, y + cut); c.lineTo(x + cut, y + 1); c.lineTo(x + w - cut, y + 1); c.stroke();
    c.strokeStyle = 'rgba(0,0,0,.7)'; c.beginPath(); c.moveTo(x + w - cut, y + h - 1); c.lineTo(x + cut, y + h - 1); c.moveTo(x + w - 1, y + cut); c.lineTo(x + w - 1, y + h - cut); c.stroke();
    c.restore();
    /* içe gömülü panel */
    if (big) {
      const ix = x + 7, iy = y + 7, iw = w - 14, ih = h - 14, ic = Math.max(4, cut - 4);
      cutPath(c, ix, iy, iw, ih, ic);
      const inner = c.createLinearGradient(0, iy, 0, iy + ih);
      inner.addColorStop(0, '#060c14'); inner.addColorStop(.18, '#0b1621'); inner.addColorStop(1, '#122230');
      c.fillStyle = inner; c.fill();
      c.lineWidth = 1.5;
      c.strokeStyle = 'rgba(0,0,0,.85)'; c.beginPath(); c.moveTo(ix + 1, iy + ih - ic); c.lineTo(ix + 1, iy + ic); c.lineTo(ix + ic, iy + 1); c.lineTo(ix + iw - ic, iy + 1); c.stroke();
      c.strokeStyle = 'rgba(160,210,230,.28)'; c.beginPath(); c.moveTo(ix + iw - ic, iy + ih - 1); c.lineTo(ix + ic, iy + ih - 1); c.moveTo(ix + iw - 1, iy + ic); c.lineTo(ix + iw - 1, iy + ih - ic); c.stroke();
      /* vidalar */
      c.fillStyle = '#7d8c99';
      for (const [sx, sy] of [[x + 4, y + h / 2], [x + w - 4, y + h / 2]]) { c.beginPath(); c.arc(sx, sy, 1.6, 0, Math.PI * 2); c.fill(); }
    }
    /* neon şerit */
    c.strokeStyle = accent; c.lineWidth = active ? 2.6 : 1.4;
    if (active && !this.record.reduced) { c.shadowColor = accent; c.shadowBlur = 12; }
    cutPath(c, x + .5, y + .5, w - 1, h - 1, cut); c.globalAlpha = active ? .95 : .45; c.stroke();
    c.globalAlpha = 1; c.shadowBlur = 0;
    if (active) { c.fillStyle = accent; c.fillRect(x + cut + 4, y + h - 4, Math.min(46, w * .25), 2); c.fillRect(x + w - cut - 4 - Math.min(46, w * .25), y + 2, Math.min(46, w * .25), 2); }
    c.restore();
  };

  /* Büyük yazılar: katmanlı derinlik (3D ekstrüzyon) + metal yüz */
  const textV1 = P.text;
  P.text = function (t, x, y, size = 20, color = '#e8f2ff', align = 'left') {
    if (size < 24 || /^[1-4]$/.test(t) && (size === 42 || size === 34)) return textV1.call(this, t, x, y, size, color, align);
    const c = this.ctx;
    textV1.call(this, '', x, y, size, color, align); /* yazı tipini ayarla */
    const fnt = c.font;
    c.save(); c.font = fnt; c.textAlign = align;
    const depth = size >= 30 ? 7 : 4;
    for (let k = depth; k >= 1; k--) { c.fillStyle = k === depth ? 'rgba(0,0,0,.8)' : shade(color.length === 7 ? color : '#8899aa', -.55 - k * .05); c.fillText(t, x + k * .4, y + k); }
    const m = c.measureText(t), top = y - size * .85;
    const g = c.createLinearGradient(0, top, 0, y);
    const base = color.length === 7 ? color : '#e8f2ff';
    g.addColorStop(0, shade(base, .55)); g.addColorStop(.45, base); g.addColorStop(.55, shade(base, -.18)); g.addColorStop(1, shade(base, .1));
    c.fillStyle = g; c.fillText(t, x, y);
    c.lineWidth = 1; c.strokeStyle = 'rgba(0,0,0,.45)'; c.strokeText(t, x, y);
    c.restore();
  };

  /* Menü: büyük kabartmalı logo ve çekirdek */
  const renderD = P.render;
  P.render = function () {
    renderD.call(this);
    if (this.state !== 'menu') return;
    const c = this.ctx;
    c.save();
    if (globalThis.NEON_BANNER) globalThis.NEON_BANNER(this, c); else { c.fillStyle = '#070b1a'; c.fillRect(0, 22, 540, 86); }
    c.restore();
    this.text('NEON SUDOKU', 270, 68, 44, '#5ff0f5', 'center');
    this.text('O V E R D R I V E', 270, 98, 18, '#ff7fb6', 'center');
  };
})();

/* ---------- Canlı görseller: şimşek, alev, rakam vuruşu, akan ısı, nefes alan arka plan, hata sarsıntısı ---------- */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_ANIM) return;
  NS.V1_ANIM = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const BASE = (globalThis.NEON_V1_BASE || 'media/');
  const find = name => { for (const i of document.images) if (i.src.indexOf(name) >= 0) return i; return null; };
  const ART = {};
  const get = (k, f) => { if (!ART[k]) { const i = new Image(); i.src = BASE + f; ART[k] = i; } return ART[k]; };
  const ok = i => i && i.complete && i.naturalWidth > 0;
  const CELL = { normal: [80, 450, 605, 620], selected: [650, 370, 800, 800], overdrive: [1290, 340, 850, 850], error: [2080, 450, 605, 620] };
  const DIGIT = [[170, 240, 600, 1060], [720, 240, 620, 1060], [1345, 240, 650, 1060], [1980, 240, 710, 1060]];

  function bolt(c, x1, y1, x2, y2, color, rnd) {
    c.beginPath(); c.moveTo(x1, y1);
    const n = 6;
    for (let k = 1; k < n; k++) { const t = k / n; c.lineTo(x1 + (x2 - x1) * t + (rnd() - .5) * 14, y1 + (y2 - y1) * t + (rnd() - .5) * 14); }
    c.lineTo(x2, y2);
    c.strokeStyle = color; c.lineWidth = 1.6; c.shadowColor = color; c.shadowBlur = 10; c.stroke();
    c.strokeStyle = '#ffffff'; c.lineWidth = .6; c.stroke();
  }

  /* Hücreler */
  const hullPrev = P.hull;
  P.hull = function (x, y, w, h, accent, active) {
    const cells = get('cells', 'Gemini-Hucre-Durumlari-V1-Depth.jpg');
    if (!(w === 112 && h === 112 && this.cfg && ok(cells) && ['playing', 'chain', 'paused', 'timeout', 'complete'].includes(this.state))) return hullPrev.call(this, x, y, w, h, accent, active);
    const c = this.ctx, t = now(), still = this.record.reduced;
    const i = Math.round((x - 30) / 120) + Math.round((y - 326) / 120) * 4;
    let state = 'normal';
    if (i === this.selected) state = this.errorFlash > 0 ? 'error' : this.overdrive > 0 ? 'overdrive' : 'selected';
    const [sx, sy, sw, sh] = CELL[state];
    let pad = state === 'normal' || state === 'error' ? 6 : state === 'selected' ? 16 : 22, dx = 0, scale = 1, alpha = 1;
    if (!still) {
      if (state === 'error') dx = Math.sin(t * 70) * 5 * Math.min(1, this.errorFlash);
      if (state === 'selected') { alpha = .9 + .1 * Math.sin(t * 3); scale = 1 + .012 * Math.sin(t * 3); }
      if (state === 'overdrive') scale = 1 + .05 * Math.sin(t * 6);
    }
    const cx = x + w / 2 + dx, cy = y + h / 2, W = (w + pad * 2) * scale;
    c.save();
    c.fillStyle = 'rgba(6,12,20,.8)'; c.fillRect(x + 14 + dx, y + 14, w - 28, h - 28);
    c.globalCompositeOperation = 'screen'; c.globalAlpha = alpha;
    c.drawImage(cells, sx, sy, sw, sh, cx - W / 2, cy - W / 2, W, W);
    c.restore();
    if (!still && state === 'selected' && Math.sin(t * 2.2 + i) > .92) {
      const seed = Math.floor(t * 4) + i * 31; let s = seed; const rnd = () => (s = (s * 9301 + 49297) % 233280) / 233280;
      c.save(); c.globalCompositeOperation = 'lighter';
      const side = Math.floor(rnd() * 4), a = [[x, y, x + w, y], [x + w, y, x + w, y + h], [x + w, y + h, x, y + h], [x, y + h, x, y]][side];
      bolt(c, a[0], a[1], a[2], a[3], rnd() > .5 ? '#6ff3ff' : '#e07bff', rnd);
      c.restore();
    }
    if (!still && state === 'overdrive' && Math.random() < .35) {
      const ang = Math.random() * Math.PI * 2;
      this.fx.push({ kind: 'spark', x: cx + Math.cos(ang) * 58, y: cy + Math.sin(ang) * 58, vx: Math.cos(ang) * 70, vy: Math.sin(ang) * 70 - 40, age: 0, life: .55, color: Math.random() < .5 ? '#ffb34a' : '#ffe08a' });
    }
    if (active && accent && state === 'normal') { c.save(); c.strokeStyle = accent; c.globalAlpha = .45 + (still ? 0 : .2 * Math.sin(t * 4)); c.lineWidth = 2; c.strokeRect(x + 6, y + 6, w - 12, h - 12); c.restore(); }
  };

  /* Rakam vuruşu: hücre çözülünce içe basılıp çıkar, neon parlar */
  const solvePrev = P.solveCell;
  P.solveCell = function (i) { (this.popAt || (this.popAt = {}))[i] = now(); return solvePrev.call(this, i); };
  const startPrev = P.start;
  P.start = function (n) { this.popAt = {}; return startPrev.call(this, n); };
  const textPrev = P.text;
  P.text = function (t, x, y, size, color, align) {
    const digits = get('digits', 'Gemini-Rakamlar-V1-Depth.jpg');
    if (size === 42 && /^[1-4]$/.test(t) && ok(digits) && this.popAt) {
      const col = Math.round((x - 86) / 120), row = Math.round((y - 399) / 120), i = row * 4 + col, at = this.popAt[i];
      if (at !== undefined && !this.record.reduced) {
        const e = now() - at;
        if (e < .6) {
          const s = e < .12 ? 1 - e / .12 * .25 : e < .3 ? .75 + (e - .12) / .18 * .4 : 1.15 - (e - .3) / .3 * .15;
          const [sx, sy, sw, sh] = DIGIT[+t - 1], H = 66 * s, W = H * sw / sh, cy = y - 17, c = this.ctx;
          c.save(); c.globalCompositeOperation = 'screen'; c.drawImage(digits, sx, sy, sw, sh, x - W / 2, cy - H / 2, W, H);
          c.globalCompositeOperation = 'lighter'; c.globalAlpha = Math.max(0, .9 - e * 1.6); c.drawImage(digits, sx, sy, sw, sh, x - W / 2, cy - H / 2, W, H);
          c.restore();
          return;
        }
      }
    }
    return textPrev.call(this, t, x, y, size, color, align);
  };

  /* Isı çubuğu: akan alev ve yıldırım */
  const heatPrev = P.heatGauge;
  P.heatGauge = function () {
    const boost = get('boost', 'Gemini-Boost-Yildirim-Cubugu.jpg');
    const hold = boost.complete; boost.__hold = true;
    /* temel çubuk (alevsiz) */
    const real = boost.src; 
    heatPrev.call(this);
    if (!ok(boost) || this.record.reduced) return;
    const c = this.ctx, f = Math.max(0, Math.min(1, this.heat / 100)), t = now();
    if (f <= 0) return;
    c.save(); c.beginPath(); c.rect(28, 210, 484 * f, 21); c.clip();
    c.globalCompositeOperation = 'lighter';
    const off = (t * 260) % 900;
    c.globalAlpha = .35 + .25 * Math.abs(Math.sin(t * 7));
    c.drawImage(boost, 380 + off, 520, 1100, 480, 28, 205, 484, 31);
    if (this.heat >= 70 && Math.sin(t * 11) > .3) {
      let s = Math.floor(t * 15); const rnd = () => (s = (s * 9301 + 49297) % 233280) / 233280;
      c.globalAlpha = 1; bolt(c, 30, 212 + rnd() * 16, 28 + 484 * f, 212 + rnd() * 16, this.overdrive > 0 ? '#ffe89a' : '#7ff6ff', rnd);
    }
    c.restore();
  };

  /* Arka plan: yavaş kayma ve nefes alan reaktör ışığı */
  const atmosPrev = P.sceneAtmosphere;
  P.sceneAtmosphere = function () {
    const c = this.ctx, t = now();
    if (this.record.reduced) return atmosPrev.call(this);
    c.save();
    const sc = 1.05, dx = Math.sin(t * .09) * 9, dy = Math.cos(t * .07) * 6;
    c.translate(270 + dx, 480 + dy); c.scale(sc, sc); c.translate(-270, -480);
    atmosPrev.call(this);
    c.restore();
    const b = .5 + .5 * Math.sin(t * 1.3);
    const g = c.createRadialGradient(270, 690, 10, 270, 690, 330);
    g.addColorStop(0, 'rgba(255,140,60,' + (0.05 + 0.09 * b) + ')'); g.addColorStop(1, 'rgba(255,140,60,0)');
    c.save(); c.fillStyle = g; c.fillRect(0, 300, 540, 660);
    const g2 = c.createRadialGradient(270, 120, 10, 270, 120, 300);
    g2.addColorStop(0, 'rgba(80,230,255,' + (0.04 + 0.06 * (1 - b)) + ')'); g2.addColorStop(1, 'rgba(80,230,255,0)');
    c.fillStyle = g2; c.fillRect(0, 0, 540, 420); c.restore();
  };
})();

/* ---------- Titreşim (haptik) + menüde AÇ/KAPA ---------- */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_VIBE) return;
  NS.V1_VIBE = true;
  const P = NS.Game.prototype;
  const KEY = 'NeonSudoku.vibe';
  let on = true;
  try { on = localStorage.getItem(KEY) !== '0'; } catch (_) {}
  const can = typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function';
  const buzz = p => { if (on && can) { try { navigator.vibrate(p); } catch (_) {} } };
  /* Olay → titreşim deseni (ms) */
  const PAT = {
    select: 8, eliminate: 12, hint: 10, link: 10, praise: 15,
    solve: 28, combo: [18, 30, 18], charge: 20,
    error: [70, 40, 70], fail: [180, 60, 260], weak: 15,
    overdrive: [25, 20, 25, 20, 90],
    timeBonus: [15, 40, 30],
    warning: [40, 60, 40, 60, 40], block: 45,
    bossHit: [35, 25, 60], blast: [50, 30, 120], phase: [60, 50, 60],
    chainStart: 20, chainStep: 14, chainBurst: [30, 30, 30, 30, 120],
    victory: [40, 70, 40, 70, 160]
  };
  const sfxPrev = P.sfx;
  P.sfx = function (name) {
    if (name === 'tick') {
      /* Süre azalınca: 5-4 sn hafif, 3-2-1 sn giderek güçlenen nabız */
      const s = Math.ceil(this.time);
      buzz(s >= 4 ? 12 : s === 3 ? [25, 90, 15] : s === 2 ? [35, 80, 25] : [50, 60, 40, 60, 30]);
    } else if (PAT[name] !== undefined) buzz(PAT[name]);
    return sfxPrev.apply(this, arguments);
  };
  /* Son 3 saniyede ekran da hafifçe titrer */
  const renderPrev = P.render;
  P.render = function () {
    const live = this.state === 'playing' && this.time > 0 && this.time <= 3 && !this.record.reduced;
    if (!live) return renderPrev.apply(this, arguments);
    const c = this.ctx, k = (3 - this.time) / 3, a = 1 + k * 2.2, t = performance.now() / 1000;
    c.save(); c.translate(Math.sin(t * 61) * a, Math.cos(t * 47) * a * .6);
    const r = renderPrev.apply(this, arguments);
    c.restore(); return r;
  };
  /* Menü: TEMA düğmesini ikiye böl, yanına TİTREŞİM ekle */
  const btnPrev = P.button;
  P.button = function (label, x, y, w, h, action, accent, name) {
    if (this.state === 'menu' && y === 572 && w === 396 && /^TEMA/.test(label)) {
      const WD = globalThis.NEON_CEH ? 1 : 0; btnPrev.call(this, label, WD ? 30 : x, y, WD ? 234 : 190, h, action, accent, name);
      return btnPrev.call(this, on ? 'TİTREŞİM AÇIK' : 'TİTREŞİM KAPALI', WD ? 276 : 278, y, WD ? 234 : 190, h, () => {
        on = !on; try { localStorage.setItem(KEY, on ? '1' : '0'); } catch (_) {}
        if (on) buzz([30, 40, 30]);
      }, false, 'vibe');
    }
    return btnPrev.apply(this, arguments);
  };
  NS.vibe = { get on() { return on; }, supported: can };
})();
