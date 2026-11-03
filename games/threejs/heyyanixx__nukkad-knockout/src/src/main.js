import { Game, W } from './game.js';
import { CPU } from './ai.js';
import { ROSTER, byId, STAGES } from './roster.js';
import { Controls, MAPS } from './input.js';
import { Audio } from './audio.js';
import { World } from './r3d/world.js';
import { toX, toY } from './r3d/common.js';
import * as THREE from 'three';

const $ = (s) => document.querySelector(s);
const $$ = (s) => document.querySelectorAll(s);
const store = {
  get(k, d) { try { const v = localStorage.getItem('nk:' + k); return v === null ? d : JSON.parse(v); } catch { return d; } },
  set(k, v) { try { localStorage.setItem('nk:' + k, JSON.stringify(v)); } catch {} },
};
const isTouch = matchMedia('(pointer: coarse)').matches || 'ontouchstart' in window;

export const SETTINGS_DEFAULTS = { quality: 'auto', sfx: true, music: true, meme: true, vibe: true, fps: false };
const set = Object.assign({}, SETTINGS_DEFAULTS, store.get('settings', {}));
const S = {
  screen: 'title', mode: 'cpu', diff: 'normal', stage: 'tapri',
  p1: 'chaiwala', p2: 'dadi', picking: 1, meme: 'off',
  game: null, cpu: null, paused: false, frame: 0, demo: null, demoCpu: null,
  unlocked: store.get('anishUnlocked', false), settingsFrom: 'title',
};

const controls = new Controls(), audio = new Audio();
audio.setSfx(set.sfx); audio.setMusic(set.music); audio.setMeme(set.meme);
controls.bindTouch($('#touch'));
const vibrate = (ms) => { if (set.vibe && navigator.vibrate) navigator.vibrate(ms); };

// ---------- 3D world ----------
const autoStart = isTouch ? 'med' : 'high';
const world = new World($('#game'), set.quality === 'auto' ? autoStart : set.quality);
const perf = { level: world.qName, drops: [], samples: [], last: performance.now(), frames: 0, fps: 0, worst: 999 };
addEventListener('resize', () => world.resize());
addEventListener('orientationchange', () => setTimeout(() => world.resize(), 250));

// ---------- screens ----------
const SCREENS = ['title', 'select', 'pause', 'result', 'settings'];
function show(id) {
  S.screen = id;
  for (const s of SCREENS) $('#' + s).classList.toggle('hidden', s !== id);
  const inFight = id === 'fight';
  $('#hud').classList.toggle('hidden', !(inFight || id === 'pause' || (id === 'settings' && S.settingsFrom === 'pause')));
  $('#topbar').classList.toggle('hidden', !inFight);
  $('#touch').classList.toggle('hidden', !(isTouch && inFight));
  if (id === 'title') { world.mode = 'menu'; startDemo(); }
  if (id === 'select') { world.mode = 'select'; S.demo = null; world.setStage(S.stage); world.setFighters(byId(S.p1), byId(S.p2)); }
}

// juicy button ripple + click tick for every button
document.addEventListener('pointerdown', (e) => {
  const b = e.target.closest('.btn, .seg button, .tile, .tog');
  if (!b) return;
  if (b.classList.contains('btn')) {
    const r = b.getBoundingClientRect(), s = Math.max(r.width, r.height), sp = document.createElement('span');
    sp.className = 'ripple'; sp.style.width = sp.style.height = s + 'px'; sp.style.left = e.clientX - r.left - s / 2 + 'px'; sp.style.top = e.clientY - r.top - s / 2 + 'px';
    b.appendChild(sp); setTimeout(() => sp.remove(), 600);
  }
  vibrate(8);
});

