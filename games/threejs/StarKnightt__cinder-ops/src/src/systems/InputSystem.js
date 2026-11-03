export class InputSystem {
  constructor() {
    this.moveX = 0;
    this.moveZ = 0;
    this.lookX = 0;
    this.lookY = 0;
    this.fire = false;
    this.ads = false;
    this.jump = false;
    this.reload = false;
    this.sprint = false;
    this.crouch = false;
    this.sensUp = false;
    this.sensDown = false;
    // Edge-triggered weapon controls: consumed once per sample().
    this.slot1 = false;
    this.slot2 = false;
    this.slot3 = false;
    this.swap = false;
    this.wheel = 0;   // scroll-wheel switch: net notches since last sample()
    this.fireDown = false;
    this.adsDown = false;
    this.keys = Object.create(null);
    this._skipNextMove = false;
    this._onKey = (e) => {
      this.keys[e.code] = e.type === 'keydown';
      if (e.type === 'keydown') {
        if (e.code === 'KeyR') this.reload = true;
        if (e.code === 'BracketRight') this.sensUp = true;
        if (e.code === 'BracketLeft') this.sensDown = true;
        if (e.code === 'Digit1' && !e.repeat) this.slot1 = true;
        if (e.code === 'Digit2' && !e.repeat) this.slot2 = true;
        if (e.code === 'Digit3' && !e.repeat) this.slot3 = true;
        if (e.code === 'KeyQ' && !e.repeat) this.swap = true;
        if (e.code === 'Space') {
          this.jump = true;
          e.preventDefault();
        }
      }
    };
    this._onMouse = (e) => {
      // First event after (re)acquiring pointer lock can carry a bogus jump
      // delta; known Chromium issue also spits occasional huge spikes, so
      // reject anything larger than a third of the viewport.
      if (this._skipNextMove) {
        this._skipNextMove = false;
        return;
      }
      const capX = Math.max(200, innerWidth / 3);
      const capY = Math.max(200, innerHeight / 3);
      if (Math.abs(e.movementX) > capX || Math.abs(e.movementY) > capY) return;
      this.lookX += e.movementX;
      this.lookY += e.movementY;
    };
    this._onLockChange = () => {
      this._skipNextMove = true;
      this.lookX = 0;
      this.lookY = 0;
      if (!document.pointerLockElement) this._release();
    };
    this._onBlur = () => this._release();
    this._onDown = (e) => {
      if (e.button === 0) { this.fire = true; this.fireDown = true; }
      if (e.button === 2) { this.ads = true; this.adsDown = true; }
    };
    this._onUp = (e) => {
      if (e.button === 0) this.fire = false;
      if (e.button === 2) this.ads = false;
    };
    this._onWheel = (e) => {
      if (e.deltaY > 0) this.wheel += 1;
      else if (e.deltaY < 0) this.wheel -= 1;
    };
    this._block = (e) => e.preventDefault();
    addEventListener('keydown', this._onKey);
    addEventListener('keyup', this._onKey);
    addEventListener('mousemove', this._onMouse);
    addEventListener('mousedown', this._onDown);
    addEventListener('mouseup', this._onUp);
    addEventListener('wheel', this._onWheel, { passive: true });
    addEventListener('contextmenu', this._block);
    addEventListener('blur', this._onBlur);
    document.addEventListener('pointerlockchange', this._onLockChange);
  }

  /** Drop all held state so keys never stick after Esc or alt-tab. */
  _release() {
    this.keys = Object.create(null);
    this.fire = false;
    this.ads = false;
    this.jump = false;
    this.fireDown = false;
    this.adsDown = false;
    this.slot1 = false;
    this.slot2 = false;
    this.slot3 = false;
    this.swap = false;
    this.wheel = 0;
  }

  sample() {
    const l = !!this.keys.KeyA, r = !!this.keys.KeyD;
    const f = !!this.keys.KeyW, b = !!this.keys.KeyS;
    this.moveX = (r ? 1 : 0) - (l ? 1 : 0);
    this.moveZ = (f ? 1 : 0) - (b ? 1 : 0);
    this.sprint = !!this.keys.ShiftLeft || !!this.keys.ShiftRight;
    this.crouch = !!this.keys.ControlLeft || !!this.keys.KeyC;
    const look = { x: this.lookX, y: this.lookY };
    this.lookX = 0;
    this.lookY = 0;
    const jump = this.jump;
    const reload = this.reload;
    const sensUp = this.sensUp;
    const sensDown = this.sensDown;
    const slot1 = this.slot1, slot2 = this.slot2, slot3 = this.slot3;
    const swap = this.swap;
    const wheel = this.wheel;
    const fireDown = this.fireDown;
    const adsDown = this.adsDown;
    this.wheel = 0;
    this.jump = false;
    this.reload = false;
    this.sensUp = false;
    this.sensDown = false;
    this.slot1 = false;
    this.slot2 = false;
    this.slot3 = false;
    this.swap = false;
    this.fireDown = false;
    this.adsDown = false;
    return {
      moveX: this.moveX,
      moveZ: this.moveZ,
      lookX: look.x,
      lookY: look.y,
      fire: this.fire,
      ads: this.ads,
      jump,
      reload,
      sprint: this.sprint,
      crouch: this.crouch,
      sensUp,
      sensDown,
      slot1,
      slot2,
      slot3,
      swap,
      wheel,
      fireDown,
      adsDown,
    };
  }

  dispose() {
    removeEventListener('keydown', this._onKey);
    removeEventListener('keyup', this._onKey);
    removeEventListener('mousemove', this._onMouse);
    removeEventListener('mousedown', this._onDown);
    removeEventListener('mouseup', this._onUp);
    removeEventListener('wheel', this._onWheel);
    removeEventListener('contextmenu', this._block);
    removeEventListener('blur', this._onBlur);
    document.removeEventListener('pointerlockchange', this._onLockChange);
  }
}
