/**
 * Emberhold — the village on the plateau between the lake and the river.
 *
 * Layout is grown, not gridded: a plaza with a well, three lanes radiating out,
 * cottages set back from the lanes with their gables turned to the wind. Houses
 * are drawn from four merged variants and instanced.
 *
 * The village is where the lighting story pays off: every window is an emissive
 * quad with its own flicker phase, so at night the settlement reads as *lived
 * in*, and when the dragon breathes fire the whole cluster gets rim-lit by the
 * shared fire light in injectAmbient().
 */
import * as THREE from 'three';
import { makeRng, noise } from '../utils/Noise.js';
import { TAU, clamp, hash11 } from '../utils/MathX.js';
import { WORLD, height, canBuild, isOnLava, isOnWater } from '../world/Heightfield.js';
import { buildRibbon } from '../world/Ribbon.js';
import { box, roofPrism, blockWall, meshFrom, mergeSafe } from './Blocks.js';
import { G } from '../materials/GlobalUniforms.js';

/* ── one cottage ──────────────────────────────────────────────────────── */

function buildCottage(rng, detail = 1) {
  const w = 6 + rng() * 4;
  const d = 5 + rng() * 3.5;
  const h = 4 + rng() * 2.2;
  const storeys = rng() > 0.72 ? 2 : 1;
  const H = h * storeys;

  const plaster = [];
  const timber = [];
  const foundation = [];
  const doors = [];
  const roofParts = [];
  const windows = [];

  // Walls (four slabs, inset so the corner posts read).
  plaster.push(box(w, H, d, 0, H / 2, 0));
  // Dressed-stone plinth and a raised splash course ground the house and make
  // the wall read as a real structure rather than a floating plaster cube.
  foundation.push(box(w + 0.44, 0.88, d + 0.44, 0, 0.44, 0));
  foundation.push(box(w + 0.18, 0.22, d + 0.18, 0, 0.95, 0));

  // Half-timbering: corner posts, sill, top plate, braces.
  const t = 0.34;
  for (const sx of [-1, 1]) {
    for (const sz of [-1, 1]) {
      timber.push(box(t * 1.6, H, t * 1.6, sx * (w / 2 - t), H / 2, sz * (d / 2 - t)));
    }
  }
  timber.push(box(w + 0.1, t, t, 0, 0.2, d / 2));
  timber.push(box(w + 0.1, t, t, 0, 0.2, -d / 2));
  timber.push(box(w + 0.1, t, t, 0, H - 0.2, d / 2));
  timber.push(box(w + 0.1, t, t, 0, H - 0.2, -d / 2));
  // Floor girts and regular studs make this an actual timber frame instead of
  // a handful of decorative beams.
  for (const y of (storeys === 2 ? [h, H - 0.2] : [H - 0.2])) {
    timber.push(box(w + 0.2, t, t, 0, y, d / 2 + 0.02));
    timber.push(box(w + 0.2, t, t, 0, y, -d / 2 - 0.02));
  }
  for (let i = -1; i <= 1; i++) {
    const x = i * w * 0.27;
    timber.push(box(t, H - 0.7, t, x, H * 0.5, d / 2 + 0.03));
    timber.push(box(t, H - 0.7, t, x, H * 0.5, -d / 2 - 0.03));
  }
  if (storeys === 2) {
    // Jettied upper floor — the single most "medieval" silhouette cue.
    plaster.push(box(w + 1.1, h * 0.92, d + 1.1, 0, h + h * 0.46, 0));
    timber.push(box(w + 1.3, t, t, 0, h, d / 2 + 0.55));
    timber.push(box(w + 1.3, t, t, 0, h, -d / 2 - 0.55));
    for (let i = -1; i <= 1; i++) {
      const br = box(t, 1.6, t, i * (w / 3), h - 0.6, d / 2 + 0.3);
      br.rotateX(0.5);
      timber.push(br);
    }
  }
  if (detail) {
    for (let i = 0; i < 3; i++) {
      const br = box(t, 2.6, t, (rng() - 0.5) * w * 0.7, H * 0.4, d / 2 + 0.02);
      br.rotateZ((rng() > 0.5 ? 1 : -1) * 0.6);
      timber.push(br);
    }
  }

  // Roof.
  const roofH = 3 + rng() * 2;
  const top = storeys === 2 ? h * 1.92 : H;
  const roof = roofPrism(storeys === 2 ? w + 1.1 : w, storeys === 2 ? d + 1.1 : d, roofH, { overhang: 0.75 });
  roof.translate(0, top, 0);
  roofParts.push(roof);
  // Ridge cap and eave boards give the roof thickness and a proper shadow line.
  const roofW = storeys === 2 ? w + 1.1 : w;
  const roofD = storeys === 2 ? d + 1.1 : d;
  timber.push(box(roofW + 1.55, 0.24, 0.36, 0, top + roofH + 0.03, 0));
  for (const s of [-1, 1]) {
    timber.push(box(roofW + 1.5, 0.22, 0.28, 0, top + 0.16, s * (roofD / 2 + 0.72)));
  }

  // Chimney.
  const cx = (rng() - 0.5) * w * 0.5;
  const cz = (rng() - 0.5) * d * 0.4;
  const chimH = roofH + 3.4;
  const chim = box(1.5, chimH, 1.5, cx, top + chimH / 2 - 0.6, cz);
  const chimCap = box(1.9, 0.25, 1.9, cx, top + chimH - 0.48, cz);
  const chimTop = { x: cx, y: top + roofH + 3.0, z: cz };

  // Windows & door (emissive quads, slightly inset).
  const winCount = 1 + Math.floor(rng() * 2) + storeys;
  for (let i = 0; i < winCount; i++) {
    const face = Math.floor(rng() * 4);
    const wy = storeys === 2 && i % 2 ? h + h * 0.5 : H * 0.5;
    const ww = 0.9 + rng() * 0.5, wh = 1.1 + rng() * 0.5;
    const along = (rng() - 0.5) * (face < 2 ? w : d) * 0.50;
    const rot = [0, Math.PI, Math.PI / 2, -Math.PI / 2][face];
    const bx = face < 2 ? 0 : (face === 2 ? w / 2 : -w / 2);
    const bz = face < 2 ? (face === 0 ? d / 2 : -d / 2) : 0;
    const place = (part) => {
      part.rotateY(rot);
      part.translate(bx, wy, bz);
      return part;
    };
    const g = new THREE.PlaneGeometry(ww, wh);
    g.translate(along, 0, 0.13);
    windows.push(place(g));

    // Recessed casement frames and shutters turn the emissive plane into a
    // genuine opening while preserving the instanced-village performance.
    for (const sx of [-1, 1]) timber.push(place(box(0.14, wh + 0.30, 0.18, along + sx * (ww / 2 + 0.05), 0, 0.18)));
    for (const sy of [-1, 1]) timber.push(place(box(ww + 0.28, 0.14, 0.18, along, sy * (wh / 2 + 0.05), 0.18)));
    timber.push(place(box(0.10, wh, 0.16, along, 0, 0.21)));
    if (rng() > 0.42) {
      for (const sx of [-1, 1]) doors.push(place(box(ww * 0.42, wh * 0.84, 0.10, along + sx * ww * 0.48, 0, 0.27)));
    }
  }

  // One proper entrance, proud of the wall with lintel and stone threshold.
  const doorX = (rng() - 0.5) * w * 0.36;
  doors.push(box(1.55, 2.45, 0.18, doorX, 1.225, d / 2 + 0.14));
  timber.push(box(1.85, 0.18, 0.24, doorX, 2.54, d / 2 + 0.18));
  foundation.push(box(2.45, 0.32, 1.25, doorX, 0.16, d / 2 + 0.62));

  // three drives per-instance tint through vColor, which needs BOTH
  // vertexColors on the material and a base colour attribute on the geometry —
  // instanceColor alone multiplies against nothing.
  const winGeo = mergeSafe(windows);
  if (winGeo) {
    const n = winGeo.attributes.position.count;
    winGeo.setAttribute('color', new THREE.BufferAttribute(new Float32Array(n * 3).fill(1), 3));
  }

  return {
    plaster: mergeSafe(plaster),
    foundation: mergeSafe(foundation),
    timber: mergeSafe(timber),
    roof: mergeSafe(roofParts),
    chimney: mergeSafe([chim, chimCap]),
    doors: mergeSafe(doors),
    windows: winGeo,
    chimTop, w, d, H: H + roofH,
  };
}

