import test from 'node:test';
import assert from 'node:assert/strict';
import { GameModel } from '../dist/js/model.js';

function run(game, seconds, dt = 1 / 60, tick = () => {}) {
  for (let t = 0; t < seconds - 1e-9; t += dt) { tick(game); game.step(Math.min(dt, seconds - t)); }
}
function started() { const g = new GameModel({ spawnMonsters: false }); g.start(); return g; }

test('neglecting B reduces its area and ends the run', () => {
  const g = started(); run(g, 4); assert.equal(g.contact, 1);
  run(g, 4); assert.ok(Math.abs(g.contact - 0.5) < 0.001);
  run(g, 4.1); assert.equal(g.reason, 'forgotten');
});
test('effective tap restores B and creates a resistible turn; spam cannot refresh contact', () => {
  const g = started(); run(g, 8); assert.equal(g.tap(), true);
  assert.equal(g.contact, 1); assert.equal(g.tap(), false);
  run(g, 0.5); assert.ok(g.yaw > 0.5);
  g.look(-g.yaw, 0); assert.ok(Math.abs(g.yaw) < 0.001);
});
test('holding A causes inevitable rear turn despite continuous mouse resistance', () => {
  const g = started(); g.setGuard(true);
  run(g, 4, 1 / 60, model => model.look(-2, 0));
  assert.equal(g.status, 'lost'); assert.equal(g.reason, 'held');
});
test('release after forced turn latches cannot cancel failure', () => {
  const g = started(); g.setGuard(true); run(g, 2.05); g.setGuard(false);
  run(g, 2, 1 / 60, model => model.look(-2, 0)); assert.equal(g.reason, 'held');
});
test('short guard releases safely and repeated keydown does not refresh it', () => {
  const g = started(); g.setGuard(true); run(g, 0.6); g.setGuard(true);
  assert.equal(g.guarding, false); g.setGuard(false); run(g, 1); assert.equal(g.status, 'playing');
});
test('facing fully backward briefly ends the run', () => {
  const g = started(); g.look(Math.PI, 0); run(g, 0.3); assert.equal(g.reason, 'turned');
});
test('pause freezes contact, run time and held-key timers; resume clears held input', () => {
  const g = started(); g.setGuard(true); run(g, 1); g.pause(); run(g, 30);
  assert.equal(g.time, 1); assert.equal(g.status, 'paused');
  g.resume(); run(g, 1.5); assert.equal(g.status, 'playing');
});
test('health damage is low and guard needs forward facing', () => {
  const g = started(); g.hit(); assert.equal(g.health, 97);
  g.setGuard(true); g.hit(); assert.equal(g.health, 97);
  g.look(1.5, 0); g.hit(); assert.equal(g.health, 94);
});
test('frame rate does not change contact or forward distance', () => {
  const a = started(), b = started(); run(a, 7, 1/30); run(b, 7, 1/144);
  assert.ok(Math.abs(a.contact - b.contact) < 1e-6);
  assert.ok(Math.abs(a.distance - b.distance) < 1e-6);
});
test('maintaining both views reaches the exit and retry resets all run state', () => {
  const g = started(); run(g, 90.1, 1/60, model => {
    if (model.time - model.lastTap > 3) model.tap();
    model.look(-model.yaw, 0);
  });
  assert.equal(g.status, 'won'); g.start();
  assert.equal(g.time, 0); assert.equal(g.health, 100); assert.equal(g.contact, 1);
  assert.equal(g.yaw, 0); assert.equal(g.reason, ''); assert.deepEqual(g.monsters, []);
});
