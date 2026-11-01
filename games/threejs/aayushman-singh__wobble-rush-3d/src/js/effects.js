/* Pooled additive-blend particle system — one THREE.Points draw call.
   Particles fade by scaling their color toward black (additive blending
   makes black == transparent). */
'use strict';

class Effects {
  constructor(scene) {
    this.max = 900;
    this.pos = new Float32Array(this.max * 3);
    this.col = new Float32Array(this.max * 3);
    this.vel = new Float32Array(this.max * 3);
    this.base = new Float32Array(this.max * 3);
    this.life = new Float32Array(this.max);
    this.span = new Float32Array(this.max);
    this.grav = new Float32Array(this.max);
    this.drag = new Float32Array(this.max);
    for (let i = 0; i < this.max; i++) this.pos[i * 3 + 1] = -9999;

    const geo = new THREE.BufferGeometry();
    this.posAttr = new THREE.BufferAttribute(this.pos, 3).setUsage(THREE.DynamicDrawUsage);
    this.colAttr = new THREE.BufferAttribute(this.col, 3).setUsage(THREE.DynamicDrawUsage);
    geo.setAttribute('position', this.posAttr);
    geo.setAttribute('color', this.colAttr);

    this.points = new THREE.Points(geo, new THREE.PointsMaterial({
      size: 0.45,
      map: Effects.makeSoftTexture(),
      vertexColors: true,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      sizeAttenuation: true
    }));
    this.points.frustumCulled = false;
    scene.add(this.points);

    this.cursor = 0;
    this._c = new THREE.Color();
  }

  static makeSoftTexture() {
    const c = document.createElement('canvas');
    c.width = c.height = 64;
    const ctx = c.getContext('2d');
    const g = ctx.createRadialGradient(32, 32, 2, 32, 32, 30);
    g.addColorStop(0, 'rgba(255,255,255,1)');
    g.addColorStop(0.5, 'rgba(255,255,255,0.6)');
    g.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 64, 64);
    return new THREE.CanvasTexture(c);
  }

  emit(x, y, z, vx, vy, vz, hex, life, grav, drag) {
    const i = this.cursor;
    this.cursor = (this.cursor + 1) % this.max;
    const i3 = i * 3;
    this.pos[i3] = x; this.pos[i3 + 1] = y; this.pos[i3 + 2] = z;
    this.vel[i3] = vx; this.vel[i3 + 1] = vy; this.vel[i3 + 2] = vz;
    this._c.setHex(hex);
    this.base[i3] = this._c.r; this.base[i3 + 1] = this._c.g; this.base[i3 + 2] = this._c.b;
    this.col[i3] = this._c.r; this.col[i3 + 1] = this._c.g; this.col[i3 + 2] = this._c.b;
    this.life[i] = life;
    this.span[i] = life;
    this.grav[i] = grav;
    this.drag[i] = drag;
  }

  /* Generic radial burst. opts: count, colors[], speed[min,max], up[min,max],
     life[min,max], gravity, drag */
  burst(p, opts) {
    const n = opts.count || 12;
    for (let k = 0; k < n; k++) {
      const a = Math.random() * Math.PI * 2;
      const sp = WRUtils.rand(opts.speed[0], opts.speed[1]) * (0.3 + Math.random() * 0.7);
      const hex = WRUtils.pick(opts.colors);
      this.emit(
        p.x + WRUtils.rand(-0.15, 0.15),
        p.y + WRUtils.rand(0, 0.2),
        p.z + WRUtils.rand(-0.15, 0.15),
        Math.cos(a) * sp,
        WRUtils.rand(opts.up[0], opts.up[1]),
        Math.sin(a) * sp,
        hex,
        WRUtils.rand(opts.life[0], opts.life[1]),
        opts.gravity !== undefined ? opts.gravity : -6,
        opts.drag !== undefined ? opts.drag : 2
      );
    }
  }

  /* ---- Presets ---- */

  land(p, power) {
    this.burst(p, {
      count: Math.min(26, 6 + Math.round(power * 1.6)),
      colors: [0xffffff, 0xfff3c4, 0xd9f4ff],
      speed: [1.5, 3.2 + power * 0.28],
      up: [0.6, 2.4],
      life: [0.3, 0.65],
      gravity: -7, drag: 3.5
    });
  }

  jump(p) {
    this.burst(p, {
      count: 8, colors: [0xffffff, 0xd9f4ff],
      speed: [1, 2.4], up: [-0.4, 0.8],
      life: [0.25, 0.45], gravity: -4, drag: 3
    });
  }

  checkpoint(p) {
    this.burst(p, {
      count: 46, colors: [0x51e08a, 0xffd93d, 0xffffff],
      speed: [1, 4], up: [3, 8.5],
      life: [0.6, 1.2], gravity: -5, drag: 1.5
    });
  }

  respawn(p) {
    this.burst(p, {
      count: 30, colors: [0x7ef0ff, 0xffffff, 0x8e7cf3],
      speed: [1, 3], up: [2, 6],
      life: [0.5, 0.9], gravity: -4, drag: 2
    });
  }

  bumper(p) {
    this.burst(p, {
      count: 18, colors: [0xff5da2, 0xffffff, 0xffd93d],
      speed: [2, 5], up: [3, 6.5],
      life: [0.4, 0.8], gravity: -8, drag: 2
    });
  }

  knock(p) {
    this.burst(p, {
      count: 16, colors: [0xffa94d, 0xff6b6b, 0xffffff],
      speed: [3, 6], up: [2, 5],
      life: [0.35, 0.7], gravity: -9, drag: 2
    });
  }

  dive(p) {
    this.burst(p, {
      count: 2, colors: [0xbdf6ff, 0xffffff],
      speed: [0.2, 0.8], up: [-0.2, 0.4],
      life: [0.25, 0.4], gravity: 0, drag: 4
    });
  }

  finish(p) {
    this.burst(p, {
      count: 5,
      colors: [0xff6b6b, 0xffd93d, 0x51e08a, 0x7ef0ff, 0x8e7cf3, 0xff5da2],
      speed: [2, 6], up: [4, 10],
      life: [0.8, 1.6], gravity: -8, drag: 1.2
    });
  }

  update(dt) {
    for (let i = 0; i < this.max; i++) {
      if (this.life[i] <= 0) continue;
      this.life[i] -= dt;
      const i3 = i * 3;
      if (this.life[i] <= 0) {
        this.pos[i3 + 1] = -9999;
        this.col[i3] = this.col[i3 + 1] = this.col[i3 + 2] = 0;
        continue;
      }
      const dampFactor = Math.max(0, 1 - this.drag[i] * dt);
      this.vel[i3] *= dampFactor;
      this.vel[i3 + 2] *= dampFactor;
      this.vel[i3 + 1] = this.vel[i3 + 1] * dampFactor + this.grav[i] * dt;
      this.pos[i3] += this.vel[i3] * dt;
      this.pos[i3 + 1] += this.vel[i3 + 1] * dt;
      this.pos[i3 + 2] += this.vel[i3 + 2] * dt;
      let f = this.life[i] / this.span[i];
      f = f * f;
      this.col[i3] = this.base[i3] * f;
      this.col[i3 + 1] = this.base[i3 + 1] * f;
      this.col[i3 + 2] = this.base[i3 + 2] * f;
    }
    this.posAttr.needsUpdate = true;
    this.colAttr.needsUpdate = true;
  }
}
