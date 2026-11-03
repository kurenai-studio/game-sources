import { GameModel } from './model.js';
import { World } from './world.js';
import { SplitView } from './splitView.js';
import { Input } from './input.js';
import { Sound } from './sound.js';
import { UI } from './ui.js';

const model = new GameModel();
const ui = new UI(model);
const sound = new Sound();
const canvas = document.querySelector('#game');
let previous = performance.now();

try {
  const world = new World();
  const view = new SplitView(canvas, document.querySelector('#stage'), world);
  const pause = () => { model.pause(); input.unlock(); ui.update(0); };
  const input = new Input(model, canvas, world.cameraA, pause, () => ui.showPointerError());
  document.querySelector('#start').addEventListener('click', () => {
    if (ui.settingsOpen) ui.showSettings(false);
    if (model.status === 'paused') model.resume();
    else { model.start(); ui.resetFeedback(); sound.nextStep = 0; }
    previous = performance.now();
    sound.unlock(); input.lock(); ui.update(0);
  });
  document.querySelector('#pause').addEventListener('click', pause);
  document.querySelector('#settings').addEventListener('click', () => { pause(); ui.showSettings(true); });
  document.querySelector('#close-settings').addEventListener('click', () => ui.showSettings(false));
  document.querySelector('#sound').addEventListener('click', () => {
    sound.muted = !sound.muted;
    document.querySelector('#sound').textContent = sound.muted ? '♪̸' : '♪';
    document.querySelector('#sound').setAttribute('aria-label', sound.muted ? 'Unmute' : 'Mute');
    if (!sound.muted) sound.unlock();
  });
  document.querySelector('#sensitivity').addEventListener('input', event => {
    const value = Number(event.target.value); input.setSensitivity(value);
    document.querySelector('#sensitivity-value').textContent = `${value.toFixed(1)}×`;
  });
  document.querySelector('#volume').addEventListener('input', event => {
    sound.volume = Number(event.target.value)/100;
    document.querySelector('#volume-value').textContent = `${event.target.value}%`;
  });
  document.querySelector('#reduced-motion').addEventListener('change', event => ui.reducedMotion = event.target.checked);
  canvas.addEventListener('webglcontextlost', event => {
    event.preventDefault(); pause();
    document.querySelector('#dialog-detail').textContent = 'Graphics interrupted. Refresh to retry.';
    document.querySelector('#start').disabled = true;
  });
  function frame(now) {
    const dt = Math.min((now - previous)/1000, .1); previous = now;
    model.step(dt);
    for (const event of model.drainEvents()) {
      ui.event(event); sound.play(event.type);
      if (event.type === 'end') input.unlock();
    }
    world.update(model, !ui.reducedMotion);
    if (!ui.reducedMotion && model.status === 'playing' && ui.damage > 0) {
      world.cameraA.position.x += Math.sin(now*.055)*ui.damage*.055;
      world.cameraA.position.y += Math.cos(now*.075)*ui.damage*.025;
    }
    ui.update(dt); sound.update(model); view.render(model);
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
} catch (error) {
  console.error(error);
  document.querySelector('#dialog-title').textContent = 'Unable to start.';
  document.querySelector('#dialog-copy').textContent = 'WebGL is required.';
  document.querySelector('#dialog-detail').textContent = 'Enable hardware acceleration and refresh.';
  document.querySelector('#start').disabled = true;
}
