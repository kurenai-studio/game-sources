// GPU-animated creature layers. One draw call per creature type, all motion in the vertex shader.
// Instances are plain attributes rather than InstancedMesh: positionNode runs after instancing,
// and the skeleton below needs the untransformed model position. Each part rotates about a lower
// joint, then an upper joint, then the whole body leans, bobs and finally falls when dead.
import * as THREE from 'three/webgpu';
import {
  attribute, positionGeometry, normalGeometry, vec3, vec4, float, sin, cos, abs, max, clamp, mix, pow, normalize,
  dot, varying, cameraViewMatrix, positionViewDirection, uniform, time, Fn, sqrt, saturate, smoothstep, step, mx_noise_float,
} from 'three/tsl';

const STRIDE = 20;
const RIG = ['position', 'normal', 'color', 'aPivot', 'aLimb', 'aMat', 'aJoint', 'aBend', 'aPose', 'aFlop'];

const rotX = (p, a) => { const c = cos(a), s = sin(a); return vec3(p.x, p.y.mul(c).sub(p.z.mul(s)), p.y.mul(s).add(p.z.mul(c))); };
const rotY = (p, a) => { const c = cos(a), s = sin(a); return vec3(p.x.mul(c).add(p.z.mul(s)), p.y, p.z.mul(c).sub(p.x.mul(s))); };
const rotZ = (p, a) => { const c = cos(a), s = sin(a); return vec3(p.x.mul(c).sub(p.y.mul(s)), p.x.mul(s).add(p.y.mul(c)), p.z); };

// The pose of one vertex in model space, shared by the live crowd and the corpse baker.
function skeleton(inst, u) {
  const { phase, move, dead, attack, flinch, seed, rise } = inst;
  const aPivot = attribute('aPivot', 'vec3'), aLimb = attribute('aLimb', 'vec4'), aMat = attribute('aMat', 'vec4');
  const aJoint = attribute('aJoint', 'vec3'), aBend = attribute('aBend', 'vec4'), aPose = attribute('aPose', 'vec4'), aFlop = attribute('aFlop', 'float');

  const fallT = clamp(dead, 0, 1), sink = clamp(dead.sub(1), 0, 1);
  const fall = fallT.mul(fallT).mul(fallT.mul(-2).add(3));
  const alive = fall.oneMinus();
  const rollSide = step(0.5, seed).mul(2).sub(1);
  const reach = smoothstep(0.22, 0.6, seed).mul(alive);

  const wave = phase.add(aLimb.x);
  const swing = sin(wave).mul(move).mul(alive);
  const stride = cos(wave).mul(-0.5).add(0.5);                 // 0 planted, 1 mid swing
  const lowerAng = stride.mul(stride).mul(aBend.y).mul(move).mul(alive).add(aPose.w.mul(fall)).mul(aBend.x);
  const upperAng = aLimb.y.mul(swing).add(aPose.x.mul(attack)).add(aPose.z.mul(reach)).add(aPose.y.mul(fall));
  const sweepAng = aLimb.z.mul(swing);
  const flopAng = aFlop.mul(fall).mul(seed.mul(0.7).add(0.65));   // every body lands a little differently
  const hinge = (p, a) => mix(rotX(p, a), rotZ(p, a), aBend.w);

  const pitchBody = fall.mul(u.fallX).negate();
  const rollBody = fall.mul(u.fallZ).mul(rollSide);

  const pos = Fn(() => {
    const gone = step(aMat.x, 0).mul(step(0.8, seed));          // some are missing a part
    const breathe = sin(time.mul(5).add(seed.mul(40))).mul(aMat.z).mul(attack.mul(2).add(1));
    let p = positionGeometry.add(normalGeometry.mul(breathe));
    p = hinge(p.sub(aJoint), lowerAng).add(aJoint);
    p = rotY(rotZ(hinge(p.sub(aPivot), upperAng), flopAng), sweepAng).add(aPivot);
    p = mix(p, aPivot, gone);
    p = vec3(p.x, p.y.add(max(cos(wave).negate(), 0).mul(aLimb.w).mul(move).mul(alive)), p.z);
    // Upper body: lean into the run, recoil from hits, lunge into attacks. Feet stay planted.
    const upper = smoothstep(u.hip.mul(0.5), u.hip, p.y);
    const lean = u.lean.mul(move).add(u.lunge.mul(attack)).sub(u.flinch.mul(flinch)).mul(upper).mul(alive);
    const roll = sin(phase).mul(u.sway).mul(move).mul(upper).mul(alive);
    p = vec3(p.x, p.y.sub(u.hip), p.z);
    p = rotZ(rotX(p, lean), roll);
    p = vec3(p.x, p.y.add(u.hip).add(abs(cos(phase)).mul(u.bob).mul(move).mul(alive)), p.z);
    // Death: tip over, drop to the ground, flatten a little, then sink into the stain.
    p = rotZ(rotX(p, pitchBody), rollBody);
    const hop = sin(fallT.mul(Math.PI)).mul(u.hop);
    p = vec3(p.x, p.y.mul(fall.mul(u.squash.oneMinus()).oneMinus()).add(fall.mul(u.rest)).add(hop), p.z);
    return vec3(p.x, p.y.sub(sink.mul(u.height)).sub(rise.oneMinus().mul(u.height)), p.z);
  })();

  const nor = Fn(() => {
    let n = hinge(normalGeometry, lowerAng);
    n = rotY(rotZ(hinge(n, upperAng), flopAng), sweepAng);
    return rotZ(rotX(n, pitchBody), rollBody);
  })();
  return { pos, nor, fall };
}