// ---------- title (attract mode: CPU vs CPU demo fight behind the menu) ----------
function startDemo() {
  const pool = ROSTER.filter((c) => !c.secret);
  const a = pool[Math.floor(Math.random() * pool.length)]; let b = pool[Math.floor(Math.random() * pool.length)]; if (b === a) b = pool[(pool.indexOf(a) + 3) % pool.length];
  const st = STAGES[Math.floor(Math.random() * STAGES.length)].id;
  S.demo = new Game({ p1: a, p2: b, stage: st, events: true });
  S.demoCpu = [new CPU('normal'), new CPU('normal')];
  world.setStage(st); world.setFighters(a, b);
  world.mode = 'menu';
}
const start = () => { audio.unlock(); audio.play('select'); audio.startMusic('menu'); buildSelect(); show('select'); };
$('#start-btn').addEventListener('click', start);
$('#settings-btn').addEventListener('click', () => { audio.unlock(); openSettings('title'); });

// ---------- select ----------
const tiles = [];
function buildSelect() {
  const grid = $('#grid');
  if (!tiles.length) {
    for (const c of ROSTER) {
      const b = document.createElement('button'); b.className = 'tile'; b.type = 'button'; b.dataset.id = c.id;
      b.innerHTML = `<canvas width="128" height="160"></canvas><span>${c.secret ? '???' : c.name}</span><i class="c1">1P</i><i class="c2">${S.mode === 'cpu' ? 'CPU' : '2P'}</i>`;
      b.setAttribute('aria-label', c.secret ? 'Secret fighter' : c.name);
      let taps = 0;
      b.addEventListener('click', () => {
        audio.unlock();
        if (c.secret && !S.unlocked) { taps++; audio.play('ui'); $('#pick-hint').textContent = taps < 5 ? `SECRET BOSS 🔒 — CPU ko ek baar haraao (ya ${5 - taps} baar aur tap karo)` : ''; if (taps >= 5) unlockAnish(); return; }
        pick(c.id);
      });
      grid.appendChild(b); tiles.push(b);
      world.portrait(c, b.querySelector('canvas'));
    }
  }
  refreshSelect();
}
function unlockAnish() { S.unlocked = true; store.set('anishUnlocked', true); audio.play('win'); audio.event('airhorn'); $('#pick-hint').textContent = '🔓 HEYY ANISH UNLOCKED!'; refreshSelect(); }
function pick(id) {
  audio.play('select');
  if (S.picking === 1) { S.p1 = id; S.picking = 2; } else { S.p2 = id; S.picking = 1; }
  world.setFighters(byId(S.p1), byId(S.p2));
  refreshSelect();
}
const statBars = (c) => {
  const v = { POWER: (c.dmgMul - 0.8) / 0.45, SPEED: (c.speed - 2.9) / 1.3, REACH: (c.reachMul - 0.95) / 0.25, JUGAAD: (c.meterMul - 0.95) / 0.3 };
  return Object.entries(v).map(([k, x]) => `<div><span>${k}</span><i style="width:${Math.round(25 + Math.max(0, Math.min(1, x)) * 75)}%"></i></div>`).join('');
};
function refreshSelect() {
  for (const t of tiles) {
    const c = byId(t.dataset.id), locked = !!c.secret && !S.unlocked;
    t.classList.toggle('locked', locked); t.classList.toggle('p1', S.p1 === c.id); t.classList.toggle('p2', S.p2 === c.id);
    t.querySelector('span').textContent = locked ? '??? SECRET' : c.name;
    t.querySelector('.c2').textContent = S.mode === 'cpu' ? 'CPU' : '2P';
  }
  for (const [side, id] of [['p1', S.p1], ['p2', S.p2]]) {
    const card = $('#card-' + side), c = byId(id);
    card.querySelector('.nm').textContent = c.name; card.querySelector('.tg').textContent = c.tag + (c.parody ? ' (parody)' : '');
    card.querySelector('.sp').textContent = 'JUGAAD: ' + c.superName;
    card.querySelector('.stats').innerHTML = statBars(c);
    card.classList.toggle('active', (S.picking === 1) === (side === 'p1'));
  }
  $('#card-p2 .who').textContent = S.mode === 'cpu' ? 'CPU' : '2P';
  $('#pick-hint').textContent = S.picking === 1 ? 'Picking 1P — tap a fighter' : `Picking ${S.mode === 'cpu' ? 'CPU' : '2P'} — tap the opponent`;
  for (const [seg, key] of [['#mode-seg', 'mode'], ['#diff-seg', 'diff'], ['#stage-seg', 'stage'], ['#meme-seg', 'meme']])
    for (const b of $$(seg + ' button')) b.classList.toggle('on', b.dataset[key] === S[key]);
  const lb = Object.entries(store.get('wins', {})).sort((x, y) => y[1] - x[1]).slice(0, 3);
  $('#leader').textContent = lb.length ? '🏆 TOP: ' + lb.map(([id, n]) => byId(id).name + ' ×' + n).join(' · ') : '';
  $('#diff-seg').style.opacity = S.mode === 'cpu' ? 1 : 0.35;
}
for (const [seg, key] of [['#mode-seg', 'mode'], ['#diff-seg', 'diff'], ['#stage-seg', 'stage'], ['#meme-seg', 'meme']])
  for (const b of $$(seg + ' button')) b.addEventListener('click', () => { S[key] = b.dataset[key]; audio.play('ui'); if (key === 'stage') world.setStage(S.stage); refreshSelect(); });