/* ── the village ──────────────────────────────────────────────────────── */

export class Village {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Village';
    const rng = makeRng(90210);
    const V = WORLD.village;

    this.plaza = new THREE.Vector3(V.x, height(V.x, V.z), V.z);

    // ── plots: three lanes fanning off the plaza ────────────────────
    const plots = [];
    const lanes = [0.4, 2.1, 4.0];
    for (const laneA of lanes) {
      const len = 105 + rng() * 45;
      for (let s = 12; s < len; s += 13 + rng() * 9) {
        for (const side of [-1, 1]) {
          if (rng() < 0.22) continue;
          const off = (7.5 + rng() * 5) * side;
          const x = V.x + Math.cos(laneA) * s + Math.cos(laneA + Math.PI / 2) * off;
          const z = V.z + Math.sin(laneA) * s + Math.sin(laneA + Math.PI / 2) * off;
          if (!canBuild(x, z)) continue;
          plots.push({ x, z, ry: laneA + Math.PI / 2 + (rng() - 0.5) * 0.35 });
        }
      }
    }
    // A few outliers on the fringe.
    for (let i = 0; i < 5; i++) {
      const a = rng() * TAU, r = 120 + rng() * 60;
      const x = V.x + Math.cos(a) * r, z = V.z + Math.sin(a) * r;
      if (canBuild(x, z)) plots.push({ x, z, ry: rng() * TAU });
    }

