/* ==========================================================================
   30 NOCHES - particles.js
   Sistema de particulas con pool fijo (sin asignaciones por fotograma).
   ========================================================================== */
window.TN = window.TN || {};

TN.Particles = (function () {
  const MAX = 900;

  class ParticleSystem {
    constructor() {
      this.pool = new Array(MAX);
      for (let i = 0; i < MAX; i++) {
        this.pool[i] = {
          alive: false, x: 0, y: 0, vx: 0, vy: 0, life: 0, maxLife: 1,
          size: 2, color: '#fff', drag: 0.9, gravity: 0, shape: 'rect',
          fade: true, spin: 0, rot: 0, glow: false
        };
      }
      this.cursor = 0;
      this.liveCount = 0;
    }

    _get() {
      for (let i = 0; i < MAX; i++) {
        const idx = (this.cursor + i) % MAX;
        if (!this.pool[idx].alive) { this.cursor = (idx + 1) % MAX; this.liveCount++; return this.pool[idx]; }
      }
      // Pool lleno: recicla el mas viejo
      const p = this.pool[this.cursor];
      this.cursor = (this.cursor + 1) % MAX;
      return p;
    }

    spawn(opts) {
      const p = this._get();
      p.alive = true;
      p.x = opts.x; p.y = opts.y;
      p.vx = opts.vx || 0; p.vy = opts.vy || 0;
      p.life = p.maxLife = opts.life || 0.5;
      p.size = opts.size || 2;
      p.color = opts.color || '#fff';
      p.drag = opts.drag === undefined ? 0.9 : opts.drag;
      p.gravity = opts.gravity || 0;
      p.shape = opts.shape || 'rect';
      p.spin = opts.spin || 0;
      p.rot = opts.rot || 0;
      p.glow = !!opts.glow;
      return p;
    }

    /* bursting: explosion de N particulas en un cono */
    burst(x, y, count, opts) {
      opts = opts || {};
      const speed = opts.speed || 120;
      const spread = opts.spread === undefined ? Math.PI * 2 : opts.spread;
      const dir = opts.dir === undefined ? Math.random() * Math.PI * 2 : opts.dir;
      for (let i = 0; i < count; i++) {
        const a = dir + (Math.random() - 0.5) * spread;
        const s = speed * (0.4 + Math.random() * 0.8);
        this.spawn({
          x: x, y: y,
          vx: Math.cos(a) * s, vy: Math.sin(a) * s,
          life: (opts.life || 0.45) * (0.6 + Math.random() * 0.7),
          size: (opts.size || 3) * (0.6 + Math.random() * 0.8),
          color: opts.color || '#fff',
          drag: opts.drag === undefined ? 0.88 : opts.drag,
          gravity: opts.gravity || 0,
          shape: opts.shape || 'rect',
          glow: opts.glow
        });
      }
    }

    update(dt) {
      let live = 0;
      for (let i = 0; i < MAX; i++) {
        const p = this.pool[i];
        if (!p.alive) continue;
        p.life -= dt;
        if (p.life <= 0) { p.alive = false; continue; }
        p.vy += p.gravity * dt;
        const d = Math.pow(p.drag, dt * 60);
        p.vx *= d; p.vy *= d;
        p.x += p.vx * dt; p.y += p.vy * dt;
        p.rot += p.spin * dt;
        live++;
      }
      this.liveCount = live;
    }

    draw(ctx, cam) {
      const b = cam.bounds(40);
      ctx.save();
      for (let i = 0; i < MAX; i++) {
        const p = this.pool[i];
        if (!p.alive) continue;
        if (p.x < b.x0 || p.x > b.x1 || p.y < b.y0 || p.y > b.y1) continue;
        const t = p.life / p.maxLife;
        ctx.globalAlpha = p.fade ? Math.max(0, Math.min(1, t)) : 1;
        if (p.glow) ctx.globalCompositeOperation = 'lighter';
        ctx.fillStyle = p.color;
        if (p.shape === 'circle') {
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.size * (0.4 + t * 0.6), 0, Math.PI * 2);
          ctx.fill();
        } else if (p.shape === 'spark') {
          const len = Math.min(14, Math.hypot(p.vx, p.vy) * 0.045);
          const a = Math.atan2(p.vy, p.vx);
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(a);
          ctx.fillRect(-len, -p.size * 0.35, len * 2, p.size * 0.7);
          ctx.restore();
        } else {
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rot);
          ctx.fillRect(-p.size * 0.5, -p.size * 0.5, p.size, p.size);
          ctx.restore();
        }
        if (p.glow) ctx.globalCompositeOperation = 'source-over';
      }
      ctx.globalAlpha = 1;
      ctx.restore();
    }

    clear() {
      for (let i = 0; i < MAX; i++) this.pool[i].alive = false;
      this.liveCount = 0;
    }
  }

  return ParticleSystem;
})();
