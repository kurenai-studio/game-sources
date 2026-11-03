// DOM UI: loading/title overlays, HUD chips, hint toast, touch joystick
// and jump button, keyboard + orbit-drag input.
import { CHIMES } from './sim/puzzle.js';

export class UI {
  constructor() {
    this.loading = document.getElementById('loading');
    this.title = document.getElementById('title-screen');
    this.hintEl = document.getElementById('hint');
    this.dotsEl = document.getElementById('chime-dots');
    this.joystick = document.getElementById('joystick');
    this.nub = this.joystick.querySelector('.nub');
    this.jumpBtn = document.getElementById('jump-btn');

    this.isTouch = window.matchMedia('(pointer: coarse)').matches || 'ontouchstart' in window;
    if (this.isTouch) document.body.classList.add('touch');

    this.input = { x: 0, z: 0, jumpPressed: false, jumpHeld: false };
    this.onInteract = null; // E key / tap chime
    this.onTap = null; // canvas tap with ndc coords
    this.orbitDelta = { yaw: 0, pitch: 0, zoom: 0 };

    this._keys = new Set();
    this._hintTimer = 0;

    this._buildDots();
    this._bindKeyboard();
    this._bindJoystick();
    this._bindJumpButton();
  }

  _buildDots() {
    for (const chime of CHIMES) {
      const dot = document.createElement('span');
      dot.className = 'dot';
      dot.style.color = chime.color;
      this.dotsEl.appendChild(dot);
    }
  }

  setChimes(unlocked, order) {
    const dots = this.dotsEl.children;
    for (let i = 0; i < dots.length; i++) {
      const lit = i < unlocked;
      dots[i].classList.toggle('on', lit);
      dots[i].style.background = lit ? CHIMES[order[i]].color : 'rgba(90, 74, 122, 0.18)';
    }
  }

  hint(text, ms = 2600) {
    this.hintEl.textContent = text;
    this.hintEl.classList.add('show');
    clearTimeout(this._hintTimer);
    this._hintTimer = setTimeout(() => this.hintEl.classList.remove('show'), ms);
  }

  hideLoading() {
    this.loading.classList.add('hidden');
  }

  hideTitle() {
    this.title.classList.add('hidden');
  }

  onStart(cb) {
    this.title.addEventListener('pointerdown', () => cb(), { once: true });
  }

  _bindKeyboard() {
    window.addEventListener('keydown', (e) => {
      if (e.repeat) return;
      this._keys.add(e.code);
      if (e.code === 'Space') {
        this.input.jumpPressed = true;
        this.input.jumpHeld = true;
        e.preventDefault();
      }
      if (e.code === 'KeyE' && this.onInteract) this.onInteract();
    });
    window.addEventListener('keyup', (e) => {
      this._keys.delete(e.code);
      if (e.code === 'Space') this.input.jumpHeld = false;
    });
  }

  _bindJoystick() {
    let active = null;
    const setNub = (dx, dy) => {
      this.nub.style.transform = `translate(calc(-50% + ${dx}px), calc(-50% + ${dy}px))`;
    };
    this.joystick.addEventListener('pointerdown', (e) => {
      active = e.pointerId;
      this.joystick.setPointerCapture(e.pointerId);
    });
    this.joystick.addEventListener('pointermove', (e) => {
      if (e.pointerId !== active) return;
      const rect = this.joystick.getBoundingClientRect();
      let dx = e.clientX - (rect.left + rect.width / 2);
      let dy = e.clientY - (rect.top + rect.height / 2);
      const max = rect.width / 2 - 10;
      const len = Math.hypot(dx, dy);
      if (len > max) {
        dx = (dx / len) * max;
        dy = (dy / len) * max;
      }
      setNub(dx, dy);
      // deadzone: ignore tiny nub offsets so the character doesn't drift
      const DEADZONE = 0.14;
      let ix = dx / max;
      let iz = dy / max;
      if (Math.hypot(ix, iz) < DEADZONE) {
        ix = 0;
        iz = 0;
      }
      this.input.x = ix;
      this.input.z = iz;
    });
    const end = (e) => {
      if (e.pointerId !== active) return;
      active = null;
      setNub(0, 0);
      this.input.x = 0;
      this.input.z = 0;
    };
    this.joystick.addEventListener('pointerup', end);
    this.joystick.addEventListener('pointercancel', end);
  }

