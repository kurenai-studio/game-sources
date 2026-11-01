/* UI: start screen, HUD (timer, checkpoints, best), finish screen,
   flash + toast announcements. Pure DOM, no Three.js. */
'use strict';

class UI {
  constructor() {
    this.el = {};
    for (const id of [
      'hud', 'cp-count', 'timer', 'best-pill', 'best-hud', 'flash', 'toast',
      'start-screen', 'play-btn', 'finish-screen', 'final-time', 'best-time',
      'restart-btn', 'error-overlay', 'error-message'
    ]) {
      this.el[id] = document.getElementById(id);
    }
  }

  onPlay(cb) { this.el['play-btn'].addEventListener('click', cb); }
  onRestart(cb) { this.el['restart-btn'].addEventListener('click', cb); }

  showStart() {
    this.el['start-screen'].classList.remove('hidden');
    this.el['finish-screen'].classList.add('hidden');
    this.el['hud'].classList.add('hidden');
  }

  showHUD() {
    this.el['start-screen'].classList.add('hidden');
    this.el['finish-screen'].classList.add('hidden');
    this.el['hud'].classList.remove('hidden');
  }

  showFinish(time, best, isNewBest) {
    this.el['final-time'].textContent = formatTime(time);
    this.el['best-time'].textContent = isNewBest
      ? 'NEW BEST TIME!'
      : (best !== null ? 'Best: ' + formatTime(best) : '');
    this.el['finish-screen'].classList.remove('hidden');
  }

  hideFinish() {
    this.el['finish-screen'].classList.add('hidden');
  }

  setTimer(t) {
    this.el['timer'].textContent = formatTime(t);
  }

  setCheckpoints(n, total) {
    this.el['cp-count'].textContent = n + '/' + total;
  }

  showBestHUD(best) {
    if (best === null) {
      this.el['best-pill'].classList.add('hidden');
      return;
    }
    this.el['best-hud'].textContent = formatTime(best);
    this.el['best-pill'].classList.remove('hidden');
  }

  /* Big centered text that pops and fades ("GO!"). */
  flash(text) {
    const f = this.el['flash'];
    f.textContent = text;
    f.classList.remove('hidden');
    f.style.animation = 'none';
    void f.offsetWidth;             // restart the CSS animation
    f.style.animation = '';
  }

  /* Smaller rising announcement ("CHECKPOINT 1!"). */
  toast(text) {
    const t = this.el['toast'];
    t.textContent = text;
    t.classList.remove('hidden');
    t.style.animation = 'none';
    void t.offsetWidth;
    t.style.animation = '';
  }

  showError(message) {
    this.el['error-message'].textContent = message;
    this.el['error-overlay'].classList.remove('hidden');
  }
}
