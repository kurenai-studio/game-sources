/**
 * Eruption sequence — the set piece.
 *
 * This class is the *conductor*: the volcano owns its own particles, the weather
 * owns the sky, the village owns its lights. Eruption just fires them in the
 * right order with the right timing, which is the only way a multi-system event
 * ever feels composed rather than simultaneous.
 *
 * Beat sheet
 *  0.0  ground rumble, birds scatter, village lights gutter
 *  1.2  detonation: flash, shockwave ring, camera slam, bombs launch
 *  1.6  dragon reacts — breaks its orbit, climbs away, roars
 *  3.0  weather crossfades to ERUPTION (sky goes red, ash load triples)
 *  8.0  sustained column; lava surge in every channel
 * 16.0  decay begins
 * 26.0  settle back to an ash storm — the world stays changed
 */
import * as THREE from 'three';
import { gsap } from 'gsap';
import { bus, EV } from '../core/EventBus.js';
import { WORLD } from '../world/Heightfield.js';

export class Eruption {
  constructor({ volcano, weather, village, dragon, lava, rig, lightning }) {
    this.lightning = lightning;
    this.volcano = volcano;
    this.weather = weather;
    this.village = village;
    this.dragon = dragon;
    this.lava = lava;
    this.rig = rig;

    this.active = false;
    this.disturbance = 0;   // 0..1, read by the village for light flicker
    this._boost = { v: 0 };
    this._storm = { v: 0 };   // volcanic-lightning rate in the plume
  }

  trigger() {
    if (this.active) return;
    this.active = true;

    const tl = gsap.timeline({ onComplete: () => { this.active = false; } });

    // ── 0.0 — the warning ────────────────────────────────────────────
    tl.call(() => {
      bus.emit(EV.SHAKE, { amplitude: 0.5, duration: 1.4, frequency: 7 });
      this.weather.lockTimeOfDay(true);
    });
    tl.to(this, { disturbance: 0.75, duration: 1.2, ease: 'power2.in' }, 0);

    // ── 1.2 — detonation ─────────────────────────────────────────────
    tl.call(() => {
      this.volcano.erupt();
      bus.emit(EV.FLASH, { intensity: 0.7, duration: 0.9, color: '#ffd7a8' });
    }, null, 1.2);

    // ── 1.6 — the dragon reacts ──────────────────────────────────────
    tl.call(() => {
      this.dragon.animator.roar();
      // Break away from the volcano and climb.
      this.dragon.animator.circle({
        center: new THREE.Vector3(WORLD.village.x, 0, WORLD.village.z),
        radius: 520, altitude: 470, speed: 74,
      });
    }, null, 1.9);

    // ── 2.4 — the column charges up: volcanic lightning ──────────────
    // Ash grinding against ash in the plume separates charge exactly like a
    // thundercloud. Builds fast, peaks with the column, outlasts the fountain.
    tl.to(this._storm, { v: 1.6, duration: 3, ease: 'power2.in' }, 2.4);
    tl.to(this._storm, { v: 0.5, duration: 8, ease: 'sine.inOut' }, 12);
    tl.to(this._storm, { v: 0, duration: 6 }, 22);

    // ── 3.0 — the sky turns ──────────────────────────────────────────
    tl.call(() => this.weather.apply('eruption', 4.5), null, 3.0);
    tl.to(this._boost, { v: 1, duration: 5, ease: 'power2.out' }, 2.0);

    // ── sustained column ─────────────────────────────────────────────
    tl.to(this, { disturbance: 0.35, duration: 6, ease: 'sine.inOut' }, 3.5);

    // ── decay ────────────────────────────────────────────────────────
    tl.to(this._boost, { v: 0.25, duration: 9, ease: 'sine.inOut' }, 16);
    tl.to(this, { disturbance: 0, duration: 6 }, 18);
    tl.call(() => {
      // The world doesn't go back to normal — it settles into ash.
      this.weather.apply('ashstorm', 7);
      this.weather.lockTimeOfDay(false);
      bus.emit(EV.ERUPTION, { stage: 'settled' });
    }, null, 26);
    tl.to(this._boost, { v: 0, duration: 8 }, 26);

    this._tl = tl;
    return tl;
  }

  update(dt) {
    this.lightning?.setVolcanic(this._storm.v, this.volcano.vent);
    this.weather.setEruptionBoost(this._boost.v);
    this.lava.setSurge(Math.max(this.volcano.surge, this._boost.v * 0.45));
  }
}
