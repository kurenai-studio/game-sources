// Page wiring: canvas sizing, input, overlays, sounds, language and storage.
import {
  createGame, createDemoGame, update, getState, setTarget, moveTargetBy, setPaused, restartMatch,
} from './game.js';
import { MAX_PUCK_SPEED } from './physics.js';
import { normalizeStats, recordResult } from './stats.js';
import { normalizeSettings } from './settings.js';
import { sideForPointer, pointerAim, isMoveKey, keyboardMoves } from './controls.js';
import { fitCanvas, computeView, toTable } from './view.js';
import { buildBackground, drawFrame } from './render.js';
import { createAudio } from './audio.js';
import { t, normalizeLang } from './i18n.js';
import { load, save } from './storage.js';

const $ = (id) => document.getElementById(id);
const canvas = $('table');
const ctx = canvas.getContext('2d');
const stage = $('stage');
const overlays = { setup: $('setup'), pause: $('pause'), over: $('over') };
const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

const ui = {
  lang: normalizeLang(load('lang', 'en')),
  settings: normalizeSettings(load('settings', null)),
  draft: null,
  stats: normalizeStats(load('stats', null)),
  overlay: null,
  started: false,
  demo: new URLSearchParams(window.location.search).has('demo'),
  view: null,
  background: null,
  dpr: 1,
  pointers: new Map(),
  keys: new Set(),
  last: 0,
};
const audio = createAudio(load('muted', false) === true);
let game = ui.demo ? createDemoGame() : createGame({ ...ui.settings, seed: 1 });

/** Shorthand for a string in the current language. */
function tr(key, vars) {
  return t(ui.lang, key, vars);
}

/** Score labels for the bottom and top player. */
function labels() {
  return game.mode === 'pvp' ? [tr('p1'), tr('p2')] : [tr('you'), tr('cpu')];
}

// ---- Canvas size -------------------------------------------------------

/** Fits the canvas into the stage at the screen's pixel density. */
function resize() {
  const size = fitCanvas(stage.clientWidth, stage.clientHeight);
  if (size.width < 1 || size.height < 1) return;
  ui.dpr = Math.min(window.devicePixelRatio || 1, 3);
  canvas.style.width = `${size.width}px`;
  canvas.style.height = `${size.height}px`;
  canvas.width = Math.round(size.width * ui.dpr);
  canvas.height = Math.round(size.height * ui.dpr);
  ui.view = computeView(size.width, size.height);
  ui.background = buildBackground(ui.view, ui.dpr);
}

// ---- Overlays ----------------------------------------------------------

/** Shows one overlay (or none) and pauses the match while one is open. */
function showOverlay(name) {
  ui.overlay = name;
  for (const [key, el] of Object.entries(overlays)) el.hidden = key !== name;
  setPaused(game, name !== null);
  ui.keys.clear();
  ui.pointers.clear();
  renderPauseButton();
  if (name) overlays[name].querySelector('.primary')?.focus({ preventScroll: true });
}

/** True if closing the setup card returns to a match still in play. */
function canGoBack() {
  return ui.started && game.phase !== 'over';
}

/** Opens the setup card with the saved choices preselected. */
function openSetup() {
  ui.draft = { ...ui.settings };
  $('setup-back').hidden = !canGoBack();
  renderSetup();
  showOverlay('setup');
}

/** Starts a new match from the setup card. */
function startMatch() {
  ui.settings = normalizeSettings(ui.draft);
  save('settings', ui.settings);
  game = createGame({ ...ui.settings, seed: Math.floor(Math.random() * 2 ** 31) });
  ui.started = true;
  ui.demo = false;
  announceScore();
  showOverlay(null);
}

/** Pauses or resumes from the keyboard or the pause button. */
function togglePause() {
  if (ui.demo) return;
  if (ui.overlay === 'pause') showOverlay(null);
  else if (ui.overlay === null && game.phase !== 'over') showOverlay('pause');
}

/** Restarts the current match with the same settings. */
function restart() {
  restartMatch(game);
  announceScore();
  showOverlay(null);
}

/** Records the result and shows the match-over card. */
function finishMatch(winner) {
  if (game.mode === 'cpu') {
    ui.stats = recordResult(ui.stats, game.level, winner === 0);
    save('stats', ui.stats);
  }
  renderOver();
  showOverlay('over');
}

