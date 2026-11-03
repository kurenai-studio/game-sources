/**
 * Ash-crows.
 *
 * One InstancedMesh of two-triangle wings; the flap, the banking roll and the
 * orbit are all evaluated in the vertex shader from a per-instance seed. The
 * flocks scatter when the dragon passes close — the one piece of CPU logic,
 * because it needs to know where the dragon is.
 */
import * as THREE from 'three';
import { G } from '../materials/GlobalUniforms.js';
import { WORLD, height } from '../world/Heightfield.js';
import { TAU } from '../utils/MathX.js';

const vert = /* glsl */`
attribute vec3  aOrbit;      // radius, altitude, angular speed
attribute vec3  aCenter;     // orbit centre
attribute float aPhase;
attribute float aFlap;

varying float vShade;
varying float vWing;

uniform float uTime;
uniform vec3  uScatter;      // xyz = dragon position
uniform float uScatterR;

void main(){
  float t = uTime * aOrbit.z + aPhase;

  // Orbit with a slow vertical bob and an elliptical squash.
  vec3 c = aCenter;
  float r = aOrbit.x * (1.0 + 0.12 * sin(t * 0.7));
  vec3 p = vec3(c.x + cos(t) * r, c.y + aOrbit.y + sin(t * 1.7) * 6.0, c.z + sin(t) * r * 0.78);

  // Flee the dragon: push outward and up when it gets close.
  vec3 away = p - uScatter;
  float d = length(away);
  float flee = 1.0 - smoothstep(uScatterR * 0.4, uScatterR, d);
  p += normalize(away + vec3(0.001)) * flee * 70.0;
  p.y += flee * 26.0;

  // Heading = orbit tangent; bank into the turn.
  vec3 tangent = normalize(vec3(-sin(t), 0.0, cos(t) * 0.78));
  vec3 up = vec3(0.0, 1.0, 0.0);
  vec3 side = normalize(cross(up, tangent));
  float bank = 0.55 + flee * 0.6;

  // Wing flap: faster when fleeing.
  float flapT = uTime * (aFlap * (1.0 + flee * 1.6)) + aPhase * 3.0;
  float flap = sin(flapT);
  float span = position.x;                       // -1..1 across the wings
  float chord = position.y;

  vec3 local = side * span * 1.0
             + up * (abs(span) * flap * 0.85 - bank * span * 0.35)
             + tangent * chord;

  vec3 world = p + local * 1.0;
  vShade = 0.45 + 0.55 * abs(flap);
  vWing = abs(span);

  gl_Position = projectionMatrix * viewMatrix * vec4(world, 1.0);
}`;

const frag = /* glsl */`
precision highp float;
varying float vShade;
varying float vWing;
uniform vec3 uColor;
void main(){
  gl_FragColor = vec4(uColor * (0.35 + vShade * 0.5) * (1.0 - vWing * 0.25), 1.0);
}`;

export class Birds {
  constructor(settings) {
    const count = settings.birdCount;

    // A bird = two triangles (left wing, right wing) with a shared body vertex.
    const scale = 2.6;
    const pos = new Float32Array([
      // left wing
      0, 0.4, 0,   -1, 0, 0,   -0.35, -0.6, 0,
      // right wing
      0, 0.4, 0,    1, 0, 0,    0.35, -0.6, 0,
    ]);
    for (let i = 0; i < pos.length; i += 3) { pos[i] *= scale; pos[i + 1] *= scale; }

    const base = new THREE.BufferGeometry();
    base.setAttribute('position', new THREE.BufferAttribute(pos, 3));

    const geo = new THREE.InstancedBufferGeometry();
    geo.attributes.position = base.attributes.position;
    geo.instanceCount = count;

    const orbit = new Float32Array(count * 3);
    const center = new Float32Array(count * 3);
    const phase = new Float32Array(count);
    const flap = new Float32Array(count);

    // Flocks: a few loose groups, each circling a landmark.
    const anchors = [
      [WORLD.village.x, WORLD.village.z, 120],
      [WORLD.temple.x, WORLD.temple.z, 90],
      [WORLD.castle.x, WORLD.castle.z, 170],
      [180, 640, 100],
      [WORLD.pool.x, WORLD.pool.z, 120],
      [-520, -120, 240],
    ];

    for (let i = 0; i < count; i++) {
      const a = anchors[i % anchors.length];
      const jitter = 40;
      const cx = a[0] + (Math.random() - 0.5) * jitter;
      const cz = a[1] + (Math.random() - 0.5) * jitter;
      center[i * 3] = cx;
      center[i * 3 + 1] = height(cx, cz);
      center[i * 3 + 2] = cz;
      orbit[i * 3] = a[2] * (0.5 + Math.random() * 0.8);
      orbit[i * 3 + 1] = 40 + Math.random() * 130;
      orbit[i * 3 + 2] = (0.06 + Math.random() * 0.09) * (Math.random() > 0.5 ? 1 : -1);
      phase[i] = Math.random() * TAU;
      flap[i] = 5 + Math.random() * 5;
    }

    geo.setAttribute('aOrbit', new THREE.InstancedBufferAttribute(orbit, 3));
    geo.setAttribute('aCenter', new THREE.InstancedBufferAttribute(center, 3));
    geo.setAttribute('aPhase', new THREE.InstancedBufferAttribute(phase, 1));
    geo.setAttribute('aFlap', new THREE.InstancedBufferAttribute(flap, 1));

    this.material = new THREE.ShaderMaterial({
      vertexShader: vert, fragmentShader: frag,
      uniforms: {
        uTime: G.uTime,
        uColor: { value: new THREE.Color(0x14100f) },
        uScatter: { value: new THREE.Vector3(0, -9999, 0) },
        uScatterR: { value: 220 },
      },
      side: THREE.DoubleSide,
    });

    this.mesh = new THREE.Mesh(geo, this.material);
    this.mesh.frustumCulled = false;
    this.mesh.name = 'Birds';
    this.group = this.mesh;
    base.dispose?.();
  }

  update(dt, dragonPos) {
    if (dragonPos) this.material.uniforms.uScatter.value.copy(dragonPos);
  }

  setMood(color) { this.material.uniforms.uColor.value.set(color); }

  dispose() { this.mesh.geometry.dispose(); this.material.dispose(); }
}
