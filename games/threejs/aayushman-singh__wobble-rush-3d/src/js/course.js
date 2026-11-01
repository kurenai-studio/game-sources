/* Course: builds the whole level (platforms, obstacles, checkpoints,
   gates, sky and animated background decor) and owns per-frame updates.
   Player runs toward -Z. All walkable surfaces are exposed as colliders:
   - statics: {min, max} AABBs (tops are the walkable surface)
   - movers:  MovingPlatform instances (min/max updated each frame)
   - ramp:    analytic inclined surface, heightAt(z)                    */
'use strict';

const COURSE_COLORS = {
  teal:   0x2ec4b6,
  coral:  0xff6f61,
  lime:   0x7bd66f,
  yellow: 0xffd93d,
  purple: 0x8e7cf3,
  orange: 0xffa94d,
  pink:   0xff5da2
};

class Course {
  constructor(scene) {
    this.scene = scene;
    this.statics = [];
    this.movers = [];
    this.sweepers = [];
    this.bumpers = [];
    this.checkpoints = [];
    this.clouds = [];
    this.islands = [];
    this.rings = [];
    this.balloons = [];

    this.killY = -7;
    this.startSpawn = new THREE.Vector3(0, 0.55, 3.5);

    this.buildSky();
    this.buildLevel();
    this.buildDecor();
  }

  glossy(color, shininess) {
    return new THREE.MeshPhongMaterial({ color, shininess: shininess === undefined ? 55 : shininess });
  }