  _bindJumpButton() {
    this.jumpBtn.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      this.input.jumpPressed = true;
      this.input.jumpHeld = true;
    });
    const end = () => {
      this.input.jumpHeld = false;
    };
    this.jumpBtn.addEventListener('pointerup', end);
    this.jumpBtn.addEventListener('pointercancel', end);
  }

  // canvas drag = orbit, wheel = zoom, quick tap = interact ray
  bindCanvas(canvas) {
    let dragId = null;
    let lastX = 0;
    let lastY = 0;
    let downX = 0;
    let downY = 0;
    let downT = 0;
    canvas.addEventListener('pointerdown', (e) => {
      if (dragId !== null) return;
      dragId = e.pointerId;
      lastX = downX = e.clientX;
      lastY = downY = e.clientY;
      downT = performance.now();
      canvas.setPointerCapture(e.pointerId);
    });
    canvas.addEventListener('pointermove', (e) => {
      if (e.pointerId !== dragId) return;
      this.orbitDelta.yaw -= (e.clientX - lastX) * 0.005;
      this.orbitDelta.pitch -= (e.clientY - lastY) * 0.004;
      lastX = e.clientX;
      lastY = e.clientY;
    });
    const up = (e) => {
      if (e.pointerId !== dragId) return;
      dragId = null;
      const moved = Math.hypot(e.clientX - downX, e.clientY - downY);
      if (moved < 8 && performance.now() - downT < 350 && this.onTap) {
        const rect = canvas.getBoundingClientRect();
        this.onTap(
          ((e.clientX - rect.left) / rect.width) * 2 - 1,
          -((e.clientY - rect.top) / rect.height) * 2 + 1
        );
      }
    };
    canvas.addEventListener('pointerup', up);
    canvas.addEventListener('pointercancel', up);
    canvas.addEventListener('wheel', (e) => {
      this.orbitDelta.zoom += e.deltaY * 0.01;
      e.preventDefault();
    }, { passive: false });
  }

  // called once per frame; merges keyboard into input, consumes edges
  poll(orbit) {
    if (!this.isTouch || this._keys.size) {
      let kx = 0;
      let kz = 0;
      if (this._keys.has('KeyA') || this._keys.has('ArrowLeft')) kx -= 1;
      if (this._keys.has('KeyD') || this._keys.has('ArrowRight')) kx += 1;
      if (this._keys.has('KeyW') || this._keys.has('ArrowUp')) kz -= 1;
      if (this._keys.has('KeyS') || this._keys.has('ArrowDown')) kz += 1;
      if (kx || kz) {
        const len = Math.hypot(kx, kz);
        this.input.x = kx / len;
        this.input.z = kz / len;
      } else if (!this.isTouch) {
        this.input.x = 0;
        this.input.z = 0;
      }
    }
    orbit.yaw += this.orbitDelta.yaw;
    orbit.pitch = Math.min(1.25, Math.max(0.05, orbit.pitch + this.orbitDelta.pitch));
    orbit.dist = Math.min(16, Math.max(3.5, orbit.dist + this.orbitDelta.zoom));
    this.orbitDelta.yaw = 0;
    this.orbitDelta.pitch = 0;
    this.orbitDelta.zoom = 0;
    const pressed = this.input.jumpPressed;
    this.input.jumpPressed = false;
    return { x: this.input.x, z: this.input.z, jumpPressed: pressed, jumpHeld: this.input.jumpHeld };
  }
}
