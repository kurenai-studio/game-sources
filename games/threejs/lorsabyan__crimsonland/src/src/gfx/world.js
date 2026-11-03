// Ground plane, boundary rocks and grass. The ground material samples the decal layer.
import * as THREE from 'three/webgpu';
import {
  texture, uniform, positionWorld, positionGeometry, positionLocal, vec2, vec3, vec4, float, mix, smoothstep, max, min,
  normalize, cameraViewMatrix, time, sin, abs, Fn, cos, instanceIndex, fract,
} from 'three/tsl';
import { ARENA, OUTER } from '../config.js';
import { DECAL_HALF } from './decals.js';
import { BIOMES } from '../data/biomes.js';
import { makeGroundTextures } from './textures.js';
import { Props } from './props.js';
import { mulberry32, TAU } from '../core/util.js';

const TILE = 15;

export class World {
  constructor(stage, decals, tier) {
    this.stage = stage;
    this.decals = decals;
    this.tier = tier;
    this.cache = new Map();
    this.u = {
      lava: uniform(0), bump: uniform(1),
      grassBase: uniform(new THREE.Color()), grassTip: uniform(new THREE.Color()),
      rockA: uniform(new THREE.Color()), rockB: uniform(new THREE.Color()),
    };
    this.buildGround();
    this.buildRocks();
    this.buildGrass();
    this.props = new Props(stage);
  }

  textures(biome) {
    if (!this.cache.has(biome.id)) this.cache.set(biome.id, makeGroundTextures(biome, this.tier.tex, this.stage.renderer));
    return this.cache.get(biome.id);
  }

  buildGround() {
    const first = this.textures(BIOMES.dust);
    const wp = positionWorld.xz;
    const rot = (p, a) => vec2(p.x.mul(Math.cos(a)).sub(p.y.mul(Math.sin(a))), p.x.mul(Math.sin(a)).add(p.y.mul(Math.cos(a))));
    const uvA = wp.div(TILE);
    const uvB = rot(wp, 0.73).div(TILE * 1.37).add(0.31);
    const uvM = rot(wp, 2.1).div(TILE * 5.3);
    const alA = this.tAlbA = texture(first.albedo, uvA);
    const alB = this.tAlbB = texture(first.albedo, uvB);
    const alM = this.tAlbM = texture(first.albedo, uvM);
    const noA = this.tNorA = texture(first.normal, uvA);
    const noB = this.tNorB = texture(first.normal, uvB);

    const rt = this.decals.rt.texture;
    const span = float(DECAL_HALF * 2);
    // Render-target v runs from the top of the image, so world +z (image up) maps to low v.
    const sUv = vec2(positionWorld.x.div(span).add(0.5), float(0.5).sub(positionWorld.z.div(span)));
    const e = 1.6 / this.decals.size;
    const stain = texture(rt, sUv);
    const stainX = texture(rt, sUv.add(vec2(e, 0))).a;
    const stainZ = texture(rt, sUv.sub(vec2(0, e))).a;

    const blend = smoothstep(0.36, 0.62, alM.g).toVar('blend');
    const tone = smoothstep(0.1, 0.8, alM.r).mul(0.5).add(0.72);
    const edgeD = max(abs(positionWorld.x), abs(positionWorld.z));
    const fade = smoothstep(float(ARENA + 2), float(ARENA + 12), edgeD);

    const g = new THREE.MeshStandardNodeMaterial();
    g.colorNode = Fn(() => {
      const base = mix(alA.rgb, alB.rgb, blend).mul(tone);
      const c = base.sqrt().mul(stain.a.oneMinus()).add(stain.rgb);
      return c.mul(c).mul(fade.mul(-0.86).add(1));
    })();
    // Saturated stains are liquid; grey ones (scorch, ash) are dry.
    const hi = max(stain.r, max(stain.g, stain.b)), lo = min(stain.r, min(stain.g, stain.b));
    const wet = smoothstep(0.06, 0.26, hi.sub(lo));
    g.roughnessNode = mix(mix(noA.b, noB.b, blend), float(0.3), wet.mul(0.9));
    g.metalnessNode = float(0);
    const n = mix(noA.xy, noB.xy, blend).mul(2).sub(1).mul(this.u.bump).mul(wet.mul(-0.75).add(1));
    const gx = stainX.sub(stain.a).mul(5), gz = stainZ.sub(stain.a).mul(5);
    const nW = normalize(vec3(n.x.sub(gx), 1, n.y.sub(gz)));
    g.normalNode = normalize(cameraViewMatrix.mul(vec4(nW, 0)).xyz);
    const crack = mix(alA.a, alB.a, blend);
    const pulse = sin(time.mul(1.3).add(positionWorld.x.mul(0.31)).add(positionWorld.z.mul(0.23))).mul(0.3).add(0.8);
    g.emissiveNode = vec3(2.6, 0.62, 0.09).mul(smoothstep(0.3, 0.8, crack)).mul(this.u.lava).mul(pulse).mul(stain.a.oneMinus()).mul(fade.oneMinus());

    const mesh = this.ground = new THREE.Mesh(new THREE.PlaneGeometry(OUTER * 2, OUTER * 2), g);
    mesh.rotation.x = -Math.PI / 2;
    mesh.receiveShadow = true;
    mesh.matrixAutoUpdate = false;
    mesh.updateMatrix();
    this.stage.scene.add(mesh);
  }

