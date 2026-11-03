import { Game, W, H } from './game.js';
import { CPU } from './ai.js';
import { ROSTER, byId } from './roster.js';
import { render, drawPortrait } from './render.js';
import { Controls, MAPS } from './input.js';
import { Audio } from './audio.js';

const $ = (s) => document.querySelector(s);
const canvas = $('#game'), ctx = canvas.getContext('2d');
const controls = new Controls(), audio = new Audio();
const store = {
  get(k, d) { try { const v = localStorage.getItem('nk:' + k); return v === null ? d : JSON.parse(v); } catch { return d; } },
  set(k, v) { try { localStorage.setItem('nk:' + k, JSON.stringify(v)); } catch {} },
};

const S = {
  screen: 'title', mode: 'cpu', diff: 'normal', stage: 'tapri',
  p1: 'chaiwala', p2: 'dadi', picking: 1, meme: 'off',
  game: null, cpu: null, paused: false, frame: 0,
  unlocked: store.get('anishUnlocked', false),
  sfx: store.get('sfx', true), music: store.get('music', true),
};
audio.setSfx(S.sfx); audio.setMusic(S.music);
const isTouch = matchMedia('(pointer: coarse)').matches || 'ontouchstart' in window;
controls.bindTouch($('#touch'));

// ---------- canvas sizing (crisp on retina) ----------
function resize() {
  const r = canvas.getBoundingClientRect();
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = Math.round(r.width * dpr); canvas.height = Math.round(r.height * dpr);
  ctx.setTransform(canvas.width / W, 0, 0, canvas.height / H, 0, 0);
}
addEventListener('resize', resize); addEventListener('orientationchange', () => setTimeout(resize, 200));

// ---------- screens ----------
function show(id) {
  S.screen = id;
  for (const s of ['title', 'select', 'pause', 'result']) $('#' + s).classList.toggle('hidden', s !== id && !(id === 'pause' && s === 'none'));
  const inFight = id === 'fight' || id === 'pause' || id === 'result';
  $('#topbar').classList.toggle('hidden', id !== 'fight');
  $('#touch').classList.toggle('hidden', !(isTouch && id === 'fight'));
}

// title
const start = () => { audio.unlock(); audio.play('select'); audio.startMusic('menu'); buildSelect(); show('select'); };
$('#start-btn').addEventListener('click', start);
$('#title').addEventListener('pointerdown', (e) => { if (e.target.id !== 'start-btn') start(); });

// select
const tiles = [];
function availableRoster() { return ROSTER; }
function buildSelect() {
  const grid = $('#grid');
  if (!tiles.length) {
    for (const c of availableRoster()) {
      const b = document.createElement('button'); b.className = 'tile'; b.type = 'button'; b.dataset.id = c.id;
      b.innerHTML = `<canvas width="160" height="200"></canvas><span>${c.secret ? '???' : c.name}</span><i class="c1">1P</i><i class="c2">2P</i>`;
      b.setAttribute('aria-label', c.secret ? 'Secret fighter' : c.name);
      let taps = 0;
      b.addEventListener('click', () => {
        audio.unlock();
        if (c.secret && !S.unlocked) { taps++; audio.play('ui'); $('#pick-hint').textContent = taps < 5 ? `SECRET BOSS 🔒 — CPU ko ek baar haraao (ya ${5 - taps} baar aur tap karo)` : ''; if (taps >= 5) unlockAnish(); return; }
        pick(c.id);
      });
      grid.appendChild(b); tiles.push(b);
    }
  }
  refreshSelect();
}
function unlockAnish() { S.unlocked = true; store.set('anishUnlocked', true); audio.play('win'); $('#pick-hint').textContent = '🔓 HEYY ANISH UNLOCKED!'; refreshSelect(); }
function pick(id) {
  audio.play('select');
  if (S.picking === 1) { S.p1 = id; S.picking = 2; } else { S.p2 = id; S.picking = 1; }
  refreshSelect();
}
function refreshSelect() {
  for (const t of tiles) {
    const c = byId(t.dataset.id), locked = !!c.secret && !S.unlocked;
    t.classList.toggle('locked', locked); t.classList.toggle('p1', S.p1 === c.id); t.classList.toggle('p2', S.p2 === c.id);
    t.querySelector('span').textContent = locked ? '??? SECRET' : c.name;
    drawPortrait(t.querySelector('canvas'), c, 0);
  }
  for (const [side, id] of [['p1', S.p1], ['p2', S.p2]]) {
    const card = $('#card-' + side), c = byId(id);
    card.querySelector('.nm').textContent = c.name; card.querySelector('.tg').textContent = c.tag + (c.parody ? ' (parody)' : '');
    card.querySelector('.sp').textContent = 'JUGAAD: ' + c.superName;
    card.classList.toggle('active', (S.picking === 1) === (side === 'p1'));
    drawPortrait(card.querySelector('canvas'), c, S.frame);
  }
  $('#card-p2 .who').textContent = S.mode === 'cpu' ? 'CPU' : '2P';
  $('#pick-hint').textContent = S.picking === 1 ? 'Picking 1P — tap a fighter' : `Picking ${S.mode === 'cpu' ? 'CPU' : '2P'} — tap the opponent`;
  for (const [seg, key] of [['#mode-seg', 'mode'], ['#diff-seg', 'diff'], ['#stage-seg', 'stage'], ['#meme-seg', 'meme']])
    for (const b of document.querySelectorAll(seg + ' button')) b.classList.toggle('on', b.dataset[key] === S[key]);
  const lb = Object.entries(store.get('wins', {})).sort((x, y) => y[1] - x[1]).slice(0, 3);
  $('#leader').textContent = lb.length ? '🏆 TOP: ' + lb.map(([id, n]) => byId(id).name + ' ×' + n).join(' · ') : '';
  $('#diff-seg').style.opacity = S.mode === 'cpu' ? 1 : 0.35;
}
for (const [seg, key] of [['#mode-seg', 'mode'], ['#diff-seg', 'diff'], ['#stage-seg', 'stage'], ['#meme-seg', 'meme']])
  for (const b of document.querySelectorAll(seg + ' button')) b.addEventListener('click', () => { S[key] = b.dataset[key]; audio.play('ui'); refreshSelect(); });
