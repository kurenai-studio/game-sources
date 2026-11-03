/**
 * Five other balloons sharing the sky, each in its own bold pattern (balloon.ts PATTERNS), keeping
 * the player company: they are laid out in a loose fan ahead of the view (400 m to 1.8 km, some
 * above, some below), drift with their own layer's wind and bob gently, and a slow leash pulls each
 * one back toward its place round the player when it wanders more than a few hundred metres, so the
 * festival never drifts apart. One of them burns now and then: a 3-4 s flame every ~22 s.
 */
import * as THREE from "three";
import { BalloonActor } from "./balloon";
import { windAt } from "./wind";

interface Other {
  actor: BalloonActor;
  pos: THREE.Vector3;
  /** Place round the player (x, z offset, metres). */
  home: THREE.Vector2;
  alt: number;
  phase: number;
  burns: boolean;
}

/** [pattern (1-5), height offset from the player m, distance m, bearing from the view deg (+ = right), burns] */
const SPECS: [number, number, number, number, boolean][] = [
  [1, 25, 300, -22, false],
  [2, -45, 520, 20, true],
  [3, 90, 800, -8, false],
  [4, 5, 1150, 33, false],
  [5, 200, 1600, -36, false],
];

export class OtherBalloons {
  readonly group = new THREE.Group();
  readonly list: Other[] = [];
  private readonly w = new THREE.Vector2();
  private readonly rel = new THREE.Vector2();

  constructor(tpl: THREE.Group, around: THREE.Vector3, heading: THREE.Vector2, private readonly ground: (x: number, z: number) => number) {
    SPECS.forEach(([pal, , , , burns], i) => {
      const actor = new BalloonActor(tpl, pal, i + 1);
      this.group.add(actor.root);
      this.list.push({ actor, pos: new THREE.Vector3(), home: new THREE.Vector2(), alt: 0, phase: i * 1.7, burns });
    });
    this.reset(around, heading);
  }

  /** Lay them out again round `around` in a fan about the view heading (x, z) (start and capture spots). */
  reset(around: THREE.Vector3, heading: THREE.Vector2): void {
    const h0 = Math.atan2(heading.y, heading.x);
    const agl = Math.max(30, around.y - Math.max(0, this.ground(around.x, around.z)));
    SPECS.forEach(([, dh, dist, brg], i) => {
      const a = h0 + (brg * Math.PI) / 180;
      const o = this.list[i];
      o.home.set(Math.cos(a) * dist, Math.sin(a) * dist);
      o.pos.set(around.x + o.home.x, 0, around.z + o.home.y);
      const fl = Math.max(0, this.ground(o.pos.x, o.pos.z));
      o.alt = fl + Math.min(950, Math.max(60, agl + dh));
      o.pos.y = o.alt;
      o.actor.root.position.copy(o.pos);
    });
  }

  update(player: THREE.Vector3, t: number, dt: number, realDt: number): void {
    for (const o of this.list) {
      windAt(o.pos.x, o.pos.y, o.pos.z, t, this.w);
      // Leash: beyond 200 m from its place round the player it drifts back (a few m/s at most, which
      // nobody can tell from the wind at that range); a long way off it slips round to the far side.
      this.rel.set(player.x + o.home.x - o.pos.x, player.z + o.home.y - o.pos.z);
      const off = this.rel.length();
      if (off > 2500) {
        o.pos.x = player.x - o.home.x;
        o.pos.z = player.z - o.home.y;
      } else if (off > 200) this.w.addScaledVector(this.rel, Math.min(5, (off - 200) * 0.01) / off);
      o.pos.x += this.w.x * dt;
      o.pos.z += this.w.y * dt;
      // Burn cycle: 3.5 s of flame every 22 s, a gentle climb after it and a sink before the next.
      let burning = false;
      let lift = 0;
      if (o.burns) {
        const c = (t + o.phase * 5) % 22;
        burning = c < 3.5;
        lift = Math.sin(((c - 2) / 22) * Math.PI * 2) * 4;
      }
      const bob = Math.sin(t * 0.21 + o.phase) * 2.5 + Math.sin(t * 0.083 + o.phase * 2.1) * 3 + lift;
      const fl = Math.max(0, this.ground(o.pos.x, o.pos.z));
      o.pos.y = Math.max(fl + 10, o.alt + bob);
      o.actor.root.position.copy(o.pos);
      o.actor.setSway(Math.sin(t * 0.9 + o.phase) * 0.012, Math.cos(t * 0.75 + o.phase) * 0.012);
      o.actor.flame.update(burning, realDt);
    }
  }
}