function makeMaterial(u) {
  const iPose = attribute('iPose', 'vec4');   // x y z yaw
  const iAnim = attribute('iAnim', 'vec4');   // phase scale move dead
  const iTint = attribute('iTint', 'vec4');   // rgb flash
  const iFx = attribute('iFx', 'vec4');       // frozen burn poison rise
  const iAct = attribute('iAct', 'vec4');     // attack flinch wounds seed
  const aMat = attribute('aMat', 'vec4');
  const { pos, nor, fall } = skeleton({
    phase: iAnim.x, move: iAnim.z, dead: iAnim.w, attack: iAct.x, flinch: iAct.y, seed: iAct.w, rise: iFx.w,
  }, u);

  const m = new THREE.MeshStandardNodeMaterial();
  m.positionNode = Fn(() => rotY(pos.toVar().mul(iAnim.y), iPose.w).add(iPose.xyz))();

  const nWorld = varying(Fn(() => rotY(nor.toVar(), iPose.w))());
  const nView = normalize(cameraViewMatrix.mul(vec4(nWorld, 0)).xyz);
  m.normalNode = nView;

  // Model-space mottling: breaks up the plastic look on large bodies without any textures.
  const skin = varying(positionGeometry.mul(u.grain));
  const blotch = mx_noise_float(skin).mul(0.5).add(0.5);
  const pores = mx_noise_float(skin.mul(3.7)).mul(0.5).add(0.5);
  const seed = iAct.w, hue = seed.mul(6.283);
  m.colorNode = Fn(() => {
    let c = attribute('color', 'vec3').mul(iTint.rgb).mul(blotch.mul(0.62).add(0.58)).mul(pores.mul(0.42).add(0.76));
    // Clothes differ per instance, so a crowd of one model does not read as clones.
    const dye = vec3(cos(hue), cos(hue.add(2.1)), cos(hue.add(4.2))).mul(0.14).add(0.86);
    c = mix(c, c.mul(dye), aMat.w);
    // The more damage it has taken, the more of it is blood.
    const wounds = iAct.z, bloody = smoothstep(wounds.mul(-0.62).add(0.86), wounds.mul(-0.62).add(0.92), blotch.mul(0.5).add(pores.mul(0.5)).add(0.06));
    c = mix(c, vec3(0.16, 0.008, 0.012), bloody.mul(step(0.01, wounds)).mul(0.9));
    c = mix(c, vec3(0.1, 0.24, 0.42), iFx.x.mul(0.82));
    c = mix(c, vec3(0.1, 0.42, 0.08), iFx.z.mul(0.42));
    return c.mul(iFx.y.mul(-0.55).add(1));
  })();
  m.roughnessNode = mix(abs(aMat.x).add(pores.mul(0.34)).add(blotch.mul(0.16)), float(0.42), iFx.x);
  m.metalnessNode = float(0);
  m.emissiveNode = Fn(() => {
    const rim = pow(saturate(float(1).sub(dot(nView, positionViewDirection))), 3);
    const alive = fall.oneMinus();
    const glow = u.glow.mul(aMat.y).mul(sin(time.mul(4).add(iPose.z)).mul(0.25).add(1)).mul(alive);
    const edge = u.rim.mul(rim).mul(0.07).mul(alive);
    const hit = vec3(iTint.a.mul(0.5), iTint.a.mul(0.26), iTint.a.mul(0.2));
    const ember = vec3(3.0, 0.8, 0.12).mul(iFx.y).mul(smoothstep(0.35, 0.8, sin(positionGeometry.y.mul(19).add(time.mul(9)).add(iPose.x)).mul(0.5).add(0.5)));
    const ice = vec3(0.1, 0.24, 0.42).mul(rim).mul(iFx.x);
    return glow.add(edge).add(hit).add(ember).add(ice);
  })();
  return m;
}

