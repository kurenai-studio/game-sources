/**
 * ASHMAW — the Emberwyrm.
 *
 * There is no rigged model here; the whole creature is procedural geometry
 * deformed on the CPU every frame. That's a deliberate choice: it gives us
 * physical behaviour (a tail that whips because it's actually lagging, a neck
 * that overshoots because it's actually sprung) instead of baked clips, and it
 * costs almost nothing — the body is ~26 spine rings and the wings ~2×(14×7)
 * vertices, so a full re-skin is a few thousand float writes.
 *
 * Anatomy
 * ───────
 *  spine[0..25]  snout → tail tip, each node a world-space Spring3
 *  radius[]      profile giving the body its silhouette (thick chest, thin neck)
 *  wings         3-bone arm (humerus/radius/wrist) + 4 finger struts + membrane
 *                grid, membrane sag driven by flap velocity so it *catches* air
 *  extras        horns, jaw, spinal spikes, eyes with glow, claws, tail fin
 *
 * Everything else (flight paths, states, banking) lives in DragonAnimator so
 * this file stays "the body" and that one stays "the performance".
 */
import * as THREE from 'three';
import * as BGU from 'three/addons/utils/BufferGeometryUtils.js';
import { Spring3, TAU, clamp, lerp, smoothstep } from '../utils/MathX.js';
import { G } from '../materials/GlobalUniforms.js';
import { AX_GLOBALS } from '../shaders/lib/noise.glsl.js';

const SPINE = 26;
const RING = 20;

const WING_K = 0.22;
const WING_NORM = 1.08;
function wingBeat(phase) {
  return (Math.sin(phase) + WING_K * Math.sin(2 * phase)) / WING_NORM;
}
function wingBeatVel(phase) {
  return (Math.cos(phase) + 2 * WING_K * Math.cos(2 * phase)) / WING_NORM;
}

/** The leg cylinders extend along local -Y after their geometry translate. */
const LEG_DOWN = new THREE.Vector3(0, -1, 0);

const SEGMENT_PITCH = 1.62;
const RADIUS = [
  0.75, 1.15, 1.55, 1.85,          // snout → skull
  1.45, 1.35, 1.40, 1.55, 1.85,    // neck
  2.70, 3.80, 4.65, 4.85, 4.50,    // chest → belly
  3.80, 3.10, 2.45, 1.95,          // hips → tail base
  1.55, 1.25, 0.95, 0.70,
  0.50, 0.35, 0.22, 0.12,          // tail tip
];

export class Dragon {
  /**
   * @param opts.simple  Build a reduced wyrm for the background flight.
   *
   * A full Ashmaw is 40 meshes and ~67 draw calls (measured), and 28 of those
   * meshes are the four legs — an upper, a lower, a haunch, a foot pad and
   * three claws each. At the distance the flight is seen from, a claw is well
   * under a pixel, so `simple` drops the legs entirely and stops the body
   * casting shadows. That takes a flight member to ~12 meshes and roughly a
   * fifth of the draw calls, which is what makes several of them affordable.
   */
  constructor(materials, settings, { simple = false } = {}) {
    this.group = new THREE.Group();
    this.group.name = simple ? 'Wyrm' : 'Dragon';
    this.materials = materials;
    this.simple = simple;
    this.scale = 1.0;

    /** World position of the chest — the animator drives this. */
    this.root = new THREE.Vector3(0, 300, 0);
    this.heading = new THREE.Quaternion();
    this.bank = 0;
    this.pitch = 0;

    // ── spine ────────────────────────────────────────────────────────
    this.spine = [];
    this.springs = [];
    for (let i = 0; i < SPINE; i++) {
      const p = new THREE.Vector3(0, 300, -i * 3);
      this.spine.push(p.clone());
      // Head springs are stiff (deliberate look-at), tail is loose (whip).
      const t = i / (SPINE - 1);
      const stiff = i < 9 ? lerp(160, 90, i / 9) : lerp(70, 26, (i - 9) / (SPINE - 10));
      const damp = i < 9 ? lerp(22, 16, i / 9) : lerp(14, 7, (i - 9) / (SPINE - 10));
      this.springs.push(new Spring3(p, stiff, damp));
    }
    this.spineTargets = this.spine.map((p) => p.clone());

    // ── body mesh ────────────────────────────────────────────────────
    this.bodyGeo = this._buildBodyGeometry();
    this.body = new THREE.Mesh(this.bodyGeo, materials.get('hide'));
    this.body.castShadow = !this.simple;
    this.body.receiveShadow = true;
    this.body.frustumCulled = false;
    this.body.name = 'DragonBody';
    this.group.add(this.body);

    // ── wings ────────────────────────────────────────────────────────
    this.wings = [this._buildWing(-1), this._buildWing(1)];
    for (const w of this.wings) this.group.add(w.mesh, w.struts);

    // ── head furniture ───────────────────────────────────────────────
    this._buildHead();

    // ── spikes along the spine ───────────────────────────────────────
    this._buildSpikes();

    // ── limbs ────────────────────────────────────────────────────────
    // `legs` stays an empty array in simple mode so _poseLegs() no-ops.
    this.legs = [];
    if (!simple) this._buildLegs();

    // ── mouth glow + fire anchor ─────────────────────────────────────
    this.mouth = new THREE.Object3D();
    this.group.add(this.mouth);
    this.mouthGlow = new THREE.PointLight(0xff7a28, 0, 90, 2);
    this.group.add(this.mouthGlow);

    this.charge = 0;      // 0..1 throat glow before a breath
    this.breathing = 0;
    this.flapPhase = 0;
    this.flapAmp = 1;
    this.flapSpeed = 1.15;
    this.mouthOpen = 0;
    this.legTuck = 1;     // 1 = tucked for flight, 0 = extended for landing
  }