$('#fight-btn').addEventListener('click', () => startFight());
$('#back-btn').addEventListener('click', () => { audio.play('ui'); show('title'); });
$('#sel-settings').addEventListener('click', () => openSettings('select'));

// ---------- settings ----------
function openSettings(from) { S.settingsFrom = from; syncSettings(); show('settings'); }
function syncSettings() {
  for (const b of $$('#q-seg button')) b.classList.toggle('on', b.dataset.q === set.quality);
  for (const t of $$('.tog')) t.classList.toggle('on', !!set[t.dataset.set]);
  $('#q-info').textContent = `Now rendering: ${world.qName.toUpperCase()}${set.quality === 'auto' ? ' (auto — drops itself if FPS < 45)' : ''} · ${perf.fps || '--'} FPS`;
  $('#fps').classList.toggle('hidden', !set.fps);
}
function saveSettings() { store.set('settings', set); }
for (const b of $$('#q-seg button')) b.addEventListener('click', () => {
  set.quality = b.dataset.q; saveSettings();
  const q = set.quality === 'auto' ? autoStart : set.quality;
  if (q !== world.qName) { world.setQuality(q); perf.level = q; }
  audio.play('ui'); syncSettings();
});
for (const t of $$('.tog')) t.addEventListener('click', () => {
  const k = t.dataset.set; set[k] = !set[k]; saveSettings();
  if (k === 'sfx') audio.setSfx(set.sfx); if (k === 'music') audio.setMusic(set.music); if (k === 'meme') { audio.setMeme(set.meme); if (set.meme) audio.play('airhorn'); }
  audio.play('ui'); syncSettings();
});
$('#settings-done').addEventListener('click', () => { audio.play('ui'); show(S.settingsFrom); if (S.settingsFrom === 'pause') $('#hud').classList.remove('hidden'); });

// ---------- fight ----------
const hud = {
  side: [0, 1].map((i) => ({ root: $('#hud .s' + i), name: $(`#hud .s${i} .pname b`), who: $(`#hud .s${i} .who`), hp: $(`#hud .s${i} .hp`), fill: $(`#hud .s${i} .hp .fill`), trail: $(`#hud .s${i} .hp .trail`), meter: $(`#hud .s${i} .meter`), mfill: $(`#hud .s${i} .meter .fill`), pips: $$(`#hud .s${i} .pips i`), combo: $('#hud .c' + i), lastHp: 100, comboShown: 0 })),
  timer: $('#timer'), round: $('#round-lbl'), banner: $('#banner'), texts: $('#texts'), ev: $('#eventtag'), fps: $('#fps'),
};
const textEls = new Map();