  buildRocks() {
    const rng = mulberry32(777);
    const base = new THREE.IcosahedronGeometry(1, 2);
    const p = base.getAttribute('position');
    const v = new THREE.Vector3();
    // Vertices are unshared here, so displace by a hash of the rounded position to keep faces closed.
    const bump = (x, y, z) => { const s = Math.sin(x * 12.9 + y * 78.2 + z * 37.7) * 43758.5; return s - Math.floor(s); };
    for (let i = 0; i < p.count; i++) {
      v.fromBufferAttribute(p, i);
      const k = 0.78 + bump(Math.round(v.x * 40), Math.round(v.y * 40), Math.round(v.z * 40)) * 0.4;
      p.setXYZ(i, v.x * k, v.y * k * 0.8, v.z * k);
    }
    base.computeVertexNormals();
    const m = new THREE.MeshStandardNodeMaterial({ flatShading: true });
    m.colorNode = mix(this.u.rockA, this.u.rockB, smoothstep(-0.5, 0.9, positionGeometry.y)).mul(fract(float(instanceIndex).mul(0.618)).mul(0.5).add(0.75));
    m.roughness = 0.88;
    const count = this.tier.rocks;
    const small = 90;
    const rocks = this.rocks = new THREE.InstancedMesh(base, m, count + small);
    const M = new THREE.Matrix4(), Q = new THREE.Quaternion(), P = new THREE.Vector3(), S = new THREE.Vector3(), E = new THREE.Euler();
    for (let i = 0; i < count + small; i++) {
      let x, z, s;
      if (i < count) {
        // Boundary band: a rough wall with gaps, thicker further out.
        const side = Math.floor(rng() * 4), t = (rng() * 2 - 1) * (OUTER - 1), d = ARENA + 2.6 + rng() * rng() * 13;
        x = side < 2 ? (side ? d : -d) : t;
        z = side < 2 ? t : (side === 2 ? d : -d);
        s = 0.8 + rng() * rng() * 2.8;
      } else {
        x = (rng() * 2 - 1) * (ARENA - 2); z = (rng() * 2 - 1) * (ARENA - 2);
        s = 0.1 + rng() * rng() * 0.38;
      }
      P.set(x, s * 0.1, z);
      Q.setFromEuler(E.set(rng() * 0.6, rng() * TAU, rng() * 0.6));
      S.set(s * (0.8 + rng() * 0.6), s * (0.5 + rng() * 0.5), s * (0.8 + rng() * 0.6));
      rocks.setMatrixAt(i, M.compose(P, Q, S));
    }
    rocks.castShadow = this.tier.shadow > 0;
    rocks.receiveShadow = true;
    rocks.frustumCulled = false;
    this.stage.scene.add(rocks);
  }

