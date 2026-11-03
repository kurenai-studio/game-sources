/**
 * Lightning you can actually see.
 *
 * The storm used to be a light that blinked. Now every strike is a real bolt:
 * a stepped leader grown by recursive midpoint displacement, with forked
 * branches that thin and die before reaching the ground, rendered as
 * camera-facing ribbons in HDR so bloom does the glow.
 *
 * Two flavours:
 *   storm     — cloud-to-ground, from the cloud deck to a terrain point. If it
 *               lands in the forest it starts a wildfire.
 *   volcanic  — "dirty thunderstorm" discharges crawling through the eruption
 *               column. Ash particles colliding in the plume charge up exactly
 *               like a thundercloud; real eruptions do this, and it is the
 *               single most apocalyptic image a volcano produces.
 *
 * Rendering: each bolt is one BufferGeometry of quads (4 verts per segment),
 * expanded in view space in the vertex shader so the ribbon is always
 * face-on. Two draws per bolt share that geometry: a thin white-hot core and a
 * wide, faint corona.
 */
import * as THREE from 'three';
import { gsap } from 'gsap';
import { bus, EV } from '../core/EventBus.js';
import { height, canPlant, WORLD } from '../world/Heightfield.js';

const MAX_SEG = 520;
const POOL = 6;

const VS = /* glsl */`
  attribute vec3 aOther;
  attribute float aSide;
  attribute float aWidth;
  attribute float aBright;
  uniform float uWidthMul;
  varying float vSide;
  varying float vBright;
  void main(){
    vSide = aSide;
    vBright = aBright;
    vec4 a = modelViewMatrix * vec4(position, 1.0);
    vec4 b = modelViewMatrix * vec4(aOther, 1.0);
    vec3 d = normalize(b.xyz - a.xyz + 1e-5);
    vec3 n = normalize(cross(d, normalize(-a.xyz)));
    // Keep a minimum on-screen width so distant bolts don't alias to nothing.
    float w = max(aWidth * uWidthMul, -a.z * 0.0018 * uWidthMul);
    a.xyz += n * aSide * w;
    gl_Position = projectionMatrix * a;
  }`;

const FS = /* glsl */`
  uniform vec3 uColor;
  uniform float uIntensity;
  uniform float uFalloff;
  varying float vSide;
  varying float vBright;
  void main(){
    float k = exp(-vSide * vSide * uFalloff);
    gl_FragColor = vec4(uColor * k * vBright * uIntensity, 1.0);
  }`;

export class Lightning {
  constructor({ lights } = {}) {
    this.group = new THREE.Group();
    this.group.name = 'Lightning';
    this.strikeLight = lights?.strike ?? null;
    this.pool = [];
    for (let i = 0; i < POOL; i++) this.pool.push(this._makeBolt());

    this.volcanic = 0;        // 0..1 rate of plume discharges, set by Eruption
    this._volcT = 0;
    this._vent = new THREE.Vector3();

    this._unsub = bus.on(EV.LIGHTNING, (e) => {
      if (e?.to) this.strike(e.from, e.to, { volcanic: !!e.volcanic });
    });
  }