function startFight(opts = {}) {
  Object.assign(S, opts);
  audio.unlock();
  S.demo = null;
  S.game = new Game({ p1: byId(S.p1), p2: byId(S.p2), stage: S.stage, meme: S.meme === 'on' });
  S.cpu = S.mode === 'cpu' ? new CPU(S.diff) : null;
  S.paused = false; S.resultShown = false;
  hookGame(S.game, true);
  world.setStage(S.stage); world.setFighters(byId(S.p1), byId(S.p2)); world.fx.clear();
  world.mode = 'fight';
  for (let i = 0; i < 2; i++) { const h = hud.side[i]; h.name.textContent = S.game.f[i].char.name; h.who.textContent = i === 0 ? '1P' : S.mode === 'cpu' ? 'CPU · ' + S.diff.toUpperCase() : '2P'; h.lastHp = 100; }
  for (const el of textEls.values()) el.remove(); textEls.clear();
  audio.startMusic('fight');
  show('fight');
}

function hookGame(g, live) {
  g.onSound = live ? (n) => { audio.event(n); if (window.NK.rec) window.NK.rec.push([window.NK.recFrame, n]); } : null;
  g.onEvent = (type, d) => {
    const fx = world.fx;
    if (!fx) return;
    if (type === 'hit') {
      fx.impact(d.x, d.y, { big: d.big, dir: d.dir, superHit: d.super });
      if (live) { flash(d.big ? 0.35 : 0.12, d.super ? '#ffd98a' : '#ffffff'); vibrate(d.big ? 40 : 15); const h = hud.side[d.side]; h.hp.classList.remove('hit'); void h.hp.offsetWidth; h.hp.classList.add('hit'); }
    } else if (type === 'block') { fx.impact(d.x, d.y, { blocked: true }); if (live) vibrate(8); }
    else if (type === 'super') {
      const f = g.f[d.side]; fx.burst(toX(f.x), 1.0, new THREE.Color(f.char.superColor).getHex(), world.q.level === 'low' ? 24 : 60, 0.11);
      if (live) { cutin(f); flash(0.5, f.char.superColor); vibrate(60); }
    } else if (type === 'ko') {
      const f = g.f[d.loser]; fx.burst(toX(f.x), 1.0, 0xffd36b, 90, 0.16); fx.shock(f.x, 0xffd36b);
      if (live) { flash(0.9, '#ffffff'); vibrate([60, 40, 120]); }
    } else if (type === 'fight' && live) flash(0.25, '#e3b65a');
  };
}

// screen flash overlay
let flashV = 0;
function flash(v, color = '#ffffff') { flashV = Math.max(flashV, v); $('#flash').style.background = color; }

// super cut-in: portrait + super name sliding across the screen
function cutin(f) {
  const el = $('#cutin');
  el.className = 's' + f.side;
  el.querySelector('b').textContent = f.char.superName;
  el.querySelector('b').style.color = f.char.superColor === '#ffffff' ? '#fff' : f.char.superColor;
  el.querySelector('i').textContent = f.char.name;
  world.portrait(f.char, el.querySelector('canvas'));
  const band = el.querySelector('.cut-band'); band.style.animation = 'none'; void band.offsetWidth; band.style.animation = '';
  $('#speedlines').classList.add('on');
}

function pause(on) {
  if (!S.game || (S.screen !== 'fight' && S.screen !== 'pause')) return;
  S.paused = on; show(on ? 'pause' : 'fight'); audio.play('ui');
  if (on) $('#hud').classList.remove('hidden');
}
$('#pause-btn').addEventListener('click', () => pause(true));
$('#resume-btn').addEventListener('click', () => pause(false));
$('#restart-btn').addEventListener('click', () => startFight());
$('#p-settings').addEventListener('click', () => openSettings('pause'));
$('#quit-btn').addEventListener('click', () => { S.game = null; audio.startMusic('menu'); buildSelect(); show('select'); });

