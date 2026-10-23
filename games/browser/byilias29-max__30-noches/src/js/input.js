/* ==========================================================================
   30 NOCHES - input.js
   Teclado y raton. Estado por fotograma con consumo explicito de pulsaciones.
   ========================================================================== */
window.TN = window.TN || {};

TN.Input = (function () {
  const U = TN.Utils;

  class Input {
    constructor(canvas) {
      this.canvas = canvas;
      this.keys = new Set();          // teclas mantenidas
      this.justPressed = new Set();   // teclas pulsadas en este fotograma
      this.justReleased = new Set();
      this.mouse = { x: 0, y: 0, down: false, justDown: false, justUp: false, right: false, rightJustDown: false, wheel: 0 };
      this.enabled = true;
      this._bind();
    }

    _bind() {
      const self = this;

      this._onKeyDown = function (e) {
        const code = e.code;
        // Evita el scroll con la barra espaciadora / flechas
        if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Tab'].indexOf(code) !== -1) e.preventDefault();
        if (e.repeat) return;           // ignora autorepeticion: no dispara acciones repetidas
        if (!self.keys.has(code)) self.justPressed.add(code);
        self.keys.add(code);
      };
      this._onKeyUp = function (e) {
        self.keys.delete(e.code);
        self.justReleased.add(e.code);
      };
      this._onBlur = function () { self.clear(); };

      this._onMove = function (e) {
        const r = self.canvas.getBoundingClientRect();
        self.mouse.x = (e.clientX - r.left) * (self.canvas.width / r.width / (window.devicePixelRatio || 1));
        self.mouse.y = (e.clientY - r.top) * (self.canvas.height / r.height / (window.devicePixelRatio || 1));
        self.mouse.screenX = e.clientX - r.left;
        self.mouse.screenY = e.clientY - r.top;
      };
      this._onDown = function (e) {
        self._onMove(e);
        if (e.button === 0) { self.mouse.down = true; self.mouse.justDown = true; }
        if (e.button === 2) { self.mouse.right = true; self.mouse.rightJustDown = true; }
      };
      this._onUp = function (e) {
        if (e.button === 0) { self.mouse.down = false; self.mouse.justUp = true; }
        if (e.button === 2) { self.mouse.right = false; }
      };
      this._onContext = function (e) { e.preventDefault(); };
      this._onWheel = function (e) { self.mouse.wheel += Math.sign(e.deltaY); };

      window.addEventListener('keydown', this._onKeyDown, { passive: false });
      window.addEventListener('keyup', this._onKeyUp);
      window.addEventListener('blur', this._onBlur);
      document.addEventListener('visibilitychange', function () { if (document.hidden) self.clear(); });
      this.canvas.addEventListener('mousemove', this._onMove);
      this.canvas.addEventListener('mousedown', this._onDown);
      window.addEventListener('mouseup', this._onUp);
      this.canvas.addEventListener('contextmenu', this._onContext);
      this.canvas.addEventListener('wheel', this._onWheel, { passive: true });
    }

    isDown(code) { return this.keys.has(code); }
    wasPressed(code) { return this.justPressed.has(code); }
    wasReleased(code) { return this.justReleased.has(code); }
    consume(code) { const has = this.justPressed.has(code); this.justPressed.delete(code); return has; }

    /* Vector de movimiento normalizado (diagonales sin velocidad extra). */
    moveVector() {
      let x = 0, y = 0;
      if (this.keys.has('KeyW') || this.keys.has('ArrowUp')) y -= 1;
      if (this.keys.has('KeyS') || this.keys.has('ArrowDown')) y += 1;
      if (this.keys.has('KeyA') || this.keys.has('ArrowLeft')) x -= 1;
      if (this.keys.has('KeyD') || this.keys.has('ArrowRight')) x += 1;
      if (x !== 0 && y !== 0) { const inv = Math.SQRT1_2; x *= inv; y *= inv; }
      return { x: x, y: y };
    }

    endFrame() {
      this.justPressed.clear();
      this.justReleased.clear();
      this.mouse.justDown = false;
      this.mouse.justUp = false;
      this.mouse.rightJustDown = false;
      this.mouse.wheel = 0;
    }

    clear() {
      this.keys.clear();
      this.justPressed.clear();
      this.justReleased.clear();
      this.mouse.down = false;
      this.mouse.justDown = false;
      this.mouse.justUp = false;
      this.mouse.right = false;
      this.mouse.rightJustDown = false;
    }
  }

  return Input;
})();