  _makeBolt() {
    const n = MAX_SEG * 4;
    const geo = new THREE.BufferGeometry();
    const attr = (k, size) => {
      const a = new THREE.BufferAttribute(new Float32Array(n * size), size);
      a.setUsage(THREE.DynamicDrawUsage);
      geo.setAttribute(k, a);
      return a;
    };
    const A = {
      position: attr('position', 3),
      aOther: attr('aOther', 3),
      aSide: attr('aSide', 1),
      aWidth: attr('aWidth', 1),
      aBright: attr('aBright', 1),
    };
    const idx = new Uint16Array(MAX_SEG * 6);
    for (let s = 0; s < MAX_SEG; s++) {
      const v = s * 4;
      idx.set([v, v + 1, v + 2, v + 2, v + 1, v + 3], s * 6);
    }
    geo.setIndex(new THREE.BufferAttribute(idx, 1));
    geo.setDrawRange(0, 0);

    const mk = (widthMul, falloff, intensity) => new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color(0.75, 0.85, 1.0) },
        uIntensity: { value: 0 },
        uWidthMul: { value: widthMul },
        uFalloff: { value: falloff },
      },
      vertexShader: VS, fragmentShader: FS,
      // MAX, not additive: adjacent segment quads overlap at every joint, and
      // additive blending doubled the brightness there — the bolt rendered as
      // a ladder of bright rungs. Max blending makes the overlap invisible.
      transparent: true, depthWrite: false,
      blending: THREE.CustomBlending, blendEquation: THREE.MaxEquation,
      blendSrc: THREE.OneFactor, blendDst: THREE.OneFactor,
      side: THREE.DoubleSide,
      userData: { base: intensity },
    });
    const core = new THREE.Mesh(geo, mk(1, 2.2, 9.0));
    const corona = new THREE.Mesh(geo, mk(5, 1.6, 0.9));
    for (const m of [core, corona]) {
      m.frustumCulled = false;
      m.visible = false;
      m.renderOrder = 9;
      this.group.add(m);
    }
    return { geo, A, core, corona, age: 1e9, life: 0, seed: 0, busy: false };
  }

  /* ── bolt shape ───────────────────────────────────────────────────── */

  /**
   * Midpoint displacement: split each segment, kick the midpoint sideways by an
   * amount proportional to its length, recurse. Branches leave at a random
   * midpoint heading roughly the way the parent was going, and are shorter,
   * thinner and dimmer.
   */
  _grow(from, to, { width, bright, depth, out, branchChance }) {
    let pts = [from.clone(), to.clone()];
    const len = from.distanceTo(to);
    let disp = len * 0.22;
    for (let d = 0; d < depth; d++) {
      const next = [pts[0]];
      for (let i = 0; i < pts.length - 1; i++) {
        const a = pts[i], b = pts[i + 1];
        const m = a.clone().lerp(b, 0.42 + Math.random() * 0.16);
        m.x += (Math.random() - 0.5) * disp;
        m.y += (Math.random() - 0.5) * disp * 0.2;
        m.z += (Math.random() - 0.5) * disp;
        next.push(m, b);
      }
      pts = next;
      // Decay slower than ½ so the fine levels keep real zig-zag, not wobble.
      disp *= 0.6;
    }

    for (let i = 0; i < pts.length - 1; i++) {
      // Taper toward the tip so branches end in a hair, not a stub.
      const t = i / (pts.length - 1);
      out.push({ a: pts[i], b: pts[i + 1], w: width * (1 - t * 0.6), br: bright * (1 - t * 0.35) });
    }

    if (depth >= 5) {
      for (let i = 2; i < pts.length - 3; i++) {
        if (Math.random() > branchChance) continue;
        const a = pts[i];
        const dir = pts[i + 1].clone().sub(pts[i - 1]).normalize();
        dir.x += (Math.random() - 0.5) * 1.4;
        dir.z += (Math.random() - 0.5) * 1.4;
        dir.y = Math.min(dir.y, -0.15) - Math.random() * 0.3;
        dir.normalize();
        const bl = len * (0.12 + Math.random() * 0.22) * (1 - i / pts.length);
        this._grow(a, a.clone().addScaledVector(dir, bl), {
          width: width * 0.45, bright: bright * 0.55, depth: depth - 2, out, branchChance: branchChance * 0.5,
        });
      }
    }
    return out;
  }

  _writeBolt(bolt, segs) {
    const { A } = bolt;
    const n = Math.min(segs.length, MAX_SEG);
    for (let s = 0; s < n; s++) {
      const { a, b, w, br } = segs[s];
      for (let k = 0; k < 4; k++) {
        const v = s * 4 + k;
        const self = k < 2 ? a : b, other = k < 2 ? b : a;
        // The far end's "other" points backward, so flip its side to keep winding.
        const side = (k % 2 === 0 ? 1 : -1) * (k < 2 ? 1 : -1);
        A.position.setXYZ(v, self.x, self.y, self.z);
        A.aOther.setXYZ(v, other.x, other.y, other.z);
        A.aSide.setX(v, side);
        A.aWidth.setX(v, w);
        A.aBright.setX(v, br);
      }
    }
    for (const k in A) A[k].needsUpdate = true;
    bolt.geo.setDrawRange(0, n * 6);
  }

  /* ── api ──────────────────────────────────────────────────────────── */

  /** Fire a bolt from `from` to `to` (world space). */
  strike(from, to, { volcanic = false, ignite = !volcanic } = {}) {
    const bolt = this.pool.find((b) => !b.busy) ?? this.pool.reduce((a, b) => (a.age > b.age ? a : b));
    const segs = this._grow(from, to, {
      width: volcanic ? 1.3 : 2.4, bright: 1, depth: volcanic ? 6 : 7, out: [],
      branchChance: volcanic ? 0.26 : 0.075,
    });
    this._writeBolt(bolt, segs);
    bolt.busy = true;
    bolt.age = 0;
    bolt.life = volcanic ? 0.32 + Math.random() * 0.25 : 0.55 + Math.random() * 0.3;
    bolt.seed = Math.random() * 100;
    const col = volcanic ? new THREE.Color(0.9, 0.72, 1.0) : new THREE.Color(0.72, 0.84, 1.0);
    for (const m of [bolt.core, bolt.corona]) {
      m.material.uniforms.uColor.value.copy(col);
      m.visible = true;
    }

    // Light the world from the strike.
    if (this.strikeLight) {
      const L = this.strikeLight;
      L.position.copy(from).lerp(to, 0.3);
      const peak = volcanic ? 4 + Math.random() * 4 : 8 + Math.random() * 10;
      gsap.killTweensOf(L);
      gsap.timeline()
        .to(L, { intensity: peak, duration: 0.03, ease: 'none' })
        .to(L, { intensity: peak * 0.2, duration: 0.06 })
        .to(L, { intensity: peak * 0.8, duration: 0.03 })
        .to(L, { intensity: 0, duration: 0.45, ease: 'power2.out' });
    }

    bus.emit(EV.STRIKE, { from: from.clone(), to: to.clone(), volcanic });
    if (!volcanic) {
      bus.emit(EV.FLASH, { intensity: 0.3, duration: 0.3, color: '#dce8ff' });
      if (ignite && canPlant(to.x, to.z)) {
        bus.emit(EV.IGNITE, { pos: to.clone(), radius: 18, strength: 0.8 });
      }
    }
    return bolt;
  }

  /** A cloud-to-ground strike somewhere near `around` (defaults to the map). */
  stormStrike(around = null, spread = 900) {
    const cx = around?.x ?? 0, cz = around?.z ?? 150;
    const x = cx + (Math.random() - 0.5) * spread * 2;
    const z = cz + (Math.random() - 0.5) * spread * 2;
    const to = new THREE.Vector3(x, height(x, z), z);
    const from = new THREE.Vector3(x + (Math.random() - 0.5) * 300, 820 + Math.random() * 160, z + (Math.random() - 0.5) * 300);
    return this.strike(from, to);
  }

  /** Set the eruption plume discharge rate (0 = off). */
  setVolcanic(rate, vent) {
    this.volcanic = rate;
    if (vent) this._vent.copy(vent);
  }

  _volcanicBolt() {
    const V = this._vent;
    // Discharges live in the lower-middle of the column, where the ash is
    // densest, and mostly run sideways and down through it.
    const r = () => (Math.random() - 0.5);
    const top = new THREE.Vector3(V.x + r() * 160, V.y + 140 + Math.random() * 260, V.z + r() * 160);
    const toGround = Math.random() < 0.3;
    let end;
    if (toGround) {
      const a = Math.random() * Math.PI * 2, d = WORLD.volcano.craterR * (1 + Math.random() * 2.5);
      const x = V.x + Math.cos(a) * d, z = V.z + Math.sin(a) * d;
      end = new THREE.Vector3(x, height(x, z), z);
    } else {
      end = top.clone().add(new THREE.Vector3(r() * 260, -60 - Math.random() * 140, r() * 260));
    }
    this.strike(top, end, { volcanic: true });
  }

  /* ── frame ────────────────────────────────────────────────────────── */

  update(dt) {
    // Volcanic discharges come in bursts: Poisson with a jittered rate.
    if (this.volcanic > 0.01) {
      this._volcT -= dt;
      if (this._volcT <= 0) {
        this._volcanicBolt();
        if (Math.random() < 0.35) this._volcanicBolt();
        this._volcT = (0.12 + Math.random() * 0.9) / this.volcanic;
      }
    }

    for (const b of this.pool) {
      if (!b.busy) continue;
      b.age += dt;
      const t = b.age / b.life;
      if (t >= 1) {
        b.busy = false;
        b.core.visible = b.corona.visible = false;
        continue;
      }
      // Return strokes: the channel re-brightens two or three times as it decays.
      const stutter = 0.55 + 0.45 * Math.abs(Math.sin(b.age * 38 + b.seed)) ;
      const env = (1 - t) * (1 - t) * stutter * (b.age < 0.03 ? b.age / 0.03 : 1);
      for (const m of [b.core, b.corona]) {
        m.material.uniforms.uIntensity.value = m.material.userData.base * env;
      }
    }
  }

  dispose() {
    this._unsub?.();
    for (const b of this.pool) { b.geo.dispose(); b.core.material.dispose(); b.corona.material.dispose(); }
  }
}