const CAPTIONS = ['Gaya tu! 👋', 'Chhota pack, bada dhamaka', 'Bhai ne bola tha', 'Ghar jaake practice kar', 'Ye toh trailer tha, picture abhi baaki hai', 'Itna sannata kyun hai bhai?', 'Mummy se bolna mat', 'Skill issue detected'];
function showResult() {
  const g = S.game, wnr = g.winner, [a, b] = g.f;
  let title, sub;
  if (wnr === null) { title = 'BARABAR! DRAW'; sub = 'Dono hi ghar jao.'; }
  else {
    const wf = g.f[wnr];
    title = (S.mode === 'cpu' ? (wnr === 0 ? 'JEET GAYA! 🏆' : 'HAAR GAYA 😵') : `${wnr === 0 ? '1P' : '2P'} JEETA!`);
    sub = `${wf.char.name} wins — "${CAPTIONS[Math.floor(Math.random() * CAPTIONS.length)]}"`;
  }
  $('#res-title').textContent = title; $('#res-sub').textContent = sub;
  const lb = store.get('wins', {}); if (wnr !== null) { const k = g.f[wnr].char.id; lb[k] = (lb[k] || 0) + 1; store.set('wins', lb); }
  const top = Object.entries(lb).sort((x, y) => y[1] - x[1])[0];
  $('#res-stats').innerHTML = `<div>DAMAGE<b>${a.stats.dmgDealt} - ${b.stats.dmgDealt}</b></div><div>BEST COMBO<b>${a.stats.maxCombo} - ${b.stats.maxCombo}</b></div><div>TOP FIGHTER<b>${top ? byId(top[0]).name.split(' ')[0] + ' ×' + top[1] : '-'}</b></div>`;
  const newUnlock = S.mode === 'cpu' && wnr === 0 && !S.unlocked;
  if (newUnlock) { S.unlocked = true; store.set('anishUnlocked', true); }
  $('#res-unlock').classList.toggle('hidden', !newUnlock);
  show('result');
}
$('#rematch-btn').addEventListener('click', () => startFight());
$('#share-btn').addEventListener('click', shareWin);
$('#reselect-btn').addEventListener('click', () => { S.game = null; audio.startMusic('menu'); buildSelect(); show('select'); });
async function shareWin() {
  world.render(S.game, 0.001, { shake: false });
  const src = $('#game'), card = document.createElement('canvas'); card.width = 960; card.height = 600;
  const c = card.getContext('2d');
  c.fillStyle = '#060608'; c.fillRect(0, 0, 960, 600);
  const sw = src.width, sh = src.height, k = Math.max(960 / sw, 540 / sh);
  c.drawImage(src, (960 - sw * k) / 2, (540 - sh * k) / 2, sw * k, sh * k);
  c.fillStyle = '#e3b65a'; c.fillRect(0, 540, 960, 60); c.fillStyle = '#060608'; c.font = '28px Anton, Impact, sans-serif'; c.textAlign = 'center';
  c.fillText(($('#res-title').textContent + ' — ' + $('#res-sub').textContent).slice(0, 70), 480, 580);
  const text = `${$('#res-title').textContent} ${$('#res-sub').textContent} | Nukkad Knockout 3D by HEYYANIXX: ${location.origin}${location.pathname}`;
  const blob = await new Promise((r) => card.toBlob(r, 'image/png'));
  const file = blob && new File([blob], 'nukkad-knockout-win.png', { type: 'image/png' });
  try { if (file && navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], text, title: 'Nukkad Knockout 3D' }); return; } } catch (e) { if (e && e.name === 'AbortError') return; }
  if (blob) { const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'nukkad-knockout-win.png'; a.click(); }
  open('https://wa.me/?text=' + encodeURIComponent(text), '_blank', 'noopener');
}

