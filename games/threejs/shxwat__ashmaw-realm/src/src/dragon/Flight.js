/**
 * The flight — Ashmaw's lesser kin.
 *
 * A handful of smaller wyrms that hold their own orbits around the caldera.
 * They exist for two reasons, and the second one matters more than the first:
 *
 *  1. An empty sky reads as an empty world. Traffic sells a living realm.
 *  2. Scale. A lone creature has nothing to be measured against, so it is
 *     whatever size the viewer assumes. Put three half-size wyrms in the same
 *     frame and Ashmaw is suddenly, unarguably, enormous — the cheapest and
 *     most reliable way to make a hero creature feel big.
 *
 * These are deliberately *not* peers of the hero. Ashmaw is what the director,
 * the chase camera, the hero light, the fire breath and every HUD action refer
 * to as "the dragon"; making the flight co-equal would mean teaching all of
 * those which one they meant. Instead the flight is scenery that happens to be
 * alive: same body, same solver, no privileged references anywhere.
 *
 * Cost control (measured, see Dragon's `simple` option): a full Ashmaw is 40
 * meshes / ~67 draw calls, so a naive flight of four would roughly triple the
 * scene's draw calls. Simple builds drop the legs and shadow casting, which is
 * most of that, and the CPU skinning was never the problem — 0.077 ms each.
 */
import * as THREE from 'three';
import { Dragon } from './Dragon.js';
import { DragonAnimator } from './DragonAnimator.js';
import { WORLD } from '../world/Heightfield.js';
import { TAU } from '../utils/MathX.js';

/**
 * Orbits are spread across radius, altitude, speed *and* centre so the flight
 * never reads as a formation. Scales stay well under the hero's 1.35 — these
 * have to be legible as the same species but obviously lesser.
 */
const MEMBERS = [
  { scale: 0.62, radius: 690, altitude: 470, speed: 58, phase: 0.0,  centre: 'volcano', ry: 0.86 },
  { scale: 0.54, radius: 880, altitude: 560, speed: 52, phase: 2.3,  centre: 'volcano', ry: 0.74 },
  { scale: 0.70, radius: 560, altitude: 380, speed: 63, phase: 4.1,  centre: 'castle',  ry: 0.92 },
  { scale: 0.48, radius: 980, altitude: 640, speed: 47, phase: 5.4,  centre: 'village', ry: 0.80 },
];

export class Flight {
  constructor(materials, settings, { count = MEMBERS.length } = {}) {
    this.group = new THREE.Group();
    this.group.name = 'Flight';
    this.members = [];

    const centres = {
      volcano: new THREE.Vector3(WORLD.volcano.x, 0, WORLD.volcano.z),
      castle: new THREE.Vector3(WORLD.castle.x, 0, WORLD.castle.z),
      village: new THREE.Vector3(WORLD.village.x, 0, WORLD.village.z),
    };

    // Low tier gets a thinner sky; the scale cue still lands with two.
    const n = Math.min(count, settings.tier === 'low' ? 2 : MEMBERS.length);

    for (let i = 0; i < n; i++) {
      const m = MEMBERS[i];
      const dragon = new Dragon(materials, settings, { simple: true });
      dragon.setScale(m.scale);
      this.group.add(dragon.group);

      const animator = new DragonAnimator(dragon);
      const centre = centres[m.centre];

      /**
       * Establish the orbit directly rather than via circle().
       *
       * circle() eases its parameters in over 3.2 s with GSAP and leaves the
       * body wherever it already was — which for a fresh animator is a single
       * shared default position. Four wyrms built that way all spawn on top of
       * each other and then visibly converge-then-diverge over the first few
       * seconds, right when the opening shot is playing. Writing the orbit
       * state and dropping each one onto its own starting point means the
       * flight is correct on frame one.
       */
      animator.setState('circle');
      animator.circleCenter.copy(centre);
      animator.orbitAngle = m.phase;
      animator.orbitRatio = m.ry;
      animator.p.orbitRadius = m.radius;
      animator.p.altitude = m.altitude;
      animator.p.speed = m.speed;
      // Smaller wings beat faster — a real scaling law, and it stops the
      // flight looking like one animation played on four bodies.
      animator.p.flapSpeed = 1.05 / Math.sqrt(m.scale);

      // Drop it onto the orbit, moving along the tangent.
      animator.pos.set(
        centre.x + Math.cos(m.phase) * m.radius,
        m.altitude,
        centre.z + Math.sin(m.phase) * m.radius * m.ry,
      );
      const tangent = new THREE.Vector3(
        -Math.sin(m.phase), 0, Math.cos(m.phase) * m.ry,
      ).normalize();
      animator.vel.copy(tangent).multiplyScalar(m.speed);
      animator.forward.copy(tangent);
      this.members.push({ dragon, animator, cfg: m });
    }
  }

  update(dt, camera) {
    for (const m of this.members) m.animator.update(dt, camera);
  }

  dispose() {
    for (const m of this.members) m.dragon.dispose();
  }
}
