/* Obstacles: rotating Sweeper bars, MovingPlatforms, Bouncing Bumpers.
   Each obstacle owns its meshes and exposes a checkHit(player) for
   physical interaction. MovingPlatform also acts as a collider. */
'use strict';

class Obstacle {
  constructor() {
    this.delta = new THREE.Vector3(); // per-frame movement (for carriers)
  }
  update() {}
}

/* ------------------------------------------------------------------ */

class Sweeper extends Obstacle {
  constructor(scene, opts) {
    super();
    this.x = opts.x;
    this.z = opts.z;
    this.baseY = opts.baseY;           // platform top the hub sits on
    this.length = opts.length || 10;
    this.thickness = 0.7;
    this.speed = opts.speed;           // rad/s about +Y
    this.angle = opts.phase || 0;
    this.barBottom = this.baseY + 0.18;
    this.barTop = this.baseY + 0.88;

    const g = new THREE.Group();

    const hub = new THREE.Mesh(
      new THREE.CylinderGeometry(0.55, 0.72, 1.3, 20),
      new THREE.MeshPhongMaterial({ color: 0xff5da2, shininess: 70 })
    );
    hub.position.y = 0.65;
    hub.castShadow = true;
    hub.receiveShadow = true;

    const cap = new THREE.Mesh(
      new THREE.SphereGeometry(0.5, 18, 12),
      new THREE.MeshPhongMaterial({ color: 0xffffff, shininess: 80 })
    );
    cap.position.y = 1.32;
    cap.castShadow = true;

    this.spinner = new THREE.Group();
    const barMat = new THREE.MeshPhongMaterial({ color: 0xffd93d, shininess: 60 });
    const bar = new THREE.Mesh(
      new THREE.BoxGeometry(this.length, this.thickness, this.thickness), barMat
    );
    bar.position.y = 0.53;
    bar.castShadow = true;
    bar.receiveShadow = true;
    const e1 = new THREE.Mesh(new THREE.SphereGeometry(0.44, 14, 10), barMat);
    e1.position.set(this.length / 2, 0.53, 0);
    e1.castShadow = true;
    const e2 = e1.clone();
    e2.position.x = -this.length / 2;
    this.spinner.add(bar, e1, e2);
    this.spinner.rotation.y = this.angle;

    g.add(hub, cap, this.spinner);
    g.position.set(this.x, this.baseY, this.z);
    scene.add(g);
    this.group = g;
  }

  update(dt) {
    this.angle += this.speed * dt;
    this.spinner.rotation.y = this.angle;
  }

  /* Returns true when the bar clips the player; applies knockback. */
  checkHit(p) {
    if (p.invuln > 0) return false;
    const feet = p.pos.y;
    const head = p.pos.y + p.height;
    if (feet >= this.barTop - 0.03 || head <= this.barBottom) return false;

    const dx = p.pos.x - this.x;
    const dz = p.pos.z - this.z;
    const ca = Math.cos(this.angle), sa = Math.sin(this.angle);
    const s = dx * ca + dz * sa;    // distance along the bar
    const q = -dx * sa + dz * ca;   // distance across the bar
    if (Math.abs(s) >= this.length / 2 + p.radius) return false;
    if (Math.abs(q) >= this.thickness / 2 + p.radius * 0.8) return false;

    // Bar surface velocity at contact: v = omega * s * perp, perp=(sa,0,-ca)
    let kx = this.speed * s * sa;
    let kz = -this.speed * s * ca;
    const m = Math.hypot(kx, kz);
    if (m < 3) {
      const dir = Math.sign(this.speed) || 1;
      kx = sa * dir * 3;
      kz = -ca * dir * 3;
    }
    const km = WRUtils.clamp(m * 1.5, 9, 14);
    const n = Math.hypot(kx, kz) || 1;
    p.vel.x = (kx / n) * km;
    p.vel.z = (kz / n) * km;
    p.vel.y = 8.5;
    p.grounded = false;
    p.groundPlat = null;
    p.invuln = 0.7;
    p.jolt();
    return true;
  }
}

/* ------------------------------------------------------------------ */