// ---------- keyboard ----------
addEventListener('keydown', (e) => {
  if (e.repeat) return;
  const inGame = S.screen === 'fight' || S.screen === 'pause';   // not on select, so typing ANISH never toggles sound
  if (inGame && e.code === 'KeyM') { set.music = !set.music; audio.setMusic(set.music); saveSettings(); }
  if (inGame && e.code === 'KeyN') { set.sfx = !set.sfx; audio.setSfx(set.sfx); saveSettings(); }
  if (S.screen === 'title' && (e.code === 'Enter' || e.code === 'Space')) start();
  else if (S.screen === 'select') {
    if (e.code === 'Enter') startFight();
    if (e.code === 'Escape') show('title');
    const ids = ROSTER.filter((c) => !c.secret || S.unlocked).map((c) => c.id);
    const cur = S.picking === 1 ? S.p1 : S.p2;
    if (e.code === 'ArrowRight' || e.code === 'ArrowLeft') { const i = ids.indexOf(cur), n = (i + (e.code === 'ArrowRight' ? 1 : -1) + ids.length) % ids.length; if (S.picking === 1) S.p1 = ids[n]; else S.p2 = ids[n]; audio.play('ui'); world.setFighters(byId(S.p1), byId(S.p2)); refreshSelect(); }
    if (e.code === 'Tab') { e.preventDefault(); S.picking = S.picking === 1 ? 2 : 1; refreshSelect(); }
    if (e.code === 'Digit1') { S.diff = 'easy'; refreshSelect(); } if (e.code === 'Digit2') { S.diff = 'normal'; refreshSelect(); } if (e.code === 'Digit3') { S.diff = 'hard'; refreshSelect(); }
    S.typed = ((S.typed || '') + e.key.toUpperCase()).slice(-5); if (S.typed === 'ANISH' && !S.unlocked) unlockAnish();
  } else if (S.screen === 'fight' && (e.code === 'Escape' || (e.code === 'KeyP' && S.mode === 'cpu'))) pause(true);
  else if (S.screen === 'pause' && (e.code === 'Escape' || e.code === 'KeyP')) pause(false);
  else if (S.screen === 'settings' && e.code === 'Escape') show(S.settingsFrom);
  else if (S.screen === 'result' && e.code === 'Enter') startFight();
});
document.addEventListener('visibilitychange', () => { if (document.hidden && S.screen === 'fight') pause(true); });

