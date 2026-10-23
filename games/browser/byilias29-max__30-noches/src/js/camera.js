/* ==========================================================================
   30 NOCHES - camera.js
   Camara suave que sigue al jugador y respeta los limites del mundo.
   ========================================================================== */
window.TN = window.TN || {};

TN.Camera = (function () {
  const U = TN.Utils;

  class Camera {
    constructor(world) {
      this.world = world;
      this.x = 0; this.y = 0;
      this.targetX = 0; this.targetY = 0;
      this.shake = 0;
      this.shakeX = 0; this.shakeY = 0;
      this.viewW = 800; this.viewH = 600;
      this.zoom = 1;
    }

    setViewport(w, h) { this.viewW = w; this.viewH = h; }

    snapTo(x, y) {
      this.x = x; this.y = y;
      this.targetX = x; this.targetY = y;
      this.clampToWorld();
    }

    follow(x, y, dt) {
      this.targetX = x;
      this.targetY = y;
      const k = 1 - Math.exp(-TN.Config.CAMERA.lerp * Math.min(dt, 0.1));
      this.x += (this.targetX - this.x) * k;
      this.y += (this.targetY - this.y) * k;
      this.clampToWorld();
    }

    clampToWorld() {
      const w = this.world;
      const halfW = this.viewW / 2, halfH = this.viewH / 2;
      if (w.width <= this.viewW) this.x = w.width / 2;
      else this.x = U.clamp(this.x, halfW, w.width - halfW);
      if (w.height <= this.viewH) this.y = w.height / 2;
      else this.y = U.clamp(this.y, halfH, w.height - halfH);
    }

    addShake(amount) {
      this.shake = Math.min(26, this.shake + amount);
    }

    updateShake(dt) {
      if (this.shake > 0.05) {
        this.shake = Math.max(0, this.shake - TN.Config.CAMERA.shakeDecay * this.shake * dt - 0.4 * dt);
        this.shakeX = (Math.random() * 2 - 1) * this.shake;
        this.shakeY = (Math.random() * 2 - 1) * this.shake;
      } else {
        this.shake = 0; this.shakeX = 0; this.shakeY = 0;
      }
    }

    /* Transformaciones mundo <-> pantalla (sin shake) */
    worldToScreen(wx, wy) {
      return { x: wx - this.x + this.viewW / 2, y: wy - this.y + this.viewH / 2 };
    }
    screenToWorld(sx, sy) {
      return { x: sx + this.x - this.viewW / 2, y: sy + this.y - this.viewH / 2 };
    }

    /* Rectangulo visible en coordenadas de mundo (para culling). */
    bounds(pad) {
      pad = pad || 0;
      return {
        x0: this.x - this.viewW / 2 - pad,
        y0: this.y - this.viewH / 2 - pad,
        x1: this.x + this.viewW / 2 + pad,
        y1: this.y + this.viewH / 2 + pad
      };
    }

    isVisible(x, y, r) {
      const b = this.bounds(r || 0);
      return x >= b.x0 && x <= b.x1 && y >= b.y0 && y <= b.y1;
    }
  }

  return Camera;
})();
