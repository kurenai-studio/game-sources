import * as THREE from 'three';
import { SSTEP } from '../gfx/glsl.js';

/* Pickup beacon: camera-facing additive shaft + gaussian ground glow.
 * A 10-gon cylinder read as a glass card up close (hard silhouette,
 * corner crease, fat-base pulse blob). A Y-billboard with gaussian-X
 * falloff has no geometric edge — alpha is 0 before the mesh rim.
 * Distance-weighted gain keeps the alley god-ray while the near-camera
 * core stays off the bloom knee. */

const SHAFT_VS = /* glsl */ `
varying vec2 vUv;
varying vec3 vWorldP;
void main(){
  vUv = uv;
  vWorldP = (modelMatrix * vec4(position, 1.0)).xyz;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

const SHAFT_FS = /* glsl */ `
uniform vec3 uColor;
uniform float uGain;
varying vec2 vUv;
varying vec3 vWorldP;
${SSTEP}
void main(){
  float x = abs(vUv.x - 0.5) * 2.0;
  float dist = length(cameraPosition - vWorldP);
  float nearW = sstep(8.0, 2.3, dist);
  float farW = sstep(3.6, 6.2, dist);
  float halo = exp(-x * x * 1.85);
  float core = exp(-x * x * 6.4);
  float gx = halo * mix(0.50, 0.40, nearW) + core * (farW * 2.05);
  float top = sstep(1.0, 0.48, vUv.y);
  float bot = sstep(0.0, 0.22, vUv.y);
  float a = uGain * gx * top * bot;
  gl_FragColor = vec4(uColor, a);
}
`;

const GLOW_VS = /* glsl */ `
varying vec2 vUv;
void main(){
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

const GLOW_FS = /* glsl */ `
uniform vec3 uColor;
uniform float uGain;
varying vec2 vUv;
void main(){
  vec2 d = vUv - vec2(0.5);
  float r2 = dot(d, d) * 4.0;
  float a = exp(-r2 * 2.4) * uGain;
  gl_FragColor = vec4(uColor, a);
}
`;

function additive(color, vs, fs, gain) {
  return new THREE.ShaderMaterial({
    uniforms: {
      uColor: { value: new THREE.Color(color) },
      uGain: { value: gain },
    },
    vertexShader: vs,
    fragmentShader: fs,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
    toneMapped: false,
    fog: false,
  });
}

export function makeBeaconShaftMat(color) {
  return additive(color, SHAFT_VS, SHAFT_FS, 0.55);
}

export function makeBeaconGlowMat(color) {
  return additive(color, GLOW_VS, GLOW_FS, 0.28);
}