class MovingPlatform extends Obstacle {
  constructor(scene, opts) {
    super();
    this.size = opts.size;             // [sx, sy, sz]
    this.base = new THREE.Vector3(opts.base[0], opts.base[1], opts.base[2]);
    this.axis = opts.axis;             // 'x' | 'y' | 'z'
    this.amp = opts.amp;
    this.speed = opts.speed;
    this.phase = opts.phase || 0;
    this.center = this.base.clone();
    this.prev = this.base.clone();

    this.mesh = new THREE.Mesh(
      new THREE.BoxGeometry(this.size[0], this.size[1], this.size[2]),
      new THREE.MeshPhongMaterial({ color: opts.color || 0x8e7cf3, shininess: 55 })
    );
    this.mesh.castShadow = true;
    this.mesh.receiveShadow = true;
    const trim = new THREE.Mesh(
      new THREE.BoxGeometry(this.size[0] - 0.4, 0.08, this.size[2] - 0.4),
      new THREE.MeshPhongMaterial({ color: 0xffffff, shininess: 70 })
    );
    trim.position.y = this.size[1] / 2 + 0.01;
    trim.receiveShadow = true;
    this.mesh.add(trim);
    this.mesh.position.copy(this.center);
    scene.add(this.mesh);

    this.min = new THREE.Vector3();
    this.max = new THREE.Vector3();
    this.updateBox();
  }

  updateBox() {
    this.min.set(
      this.center.x - this.size[0] / 2,
      this.center.y - this.size[1] / 2,
      this.center.z - this.size[2] / 2
    );
    this.max.set(
      this.center.x + this.size[0] / 2,
      this.center.y + this.size[1] / 2,
      this.center.z + this.size[2] / 2
    );
  }

  update(dt, t) {
    this.prev.copy(this.center);
    const off = this.amp * Math.sin(t * this.speed + this.phase);
    this.center.copy(this.base);
    this.center[this.axis] += off;
    this.delta.subVectors(this.center, this.prev);
    this.mesh.position.copy(this.center);
    this.updateBox();
  }

  /* Place platform at its position for time t (used on course reset). */
  snapTo(t) { this.update(0, t); this.prev.copy(this.center); this.delta.set(0, 0, 0); }
}

/* ------------------------------------------------------------------ */

class Bumper extends Obstacle {
  constructor(scene, opts) {
    super();
    this.x = opts.x;
    this.z = opts.z;
    this.baseY = opts.baseY;
    this.radius = 0.95;
    this.top = this.baseY + 1.05;
    this.cd = 0;
    this.pulse = 0;

    const g = new THREE.Group();
    const body = new THREE.Mesh(
      new THREE.CylinderGeometry(this.radius, this.radius * 1.08, 1.05, 24),
      new THREE.MeshPhongMaterial({ color: 0xff5da2, shininess: 85 })
    );
    body.position.y = 0.525;
    body.castShadow = true;
    body.receiveShadow = true;
    const ring = new THREE.Mesh(
      new THREE.TorusGeometry(0.72, 0.17, 12, 24),
      new THREE.MeshPhongMaterial({ color: 0xffffff, shininess: 90 })
    );
    ring.rotation.x = Math.PI / 2;
    ring.position.y = 1.06;
    ring.castShadow = true;
    g.add(body, ring);
    g.position.set(this.x, this.baseY, this.z);
    scene.add(g);
    this.group = g;
  }

  update(dt) {
    if (this.cd > 0) this.cd -= dt;
    if (this.pulse > 0) this.pulse = Math.max(0, this.pulse - dt * 4);
    const s = 1 + 0.22 * this.pulse;
    this.group.scale.set(s, 1 + 0.1 * this.pulse, s);
  }

  checkHit(p) {
    if (this.cd > 0 || p.invuln > 0) return false;
    if (p.pos.y >= this.top || p.pos.y + p.height <= this.baseY + 0.05) return false;
    const dx = p.pos.x - this.x;
    const dz = p.pos.z - this.z;
    const d = Math.hypot(dx, dz);
    if (d >= this.radius + p.radius * 0.7) return false;
    let nx = 0, nz = -1;
    if (d > 0.001) { nx = dx / d; nz = dz / d; }
    p.vel.x = nx * 9.5;
    p.vel.z = nz * 9.5;
    p.vel.y = 7.5;
    p.grounded = false;
    p.groundPlat = null;
    this.cd = 0.35;
    this.pulse = 1;
    return true;
  }
}