// Corpses are drawn flat into the decal layer, so the ground keeps every kill.
class Baker {
  constructor(base, capacity, u) {
    this.capacity = capacity;
    this.n = 0;
    this.pose = new Float32Array(capacity * 4);
    this.tint = new Float32Array(capacity * 4);
    const g = this.geo = new THREE.InstancedBufferGeometry();
    g.index = base.index;
    for (const k of RIG) g.setAttribute(k, base.getAttribute(k));
    g.setAttribute('iBake', new THREE.InstancedBufferAttribute(this.pose, 4).setUsage(THREE.DynamicDrawUsage));
    g.setAttribute('iBakeTint', new THREE.InstancedBufferAttribute(this.tint, 4).setUsage(THREE.DynamicDrawUsage));
    g.instanceCount = 0;
    const iBake = attribute('iBake', 'vec4'), iT = attribute('iBakeTint', 'vec4');
    const { pos, nor } = skeleton({ phase: float(0), move: float(0), dead: float(1), attack: float(0), flinch: float(0), seed: iT.w, rise: float(1) }, u);
    const m = new THREE.MeshBasicNodeMaterial({ transparent: true, depthTest: false, depthWrite: false, side: THREE.DoubleSide });
    m.blending = THREE.CustomBlending;
    m.blendEquation = THREE.AddEquation;
    m.blendSrc = THREE.OneFactor; m.blendDst = THREE.OneMinusSrcAlphaFactor;
    m.blendSrcAlpha = THREE.OneFactor; m.blendDstAlpha = THREE.OneMinusSrcAlphaFactor;
    m.positionNode = Fn(() => {
      const w = rotY(pos.toVar().mul(iBake.w), iBake.z).toVar();
      return vec3(w.x.add(iBake.x), w.z.add(iBake.y), 0);
    })();
    const shade = varying(nor.y).abs().mul(0.5).add(0.5);
    m.colorNode = vec4(sqrt(attribute('color', 'vec3').mul(iT.rgb).mul(shade).mul(0.5)).mul(0.9), 1);
    m.opacityNode = float(0.9);
    this.mesh = new THREE.Mesh(g, m);
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = 1;
  }
  add(x, z, yaw, scale, r, g, b, seed) {
    if (this.n >= this.capacity) return;
    const i = this.n++;
    this.pose.set([x, z, yaw, scale], i * 4);
    this.tint.set([r, g, b, seed], i * 4);
  }
  prepare() {
    this.geo.instanceCount = this.n;
    if (!this.n) return false;
    this.geo.getAttribute('iBake').needsUpdate = true;
    this.geo.getAttribute('iBakeTint').needsUpdate = true;
    return true;
  }
  finish() { this.n = 0; this.geo.instanceCount = 0; }
}

