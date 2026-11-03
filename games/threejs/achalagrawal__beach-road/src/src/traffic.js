// Ambient traffic in both directions. Cars keep their lane, follow whatever is ahead of them,
// stop (and honk) for a player blocking their lane, and nudge gently on contact.
import { roadX, roadY, heading, LANE } from './road.js';

export const DENSITY = { off: 0, light: 4, normal: 8, busy: 14 };

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

export class Traffic {
  // build(modelId, paint) -> car object from cars.js; models = CAR_MODELS
  constructor(scene, models, build) {
    this.scene = scene;
    this.models = models;
    this.build = build;
    this.cars = [];
    this.count = DENSITY.normal;
    this.nextId = 1;
    this.onHorn = () => {};
  }

  setDensity(name) {
    this.count = DENSITY[name] ?? DENSITY.normal;
    while (this.cars.length > this.count) this.remove(this.cars[this.cars.length - 1]);
  }

  // Rebuild every mesh (after a look change) without moving the cars.
  rebuild(build) {
    this.build = build;
    for (const c of this.cars) {
      this.scene.remove(c.obj.group);
      c.obj.dispose();
      c.obj = build(c.model.id, c.paint);
      this.scene.add(c.obj.group);
    }
  }

  // Drop every car and repopulate around the player on the next update (after a jump).
  clear() {
    for (const c of [...this.cars]) this.remove(c);
    this.filled = false;
  }

  remove(c) {
    this.scene.remove(c.obj.group);
    c.obj.dispose();
    this.cars.splice(this.cars.indexOf(c), 1);
  }

  spawn(player, initial) {
    const pdir = player.dir;
    const model = this.models[Math.floor(Math.random() * this.models.length)];
    const paint = model.paints[Math.floor(Math.random() * model.paints.length)];
    const same = Math.random() < 0.45;
    const dir = same ? pdir : -pdir;
    const ahead = initial ? 60 + Math.random() * 800 : 380 + Math.random() * 420;
    const z = player.z + pdir * ahead;
    const off = (dir < 0 ? 1 : -1) * LANE;
    // Keep a gap to other cars in the same lane.
    if (this.cars.some((o) => o.dir === dir && Math.abs(o.z - z) < 35)) return;
    const v = same ? 14 + Math.random() * 9 : 17 + Math.random() * 9;
    const obj = this.build(model.id, paint);
    this.scene.add(obj.group);
    this.cars.push({ id: this.nextId++, model, paint, obj, z, off, dir, v, cruise: v, honked: 0, braking: false, spin: 0 });
  }

  update(dt, player, night) {
    const pdir = player.dir;
    for (const c of [...this.cars]) {
      const along = (c.z - player.z) * pdir; // positive = ahead of the player
      if (along < -140 || along > 950) this.remove(c);
    }
    if (!this.filled) {
      for (let i = 0; i < this.count * 2 && this.cars.length < this.count; i++) this.spawn(player, true);
      this.filled = true;
    } else if (this.cars.length < this.count) {
      this.spawn(player, false);
    }

    const pOff = player.offset;
    for (const c of this.cars) {
      let target = c.cruise, gapMin = Infinity, leaderV = 0;
      for (const o of this.cars) {
        if (o === c || o.dir !== c.dir || Math.abs(o.off - c.off) > 2) continue;
        const gap = (o.z - c.z) * c.dir - 4.6;
        if (gap > 0 && gap < gapMin) { gapMin = gap; leaderV = o.v; }
      }
      // The player counts as a leader when in this lane, ahead of us.
      if (Math.abs(pOff - c.off) < 2.2) {
        const gap = (player.z - c.z) * c.dir - 4.6;
        if (gap > 0 && gap < gapMin) {
          gapMin = gap;
          const pv = player.v * (player.dir === c.dir ? 1 : -1);
          leaderV = pv;
          if (pv < -1 && gap < 90) { // player is driving toward us in our lane
            target = 0;
            if (c.honked <= 0 && gap < 70) { this.onHorn(c, gap); c.honked = 8; }
          }
        }
      }
      if (gapMin < Infinity) target = Math.min(target, Math.max(0, leaderV + (gapMin - (8 + 1.2 * c.v)) * 0.4));
      const accel = target > c.v ? 2.2 : (gapMin < 12 ? 7 : 4.5);
      c.braking = target < c.v - 0.3;
      c.v += clamp(target - c.v, -accel * dt, accel * dt);
      c.z += c.dir * c.v * dt;
      c.honked -= dt;
      this.place(c, dt, night);
    }
  }

