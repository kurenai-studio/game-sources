import { emptyInput } from './fighter.js';

// Key maps. Action names: p = THAPPAD (punch), k = LAAT (kick), g = PAKAD (grab), s = JUGAAD (super)
export const MAPS = {
  solo: { // 1 player vs CPU: WASD or arrows
    left: ['KeyA', 'ArrowLeft'], right: ['KeyD', 'ArrowRight'], up: ['KeyW', 'ArrowUp'], down: ['KeyS', 'ArrowDown'],
    p: ['KeyJ', 'KeyZ'], k: ['KeyK', 'KeyX'], g: ['KeyI', 'KeyC'], s: ['KeyL', 'Space', 'KeyV'], t: ['KeyU', 'KeyB'],
  },
  p1: { left: ['KeyA'], right: ['KeyD'], up: ['KeyW'], down: ['KeyS'], p: ['KeyF'], k: ['KeyG'], g: ['KeyH'], s: ['KeyT'], t: ['KeyR'] },
  p2: {
    left: ['ArrowLeft'], right: ['ArrowRight'], up: ['ArrowUp'], down: ['ArrowDown'],
    p: ['Numpad1', 'KeyK'], k: ['Numpad2', 'KeyL'], g: ['Numpad3', 'KeyO'], s: ['Numpad0', 'KeyP'], t: ['Numpad4', 'KeyU'],
  },
};

export class Controls {
  constructor() {
    this.held = new Set();
    this.tapped = new Set();     // keys pressed since the last simulation step
    this.touch = { left: false, right: false, up: false, down: false, p: false, k: false, g: false, s: false, t: false };
    this.touchTapped = new Set();
    this.prevUp = [false, false];
    addEventListener('keydown', (e) => {
      if (e.repeat) return;
      if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) e.preventDefault();
      this.held.add(e.code); this.tapped.add(e.code);
    });
    addEventListener('keyup', (e) => this.held.delete(e.code));
    addEventListener('blur', () => { this.held.clear(); });
  }

  read(map, side, withTouch) {
    const inp = emptyInput();
    const any = (codes, set) => codes.some((c) => set.has(c));
    for (const k of ['left', 'right', 'up', 'down', 'p', 'k', 'g', 's', 't']) inp[k] = any(map[k] || [], this.held);
    for (const b of ['p', 'k', 'g', 's', 't']) inp.pressed[b] = any(map[b] || [], this.tapped);
    if (withTouch) {
      for (const k of ['left', 'right', 'up', 'down', 'p', 'k', 'g', 's', 't']) inp[k] = inp[k] || this.touch[k];
      for (const b of ['p', 'k', 'g', 's', 't']) inp.pressed[b] = inp.pressed[b] || this.touchTapped.has(b);
    }
    inp.pressed.up = inp.up && !this.prevUp[side];
    this.prevUp[side] = inp.up;
    return inp;
  }
  endStep() { this.tapped.clear(); this.touchTapped.clear(); }

  // ---- on-screen touch controls ----
  bindTouch(root) {
    const stick = root.querySelector('.stick'), knob = root.querySelector('.knob');
    let id = null, cx = 0, cy = 0;
    const set = (dx, dy) => {
      const d = Math.hypot(dx, dy), max = 46, k = d > max ? max / d : 1;
      knob.style.transform = `translate(${dx * k}px, ${dy * k}px)`;
      this.touch.left = dx < -16; this.touch.right = dx > 16; this.touch.up = dy < -26; this.touch.down = dy > 22;
    };
    stick.addEventListener('pointerdown', (e) => { id = e.pointerId; const r = stick.getBoundingClientRect(); cx = r.left + r.width / 2; cy = r.top + r.height / 2; stick.setPointerCapture(id); set(e.clientX - cx, e.clientY - cy); e.preventDefault(); });
    stick.addEventListener('pointermove', (e) => { if (e.pointerId === id) set(e.clientX - cx, e.clientY - cy); });
    const end = (e) => { if (e.pointerId === id) { id = null; set(0, 0); } };
    stick.addEventListener('pointerup', end); stick.addEventListener('pointercancel', end);
    for (const btn of root.querySelectorAll('[data-btn]')) {
      const b = btn.dataset.btn;
      btn.addEventListener('pointerdown', (e) => { e.preventDefault(); btn.setPointerCapture(e.pointerId); this.touch[b] = true; this.touchTapped.add(b); btn.classList.add('on'); navigator.vibrate?.(12); });
      const up = () => { this.touch[b] = false; btn.classList.remove('on'); };
      btn.addEventListener('pointerup', up); btn.addEventListener('pointercancel', up); btn.addEventListener('lostpointercapture', up);
    }
  }
}
