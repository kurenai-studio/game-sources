// Keyboard + pointer-locked mouse. `held` is continuous state; `pressed`
// fires once per keydown and is consumed each frame by main.js.
export class Input {
  constructor(canvas) {
    this.canvas = canvas;
    this.held = new Set();
    this.pressed = new Set();
    this.mouseDX = 0;
    this.mouseDY = 0;
    this.fireHeld = false;
    this.firePressed = false;
    this.locked = false;

    addEventListener('keydown', (e) => {
      if (e.repeat) return;
      const k = normalizeKey(e);
      this.held.add(k);
      this.pressed.add(k);
      if (['Space', 'Tab'].includes(e.code)) e.preventDefault();
    });
    addEventListener('keyup', (e) => this.held.delete(normalizeKey(e)));
    addEventListener('blur', () => this.held.clear());

    addEventListener('mousemove', (e) => {
      if (!this.locked) return;
      this.mouseDX += e.movementX;
      this.mouseDY += e.movementY;
    });
    addEventListener('mousedown', (e) => {
      if (e.button !== 0 || !this.locked) return;
      this.fireHeld = true;
      this.firePressed = true;
    });
    addEventListener('mouseup', (e) => { if (e.button === 0) this.fireHeld = false; });

    document.addEventListener('pointerlockchange', () => {
      this.locked = document.pointerLockElement === canvas;
      if (!this.locked) this.fireHeld = false;
    });
  }

  lock() {
    if (this.locked) return;
    try {
      const r = this.canvas.requestPointerLock?.();
      r?.catch?.(() => {}); // some environments (headless, iframes) refuse — fine
    } catch { /* ignore */ }
  }

  // read-and-clear per-frame edges
  consume() {
    this.pressed.clear();
    this.firePressed = false;
    this.mouseDX = 0;
    this.mouseDY = 0;
  }

  axis(neg, pos) { return (this.held.has(pos) ? 1 : 0) - (this.held.has(neg) ? 1 : 0); }
}

function normalizeKey(e) {
  // letters by physical code so it works on AZERTY etc.; specials by code
  if (/^Key[A-Z]$/.test(e.code)) return e.code.slice(3).toLowerCase();
  if (/^Digit[0-9]$/.test(e.code)) return e.code.slice(5);
  return e.code; // 'Space', 'ShiftLeft', 'Escape', ...
}