// ---------- HUD (DOM) ----------
const proj = new THREE.Vector3();
function screenPos(x, y) {
  proj.set(toX(x), toY(y), 0.3).project(world.camera);
  return [(proj.x * 0.5 + 0.5) * innerWidth, (-proj.y * 0.5 + 0.5) * innerHeight];
}
let bannerKey = null;
function updateHud(g) {
  for (let i = 0; i < 2; i++) {
    const f = g.f[i], h = hud.side[i];
    h.fill.style.transform = `scaleX(${Math.max(0, f.hp) / f.maxHp})`;
    h.trail.style.transform = `scaleX(${Math.max(0, f.trailHp) / f.maxHp})`;
    h.hp.classList.toggle('low', f.hp <= 25);
    h.mfill.style.transform = `scaleX(${f.meter / 100})`;
    h.meter.classList.toggle('full', f.meter >= 100);
    h.pips.forEach((p, k) => p.classList.toggle('on', g.wins[i] > k));
    // combo counter shows on the attacker's side
    const opp = g.f[1 - i], n = opp.comboHits;
    if (n >= 2) { if (n !== h.comboShown) { h.combo.querySelector('b').textContent = n; h.combo.querySelector('em').textContent = ['', '', 'DHISHUM!', 'BHAUKAAL!', 'JHAKAAS!', 'OP BOLTE!', 'KHATAM!'][Math.min(n, 6)] || 'GAME OVER BETA!'; h.combo.classList.remove('bump'); void h.combo.offsetWidth; h.combo.classList.add('bump'); h.comboShown = n; } h.combo.classList.add('on'); h.comboHold = 50; }
    else if (h.comboHold > 0) { if (--h.comboHold === 0) { h.combo.classList.remove('on'); h.comboShown = 0; } }
  }
  const secs = Math.ceil(g.timer / 60);
  hud.timer.textContent = Math.max(0, secs); hud.timer.classList.toggle('urgent', secs <= 10 && g.phase === 'fight');
  hud.round.textContent = g.isFinalRound ? 'FINAL ROUND' : 'ROUND ' + g.round;
  // banner
  const bd = g.bannerData;
  if (bd) {
    const key = bd.text + bd.sub + bd.max + g.round;
    if (key !== bannerKey || !hud.banner.classList.contains('show')) {
      bannerKey = key;
      hud.banner.querySelector('b').textContent = bd.text; hud.banner.querySelector('span').textContent = bd.sub;
      hud.banner.className = ''; void hud.banner.offsetWidth; hud.banner.className = 'show' + (bd.text === 'K.O.!' ? ' ko' : '');
      hud.banner.querySelector('b').style.color = bd.text === 'K.O.!' ? '' : bd.color;
    }
    hud.banner.style.opacity = Math.min(1, bd.life / 12);
  } else { hud.banner.style.opacity = 0; hud.banner.className = ''; bannerKey = null; }
  // pop texts (sim) + callouts
  const alive = new Set();
  for (const t of g.fx.texts) {
    alive.add(t);
    let el = textEls.get(t);
    if (!el) { el = document.createElement('div'); el.className = 'pop' + (t.box ? ' box' : ''); el.textContent = t.text; el.style.color = t.color; el.style.fontSize = Math.round(t.size * Math.min(1.1, innerHeight / 540)) + 'px'; hud.texts.appendChild(el); textEls.set(t, el); }
    const [sx, sy] = screenPos(t.x, t.y);
    el.style.left = sx + 'px'; el.style.top = sy + 'px'; el.style.opacity = Math.min(1, t.life / 15);
  }
  for (const c of g.callouts) {
    if (/^\d+ HITS/.test(c.text)) continue;   // the big combo counter shows this
    alive.add(c);
    let el = textEls.get(c);
    if (!el) { el = document.createElement('div'); el.className = `callout s${c.side}` + (c.big ? ' big' : ''); el.textContent = c.text; el.style.color = c.color; el.style.setProperty('--from', c.side ? '80px' : '-80px'); const stack = g.callouts.filter((o) => o.side === c.side && o !== c && textEls.has(o)).length; el.style.marginTop = stack * 34 + 'px'; hud.texts.appendChild(el); textEls.set(c, el); }
    el.style.opacity = Math.min(1, c.life / 12);
  }
  for (const [k, el] of textEls) if (!alive.has(k)) { el.remove(); textEls.delete(k); }
  // chaos event tag
  const e = g.event; hud.ev.classList.toggle('on', !!e);
  if (e) hud.ev.textContent = { cow: '🐄 GAI ON THE FIELD', powercut: '💡 POWER CUT', rain: '🌧 BAARISH', kite: '🪁 PATANG', lag: '📶 LAG', moon: '🌙 LOW GRAVITY' }[e.type] || '';
  $('#touch .super')?.classList.toggle('ready', g.f[0].meter >= 100);
  // lag glitch
  $('#game').style.filter = e && e.type === 'lag' && (g.frame % 20 < 3) ? 'hue-rotate(90deg) contrast(1.4)' : '';
}