export class CrowdLayer {
  constructor(stage, decals, base, capacity, opts = {}) {
    this.capacity = capacity;
    this.n = 0;
    this.fallRate = opts.fallRate ?? 2.4;
    this.heavy = !!opts.heavy;
    this.bodyLen = opts.bodyLen ?? 0;
    this.noCorpse = !!opts.noCorpse;
    this.u = {
      bob: uniform(opts.bob ?? 0.04), sway: uniform(opts.sway ?? 0.04), grain: uniform(opts.grain ?? 5),
      hip: uniform(opts.hip ?? 0.8), lean: uniform(opts.lean ?? 0), lunge: uniform(opts.lunge ?? 0), flinch: uniform(opts.flinch ?? 0.3),
      fallX: uniform(opts.fallX ?? 0), fallZ: uniform(opts.fallZ ?? 0), hop: uniform(opts.hop ?? 0),
      rest: uniform(opts.rest ?? 0), squash: uniform(opts.squash ?? 0.8), height: uniform(opts.height ?? 1),
      glow: uniform(new THREE.Color(opts.glow ?? '#ff3a1e').multiplyScalar(opts.glowPower ?? 4)),
      rim: uniform(new THREE.Color(opts.rim ?? '#8fb0d8')),
    };
    this.data = new Float32Array(capacity * STRIDE);
    const g = this.geo = new THREE.InstancedBufferGeometry();
    g.index = base.index;
    for (const k of RIG) g.setAttribute(k, base.getAttribute(k));
    this.buffer = new THREE.InstancedInterleavedBuffer(this.data, STRIDE).setUsage(THREE.DynamicDrawUsage);
    ['iPose', 'iAnim', 'iTint', 'iFx', 'iAct'].forEach((k, i) => g.setAttribute(k, new THREE.InterleavedBufferAttribute(this.buffer, 4, i * 4)));
    g.instanceCount = 0;
    this.mesh = new THREE.Mesh(g, makeMaterial(this.u));
    this.mesh.frustumCulled = false;
    this.mesh.castShadow = stage.tier.shadow > 0;
    stage.scene.add(this.mesh);
    if (decals) {
      this.baker = new Baker(base, 96, this.u);
      decals.addBaker(this.baker);
    }
  }

  begin() { this.n = 0; }

  push(x, y, z, yaw, phase, scale, move, dead, r, g, b, flash, frozen = 0, burn = 0, poison = 0, rise = 1, attack = 0, flinch = 0, wounds = 0, seed = 0.1) {
    if (this.n >= this.capacity) return;
    const i = this.n++ * STRIDE, d = this.data;
    d[i] = x; d[i + 1] = y; d[i + 2] = z; d[i + 3] = yaw;
    d[i + 4] = phase; d[i + 5] = scale; d[i + 6] = move; d[i + 7] = dead;
    d[i + 8] = r; d[i + 9] = g; d[i + 10] = b; d[i + 11] = flash;
    d[i + 12] = frozen; d[i + 13] = burn; d[i + 14] = poison; d[i + 15] = rise;
    d[i + 16] = attack; d[i + 17] = flinch; d[i + 18] = wounds; d[i + 19] = seed;
  }

  end() {
    this.geo.instanceCount = this.n;
    if (this.n) this.buffer.needsUpdate = true;
  }
}