    // ── instance the variants ───────────────────────────────────────
    const VARIANTS = 4;
    const lib = [];
    for (let i = 0; i < VARIANTS; i++) lib.push(buildCottage(rng, settings.houseDetail));

    const buckets = lib.map(() => []);
    for (const p of plots) buckets[Math.floor(rng() * VARIANTS)].push(p);

    this.chimneys = [];
    this.windowMeshes = [];

    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const pos = new THREE.Vector3();
    const scl = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);

    const winMat = new THREE.MeshBasicMaterial({
      color: 0xffb54d, toneMapped: false, side: THREE.DoubleSide, vertexColors: true,
    });
    this.windowMaterial = winMat;

    lib.forEach((variant, vi) => {
      const list = buckets[vi];
      if (!list.length) return;
      const mk = (geo, mat, cast = true) => {
        if (!geo) return null;
        const inst = new THREE.InstancedMesh(geo, mat, list.length);
        inst.castShadow = cast;
        inst.receiveShadow = true;
        return inst;
      };
      const iPlaster = mk(variant.plaster, materials.get('plaster'));
      const iFoundation = mk(variant.foundation, materials.get('stoneDark'));
      const iTimber = mk(variant.timber, materials.get('wood'));
      const iRoof = mk(variant.roof, vi % 2 ? materials.get('thatch') : materials.get('tile'));
      const iChim = mk(variant.chimney, materials.get('stoneDark'));
      const iDoor = mk(variant.doors, materials.get('woodDark'));
      const iWin = mk(variant.windows, winMat, false);
      if (iWin) {
        iWin.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(list.length * 3), 3);
        this.windowMeshes.push({ mesh: iWin, count: list.length, seed: vi * 13 });
      }

      for (let i = 0; i < list.length; i++) {
        const p = list[i];
        const y = height(p.x, p.z) - 0.35;
        const s = 0.9 + rng() * 0.35;
        pos.set(p.x, y, p.z);
        q.setFromAxisAngle(up, p.ry);
        scl.set(s, s * (0.94 + rng() * 0.2), s);
        m.compose(pos, q, scl);
        for (const inst of [iPlaster, iFoundation, iTimber, iRoof, iChim, iDoor, iWin]) inst?.setMatrixAt(i, m);

        // Register the chimney mouth for smoke.
        const c = new THREE.Vector3(variant.chimTop.x, variant.chimTop.y, variant.chimTop.z)
          .multiplyScalar(s).applyAxisAngle(up, p.ry).add(pos);
        this.chimneys.push(c);
      }
      for (const inst of [iPlaster, iFoundation, iTimber, iRoof, iChim, iDoor, iWin]) if (inst) this.group.add(inst);
    });

    this.houseCount = plots.length;
    this.plots = plots;

    // ── plaza furniture ─────────────────────────────────────────────
    this.group.add(this._buildWell(materials, rng));
    this.group.add(this._buildStalls(materials, rng));
    this.group.add(this._buildFences(materials, rng));
    this.group.add(this._buildRoads(materials, rng, lanes));
    this._buildHearthSmoke(materials, settings);
  }

  _buildWell(materials, rng) {
    const g = new THREE.Group();
    g.name = 'Well';
    const V = WORLD.village;
    const y = height(V.x, V.z);
    const parts = [];
    const ring = new THREE.CylinderGeometry(2.2, 2.4, 1.6, 16, 1, true);
    ring.translate(0, 0.8, 0);
    parts.push(ring);
    parts.push(box(6.4, 0.5, 6.4, 0, 0.15, 0));
    const stone = meshFrom(parts, materials.get('stone'), { name: 'WellStone' });
    const posts = [];
    for (const s of [-1, 1]) posts.push(box(0.3, 4.4, 0.3, s * 1.9, 2.2, 0));
    posts.push(box(0.3, 0.3, 5, 0, 4.3, 0, Math.PI / 2));
    const roof = roofPrism(5.4, 3.4, 1.5, { overhang: 0.4 });
    roof.translate(0, 4.4, 0);
    const wood = meshFrom([...posts, roof], materials.get('woodDark'), { name: 'WellTimber' });
    if (stone) g.add(stone);
    if (wood) g.add(wood);
    g.position.set(V.x, y, V.z);
    return g;
  }

  _buildStalls(materials, rng) {
    const g = new THREE.Group();
    g.name = 'MarketStalls';
    const V = WORLD.village;
    const cloth = materials.get('cloth');
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU + 0.6;
      const r = 16 + rng() * 12;
      const x = V.x + Math.cos(a) * r, z = V.z + Math.sin(a) * r;
      const y = height(x, z);
      const posts = [];
      const w = 4 + rng() * 2, d = 2.6 + rng();
      for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
        posts.push(box(0.2, 3.2, 0.2, sx * w / 2, 1.6, sz * d / 2));
      }
      posts.push(box(w, 0.28, d, 0, 1.1, 0));
      const wood = meshFrom(posts, materials.get('woodDark'), { name: `Stall${i}` });
      // Awning gets the wind shader for free (cloth material).
      const awn = new THREE.Mesh(new THREE.PlaneGeometry(w + 0.8, d + 1.4, 6, 4), cloth);
      awn.rotation.x = -Math.PI / 2 + 0.18;
      awn.position.y = 3.3;
      awn.castShadow = true;
      const s = new THREE.Group();
      if (wood) s.add(wood);
      s.add(awn);
      s.position.set(x, y, z);
      s.rotation.y = a;
      g.add(s);
    }
    return g;
  }

  _buildFences(materials, rng) {
    const parts = [];
    const V = WORLD.village;
    for (let f = 0; f < 9; f++) {
      const a = rng() * TAU;
      const r = 40 + rng() * 90;
      let x = V.x + Math.cos(a) * r, z = V.z + Math.sin(a) * r;
      const dir = rng() * TAU;
      const n = 6 + Math.floor(rng() * 10);
      for (let i = 0; i < n; i++) {
        x += Math.cos(dir) * 2.4;
        z += Math.sin(dir) * 2.4;
        if (isOnLava(x, z) || isOnWater(x, z)) break;
        const y = height(x, z);
        const post = box(0.18, 1.5, 0.18, x, y + 0.75, z);
        parts.push(post);
        if (i > 0) {
          for (const hy of [0.55, 1.15]) {
            const rail = box(2.5, 0.12, 0.1, x - Math.cos(dir) * 1.2, y + hy, z - Math.sin(dir) * 1.2, -dir);
            parts.push(rail);
          }
        }
      }
    }
    return meshFrom(parts, materials.get('woodDark'), { name: 'Fences' }) ?? new THREE.Group();
  }

  /** Beaten-earth lanes, draped on the terrain. */
  _buildRoads(materials, rng, lanes) {
    const g = new THREE.Group();
    g.name = 'Lanes';
    const V = WORLD.village;
    const mat = materials.get('dirt').clone();
    mat.onBeforeCompile = materials.get('dirt').onBeforeCompile;
    mat.customProgramCacheKey = materials.get('dirt').customProgramCacheKey;
    mat.polygonOffset = true;
    mat.polygonOffsetFactor = -2;
    mat.polygonOffsetUnits = -2;

    for (const a of lanes) {
      const pts = [];
      for (let s = 0; s < 150; s += 15) {
        const wob = noise.simplex2(s * 0.02, a * 10) * 9;
        pts.push([
          V.x + Math.cos(a) * s + Math.cos(a + Math.PI / 2) * wob,
          V.z + Math.sin(a) * s + Math.sin(a + Math.PI / 2) * wob,
        ]);
      }
      const geo = buildRibbon(pts, {
        width: 4.2, widthJitter: 0.3, yOffset: 0.14,
        segmentsPerUnit: 1 / 4, uvScale: 0.25, taperEnds: false,
      });
      const mesh = new THREE.Mesh(geo, mat);
      mesh.receiveShadow = true;
      g.add(mesh);
    }
    // The road out to the castle bridge.
    const toCastle = [];
    for (let t = 0; t <= 1.001; t += 0.1) {
      const x = V.x + (-40 - V.x) * t;
      const z = V.z + (300 - V.z) * t;
      toCastle.push([x + Math.sin(t * 6) * 12, z + Math.cos(t * 5) * 8]);
    }
    const road = new THREE.Mesh(buildRibbon(toCastle, {
      width: 5.5, yOffset: 0.14, segmentsPerUnit: 1 / 5, uvScale: 0.25, taperEnds: false,
    }), mat);
    road.receiveShadow = true;
    g.add(road);
    return g;
  }

  /** Thin hearth smoke from every chimney — one Points cloud for all of them. */
  _buildHearthSmoke(materials, settings) {
    const per = 4;
    const count = Math.min(this.chimneys.length, 40) * per;
    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(count * 3);
    const seed = new Float32Array(count);
    const base = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const c = this.chimneys[Math.floor(i / per) % this.chimneys.length];
      base[i * 3] = c.x; base[i * 3 + 1] = c.y; base[i * 3 + 2] = c.z;
      pos[i * 3] = c.x; pos[i * 3 + 1] = c.y; pos[i * 3 + 2] = c.z;
      seed[i] = Math.random();
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aBase', new THREE.BufferAttribute(base, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1));

    const mat = new THREE.ShaderMaterial({
      transparent: true, depthWrite: false,
      uniforms: {
        uTime: G.uTime, uWindDir: G.uWindDir, uWindStrength: G.uWindStrength,
        uSprite: { value: materials.T.smoke },
      },
      vertexShader: /* glsl */`
        attribute vec3 aBase;
        attribute float aSeed;
        varying float vFade;
        uniform float uTime, uWindStrength;
        uniform vec2 uWindDir;
        void main(){
          float life = 7.0 + aSeed * 5.0;
          float age = fract((uTime + aSeed * 31.0) / life);
          vec3 p = aBase;
          p.y += age * (7.0 + aSeed * 6.0);
          p.xz += uWindDir * age * (9.0 + aSeed * 12.0) * uWindStrength;
          p.x += sin(uTime * 0.7 + aSeed * 20.0) * age * 1.6;
          vFade = sin(age * 3.14159) * 0.5;
          vec4 mv = modelViewMatrix * vec4(p, 1.0);
          gl_Position = projectionMatrix * mv;
          gl_PointSize = (3.0 + age * 22.0) * (170.0 / max(-mv.z, 1.0));
        }`,
      fragmentShader: /* glsl */`
        varying float vFade;
        uniform sampler2D uSprite;
        void main(){
          vec4 s = texture2D(uSprite, gl_PointCoord);
          float a = s.a * vFade;
          if (a < 0.004) discard;
          gl_FragColor = vec4(vec3(0.42, 0.40, 0.40) * (0.6 + s.a * 0.6), a);
        }`,
    });
    const pts = new THREE.Points(geo, mat);
    pts.frustumCulled = false;
    pts.name = 'HearthSmoke';
    this.group.add(pts);
  }

  /**
   * Window flicker. Candles gutter; during an eruption they surge and fail.
   * @param nightness 0 = daylight (windows dark), 1 = full night
   */
  update(dt, elapsed, nightness = 1, disturbance = 0) {
    const base = clamp(nightness, 0, 1);
    for (const w of this.windowMeshes) {
      const arr = w.mesh.instanceColor.array;
      for (let i = 0; i < w.count; i++) {
        const s = hash11(i * 7.13 + w.seed);
        // Slow flicker + rare guttering + eruption-driven blackouts.
        let f = 0.72 + 0.28 * Math.sin(elapsed * (1.7 + s * 2.6) + s * 40);
        f *= 0.85 + 0.15 * Math.sin(elapsed * (11 + s * 9) + s * 12);
        if (disturbance > 0.01) {
          const strobe = Math.sin(elapsed * 26 + s * 30);
          f *= 1 - disturbance * (0.5 + 0.5 * strobe) * (s > 0.3 ? 1 : 0.2);
        }
        const lit = base * f;
        arr[i * 3] = 1.0 * lit;
        arr[i * 3 + 1] = 0.66 * lit;
        arr[i * 3 + 2] = 0.28 * lit;
      }
      w.mesh.instanceColor.needsUpdate = true;
    }
  }

  dispose() { this.group.traverse((o) => o.geometry?.dispose()); }
}