$('#fight-btn').addEventListener('click', () => startFight());

// ---------- fight ----------
function startFight(opts = {}) {
  Object.assign(S, opts);
  audio.unlock();
  S.game = new Game({ p1: byId(S.p1), p2: byId(S.p2), stage: S.stage, meme: S.meme === 'on' });
  S.cpu = S.mode === 'cpu' ? new CPU(S.diff) : null;
  S.paused = false; S.resultShown = false;
  S.game.onSound = (n) => audio.play(n);
  audio.startMusic('fight');
  show('fight'); resize();
}
function pause(on) {
  if (!S.game || (S.screen !== 'fight' && S.screen !== 'pause')) return;
  S.paused = on; show(on ? 'pause' : 'fight'); audio.play('ui');
  if (on) $('#pause').classList.remove('hidden');
}
$('#pause-btn').addEventListener('click', () => pause(true));
$('#resume-btn').addEventListener('click', () => pause(false));
$('#quit-btn').addEventListener('click', () => { S.game = null; audio.startMusic('menu'); buildSelect(); show('select'); });
function setSfx(on) { S.sfx = on; audio.setSfx(on); store.set('sfx', on); syncAudioLabels(); }
function setMusic(on) { S.music = on; audio.setMusic(on); store.set('music', on); syncAudioLabels(); }
function syncAudioLabels() {
  $('#sfx-btn').textContent = S.sfx ? '🔊' : '🔇'; $('#music-btn').style.opacity = S.music ? 1 : 0.4;
  $('#p-sfx').textContent = 'SFX: ' + (S.sfx ? 'ON' : 'OFF'); $('#p-music').textContent = 'MUSIC: ' + (S.music ? 'ON' : 'OFF');
}
$('#sfx-btn').addEventListener('click', () => setSfx(!S.sfx)); $('#music-btn').addEventListener('click', () => setMusic(!S.music));
$('#p-sfx').addEventListener('click', () => setSfx(!S.sfx)); $('#p-music').addEventListener('click', () => setMusic(!S.music));
syncAudioLabels();

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
  show('result'); $('#result').classList.remove('hidden');
}
$('#rematch-btn').addEventListener('click', () => startFight());
$('#share-btn').addEventListener('click', shareWin);
async function shareWin() {
  // build a win card image from the game canvas + the headline
  const card = document.createElement('canvas'); card.width = 960; card.height = 600;
  const c = card.getContext('2d');
  c.fillStyle = '#060608'; c.fillRect(0, 0, 960, 600); c.drawImage(canvas, 0, 0, 960, 540);
  c.fillStyle = '#e3b65a'; c.fillRect(0, 540, 960, 60); c.fillStyle = '#060608'; c.font = 'bold 26px Impact, Arial Black, sans-serif'; c.textAlign = 'center';
  c.fillText(($('#res-title').textContent + ' — ' + $('#res-sub').textContent).slice(0, 70), 480, 580);
  const text = `${$('#res-title').textContent} ${$('#res-sub').textContent} | Nukkad Knockout by HEYYANIXX: ${location.origin}${location.pathname}`;
  const blob = await new Promise((r) => card.toBlob(r, 'image/png'));
  const file = blob && new File([blob], 'nukkad-knockout-win.png', { type: 'image/png' });
  try {
    if (file && navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], text, title: 'Nukkad Knockout' }); return; }
  } catch (e) { if (e && e.name === 'AbortError') return; }
  if (blob) { const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'nukkad-knockout-win.png'; a.click(); }
  open('https://wa.me/?text=' + encodeURIComponent(text), '_blank', 'noopener');
}
$('#reselect-btn').addEventListener('click', () => { S.game = null; audio.startMusic('menu'); buildSelect(); show('select'); });

