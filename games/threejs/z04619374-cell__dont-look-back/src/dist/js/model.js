import { CONFIG } from './config.js';

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const wrap = angle => Math.atan2(Math.sin(angle), Math.cos(angle));

/** Pure simulation. Inputs are semantic actions; angles use radians. */
export class GameModel {
  constructor(options = {}) {
    this.config = { ...CONFIG, ...options };
    this.spawnMonsters = options.spawnMonsters !== false;
    this.seed = options.seed ?? 73;
    this.reset();
  }
  reset() {
    this.status = 'ready'; this.reason = ''; this.time = 0;
    this.health = this.config.maxHealth; this.distance = 0;
    this.yaw = 0; this.pitch = 0; this.contact = 1;
    this.lastTap = 0; this.tapReady = -Infinity; this.tapVelocity = 0;
    this.guardHeld = false; this.heldTime = 0; this.guardUntil = -Infinity;
    this.guardReady = -Infinity; this.forced = false; this.forceElapsed = 0;
    this.forceStart = 0; this.forceDirection = 1; this.rearTime = 0;
    this.monsters = []; this.nextMonster = 3.5; this.monsterId = 0;
    this.randomState = this.seed; this.events = [];
    this.hits = 0; this.blocks = 0; this.taps = 0;
  }
  start() { this.reset(); this.status = 'playing'; }
  get guarding() { return this.status === 'playing' && this.time < this.guardUntil && !this.forced; }
  get holdPressure() { return clamp(this.heldTime / this.config.holdLimit, 0, 1); }
  pause() {
    if (this.status !== 'playing') return;
    this.status = 'paused'; this.clearInput();
  }
  resume() { if (this.status === 'paused') { this.clearInput(); this.status = 'playing'; } }
  clearInput() { this.guardHeld = false; this.heldTime = 0; this.guardUntil = -Infinity; }
  setGuard(pressed) {
    if (this.status !== 'playing') return;
    if (pressed === this.guardHeld) return;
    this.guardHeld = pressed;
    if (!pressed) { this.heldTime = 0; return; }
    if (this.time + 1e-9 >= this.guardReady && !this.forced) {
      this.guardUntil = this.time + this.config.guardWindow;
      this.guardReady = this.time + this.config.guardCooldown;
      this.events.push({ type: 'guard' });
    }
  }
  tap() {
    if (this.status !== 'playing' || this.forced || this.time + 1e-9 < this.tapReady) return false;
    this.lastTap = this.time; this.contact = 1;
    this.tapReady = this.time + this.config.tapCooldown;
    this.tapVelocity += this.config.tapTurn * this.config.tapDamping;
    this.taps++; this.events.push({ type: 'tap' }); return true;
  }
  look(yawDelta, pitchDelta) {
    if (this.status !== 'playing' || this.forced) return;
    this.yaw = wrap(this.yaw + yawDelta);
    this.pitch = clamp(this.pitch + pitchDelta, -this.config.pitchLimit, this.config.pitchLimit);
  }
  hit() {
    if (this.status !== 'playing') return;
    if (this.guarding && Math.abs(this.yaw) <= this.config.guardAngle && Math.abs(this.pitch) < 0.8) {
      this.blocks++; this.events.push({ type: 'block' });
    } else {
      this.health = Math.max(0, this.health - this.config.hitDamage);
      this.hits++; this.events.push({ type: 'hit' });
      if (this.health === 0) this.end('hurt');
    }
  }
  end(reason) {
    if (this.status !== 'playing') return;
    this.reason = reason; this.status = reason === 'exit' ? 'won' : 'lost';
    this.guardHeld = false; this.events.push({ type: 'end', reason });
  }
  random() {
    // Deterministic, reproducible spawn sequence for debugging and tests.
    this.randomState = (Math.imul(this.randomState, 1664525) + 1013904223) >>> 0;
    return this.randomState / 4294967296;
  }
  step(dt) {
    if (this.status !== 'playing' || !Number.isFinite(dt) || dt <= 0) return;
    // Substeps make outcomes stable for slow frames and test time advances.
    for (let remaining = dt; remaining > 1e-9 && this.status === 'playing';) {
      const step = Math.min(1 / 60, remaining);
      this.advance(step); remaining -= step;
    }
  }
  advance(dt) {
    const c = this.config;
    this.time += dt; this.distance = this.time * c.speed;
    this.contact = clamp(1 - Math.max(0, this.time - this.lastTap - c.neglectGrace) / c.neglectFade, 0, 1);
    if (this.guardHeld && !this.forced) {
      this.heldTime += dt;
      if (this.heldTime + 1e-9 >= c.holdLimit) {
        this.forced = true; this.forceStart = this.yaw;
        this.forceDirection = this.yaw < 0 ? -1 : 1;
        this.events.push({ type: 'forced' });
      }
    }
    if (this.forced) {
      this.forceElapsed += dt;
      const t = clamp(this.forceElapsed / c.forcedTurnDuration, 0, 1);
      const smooth = t * t * (3 - 2 * t);
      this.yaw = this.forceStart + (this.forceDirection * Math.PI - this.forceStart) * smooth;
      if (t >= 1) { this.end('held'); return; }
    } else {
      const decay = Math.exp(-c.tapDamping * dt);
      this.yaw = wrap(this.yaw + this.tapVelocity * (1 - decay) / c.tapDamping);
      this.tapVelocity *= decay;
      this.rearTime = Math.abs(this.yaw) >= c.rearAngle ? this.rearTime + dt : 0;
      if (this.rearTime + 1e-9 >= c.rearDwell) { this.end('turned'); return; }
    }
    if (this.contact <= 1e-9) { this.contact = 0; this.end('forgotten'); return; }
    if (this.spawnMonsters && this.time >= this.nextMonster) {
      this.monsters.push({ id: ++this.monsterId, age: 0, lane: (this.random() - 0.5) * 1.5, attacked: false });
      this.nextMonster = this.time + 3.5 + this.random() * 2.5;
      this.events.push({ type: 'approach' });
    }
    for (const monster of this.monsters) {
      const previous = monster.age; monster.age += dt;
      if (previous < 2.45 && monster.age >= 2.45) this.events.push({ type: 'warning' });
      if (!monster.attacked && monster.age >= c.monsterAttackTime) {
        monster.attacked = true; this.hit();
      }
    }
    this.monsters = this.monsters.filter(m => m.age < c.monsterLifetime);
    if (this.time + 1e-9 >= c.duration) { this.time = c.duration; this.end('exit'); }
  }
  drainEvents() { const events = this.events; this.events = []; return events; }
}
