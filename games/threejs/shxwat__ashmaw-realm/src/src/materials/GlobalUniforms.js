/**
 * Shared uniform objects.
 *
 * Three.js compares uniform *object identity* per material, so handing the same
 * object to fifty materials means one write per frame drives all of them. Time,
 * wind, mood and the dragon's fire light all live here — that's what keeps the
 * whole realm in phase instead of each system running its own clock.
 */
import * as THREE from 'three';

export const G = {
  uTime:         { value: 0 },
  uDelta:        { value: 0 },

  // wind
  uWindDir:      { value: new THREE.Vector2(0.82, 0.57) },
  uWindStrength: { value: 0.85 },
  uGustPhase:    { value: 0 },

  // mood — driven by WeatherSystem, read by lava/fire/sky/foliage
  uEmberMood:    { value: 1.0 },   // volcanic glow multiplier
  uSunDir:       { value: new THREE.Vector3(0.4, 0.35, -0.85) },
  uSunColor:     { value: new THREE.Color(0xffb066) },
  uSkyColor:     { value: new THREE.Color(0x2a3550) },
  uFogColor:     { value: new THREE.Color(0x2a2028) },
  uFogDensity:   { value: 0.00055 },
  uWetness:      { value: 0.0 },   // rain darkens & glosses surfaces
  uAshLoad:      { value: 0.25 },  // ash dusting on upward faces

  // dragon fire — a travelling light that lava, water and windows all respond to
  uFirePos:      { value: new THREE.Vector3(0, -999, 0) },
  uFireIntensity:{ value: 0 },
  uFireColor:    { value: new THREE.Color(0xff7a2a) },

  // eruption
  uShockwave:    { value: new THREE.Vector4(0, 0, 0, -1) }, // xyz origin, w radius (<0 = off)

  // the dragon's roar — a second, smaller pressure wave that only foliage feels
  uRoarWave:     { value: new THREE.Vector4(0, 0, 0, -1) },
};

/** Advance the shared clock. Called once per frame by App. */
export function tickGlobals(dt, elapsed) {
  G.uTime.value = elapsed;
  G.uDelta.value = dt;
  G.uGustPhase.value += dt * 0.21 * (0.4 + G.uWindStrength.value);
}
