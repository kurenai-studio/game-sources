// Keyboard + mouse, gamepad and twin virtual sticks, all reduced to the same fields.
import { IS_TOUCH } from '../config.js';

const ground = { x: 0, z: 0 };

export class Input {
  constructor() {
    Object.assign(this, { moveX: 0, moveZ: 0, aimX: 0, aimZ: 5, fire: false, reload: false, swap: false, firePressed: false, perkKey: false, pauseKey: false });
    this.keys = new Set();
    this.mouseX = innerWidth / 2; this.mouseY = innerHeight * 0.4;
    this.mouseDown = false;
    this.touch = { move: null, aim: null, aimX: 0, aimZ: 1, aiming: false };
    this.mode = IS_TOUCH ? 'touch' : 'mouse';
    this.onSlot = null;
    this.onType = null;
    this.bind();
  }

  bind() {
    addEventListener('keydown', (e) => {
      if (this.onType && e.code !== 'Escape') {
        if (!e.repeat && !e.metaKey && !e.ctrlKey) this.onType(e.key);
        if (e.key === 'Backspace' || e.key === "'" || e.key === '/') e.preventDefault();
        return;
      }
      if (e.repeat) return;
      this.keys.add(e.code);
      this.mode = 'mouse';
      if (e.code === 'KeyR') this.reload = true;
      if (e.code === 'KeyQ') this.swap = true;
      if (e.code === 'KeyE' || e.code === 'Space') { this.perkKey = true; e.preventDefault(); }
      if (e.code === 'Escape' || e.code === 'KeyP') this.pauseKey = true;
      const m = /^Digit([1-6])$/.exec(e.code);
      if (m) this.onSlot?.(Number(m[1]) - 1);
    });
    addEventListener('keyup', (e) => this.keys.delete(e.code));
    addEventListener('blur', () => { this.keys.clear(); this.mouseDown = false; });
    addEventListener('pointermove', (e) => {
      if (e.pointerType === 'touch') return;
      this.mouseX = e.clientX; this.mouseY = e.clientY;
      this.mode = 'mouse';
      this.onPointer?.(e.clientX, e.clientY);
    });
    addEventListener('contextmenu', (e) => e.preventDefault());
    const canvasOnly = (e) => e.target.closest?.('#menu, #perks, #over, #pause, button');
    addEventListener('pointerdown', (e) => {
      if (e.pointerType === 'touch' || canvasOnly(e)) return;
      if (e.button === 0) { this.mouseDown = true; this.firePressed = true; }
      if (e.button === 2) this.swap = true;
    });
    addEventListener('pointerup', (e) => { if (e.button === 0) this.mouseDown = false; });
  }

  // Called by the UI's virtual sticks.
  setStick(which, x, y, active) {
    this.mode = 'touch';
    const t = this.touch;
    if (which === 'move') t.move = active ? { x, y } : null;
    else {
      t.aiming = active;
      if (active && (x * x + y * y) > 0.04) { t.aimX = x; t.aimZ = y; }
    }
  }

  poll(game) {
    const p = game.player, k = this.keys;
    let mx = 0, mz = 0;
    if (k.has('KeyA') || k.has('ArrowLeft')) mx -= 1;
    if (k.has('KeyD') || k.has('ArrowRight')) mx += 1;
    if (k.has('KeyW') || k.has('ArrowUp')) mz -= 1;
    if (k.has('KeyS') || k.has('ArrowDown')) mz += 1;
    this.fire = this.mouseDown;

    const pad = navigator.getGamepads?.()?.find((g) => g && g.connected);
    if (pad) {
      const dz = (v) => (Math.abs(v) < 0.18 ? 0 : v);
      const lx = dz(pad.axes[0]), ly = dz(pad.axes[1]), rx = dz(pad.axes[2]), ry = dz(pad.axes[3]);
      if (lx || ly || rx || ry) this.mode = 'pad';
      if (this.mode === 'pad') {
        mx += lx; mz += ly;
        if (rx || ry) { const l = Math.hypot(rx, ry); this.padAimX = rx / l; this.padAimZ = ry / l; }
        const b = (i) => pad.buttons[i]?.pressed;
        this.fire = b(7) || b(5) || Math.hypot(rx, ry) > 0.7;
        if (b(2)) this.reload = true;
        if (b(3) && !this.padY) this.swap = true;
        this.padY = b(3);
        if (b(0) && !this.padA) this.perkKey = true;
        this.padA = b(0);
        if (b(9) && !this.padStart) this.pauseKey = true;
        this.padStart = b(9);
      }
    }

    if (this.mode === 'touch') {
      const t = this.touch;
      if (t.move) { mx += t.move.x; mz += t.move.y; }
      this.aimX = p.x + t.aimX * 9; this.aimZ = p.z + t.aimZ * 9;
      this.fire = t.aiming;
    } else if (this.mode === 'pad') {
      this.aimX = p.x + (this.padAimX ?? 0) * 9; this.aimZ = p.z + (this.padAimZ ?? 1) * 9;
    } else {
      const ndcX = (this.mouseX / innerWidth) * 2 - 1, ndcY = -(this.mouseY / innerHeight) * 2 + 1;
      game.stage.toGround(ndcX, ndcY, 1.1, ground);
      this.aimX = ground.x; this.aimZ = ground.z;
    }
    this.moveX = mx; this.moveZ = mz;
  }

  endFrame() {
    this.reload = false; this.swap = false; this.firePressed = false; this.perkKey = false; this.pauseKey = false;
  }
}
