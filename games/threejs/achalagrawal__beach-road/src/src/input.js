// Keyboard, mouse and gamepad. Continuous controls are polled each frame; discrete actions fire
// through on(action, fn).

const KEY_ACTIONS = {
  KeyE: 'autodrive', KeyC: 'cruise', KeyV: 'camera', Equal: 'speedUp', NumpadAdd: 'speedUp',
  Minus: 'speedDown', NumpadSubtract: 'speedDown', Period: 'nextStation', Comma: 'prevStation', KeyN: 'nextStation',
  KeyL: 'lights', KeyG: 'horn', KeyH: 'hud', KeyM: 'mute', KeyK: 'screenshot', Escape: 'menu', KeyP: 'menu',
  KeyT: 'time', KeyY: 'weather', Digit1: 'look1', Digit2: 'look2', Digit3: 'look3', KeyR: 'turnAround',
};

// Standard gamepad mapping.
const PAD_ACTIONS = {
  0: 'autodrive', 2: 'cruise', 3: 'camera', 1: 'horn', 5: 'nextStation', 4: 'prevStation',
  12: 'speedUp', 13: 'speedDown', 9: 'menu', 8: 'hud', 10: 'lights', 14: 'time', 15: 'weather',
};

const DRIVE_KEYS = {
  throttle: ['KeyW', 'ArrowUp'],
  brake: ['KeyS', 'ArrowDown', 'Space'],
  left: ['KeyA', 'ArrowLeft'],
  right: ['KeyD', 'ArrowRight'],
};

export class Input {
  constructor(canvas) {
    this.down = new Set();
    this.handlers = {};
    this.enabled = true;  // driving controls (off while a menu is open)
    this.steerKey = 0;
    this.throttleKey = 0;
    this.drag = { x: 0, y: 0 };
    this.wheel = 0;
    this.padPrev = [];
    this.usingPad = false;

    addEventListener('keydown', (e) => {
      if (e.target instanceof HTMLInputElement) return;
      const action = KEY_ACTIONS[e.code];
      if (Object.values(DRIVE_KEYS).flat().includes(e.code) || action) e.preventDefault();
      if (e.repeat && action !== 'speedUp' && action !== 'speedDown') return;
      this.down.add(e.code);
      this.usingPad = false;
      if (action) this.fire(action);
    });
    addEventListener('keyup', (e) => this.down.delete(e.code));
    addEventListener('blur', () => this.down.clear());

    let dragging = false, lx = 0, ly = 0;
    canvas.addEventListener('pointerdown', (e) => {
      dragging = true; lx = e.clientX; ly = e.clientY;
      canvas.setPointerCapture(e.pointerId);
    });
    canvas.addEventListener('pointermove', (e) => {
      if (!dragging) return;
      this.drag.x += e.clientX - lx;
      this.drag.y += e.clientY - ly;
      lx = e.clientX; ly = e.clientY;
    });
    const end = () => { dragging = false; };
    canvas.addEventListener('pointerup', end);
    canvas.addEventListener('pointercancel', end);
    canvas.addEventListener('wheel', (e) => { this.wheel += e.deltaY; e.preventDefault(); }, { passive: false });
  }

  on(action, fn) {
    (this.handlers[action] ??= []).push(fn);
  }

  fire(action) {
    for (const fn of this.handlers[action] ?? []) fn();
  }

  any(codes) { return codes.some((c) => this.down.has(c)); }

  // -> { throttle, brake, steer (+1 = right), orbitX, orbitY, zoom }
  poll(dt) {
    const out = { throttle: 0, brake: 0, steer: 0, orbitX: this.drag.x, orbitY: this.drag.y, zoom: this.wheel };
    this.drag.x = this.drag.y = this.wheel = 0;

    // Keyboard, smoothed so tapping steers gently.
    const s = (this.any(DRIVE_KEYS.right) ? 1 : 0) - (this.any(DRIVE_KEYS.left) ? 1 : 0);
    // A tap gives a small correction; holding for half a second reaches full lock.
    const rate = s === 0 ? 4 : (Math.sign(s) !== Math.sign(this.steerKey) && this.steerKey !== 0 ? 6 : 2);
    this.steerKey += Math.max(-rate * dt, Math.min(rate * dt, s - this.steerKey));
    const th = this.any(DRIVE_KEYS.throttle) ? 1 : 0;
    this.throttleKey += Math.max(-4 * dt, Math.min(4 * dt, th - this.throttleKey));
    out.steer = this.steerKey;
    out.throttle = this.throttleKey;
    out.brake = this.any(DRIVE_KEYS.brake) ? 1 : 0;

    const pad = this.gamepad();
    if (pad) {
      const dz = (v, d = 0.12) => (Math.abs(v) < d ? 0 : (v - Math.sign(v) * d) / (1 - d));
      const steer = dz(pad.axes[0] ?? 0), rt = pad.buttons[7]?.value ?? 0, lt = pad.buttons[6]?.value ?? 0;
      if (steer || rt > 0.05 || lt > 0.05) this.usingPad = true;
      if (this.usingPad) {
        out.steer = Math.sign(steer) * steer * steer * 0.6 + steer * 0.4;
        out.throttle = rt;
        out.brake = lt;
      }
      out.orbitX += dz(pad.axes[2] ?? 0, 0.18) * 600 * dt;
      out.orbitY += dz(pad.axes[3] ?? 0, 0.18) * 400 * dt;
      pad.buttons.forEach((b, i) => {
        if (b.pressed && !this.padPrev[i] && PAD_ACTIONS[i]) this.fire(PAD_ACTIONS[i]);
        this.padPrev[i] = b.pressed;
      });
    }
    if (!this.enabled) { out.throttle = out.brake = out.steer = 0; }
    return out;
  }

  gamepad() {
    if (!navigator.getGamepads) return null;
    for (const p of navigator.getGamepads()) if (p && p.connected) return p;
    return null;
  }
}
