/**
 * Shared wind displacement.
 *
 * One function, used by trees, grass, banners, leaves and reeds — so every
 * moving plant in the realm agrees on gust phase and direction. That coherence
 * is what makes wind read as *weather* rather than as per-object wobble.
 */
import { AX_GLOBALS } from './noise.glsl.js';

export const WIND_GLSL = /* glsl */`
${AX_GLOBALS}
#ifndef AX_WIND_INCLUDED
#define AX_WIND_INCLUDED

/**
 * Outward shove from an expanding ring (xyz origin, w radius; w < 0 = off).
 * A sharp leading band, then a damped rebound behind it so plants spring back
 * past upright instead of just relaxing — that overshoot is what sells mass.
 */
vec3 blastPush(vec3 wp, vec4 wave, float width, float reach, float amp){
  if (wave.w <= 0.0) return vec3(0.0);
  vec2 d = wp.xz - wave.xz;
  float r = length(d);
  float x = (wave.w - r) / width;            // >0 once the front has passed
  float front = exp(-x * x);
  float wake = x > 0.0 ? -0.45 * sin(x * 1.6) * exp(-x * 0.55) : 0.0;
  float fall = smoothstep(reach, reach * 0.12, wave.w);
  vec2 dir = d / max(r, 1e-3);
  float k = (front + wake) * fall * amp;
  return vec3(dir.x * k, -abs(k) * 0.3, dir.y * k);
}

/**
 * @param worldPos  world-space position of the vertex
 * @param stiffness 0 = tip (max sway), 1 = root (locked)
 * @param freq      per-object frequency multiplier
 */
vec3 windOffset(vec3 worldPos, float stiffness, float freq){
  float flex = 1.0 - clamp(stiffness, 0.0, 1.0);
  if (flex <= 0.001) return vec3(0.0);

  // Travelling gust front: a slow wave moving downwind across the whole map.
  float travel = dot(worldPos.xz, uWindDir) * 0.0045;
  float gust   = 0.55 + 0.45 * sin(uTime * 0.31 - travel * 1.7 + uGustPhase);
  gust *= 0.75 + 0.35 * sin(uTime * 0.11 - travel * 0.4);

  // Two detuned oscillators avoid a metronome feel.
  float t  = uTime * freq;
  float a  = sin(t * 1.9 - travel * 5.0);
  float b  = sin(t * 3.7 + worldPos.y * 0.09 + travel * 3.0) * 0.42;
  float sway = (a + b) * gust * uWindStrength;

  vec3 lateral = vec3(uWindDir.x, 0.0, uWindDir.y) * sway;
  vec3 flutter = vec3(-uWindDir.y, 0.0, uWindDir.x) * sway * 0.35
               * sin(t * 5.3 + worldPos.x * 0.2);

  // Bending shortens vertical reach slightly — keeps volume believable.
  float droop = -abs(sway) * 0.16;

  // Pressure waves: the eruption's blast and the dragon's roar. They ride the
  // same flex² falloff and per-material amp as the sway, so roots stay planted,
  // canopies heel right over and grass just shivers flat.
  vec3 blast = blastPush(worldPos, uShockwave, 70.0, 1500.0, 9.0)
             + blastPush(worldPos, uRoarWave,  45.0,  900.0, 5.5);

  return (lateral + flutter + vec3(0.0, droop, 0.0) + blast) * flex * flex;
}
#endif
`;