// ---- Rendering of DOM text ---------------------------------------------

/** Highlights the chosen option in each setup group and fills the hints. */
function renderSetup() {
  if (!ui.draft) return;
  for (const group of document.querySelectorAll('.seg[data-setting]')) {
    const current = String(ui.draft[group.dataset.setting]);
    for (const btn of group.querySelectorAll('button')) {
      btn.setAttribute('aria-pressed', String(btn.dataset.value === current));
    }
  }
  const cpu = ui.draft.mode === 'cpu';
  $('level-field').hidden = !cpu;
  const rec = ui.stats[ui.draft.level];
  $('record').textContent = tr('record', { level: tr(ui.draft.level), wins: rec.wins, losses: rec.losses });
  $('hint').textContent = tr(cpu ? 'hintCpu' : 'hintPvp');
}

/** Fills the match-over card. */
function renderOver() {
  const w = game.winner;
  if (w === null) return;
  const title = game.mode === 'pvp' ? tr('playerWins', { n: w + 1 }) : tr(w === 0 ? 'youWin' : 'cpuWins');
  const score = tr('finalScore', { a: game.score[0], b: game.score[1] });
  $('over-title').textContent = title;
  $('over-score').textContent = score;
  $('over-top').hidden = game.mode !== 'pvp';
  $('over-top-title').textContent = title;
  $('over-top-score').textContent = score;
}

/** Updates the pause button icon and label. */
function renderPauseButton() {
  const btn = $('btn-pause');
  const paused = ui.overlay === 'pause';
  btn.classList.toggle('is-paused', paused);
  setLabel(btn, tr(paused ? 'resume' : 'pause'));
}

/** Updates the mute button icon and label. */
function renderMuteButton() {
  const btn = $('btn-mute');
  btn.classList.toggle('is-muted', audio.muted);
  btn.setAttribute('aria-pressed', String(audio.muted));
  setLabel(btn, tr(audio.muted ? 'unmute' : 'mute'));
}

/** Sets a button's accessible name and tooltip. */
function setLabel(el, text) {
  el.setAttribute('aria-label', text);
  el.title = text;
}

/** Puts the current score into the screen-reader live region. */
function announceScore() {
  const [a, b] = labels();
  $('live').textContent = tr('scoreLine', { a, sa: game.score[0], b, sb: game.score[1] });
}

/** Applies the current language to every visible string. */
function applyLanguage() {
  document.documentElement.lang = ui.lang;
  document.title = tr('title');
  for (const el of document.querySelectorAll('[data-i18n]')) el.textContent = tr(el.dataset.i18n);
  const lang = $('btn-lang');
  lang.textContent = tr('langButton');
  setLabel(lang, tr('langLabel'));
  canvas.setAttribute('aria-label', tr('canvasLabel'));
  renderPauseButton();
  renderMuteButton();
  renderSetup();
  renderOver();
}

// ---- Input -------------------------------------------------------------

/** Moves the mallet of the pointer's player toward the pointer. */
function aimPointer(e, side) {
  if (!ui.view) return;
  const rect = canvas.getBoundingClientRect();
  const p = toTable(ui.view, e.clientX - rect.left, e.clientY - rect.top);
  const aim = pointerAim(p.x, p.y, side, e.pointerType === 'touch');
  setTarget(game, side, aim.x, aim.y);
}

/** True when a person may move a mallet right now. */
function canControl() {
  return !ui.demo && ui.overlay === null && game.phase !== 'over';
}

/** True if `side` is played by a person. */
function isHuman(side) {
  return game.players[side].controller === 'human';
}

function onPointerDown(e) {
  audio.unlock();
  if (!canControl()) return;
  const rect = canvas.getBoundingClientRect();
  const p = toTable(ui.view, e.clientX - rect.left, e.clientY - rect.top);
  const side = sideForPointer(game.mode, p.y);
  if (!isHuman(side)) return;
  e.preventDefault();
  ui.pointers.set(e.pointerId, side);
  canvas.setPointerCapture(e.pointerId);
  aimPointer(e, side);
}

function onPointerMove(e) {
  if (!canControl()) return;
  if (ui.pointers.has(e.pointerId)) {
    aimPointer(e, ui.pointers.get(e.pointerId));
  } else if (e.pointerType === 'mouse') {
    const rect = canvas.getBoundingClientRect();
    const side = sideForPointer(game.mode, toTable(ui.view, e.clientX - rect.left, e.clientY - rect.top).y);
    if (isHuman(side)) aimPointer(e, side);
  }
}

