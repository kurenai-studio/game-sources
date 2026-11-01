/* Player: the wobbly runner. Arcade movement (not a physics sim):
   snappy acceleration, coyote time, jump buffering, dive boost,
   squash & stretch. pos is the FEET position. */
'use strict';

const PLAYER_TUNING = {
  runSpeed: 9,
  accelGround: 70,
  accelAir: 30,
  frictionGround: 60,
  frictionAir: 6,
  gravityUp: 34,
  gravityDown: 46,
  jumpVel: 13,
  maxFall: 30,
  coyote: 0.12,
  jumpBuffer: 0.15,
  diveCooldown: 1.1
};

class Player {
  constructor(scene) {
    this.radius = 0.42;
    this.height = 1.42;

    this.pos = new THREE.Vector3();
    this.vel = new THREE.Vector3();
    this.grounded = false;
    this.groundPlat = null;      // MovingPlatform we're riding, or null
    this.coyote = 0;
    this.jumpBuf = 0;
    this.diveCD = 0;
    this.diveReq = false;
    this.diving = false;
    this.invuln = 0;
    this.yaw = 0;
    this.squashY = 1;
    this.lastDir = new THREE.Vector2(0, -1);
    this.wobbleT = 0;

    this.buildMesh(scene);
  }

  buildMesh(scene) {
    const bodyColor = 0xff7096;
    const bodyMat = new THREE.MeshPhongMaterial({ color: bodyColor, shininess: 90 });
    const darkMat = new THREE.MeshPhongMaterial({ color: 0x2c2c5e, shininess: 40 });

    this.group = new THREE.Group();          // at feet, yaw-rotated
    this.body = new THREE.Group();           // squash/wobble applied here
    this.group.add(this.body);

    // capsule body: cylinder + 2 sphere caps (CapsuleGeometry doesn't exist in r128)
    const cyl = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.42, 0.55, 20), bodyMat);
    cyl.position.y = 0.72;
    const capB = new THREE.Mesh(new THREE.SphereGeometry(0.42, 20, 14), bodyMat);
    capB.position.y = 0.445;
    const capT = new THREE.Mesh(new THREE.SphereGeometry(0.42, 20, 14), bodyMat);
    capT.position.y = 0.995;

    // dark navy outline hull (inverted, slightly larger) for a chunky toy pop
    const outlineMat = new THREE.MeshBasicMaterial({ color: 0x23235e, side: THREE.BackSide });
    const oCyl = new THREE.Mesh(cyl.geometry, outlineMat);
    oCyl.position.copy(cyl.position); oCyl.scale.setScalar(1.07);
    const oB = new THREE.Mesh(capB.geometry, outlineMat);
    oB.position.copy(capB.position); oB.scale.setScalar(1.07);
    const oT = new THREE.Mesh(capT.geometry, outlineMat);
    oT.position.copy(capT.position); oT.scale.setScalar(1.07);

    // belly
    const belly = new THREE.Mesh(
      new THREE.SphereGeometry(0.3, 16, 12),
      new THREE.MeshPhongMaterial({ color: 0xfff1e6, shininess: 80 })
    );
    belly.position.set(0, 0.62, -0.22);
    belly.scale.set(0.9, 1.15, 0.75);

    // eyes (face -Z, the run direction)
    const eyeMat = new THREE.MeshPhongMaterial({ color: 0xffffff, shininess: 90 });
    const pupilMat = new THREE.MeshBasicMaterial({ color: 0x23235e });
    for (const side of [-1, 1]) {
      const eye = new THREE.Mesh(new THREE.SphereGeometry(0.105, 12, 10), eyeMat);
      eye.position.set(side * 0.17, 1.02, -0.35);
      const pupil = new THREE.Mesh(new THREE.SphereGeometry(0.05, 8, 8), pupilMat);
      pupil.position.set(side * 0.17, 1.02, -0.44);
      this.body.add(eye, pupil);
    }

    // feet
    for (const side of [-1, 1]) {
      const foot = new THREE.Mesh(new THREE.SphereGeometry(0.17, 12, 10), darkMat);
      foot.position.set(side * 0.2, 0.09, -0.04);
      foot.scale.y = 0.6;
      foot.castShadow = true;
      this.body.add(foot);
    }

    // arms
    this.armL = new THREE.Mesh(new THREE.SphereGeometry(0.13, 10, 8), bodyMat);
    this.armL.position.set(-0.5, 0.68, 0);
    this.armR = this.armL.clone();
    this.armR.position.x = 0.5;

    // antenna tuft
    const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, 0.22, 6), darkMat);
    stem.position.y = 1.5;
    const bob = new THREE.Mesh(
      new THREE.SphereGeometry(0.075, 10, 8),
      new THREE.MeshPhongMaterial({ color: 0xffd93d, shininess: 90 })
    );
    bob.position.y = 1.63;

    for (const m of [cyl, capB, capT, belly]) { m.castShadow = true; }
    this.body.add(cyl, capB, capT, oCyl, oB, oT, belly, this.armL, this.armR, stem, bob);

    scene.add(this.group);
  }

  respawn(p) {
    this.pos.copy(p);
    this.vel.set(0, 0, 0);
    this.grounded = false;
    this.groundPlat = null;
    this.diving = false;
    this.diveCD = 0;
    this.coyote = 0;
    this.jumpBuf = 0;
    this.diveReq = false;
    this.invuln = 1.0;
    this.yaw = 0;
    this.squashY = 1;
    this.group.visible = true;
  }

  requestJump() { this.jumpBuf = PLAYER_TUNING.jumpBuffer; }
  requestDive() { this.diveReq = true; }

  /* Small reaction when an obstacle smacks us. */
  jolt() { this.squashY = 0.7; }

  update(dt, input, course, fx) {
    const T = PLAYER_TUNING;
    const ix = input.x, iz = input.z;

    // timers
    if (this.coyote > 0) this.coyote -= dt;
    if (this.jumpBuf > 0) this.jumpBuf -= dt;
    if (this.diveCD > 0) this.diveCD -= dt;
    if (this.invuln > 0) this.invuln -= dt;

    // ride a moving platform
    if (this.grounded && this.groundPlat) {
      this.pos.x += this.groundPlat.delta.x;
      this.pos.y += this.groundPlat.delta.y;
      this.pos.z += this.groundPlat.delta.z;
    }

    // horizontal acceleration toward desired velocity; while glide-diving
    // keep the momentum instead of snapping back to run speed
    const gliding = this.diving && !this.grounded;
    const airRate = gliding ? 4 : T.accelAir;
    const airFric = gliding ? 1.5 : T.frictionAir;
    const tx = ix * T.runSpeed;
    const tz = iz * T.runSpeed;
    const rateX = ix !== 0 ? (this.grounded ? T.accelGround : airRate)
                           : (this.grounded ? T.frictionGround : airFric);
    const rateZ = iz !== 0 ? (this.grounded ? T.accelGround : airRate)
                           : (this.grounded ? T.frictionGround : airFric);
    this.vel.x = WRUtils.approach(this.vel.x, tx, rateX * dt);
    this.vel.z = WRUtils.approach(this.vel.z, tz, rateZ * dt);

    // jump (with buffer + coyote time)
    let jumped = false;
    if (this.jumpBuf > 0 && (this.grounded || this.coyote > 0)) {
      this.vel.y = T.jumpVel;
      this.grounded = false;
      this.groundPlat = null;
      this.coyote = 0;
      this.jumpBuf = 0;
      this.diving = false;
      jumped = true;
      this.squashY = 1.16;
      fx.effects.jump(this.pos);
      fx.audio.jump();
    }

    // dive / boost
    if (this.diveReq) {
      this.diveReq = false;
      if (this.diveCD <= 0) {
        this.diveCD = T.diveCooldown;
        this.diving = true;
        const sp = Math.hypot(this.vel.x, this.vel.z);
        let dx = this.lastDir.x, dz = this.lastDir.y;
        if (sp > 0.5) { dx = this.vel.x / sp; dz = this.vel.z / sp; }
        const boost = WRUtils.clamp(Math.max(sp + 6.5, 12), 0, 15);
        this.vel.x = dx * boost;
        this.vel.z = dz * boost;
        this.vel.y = Math.max(this.vel.y, 4.2);
        this.grounded = false;
        this.groundPlat = null;
        fx.audio.dive();
      }
    }

    // gravity (heavier on the way down for snap)
    const g = this.vel.y > 0 ? T.gravityUp : T.gravityDown;
    this.vel.y = Math.max(this.vel.y - g * dt, -T.maxFall);

    // integrate
    const prevY = this.pos.y;
    const wasGrounded = this.grounded;
    const fallSpeed = -this.vel.y;
    this.pos.x += this.vel.x * dt;
    this.pos.y += this.vel.y * dt;
    this.pos.z += this.vel.z * dt;

    // remember facing for dives
    const hSpeed = Math.hypot(this.vel.x, this.vel.z);
    if (hSpeed > 0.5) this.lastDir.set(this.vel.x / hSpeed, this.vel.z / hSpeed);

    this.resolveGround(prevY, wasGrounded, jumped, fallSpeed, course, fx);
    this.resolveSides(course);

    // obstacle interactions
    for (const s of course.sweepers) {
      if (s.checkHit(this)) {
        fx.effects.knock(this.pos);
        fx.audio.knock();
      }
    }
    for (const b of course.bumpers) {
      if (b.checkHit(this)) {
        fx.effects.bumper(this.pos);
        fx.audio.bumper();
        this.squashY = 0.75;
      }
    }

    // dive trail
    if (this.diving && !this.grounded) fx.effects.dive(this.pos);
    if (this.diving && this.grounded) this.diving = false;

    this.updateVisuals(dt, hSpeed);
  }

  /* Land on the highest walkable top we crossed this frame; snap down
     when walking off small steps / riding platforms downward. */
  resolveGround(prevY, wasGrounded, jumped, fallSpeed, course, fx) {
    const r = this.radius * 0.72;
    let bestTop = -Infinity;
    let bestPlat = null;

    const consider = (minX, maxX, minZ, maxZ, top, plat) => {
      if (this.pos.x <= minX - r || this.pos.x >= maxX + r) return;
      if (this.pos.z <= minZ - r || this.pos.z >= maxZ + r) return;
      if (prevY >= top - 0.06 && this.pos.y <= top + 0.001 && this.vel.y <= 0.001 && top > bestTop) {
        bestTop = top;
        bestPlat = plat;
      }
    };

    for (const c of course.statics) consider(c.min.x, c.max.x, c.min.z, c.max.z, c.max.y, null);
    for (const m of course.movers) consider(m.min.x, m.max.x, m.min.z, m.max.z, m.max.y, m);

    const rp = course.ramp;
    if (Math.abs(this.pos.x) < rp.halfW + r && this.pos.z < rp.z0 + r && this.pos.z > rp.z1 - r) {
      consider(-rp.halfW, rp.halfW, rp.z1, rp.z0, course.rampHeightAt(WRUtils.clamp(this.pos.z, rp.z1, rp.z0)), null);
    }

    if (bestTop > -Infinity) {
      this.pos.y = bestTop;
      if (!wasGrounded) {
        if (fallSpeed > 5) {
          fx.effects.land(this.pos, fallSpeed);
          fx.audio.land();
          this.squashY = WRUtils.clamp(1 - fallSpeed * 0.014, 0.7, 0.92);
        } else {
          this.squashY = 0.92;
        }
      }
      this.vel.y = 0;
      this.grounded = true;
      this.groundPlat = bestPlat;
      this.coyote = PLAYER_TUNING.coyote;
      return;
    }

    // snap-down: keep grounded continuity on small descents
    if (wasGrounded && !jumped && this.vel.y <= 0.001) {
      let snapTop = -Infinity;
      let snapPlat = null;
      const probe = (minX, maxX, minZ, maxZ, top, plat) => {
        if (this.pos.x <= minX - r || this.pos.x >= maxX + r) return;
        if (this.pos.z <= minZ - r || this.pos.z >= maxZ + r) return;
        if (top <= this.pos.y + 0.02 && top >= this.pos.y - 0.4 && top > snapTop) {
          snapTop = top;
          snapPlat = plat;
        }
      };
      for (const c of course.statics) probe(c.min.x, c.max.x, c.min.z, c.max.z, c.max.y, null);
      for (const m of course.movers) probe(m.min.x, m.max.x, m.min.z, m.max.z, m.max.y, m);
      if (Math.abs(this.pos.x) < rp.halfW + r && this.pos.z < rp.z0 + r && this.pos.z > rp.z1 - r) {
        probe(-rp.halfW, rp.halfW, rp.z1, rp.z0, course.rampHeightAt(WRUtils.clamp(this.pos.z, rp.z1, rp.z0)), null);
      }
      if (snapTop > -Infinity) {
        this.pos.y = snapTop;
        this.vel.y = 0;
        this.grounded = true;
        this.groundPlat = snapPlat;
        this.coyote = PLAYER_TUNING.coyote;
        return;
      }
    }

    this.grounded = false;
    this.groundPlat = null;
  }

  /* Push out of box sides (walls, platform edges, sweeper hubs). */
  resolveSides(course) {
    const rad = this.radius * 0.9;
    const head = this.pos.y + this.height;
    const push = (min, max) => {
      if (this.pos.x <= min.x - rad || this.pos.x >= max.x + rad) return;
      if (this.pos.z <= min.z - rad || this.pos.z >= max.z + rad) return;
      if (this.pos.y >= max.y - 0.45 || head <= min.y + 0.02) return; // walkable top, not a wall
      const left = min.x - rad, right = max.x + rad;
      const near = min.z - rad, far = max.z + rad;
      const penX = Math.min(this.pos.x - left, right - this.pos.x);
      const penZ = Math.min(this.pos.z - near, far - this.pos.z);
      if (penX < penZ) {
        this.pos.x = (this.pos.x - left < right - this.pos.x) ? left : right;
        this.vel.x = 0;
      } else {
        this.pos.z = (this.pos.z - near < far - this.pos.z) ? near : far;
        this.vel.z = 0;
      }
    };
    for (const c of course.statics) push(c.min, c.max);
    for (const m of course.movers) push(m.min, m.max);
  }

  updateVisuals(dt, hSpeed) {
    // face movement direction
    if (hSpeed > 0.6) {
      const targetYaw = Math.atan2(-this.vel.x, -this.vel.z);
      let d = targetYaw - this.yaw;
      while (d > Math.PI) d -= Math.PI * 2;
      while (d < -Math.PI) d += Math.PI * 2;
      this.yaw += d * Math.min(1, 12 * dt);
    }
    this.group.rotation.y = this.yaw;

    // squash & stretch spring back to 1
    this.squashY = WRUtils.damp(this.squashY, 1, 9, dt);
    if (!this.grounded) {
      const stretch = WRUtils.clamp(1 + this.vel.y * 0.012, 0.85, 1.18);
      this.squashY = WRUtils.damp(this.squashY, stretch, 8, dt);
    }
    const sxz = 1 + (1 - this.squashY) * 0.55;
    this.body.scale.set(sxz, this.squashY, sxz);

    // jelly wobble + forward lean
    this.wobbleT += dt * (4 + hSpeed * 1.2);
    const wob = Math.min(1, hSpeed / PLAYER_TUNING.runSpeed);
    this.body.rotation.z = Math.sin(this.wobbleT * 2.2) * 0.05 * wob;
    this.body.rotation.x = 0.1 * wob + (this.diving && !this.grounded ? 0.9 : 0);

    // arms trail while diving
    const armZ = this.diving && !this.grounded ? 0.35 : 0;
    this.armL.position.z = WRUtils.damp(this.armL.position.z, armZ, 10, dt);
    this.armR.position.z = this.armL.position.z;

    // invulnerability blink
    if (this.invuln > 0) {
      this.group.visible = Math.floor(this.invuln * 14) % 2 === 0;
      if (this.invuln <= 0) this.group.visible = true;
    } else {
      this.group.visible = true;
    }

    this.group.position.copy(this.pos);
  }
}