  buildGrass() {
    // One tuft is a fan of bent blades whose normals point up, so it lights like the ground beneath.
    const blades = 6, pos = [], idx = [], nor = [];
    const rng = mulberry32(31337);
    for (let b = 0; b < blades; b++) {
      const a = rng() * TAU, l = 0.2 + rng() * 0.35, h = 0.55 + rng() * 0.45, w = 0.045;
      const dx = Math.cos(a), dz = Math.sin(a), sx = -dz * w, sz = dx * w;
      const n0 = pos.length / 3;
      for (let s = 0; s < 3; s++) {
        const t = s / 2, r = (1 - t * 0.5), bend = t * t * l;
        pos.push(dx * bend - sx * r, h * t, dz * bend - sz * r, dx * bend + sx * r, h * t, dz * bend + sz * r);
        nor.push(0, 1, 0, 0, 1, 0);
      }
      pos.push(dx * l * 1.4, h * 1.2, dz * l * 1.4); nor.push(0, 1, 0);
      idx.push(n0, n0 + 1, n0 + 2, n0 + 1, n0 + 3, n0 + 2, n0 + 2, n0 + 3, n0 + 4, n0 + 3, n0 + 5, n0 + 4, n0 + 4, n0 + 5, n0 + 6);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    g.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
    g.setIndex(idx);
    const m = new THREE.MeshStandardNodeMaterial({ side: THREE.DoubleSide });
    const hNorm = positionGeometry.y.div(1.2);
    m.colorNode = mix(this.u.grassBase, this.u.grassTip, hNorm.mul(hNorm));
    m.roughness = 0.82;
    m.positionNode = Fn(() => {
      const p = positionLocal;
      const w = sin(time.mul(1.7).add(p.x.mul(0.37)).add(p.z.mul(0.29))).mul(0.5).add(cos(time.mul(3.1).add(p.x))).mul(0.11);
      return vec3(p.x.add(w.mul(hNorm.mul(hNorm))), p.y, p.z.add(w.mul(0.6).mul(hNorm.mul(hNorm))));
    })();
    const count = this.tier.grass;
    const mesh = this.grass = new THREE.InstancedMesh(g, m, count);
    const rng2 = mulberry32(99);
    const M = new THREE.Matrix4(), Q = new THREE.Quaternion(), P = new THREE.Vector3(), S = new THREE.Vector3(), Y = new THREE.Vector3(0, 1, 0);
    let i = 0;
    while (i < count) {
      // Clumps: pick a centre, drop a few tufts around it.
      const cx = (rng2() * 2 - 1) * (ARENA + 8), cz = (rng2() * 2 - 1) * (ARENA + 8);
      const n = 2 + Math.floor(rng2() * 5);
      for (let k = 0; k < n && i < count; k++, i++) {
        const s = 0.45 + rng2() * 0.85;
        P.set(cx + (rng2() - 0.5) * 2.2, 0, cz + (rng2() - 0.5) * 2.2);
        Q.setFromAxisAngle(Y, rng2() * TAU);
        S.set(s, s, s);
        mesh.setMatrixAt(i, M.compose(P, Q, S));
      }
    }
    mesh.frustumCulled = false;
    this.stage.scene.add(mesh);
  }

  setBiome(biome) {
    const t = this.textures(biome);
    this.tAlbA.value = t.albedo; this.tAlbB.value = t.albedo; this.tAlbM.value = t.albedo;
    this.tNorA.value = t.normal; this.tNorB.value = t.normal;
    this.u.lava.value = biome.lava;
    this.u.grassBase.value.set(biome.grass.base);
    this.u.grassTip.value.set(biome.grass.tip);
    this.u.rockA.value.set(biome.rock.a);
    this.u.rockB.value.set(biome.rock.b);
    this.props.setBiome(biome);
    this.stage.applyBiome(biome);
  }
}
