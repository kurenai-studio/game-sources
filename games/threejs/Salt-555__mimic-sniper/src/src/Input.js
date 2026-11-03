export class Input {
  constructor(element) {
    this.keys = new Set();
    this.pointerLocked = false;
    this.fireRequested = false;
    this.transformRequested = false;
    this.scopeHeld = false;
    this.mouseDelta = { x: 0, y: 0 };

    window.addEventListener('keydown', (event) => {
      this.keys.add(event.code);
      if (event.code === 'KeyE' && !event.repeat) this.transformRequested = true;
    });
    window.addEventListener('keyup', (event) => this.keys.delete(event.code));
    element.addEventListener('mousedown', (event) => {
      if (event.button === 0) this.fireRequested = true;
      if (event.button === 2) this.scopeHeld = true;
    });
    window.addEventListener('mouseup', (event) => {
      if (event.button === 2) this.scopeHeld = false;
    });
    element.addEventListener('contextmenu', (event) => event.preventDefault());
    window.addEventListener('mousemove', (event) => {
      if (!this.pointerLocked) return;
      this.mouseDelta.x += event.movementX;
      this.mouseDelta.y += event.movementY;
    });
    document.addEventListener('pointerlockchange', () => {
      this.pointerLocked = document.pointerLockElement === element;
    });
  }

  axis(positive, negative) {
    return (this.keys.has(positive) ? 1 : 0) - (this.keys.has(negative) ? 1 : 0);
  }

  consumeMouseDelta() {
    const delta = { ...this.mouseDelta };
    this.mouseDelta.x = 0;
    this.mouseDelta.y = 0;
    return delta;
  }

  consumeFire() { const value = this.fireRequested; this.fireRequested = false; return value; }
  consumeTransform() { const value = this.transformRequested; this.transformRequested = false; return value; }
}