function onPointerEnd(e) {
  ui.pointers.delete(e.pointerId);
}

function onKeyDown(e) {
  audio.unlock();
  if (e.code === 'KeyP' || e.code === 'Escape') {
    if (e.code === 'Escape' && ui.overlay === 'setup' && canGoBack()) showOverlay(null);
    else togglePause();
    return;
  }
  if (isMoveKey(e.code) && canControl()) {
    ui.keys.add(e.code);
    e.preventDefault();
  }
}

function onKeyUp(e) {
  ui.keys.delete(e.code);
}

/** Applies held movement keys to the human mallets. */
function applyKeys(dt) {
  if (!ui.keys.size || !canControl()) return;
  keyboardMoves(ui.keys, game.mode, dt).forEach((m, side) => {
    if ((m.dx || m.dy) && isHuman(side)) moveTargetBy(game, side, m.dx, m.dy);
  });
}

// ---- Main loop -----------------------------------------------------------

/** Plays sounds and reacts to goals and the end of the match. */
function handleEvents(events) {
  for (const e of events) {
    if (e.type === 'hit') audio.play('hit', e.speed / MAX_PUCK_SPEED);
    else if (e.type === 'wall' || e.type === 'post') audio.play(e.type, e.speed / MAX_PUCK_SPEED);
    else if (e.type === 'goal') {
      audio.play('goal');
      announceScore();
    } else if (e.type === 'over') finishMatch(e.winner);
  }
}

/** One animation frame: input, physics, drawing. */
function frame(now) {
  const dt = ui.last ? (now - ui.last) / 1000 : 0;
  ui.last = now;
  applyKeys(dt);
  handleEvents(update(game, dt));
  if (ui.view) {
    drawFrame(ctx, ui.background, ui.view, ui.dpr, getState(game), {
      labels: labels(),
      goalText: tr('goal'),
      flipTop: game.mode === 'pvp',
      reducedMotion: motionQuery.matches,
    });
  }
  window.requestAnimationFrame(frame);
}

// ---- Wiring --------------------------------------------------------------

function bindSetup() {
  for (const group of document.querySelectorAll('.seg[data-setting]')) {
    group.addEventListener('click', (e) => {
      const btn = e.target.closest('button[data-value]');
      if (!btn || !ui.draft) return;
      const key = group.dataset.setting;
      ui.draft[key] = key === 'goalsToWin' ? Number(btn.dataset.value) : btn.dataset.value;
      renderSetup();
    });
  }
  $('setup-start').addEventListener('click', startMatch);
  $('setup-back').addEventListener('click', () => showOverlay(null));
}

function bindButtons() {
  $('btn-new').addEventListener('click', openSetup);
  $('btn-pause').addEventListener('click', togglePause);
  $('btn-mute').addEventListener('click', () => {
    audio.unlock();
    audio.setMuted(!audio.muted);
    save('muted', audio.muted);
    renderMuteButton();
  });
  $('btn-lang').addEventListener('click', () => {
    ui.lang = ui.lang === 'en' ? 'tr' : 'en';
    save('lang', ui.lang);
    applyLanguage();
    announceScore();
  });
  $('pause-resume').addEventListener('click', () => showOverlay(null));
  $('pause-restart').addEventListener('click', restart);
  $('over-rematch').addEventListener('click', restart);
  $('over-new').addEventListener('click', openSetup);
}

function bindInput() {
  canvas.addEventListener('pointerdown', onPointerDown);
  canvas.addEventListener('pointermove', onPointerMove);
  canvas.addEventListener('pointerup', onPointerEnd);
  canvas.addEventListener('pointercancel', onPointerEnd);
  window.addEventListener('keydown', onKeyDown);
  window.addEventListener('keyup', onKeyUp);
  window.addEventListener('blur', () => ui.keys.clear());
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && ui.overlay === null && !ui.demo && game.phase !== 'over') showOverlay('pause');
  });
  new ResizeObserver(resize).observe(stage);
}

function init() {
  bindSetup();
  bindButtons();
  bindInput();
  applyLanguage();
  announceScore();
  resize();
  if (!ui.demo) openSetup();
  window.requestAnimationFrame(frame);
}

init();