  /* Adds a box platform mesh + static collider. cy is the box CENTER y. */
  addBox(cx, cy, cz, sx, sy, sz, color, opts) {
    opts = opts || {};
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(sx, sy, sz), this.glossy(color));
    mesh.position.set(cx, cy, cz);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    if (opts.trim !== false) {
      const trim = new THREE.Mesh(
        new THREE.BoxGeometry(sx - 0.45, 0.09, sz - 0.45),
        this.glossy(0xffffff, 70)
      );
      trim.position.y = sy / 2 + 0.012;
      trim.receiveShadow = true;
      mesh.add(trim);
    }
    this.scene.add(mesh);
    if (opts.collide !== false) {
      this.statics.push({
        min: new THREE.Vector3(cx - sx / 2, cy - sy / 2, cz - sz / 2),
        max: new THREE.Vector3(cx + sx / 2, cy + sy / 2, cz + sz / 2)
      });
    }
    return mesh;
  }

  /* ---------------- level ---------------- */

  buildLevel() {
    const S = this.scene;

    // 1. Start platform (top y=0), z in [-5, 5]
    this.addBox(0, -1, 0, 10, 2, 10, COURSE_COLORS.teal);
    this.startGate = new Gate(S, {
      z: -4.5, y: 0, span: 7, color: COURSE_COLORS.teal,
      label: 'START', bannerBg: '#2ec4b6', checkered: false
    });

    // 2. Sweeper arena (top y=0), z in [-21, -9]
    this.addBox(0, -1, -15, 14, 2, 12, COURSE_COLORS.coral);
    this.sweepers.push(new Sweeper(S, { x: 0, z: -12.5, baseY: 0, length: 10, speed: 1.5, phase: 0 }));
    this.sweepers.push(new Sweeper(S, { x: 0, z: -17.5, baseY: 0, length: 10, speed: -2.0, phase: 1.2 }));
    // hub colliders so the player can't walk through the posts
    this.statics.push({
      min: new THREE.Vector3(-0.6, 0, -13.1), max: new THREE.Vector3(0.6, 1.3, -11.9)
    });
    this.statics.push({
      min: new THREE.Vector3(-0.6, 0, -18.1), max: new THREE.Vector3(0.6, 1.3, -16.9)
    });

    // 3. Moving platforms over the pit
    this.movers.push(new MovingPlatform(S, {
      base: [0, -0.5, -24], size: [3.4, 1, 3.4], axis: 'x', amp: 3.2, speed: 1.0, phase: 0
    }));
    this.movers.push(new MovingPlatform(S, {
      base: [0, -0.5, -29.5], size: [3.4, 1, 3.4], axis: 'y', amp: 1.1, speed: 1.3, phase: 1.6
    }));
    this.movers.push(new MovingPlatform(S, {
      base: [0, -0.5, -35], size: [3.4, 1, 3.4], axis: 'z', amp: 2.2, speed: 1.15, phase: 3.1
    }));

    // 4. Island 1: checkpoint + bumper garden (top y=0), z in [-47, -38]
    this.addBox(0, -1, -42.5, 13, 2, 9, COURSE_COLORS.lime);
    this.checkpoints.push(new Checkpoint(S, { index: 1, x: 0, y: 0, z: -40 }));
    this.bumpers.push(new Bumper(S, { x: -3.4, z: -43, baseY: 0 }));
    this.bumpers.push(new Bumper(S, { x: 3.4, z: -43, baseY: 0 }));
    this.bumpers.push(new Bumper(S, { x: 0, z: -45.5, baseY: 0 }));

    // 5. Narrow zigzag bridge (top y=0), z in [-64, -50.5]
    this.addBox(0, -0.5, -52.75, 1.9, 1, 4.5, COURSE_COLORS.yellow);
    this.addBox(1.4, -0.5, -57.25, 1.9, 1, 4.5, COURSE_COLORS.yellow);
    this.addBox(0, -0.5, -61.75, 1.9, 1, 4.5, COURSE_COLORS.yellow);

    // 6. Island 2: checkpoint (top y=0), z in [-71, -64]
    this.addBox(0, -1, -67.5, 9, 2, 7, COURSE_COLORS.orange);
    this.checkpoints.push(new Checkpoint(S, { index: 2, x: 0, y: 0, z: -66 }));

    // 7. Final ramp: z -71 (y=0) -> z -79 (y=3.2), width 4.6
    this.ramp = { z0: -71, z1: -79, y0: 0, y1: 3.2, halfW: 2.3 };
    {
      const slope = Math.atan2(3.2, 8);
      const len = Math.hypot(8, 3.2);
      const rampMesh = new THREE.Mesh(
        new THREE.BoxGeometry(4.6, 0.8, len),
        this.glossy(COURSE_COLORS.pink)
      );
      rampMesh.position.set(0, 1.6 - 0.4 * Math.cos(slope), -75);
      rampMesh.rotation.x = slope;
      rampMesh.castShadow = true;
      rampMesh.receiveShadow = true;
      const trim = new THREE.Mesh(new THREE.BoxGeometry(4.2, 0.08, len - 0.4), this.glossy(0xffffff, 70));
      trim.position.y = 0.44;
      rampMesh.add(trim);
      S.add(rampMesh);
    }

    // 8. Final platform (top y=3.2), z in [-89, -79]
    this.addBox(0, 2.2, -84, 12, 2, 10, COURSE_COLORS.teal);
    this.finishGate = new Gate(S, {
      z: -83, y: 3.2, span: 7.2, color: COURSE_COLORS.coral,
      label: 'FINISH', bannerBg: '#ff6f61', checkered: true
    });
  }

  rampHeightAt(z) {
    const r = this.ramp;
    const t = WRUtils.clamp((r.z0 - z) / (r.z0 - r.z1), 0, 1);
    return r.y0 + (r.y1 - r.y0) * t;
  }

  /* ---------------- sky & decor ---------------- */

  buildSky() {
    const skyGeo = new THREE.SphereGeometry(420, 24, 16);
    const skyMat = new THREE.ShaderMaterial({
      side: THREE.BackSide,
      depthWrite: false,
      uniforms: {
        top: { value: new THREE.Color(0x3d9be9) },
        bottom: { value: new THREE.Color(0xcfeeff) }
      },
      vertexShader:
        'varying vec3 vPos;\n' +
        'void main(){ vPos = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }',
      fragmentShader:
        'uniform vec3 top; uniform vec3 bottom; varying vec3 vPos;\n' +
        'void main(){ float h = clamp(vPos.y/420.0*1.6+0.25, 0.0, 1.0);\n' +
        'gl_FragColor = vec4(mix(bottom, top, h), 1.0); }'
    });
    this.scene.add(new THREE.Mesh(skyGeo, skyMat));

    const sun = new THREE.Mesh(
      new THREE.CircleGeometry(16, 32),
      new THREE.MeshBasicMaterial({ color: 0xfff3b0 })
    );
    sun.position.set(-150, 120, -190);
    sun.lookAt(0, 0, -40);
    this.scene.add(sun);
    const halo = new THREE.Mesh(
      new THREE.CircleGeometry(26, 32),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.25 })
    );
    halo.position.copy(sun.position).add(new THREE.Vector3(0, 0, 1));
    halo.lookAt(0, 0, -40);
    this.scene.add(halo);
  }

  makeCloud(x, y, z) {
    const g = new THREE.Group();
    const mat = this.glossy(0xffffff, 25);
    const puffs = 3 + ((Math.random() * 2) | 0);
    for (let i = 0; i < puffs; i++) {
      const r = WRUtils.rand(1.2, 2.4);
      const m = new THREE.Mesh(new THREE.SphereGeometry(r, 12, 10), mat);
      m.position.set(i * WRUtils.rand(1.3, 1.9) - puffs * 0.8, WRUtils.rand(-0.4, 0.4), WRUtils.rand(-0.8, 0.8));
      g.add(m);
    }
    g.position.set(x, y, z);
    g.userData.speed = WRUtils.rand(0.4, 0.9);
    this.scene.add(g);
    this.clouds.push(g);
  }

  makeIsland(x, y, z) {
    const g = new THREE.Group();
    const topColor = WRUtils.pick([COURSE_COLORS.teal, COURSE_COLORS.lime, COURSE_COLORS.orange, COURSE_COLORS.purple]);
    const top = new THREE.Mesh(
      new THREE.CylinderGeometry(WRUtils.rand(2, 3.6), WRUtils.rand(2.4, 4), 1, 10),
      this.glossy(topColor, 45)
    );
    const bottom = new THREE.Mesh(
      new THREE.ConeGeometry(WRUtils.rand(2.2, 3.6), WRUtils.rand(2.5, 4.5), 10),
      this.glossy(0x9b7bd8, 35)
    );
    bottom.rotation.x = Math.PI;
    bottom.position.y = -1.6;
    g.add(top, bottom);
    g.position.set(x, y, z);
    g.userData = { baseY: y, phase: Math.random() * 6.28, amp: WRUtils.rand(0.3, 0.7), spin: WRUtils.rand(-0.15, 0.15) };
    this.scene.add(g);
    this.islands.push(g);
  }

  makeRing(x, y, z) {
    const m = new THREE.Mesh(
      new THREE.TorusGeometry(WRUtils.rand(4, 7), 0.45, 10, 32),
      this.glossy(WRUtils.pick([COURSE_COLORS.pink, COURSE_COLORS.yellow, COURSE_COLORS.teal, COURSE_COLORS.purple, COURSE_COLORS.coral]), 70)
    );
    m.position.set(x, y, z);
    m.userData = { spinX: WRUtils.rand(-0.4, 0.4), spinY: WRUtils.rand(-0.4, 0.4) };
    this.scene.add(m);
    this.rings.push(m);
  }

  makeBalloon(x, y, z) {
    const g = new THREE.Group();
    const balloon = new THREE.Mesh(
      new THREE.SphereGeometry(1.3, 16, 12),
      this.glossy(WRUtils.pick([0xff6b6b, 0xffd93d, 0x7ef0ff, 0xff5da2, 0x51e08a]), 80)
    );
    balloon.scale.y = 1.15;
    const string = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.03, 2.2, 6),
      this.glossy(0xffffff, 30)
    );
    string.position.y = -1.9;
    const basket = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.45, 0.55), this.glossy(0x8e7cf3, 40));
    basket.position.y = -3.05;
    g.add(balloon, string, basket);
    g.position.set(x, y, z);
    g.userData = { baseY: y, phase: Math.random() * 6.28 };
    this.scene.add(g);
    this.balloons.push(g);
  }

  buildDecor() {
    for (let i = 0; i < 9; i++) {
      this.makeCloud(WRUtils.rand(-42, 42), WRUtils.rand(13, 30), WRUtils.rand(15, -105));
    }
    for (let i = 0; i < 11; i++) {
      const side = i % 2 ? 1 : -1;
      this.makeIsland(side * WRUtils.rand(15, 38), WRUtils.rand(-13, -4), WRUtils.rand(10, -100));
    }
    for (let i = 0; i < 5; i++) {
      const side = i % 2 ? 1 : -1;
      this.makeRing(side * WRUtils.rand(17, 30), WRUtils.rand(6, 16), WRUtils.rand(-5, -90));
    }
    for (let i = 0; i < 6; i++) {
      const side = i % 2 ? 1 : -1;
      this.makeBalloon(side * WRUtils.rand(10, 22), WRUtils.rand(7, 14), WRUtils.rand(0, -88));
    }
  }

  /* ---------------- runtime ---------------- */

  reset() {
    for (const cp of this.checkpoints) cp.reset();
  }

  update(dt, t) {
    for (const m of this.movers) m.update(dt, t);
    for (const s of this.sweepers) s.update(dt);
    for (const b of this.bumpers) b.update(dt);
    for (const cp of this.checkpoints) cp.update(dt, t);
    this.startGate.update(dt, t);
    this.finishGate.update(dt, t);

    for (const c of this.clouds) {
      c.position.x += c.userData.speed * dt;
      if (c.position.x > 48) c.position.x = -48;
    }
    for (const g of this.islands) {
      const u = g.userData;
      g.position.y = u.baseY + Math.sin(t * 0.5 + u.phase) * u.amp;
      g.rotation.y += u.spin * dt;
    }
    for (const r of this.rings) {
      r.rotation.x += r.userData.spinX * dt;
      r.rotation.y += r.userData.spinY * dt;
    }
    for (const b of this.balloons) {
      const u = b.userData;
      b.position.y = u.baseY + Math.sin(t * 0.7 + u.phase) * 0.8;
      b.rotation.y = Math.sin(t * 0.4 + u.phase) * 0.3;
    }
  }
}
