import test from 'node:test';
import assert from 'node:assert/strict';
import {
  MOVE,
  createMoveState,
  stepVertical,
  stepHorizontal,
  shouldRespawn
} from '../src/sim/movement.js';

const DT = 1 / 60;

test('ground jump then double jump, but no third jump', () => {
  const s = createMoveState();
  // grounded first frame primes coyote/jump reset
  stepVertical(s, { jumpPressed: false, jumpHeld: false }, DT);
  assert.equal(s.grounded, true);

  let r = stepVertical(s, { jumpPressed: true, jumpHeld: true }, DT);
  assert.equal(r.events.jumped, 1);
  assert.equal(s.jumpsUsed, 1);
  assert.equal(s.vy > 0, true);

  r = stepVertical(s, { jumpPressed: true, jumpHeld: true }, DT);
  assert.equal(r.events.jumped, 2);
  assert.equal(s.jumpsUsed, 2);
  assert.equal(s.vy, MOVE.doubleJumpSpeed + MOVE.gravity * DT);

  r = stepVertical(s, { jumpPressed: true, jumpHeld: true }, DT);
  assert.equal(r.events.jumped, 0); // no third jump
  assert.equal(s.jumpsUsed, 2);
});

test('falling off a ledge still allows one air jump (but only one)', () => {
  const s = createMoveState();
  s.grounded = false;
  s.coyote = 0;
  s.jumpsUsed = 0;
  let r = stepVertical(s, { jumpPressed: true, jumpHeld: false }, DT);
  assert.equal(r.events.jumped, 2); // the save-yourself air jump
  assert.equal(s.jumpsUsed, MOVE.maxJumps);
  r = stepVertical(s, { jumpPressed: true, jumpHeld: false }, DT);
  assert.equal(r.events.jumped, 0); // nothing left
});

test('coyote time allows a jump just after leaving the ground', () => {
  const s = createMoveState();
  stepVertical(s, { jumpPressed: false, jumpHeld: false }, DT); // grounded
  s.grounded = false; // walked off
  const r = stepVertical(s, { jumpPressed: true, jumpHeld: false }, DT);
  assert.equal(r.events.jumped, 1);
});

test('glide caps fall speed while jump is held', () => {
  const s = createMoveState();
  s.grounded = false;
  s.jumpsUsed = 1;
  s.vy = -1;
  // simulate 3 seconds of falling while holding jump
  for (let i = 0; i < 180; i++) {
    stepVertical(s, { jumpPressed: false, jumpHeld: true }, DT);
  }
  assert.equal(s.gliding, true);
  assert.equal(s.vy, MOVE.glideFallSpeed);
});

test('without holding jump, fall speed keeps growing past the glide cap', () => {
  const s = createMoveState();
  s.grounded = false;
  s.vy = -1;
  for (let i = 0; i < 60; i++) {
    stepVertical(s, { jumpPressed: false, jumpHeld: false }, DT);
  }
  assert.equal(s.gliding, false);
  assert.ok(s.vy < MOVE.glideFallSpeed);
});

test('glide boosts forward speed', () => {
  const s = createMoveState();
  s.grounded = false;
  s.vy = -3;
  stepVertical(s, { jumpPressed: false, jumpHeld: true }, DT);
  assert.equal(s.gliding, true);
  // wish dir (1,0) at walk speed; glide should push past walk speed
  for (let i = 0; i < 240; i++) {
    stepVertical(s, { jumpPressed: false, jumpHeld: true }, DT);
    stepHorizontal(s, MOVE.walkSpeed, 0, DT);
  }
  assert.ok(s.vx > MOVE.walkSpeed);
  assert.ok(s.vx <= MOVE.walkSpeed + MOVE.glideBoost + 1e-6);
});

test('respawn triggers below the kill plane', () => {
  assert.equal(shouldRespawn(-41), true);
  assert.equal(shouldRespawn(MOVE.respawnY - 0.001), true);
  assert.equal(shouldRespawn(0), false);
  assert.equal(shouldRespawn(-39), false);
});

test('gravity integration is stable and downward', () => {
  const s = createMoveState();
  s.grounded = false;
  const v0 = s.vy;
  stepVertical(s, { jumpPressed: false, jumpHeld: false }, DT);
  assert.equal(s.vy, v0 + MOVE.gravity * DT);
});