  /* ── geometry construction ───────────────────────────────────────── */

  _buildBodyGeometry() {
    const geo = new THREE.BufferGeometry();
    const verts = SPINE * (RING + 1);
    const pos = new Float32Array(verts * 3);
    const nrm = new Float32Array(verts * 3);
    const uv = new Float32Array(verts * 2);
    const idx = [];

    for (let s = 0; s < SPINE; s++) {
      for (let r = 0; r <= RING; r++) {
        const i = s * (RING + 1) + r;
        uv[i * 2] = r / RING * 2.0;
        uv[i * 2 + 1] = s / (SPINE - 1) * 6.0;
      }
    }
    for (let s = 0; s < SPINE - 1; s++) {
      for (let r = 0; r < RING; r++) {
        const a = s * (RING + 1) + r;
        const b = (s + 1) * (RING + 1) + r;
        idx.push(a, b, a + 1, b, b + 1, a + 1);
      }
    }

    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('normal', new THREE.BufferAttribute(nrm, 3));
    geo.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
    geo.setIndex(idx);
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 200);
    return geo;
  }

  /**
   * A wing is a grid in "wing space": u runs shoulder→wingtip, v runs
   * leading→trailing edge. We keep the topology and rewrite positions each
   * frame from the arm pose, which is what lets the membrane billow.
   */
  _buildWing(side) {
    const U = 20, V = 10;
    const geo = new THREE.BufferGeometry();
    const n = U * V;
    const pos = new Float32Array(n * 3);
    const nrm = new Float32Array(n * 3);
    const uv = new Float32Array(n * 2);
    const idx = [];
    for (let i = 0; i < U; i++) {
      for (let j = 0; j < V; j++) {
        const k = i * V + j;
        uv[k * 2] = i / (U - 1);
        uv[k * 2 + 1] = j / (V - 1);
      }
    }
    for (let i = 0; i < U - 1; i++) {
      for (let j = 0; j < V - 1; j++) {
        const a = i * V + j, b = (i + 1) * V + j;
        if (side > 0) idx.push(a, b, a + 1, b, b + 1, a + 1);
        else idx.push(a, a + 1, b, b, a + 1, b + 1);
      }
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('normal', new THREE.BufferAttribute(nrm, 3));
    geo.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
    geo.setIndex(idx);
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 200);

    const membrane = this._membraneMaterial();
    const mesh = new THREE.Mesh(geo, membrane);
    mesh.castShadow = !this.simple;
    mesh.frustumCulled = false;
    mesh.name = `Wing${side > 0 ? 'R' : 'L'}`;

    // Finger struts: thin tapered cylinders we re-orient each frame.
    const strutGeo = new THREE.CylinderGeometry(0.16, 0.42, 1, 6, 1);
    strutGeo.translate(0, 0.5, 0);            // origin at the base
    // humerus + forearm + 4 fingers = 6 bones.
    const struts = new THREE.InstancedMesh(strutGeo, this.materials.get('hide'), 6);
    struts.castShadow = !this.simple;
    struts.frustumCulled = false;

    return { side, mesh, geo, struts, U, V };
  }

  /** Wing membrane: translucent, veined, and it glows when backlit. */
  _membraneMaterial() {
    const mat = new THREE.MeshStandardMaterial({
      color: 0x38181a,
      roughness: 0.62,
      metalness: 0.05,
      side: THREE.DoubleSide,
      envMap: this.materials.env,
      envMapIntensity: 0.6,
      emissive: new THREE.Color(0x140202),
      emissiveIntensity: 1.0,
    });
    mat.name = 'membrane';

    mat.onBeforeCompile = (shader) => {
      Object.assign(shader.uniforms, {
        uTime: G.uTime,
        uSunDir: G.uSunDir,
        uFireIntensity: G.uFireIntensity,
        uFireColor: G.uFireColor,
      });
      shader.vertexShader = shader.vertexShader
        .replace('#include <common>', `#include <common>
          varying vec2  vMemUv;
          varying vec3  vMemN;
          varying vec3  vMemW;
        `)
        .replace('#include <worldpos_vertex>', `#include <worldpos_vertex>
          vMemUv = uv;
          vMemN = normalize(mat3(modelMatrix) * objectNormal);
          vMemW = (modelMatrix * vec4(transformed, 1.0)).xyz;
        `);
      shader.fragmentShader = shader.fragmentShader
        .replace('#include <common>', `#include <common>
          varying vec2 vMemUv;
          varying vec3 vMemN;
          varying vec3 vMemW;
          ${AX_GLOBALS}
        `)
        .replace('#include <color_fragment>', `#include <color_fragment>
          {
            // Veins: branching lines along the wing, thicker near the arm.
            float v = vMemUv.y;
            float u = vMemUv.x;
            float rib = abs(sin((v * 7.0 + u * 2.2) * 3.14159));
            float vein = 1.0 - smoothstep(0.0, 0.20, rib);
            float fine = 1.0 - smoothstep(0.0, 0.35, abs(sin((v * 23.0 + u * 6.0) * 3.14159)));
            diffuseColor.rgb *= 1.0 - vein * 0.45 - fine * 0.12;
            // Thinner (paler, warmer) toward the trailing edge — but only
            // slightly. This is leather stretched over bone, not a lampshade.
            diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.20, 0.09, 0.08), smoothstep(0.35, 1.0, v) * 0.45);
          }
        `)
        .replace('#include <emissivemap_fragment>', `#include <emissivemap_fragment>
          {
            /**
             * Sub-surface: sunlight (and firelight) bleeding through the skin.
             *
             * The gain here was 1.5, which is far too much unlit energy: any
             * wing angled away from the sun — i.e. the near wing in half the
             * shots — lit up salmon pink across its whole area and swamped the
             * dark leather it is supposed to be. A backlit membrane does glow,
             * but it glows *at the thin trailing edge*, not over the whole
             * panel, so the exponent goes up (tightening it to near-exact
             * backlighting) and the gain comes down hard.
             */
            vec3 N = normalize(vMemN);
            float back = clamp(dot(-N, normalize(uSunDir)), 0.0, 1.0);
            float thin = smoothstep(0.35, 1.0, vMemUv.y);
            totalEmissiveRadiance += vec3(1.0, 0.30, 0.16) * pow(back, 4.5) * thin * 0.40;
            totalEmissiveRadiance += uFireColor * uFireIntensity * thin * 0.55;
          }
        `);
    };
    mat.customProgramCacheKey = () => 'membrane_v2';
    return mat;
  }

  _buildHead() {
    const hide = this.materials.get('hide');
    const g = new THREE.Group();
    this.head = g;
    this.group.add(g);

    // Snout & Skull base structure
    const skullParts = [];
    const snoutBridge = new THREE.CylinderGeometry(0.85, 1.45, 3.8, 8);
    snoutBridge.rotateX(Math.PI * 0.5);
    snoutBridge.translate(0, 0.25, 1.4);
    skullParts.push(snoutBridge);

    // Nostrils
    for (const s of [-1, 1]) {
      const nos = new THREE.ConeGeometry(0.22, 0.8, 5);
      nos.rotateX(0.4);
      nos.rotateZ(s * 0.3);
      nos.translate(s * 0.45, 0.55, 3.0);
      skullParts.push(nos);
    }

    // Jaw — hinged with lower fangs
    const jawParts = [];
    const jawBase = new THREE.CylinderGeometry(0.75, 1.35, 3.6, 8);
    jawBase.rotateX(Math.PI * 0.5);
    jawBase.translate(0, -0.45, 1.3);
    jawParts.push(jawBase);

    for (let i = 0; i < 7; i++) {
      for (const s of [-1, 1]) {
        const tooth = new THREE.ConeGeometry(0.12, 0.65, 5);
        tooth.rotateX(Math.PI);
        tooth.translate(s * (0.35 + i * 0.05), 0.05, 0.4 + i * 0.45);
        jawParts.push(tooth);
      }
    }
    this.jaw = new THREE.Mesh(BGU.mergeGeometries(jawParts), hide);
    this.jaw.castShadow = !this.simple;
    jawParts.forEach((p) => p.dispose());
    g.add(this.jaw);

    // Upper teeth / Fangs
    for (let i = 0; i < 7; i++) {
      for (const s of [-1, 1]) {
        const tooth = new THREE.ConeGeometry(0.14, 0.72, 5);
        tooth.translate(s * (0.38 + i * 0.05), -0.25, 0.45 + i * 0.45);
        skullParts.push(tooth);
      }
    }

    for (const s of [-1, 1]) {
      // Main horns: large, swept back and curving outward
      const horn = new THREE.ConeGeometry(0.48, 5.4, 8);
      horn.translate(0, 2.7, 0);
      horn.rotateX(0.75);
      horn.rotateZ(s * 0.45);
      horn.translate(s * 0.95, 0.75, -1.1);
      skullParts.push(horn);

      // Secondary horns
      const h2 = new THREE.ConeGeometry(0.28, 3.0, 7);
      h2.translate(0, 1.5, 0);
      h2.rotateX(1.3);
      h2.rotateZ(s * 0.75);
      h2.translate(s * 1.15, 0.25, -0.3);
      skullParts.push(h2);

      // Cheek armor plates & spikes
      const c = new THREE.ConeGeometry(0.18, 1.4, 6);
      c.translate(0, 0.7, 0);
      c.rotateX(1.7);
      c.rotateZ(s * 1.1);
      c.translate(s * 1.1, -0.35, 0.5);
      skullParts.push(c);

      // Brow Ridge / Eye Arch
      const brow = new THREE.BoxGeometry(0.85, 0.35, 1.4);
      brow.rotateZ(s * 0.25);
      brow.translate(s * 0.72, 0.65, 0.2);
      skullParts.push(brow);
    }

    // Crown Frill / Spine crest
    for (let i = 0; i < 7; i++) {
      const t = i / 6;
      const spike = new THREE.ConeGeometry(0.14, 1.8 - Math.abs(t - 0.5) * 1.4, 5);
      spike.translate(0, (1.8 - Math.abs(t - 0.5) * 1.4) / 2, 0);
      spike.rotateX(-0.55);
      spike.rotateZ((t - 0.5) * 1.8);
      spike.translate((t - 0.5) * 2.2, 0.5, -1.6);
      skullParts.push(spike);
    }
    this.skull = new THREE.Mesh(BGU.mergeGeometries(skullParts), hide);
    this.skull.castShadow = !this.simple;
    skullParts.forEach((p) => p.dispose());
    g.add(this.skull);

    // Eyes: an emissive core plus a soft additive halo so they read at distance.
    this.eyes = [];
    for (const s of [-1, 1]) {
      const eye = new THREE.Mesh(
        new THREE.SphereGeometry(0.26, 12, 10),
        this.materials.get('eyeGlow'),
      );
      eye.position.set(s * 0.78, 0.30, -0.15);
      g.add(eye);
      const halo = new THREE.Sprite(new THREE.SpriteMaterial({
        map: this.materials.T.glow, color: 0xffb14a,
        blending: THREE.AdditiveBlending, transparent: true,
        depthWrite: false, toneMapped: false, opacity: 0.85,
      }));
      halo.scale.setScalar(2.2);   // local to the head group, already scaled
      halo.position.copy(eye.position);
      g.add(halo);
      this.eyes.push({ eye, halo });
    }

    // Throat glow — brightens as it charges a breath.
    this.throat = new THREE.Mesh(
      new THREE.SphereGeometry(0.62, 12, 10),
      new THREE.MeshBasicMaterial({ color: 0xff5a12, transparent: true, opacity: 0, toneMapped: false }),
    );
    this.throat.position.set(0, -0.1, 1.1);
    g.add(this.throat);
  }

  _buildSpikes() {
    const geo = new THREE.ConeGeometry(0.3, 1.6, 5);
    geo.translate(0, 0.8, 0);
    this.spikes = new THREE.InstancedMesh(geo, this.materials.get('hide'), SPINE - 6);
    this.spikes.castShadow = !this.simple;
    this.spikes.frustumCulled = false;
    this.group.add(this.spikes);

    // Tail fin — two blades at the tip.
    const finParts = [];
    for (const s of [-1, 1]) {
      const f = new THREE.BoxGeometry(0.2, 2.6, 3.2);
      f.rotateZ(s * 0.5);
      f.translate(s * 0.5, 0.9, -1.2);
      finParts.push(f);
    }
    this.tailFin = new THREE.Mesh(BGU.mergeGeometries(finParts), this.materials.get('hide'));
    this.tailFin.castShadow = !this.simple;
    this.tailFin.frustumCulled = false;
    finParts.forEach((p) => p.dispose());
    this.group.add(this.tailFin);
  }

  _buildLegs() {
    const hide = this.materials.get('hide');
    this.legs = [];
    for (const side of [-1, 1]) {
      for (const fore of [true, false]) {
        /**
         * Thigh mass.
         *
         * A 0.55-radius stick emerging from a 4.85-radius torso has nothing
         * joining the two, so the limbs read as four detached blocks floating
         * under the body — which is exactly how they looked. Real quadrupeds
         * carry a big muscled haunch that blends the limb into the flank; this
         * squashed sphere at the hip does that job and costs 4 draw-batched
         * spheres. It is parented to the upper limb, so it swings with it.
         */
        const upper = new THREE.Mesh(new THREE.CylinderGeometry(0.75, 1.05, 3.4, 8), hide);
        upper.geometry.translate(0, -1.7, 0);
        const haunch = new THREE.Mesh(new THREE.SphereGeometry(2.05, 10, 8), hide);
        haunch.scale.set(1.0, 1.25, 1.35);
        haunch.position.y = -0.35;
        haunch.castShadow = true;
        upper.add(haunch);
        const lower = new THREE.Mesh(new THREE.CylinderGeometry(0.44, 0.72, 3.0, 8), hide);
        lower.geometry.translate(0, -1.5, 0);
        const foot = new THREE.Group();
        const pad = new THREE.Mesh(new THREE.SphereGeometry(0.62, 8, 6), hide);
        pad.scale.set(1.3, 0.6, 1.5);
        foot.add(pad);
        for (let c = 0; c < 3; c++) {
          const claw = new THREE.Mesh(new THREE.ConeGeometry(0.13, 1.0, 5), hide);
          claw.rotation.set(1.9, (c - 1) * 0.5, 0);
          claw.position.set((c - 1) * 0.4, -0.1, 0.75);
          foot.add(claw);
        }
        for (const o of [upper, lower, pad]) o.castShadow = true;
        lower.position.y = -3.4;
        foot.position.y = -3.0;
        lower.add(foot);
        upper.add(lower);
        this.group.add(upper);
        this.legs.push({ side, fore, upper, lower, foot });
      }
    }
  }

  /* ── per-frame skinning ──────────────────────────────────────────── */

  /**
   * @param pose {position, forward, up, bank, speed, flapAmp, flapSpeed,
   *              neckLook, mouthOpen, legTuck, charge}
   */
  update(dt, pose) {
    const S = this.scale;
    this.flapPhase += dt * pose.flapSpeed * TAU * 0.55;
    const flap = wingBeat(this.flapPhase);
    const flapVel = wingBeatVel(this.flapPhase);

    // ── frame ────────────────────────────────────────────────────────
    const fwd = pose.forward.clone().normalize();
    const worldUp = new THREE.Vector3(0, 1, 0);
    const right = new THREE.Vector3().crossVectors(worldUp, fwd).normalize();
    if (right.lengthSq() < 1e-6) right.set(1, 0, 0);
    const up = new THREE.Vector3().crossVectors(fwd, right).normalize();

    // Roll the frame for banking.
    const bankQ = new THREE.Quaternion().setFromAxisAngle(fwd, -pose.bank);
    right.applyQuaternion(bankQ);
    up.applyQuaternion(bankQ);

    this.frame = { fwd, right, up };

    // ── spine targets ────────────────────────────────────────────────
    // Chest sits at spine[11]; we lay the body out along the flight axis with
    // an S-curve so the neck rises and the tail trails.
    const chestIdx = 11;
    const base = pose.position;

    for (let i = 0; i < SPINE; i++) {
      const d = (i - chestIdx) * SEGMENT_PITCH * S;   // negative = ahead (head)
      const t = i / (SPINE - 1);

      // Undulation: a travelling wave down the body, stronger toward the tail.
      const waveAmp = (i < chestIdx ? 0.25 : smoothstep(0.42, 1.0, t) * 1.5) * S;
      const wave = Math.sin(this.flapPhase * 0.9 - i * 0.42) * waveAmp;

      // Neck lift and head look.
      let lift = 0;
      if (i < 9) {
        const nt = 1 - i / 9;                  // 1 at snout
        lift = (2.6 + pose.neckLook * 5.0) * nt * nt * S;
      } else if (i > chestIdx + 3) {
        // Tail droops when slow, streams straight when fast.
        lift = -smoothstep(0.5, 1.0, t) * (3.2 - clamp(pose.speed / 40, 0, 1) * 2.6) * S;
      }

      // Breathing: the chest expands.
      const breath = Math.sin(G.uTime.value * 1.15) * 0.28
                   * smoothstep(0.28, 0.5, t) * smoothstep(0.75, 0.5, t) * S;

      this.spineTargets[i].copy(base)
        .addScaledVector(fwd, -d)
        .addScaledVector(up, lift + breath + flap * 0.3 * (1 - Math.abs(t - 0.45) * 1.4) * S)
        .addScaledVector(right, wave);
    }

    // Springs give lag: head leads, tail follows. Head node is driven directly
    // so the animator's aim is exact; everything else settles behind it.
    for (let i = 0; i < SPINE; i++) {
      if (i === chestIdx) this.spine[i].copy(this.spineTargets[i]);
      else this.spine[i].copy(this.springs[i].step(this.spineTargets[i], dt));
    }

    this._skinBody(S);
    this._poseHead(pose, S);
    this._poseSpikes(S);
    this._poseWings(dt, pose, flap, flapVel, S);
    this._poseLegs(pose, S);

    // Mouth anchor for the fire breath.
    const snout = this.spine[0];
    const jawDir = new THREE.Vector3().subVectors(this.spine[0], this.spine[2]).normalize();
    this.mouth.position.copy(snout).addScaledVector(jawDir, 3.4 * S);
    this.mouthDir = jawDir;

    // Throat/eye glow.
    const glow = Math.max(pose.charge, this.breathing);
    this.throat.material.opacity = glow * 0.9;
    this.throat.scale.setScalar(1 + glow * 0.5);
    for (const e of this.eyes) {
      e.halo.material.opacity = 0.55 + glow * 0.45 + 0.12 * Math.sin(G.uTime.value * 3.1);
      // The halo is parented to the head group, which is already scaled by S —
      // multiplying again gave S² and a beach-ball on the snout.
      e.halo.scale.setScalar(2.0 + glow * 1.6);
    }
    this.mouthGlow.position.copy(this.mouth.position);
    this.mouthGlow.intensity = glow * 260;
  }

  _skinBody(S) {
    const pos = this.bodyGeo.attributes.position.array;
    const nrm = this.bodyGeo.attributes.normal.array;
    const tan = new THREE.Vector3();
    const rad = new THREE.Vector3();
    const bin = new THREE.Vector3();
    const p = new THREE.Vector3();
    const worldUp = new THREE.Vector3(0, 1, 0);

    for (let s = 0; s < SPINE; s++) {
      const c = this.spine[s];
      const prev = this.spine[Math.max(0, s - 1)];
      const next = this.spine[Math.min(SPINE - 1, s + 1)];
      tan.subVectors(next, prev);
      if (tan.lengthSq() < 1e-8) tan.set(0, 0, 1);
      tan.normalize();
      rad.crossVectors(worldUp, tan);
      if (rad.lengthSq() < 1e-8) rad.set(1, 0, 0);
      rad.normalize();
      bin.crossVectors(tan, rad).normalize();

      const r = RADIUS[s] * S;
      for (let k = 0; k <= RING; k++) {
        const a = (k / RING) * TAU;
        // Elliptical, flatter on the belly, with a dorsal keel.
        const ca = Math.cos(a), sa = Math.sin(a);
        const keel = 1 + Math.max(0, sa) * 0.18;
        const belly = 1 - Math.max(0, -sa) * 0.22;
        p.copy(c)
          .addScaledVector(rad, ca * r * 1.06)
          .addScaledVector(bin, sa * r * keel * belly);
        const i = (s * (RING + 1) + k) * 3;
        pos[i] = p.x; pos[i + 1] = p.y; pos[i + 2] = p.z;
        // Normal ≈ radial direction (exact enough for a tube).
        nrm[i] = rad.x * ca + bin.x * sa;
        nrm[i + 1] = rad.y * ca + bin.y * sa;
        nrm[i + 2] = rad.z * ca + bin.z * sa;
      }
    }
    this.bodyGeo.attributes.position.needsUpdate = true;
    this.bodyGeo.attributes.normal.needsUpdate = true;
  }

  _poseHead(pose, S) {
    const head = this.spine[2];
    const fwd = new THREE.Vector3().subVectors(this.spine[0], this.spine[4]).normalize();
    const up = this.frame.up;
    this.head.position.copy(head);
    this.head.scale.setScalar(S);
    const m = new THREE.Matrix4().lookAt(new THREE.Vector3(), fwd.clone().negate(), up);
    this.head.quaternion.setFromRotationMatrix(m);

    this.jaw.rotation.x = pose.mouthOpen * 0.55;
    this.jaw.position.set(0, -0.05 - pose.mouthOpen * 0.15, 0);
  }

  _poseSpikes(S) {
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const p = new THREE.Vector3();
    const sc = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    const dir = new THREE.Vector3();
    const spikeDir = new THREE.Vector3();

    for (let i = 0; i < SPINE - 6; i++) {
      const s = i + 4;
      const c = this.spine[s];
      dir.subVectors(this.spine[Math.min(SPINE - 1, s + 1)], this.spine[Math.max(0, s - 1)]).normalize();
      const rad = new THREE.Vector3().crossVectors(up, dir).normalize();
      const bin = new THREE.Vector3().crossVectors(dir, rad).normalize();

      // Swept back orientation: tilt backward along -dir by ~45 degrees
      spikeDir.copy(bin).multiplyScalar(0.72).addScaledVector(dir, -0.68).normalize();
      p.copy(c).addScaledVector(bin, RADIUS[s] * S * 0.92);
      q.setFromUnitVectors(up, spikeDir);

      // Scute sizing: large armor plates on shoulders/back, tapering down tail
      const scuteFactor = (s >= 8 && s <= 15) ? 1.55 : 1.0;
      const size = (0.42 + RADIUS[s] * 0.48) * S * scuteFactor;
      sc.set(size * 0.75, size * 1.85, size * 0.75);
      m.compose(p, q, sc);
      this.spikes.setMatrixAt(i, m);
    }
    this.spikes.instanceMatrix.needsUpdate = true;

    // Tail fin at the last node.
    const tip = this.spine[SPINE - 1];
    const d = new THREE.Vector3().subVectors(tip, this.spine[SPINE - 3]).normalize();
    this.tailFin.position.copy(tip);
    this.tailFin.scale.setScalar(S);
    this.tailFin.quaternion.setFromRotationMatrix(
      new THREE.Matrix4().lookAt(new THREE.Vector3(), d.clone().negate(), this.frame.up),
    );
  }

  /**
   * Wing kinematics.
   *
   * The arm is three joints (shoulder → elbow → wrist), each swinging on the
   * flap phase with a *phase delay* down the chain — that lag is the entire
   * reason real wings look like they're pushing air rather than waving. The
   * membrane then sags between the finger struts by an amount proportional to
   * flap velocity, so it billows on the downstroke and snaps taut on the up.
   */
  _poseWings(dt, pose, flap, flapVel, S) {
    const shoulderIdx = 10;
    const shoulderC = this.spine[shoulderIdx];
    const { fwd, right, up } = this.frame;
    const amp = pose.flapAmp;

    for (const w of this.wings) {
      const side = w.side;
      const sideDir = right.clone().multiplyScalar(side);

      const shoulder = shoulderC.clone()
        .addScaledVector(sideDir, 3.0 * S)
        .addScaledVector(up, 1.3 * S);

      /**
       * Joint angles (radians): positive = up.
       *
       * The rest offsets here are the difference between a dragon that soars
       * and one that looks like it is permanently half-folding its wings.
       * They used to be -0.12 at the shoulder, -0.25 at the elbow and -0.10 at
       * the wrist — and because each joint's angle is built on the previous
       * one, those don't sit side by side, they *accumulate*: -0.47 rad, a
       * 27° downward droop through the arm before the flap wave is even
       * applied, with the finger fan then inheriting all of it. Measured on a
       * level, unbanked, fully-spread pose the wingtip sat 19 units below the
       * shoulder while reaching only 47 out.
       *
       * Real soaring anatomy is the opposite: a *slight dihedral*, wings held
       * a touch above horizontal (it's what makes a flyer self-righting), with
       * the chain close to straight so the span is actually deployed. The flap
       * wave then swings around that rest pose instead of hanging below it.
       */
      const fold = 1 - pose.wingSpread;         // 0 open, 1 folded
      const sFlap = flap * amp * 0.85 + 0.13;
      const eFlap = wingBeat(this.flapPhase - 0.55) * amp * 0.5;
      const wFlap = wingBeat(this.flapPhase - 1.05) * amp * 0.42;

      // Bone lengths. A 61-unit body was carrying a 101-unit total span — a
      // ratio of 1.7, which is glider-like rather than dragon-like and is a
      // large part of why the creature read as small and stubby. Real large
      // flyers run 2.5–3x body length; these put it at ~2.8.
      const humerus = 14.0 * S, radius = 17.0 * S, wrist = 10.0 * S;

      // Build the arm in the (sideDir, up, fwd) frame.
      const elbow = shoulder.clone()
        .addScaledVector(sideDir, Math.cos(sFlap) * humerus * (1 - fold * 0.55))
        .addScaledVector(up, Math.sin(sFlap) * humerus)
        .addScaledVector(fwd, -0.6 * S + fold * 2.5 * S);

      const eAngle = sFlap + eFlap - 0.06 - fold * 1.5;
      const wristP = elbow.clone()
        .addScaledVector(sideDir, Math.cos(eAngle) * radius * (1 - fold * 0.7))
        .addScaledVector(up, Math.sin(eAngle) * radius)
        .addScaledVector(fwd, -1.4 * S + fold * 4.0 * S);

      const wAngle = eAngle + wFlap - 0.03 - fold * 0.8;
      const tip = wristP.clone()
        .addScaledVector(sideDir, Math.cos(wAngle) * wrist * (1 - fold * 0.85))
        .addScaledVector(up, Math.sin(wAngle) * wrist)
        .addScaledVector(fwd, -1.0 * S + fold * 3.0 * S);

      w.joints = { shoulder, elbow, wrist: wristP, tip };

      // ── finger struts: fan from the wrist toward the trailing edge ──
      const fingers = [];
      const nF = 4;
      for (let f = 0; f < nF; f++) {
        const t = f / (nF - 1);
        // Finger 0 continues the wing outboard; finger 3 rakes back toward the
        // tail. That spread is what gives the membrane its chord — and the
        // chord was far too small, so the "wing" was a narrow strap of
        // membrane hung off a long arm. Longer inner fingers and a wider rake
        // give the wing an actual area to catch light and cast shadow with.
        const len = lerp(20.0, 15.0, t) * S * (1 - fold * 0.82);
        const outward = 1 - t * 0.62;
        const backward = 0.30 + t * 2.45;
        const dirV = new THREE.Vector3()
          .addScaledVector(sideDir, Math.cos(wAngle) * outward)
          .addScaledVector(up, Math.sin(wAngle) * (1 - t * 0.45))
          .addScaledVector(fwd, -backward)
          .normalize();
        fingers.push({ base: wristP, dir: dirV, len, end: wristP.clone().addScaledVector(dirV, len) });
      }
      w.fingers = fingers;

      this._skinMembrane(w, fingers, flapVel, amp, S);
      this._writeStruts(w, fingers, S);
    }
  }

  _skinMembrane(w, fingers, flapVel, amp, S) {
    const { U, V } = w;
    const pos = w.geo.attributes.position.array;
    const nrm = w.geo.attributes.normal.array;
    const { shoulder, elbow, wrist } = w.joints;
    const sag = -flapVel * amp * 1.9 * S;       // billow direction follows the stroke
    const upV = this.frame.up;
    const tmp = new THREE.Vector3();
    const a = new THREE.Vector3();
    const b = new THREE.Vector3();

    // Leading edge: shoulder → elbow → wrist → wingtip (finger 0's tip).
    const lead = [shoulder, elbow, wrist, fingers[0].end];
    // Trailing edge: from the flank *outward* — so the innermost trailing point
    // is the most raked-back finger and the chain closes at the same wingtip
    // the leading edge ends on. Ordering these the other way round makes the
    // membrane fold into a sail along the spine instead of spanning the wing.
    const bodyRoot = this.spine[15].clone()
      .addScaledVector(this.frame.up, 0.8 * S)
      .addScaledVector(this.frame.right, w.side * RADIUS[15] * 0.7 * S);
    const trail = [bodyRoot, fingers[3].end, fingers[2].end, fingers[1].end, fingers[0].end];

    /**
     * Scallop depth along the span.
     *
     * A bat/dragon wing's trailing edge does not run straight from fingertip to
     * fingertip — the membrane is slack between the struts and bows *inward*,
     * which is what gives the wing its distinctive scalloped rear edge. Without
     * it the membrane is a straight-edged trapezoid, and a straight-edged
     * trapezoid on a straight arm reads as an aircraft wing, not an animal's.
     *
     * There are 4 fingers, so 3 gaps; sin(3π·t) is one full inward bow per gap,
     * zero exactly at each strut where the membrane is pinned.
     */
    const scallopAt = (u) => Math.sin(clamp(u, 0, 1) * Math.PI * 3.0);

    for (let i = 0; i < U; i++) {
      const u = i / (U - 1);
      // Sample the leading edge as a polyline.
      const le = sampleChain(lead, u, a);
      const te = sampleChain(trail, u, b);

      // Pull the trailing edge in toward the leading edge between struts.
      const scallop = Math.abs(scallopAt(u)) * 0.13 * smoothstep(0.05, 0.35, u);

      for (let j = 0; j < V; j++) {
        const v = j / (V - 1);
        // v is remapped so the chord shortens between the fingers.
        tmp.lerpVectors(le, te, v * (1.0 - scallop));

        // Camber: an airfoil is not a flat sheet, it's a curved one. Bowing the
        // membrane along the chord is what lets it shade smoothly from leading
        // to trailing edge instead of reading as a flat plank of one value.
        const camber = Math.sin(v * Math.PI) * (0.9 + 0.5 * Math.sin(u * Math.PI));
        tmp.addScaledVector(upV, -camber * 0.9 * S);

        // Catenary sag between the struts, biased toward the trailing edge.
        const s = Math.sin(v * Math.PI) * Math.sin(u * Math.PI * 0.9 + 0.15);
        tmp.addScaledVector(upV, sag * s * (0.4 + v * 0.9));
        // Ripple: high-frequency flutter along the trailing edge.
        const rip = Math.sin(G.uTime.value * 9.0 + u * 11.0 + v * 3.0) * 0.22 * S * v * v;
        tmp.addScaledVector(upV, rip);
        const k = (i * V + j) * 3;
        pos[k] = tmp.x; pos[k + 1] = tmp.y; pos[k + 2] = tmp.z;
      }
    }

    // Recompute normals from the grid (cheap cross products, no full pass).
    for (let i = 0; i < U; i++) {
      for (let j = 0; j < V; j++) {
        const k = i * V + j;
        const i0 = Math.max(0, i - 1) * V + j;
        const i1 = Math.min(U - 1, i + 1) * V + j;
        const j0 = i * V + Math.max(0, j - 1);
        const j1 = i * V + Math.min(V - 1, j + 1);
        a.set(pos[i1 * 3] - pos[i0 * 3], pos[i1 * 3 + 1] - pos[i0 * 3 + 1], pos[i1 * 3 + 2] - pos[i0 * 3 + 2]);
        b.set(pos[j1 * 3] - pos[j0 * 3], pos[j1 * 3 + 1] - pos[j0 * 3 + 1], pos[j1 * 3 + 2] - pos[j0 * 3 + 2]);
        tmp.crossVectors(a, b);
        const len = tmp.length() || 1;
        nrm[k * 3] = (tmp.x / len) * w.side;
        nrm[k * 3 + 1] = (tmp.y / len) * w.side;
        nrm[k * 3 + 2] = (tmp.z / len) * w.side;
      }
    }
    w.geo.attributes.position.needsUpdate = true;
    w.geo.attributes.normal.needsUpdate = true;
  }

  _writeStruts(w, fingers, S) {
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const sc = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    const { shoulder, elbow, wrist } = w.joints;
    const bones = [
      [shoulder, elbow, 0.85],
      [elbow, wrist, 0.7],
      ...fingers.map((f, i) => [f.base, f.end, 0.34 - i * 0.05]),
    ];
    for (let i = 0; i < bones.length; i++) {
      const [from, to, thick] = bones[i];
      const dir = new THREE.Vector3().subVectors(to, from);
      const len = dir.length() || 0.001;
      q.setFromUnitVectors(up, dir.clone().normalize());
      sc.set(thick * S, len, thick * S);
      m.compose(from, q, sc);
      w.struts.setMatrixAt(i, m);
    }
    w.struts.instanceMatrix.needsUpdate = true;
  }

  _poseLegs(pose, S) {
    const tuck = pose.legTuck;
    const localDown = LEG_DOWN;
    for (const leg of this.legs) {
      const idx = leg.fore ? 12 : 15;
      const c = this.spine[idx];
      const { right, up, fwd } = this.frame;
      const p = c.clone()
        .addScaledVector(right, leg.side * RADIUS[idx] * 0.75 * S)
        .addScaledVector(up, -RADIUS[idx] * 0.45 * S);
      leg.upper.position.copy(p);
      leg.upper.scale.setScalar(S);

      /**
       * Tucked (tuck=1): swing the whole limb up and back so it hugs the
       * belly, knee bent hard, foot pulled in — a flying bird's or bat's legs
       * are never just hanging. Extended (tuck=0): reaches straight down for
       * landing/perching.
       *
       * This used to build the limb's orientation via Matrix4.lookAt() into a
       * target direction, convert that to a quaternion, then bolt on an extra
       * fixed rotateX(π/2) to compensate for the cylinder's own local axis —
       * three composed rotations with no direct way to verify the result
       * analytically. Measured live: at tuck=1 the leg's local -Y (where the
       * cylinder geometry actually sits) pointed at world (0.02, -0.98, 0.22)
       * — straight down — regardless of the swing angle, i.e. full flight
       * tuck looked identical to hanging landing gear. Building the target
       * direction and going straight to setFromUnitVectors(localDown, dir)
       * removes the ambiguity: there is exactly one rotation involved, and
       * "does the leg point where `dir` points" is directly checkable.
       */
      const swing = lerp(0.05, 1.35, tuck) + (leg.fore ? 0.08 : -0.08);
      const knee = lerp(0.35, 1.95, tuck);
      const dir = up.clone().negate().applyAxisAngle(right, swing).normalize();
      leg.upper.quaternion.setFromUnitVectors(localDown, dir);

      leg.lower.rotation.x = knee;
      leg.foot.rotation.x = -knee * 0.6 - swing * 0.4;
    }
  }

  setScale(s) { this.scale = s; }

  dispose() {
    this.group.traverse((o) => { o.geometry?.dispose(); });
  }
}