  place(c, dt, night) {
    const g = c.obj.group;
    const y = roadY(c.z), yf = roadY(c.z + c.dir * 1.4), yb = roadY(c.z - c.dir * 1.4);
    g.position.set(roadX(c.z) + c.off, y + 0.03, c.z);
    g.rotation.set(Math.atan2(yf - yb, 2.8), heading(c.z, c.dir), 0, 'YXZ');
    const spin = (c.v * dt) / (c.model.dims.wheelRadius ?? 0.38);
    for (const w of c.obj.wheels) w.rotation.x -= spin;
    c.obj.body.position.y = Math.sin(c.z * 0.37) * 0.01;
    setLights(c.obj, c.braking, night);
  }

  // Two circles per car (front and back) are enough for gentle contact on a two-lane road.
  collide(player, playerObj) {
    let hit = null;
    const pr = player.spec.dims.width * 0.5, pl = player.spec.dims.length * 0.5 - pr;
    const pc = [[player.x + player.fx * pl, player.z + player.fz * pl], [player.x - player.fx * pl, player.z - player.fz * pl]];
    for (const c of this.cars) {
      if (Math.abs(c.z - player.z) > 12) continue;
      const cr = c.model.dims.width * 0.5, cl = c.model.dims.length * 0.5 - cr;
      const cx = roadX(c.z) + c.off, yaw = heading(c.z, c.dir), fx = -Math.sin(yaw), fz = -Math.cos(yaw);
      const cc = [[cx + fx * cl, c.z + fz * cl], [cx - fx * cl, c.z - fz * cl]];
      let best = null;
      for (const a of pc) for (const b of cc) {
        const dx = a[0] - b[0], dz = a[1] - b[1], d = Math.hypot(dx, dz), pen = pr + cr - d;
        if (pen > 0 && (!best || pen > best.pen)) best = { pen, nx: dx / (d || 1), nz: dz / (d || 1) };
      }
      if (!best) continue;
      player.x += best.nx * best.pen;
      player.z += best.nz * best.pen;
      // Inelastic along the contact normal.
      const pvx = player.fx * player.v, pvz = player.fz * player.v;
      const ovx = fx * c.v, ovz = fz * c.v;
      const vn = (pvx - ovx) * best.nx + (pvz - ovz) * best.nz;
      if (vn < 0) {
        // Contact only ever slows the player; it never throws the car backwards.
        const nvx = pvx - best.nx * vn, nvz = pvz - best.nz * vn;
        const nv = nvx * player.fx + nvz * player.fz;
        player.v = player.v >= 0 ? clamp(nv, 0, player.v) : clamp(nv, player.v, 0);
        c.v *= 0.7;
        if (!hit || -vn > hit.strength * 12) hit = { strength: clamp(-vn / 12, 0.1, 1), car: c };
      }
    }
    return hit;
  }

  // ------------------------------------------------------------ queries for autodrive

  leader(z, dir, laneOff, ignoreId) {
    let best = null;
    for (const c of this.cars) {
      if (c.dir !== dir || c.id === ignoreId || Math.abs(c.off - laneOff) > 2) continue;
      const gap = (c.z - z) * dir - 4.6;
      if (gap > -2 && (!best || gap < best.gap)) best = { id: c.id, gap: Math.max(gap, 0), speed: c.v };
    }
    return best && best.gap < 160 ? best : null;
  }

  relativePosition(id, z, dir) {
    const c = this.cars.find((o) => o.id === id);
    return c ? (c.z - z) * dir : null;
  }

  oncomingClear(z, dir, laneOff, dist) {
    return !this.cars.some((c) => c.dir !== dir && Math.abs(c.off - laneOff) < 2 && (c.z - z) * dir > -5 && (c.z - z) * dir < dist);
  }

  laneClear(z, dir, laneOff, range) {
    return !this.cars.some((c) => c.dir === dir && Math.abs(c.off - laneOff) < 2 && Math.abs(c.z - z) < range);
  }
}

// Brake lights brighten when slowing; headlights come on at night.
export function setLights(obj, braking, night) {
  const { head, tail } = obj.lights;
  head.userData.base ??= head.color.clone();
  tail.userData.base ??= tail.color.clone();
  head.color.copy(head.userData.base).multiplyScalar(0.35 + 0.65 * night + (night > 0.4 ? 0.8 : 0));
  tail.color.copy(tail.userData.base).multiplyScalar(braking ? 1.6 : 0.45 + 0.55 * night);
}