// ---------- keyboard shortcuts ----------
addEventListener('keydown', (e) => {
  if (e.repeat) return;
  if (e.code === 'KeyM') setMusic(!S.music);
  if (e.code === 'KeyN') setSfx(!S.sfx);
  if (S.screen === 'title' && (e.code === 'Enter' || e.code === 'Space')) start();
  else if (S.screen === 'select') {
    if (e.code === 'Enter') startFight();
    const ids = ROSTER.filter((c) => !c.secret || S.unlocked).map((c) => c.id);
    const cur = S.picking === 1 ? S.p1 : S.p2;
    if (e.code === 'ArrowRight' || e.code === 'ArrowLeft') { const i = ids.indexOf(cur), n = (i + (e.code === 'ArrowRight' ? 1 : -1) + ids.length) % ids.length; if (S.picking === 1) S.p1 = ids[n]; else S.p2 = ids[n]; audio.play('ui'); refreshSelect(); }
    if (e.code === 'Tab') { e.preventDefault(); S.picking = S.picking === 1 ? 2 : 1; refreshSelect(); }
    if (e.code === 'Digit1') { S.diff = 'easy'; refreshSelect(); } if (e.code === 'Digit2') { S.diff = 'normal'; refreshSelect(); } if (e.code === 'Digit3') { S.diff = 'hard'; refreshSelect(); }
    S.typed = ((S.typed || '') + e.key.toUpperCase()).slice(-5); if (S.typed === 'ANISH' && !S.unlocked) unlockAnish();
  } else if (S.screen === 'fight' && (e.code === 'Escape' || (e.code === 'KeyP' && S.mode === 'cpu'))) pause(true);
  else if (S.screen === 'pause' && (e.code === 'Escape' || e.code === 'KeyP')) pause(false);
  else if (S.screen === 'result' && e.code === 'Enter') startFight();
});
document.addEventListener('visibilitychange', () => { if (document.hidden && S.screen === 'fight') pause(true); });

// ---------- main loop: fixed 60 Hz simulation, render every animation frame ----------
const STEP = 1000 / 60;
let last = performance.now(), acc = 0, fpsFrames = 0, fpsT = last;
function loop(now) {
  requestAnimationFrame(loop);
  const dt = Math.min(100, now - last); last = now;
  fpsFrames++; if (now - fpsT >= 1000) { window.NK.fps = Math.round((fpsFrames * 1000) / (now - fpsT)); fpsFrames = 0; fpsT = now; }
  S.frame++;
  const g = S.game;
  if (g && (S.screen === 'fight' || S.screen === 'result' || S.screen === 'pause')) {
    if (!S.paused) {
      acc += dt;
      const steps = g.meme ? 2 : 1;   // meme mode = double speed
      while (acc >= STEP) {
        for (let n = 0; n < steps; n++) {
          const in1 = controls.read(S.mode === 'cpu' ? MAPS.solo : MAPS.p1, 0, true);
          const in2 = S.cpu ? S.cpu.think(g.f[1], g.f[0], g) : controls.read(MAPS.p2, 1, false);
          g.step([in1, in2]); controls.endStep();
        }
        acc -= STEP;
      }
      if (g.phase === 'over' && !S.resultShown) { S.resultShown = true; setTimeout(showResult, 600); }
    }
    render(ctx, g, S.frame, { labels: S.mode === 'cpu' ? ['1P · YOU', 'CPU · ' + S.diff.toUpperCase()] : ['1P', '2P'] });
  } else {
    drawMenuBackdrop();
    acc = 0;
    if (S.screen === 'select' && S.frame % 4 === 0) for (const side of ['p1', 'p2']) drawPortrait($('#card-' + side + ' canvas'), byId(S[side]), S.frame);
  }
}
function drawMenuBackdrop() {
  ctx.fillStyle = '#060608'; ctx.fillRect(0, 0, W, H);
}

// test / debug hooks (used by the automated browser tests)
window.NK = { S, startFight, show, controls, audio, fps: 0, get game() { return S.game; } };

resize();
requestAnimationFrame(loop);
// Classic build: offline caching is handled by the main site's service worker (scope /).