/**
 * Sample a polyline of Vector3 at t∈[0,1] by *arc length*.
 *
 * This used to index by segment count, which quietly wrecked the wing
 * membrane: the leading edge is a 3-segment chain (shoulder→elbow→wrist→tip)
 * and the trailing edge a 4-segment one (body root→finger3→finger2→finger1→
 * tip). At t=0.5 the old version returned the midpoint of leading segment 1
 * and the midpoint of trailing segment 2 — two points that have nothing
 * geometrically to do with each other, and whose segments are also wildly
 * different lengths. Every row of the membrane grid was therefore stretched
 * across the wing at a skew, which is what made the surface fold into a sail
 * along the arm instead of spanning between the fingers.
 *
 * Arc length makes "halfway along the leading edge" and "halfway along the
 * trailing edge" actually correspond, so the grid rows run across the wing.
 */
function sampleChain(chain, t, out) {
  const n = chain.length - 1;
  let total = 0;
  for (let i = 0; i < n; i++) total += chain[i].distanceTo(chain[i + 1]);
  if (total < 1e-6) return out.copy(chain[0]);

  let want = clamp(t, 0, 1) * total;
  for (let i = 0; i < n; i++) {
    const seg = chain[i].distanceTo(chain[i + 1]);
    if (want <= seg || i === n - 1) {
      return out.lerpVectors(chain[i], chain[i + 1], seg < 1e-6 ? 0 : clamp(want / seg, 0, 1));
    }
    want -= seg;
  }
  return out.copy(chain[n]);
}