// ---------- performance: FPS + auto quality ----------
const LEVELS = ['low', 'med', 'high'];
function trackFps(now) {
  perf.frames++;
  if (now - perf.last >= 1000) {
    perf.fps = Math.round((perf.frames * 1000) / (now - perf.last)); perf.frames = 0; perf.last = now;
    perf.samples.push(perf.fps); if (perf.samples.length > 120) perf.samples.shift();
    hud.fps.textContent = `${perf.fps} FPS · ${world.qName.toUpperCase()}`;
    window.NK.fps = perf.fps;
    // auto quality: two slow seconds in a fight -> drop one level
    if (set.quality === 'auto' && (S.screen === 'fight' || S.screen === 'title') && !document.hidden) {
      const last2 = perf.samples.slice(-2);
      if (last2.length === 2 && last2.every((x) => x < 45) && world.qName !== 'low' && now - (perf.lastChange || 0) > 3000) {
        const next = LEVELS[LEVELS.indexOf(world.qName) - 1];
        perf.drops.push({ from: world.qName, to: next, fps: perf.fps, t: Math.round(now) });
        world.setQuality(next); perf.lastChange = now;
      }
    }
  }
}

// ---------- main loop: fixed 60 Hz simulation, render every animation frame ----------
const STEP = 1000 / 60;
let last = performance.now(), acc = 0;
function simStep(g) {
  const steps = g.meme ? 2 : 1;   // meme mode = double speed
  for (let n = 0; n < steps; n++) {
    const in1 = S.autoP1 ? S.autoP1.think(g.f[0], g.f[1], g) : controls.read(S.mode === 'cpu' ? MAPS.solo : MAPS.p1, 0, true);
    const in2 = S.cpu ? S.cpu.think(g.f[1], g.f[0], g) : controls.read(MAPS.p2, 1, false);
    g.step([in1, in2]); controls.endStep();
  }
}
function demoStep(g) {
  g.step([S.demoCpu[0].think(g.f[0], g.f[1], g), S.demoCpu[1].think(g.f[1], g.f[0], g)]);
  if (g.phase === 'over' && g.phaseT > 60) startDemo();
}
function frame(dtMs) {
  S.frame++;
  const dt = dtMs / 1000;
  const g = S.game;
  if (g && ['fight', 'result', 'pause'].includes(S.screen) || (g && S.screen === 'settings' && S.settingsFrom === 'pause')) {
    if (!S.paused && S.screen !== 'settings') {
      acc += dtMs;
      while (acc >= STEP) { simStep(g); acc -= STEP; }
      if (g.phase === 'over' && !S.resultShown) { S.resultShown = true; setTimeout(showResult, 900); }
    }
    world.render(g, S.paused ? 0 : dt);
    updateHud(g);
    if (!(g.freeze > 0)) $('#speedlines').classList.remove('on'), $('#cutin').classList.add('hidden'); else $('#cutin').classList.remove('hidden');
  } else if (S.screen === 'title' || (S.screen === 'settings' && S.settingsFrom === 'title')) {
    if (!S.demo) startDemo();
    if (!S.demo.onEvent) hookGame(S.demo, false);
    acc += dtMs; while (acc >= STEP) { demoStep(S.demo); acc -= STEP; }
    world.render(S.demo, dt);
  } else {
    acc = 0;
    world.render(null, dt, { showroom: true });
  }
  flashV *= Math.pow(0.0005, dt); if (flashV < 0.01) flashV = 0;
  $('#flash').style.opacity = flashV;
}
function loop(now) {
  requestAnimationFrame(loop);
  if (window.NK.manual) return;
  const dt = Math.min(100, now - last); last = now;
  trackFps(now);
  frame(dt);
}

// test / debug hooks (used by the automated browser tests and the video capture)
window.NK = {
  S, set, world, perf, audio, controls, startFight, show, frame, fps: 0, manual: false, errors: [], CPU, rec: null, recFrame: 0,
  get game() { return S.game; },
  advance(frames = 1) { for (let i = 0; i < frames; i++) { window.NK.recFrame++; frame(STEP); } },
  unlock: unlockAnish,
};
addEventListener('error', (e) => window.NK.errors.push(String(e.message)));

show('title');
setTimeout(() => $('#loading').classList.add('gone'), 250);
requestAnimationFrame(loop);
if ('serviceWorker' in navigator && location.protocol === 'https:') navigator.serviceWorker.register('./sw.js').catch(() => {});
