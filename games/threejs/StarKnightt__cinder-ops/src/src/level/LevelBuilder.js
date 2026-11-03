import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { makeRng } from '../world/noise.js';
import { COLORS, WORLD } from '../core/Constants.js';

// Ashline Bazaar footprint (refs/map-expansion-plan.md):
//   Main street  x -7..+5  (12 m, lane center CX)
//   Block row    x +5..+13 (solid, Cut A z 18..22, plaza z 40..58, Cut B z 62..66)
//   Suq alley    x +13..+21 (8 m, lane center SUQ_X)
const INNER = 7.0;   // west face of Main
const EAST = 5;      // block-row west face (Main east edge)
const CX = -1;       // Main lane center
const SUQ_X = 17;    // Suq lane center
const FAR_W = 17;    // west skyline offset
const FAR_E = 30;    // east skyline offset (behind the Suq east row)

export class LevelBuilder {
  constructor(scene, mats) {
    this.scene = scene;
    this.mats = mats;
    this.colliders = [];
    this.lights = [];
    this.spawns = [];
    this.extract = new THREE.Vector3(0, 0, 86);
    this.group = new THREE.Group();
    this.group.name = 'ashline';
    scene.add(this.group);
    this._box = new THREE.BoxGeometry(1, 1, 1);
    this._cyl = new THREE.CylinderGeometry(1, 1, 1, 16);
    this._boxCache = new Map();
    this._dummy = new THREE.Object3D();
    this._color = new THREE.Color();
    this._flames = [];
    this._initKit();
    this._tints();
    this._build();
  }

  addBox(x, y, z, sx, sy, sz, mat, collide = true, tile = 1.35) {
    const m = new THREE.Mesh(this._cachedBox(sx, sy, sz, tile), mat);
    m.position.set(x, y, z);
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    if (collide) this._aabb(x, y, z, sx, sy, sz);
    return m;
  }

  addCyl(x, y, z, r, h, mat, collide = false) {
    const m = new THREE.Mesh(this._cyl, mat);
    m.position.set(x, y, z);
    m.scale.set(r, h, r);
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    if (collide) this.colliders.push({
      min: new THREE.Vector3(x - r, y - h * 0.5, z - r),
      max: new THREE.Vector3(x + r, y + h * 0.5, z + r),
    });
    return m;
  }

  _cachedBox(sx, sy, sz, tile = 1.35) {
    const k = `${(sx * 40) | 0}_${(sy * 40) | 0}_${(sz * 40) | 0}_${(tile * 8) | 0}_0`;
    let g = this._boxCache.get(k);
    if (!g) {
      g = this._uvBox(sx, sy, sz, tile);
      this._boxCache.set(k, g);
    }
    return g;
  }

  _meterUV(g, sx, sy, sz, tile) {
    const pos = g.attributes.position;
    const nrm = g.attributes.normal;
    const uv = g.attributes.uv;
    const inv = 1 / tile;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
      const nx = nrm ? Math.abs(nrm.getX(i)) : 0;
      const ny = nrm ? Math.abs(nrm.getY(i)) : 0;
      const nz = nrm ? Math.abs(nrm.getZ(i)) : 0;
      if (nx >= ny && nx >= nz) uv.setXY(i, (z + sz * 0.5) * inv, (y + sy * 0.5) * inv);
      else if (ny >= nx && ny >= nz) uv.setXY(i, (x + sx * 0.5) * inv, (z + sz * 0.5) * inv);
      else uv.setXY(i, (x + sx * 0.5) * inv, (y + sy * 0.5) * inv);
    }
    uv.needsUpdate = true;
    g.setAttribute('uv2', uv.clone());
    return g;
  }

  _uvRound(sx, sy, sz, tile, r) {
    return this._meterUV(new RoundedBoxGeometry(sx, sy, sz, 2, r), sx, sy, sz, tile);
  }

  _uvBox(sx, sy, sz, tile) {
    return this._meterUV(new THREE.BoxGeometry(sx, sy, sz), sx, sy, sz, tile);
  }

  _aabb(x, y, z, sx, sy, sz) {
    this.colliders.push({
      min: new THREE.Vector3(x - sx * 0.5, y - sy * 0.5, z - sz * 0.5),
      max: new THREE.Vector3(x + sx * 0.5, y + sy * 0.5, z + sz * 0.5),
    });
  }

  _rotAabb(x, z, yaw, hx, hz, hy) {
    const c = Math.abs(Math.cos(yaw)), s = Math.abs(Math.sin(yaw));
    const wx = hx * c + hz * s;
    const wz = hx * s + hz * c;
    this.colliders.push({
      min: new THREE.Vector3(x - wx, 0, z - wz),
      max: new THREE.Vector3(x + wx, hy, z + wz),
    });
  }

  _part(parent, geo, mat, x, y, z, sx = 1, sy = 1, sz = 1, rx = 0, ry = 0, rz = 0) {
    const m = new THREE.Mesh(geo, mat);
    m.position.set(x, y, z);
    m.scale.set(sx, sy, sz);
    m.rotation.set(rx, ry, rz);
    m.castShadow = true;
    m.receiveShadow = true;
    parent.add(m);
    return m;
  }

  _point(color, intensity, distance, x, y, z, decay = 2) {
    if (this.lights.length >= 8) return null;
    const l = new THREE.PointLight(color, intensity * 0.12, distance * 0.7, decay);
    l.position.set(x, y, z);
    this.scene.add(l);
    this.lights.push(l);
    return l;
  }

  _spot(color, intensity, distance, angle, x, y, z, tx, ty, tz, shadow = false) {
    if (this.lights.length >= 24) return null;
    const l = new THREE.SpotLight(color, intensity, distance, angle, 0.48, 1.15);
    l.position.set(x, y, z);
    l.target.position.set(tx, ty, tz);
    if (shadow) {
      l.castShadow = true;
      l.shadow.mapSize.set(512, 512);
      l.shadow.camera.near = 0.5;
      l.shadow.camera.far = 22;
      l.shadow.bias = -0.0002;
    }
    this.scene.add(l, l.target);
    this.lights.push(l);
    return l;
  }

  _push(list, x, y, z, rx = 0, ry = 0, rz = 0, sx = 1, sy = 1, sz = 1) {
    list.push([x, y, z, rx, ry, rz, sx, sy, sz]);
  }

  _instanced(geo, mat, list, cast = true) {
    if (!list.length) return null;
    const im = new THREE.InstancedMesh(geo, mat, list.length);
    im.castShadow = !!cast;
    im.receiveShadow = true;
    im.frustumCulled = false;
    const d = this._dummy;
    for (let i = 0; i < list.length; i++) {
      const t = list[i];
      d.position.set(t[0], t[1], t[2]);
      d.rotation.set(t[3], t[4], t[5]);
      d.scale.set(t[6], t[7], t[8]);
      d.updateMatrix();
      im.setMatrixAt(i, d.matrix);
    }
    im.instanceMatrix.needsUpdate = true;
    this.group.add(im);
    return im;
  }

  _tint(base, hex) {
    const m = base.clone();
    m.color.setHex(hex);
    if ('envMapIntensity' in m) m.envMapIntensity = Math.min(0.35, (base.envMapIntensity || 0.2) * 0.55);
    return m;
  }

  _tints() {
    const p = this.mats.paint;
    this.col = {
      dump: this.mats.dumpPaint || this._tint(p, 0x6a6848),
      dumpLid: this.mats.dumpRust || this._tint(p, 0x8a6a40),
      navy: this._tint(p, 0x3a342c),
      silver: this.mats.sedanSilver || this._tint(p, 0x8a8478),
      maroon: this.mats.sedanMaroon || this._tint(p, 0x6a2a22),
      taxi: this.mats.sedanTaxi || this._tint(p, 0xb89628),
      sand: this.mats.burlap || this._tint(p, 0x8a7048),
      cone: this._tint(p, 0x8a4a22),
      awnR: this.mats.awningStripe || this.mats.awningCloth || this._tint(p, 0x7a5848),
      awnG: this.mats.awningStripe || this.mats.awningAlt || this._tint(p, 0x6a5a40),
      awnN: this.mats.awningUnder || this._tint(this.mats.fabric || p, 0x5a4a38),
      cab: this._tint(p, 0x4c4034),
      door: this._tint(p, 0x5c422e),
      doorInset: this._tint(p, 0x4a3424),
      tarp: this.mats.tarp || this._tint(this.mats.fabric || p, 0x5a4a32),
      cratePaint: this.mats.cratePaint || this._tint(p, 0x4a4638),
      recess: this.mats.interior || this.mats.warmWall || this.mats.darkRoom,
      leaf: this._tint(p, 0x2a2414),
      goods: this._tint(p, 0x30251b),
      frame: this.mats.sill || this._tint(this.mats.plaster, 0x7a7468),
      sill: this.mats.sill || this._tint(this.mats.plaster, 0x6a6458),
      mull: this.mats.sill || this._tint(this.mats.concrete, 0x6a665c),
      tan: this.mats.tanMull || this.mats.sill || this._tint(this.mats.plaster, 0x8a8274),
      vanPlate: this.mats.vanPlate || this._tint(p, 0x33201e),
    };
    this._worldMats();
  }

  /* Local clones only — materials.js / bake.js are owned by another lane. */
  _worldMats() {
    const plaster = this.mats.plaster;
    const cloneP = (hex, rough = 0.90) => {
      const m = plaster.clone();
      m.color = new THREE.Color(hex);
      m.roughness = rough;
      this._bindFacade(m, plaster);
      return m;
    };
    /* CS2 Italy: cream / pink-ochre / warm white / pale tan per building. */
    this._plasters = [
      cloneP(0xf2e6cc, 0.91),
      cloneP(0xd4a090, 0.89),
      cloneP(0xf6f0e4, 0.92),
      cloneP(0xc9a878, 0.88),
    ];
    for (const p of this._plasters) {
      if (p.normalScale) p.normalScale = p.normalScale.clone().multiplyScalar(0.42);
    }
    this._plasterTile = [2.15, 4.85, 3.35, 6.20];
    if (this.mats.brick) {
      this._brickBound = this.mats.brick.clone();
      this._bindFacade(this._brickBound, this.mats.brick);
    }
    const trim = plaster.clone();
    trim.color = new THREE.Color(0xd8c8a8);
    trim.roughness = 0.78;
    if (trim.envMapIntensity != null) trim.envMapIntensity = 0.22;
    this.col.trim = trim;
    const chip = plaster.clone();
    chip.color = new THREE.Color(0xb8a078);
    chip.roughness = 0.86;
    this.col.chipStone = chip;
    const chrome = (this.mats.chrome || this.mats.metal).clone();
    /* Aged steel — dark body, modest spec. High env was blowing bumpers
     * into white slabs against the noon sky. */
    chrome.color = new THREE.Color(0x2a2e34);
    chrome.roughness = 0.46;
    chrome.metalness = 0.72;
    if (chrome.envMapIntensity != null) chrome.envMapIntensity = 0.55;
    this.col.agedChrome = chrome;
    const streak = this._streakMap();
    const windStreak = this._windStreakMap();
    const pane = (this.mats.windowDark || this.mats.paneGlass || this.mats.glass).clone();
    /* Dark blue-grey sky glass + one warm streak. c25 lit panes read as
     * glowing frosted paper (~200) because warm emissive sat on a pale body. */
    pane.color = new THREE.Color(0x1a2228);
    pane.map = streak;
    pane.emissive = new THREE.Color(0x2a3238);
    pane.emissiveMap = streak;
    pane.emissiveIntensity = 0.05;
    pane.roughness = 0.28;
    pane.metalness = 0.10;
    pane.envMapIntensity = 0.22;
    pane.opacity = 0.90;
    pane.transparent = true;
    pane.side = THREE.DoubleSide;
    this.col.pane = pane;
    const lit = pane.clone();
    lit.color = new THREE.Color(0x243038);
    lit.emissive = new THREE.Color(0x3a4650);
    lit.emissiveIntensity = 0.08;
    this.col.paneLit = lit;
    const wind = pane.clone();
    wind.color = new THREE.Color(0x2c3844);
    wind.map = windStreak;
    wind.emissive = new THREE.Color(0x6a5e4c);
    wind.emissiveMap = windStreak;
    wind.emissiveIntensity = 0.16;
    wind.roughness = 0.18;
    wind.metalness = 0.10;
    wind.envMapIntensity = 0.22;
    wind.opacity = 0.90;
    wind.transparent = true;
    wind.side = THREE.DoubleSide;
    this.col.wind = wind;
    this.col.windStreak = wind;
    this._capGlass(pane, 0.28);
    this._capGlass(lit, 0.34);
    this._capGlass(wind, 0.40);
    const cone = (this.mats.paint || plaster).clone();
    cone.color = new THREE.Color(0xb86830);
    cone.roughness = 0.88;
    cone.vertexColors = true;
    if (cone.envMapIntensity != null) cone.envMapIntensity = 0.12;
    this.col.cone = cone;
    const joist = (this.mats.wood || plaster).clone();
    joist.color = new THREE.Color(0x8a6a44);
    joist.roughness = 0.72;
    if (joist.emissive) joist.emissive = new THREE.Color(0x1a1208);
    if (joist.emissiveIntensity != null) joist.emissiveIntensity = 0.04;
    this.col.joist = joist;
    /* Window / shop wells were 0x1a1410 + 0.028 emissive — a hole in the
     * world once the sun no longer leaked through a broken frustum. */
    const dim = (this.mats.darkRoom || this.mats.interior).clone();
    dim.color = new THREE.Color(0x5c4a36);
    dim.roughness = 0.90;
    dim.emissive = new THREE.Color(0x4a3826);
    dim.emissiveIntensity = 0.42;
    if (dim.envMapIntensity != null) dim.envMapIntensity = 0.10;
    this.col.dimRoom = dim;
    const warmIn = (this.mats.interior || this.mats.warmRoom || dim).clone();
    warmIn.color = new THREE.Color(0x7a5e40);
    warmIn.roughness = 0.88;
    warmIn.emissive = new THREE.Color(0x5a4030);
    warmIn.emissiveIntensity = 0.36;
    if (warmIn.envMapIntensity != null) warmIn.envMapIntensity = 0.12;
    this.col.warmIn = warmIn;
  }

  _streakMap() {
    if (this._streakTex) return this._streakTex;
    const c = document.createElement('canvas');
    c.width = c.height = 256;
    const g = c.getContext('2d');
    const lg = g.createLinearGradient(0, 256, 0, 0);
    lg.addColorStop(0, '#2a241c');
    lg.addColorStop(0.45, '#322c22');
    lg.addColorStop(1, '#3a3428');
    g.fillStyle = lg;
    g.fillRect(0, 0, 256, 256);
    /* ONE soft band: width ~12% of the pane, peak ~155, never a white bar. */
    g.save();
    g.translate(128, 128);
    g.rotate(-0.58);
    const half = 16;
    const sg = g.createLinearGradient(0, -half, 0, half);
    sg.addColorStop(0, 'rgba(150,138,118,0)');
    sg.addColorStop(0.28, 'rgba(158,146,126,0.08)');
    sg.addColorStop(0.50, 'rgba(168,158,138,0.34)');
    sg.addColorStop(0.62, 'rgba(172,162,142,0.20)');
    sg.addColorStop(0.82, 'rgba(150,138,118,0.05)');
    sg.addColorStop(1, 'rgba(140,128,110,0)');
    g.fillStyle = sg;
    g.fillRect(-300, -half, 600, half * 2);
    g.restore();
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = THREE.SRGBColorSpace;
    t.needsUpdate = true;
    this._streakTex = t;
    return t;
  }

  /* Vehicle glass: same one-band rule, but the band is forced through UV
   * center so a face-on 3/4 card (street taxi) cannot miss it. */
  _windStreakMap() {
    if (this._windStreakTex) return this._windStreakTex;
    const c = document.createElement('canvas');
    c.width = c.height = 256;
    const g = c.getContext('2d');
    const lg = g.createLinearGradient(0, 256, 0, 0);
    lg.addColorStop(0, '#4a4034');
    lg.addColorStop(0.55, '#5c5040');
    lg.addColorStop(1, '#6a5c48');
    g.fillStyle = lg;
    g.fillRect(0, 0, 256, 256);
    g.save();
    g.translate(128, 128);
    g.rotate(-0.52);
    const half = 17;
    const sg = g.createLinearGradient(0, -half, 0, half);
    sg.addColorStop(0, 'rgba(150,138,118,0)');
    sg.addColorStop(0.30, 'rgba(176,164,140,0.16)');
    sg.addColorStop(0.50, 'rgba(198,186,160,0.55)');
    sg.addColorStop(0.70, 'rgba(176,164,140,0.18)');
    sg.addColorStop(1, 'rgba(140,128,110,0)');
    g.fillStyle = sg;
    g.fillRect(-300, -half, 600, half * 2);
    g.restore();
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = THREE.SRGBColorSpace;
    t.needsUpdate = true;
    this._windStreakTex = t;
    return t;
  }

  /* Keep dressFacade on tinted plaster clones + a stronger ground skirt. */
  _bindFacade(m, src) {
    if (!src || !src.onBeforeCompile) return m;
    const prev = src.onBeforeCompile;
    m.onBeforeCompile = (shader) => {
      prev(shader);
      if (!shader.fragmentShader.includes('vWPosF')) return;
      /* c29: kill leftover ellipse RIM (c28 zeroed inPatch fill only —
       * patchRim still drew 2m crop-circles). Pentagon patches keep a
       * relative underlayer so tan walls get a filled interior, not a rim. */
      shader.fragmentShader = shader.fragmentShader
        .replace(
          'float inPatch = sstepF(1.05, 0.70, dEllF) * isPatchF;',
          'float inPatch = 0.0;',
        )
        .replace(
          'float patchRim = sstepF(0.22, 0.04, abs(dEllF - 0.88)) * isPatchF;',
          'float patchRim = 0.0;',
        )
        .replace(
          'diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * vec3(1.07, 1.00, 0.91), sstepF(0.55, 0.90, mac.g) * 0.8);',
          'diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * vec3(1.07, 1.00, 0.91), 0.0);',
        )
        .replace(
          'diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.16, 0.11, 0.07), streak * 0.78);',
          [
            'diffuseColor.rgb *= 0.66 / max(0.50 + 0.62 * mac.r, 0.20);',
            'vec2 wUV = wallUVF;',
            'vec2 baySz = vec2(3.55, 2.95);',
            'vec2 bayId = floor(wUV / baySz);',
            'vec2 bayF = fract(wUV / baySz);',
            'float bayH = fract(sin(dot(bayId + vec2(2.1, 7.3), vec2(127.1, 311.7))) * 43758.5453);',
            'float nWant = step(0.34, bayH) + step(0.70, bayH) + step(0.92, bayH);',
            'float patchM = 0.0;',
            'float rimM = 0.0;',
            'for (int i = 0; i < 3; i++) {',
            '  float fi = float(i);',
            '  float live = step(fi, nWant - 0.5);',
            '  float h = fract(bayH * (19.13 + fi * 11.7) + fi * 0.41);',
            '  vec2 ctr = vec2(0.18 + fract(h * 17.3) * 0.64, 0.22 + fract(h * 9.1) * 0.54);',
            '  vec2 d = (bayF - ctr) * vec2(1.0, 1.12);',
            '  float ang = h * 6.2831853;',
            '  vec2 r = vec2(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));',
            '  float poly = -1.0;',
            '  for (int k = 0; k < 5; k++) {',
            '    float fk = float(k);',
            '    float ak = ang + fk * 1.256637 + h * 0.35 + sin(fk * 2.3 + h * 6.0) * 0.22;',
            '    float pk = r.x * cos(ak) + r.y * sin(ak);',
            '    float radK = 0.088 + fract(h * (6.8 + fk)) * 0.090 + sin(fk * 3.1 + h * 9.0) * 0.016;',
            '    poly = max(poly, pk - radK);',
            '  }',
            '  float jag = step(0.42, fract(sin(dot(floor(r * 28.0), vec2(12.7, 4.1)) + h) * 43758.5));',
            '  poly += jag * 0.010;',
            '  float inside = step(poly, 0.0);',
            '  float ring = step(poly, 0.016) * (1.0 - inside);',
            '  patchM = max(patchM, inside * live);',
            '  rimM = max(rimM, ring * live);',
            '}',
            'float wallL = dot(diffuseColor.rgb, vec3(0.299, 0.587, 0.114));',
            'vec3 stoneU = vec3(0.22, 0.17, 0.11);',
            'vec3 paleU = vec3(0.46, 0.39, 0.30);',
            'vec3 underDark = mix(diffuseColor.rgb * vec3(0.48, 0.44, 0.38), stoneU, 0.38);',
            'vec3 underLift = mix(diffuseColor.rgb * vec3(1.20, 1.12, 1.02), paleU, 0.32);',
            'vec3 underC = mix(underLift, underDark, step(0.14, wallL));',
            'vec3 rimC = mix(diffuseColor.rgb, stoneU, 0.55);',
            'diffuseColor.rgb = mix(diffuseColor.rgb, underC, patchM * 0.88);',
            'diffuseColor.rgb = mix(diffuseColor.rgb, rimC, rimM * 0.42);',
            /* Hard sill drips — thin vertical streaks, not soft runoff. */
            'float colId = floor(wUV.x * 1.28);',
            'float dripN = fract(sin(colId * 91.17 + bayId.y * 13.7) * 43758.5);',
            'float dripOn = step(0.58, dripN);',
            'float dripX = abs(fract(wUV.x * 1.28) - 0.5);',
            'float dripLen = 0.48 + dripN * 0.90;',
            'float dripBody = dripOn * step(1.58, wUV.y) * step(wUV.y, 1.58 + dripLen)',
            '               * step(dripX, 0.038 + dripN * 0.028);',
            'diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.17, 0.12, 0.08), dripBody * 0.48);',
          ].join('\n'),
        );
      shader.fragmentShader = shader.fragmentShader.replace(
        '#include <opaque_fragment>',
        [
          'outgoingLight *= mix(vec3(1.0), vec3(0.70, 0.62, 0.50), smoothstep(1.55, 0.04, vWPosF.y));',
          'outgoingLight *= 0.905;',
          'float eave = 0.0;',
          'eave += 1.0 - smoothstep(0.0, 0.70, abs(vWPosF.y - 3.12));',
          'eave += 1.0 - smoothstep(0.0, 0.80, abs(vWPosF.y - 6.35));',
          'eave += 1.0 - smoothstep(0.0, 1.00, abs(vWPosF.y - 8.15));',
          'outgoingLight *= 1.0 - clamp(eave, 0.0, 1.0) * 0.12;',
          'float eastCanyon = (1.0 - smoothstep(0.20, 1.10, abs(vWPosF.x - 4.92)))',
          '                 * smoothstep(0.50, 1.30, vWPosF.y);',
          'outgoingLight *= mix(vec3(1.0), vec3(0.48, 0.44, 0.36), eastCanyon * 0.96);',
          'outgoingLight *= mix(1.0, 1.16, smoothstep(78.0, 88.0, vWPosF.z));',
          '#include <opaque_fragment>',
        ].join('\n'),
      );
    };
    const key = src.customProgramCacheKey ? src.customProgramCacheKey() : 'facade';
    m.customProgramCacheKey = () => `${key}-w29y`;
    return m;
  }

  _initKit() {
    const uv2 = (g) => {
      g.setAttribute('uv2', g.attributes.uv.clone());
      return g;
    };
    this.geo = {
      box: this._box,
      cyl: this._cyl,
      sphere6: new THREE.SphereGeometry(1, 10, 8),
      cone: this._coneGeo(),
      coneDirt: new THREE.TorusGeometry(0.118, 0.018, 6, 12),
      winRecess: uv2(new THREE.BoxGeometry(0.28, 1.58, 1.24)),
      winGlass: uv2(new THREE.BoxGeometry(0.07, 1.34, 1.08)),
      windPlane: uv2(new THREE.PlaneGeometry(1, 1)),
      winSill: uv2(new RoundedBoxGeometry(0.34, 0.10, 1.32, 1, 0.018)),
      winMullH: uv2(new RoundedBoxGeometry(0.08, 0.08, 0.96, 1, 0.010)),
      winMullV: uv2(new RoundedBoxGeometry(0.08, 1.22, 0.08, 1, 0.010)),
      winFrameH: uv2(new RoundedBoxGeometry(0.12, 0.10, 1.28, 1, 0.014)),
      winFrameV: uv2(new RoundedBoxGeometry(0.12, 1.48, 0.12, 1, 0.014)),
      winInterior: uv2(new THREE.BoxGeometry(0.10, 1.42, 1.12)),
      winJamb: uv2(new RoundedBoxGeometry(0.26, 1.52, 0.12, 1, 0.02)),
      winHead: uv2(new RoundedBoxGeometry(0.26, 0.12, 1.28, 1, 0.018)),
      winBlind: uv2(new THREE.BoxGeometry(0.03, 1.10, 0.92)),
      winCurtain: uv2(new THREE.BoxGeometry(0.03, 1.22, 0.28)),
      pebble: this._pebbleGeo(),
      chip: uv2(new RoundedBoxGeometry(0.16, 0.10, 0.12, 1, 0.02)),
      sandbag: this._sackGeo(),
      bolt: new RoundedBoxGeometry(0.045, 0.045, 0.032, 1, 0.006),
      debris: uv2(new RoundedBoxGeometry(0.24, 0.11, 0.17, 1, 0.02)),
      dash: new THREE.BoxGeometry(0.1, 0.01, 1.7),
      fenceBar: new THREE.CylinderGeometry(0.014, 0.014, 1.18, 8),
      crate: uv2(new THREE.BoxGeometry(0.56, 0.5, 0.56)),
      crateBand: uv2(new THREE.BoxGeometry(0.58, 0.040, 0.58)),
      crateSlat: uv2(new THREE.BoxGeometry(0.54, 0.026, 0.07)),
      crateEnd: uv2(new THREE.BoxGeometry(0.036, 0.48, 0.54)),
      crateBatten: uv2(new THREE.BoxGeometry(0.055, 0.52, 0.055)),
      card: uv2(new RoundedBoxGeometry(0.4, 0.26, 0.34, 1, 0.02)),
      trash: new THREE.SphereGeometry(0.3, 10, 8),
      manhole: new THREE.CircleGeometry(0.40, 20),
      manholeIn: new THREE.CircleGeometry(0.24, 16),
      drain: uv2(new RoundedBoxGeometry(0.58, 0.045, 0.3, 1, 0.012)),
      puddle: this._blobGeo(),
      tire: new THREE.CylinderGeometry(0.3, 0.3, 0.2, 16),
      hub: new THREE.CylinderGeometry(0.13, 0.13, 0.22, 12),
      wheel: new THREE.CylinderGeometry(0.32, 0.32, 0.16, 18),
      wheelHub: new THREE.CylinderGeometry(0.048, 0.128, 0.062, 18),
      wheelTire: new THREE.TorusGeometry(0.268, 0.046, 10, 22),
      wheelCap: new THREE.CylinderGeometry(0.022, 0.028, 0.014, 12),
      wheelWall: new THREE.CylinderGeometry(0.205, 0.205, 0.024, 18),
      wheelBolt: new THREE.CylinderGeometry(0.0065, 0.0075, 0.016, 6),
      rimLip: new THREE.TorusGeometry(0.155, 0.014, 8, 18),
      rimBarrel: new THREE.CylinderGeometry(0.168, 0.168, 0.052, 18),
      archFlare: this._archFlareGeo(),
      wellInner: this._wellInnerGeo(),
      disc: this._discGeo(),
      winGrime: uv2(new THREE.BoxGeometry(0.035, 0.92, 0.52)),
      lampBase: new THREE.CylinderGeometry(0.15, 0.2, 0.24, 16),
      lampPole: new THREE.CylinderGeometry(0.042, 0.052, 5.55, 16),
      acBody: uv2(new THREE.BoxGeometry(1.15, 0.62, 0.82)),
      acFan: new THREE.CylinderGeometry(0.36, 0.36, 0.08, 16),
      barrel: this._barrelGeo(),
      barrelHoop: uv2(new THREE.TorusGeometry(0.29, 0.018, 8, 20)),
      vent: uv2(new RoundedBoxGeometry(1.48, 0.78, 1.48, 2, 0.05)),
      ventGrille: uv2(new THREE.BoxGeometry(1.22, 0.46, 1.52).translate(0, -0.04, 0)),
      ventCap: uv2(new THREE.BoxGeometry(1.54, 0.07, 1.54).translate(0, 0.40, 0)),
      ledge: uv2(new RoundedBoxGeometry(1, 0.16, 1, 1, 0.02)),
      doorPanel: uv2(new RoundedBoxGeometry(0.08, 2.15, 0.92, 2, 0.018)),
      doorFrameH: uv2(new RoundedBoxGeometry(0.14, 0.12, 1.18, 1, 0.016)),
      doorFrameV: uv2(new RoundedBoxGeometry(0.14, 2.28, 0.12, 1, 0.016)),
      arch: this._archGeo(),
      archFill: this._archFillGeo(),
      archGlass: this._archGlassGeo(),
    };

    this.geo.lampHead = new THREE.LatheGeometry([
      new THREE.Vector2(0.02, 0),
      new THREE.Vector2(0.17, 0.012),
      new THREE.Vector2(0.21, 0.07),
      new THREE.Vector2(0.1, 0.1),
      new THREE.Vector2(0.045, 0.15),
    ], 16);

    this.geo.dish = new THREE.LatheGeometry([
      new THREE.Vector2(0.03, 0),
      new THREE.Vector2(0.42, 0.06),
      new THREE.Vector2(0.52, 0.18),
      new THREE.Vector2(0.10, 0.14),
    ], 16);

    const js = new THREE.Shape();
    js.moveTo(-0.24, 0);
    js.lineTo(0.24, 0);
    js.lineTo(0.19, 0.46);
    js.lineTo(0.11, 0.96);
    js.lineTo(-0.11, 0.96);
    js.lineTo(-0.19, 0.46);
    js.closePath();
    this.geo.jersey = new THREE.ExtrudeGeometry(js, {
      depth: 2.35, bevelEnabled: true, bevelThickness: 0.032, bevelSize: 0.028, bevelSegments: 2,
    });
    this.geo.jersey.translate(0, 0, -1.175);
    this.geo.jersey.computeVertexNormals();

    this.geo.lampArm = new THREE.TubeGeometry(new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 0, 0),
      new THREE.Vector3(0.22, 0.045, 0),
      new THREE.Vector3(0.58, 0.02, 0),
      new THREE.Vector3(0.9, -0.11, 0),
    ]), 12, 0.03, 8, false);

    this.q = {
      recess: [], frameH: [], frameV: [], glassD: [], glassC: [], sill: [], mullH: [], mullV: [],
      interior: [], darkRoom: [], jamb: [], head: [], blind: [], curtain: [], sand: [], bolt: [], debris: [],
      dash: [], fence: [], crate: [], crateBand: [], crateSlat: [], crateEnd: [], crateBatten: [], card: [], trash: [], cone: [], coneDirt: [], ac: [], fan: [],
      barrel: [], hoop: [], vent: [],       ledge: [], door: [], doorH: [], doorV: [], arch: [], archFill: [],
      contact: [], drift: [], skirt: [], grime: [], pebble: [], chip: [],
      archGlass: [], shutter: [],
    };
  }

  _pebbleGeo() {
    const g = new THREE.LatheGeometry([
      new THREE.Vector2(0.0, 0),
      new THREE.Vector2(0.026, 0.003),
      new THREE.Vector2(0.030, 0.012),
      new THREE.Vector2(0.016, 0.020),
      new THREE.Vector2(0.0, 0.022),
    ], 8);
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    return g;
  }

  _discGeo() {
    const g = new THREE.CircleGeometry(1, 28);
    g.rotateX(-Math.PI / 2);
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    return g;
  }

  _chimney(x, y, z) {
    this.addBox(x, y + 0.46, z, 0.40, 0.92, 0.40, this.mats.brick, false, 0.65);
    this.addBox(x, y + 0.94, z, 0.46, 0.10, 0.46, this.mats.concrete, false, 0.7);
    this.addCyl(x, y + 1.12, z, 0.055, 0.26, this.mats.darkMetal, false);
  }

  _antenna(x, y, z, h = 1.4) {
    this.addCyl(x, y + h * 0.5, z, 0.016, h, this.mats.darkMetal, false);
    this.addCyl(x, y + h, z, 0.032, 0.055, this.mats.metal, false);
  }

  _sackGeo() {
    const g = new THREE.LatheGeometry([
      new THREE.Vector2(0.02, 0),
      new THREE.Vector2(0.48, 0.04),
      new THREE.Vector2(0.50, 0.14),
      new THREE.Vector2(0.42, 0.26),
      new THREE.Vector2(0.22, 0.32),
      new THREE.Vector2(0.0, 0.34),
    ], 14);
    g.translate(0, -0.27, 0);
    g.computeVertexNormals();
    return g;
  }

  _barrelGeo() {
    const g = new THREE.LatheGeometry([
      new THREE.Vector2(0.22, 0),
      new THREE.Vector2(0.30, 0.04),
      new THREE.Vector2(0.28, 0.18),
      new THREE.Vector2(0.30, 0.36),
      new THREE.Vector2(0.28, 0.54),
      new THREE.Vector2(0.30, 0.68),
      new THREE.Vector2(0.22, 0.72),
    ], 20);
    g.translate(0, -0.36, 0);
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    return g;
  }

  _archGeo() {
    const s = new THREE.Shape();
    s.moveTo(-0.72, 0);
    s.lineTo(-0.72, 0.85);
    s.absarc(0, 0.85, 0.72, Math.PI, 0, true);
    s.lineTo(0.72, 0);
    s.lineTo(0.58, 0);
    s.lineTo(0.58, 0.85);
    s.absarc(0, 0.85, 0.58, 0, Math.PI, false);
    s.lineTo(-0.58, 0);
    s.closePath();
    const g = new THREE.ExtrudeGeometry(s, {
      depth: 0.22, bevelEnabled: true, bevelThickness: 0.02, bevelSize: 0.018, bevelSegments: 2,
    });
    g.translate(0, 0, -0.11);
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    return g;
  }

  /* Filled arch panel: sits recessed behind the ring so blind arches read
   * as a shadowed reveal with jamb depth, not an outline card (fix 9). */
  _archFillGeo() {
    const s = new THREE.Shape();
    s.moveTo(-0.62, 0);
    s.lineTo(-0.62, 0.85);
    s.absarc(0, 0.85, 0.62, Math.PI, 0, true);
    s.lineTo(0.62, 0);
    s.closePath();
    const g = new THREE.ExtrudeGeometry(s, { depth: 0.10, bevelEnabled: false });
    g.translate(0, 0, -0.36);
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    return g;
  }

  _archGlassGeo() {
    const s = new THREE.Shape();
    s.moveTo(-0.58, 0.04);
    s.lineTo(-0.58, 0.85);
    s.absarc(0, 0.85, 0.58, Math.PI, 0, true);
    s.lineTo(0.58, 0.04);
    s.closePath();
    const g = new THREE.ExtrudeGeometry(s, { depth: 0.03, bevelEnabled: false });
    g.translate(0, 0, -0.18);
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    return g;
  }

  _archFlareGeo() {
    const pts = [];
    for (let i = 0; i <= 10; i++) {
      const a = (i / 10) * Math.PI;
      pts.push(new THREE.Vector3(0, Math.sin(a) * 0.318, Math.cos(a) * 0.318));
    }
    const g = new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 8, 0.048, 6, false);
    g.computeVertexNormals();
    return g;
  }

  _wellInnerGeo() {
    const g = new THREE.CylinderGeometry(0.42, 0.42, 0.22, 14, 1, true, 0, Math.PI);
    g.rotateZ(Math.PI * 0.5);
    g.computeVertexNormals();
    return g;
  }

  /* Side-profile loft: hood slope, windshield rake, roof, trunk. Replaces
   * the kit-bashed box hulls on the two most-seen vehicles. */
  _loftHullGeo(kind) {
    if (!this._loftCache) this._loftCache = {};
    if (this._loftCache[kind]) return this._loftCache[kind];
    const s = new THREE.Shape();
    if (kind === 'sedan' || kind === 'sedanSolid') {
      s.moveTo(-2.16, 0.14);
      if (kind === 'sedanSolid') {
        /* Taxi: no loft wheel-cutouts — the cream arch lip read as a whitewall. */
        s.lineTo(2.16, 0.14);
      } else {
        s.lineTo(-1.52, 0.14);
        s.lineTo(-1.44, 0.34);
        s.lineTo(-1.30, 0.50);
        s.lineTo(-1.16, 0.34);
        s.lineTo(-1.08, 0.14);
        s.lineTo(1.04, 0.14);
        s.lineTo(1.12, 0.34);
        s.lineTo(1.26, 0.50);
        s.lineTo(1.40, 0.34);
        s.lineTo(1.48, 0.14);
        s.lineTo(2.16, 0.14);
      }
      s.lineTo(2.16, 0.32);
      s.lineTo(2.00, 0.46);
      s.lineTo(1.42, 0.54);
      s.lineTo(1.02, 0.58);
      s.lineTo(0.68, 1.10);
      s.lineTo(0.38, 1.20);
      s.lineTo(-0.82, 1.20);
      s.lineTo(-1.12, 1.12);
      s.lineTo(-1.40, 0.86);
      s.lineTo(-1.68, 0.52);
      s.lineTo(-2.16, 0.36);
      s.closePath();
    } else {
      s.moveTo(-2.28, 0.14);
      s.lineTo(-1.58, 0.14);
      s.lineTo(-1.50, 0.36);
      s.lineTo(-1.36, 0.52);
      s.lineTo(-1.22, 0.36);
      s.lineTo(-1.14, 0.14);
      s.lineTo(1.22, 0.14);
      s.lineTo(1.30, 0.36);
      s.lineTo(1.44, 0.52);
      s.lineTo(1.58, 0.36);
      s.lineTo(1.66, 0.14);
      s.lineTo(2.52, 0.14);
      s.lineTo(2.52, 0.34);
      s.lineTo(2.38, 0.50);
      s.lineTo(1.95, 0.60);
      s.lineTo(1.48, 0.74);
      s.lineTo(1.08, 1.32);
      s.lineTo(0.52, 1.88);
      s.lineTo(0.28, 1.94);
      s.lineTo(-2.28, 1.94);
      s.closePath();
    }
    const depth = kind === 'van' ? 1.74 : 1.58;
    const g = new THREE.ExtrudeGeometry(s, {
      depth,
      bevelEnabled: true,
      bevelThickness: 0.038,
      bevelSize: 0.030,
      bevelSegments: 1,
      curveSegments: 1,
    });
    g.rotateY(-Math.PI / 2);
    g.translate(depth * 0.5, 0, 0);
    g.computeVertexNormals();
    this._meterUV(g, depth + 0.08, kind === 'van' ? 1.98 : 1.24, kind === 'van' ? 4.9 : 4.4, 1.2);
    this._loftCache[kind] = g;
    return g;
  }

  _loftHull(parent, kind, mat) {
    const geo = mat && mat.vertexColors ? this._shadeHullGeo(kind) : this._loftHullGeo(kind);
    const m = new THREE.Mesh(geo, mat);
    m.castShadow = true;
    m.receiveShadow = true;
    parent.add(m);
    return m;
  }

  _blobGeo() {
    const s = new THREE.Shape();
    const pts = [
      [0.12, 1.0], [0.58, 0.78], [0.96, 0.32], [0.9, -0.28],
      [0.48, -0.88], [-0.08, -1.0], [-0.62, -0.74], [-0.98, -0.16],
      [-0.82, 0.4], [-0.34, 0.9],
    ];
    s.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < pts.length; i++) s.lineTo(pts[i][0], pts[i][1]);
    s.closePath();
    const g = new THREE.ShapeGeometry(s);
    g.rotateX(-Math.PI / 2);
    return g;
  }

  _build() {
    const rng = makeRng(WORLD.SEED);
    this._ground();
    this._streetDress(rng);
    this._endcaps(rng);
    this._spawnWall(rng);
    this._lamps();
    this._fire(rng);
    this._buildings(rng);
    this._sealCanyons();
    this._skyline(rng);
    this._cables();
    this._dustArch(18.4);
    this._dustArch(41.2);
    this._dustArch(68.6);
    this._cutArch(13, 20);
    this._cutArch(13, 64);
    this._cover(rng);
    this._alleyFill(rng);
    this._vanWall(rng);
    this._market(rng);
    this._marketSkyCap();
    this._suqDress(rng);
    this._sidewalkProps(rng);
    this._vehicles(rng);
    this._frustumKit(rng);
    this._midHeightSeals();
    this._macroGrime();
    this._flush();
    this._flattenStatic(this.group);
    this._pruneEmpty(this.group);
    this._trimShadows(this.group);
    this._mergeMeshes(this.group);
    this._pruneEmpty(this.group);
    this._enemies(rng);
  }

  _lot(side, z, w, d, h, extra = {}) {
    const base = extra.xBase != null ? extra.xBase : INNER;
    return { x: side * (base + w * 0.5), z, w, d, h, side, ...extra };
  }

  _ground() {
    const len = WORLD.LENGTH + 22;
    const zc = WORLD.LENGTH * 0.5 - 2;
    const street = new THREE.Mesh(this._uvPlane(10.4, len, 1.85), this.mats.asphalt);
    street.rotation.x = -Math.PI / 2;
    street.position.set(CX, 0, zc);
    street.receiveShadow = true;
    this.group.add(street);

    for (const side of [-1, 1]) {
      // East curb hardware only runs along the block row; the yard and
      // forecourt open across the full width there.
      const cl = side < 0 ? len : 70;
      const cz = side < 0 ? zc : 43;
      const walk = new THREE.Mesh(this._uvPlane(2.35, cl, 1.65), this.mats.concrete);
      walk.rotation.x = -Math.PI / 2;
      walk.position.set(CX + side * 6.26, 0.018, cz);
      walk.receiveShadow = true;
      this.group.add(walk);
      this.addBox(CX + side * 5.12, 0.13, cz, 0.20, 0.26, cl, this.mats.concrete, false, 0.7);
      this.addBox(CX + side * 5.26, 0.05, cz, 0.36, 0.10, cl, this.mats.wetCurb, false, 0.8);
      this.addBox(CX + side * 5.00, 0.022, cz, 0.42, 0.05, cl, this.mats.gutter, false, 2.4);
      const dirt = new THREE.Mesh(this._uvPlane(0.85, cl, 1.8), this.mats.dirt || this.mats.asphalt);
      dirt.rotation.x = -Math.PI / 2;
      dirt.position.set(CX + side * 4.59, 0.012, cz);
      dirt.receiveShadow = true;
      this.group.add(dirt);
    }

    // Suq alley strip + gutters/walk edges.
    const suq = new THREE.Mesh(this._uvPlane(8, 70, 1.85), this.mats.asphalt);
    suq.rotation.x = -Math.PI / 2;
    suq.position.set(SUQ_X, 0.008, 43);
    suq.receiveShadow = true;
    this.group.add(suq);
    for (const side of [-1, 1]) {
      this.addBox(SUQ_X + side * 3.5, 0.022, 43, 0.40, 0.05, 70, this.mats.gutter, false, 2.4);
      const walk = new THREE.Mesh(this._uvPlane(0.72, 70, 1.65), this.mats.concrete);
      walk.rotation.x = -Math.PI / 2;
      walk.position.set(SUQ_X + side * 3.62, 0.016, 43);
      walk.receiveShadow = true;
      this.group.add(walk);
    }

    // Warm slab variant for the big open grounds: plain white concrete over
    // these areas picks up blue sky ambient and reads untextured from afar.
    if (!this.mats.slabWarm) {
      const m = this.mats.concrete.clone();
      m.color.setHex(0xc2aa82);
      m.envMapIntensity = 0.08;
      this.mats.slabWarm = m;
    }

    // Market plaza slab — a distinct tile so Mid reads as plaza underfoot.
    const plaza = new THREE.Mesh(this._uvPlane(28, 18, 2.6), this.mats.slabWarm);
    plaza.rotation.x = -Math.PI / 2;
    plaza.position.set(7, 0.021, 49);
    plaza.receiveShadow = true;
    this.group.add(plaza);

    // Spawn yard slab (east of the Main asphalt) + extract forecourt slab
    // + the Suq→forecourt jog.
    const yard = new THREE.Mesh(this._uvPlane(17, 8.4, 1.7), this.mats.slabWarm);
    yard.rotation.x = -Math.PI / 2;
    yard.position.set(12.6, 0.014, 3.9);
    yard.receiveShadow = true;
    this.group.add(yard);
    /* Soften the street/yard slab seam — yard camera sits on it and the
     * pale rectangle read as a lightmap cut behind the viewmodel. */
    const seam = new THREE.Mesh(this._uvPlane(7.6, 10.4, 2.4), this.mats.dirt || this.mats.asphalt);
    seam.rotation.x = -Math.PI / 2;
    seam.position.set(4.6, 0.017, 5.2);
    seam.receiveShadow = true;
    this.group.add(seam);
    const apron = new THREE.Mesh(this._uvPlane(8.8, 9.6, 1.9), this.mats.asphalt);
    apron.rotation.x = -Math.PI / 2;
    apron.position.set(3.8, 0.019, 5.8);
    apron.receiveShadow = true;
    this.group.add(apron);
    const foreDirt = new THREE.Mesh(this._uvPlane(5.4, 4.2, 2.1), this.mats.dirt || this.mats.asphalt);
    foreDirt.rotation.x = -Math.PI / 2;
    foreDirt.position.set(3.2, 0.020, 6.4);
    foreDirt.receiveShadow = true;
    this.group.add(foreDirt);
    const fore = new THREE.Mesh(this._uvPlane(20.4, 12.4, 1.7), this.mats.slabWarm);
    fore.rotation.x = -Math.PI / 2;
    fore.position.set(2.9, 0.014, 84);
    fore.receiveShadow = true;
    this.group.add(fore);
    const jog = new THREE.Mesh(this._uvPlane(8, 4.6, 1.85), this.mats.asphalt);
    jog.rotation.x = -Math.PI / 2;
    jog.position.set(SUQ_X, 0.008, 80.2);
    jog.receiveShadow = true;
    this.group.add(jog);

    // Slab dressing: sand drifts + debris so the plaza/yard/forecourt planes
    // carry the same lower-third breakup as the street, plus contact pools
    // where the slabs meet the block walls.
    const drifts = [
      [1.5, 43.5, 2.6, 1.7, 0.4], [13.5, 47.0, 2.0, 1.3, 1.8], [-3.5, 53.5, 3.0, 1.9, 0.9],
      [17.5, 55.0, 2.3, 1.5, 2.6], [9.0, 2.5, 2.4, 1.6, 0.7], [16.5, 5.5, 1.9, 1.2, 1.5],
      [4.4, 6.2, 2.8, 1.8, 0.9], [5.8, 4.6, 2.2, 1.5, 2.2], [3.4, 5.4, 1.9, 1.3, 1.4],
      [-2.0, 82.0, 2.7, 1.8, 0.3], [8.5, 86.5, 2.1, 1.4, 2.1], [4.5, 81.0, 1.7, 1.1, 1.2],
      /* Blotches straddling the street->forecourt slab seam (z 77.8) so the
       * plane transition reads as drifted sand, not a polygon edge (fix 10). */
      [0.8, 77.6, 2.9, 1.6, 0.6], [5.4, 78.3, 2.2, 1.4, 2.3], [-3.2, 78.0, 2.4, 1.5, 1.1],
      [2.2, 76.9, 1.8, 1.2, 1.9],
    ];
    for (const [x, z, sx, sz, r] of drifts) this._push(this.q.drift, x, 0.026, z, 0, r, 0, sx, 1, sz);
    this._contactAt(7, 40.6, 12, 0.9);
    this._contactAt(7, 57.4, 12, 0.9);
    this._contactAt(-6.4, 49, 0.9, 14);
    this._contactAt(20.4, 49, 0.9, 14);
    this._contactAt(12.6, 0.6, 14, 0.9);
    this._contactAt(2.9, 89.4, 16, 0.9);
    this._contactAt(2.9, 77.8, 16, 0.8);

    const bed = this.addBox(7, -0.5, WORLD.LENGTH * 0.5, 60, 1, WORLD.LENGTH + 40, this.mats.asphalt, true, 6);
    bed.castShadow = false;
  }

  _uvPlane(w, h, tile) {
    const g = new THREE.PlaneGeometry(w, h);
    const pos = g.attributes.position;
    const uv = g.attributes.uv;
    for (let i = 0; i < pos.count; i++) {
      uv.setXY(i, (pos.getX(i) + w * 0.5) / tile, (pos.getY(i) + h * 0.5) / tile);
    }
    g.setAttribute('uv2', uv.clone());
    return g;
  }

  _streetDress(rng) {
    /* c32: delete the lane-dash column. Even dirtied #5a4a24 rendered as
     * 37/33/25 black dominoes (scope 935-1000,570-880); Dust/Inferno
     * streets have no markings. Empty q.dash = no instanced mesh. */

    /* Manhole cylinders read as levitating grey discs (scope ~1130,650).
     * Stamp flush dirt instead — same spot, no rim gap. */
    for (const z of [8, 47, 62]) {
      this._push(this.q.contact, CX + (z % 20 < 10 ? -1.1 : 1.2), 0.008, z, 0, 0.2, 0, 0.55, 1, 0.55);
    }

    for (const side of [-1, 1]) {
      for (let z = 10; z < 76; z += 11) {
        const d = new THREE.Mesh(this.geo.drain, this.mats.darkMetal);
        d.position.set(CX + side * 4.85, 0.032, z + rng() * 2.4);
        d.receiveShadow = true;
        this.group.add(d);
      }
      for (let z = 12; z < 74; z += 15) {
        const d = new THREE.Mesh(this.geo.drain, this.mats.darkMetal);
        d.position.set(SUQ_X + side * 3.3, 0.032, z + rng() * 2.6);
        d.receiveShadow = true;
        this.group.add(d);
      }
    }

    const stains = [
      [0.18, 12.25, 0.85, 0.45],
      [0.22, 53.15, 0.70, 0.38],
    ];
    for (const [x, z, sx, sz] of stains) this._mirror(x, z, sx, sz, rng);

    const drifts = [
      [1.6, 8.4, 1.2, 0.45], [-1.8, 14.2, 1.1, 0.40],
      [-1.4, 29.5, 0.9, 0.35], [-0.8, 47.2, 1.0, 0.38],
      [1.5, 56.8, 1.1, 0.40], [-1.6, 68.4, 1.2, 0.45],
      [2.2, 18.8, 0.8, 0.32], [-2.4, 41.2, 0.85, 0.30],
    ];
    for (const [x, z, sx, sz] of drifts) {
      this._push(this.q.drift, x, 0.014, z, 0, rng() * 1.2, 0, sx, 1, sz);
    }
    for (const z of [3.2, 6.6, 11.8, 18.4, 27.6, 35.8, 47.2, 61.4, 74.0]) {
      this._push(this.q.contact, 0.62, 0.013, z, 0, 0.08, 0, 0.32, 1, 2.6);
      this._push(this.q.contact, -0.58, 0.013, z + 1.1, 0, -0.06, 0, 0.30, 1, 2.2);
    }

    const soaks = [
      [0.18, 2.55, 0.55, 0.32],
    ];
    const soakMat = this._groundDirtMat();
    for (const [x, z, sx, sz] of soaks) {
      const s = new THREE.Mesh(this.geo.puddle, soakMat);
      s.position.set(x, 0.011, z);
      s.scale.set(sx, 1, sz);
      s.rotation.y = (rng() - 0.5) * 0.8;
      s.receiveShadow = true;
      this.group.add(s);
    }

    const extractWet = [
      [0.18, 71.85, 0.65, 0.40],
    ];
    for (const [x, z, sx, sz] of extractWet) {
      const p = new THREE.Mesh(this.geo.puddle, this._groundDirtMat());
      p.position.set(x, 0.011, z);
      p.scale.set(sx, 1, sz);
      p.rotation.y = (rng() - 0.5) * 0.8;
      p.receiveShadow = true;
      this.group.add(p);
    }

    /* Extract approach ground interest (fix 10, c19): sand drifts hugging
     * both gutters, a worn foot-path streak wandering up the middle of the
     * lane, and scattered rubble chips — the (300-1300, 700-900) rect was
     * one uninterrupted asphalt sheet. */
    const exDrifts = [
      [-2.6, 64.5, 1.9, 1.1, 0.5], [2.8, 66.8, 2.3, 1.3, 1.7],
      [-1.2, 69.5, 1.5, 0.9, 2.4], [3.4, 71.5, 1.8, 1.1, 0.9],
      [-3.0, 73.0, 2.5, 1.4, 1.3], [1.6, 74.8, 1.6, 1.0, 0.2],
    ];
    for (const [x, z, sx, sz, r] of exDrifts) {
      this._push(this.q.drift, x, 0.018, z, 0, r, 0, sx, 1, sz);
    }
    for (let z = 62.5; z < 77; z += 1.35) {
      const wob = Math.sin(z * 0.9) * 0.8;
      this._push(this.q.contact, 0.35 + wob, 0.015, z, 0, Math.sin(z) * 0.3, 0, 0.55, 1, 1.5);
    }

    for (const z of [11.2, 15.1, 31.8, 73.2]) {
      for (const side of [-1, 1]) {
        const strip = new THREE.Mesh(this.geo.puddle, this.mats.gutter);
        strip.position.set(CX + side * 4.3, 0.017, z);
        strip.scale.set(0.55, 1, 1.85);
        strip.receiveShadow = true;
        this.group.add(strip);
      }
    }

    const oils = [
      [0.18, 2.85, 0.32],
    ];
    for (const [x, z, s] of oils) {
      const o = new THREE.Mesh(this.geo.puddle, this._groundDirtMat());
      o.position.set(x, 0.011, z);
      o.scale.set(s, 1, s * 0.7);
      o.rotation.y = rng() * 1.4;
      o.receiveShadow = true;
      this.group.add(o);
    }
  }

  _mirror(x, z, sx, sz, rng) {
    const dirt = this._groundDirtMat();
    const p = new THREE.Mesh(this.geo.puddle, dirt);
    p.position.set(x, 0.011, z);
    p.scale.set(sx, 1, sz);
    p.rotation.y = (rng() - 0.5) * 0.7;
    p.receiveShadow = true;
    this.group.add(p);
    const p2 = new THREE.Mesh(this.geo.puddle, dirt);
    p2.position.set(x + (rng() - 0.5) * 1.2, 0.010, z + (rng() - 0.5) * 0.9);
    p2.scale.set(sx * 0.52, 1, sz * 0.58);
    p2.rotation.y = rng() * 2.2;
    p2.receiveShadow = true;
    this.group.add(p2);
  }

  _endcaps(rng) {
    /* Split the yard south wall into 4 building-width runs so it no longer
     * reads as one elephant-skin slab (c24). Collision stays solid. */
    const bays = [
      { x: -7.65, w: 5.1 }, { x: -2.55, w: 5.1 },
      { x: 2.55, w: 5.1 }, { x: 7.65, w: 5.1 },
    ];
    for (const b of bays) {
      const lot = { x: b.x, z: -4.15 };
      this.addBox(b.x, 6.6, -4.15, b.w, 13.2, 6.2, this._plasterOf(lot), true, this._plasterTileOf(lot));
      this._stringCourse(b.x, 3.35, -1.05, b.w * 0.96, 0.16, 0.34, 1.0);
      this._stringCourse(b.x, 6.55, -1.02, b.w * 0.96, 0.15, 0.32, 1.0);
      this.addBox(b.x, 0.48, -1.00, b.w * 0.98, 0.96, 0.20, this._dirtBand(), false, 0.7);
      this.addBox(b.x, 12.55, -1.00, b.w * 0.98, 0.38, 0.16, this._dirtBand(), false, 0.6);
    }
    this._stainDecal('stainD', -4.4, 2.55, -0.96, 0.85, 1.85, 0);
    this._stainDecal('stainD', 2.4, 2.50, -0.96, 0.78, 1.70, 0);
    this._stainDecal('stainD', 0.7, 2.48, -0.96, 0.72, 1.60, 0);
    this._stainDecal('stainC', -0.6, 1.8, -0.96, 0.55, 1.85, 0);
    /* Maroon east bay (cut/yard end-wall) — door + windows so it is not a slab. */
    this._simpleWindow(7.15, 2.25, -1.02, 1, true, Math.PI * 0.5);
    this._simpleWindow(8.15, 5.55, -1.02, 1, false, Math.PI * 0.5);
    this.addBox(7.65, 1.18, -0.78, 0.95, 2.28, 0.28, this.mats.darkMetal, false, 1);
    this.addBox(7.65, 1.12, -0.62, 0.72, 2.05, 0.10, this.col.door, false, 1);
    this.addBox(7.65, 2.38, -0.58, 0.58, 0.10, 0.08, this.col.mull, false, 1);
    this.addBox(7.65, 0.22, -0.70, 1.05, 0.16, 0.36, this.col.sill, false, 1);
    this.addBox(0, 13.45, -4.15, 21.1, 0.55, 6.8, this.col.trim || this.mats.concrete, false, 1.4);
    this.addBox(0, 12.95, -1.0, 20.8, 0.28, 0.42, this.mats.darkMetal, false, 1.2);
    this.addBox(-6.4, 6.6, -1.15, 0.42, 13.0, 0.42, this._plasterOf({ x: -6.4, z: -1.15 }), false, 2.2);
    this.addBox(6.4, 6.6, -1.15, 0.42, 13.0, 0.42, this._plasterOf({ x: 6.4, z: -1.15 }), false, 4.8);
    this.addBox(0, 0.28, -1.05, 14.8, 0.36, 0.38, this.col.trim || this.mats.concrete, false, 1.15);
    this._push(this.q.arch, -2.2, 1.15, -0.72, 0, 0, 0, 1.1, 1.05, 1);
    this._push(this.q.arch, 2.2, 1.15, -0.72, 0, 0, 0, 1.1, 1.05, 1);
    this._push(this.q.archFill, -2.2, 1.15, -0.72, 0, 0, 0, 1.1, 1.05, 1);
    this._push(this.q.archFill, 2.2, 1.15, -0.72, 0, 0, 0, 1.1, 1.05, 1);
    this._push(this.q.archGlass, -2.2, 1.15, -0.72, 0, 0, 0, 1.1, 1.05, 1);
    this._push(this.q.archGlass, 2.2, 1.15, -0.72, 0, 0, 0, 1.1, 1.05, 1);

    const faceZ = -1.02;
    this._shopOnZ(0, faceZ, 1, rng);
    const capWins = [
      [-3.2, 2.25, true], [3.2, 2.25, true],
      [-2.4, 6.15, true], [2.4, 6.15, true],
    ];
    for (const [x, y, lit] of capWins) {
      this._simpleWindow(x, y, faceZ, 1, lit, Math.PI * 0.5);
    }
    this._parapetKit(0, 13.2, -1.05, 1, 9.5, rng, Math.PI * 0.5);
    this._roofKit(0, 13.2, -4.2, 8, 4, rng, true);
    this.addCyl(-7.8, 1.2, -1.2, 0.07, 2.4, this.mats.darkMetal, false);
    this.addCyl(7.8, 1.2, -1.2, 0.07, 2.4, this.mats.darkMetal, false);
    this._queueWindow(-4.6, 4.85, -1.02, 1, true, rng, Math.PI * 0.5);
    this._queueWindow(-3.3, 4.85, -1.02, 1, false, rng, Math.PI * 0.5);
    this._queueWindow(3.2, 7.15, -1.02, 1, true, rng, Math.PI * 0.5);
    this._queueWindow(4.5, 7.15, -1.02, 1, false, rng, Math.PI * 0.5);
    this.addCyl(-3.2, 1.15, -0.85, 0.06, 2.3, this.mats.darkMetal, false);
    this.addCyl(-3.05, 1.15, -0.85, 0.045, 2.3, this.mats.darkMetal, false);
    this.addBox(0, 3.02, -0.52, 0.55, 0.22, 0.1, this.mats.darkMetal, false, 1);
    this.addBox(0, 3.02, -0.4, 0.28, 0.08, 0.05, this.mats.metal, false, 1);
    this._queueWindow(-2.05, 3.15, -1.02, 1, true, rng, Math.PI * 0.5);
    this.addCyl(-2.05, 3.52, -0.5, 0.32, 0.08, this.mats.metal, false);
    this._point(0xc47840, 0.55, 5.5, 0, 2.85, 0.35);

    // North cap extension across the yard's Suq half — two tints, not one ochre.
    this.addBox(13.6, 5.8, -4.15, 7.6, 11.6, 6.2, this._plasterOf({ x: 13.6, z: -4 }), true, this._plasterTileOf({ x: 13.6, z: -4 }));
    this.addBox(20.2, 5.8, -4.15, 5.6, 11.6, 6.2, this._plasterOf({ x: 20.2, z: -4 }), true, this._plasterTileOf({ x: 20.2, z: -4 }));
    this.addBox(16.4, 11.85, -4.15, 13.8, 0.5, 6.8, this.col.trim || this.mats.concrete, false, 1.4);
    this.addBox(16.4, 11.4, -1.0, 13.5, 0.26, 0.4, this.mats.darkMetal, false, 1.2);
    this._stringCourse(16.4, 3.2, -1.02, 12.4, 0.14, 0.30, 1.0);
    this.addBox(16.4, 0.40, -0.92, 13.2, 0.80, 0.16, this._dirtBand(), false, 0.7);
    this._stainDecal('stainD', 13.2, 2.8, -0.98, 1.4, 2.2, 0);
    this._stainDecal('stainC', 18.4, 3.4, -0.98, 1.5, 2.0, 0);
    this._stainDecal('stainD', 15.6, 2.05, -0.96, 1.6, 2.2, 0);
    for (const [x, y, lit] of [[12.6, 2.25, true], [16.2, 2.25, false], [19.6, 2.25, true], [14.4, 5.6, true], [18.2, 5.6, false]]) {
      this._simpleWindow(x, y, -1.02, 1, lit, Math.PI * 0.5);
    }
    this._awningZ(15.2, 3.24, -1.02, 1, 4.6, 1.4, this.col.awnG);
    this._roofKit(16.4, 11.6, -4.2, 5.5, 2.6, rng, true);

    // Yard east wall (x = 21 face) closes the spawn yard.
    this.addBox(21.9, 4.1, 3.6, 2.2, 8.2, 9.4, this._plasterOf({ x: 21.9, z: 3.6 }), true, this._plasterTileOf({ x: 21.9, z: 3.6 }));
    this.addBox(21.9, 8.35, 3.6, 2.7, 0.5, 9.9, this.mats.concrete, false, 1.3);
    this.addBox(20.82, 0.46, 3.6, 0.18, 0.92, 9.2, this._dirtBand(), false, 0.7);
    this.addBox(20.82, 7.85, 3.6, 0.16, 0.36, 9.2, this._dirtBand(), false, 0.6);
    this._simpleWindow(20.78, 2.3, 2.2, -1, true, 0);
    this._simpleWindow(20.78, 2.3, 5.6, -1, false, 0);
    this._simpleWindow(20.78, 5.4, 3.9, -1, true, 0);
    this._stainDecal('stainD', 20.76, 1.85, 3.4, 0.70, 1.75, -Math.PI * 0.5);
    this._stainDecal('stainD', 20.76, 1.70, 5.2, 0.65, 1.60, -Math.PI * 0.5);
    this._stainDecal('stainB', 20.76, 0.55, 4.6, 2.2, 0.85, -Math.PI * 0.5);

    this.addBox(-6.2, 7.8, 94.4, 10.1, 15.6, 7.2, this._plasterOf({ x: -6.2, z: 94 }), true, this._plasterTileOf({ x: -6.2, z: 94 }));
    this.addBox(6.2, 7.8, 94.4, 10.1, 15.6, 7.2, this._plasterOf({ x: 6.2, z: 94 }), true, this._plasterTileOf({ x: 6.2, z: 94 }));
    this.addBox(-6.2, 0.48, 90.82, 9.8, 0.96, 0.20, this._dirtBand(), false, 0.7);
    this.addBox(6.2, 0.48, 90.82, 9.8, 0.96, 0.20, this._dirtBand(), false, 0.7);
    this.addBox(-6.2, 15.15, 90.82, 9.8, 0.40, 0.16, this._dirtBand(), false, 0.6);
    this.addBox(6.2, 15.15, 90.82, 9.8, 0.40, 0.16, this._dirtBand(), false, 0.6);
    this.addBox(0, 15.85, 94.4, 23.2, 0.52, 7.8, this.mats.concrete, false, 1.4);
    this.addBox(0, 15.3, 90.85, 22.8, 0.3, 0.4, this.mats.concrete, false, 1.2);
    const ez = 90.85;
    this.addBox(0, 2.7, ez + 0.12, 7.2, 5.2, 0.22, this.mats.darkMetal, true, 1.3);
    this.addBox(0, 5.45, ez + 0.02, 7.6, 0.18, 0.36, this.mats.concrete, false, 1.2);
    this.addBox(-3.7, 2.7, ez + 0.02, 0.22, 5.3, 0.28, this.mats.concrete, false, 1);
    this.addBox(3.7, 2.7, ez + 0.02, 0.22, 5.3, 0.28, this.mats.concrete, false, 1);
    this._push(this.q.arch, -2.4, 1.35, ez - 0.15, 0, Math.PI, 0, 1.15, 1.1, 1);
    this._push(this.q.arch, 2.4, 1.35, ez - 0.15, 0, Math.PI, 0, 1.15, 1.1, 1);
    this._push(this.q.archFill, -2.4, 1.35, ez - 0.42, 0, Math.PI, 0, 1.12, 1.08, 1);
    this._push(this.q.archFill, 2.4, 1.35, ez - 0.42, 0, Math.PI, 0, 1.12, 1.08, 1);
    this._archDoor(-2.4, 1.35, ez);
    this._archDoor(2.4, 1.35, ez);
    /* Mulls deleted — they read as bright tan planks floating in the arches. */
    for (let i = -5; i <= 5; i++) {
      this.addBox(i * 0.58, 2.7, ez + 0.22, 0.06, 4.9, 0.06, this.mats.metal, false, 1);
    }
    this.addBox(0, 6.6, ez + 0.28, 0.28, 0.08, 0.05, this.mats.metal, false, 1);
    for (let f = 0; f < 3; f += 2) {
      for (const c of [-3, 3]) {
          this._simpleWindow(c * 2.2, 5.4 + f * 2.65, ez, -1, true, Math.PI * 0.5);
      }
    }
    this._parapetKit(0, 15.6, 90.85, -1, 10, rng, Math.PI * 0.5);
    this._roofKit(0, 15.6, 94.4, 9, 4.5, rng, true);
    this._chimney(-8.4, 15.6, 91.0);
    this._antenna(-7.6, 15.6, 91.4, 1.6);
    this._point(0xc48848, 0.62, 6, 0.15, 3.2, 86.2);

    // South cap extension behind the forecourt's east half.
    this.addBox(17.4, 6.6, 94.4, 12.2, 13.2, 7.2, this._plasterOf({ x: 17.4, z: 94 }), true, this._plasterTileOf({ x: 17.4, z: 94 }));
    this.addBox(17.4, 13.45, 94.4, 12.8, 0.5, 7.8, this.mats.concrete, false, 1.4);
    this._simpleWindow(9.4, 5.4, ez, -1, true, Math.PI * 0.5);
    this._simpleWindow(9.4, 10.7, ez, -1, false, Math.PI * 0.5);
    this._stainDecal('stainB', 8.2, 2.4, 90.72, 3.4, 2.4, Math.PI);
    this._roofKit(17.4, 13.2, 94.4, 5, 2.6, rng, true);
  }

  // Wall across z = 8 with two door-width gates (Main + Suq). Kills every
  // straight sightline from the lanes into the spawn yard.
  _spawnWall(rng) {
    const z = 8;
    const runs = [
      /* [7.6, 6.4] ended at x=10.8; next run starts at 11.5 — a 0.70m
       * crack that was not a gate. Widen to meet 11.5 and seal it. */
      [-6, 2.0], [1.2, 6.4], [7.95, 7.1], [13.5, 4.0], [19.75, 2.5],
    ];
    for (const [cx, w] of runs) {
      const lot = { x: cx, z };
      this.addBox(cx, 1.62, z, w, 3.24, 0.6, this._plasterOf(lot), true, this._plasterTileOf(lot));
      this._stringCourse(cx, 3.36, z, w + 0.18, 0.22, 0.78, 1.05);
      this.addBox(cx, 0.42, z - 0.28, w * 0.96, 0.84, 0.16, this._dirtBand(), false, 0.65);
    }
    for (const gx of [-3.5, 17]) {
      this.addBox(gx - 1.62, 1.62, z, 0.30, 3.24, 0.68, this.mats.concrete, true, 1);
      this.addBox(gx + 1.62, 1.62, z, 0.30, 3.24, 0.68, this.mats.concrete, true, 1);
      this.addBox(gx, 3.32, z, 3.62, 0.52, 0.72, this._plasterOf({ x: gx, z }), true, 2.4);
      this.addBox(gx, 3.64, z, 3.92, 0.2, 0.92, this.mats.concrete, false, 1.2);
      this._push(this.q.arch, gx, 1.42, z - 0.28, 0, 0, 0, 1.28, 1.16, 1);
      this._push(this.q.arch, gx, 1.42, z + 0.28, 0, Math.PI, 0, 1.28, 1.16, 1);
      /* Through-depth jamb: the same ring stretched across the wall so the
       * gate intrados is a real curved soffit, not two cards (fix 9). */
      this._push(this.q.arch, gx, 1.42, z, 0, 0, 0, 1.22, 1.11, 2.6);
      this._contactAt(gx, z, 2.4, 1.1);
    }
    this._stainDecal('stainB', 4.2, 1.5, z - 0.32, 3.4, 1.9, Math.PI);
    this._stainDecal('stainC', 10.6, 2.1, z - 0.32, 1.8, 2.6, Math.PI);
    this._stainDecal('stainA', 8.2, 1.7, z + 0.32, 2.8, 2.2, 0);
    this._junctionBox(11.8, 1.9, z - 0.35, Math.PI);
  }

  _shopOnZ(x, faceZ, face, rng) {
    this.addBox(x - 1.15, 1.18, faceZ + face * 0.32, 0.95, 2.32, 0.55, this.mats.darkMetal, false, 1);
    this.addBox(x - 1.15, 1.18, faceZ + face * 0.12, 0.95, 2.05, 0.42, this.col.dimRoom || this.mats.darkRoom, false, 1);
    this.addBox(x - 1.15, 1.12, faceZ + face * 0.32, 0.72, 1.65, 0.16, this.col.warmIn || this.mats.interior, false, 1);
    this.addBox(x - 1.15, 1.12, faceZ + face * 0.62, 0.64, 1.85, 0.06, this.col.pane || this.mats.windowDark, false, 1);
    this.addBox(x - 1.44, 1.12, faceZ + face * 0.58, 0.08, 2.02, 0.1, this.col.mull, false, 1);
    this.addBox(x - 0.86, 1.12, faceZ + face * 0.58, 0.08, 2.02, 0.1, this.col.mull, false, 1);
    this.addBox(x - 1.15, 2.08, faceZ + face * 0.58, 0.7, 0.08, 0.1, this.col.mull, false, 1);
    this.addBox(x - 1.15, 0.22, faceZ + face * 0.58, 0.7, 0.08, 0.1, this.col.mull, false, 1);
    this.addBox(x - 0.92, 1.08, faceZ + face * 0.62, 0.16, 0.05, 0.08, this.mats.metal, false, 1);
    this._simpleWindow(x + 0.15, 1.92, faceZ, face, true, Math.PI * 0.5);
    this._simpleWindow(x + 2.65, 1.92, faceZ, face, true, Math.PI * 0.5);
    this._awningZ(x, 2.72, faceZ, face, 6.2, 1.45, this.col.awnR);
  }

  _buildings(rng) {
    // West row: unchanged recipe, faces follow INNER = 7 automatically.
    const west = [
      this._lot(-1, 5.0, 6.5, 11.4, 9.4, { brick: false, shop: true }),
      this._lot(-1, 17.4, 7.1, 12.8, 12.6, { brick: false, shop: true }),
      this._lot(-1, 32.0, 6.9, 15.8, 14.2, { brick: false, shop: true }),
      this._lot(-1, 49.0, 7.3, 16.2, 10.0, { brick: false, shop: true }),
      this._lot(-1, 67.6, 7.6, 17.0, 12.8, { brick: false, shop: true }),
      this._lot(-1, 83.5, 7.4, 13.0, 11.0, { brick: false, shop: true }),
    ];
    // Blocks A–D: the solid mass between Main and the Suq. Gaps are Cut A
    // (z 18..22), the plaza (40..58) and Cut B (62..66).
    const blocks = [
      this._lot(1, 13.0, 8, 10.0, 9.2, { xBase: EAST, shop: true }),
      this._lot(1, 31.0, 8, 18.0, 11.4, { xBase: EAST, shop: true }),
      this._lot(1, 60.0, 8, 4.0, 8.0, { xBase: EAST }),
      this._lot(1, 72.0, 8, 12.0, 10.6, { xBase: EAST, shop: true }),
    ];
    // SE warehouse walls the forecourt's east side past the Suq jog.
    const warehouse = this._lot(1, 85.5, 8, 9.4, 10.4, { xBase: 13, brick: false, warehouse: true });
    for (const lot of west) this._building(lot, rng);
    for (const lot of blocks) {
      this._building(lot, rng);
      this._blockSuqFace(lot, rng);
    }
    this._building(warehouse, rng);
    this._suqEastRow(rng);
  }

  // Dress a block's east face (x = 13, looking into the Suq).
  _blockSuqFace(lot, rng) {
    const faceX = EAST + lot.w;
    const face = 1;
    this._contactAt(faceX + 0.28, lot.z, 0.85, lot.d * 0.92);
    this.addBox(faceX + 0.13, 1.15, lot.z - lot.d * 0.2, 0.08, 1.85, 0.22, this.mats.dirt || this.mats.concrete, false, 0.7);
    this._stainDecal('stainC', faceX + 0.16, 2.35, lot.z + lot.d * 0.18, 1.5, 2.6, -Math.PI * 0.5);
    this._stainDecal('stainB', faceX + 0.16, 0.9, lot.z - lot.d * 0.08, 2.4, 1.3, -Math.PI * 0.5);
    this.addCyl(faceX + 0.10, 1.15, lot.z - lot.d * 0.38, 0.055, 2.2, this.mats.darkMetal, false);
    this._pipeRun(faceX + 0.06, lot.z + lot.d * 0.30, 3.2, 1);
    if (lot.d >= 8) {
      // Ground-floor shop toward the Suq with the signature green awning.
      const doorZ = lot.z - lot.d * 0.12;
      this.addBox(faceX + 0.18, 1.22, doorZ, 0.36, 2.44, 1.18, this.mats.darkMetal, false, 1);
      this.addBox(faceX + 0.34, 1.14, doorZ, 0.08, 2.2, 0.95, this.col.door, false, 1);
      this.addBox(faceX + 0.395, 1.66, doorZ, 0.02, 0.72, 0.60, this.col.doorInset, false, 1);
      this.addBox(faceX + 0.395, 0.68, doorZ, 0.02, 0.80, 0.60, this.col.doorInset, false, 1);
      this.addBox(faceX + 0.22, 2.52, doorZ, 0.20, 0.16, 1.32, this.mats.concrete, false, 1);
      this.addBox(faceX + 0.22, 1.22, doorZ - 0.62, 0.18, 2.44, 0.16, this.mats.concrete, false, 1);
      this.addBox(faceX + 0.22, 1.22, doorZ + 0.62, 0.18, 2.44, 0.16, this.mats.concrete, false, 1);
      this._push(this.q.arch, faceX + 0.55, 1.55, doorZ, 0, 0, 0, 0.85, 0.85, 0.85);
      this._shopPane(faceX, 1.4, lot.z + lot.d * 0.22, face, rng() > 0.4, rng, 'x');
      this._awningX(faceX, 2.76, lot.z + lot.d * 0.05, face, Math.min(lot.d * 0.55, 6.8), 1.45, this.col.awnG);
      this._hangSign(faceX, 3.1, doorZ - 1.2, face, rng);
    } else {
      this._simpleWindow(faceX, 2.05, lot.z, face, rng() > 0.4, 0);
    }
    const floors = Math.max(1, Math.floor((lot.h - 5.2) / 2.8));
    for (let f = 0; f < floors; f++) {
      const wy = 5.6 + f * 2.8;
      if (wy > lot.h - 1.15 || f % 2 === 1) continue;
      this._queueWindow(faceX, wy, lot.z + ((f % 4) < 2 ? 0.2 : -0.2) * lot.d, face, rng() > 0.4, rng, 0);
    }
    this._stringCourse(faceX + 0.10, 4.92, lot.z, 0.20, 0.14, lot.d * 0.985, 1.05);
  }

  // Cheap east row closing the Suq at x = 21 (simple windows only).
  _suqEastRow(rng) {
    const lots = [
      { z: 14, d: 12, h: 9.4 }, { z: 26, d: 12, h: 11.0 },
      { z: 38, d: 12, h: 8.6 }, { z: 50, d: 12, h: 10.2 },
      { z: 62, d: 12, h: 9.0 }, { z: 74.5, d: 13, h: 11.2 },
    ];
    let i = 0;
    for (const r of lots) {
      const x = 23.5;
      const wall = this._plasterOf({ x, z: r.z });
      this.addBox(x, r.h * 0.5, r.z, 5, r.h, r.d, wall, true, this._plasterTileOf({ x, z: r.z }));
      this.addBox(x, r.h + 0.24, r.z, 5.45, 0.48, r.d + 0.45, this.mats.concrete, false, 1.35);
      const faceX = 21;
      const face = -1;
      this.addBox(faceX - 0.16, 0.22, r.z, 0.22, 0.44, r.d * 0.98, this.mats.concrete, false, 1.15);
      this._contactAt(faceX - 0.28, r.z, 0.85, r.d * 0.9);
      this._simpleWindow(faceX, 2.15, r.z - r.d * 0.26, face, rng() > 0.45, 0);
      this._simpleWindow(faceX, 2.15, r.z + r.d * 0.24, face, rng() > 0.45, 0);
      /* Plaza lot (z 50): the y 5.35 pane-sill was the remaining E5
       * rifle tangent (market 1032-1056,395). Raise + slide north. */
      const midY = r.z === 50 ? 6.15 : 5.35;
      const midZ = r.z === 50 ? r.z + r.d * 0.20 : r.z - r.d * 0.06;
      this._simpleWindow(faceX, midY, midZ, face, rng() > 0.5, 0);
      if (r.h > 9.6) this._simpleWindow(faceX, 8.0, r.z + r.d * 0.18, face, rng() > 0.5, 0);
      if (i % 2 === 0) {
        this._awningX(faceX, 2.76, r.z + r.d * 0.02, face, Math.min(r.d * 0.5, 5.6), 1.35, this.col.awnG);
        this.addBox(faceX - 0.34, 1.14, r.z - r.d * 0.33, 0.08, 2.2, 0.95, this.col.door, false, 1);
        this.addBox(faceX - 0.22, 2.34, r.z - r.d * 0.33, 0.18, 0.16, 1.22, this.mats.concrete, false, 1);
      } else {
        this._stainDecal('stainA', faceX - 0.16, 2.2, r.z + r.d * 0.3, 1.9, 3.1, Math.PI * 0.5);
      }
      if (i === 1 || i === 4) this._parapetKit(faceX, r.h, r.z, face, r.d * 0.6, rng, 0);
      else this._antenna(x, r.h, r.z - r.d * 0.15, 1.5);
      if (i === 2) this._acHang(faceX - 0.45, 3.4, r.z + 1.4, Math.PI * 0.5);
      i++;
    }
  }

  _plasterOf(lot) {
    const set = this._plasters || [
      this.mats.plaster,
      this.mats.plasterSand || this.mats.plaster,
      this.mats.plasterRose || this.mats.plaster,
      this.mats.plasterOchre || this.mats.plaster,
    ];
    return set[Math.abs((lot.z * 3 + lot.x * 7) | 0) % set.length];
  }

  _plasterTileOf(lot) {
    const tiles = this._plasterTile || [3.4, 4.8, 2.4, 6.0];
    return tiles[Math.abs((lot.z * 3 + lot.x * 7) | 0) % tiles.length];
  }

  _coneGeo() {
    const g = new THREE.ConeGeometry(0.16, 0.44, 12);
    const pos = g.attributes.position;
    const col = new Float32Array(pos.count * 3);
    for (let i = 0; i < pos.count; i++) {
      const t = (pos.getY(i) + 0.22) / 0.44;
      col[i * 3] = 0.38 + t * 0.28;
      col[i * 3 + 1] = 0.18 + t * 0.12;
      col[i * 3 + 2] = 0.08 + t * 0.05;
    }
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    return g;
  }

  _coneAt(x, z, rng) {
    const r = rng || (() => {
      const h = Math.abs(Math.sin(x * 12.99 + z * 78.23) * 43758.5) % 1;
      return h;
    });
    const a = typeof r === 'function' ? r() : 0.4;
    const b = typeof r === 'function' ? r() : 0.6;
    const tilt = (a - 0.5) * 0.20;
    const yaw = b * 6.2;
    this._push(this.q.cone, x, 0.22, z, tilt, yaw, tilt * 0.45);
    this._push(this.q.coneDirt, x, 0.10, z, Math.PI * 0.5, yaw, 0);
  }

  /* String-course with plaster/stone response + chipped leading edge. */
  _stringCourse(x, y, z, sx, sy, sz, tile = 1.05) {
    this.addBox(x, y, z, sx, sy, sz, this.col.trim || this.col.sill, false, tile);
    const span = Math.max(sx, sz);
    const alongZ = sz >= sx;
    const n = Math.max(4, Math.round(span / 0.62));
    for (let i = 0; i < n; i++) {
      const h = Math.abs(Math.sin((x + i) * 12.99 + (z + y) * 78.23) * 43758.5) % 1;
      if (h < 0.22) continue;
      const t = (i / Math.max(1, n - 1) - 0.5) * span * 0.90;
      const cx = alongZ ? x + (h - 0.5) * sx * 0.42 : x + t;
      const cz = alongZ ? z + t : z + (h - 0.5) * sz * 0.42;
      this.addBox(
        cx, y + sy * 0.48, cz,
        alongZ ? 0.14 + h * 0.12 : 0.22 + h * 0.16,
        0.055 + h * 0.045,
        alongZ ? 0.22 + h * 0.16 : 0.14 + h * 0.12,
        this.col.chipStone || this.mats.concrete, false, 0.55,
      );
    }
  }

  _contactAt(x, z, sx, sz, yaw = 0) {
    this._push(this.q.contact, x, 0.012, z, 0, yaw, 0, sx * 1.05, 1, sz * 1.05);
  }

  _wheelGround(x, z, yaw, lx, lz, scale = 1) {
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    const wx = x + (lx * ca + lz * sa) * scale;
    const wz = z + (-lx * sa + lz * ca) * scale;
    this._push(this.q.contact, wx, 0.012, wz, 0, yaw, 0, 0.72 * scale, 1, 0.55 * scale);
  }

  _uvPart(parent, sx, sy, sz, mat, x, y, z, rx = 0, ry = 0, rz = 0, tile = 1.15) {
    const m = new THREE.Mesh(this._cachedBox(sx, sy, sz, tile), mat);
    m.position.set(x, y, z);
    m.rotation.set(rx, ry, rz);
    m.castShadow = true;
    m.receiveShadow = true;
    parent.add(m);
    return m;
  }

  _awningPanel(span, depth, segs = 3, sagAmt = 0.15) {
    if (!this._awnCache) this._awnCache = new Map();
    const k = `${(span * 10) | 0}_${(depth * 10) | 0}_${segs}_${(sagAmt * 40) | 0}`;
    let g = this._awnCache.get(k);
    if (g) return g;
    g = new THREE.PlaneGeometry(depth, span, 5, segs);
    g.rotateX(-Math.PI / 2);
    const pos = g.attributes.position;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const z = pos.getZ(i);
      const t = (z / span) + 0.5;
      const sag = Math.sin(Math.PI * t) * sagAmt + (0.5 - x / depth) * (sagAmt * 0.3);
      pos.setY(i, -sag);
    }
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    this._awnCache.set(k, g);
    return g;
  }

  _awningX(faceX, y, z, face, span, depth, mat) {
    const cloth = mat || this.col.awnR;
    const geo = this._awningPanel(span, depth, 3);
    const m = new THREE.Mesh(geo, cloth);
    m.position.set(faceX + face * (0.10 + depth * 0.5), y, z);
    m.rotation.y = face > 0 ? 0 : Math.PI;
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    const under = new THREE.Mesh(geo, this.mats.awningUnder || this.col.awnN);
    under.position.copy(m.position);
    under.position.y -= 0.035;
    under.rotation.copy(m.rotation);
    under.castShadow = false;
    under.receiveShadow = true;
    this.group.add(under);
    this.addBox(faceX + face * 0.08, y + 0.02, z, 0.14, 0.10, span + 0.16, this.mats.darkMetal, false, 1);
    for (const t of [-0.40, 0, 0.40]) {
      const zz = z + t * span * 0.40;
      this.addBox(faceX + face * 0.05, y - 0.04, zz, 0.10, 0.16, 0.12, this.mats.darkMetal, false, 1);
      this.addBox(faceX + face * (depth * 0.38), y - 0.03, zz, depth * 0.62, 0.04, 0.06, this.mats.rust, false, 1);
      this.addBox(faceX + face * (depth * 0.78), y - 0.07, zz, 0.05, 0.12, 0.05, this.mats.darkMetal, false, 1);
      this._contactAt(faceX + face * 0.14, zz, 0.28, 0.22);
    }
    this._contactAt(faceX + face * 0.20, z, 0.45, span * 0.7);
  }

  _awningZ(x, y, faceZ, face, span, depth, mat) {
    const cloth = mat || this.col.awnR;
    const geo = this._awningPanel(span, depth, 3);
    const m = new THREE.Mesh(geo, cloth);
    m.position.set(x, y, faceZ + face * (0.10 + depth * 0.5));
    m.rotation.y = face > 0 ? -Math.PI * 0.5 : Math.PI * 0.5;
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    const under = new THREE.Mesh(geo, this.mats.awningUnder || this.col.awnN);
    under.position.copy(m.position);
    under.position.y -= 0.035;
    under.rotation.copy(m.rotation);
    under.castShadow = false;
    under.receiveShadow = true;
    this.group.add(under);
    this.addBox(x, y + 0.02, faceZ + face * 0.08, span + 0.16, 0.10, 0.14, this.mats.darkMetal, false, 1);
    for (const t of [-0.40, 0, 0.40]) {
      const xx = x + t * span * 0.40;
      this.addBox(xx, y - 0.04, faceZ + face * 0.05, 0.12, 0.16, 0.10, this.mats.darkMetal, false, 1);
      this.addBox(xx, y - 0.03, faceZ + face * (depth * 0.38), 0.06, 0.04, depth * 0.62, this.mats.rust, false, 1);
      this.addBox(xx, y - 0.07, faceZ + face * (depth * 0.78), 0.05, 0.12, 0.05, this.mats.darkMetal, false, 1);
      this._contactAt(xx, faceZ + face * 0.14, 0.22, 0.28);
    }
    this._contactAt(x, faceZ + face * 0.20, span * 0.7, 0.45);
  }

  _stallRoof(x, y, z, sx, sz, mat, sagAmt = 0.15) {
    const cloth = mat || this.col.awnG;
    const geo = this._awningPanel(sz, sx, 3, sagAmt);
    const m = new THREE.Mesh(geo, cloth);
    m.position.set(x, y, z);
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    const under = new THREE.Mesh(geo, this.mats.awningUnder || this.col.awnN);
    under.position.set(x, y - 0.04, z);
    under.castShadow = false;
    this.group.add(under);
    for (const [i, j] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
      const px = x + i * sx * 0.42;
      const pz = z + j * sz * 0.42;
      this.addBox(px, y * 0.5, pz, 0.08, y, 0.08, this._mattePostMat(), false, 1);
      /* Plaster/stone capital with a small cornice step (fix 7, c19): the
       * old saturated rust cap-block read as an orange toy brick at the
       * van stop. Two concrete steps — wide abacus over a narrower neck. */
      this.addBox(px, y - 0.035, pz, 0.20, 0.07, 0.20, this._plankMat(0.45), false, 1);
      this.addBox(px, y - 0.095, pz, 0.145, 0.055, 0.145, this._plankMat(0.7), false, 1);
      /* Base plinth + top cap so the bare posts read as set columns (fix 9). */
      this.addBox(px, 0.10, pz, 0.22, 0.20, 0.22, this.mats.concrete, false, 1);
      this.addBox(px, 0.215, pz, 0.16, 0.05, 0.16, this.mats.concrete, false, 1);
      this._contactAt(px, pz, 0.22, 0.22);
    }
    this._contactAt(x, z, sx * 0.65, sz * 0.65);
  }

  _acSeat(x, y, z, along = 0) {
    this.addBox(x, y + 0.08, z, 0.72, 0.18, 0.58, this.mats.darkMetal, false, 0.8);
    this.addBox(x, y + 0.22, z, 0.58, 0.12, 0.46, this.mats.rust, false, 1);
    this._junctionBox(x, y + 0.42, z, along);
    this._contactAt(x, z, 0.55, 0.48);
  }

  /* Dedicated tire rubber (fix 9, c19): darker than trim rubber and with a
   * borrowed asphalt normal so the tread face has relief instead of reading
   * as smooth plastic. Built lazily, shared by every non-wreck wheel. */
  _tireMat() {
    if (!this._tire) {
      const src = this.mats.rubber;
      const t = src && src.clone ? src.clone() : src;
      if (t && t.color) {
        t.color = new THREE.Color(0x141210);
        t.roughness = 0.95;
        const nm = this.mats.asphalt && this.mats.asphalt.normalMap;
        if (nm) {
          t.normalMap = nm;
          t.normalScale = new THREE.Vector2(1.8, 1.8);
        }
        t.needsUpdate = true;
      }
      this._tire = t || this.mats.rubber;
    }
    return this._tire;
  }

  _sidewallMat() {
    if (!this._sidewall) {
      const t = this._tireMat().clone();
      t.color = new THREE.Color(0x1c1a18);
      t.roughness = 0.92;
      this._sidewall = t;
    }
    return this._sidewall;
  }

  _capGlass(mat, cap) {
    const prev = mat.onBeforeCompile;
    mat.onBeforeCompile = (shader) => {
      if (typeof prev === 'function') prev(shader);
      if (!shader.fragmentShader.includes('#include <opaque_fragment>')) return;
      shader.fragmentShader = shader.fragmentShader.replace(
        '#include <opaque_fragment>',
        `outgoingLight = min(outgoingLight, vec3(${cap.toFixed(3)}));\n#include <opaque_fragment>`,
      );
    };
    const key = mat.customProgramCacheKey ? mat.customProgramCacheKey() : 'g';
    mat.customProgramCacheKey = () => `${key}-cap${cap}`;
    mat.needsUpdate = true;
  }

  _cabinMat() {
    if (this._cabin) return this._cabin;
    const m = (this.mats.darkRoom || this.mats.interior).clone();
    m.color = new THREE.Color(0x4a3c30);
    if (m.envMapIntensity != null) m.envMapIntensity = 0.04;
    this._cabin = m;
    return m;
  }

  _hubMat() {
    if (!this._hubSteel) {
      const src = this.mats.darkMetal || this.mats.metal;
      const m = src.clone();
      m.color = new THREE.Color(0x4a5058);
      m.roughness = 0.70;
      m.metalness = 0.42;
      if (m.envMapIntensity != null) m.envMapIntensity = 0.16;
      if (m.map) m.map = null;
      if (m.normalMap) m.normalMap = null;
      if (m.roughnessMap) m.roughnessMap = null;
      if (m.aoMap) m.aoMap = null;
      this._hubSteel = m;
    }
    return this._hubSteel;
  }

  _joistShadeMat() {
    if (this._joistShade) return this._joistShade;
    /* Unlit — a lit Standard clone washed to the same value as the floor
     * (c25 "stripes" / van shadow measured off-frame or vanished in-frame). */
    this._joistShade = new THREE.MeshBasicMaterial({
      color: 0x5a4630,
      transparent: true,
      opacity: 0.30,
      depthWrite: false,
    });
    return this._joistShade;
  }

  _rustVanMat() {
    if (this._rustVan) return this._rustVan;
    const src = this.mats.vanRed || this.col.maroon || this.mats.paint;
    const m = src.clone();
    m.color = new THREE.Color(0x6a4030);
    m.roughness = 0.62;
    m.metalness = 0.08;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.22;
    this._rustVan = m;
    return m;
  }

  _wellFillMat() {
    if (this._wellFill) return this._wellFill;
    const m = (this.mats.darkRoom || this.mats.interior || this.mats.rubber).clone();
    m.color = new THREE.Color(0x2a2218);
    m.roughness = 0.92;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.04;
    this._wellFill = m;
    return m;
  }

  _fenderMat(bodyMat) {
    /* Same color family as the hull — the old roughness-only clone of
     * vanBlack read as a detached pink blob on the rust yard van. */
    return bodyMat;
  }

  _charcoalVanMat() {
    if (this._charcoalVan) return this._charcoalVan;
    /* Map-free dusty charcoal. vanBlack/paint carry SURF_PAINT — brown
     * coat albedo + elongated scratches that read as brushed wood, and
     * color*map turns 0x7a7468 into chocolate (59,34,20 in shade). */
    const m = new THREE.MeshStandardMaterial({
      color: 0x6e6a64,
      roughness: 0.90,
      metalness: 0.04,
      envMapIntensity: 0.18,
    });
    m.onBeforeCompile = (shader) => {
      if (shader.vertexShader.includes('vDustP')) return;
      shader.vertexShader = 'varying vec3 vDustP; varying vec3 vDustN;\n' + shader.vertexShader.replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
         vDustP = (modelMatrix * vec4(position, 1.0)).xyz;
         vDustN = normalize(mat3(modelMatrix) * normal);`,
      );
      shader.fragmentShader = 'varying vec3 vDustP; varying vec3 vDustN;\n' + shader.fragmentShader.replace(
        '#include <opaque_fragment>',
        `float sunD = max(0.0, dot(normalize(vDustN), normalize(vec3(0.84, 0.38, 0.36))));
         outgoingLight *= 0.90 + sunD * 0.10;
         outgoingLight *= mix(vec3(0.70, 0.68, 0.64), vec3(1.0), smoothstep(0.18, 1.55, vDustP.y));
         float grit = fract(sin(dot(vDustP.xz, vec2(9.7, 5.3))) * 61121.1);
         outgoingLight *= 0.86 + grit * 0.10;
         float streak = abs(sin(vDustP.y * 11.0 + vDustP.z * 2.4));
         outgoingLight *= mix(vec3(0.78, 0.76, 0.72), vec3(1.0), smoothstep(0.15, 0.85, streak));
         outgoingLight = min(outgoingLight, vec3(0.50));
         #include <opaque_fragment>`,
      );
    };
    m.customProgramCacheKey = () => 'cv-dust30';
    m.needsUpdate = true;
    this._charcoalVan = m;
    return m;
  }

  _charcoalHullMat() {
    /* Same lit dusty charcoal — do NOT enable vertexColors on the shared
     * body (parts without a color attr go black). Sun-side lift is in the shader. */
    return this._charcoalVanMat();
  }

  _taxiHullMat() {
    if (this._taxiHull) return this._taxiHull;
    /* Map-free worn ochre — sedanTaxi paint bake is traffic-cone orange. */
    const m = new THREE.MeshStandardMaterial({
      color: 0x8a8474,
      roughness: 0.84,
      metalness: 0.03,
      envMapIntensity: 0.10,
    });
    m.onBeforeCompile = (shader) => {
      if (shader.vertexShader.includes('vTaxiP')) return;
      shader.vertexShader = 'varying vec3 vTaxiP; varying vec3 vTaxiN;\n' + shader.vertexShader.replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
         vTaxiP = (modelMatrix * vec4(position, 1.0)).xyz;
         vTaxiN = normalize(mat3(modelMatrix) * normal);`,
      );
      shader.vertexShader = shader.vertexShader.replace(
        'varying vec3 vTaxiP; varying vec3 vTaxiN;',
        'varying vec3 vTaxiP; varying vec3 vTaxiN; varying vec3 vTaxiL;',
      ).replace(
        'vTaxiP = (modelMatrix * vec4(position, 1.0)).xyz;',
        `vTaxiP = (modelMatrix * vec4(position, 1.0)).xyz;
         vTaxiL = position;`,
      );
      shader.fragmentShader = 'varying vec3 vTaxiP; varying vec3 vTaxiN; varying vec3 vTaxiL;\n' + shader.fragmentShader.replace(
        '#include <opaque_fragment>',
        `         float dirt = 1.0 - smoothstep(0.12, 0.42, vTaxiL.y);
         outgoingLight *= mix(vec3(1.0), vec3(0.50, 0.46, 0.40), dirt * 0.72);
         float door = min(abs(vTaxiL.z - 0.38), abs(vTaxiL.z + 0.42));
         float shut = 1.0 - smoothstep(0.018, 0.055, door);
         outgoingLight *= mix(vec3(1.0), vec3(0.38, 0.34, 0.28), shut * 0.88);
         float trunk = 1.0 - smoothstep(0.016, 0.050, abs(vTaxiL.z + 1.52));
         outgoingLight *= mix(vec3(1.0), vec3(0.40, 0.36, 0.30), trunk * 0.80);
         float arch = min(length(vTaxiL.zy - vec2(1.28, 0.20)), length(vTaxiL.zy - vec2(-1.32, 0.20)));
         outgoingLight *= mix(vec3(1.0), vec3(0.42, 0.38, 0.32), (1.0 - smoothstep(0.22, 0.40, arch)) * 0.55);
         float roof = smoothstep(1.02, 1.20, vTaxiL.y);
         outgoingLight *= mix(vec3(0.90, 0.86, 0.78), vec3(1.10, 1.06, 0.96), roof);
         float sideM = smoothstep(0.40, 0.60, abs(vTaxiL.x)) * (1.0 - smoothstep(0.90, 1.12, vTaxiL.y));
         float hoodM = smoothstep(0.58, 0.88, vTaxiL.z) * (1.0 - smoothstep(0.60, 0.86, vTaxiL.y))
                     * (1.0 - smoothstep(0.55, 0.76, abs(vTaxiL.x)));
         outgoingLight *= mix(vec3(1.0), vec3(0.93, 0.918, 0.875), sideM * 0.80);
         float sideDust = (1.0 - smoothstep(0.12, 0.86, vTaxiL.y)) * sideM;
         outgoingLight *= mix(vec3(1.0), vec3(0.66, 0.60, 0.48), sideDust * 0.78);
         float seam = 1.0 - smoothstep(0.006, 0.024, abs(abs(vTaxiL.x) - 0.58));
         outgoingLight *= mix(vec3(1.0), vec3(0.42, 0.38, 0.32), seam * (hoodM + sideM * 0.45) * 0.70);
         float shoulder = 1.0 - smoothstep(0.010, 0.038, abs(vTaxiL.y - 0.54));
         outgoingLight *= mix(vec3(1.0), vec3(0.58, 0.54, 0.46), shoulder * sideM * 0.40);
         float mott = fract(sin(dot(vTaxiP.xz, vec2(12.7, 4.1))) * 43758.5);
         outgoingLight *= 0.92 + mott * 0.06;
         /* Cap first — the old 0.34 glass-cap ran AFTER hood lifts and
          * crushed the crown to one 170 sheet (street 1350-1600,600-660). */
         outgoingLight = min(outgoingLight, vec3(0.340));
         float crease = exp(-vTaxiL.x * vTaxiL.x * 20.0) * hoodM;
         outgoingLight *= mix(vec3(1.0), vec3(1.09, 1.07, 1.03), crease * 0.88);
         float creaseGut = exp(-pow(abs(vTaxiL.x) - 0.18, 2.0) * 16.0) * hoodM;
         outgoingLight *= mix(vec3(1.0), vec3(0.84, 0.81, 0.74), creaseGut * 0.72);
         float cowl = (1.0 - smoothstep(0.020, 0.140, abs(vTaxiL.z - 0.90)))
                    * (1.0 - smoothstep(0.56, 0.80, abs(vTaxiL.x)))
                    * (1.0 - smoothstep(0.58, 0.88, vTaxiL.y));
         outgoingLight *= mix(vec3(1.0), vec3(0.76, 0.72, 0.64), cowl * 0.58);
         float lipDust = smoothstep(1.22, 2.12, vTaxiL.z) * hoodM;
         outgoingLight *= mix(vec3(1.0), vec3(0.82, 0.76, 0.64), lipDust * 0.46);
         /* Street 3/4 hits the LEFT roof face (x~-0.84, y 1.02-1.22) —
          * x-creases are constant there. Pair + header + dust in Y/Z. */
         float roofM = smoothstep(0.96, 1.08, vTaxiL.y)
                     * (1.0 - smoothstep(1.50, 1.85, abs(vTaxiL.z)));
         float yHi = exp(-pow(vTaxiL.y - 1.16, 2.0) * 70.0) * roofM;
         outgoingLight *= mix(vec3(1.0), vec3(1.10, 1.08, 1.03), yHi * 0.90);
         float yGut = exp(-pow(vTaxiL.y - 1.08, 2.0) * 65.0) * roofM;
         outgoingLight *= mix(vec3(1.0), vec3(0.83, 0.80, 0.73), yGut * 0.68);
         float header = (1.0 - smoothstep(0.06, 0.26, abs(vTaxiL.z - 0.48))) * roofM;
         outgoingLight *= mix(vec3(1.0), vec3(0.76, 0.72, 0.64), header * 0.50);
         float roofDust = smoothstep(-0.55, 0.90, vTaxiL.z) * roofM;
         outgoingLight *= mix(vec3(1.0), vec3(0.86, 0.82, 0.72), roofDust * 0.34);
         #include <opaque_fragment>`,
      );
    };
    m.customProgramCacheKey = () => 'taxi-ochre34w';
    this._taxiHull = m;
    return m;
  }

  _taxiCreamMat() {
    if (this._taxiCream) return this._taxiCream;
    const m = new THREE.MeshStandardMaterial({
      color: 0xb8b09a,
      roughness: 0.84,
      metalness: 0.03,
      envMapIntensity: 0.12,
    });
    this._taxiCream = m;
    return m;
  }

  _taxiDirtMat() {
    if (this._taxiDirt) return this._taxiDirt;
    /* Map-free — cloned dirt/gutter carried a regular pebble-dot field that
     * read as perforated speaker-grille rows on the taxi skirt. */
    this._taxiDirt = new THREE.MeshStandardMaterial({
      color: 0x4a3c2c,
      roughness: 0.95,
      metalness: 0.02,
      envMapIntensity: 0.04,
    });
    return this._taxiDirt;
  }

  _offLensMat() {
    if (this._offLens) return this._offLens;
    /* Noon: headlights off — dark glass, no emissive blast. */
    this._offLens = new THREE.MeshStandardMaterial({
      color: 0x3a4046,
      roughness: 0.24,
      metalness: 0.38,
      envMapIntensity: 0.48,
      emissive: 0x000000,
      emissiveIntensity: 0,
    });
    return this._offLens;
  }

  _bezelMat() {
    if (this._bezel) return this._bezel;
    const m = (this.mats.rubber || this.mats.darkMetal).clone();
    m.color = new THREE.Color(0x2a2622);
    m.roughness = 0.88;
    m.metalness = 0.08;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.12;
    this._bezel = m;
    return m;
  }

  _nicheMat() {
    if (this._niche) return this._niche;
    const m = (this.col.dimRoom || this.mats.interior || this.mats.darkRoom).clone();
    m.color = new THREE.Color(0x3a2c1c);
    m.roughness = 0.92;
    m.emissive = new THREE.Color(0x2a1c10);
    m.emissiveIntensity = 0.20;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.08;
    this._niche = m;
    return m;
  }

  _nicheRevealMat() {
    if (this._nicheReveal) return this._nicheReveal;
    const m = (this.mats.darkRoom || this.mats.rubber).clone();
    m.color = new THREE.Color(0x14110e);
    m.roughness = 0.94;
    m.metalness = 0.02;
    if (m.emissive) m.emissive = new THREE.Color(0x080604);
    if (m.emissiveIntensity != null) m.emissiveIntensity = 0.04;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.04;
    this._nicheReveal = m;
    return m;
  }

  _nicheDoorMat() {
    if (this._nicheDoor) return this._nicheDoor;
    const m = (this.mats.wood || this.mats.darkRoom).clone();
    m.color = new THREE.Color(0x4a3826);
    m.roughness = 0.93;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.08;
    this._nicheDoor = m;
    return m;
  }

  _archDoor(x, y, ez) {
    const place = (geo, mat, z, sx, sy) => {
      const m = new THREE.Mesh(geo, mat);
      m.position.set(x, y, z);
      m.rotation.y = Math.PI;
      m.scale.set(sx, sy, 1);
      m.castShadow = false;
      m.receiveShadow = true;
      this.group.add(m);
    };
    /* Dark reveal, then door set back so a gap frame reads around it. */
    place(this.geo.archFill, this._nicheRevealMat(), ez - 0.58, 1.04, 1.00);
    place(this.geo.archFill, this._nicheDoorMat(), ez - 0.88, 0.90, 0.88);
    place(this.geo.archFill, this._nicheMat(), ez - 1.05, 0.82, 0.80);
    for (const t of [-0.22, 0, 0.22]) {
      this.addBox(x + t, y + 0.55, ez - 0.80, 0.035, 1.35, 0.04, this._nicheRevealMat(), false, 1);
    }
  }

  _shadeHullGeo(kind) {
    const src = this._loftHullGeo(kind);
    const g = src.clone();
    const nrm = g.attributes.normal;
    const col = new Float32Array(nrm.count * 3);
    for (let i = 0; i < nrm.count; i++) {
      const nd = nrm.getX(i) * 0.84 + nrm.getY(i) * 0.38 + nrm.getZ(i) * 0.36;
      const v = 0.78 + Math.max(0, nd) * 0.28;
      col[i * 3] = v;
      col[i * 3 + 1] = v * 0.96;
      col[i * 3 + 2] = v * 0.88;
    }
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    return g;
  }

  _groundDirtMat() {
    if (this._dirtContact) return this._dirtContact;
    const c = document.createElement('canvas');
    c.width = c.height = 256;
    const ctx = c.getContext('2d');
    const img = ctx.createImageData(256, 256);
    for (let y = 0; y < 256; y++) {
      for (let x = 0; x < 256; x++) {
        const u = (x - 128) / 128;
        const v = (y - 128) / 128;
        const r = Math.hypot(u * 1.12, v * 0.88);
        const n = Math.abs(Math.sin(x * 0.19) * Math.cos(y * 0.14) + Math.sin((x + y) * 0.08));
        const body = Math.max(0, 1 - r * r);
        const a = body * (0.20 + n * 0.16);
        const i = (y * 256 + x) * 4;
        img.data[i] = 78 + n * 26;
        img.data[i + 1] = 58 + n * 18;
        img.data[i + 2] = 34 + n * 12;
        img.data[i + 3] = Math.min(200, a * 255);
      }
    }
    ctx.putImageData(img, 0, 0);
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = THREE.SRGBColorSpace;
    this._dirtContact = new THREE.MeshBasicMaterial({
      map: t, transparent: true, opacity: 0.82, depthWrite: false, fog: true,
    });
    return this._dirtContact;
  }

  _vehicleAoMat() {
    if (this._aoContact) return this._aoContact;
    const src = this._groundDirtMat();
    const m = src.clone();
    m.opacity = 0.92;
    m.color = new THREE.Color(0x6a5840);
    this._aoContact = m;
    return m;
  }

  _laneMat() {
    if (this._lane) return this._lane;
    /* Fresh matte — cloning mats.lane (0xa09058 r0.52) plus a dark
     * multiply map crushed the dashes to 37/33/25. Dusty warm off-white
     * with worn ends and asphalt holes, slightly lighter than the road. */
    const c = document.createElement('canvas');
    c.width = 32;
    c.height = 128;
    const g = c.getContext('2d');
    g.fillStyle = '#c8b890';
    g.fillRect(0, 0, 32, 128);
    const fade = g.createLinearGradient(0, 0, 0, 128);
    fade.addColorStop(0, 'rgba(110,92,58,0.45)');
    fade.addColorStop(0.16, 'rgba(110,92,58,0)');
    fade.addColorStop(0.84, 'rgba(110,92,58,0)');
    fade.addColorStop(1, 'rgba(110,92,58,0.45)');
    g.fillStyle = fade;
    g.fillRect(0, 0, 32, 128);
    for (let i = 0; i < 90; i++) {
      g.fillStyle = `rgba(92,78,48,${0.10 + (i % 5) * 0.04})`;
      g.fillRect((i * 13) % 32, (i * 17) % 128, 2 + (i % 7), 1 + (i % 4));
    }
    for (let i = 0; i < 18; i++) {
      g.fillStyle = `rgba(72,58,36,${0.35 + (i % 3) * 0.12})`;
      g.fillRect((i * 19) % 28, (i * 37) % 120, 4 + (i % 5), 3 + (i % 4));
    }
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = THREE.SRGBColorSpace;
    this._lane = new THREE.MeshStandardMaterial({
      color: 0xc2b086,
      roughness: 0.94,
      metalness: 0.0,
      envMapIntensity: 0.04,
      map: t,
    });
    return this._lane;
  }

  _dirtBand() {
    if (!this._band) {
      const src = this.mats.dirt || this.mats.plaster;
      const m = src.clone();
      m.color = new THREE.Color(0x6a5438);
      m.roughness = 0.94;
      if (m.envMapIntensity != null) m.envMapIntensity = 0.06;
      this._band = m;
    }
    return this._band;
  }

  _shadeBand() {
    if (!this._shade) {
      const m = this._dirtBand().clone();
      m.color = new THREE.Color(0x5a4a32);
      m.roughness = 0.96;
      if (m.envMapIntensity != null) m.envMapIntensity = 0.03;
      this._shade = m;
    }
    return this._shade;
  }

  _grimeMat() {
    if (this._grime) return this._grime;
    const m = (this.mats.dirt || this.mats.plaster).clone();
    m.color = new THREE.Color(0x3a2c1c);
    m.roughness = 0.96;
    m.transparent = true;
    m.opacity = 0.58;
    m.depthWrite = false;
    if (m.envMapIntensity != null) m.envMapIntensity = 0.03;
    this._grime = m;
    return m;
  }

  /* Shared opacity variants so per-decal opacity doesn't clone a material
   * per mesh. Three tiers is enough to break the "same stamp" read. */
  _stainVariant(kind, op) {
    if (op >= 0.99) return this.mats[kind];
    if (!this._stainVars) this._stainVars = {};
    const key = `${kind}-${op}`;
    if (!this._stainVars[key]) {
      const src = this.mats[kind];
      if (!src) return null;
      const m = src.clone();
      m.opacity = op;
      this._stainVars[key] = m;
    }
    return this._stainVars[key];
  }

  _stainDecal(kind, x, y, z, sx, sy, yaw = 0, pitch = 0) {
    /* c21 fix 3: the same three soot blots stamped at full opacity and near
     * identical scale read as copy-paste. A deterministic per-placement hash
     * varies scale, roll and opacity, and swaps roughly half of the tall
     * A/B blots for streak-style leak decals (stainD). */
    const h = Math.abs(Math.sin(x * 12.9898 + y * 78.233 + z * 37.719) * 43758.5453) % 1;
    const h2 = (h * 97.13) % 1;
    const h3 = (h * 57.29 + 0.31) % 1;
    /* c29: closed-ring A/B blots are gone — force rain streaks. Wide short
     * B stays as the open grime wash (new STAIN_B, no radial ring). */
    if (kind === 'stainA' && this.mats.stainD) {
      kind = 'stainD';
      if (sx >= sy * 0.85) {
        const t = sx;
        sx = Math.min(1.35, sy * 0.85);
        sy = Math.max(1.85, t * 0.90);
      } else {
        sx *= 0.78;
        sy *= 1.12;
      }
    } else if (kind === 'stainB' && sy > sx * 0.72 && h < 0.62 && this.mats.stainD) {
      kind = 'stainD';
      sx *= 0.78;
      sy *= 1.18;
    }
    const s = 0.70 + h2 * 0.32;
    const op = kind === 'stainA' ? 0.40 : (kind === 'stainB' ? 0.44 : 0.48);
    const mat = this._stainVariant(kind, op);
    if (!mat) return;
    if (!this._stainPlane) this._stainPlane = new THREE.PlaneGeometry(1, 1);
    const m = new THREE.Mesh(this._stainPlane, mat);
    m.scale.set(sx * s, sy * s, 1);
    m.position.set(x, y, z);
    m.rotation.y = yaw;
    if (pitch) m.rotation.x = pitch;
    /* Streaks stay near-vertical (gravity); blots can roll freely. */
    m.rotation.z = kind === 'stainD' ? (h3 - 0.5) * 0.10 : (h3 - 0.5) * 0.55;
    m.renderOrder = 3;
    m.castShadow = false;
    m.receiveShadow = false;
    this.group.add(m);
  }

  _building(lot, rng) {
    const plaster = this._plasterOf(lot);
    const wall = lot.brick ? (this._brickBound || this.mats.brick) : plaster;
    const tile = lot.brick ? 2.6 : this._plasterTileOf(lot);
    this.addBox(lot.x, lot.h * 0.5, lot.z, lot.w, lot.h, lot.d, wall, true, tile);
    this.addBox(lot.x + lot.side * (lot.w * 0.5 - 0.06), 0.42, lot.z, 0.18, 0.84, lot.d * 0.98, this.mats.concrete, false, 0.9);

    this.addBox(lot.x, lot.h + 0.28, lot.z, lot.w + 0.55, 0.56, lot.d + 0.55, this.mats.concrete, false, 1.35);
    this.addBox(lot.x, lot.h + 0.02, lot.z, lot.w + 0.22, 0.18, lot.d + 0.22, this.mats.concrete, false, 1.2);

    const face = lot.side < 0 ? 1 : -1;
    const faceX = lot.x + face * (lot.w * 0.5);
    this.addBox(faceX + face * 0.16, 0.22, lot.z, 0.22, 0.44, lot.d * 0.98, this.mats.concrete, false, 1.15);
    this.addBox(faceX + face * 0.20, 0.40, lot.z, 0.10, 0.80, lot.d * 0.96, this._dirtBand(), false, 0.7);
    this._contactAt(faceX + face * 0.28, lot.z, 0.85, lot.d * 0.92);
    for (let i = 0; i < 2; i++) {
      const cz = lot.z - lot.d * 0.38 + i * (lot.d * 0.76 / 4);
      this._push(this.q.chip, faceX + face * 0.18, 0.08 + (i % 2) * 0.06, cz, 0, 0, (i - 2) * 0.15, 0.8 + (i % 3) * 0.2, 0.7, 0.9);
    }
    const colH = 1.15 + ((Math.abs(lot.z * 7.13) % 1) * 1.1);
    this.addBox(faceX + face * 0.12, 1.05, lot.z + (lot.d * 0.18) * (lot.z % 2 < 1 ? 1 : -1), 0.05, colH, 0.10, this.mats.dirt || this.mats.concrete, false, 0.7);
    const stainYaw = face > 0 ? -Math.PI * 0.5 : Math.PI * 0.5;
    this._stainDecal('stainA', faceX + face * 0.16, 1.65, lot.z - lot.d * 0.12, 1.8, 2.4, stainYaw);
    this._stainDecal('stainB', faceX + face * 0.16, 0.75, lot.z + lot.d * 0.08, 2.1, 1.1, stainYaw);

    this.addCyl(faceX + face * 0.10, 1.15, lot.z - lot.d * 0.40, 0.06, 2.2, this.mats.darkMetal, false);
    this.addCyl(faceX + face * 0.10, 1.15, lot.z + lot.d * 0.36, 0.055, 2.1, this.mats.rust, false);

    this.addCyl(faceX + face * 0.16, 1.05, lot.z - lot.d * 0.44, 0.055, 2.1, this.mats.darkMetal, false);
    this.addCyl(faceX + face * 0.16, 1.05, lot.z + lot.d * 0.38, 0.05, 2.0, this.mats.darkMetal, false);

    if (lot.warehouse) this._warehouse(lot, face, faceX, rng);
    else if (lot.shop) this._shopFront(lot, face, faceX, rng);

    const floors = Math.max(1, Math.floor((lot.h - 5.2) / 2.8));
    if (!lot.shop) {
      this._simpleWindow(faceX, 2.15, lot.z - lot.d * 0.18, face, true, 0);
    }
    for (let f = 0; f < floors; f++) {
      const wy = 5.6 + f * 2.8;
      if (wy > lot.h - 1.15 || wy < 5.4) continue;
      if (f % 2 === 1) continue;
      const wz = lot.z + ((f % 4) < 2 ? -0.22 : 0.22) * lot.d;
      this._queueWindow(faceX, wy, wz, face, rng() > 0.4, rng, 0);
    }

    if (!lot.warehouse) {
      const bz = lot.z + lot.d * 0.22;
      this._balcony(faceX, 6.15, bz, face);
    }

    // Thin string-course ledges — plaster/stone, not untextured cream slabs.
    this._stringCourse(faceX + face * 0.10, 4.92, lot.z, 0.20, 0.14, lot.d * 0.985, 1.05);
    /* Edge grime washed down from under each ledge (fix 6). */
    this.addBox(faceX + face * 0.055, 4.62, lot.z, 0.05, 0.42, lot.d * 0.92, this.mats.dirt || this.mats.concrete, false, 0.55);
    if (lot.h > 10.5) {
      this._stringCourse(faceX + face * 0.08, lot.h - 2.55, lot.z, 0.16, 0.12, lot.d * 0.985, 1.05);
      this.addBox(faceX + face * 0.045, lot.h - 2.86, lot.z, 0.04, 0.36, lot.d * 0.92, this.mats.dirt || this.mats.concrete, false, 0.55);
    }

    this._parapetKit(faceX, lot.h, lot.z, face, lot.d * 0.72, rng, 0);
    this._roofKit(lot.x, lot.h, lot.z, lot.w * 0.7, lot.d * 0.55, rng, true);
  }

  /* Windows sit on solid wall boxes — anything pushed *into* the wall is
   * occluded. Interior + glass stay proud of the face; jambs/sill sit
   * further out so the opening reads as a ≥0.15 m reveal. The old plaster
   * recess box was a solid plug in front of the glass (the brown cards). */
  _windowWell(px, y, pz, face, along = 0, lit = false) {
    const nx = face * Math.cos(along);
    const nz = face * Math.sin(along);
    const room = lit ? this.q.interior : this.q.darkRoom;
    /* Seat the well on the wall plane — the old +0.02/+0.08 stack read as
     * a birdhouse box on a post. Solid walls occlude anything pushed in. */
    this._push(room, px - nx * 0.05, y, pz - nz * 0.05, 0, along, 0, 0.62, 1.08, 1.06);
  }

  _simpleWindow(px, y, pz, face, lit, along = 0) {
    const nx = face * Math.cos(along);
    const nz = face * Math.sin(along);
    const tx = -nz;
    const tz = nx;
    this._windowWell(px, y, pz, face, along, lit);
    this._push(this.q.jamb, px + nx * 0.04 + tx * 0.56, y, pz + nz * 0.04 + tz * 0.56, 0, along, 0);
    this._push(this.q.jamb, px + nx * 0.04 - tx * 0.56, y, pz + nz * 0.04 - tz * 0.56, 0, along, 0);
    this._push(this.q.head, px + nx * 0.04, y + 0.72, pz + nz * 0.04, 0, along, 0);
    this._push(this.q.head, px + nx * 0.04, y - 0.72, pz + nz * 0.04, 0, along, 0);
    if (lit) this._push(this.q.glassC, px + nx * 0.01, y, pz + nz * 0.01, 0, along, 0);
    else this._push(this.q.glassD, px + nx * 0.01, y, pz + nz * 0.01, 0, along, 0);
    this._push(this.q.frameH, px + nx * 0.05, y + 0.68, pz + nz * 0.05, 0, along, 0);
    this._push(this.q.frameH, px + nx * 0.05, y - 0.68, pz + nz * 0.05, 0, along, 0);
    this._push(this.q.frameV, px + nx * 0.05 + tx * 0.54, y, pz + nz * 0.05 + tz * 0.54, 0, along, 0);
    this._push(this.q.frameV, px + nx * 0.05 - tx * 0.54, y, pz + nz * 0.05 - tz * 0.54, 0, along, 0);
    this._push(this.q.mullH, px + nx * 0.02, y, pz + nz * 0.02, 0, along, 0);
    this._push(this.q.sill, px + nx * 0.06, y - 0.72, pz + nz * 0.06, 0, along, 0);
    this._push(this.q.grime, px + nx * 0.06, y - 1.08, pz + nz * 0.06, 0, along, 0, 0.90, 1.15, 0.78);
    this._shutterState(px, y, pz, nx, nz, tx, tz, along);
  }

  _shutterState(px, y, pz, nx, nz, tx, tz, along) {
    const h = Math.abs(Math.sin(px * 12.9898 + pz * 78.233 + y * 37.719) * 43758.5453) % 1;
    /* Shutters sit behind the glass (closer to the wall) so pane spec reads. */
    if (h < 0.14) {
      this._push(this.q.blind, px + nx * 0.015, y, pz + nz * 0.015, 0, along, 0, 1, 1, 1);
    } else if (h < 0.36) {
      this._push(this.q.blind, px + nx * 0.015, y + 0.28, pz + nz * 0.015, 0, along, 0, 1, 0.48, 1);
    } else if (h < 0.46) {
      this._push(this.q.curtain, px + nx * 0.015 + tx * 0.22, y, pz + nz * 0.015 + tz * 0.22, 0, along, 0);
    }
  }

  _queueWindow(px, y, pz, face, lit, rng, along = 0, grid3 = false) {
    const roll = rng || (() => 0.4);
    const nx = face * Math.cos(along);
    const nz = face * Math.sin(along);
    const tx = -nz;
    const tz = nx;
    this._windowWell(px, y, pz, face, along, lit);
    this._push(this.q.jamb, px + nx * 0.04 + tx * 0.56, y, pz + nz * 0.04 + tz * 0.56, 0, along, 0);
    this._push(this.q.jamb, px + nx * 0.04 - tx * 0.56, y, pz + nz * 0.04 - tz * 0.56, 0, along, 0);
    this._push(this.q.head, px + nx * 0.04, y + 0.72, pz + nz * 0.04, 0, along, 0);
    this._push(this.q.head, px + nx * 0.04, y - 0.72, pz + nz * 0.04, 0, along, 0);
    if (lit) this._push(this.q.glassC, px + nx * 0.01, y, pz + nz * 0.01, 0, along, 0);
    else this._push(this.q.glassD, px + nx * 0.01, y, pz + nz * 0.01, 0, along, 0);
    this._shutterState(px, y, pz, nx, nz, tx, tz, along);
    this._push(this.q.mullH, px + nx * 0.02, y, pz + nz * 0.02, 0, along, 0);
    this._push(this.q.mullV, px + nx * 0.02, y, pz + nz * 0.02, 0, along, 0);
    this._push(this.q.frameH, px + nx * 0.05, y + 0.68, pz + nz * 0.05, 0, along, 0);
    this._push(this.q.frameH, px + nx * 0.05, y - 0.68, pz + nz * 0.05, 0, along, 0);
    this._push(this.q.frameV, px + nx * 0.05 + tx * 0.54, y, pz + nz * 0.05 + tz * 0.54, 0, along, 0);
    this._push(this.q.frameV, px + nx * 0.05 - tx * 0.54, y, pz + nz * 0.05 - tz * 0.54, 0, along, 0);
    this._push(this.q.sill, px + nx * 0.06, y - 0.72, pz + nz * 0.06, 0, along, 0);
    this._push(this.q.grime, px + nx * 0.06, y - 1.05, pz + nz * 0.06, 0, along, 0, 0.85, 1.05, 0.7);
  }

  _shopPane(x, y, z, face, lit, rng, axis = 'x') {
    const along = axis === 'z' ? Math.PI * 0.5 : 0;
    const nx = face * Math.cos(along);
    const nz = face * Math.sin(along);
    const tx = -nz;
    const tz = nx;
    this.addBox(x - nx * 0.22, y, z - nz * 0.22, along === 0 ? 0.42 : 2.4, 2.15, along === 0 ? 2.4 : 0.42, lit ? (this.col.warmIn || this.mats.interior) : (this.col.dimRoom || this.mats.darkRoom), false, 1);
    this._simpleWindow(x, y, z, face, true, along);
    const goods = [[-0.35, -0.25], [0.28, -0.08]];
    for (const [t, yo] of goods) {
      this.addBox(x - nx * 0.28 + tx * t, y + yo - 0.15, z - nz * 0.28 + tz * t, 0.28, 0.32 + rng() * 0.22, 0.2, this.col.goods, false, 1);
    }
  }

  _shopFront(lot, face, faceX, rng) {
    const doorZ = lot.z + (rng() - 0.5) * lot.d * 0.18;
    this.addBox(faceX + face * 0.18, 1.22, doorZ, 0.36, 2.44, 1.18, this.mats.darkMetal, false, 1);
    this.addBox(faceX + face * 0.34, 1.14, doorZ, 0.08, 2.2, 0.95, this.col.door, false, 1);
    this.addBox(faceX + face * 0.395, 1.66, doorZ, 0.02, 0.72, 0.60, this.col.doorInset, false, 1);
    this.addBox(faceX + face * 0.395, 0.68, doorZ, 0.02, 0.80, 0.60, this.col.doorInset, false, 1);
    this.addBox(faceX + face * 0.395, 0.17, doorZ, 0.02, 0.26, 0.86, this.mats.metal, false, 1);
    this.addBox(faceX + face * 0.42, 1.1, doorZ + 0.28, 0.06, 0.035, 0.16, this.mats.metal, false, 1);
    this.addBox(faceX + face * 0.28, 2.44, doorZ, 0.1, 0.14, 0.7, this.col.pane || this.mats.windowDark, false, 1);
    this.addBox(faceX + face * 0.22, 2.52, doorZ, 0.20, 0.16, 1.32, this.mats.concrete, false, 1);
    this.addBox(faceX + face * 0.22, 1.22, doorZ - 0.62, 0.18, 2.44, 0.16, this.mats.concrete, false, 1);
    this.addBox(faceX + face * 0.22, 1.22, doorZ + 0.62, 0.18, 2.44, 0.16, this.mats.concrete, false, 1);
    this.addBox(faceX + face * 0.20, 0.18, doorZ, 0.22, 0.12, 1.28, this.col.sill, false, 1);
    this._push(this.q.arch, faceX + face * 0.55, 1.55, doorZ, 0, face < 0 ? Math.PI : 0, 0, 0.85, 0.85, 0.85);

    const paneZ = doorZ + (rng() > 0.5 ? 2.15 : -2.15);
    if (Math.abs(paneZ - lot.z) < lot.d * 0.42) {
      this._shopPane(faceX, 1.4, paneZ, face, rng() > 0.28, rng, 'x');
    }
    for (const wz of [lot.z - lot.d * 0.28, lot.z + lot.d * 0.28]) {
      if (Math.abs(wz - doorZ) < 1.5) continue;
      this._queueWindow(faceX, 2.05, wz, face, rng() > 0.35, rng, 0);
    }

    const awnZ = Math.min(lot.d * 0.58, 7.6);
    const awn = rng() > 0.5 ? this.col.awnR : (rng() > 0.5 ? this.col.awnG : this.col.awnN);
    this._awningX(faceX, 2.76, lot.z, face, awnZ, 1.55, awn);
  }

  _warehouse(lot, face, faceX, rng) {
    const doorZ = lot.z + 1.6;
    this.addBox(faceX + face * 0.12, 2.55, doorZ, 0.22, 5.0, 5.8, this.mats.darkMetal, true, 1.3);
    for (let i = -4; i <= 4; i++) {
      this.addBox(faceX + face * 0.22, 2.55, doorZ + i * 0.58, 0.05, 4.7, 0.08, this.mats.metal, false, 1);
    }
    this.addBox(faceX + face * 0.08, 5.15, doorZ, 0.18, 0.16, 6.1, this.mats.concrete, false, 1.2);
    this.addBox(faceX + face * 0.08, 2.55, doorZ - 2.95, 0.16, 5.1, 0.16, this.mats.concrete, false, 1);
    this.addBox(faceX + face * 0.08, 2.55, doorZ + 2.95, 0.16, 5.1, 0.16, this.mats.concrete, false, 1);
    this.addBox(faceX + face * 0.55, 0.32, doorZ, 0.95, 0.64, 6.2, this.mats.concrete, true, 1.6);
    this.addCyl(faceX + face * 0.85, 0.45, doorZ - 3.4, 0.12, 0.9, this.mats.darkMetal, true);
    this.addCyl(faceX + face * 0.85, 0.45, doorZ + 3.4, 0.12, 0.9, this.mats.darkMetal, true);
  }

  _balcony(faceX, y, z, face) {
    const slab = this.mats.balconySlab || this.mats.plaster;
    const lip = this.mats.rust;
    this.addBox(faceX + face * 0.08, y + 0.02, z, 0.18, 0.26, 2.32, lip, false, 1);
    this.addBox(faceX + face * 0.72, y, z, 1.42, 0.16, 2.55, slab, false, 1.05);
    this.addBox(faceX + face * 0.58, y - 0.08, z, 1.08, 0.04, 2.14, this.mats.concrete, false, 1);
    this.addBox(faceX + face * 0.06, y - 0.04, z, 0.10, 0.12, 2.24, this.mats.dirt || this.mats.concrete, false, 0.7);
    this.addBox(faceX + face * 0.42, y - 0.22, z - 0.72, 0.55, 0.08, 0.10, this.mats.rust, false, 1);
    this.addBox(faceX + face * 0.42, y - 0.22, z + 0.72, 0.55, 0.08, 0.10, this.mats.rust, false, 1);
    this.addBox(faceX + face * 0.42, y - 0.22, z, 0.50, 0.07, 0.08, this.mats.rust, false, 1);
    this.addBox(faceX + face * 0.28, y - 0.22, z - 0.72, 0.10, 0.44, 0.10, this.mats.darkMetal, false, 1);
    this.addBox(faceX + face * 0.28, y - 0.22, z + 0.72, 0.10, 0.44, 0.10, this.mats.darkMetal, false, 1);
    this.addBox(faceX + face * 0.28, y - 0.22, z, 0.09, 0.40, 0.09, this.mats.darkMetal, false, 1);
    const rail = this.mats.rust;
    this.addBox(faceX + face * 1.02, y + 0.50, z, 0.05, 0.88, 2.18, rail, false, 1);
    this.addBox(faceX + face * 0.58, y + 0.96, z, 1.05, 0.05, 2.22, rail, false, 1);
    this.addBox(faceX + face * 0.22, y + 0.48, z - 1.05, 0.05, 0.88, 0.05, rail, false, 1);
    this.addBox(faceX + face * 0.22, y + 0.48, z + 1.05, 0.05, 0.88, 0.05, rail, false, 1);
    this.addBox(faceX + face * 0.62, y + 0.48, z - 1.05, 0.72, 0.04, 0.04, rail, false, 1);
    this.addBox(faceX + face * 0.62, y + 0.48, z + 1.05, 0.72, 0.04, 0.04, rail, false, 1);
    this._stainDecal(
      'stainB',
      faceX + face * 0.03,
      y - 0.18,
      z,
      2.15,
      0.62,
      face > 0 ? -Math.PI * 0.5 : Math.PI * 0.5,
    );
    this._stainDecal(
      'stainC',
      faceX + face * 0.04,
      y - 0.55,
      z - 0.35,
      0.55,
      1.25,
      face > 0 ? -Math.PI * 0.5 : Math.PI * 0.5,
    );
    this._stainDecal(
      'stainA',
      faceX + face * 0.04,
      y - 0.62,
      z + 0.42,
      0.48,
      1.35,
      face > 0 ? -Math.PI * 0.5 : Math.PI * 0.5,
    );
    this.addBox(faceX + face * 0.52, y - 0.16, z - 0.55, 0.08, 0.28, 0.06, this.mats.rust, false, 1);
    this.addBox(faceX + face * 0.52, y - 0.16, z + 0.48, 0.08, 0.32, 0.06, this.mats.rust, false, 1);
    this._contactAt(faceX + face * 0.58, z, 1.0, 2.0);
  }

  _fireEscape(faceX, y0, z, face, floors) {
    const n = Math.min(floors, 4);
    for (let i = 0; i < n; i++) {
      const y = y0 + 1.15 + i * 2.55;
      this.addBox(faceX + face * 1.35, y, z, 2.35, 0.12, 2.55, this.mats.darkMetal, false, 1);
      this.addBox(faceX + face * 2.35, y + 0.72, z, 0.1, 1.35, 2.55, this.mats.metal, false, 1);
      this.addBox(faceX + face * 1.35, y + 1.35, z, 2.3, 0.07, 2.6, this.mats.metal, false, 1);
      if (i < n - 1) {
        this.addBox(faceX + face * 1.75, y + 1.45, z + 0.85, 0.14, 2.5, 0.14, this.mats.darkMetal, false, 1);
      }
    }
    this.addBox(faceX + face * 1.75, y0 + 0.7, z + 0.85, 0.12, 1.5, 0.12, this.mats.darkMetal, false, 1);
  }

  _hangSign(faceX, y, z, face, rng, along = 0) {
    const nx = face * Math.cos(along);
    const nz = face * Math.sin(along);
    const alongZ = Math.abs(along) > 0.5;
    const w = 0.2 + rng() * 0.06;
    const px = faceX + nx * 0.42;
    const pz = z + nz * 0.42;
    if (alongZ) {
      this.addBox(faceX + nx * 0.28, y, z + nz * 0.28, 0.32, 0.04, 0.05, this.mats.metal, false, 1);
      this.addBox(px, y - 0.1, pz, w, 0.16, 0.04, this.mats.darkMetal, false, 1);
    } else {
      this.addBox(faceX + nx * 0.28, y, z, 0.32, 0.04, 0.05, this.mats.metal, false, 1);
      this.addBox(px, y - 0.1, z, 0.04, 0.16, w, this.mats.darkMetal, false, 1);
    }
  }

  _parapetKit(faceX, y, z, face, spanZ, rng, along = 0) {
    const nx = face * Math.cos(along);
    const nz = face * Math.sin(along);
    const tx = -nz;
    const tz = nx;
    const px = faceX + nx * 0.85;
    const pz = z + nz * 0.85;
    this.addBox(px - nx * 0.42, y + 0.55, pz - nz * 0.42, 0.16, 0.70, 0.16, this.mats.darkMetal, false, 1);
    this._acSeat(px, y, pz, along);
    this._stainDecal(
      'stainC',
      faceX + nx * 0.05,
      y - 0.85,
      z,
      0.72,
      1.55,
      along + (face > 0 ? -Math.PI * 0.5 : Math.PI * 0.5),
    );
    this.addBox(faceX + nx * 0.10, y - 0.55, z, 0.08, 1.35, 0.22, this.mats.rust, false, 0.7);
    this.addBox(faceX + nx * 0.10, y - 1.15, z + 0.12, 0.06, 0.85, 0.16, this.mats.dirt || this.mats.rust, false, 0.7);
    /* Continuous grime shadow directly under the parapet cap, running the
     * whole span (fix 6): the single streak alone left the roofline edge
     * pasted-clean at grazing angles. */
    this.addBox(
      faceX + nx * 0.045, y - 0.30, z + tz * 0,
      Math.abs(tx) > 0.5 ? spanZ * 1.9 : 0.04,
      0.42,
      Math.abs(tz) > 0.5 ? spanZ * 1.9 : 0.04,
      this.mats.dirt || this.mats.concrete, false, 0.5,
    );
    this._push(this.q.vent, px + tx * spanZ * 0.22, y + 0.48, pz + tz * spanZ * 0.22, 0, along + 0.2, 0);
    const dx = px + tx * spanZ * 0.22;
    const dz = pz + tz * spanZ * 0.22;
    this._junctionBox(dx, y + 0.35, dz, along);
    this._chimney(px + tx * spanZ * -0.08, y, pz + tz * spanZ * -0.08);
    this._antenna(px + tx * spanZ * 0.3, y, pz + tz * spanZ * 0.3, 1.45);
    if (Math.abs(z - 33) < 12 && faceX < 0) this._mast(px, y, pz + tz * 1.4);
  }

  _roofKit(x, y, z, spanX, spanZ, rng, force = false) {
    this._acSeat(x + spanX * 0.12, y, z - spanZ * 0.12);
    this._push(this.q.vent, x - spanX * 0.18, y + 0.48, z + spanZ * 0.1, 0, 0.3, 0);
    this._junctionBox(x + spanX * 0.12, y + 0.35, z + spanZ * 0.22, 0);
    this._chimney(x - spanX * 0.08, y, z);
    if (force || rng() > 0.4) this._antenna(x + spanX * 0.28, y, z - spanZ * 0.1, 1.55);
    if (Math.abs(z - 33) < 10 && x < 0) this._mast(x, y, z + 1.6);
  }

  _mast(x, y, z) {
    this.addCyl(x, y + 3.6, z, 0.08, 7.0, this.mats.metal, false);
    this.addBox(x, y + 4.6, z, 2.8, 0.07, 0.07, this.mats.darkMetal, false, 1);
    this.addBox(x, y + 5.8, z, 2.2, 0.06, 0.06, this.mats.darkMetal, false, 1);
    this.addBox(x, y + 6.8, z, 1.4, 0.06, 0.06, this.mats.metal, false, 1);
    this._junctionBox(x + 0.28, y + 4.8, z, 0);
  }

  _skyline(rng) {
    const rows = [
      { side: -1, z: 9, w: 8.2, d: 12, h: 17 },
      { side: -1, z: 28, w: 9, d: 14, h: 21 },
      { side: -1, z: 50, w: 8.2, d: 16, h: 16 },
      { side: -1, z: 72, w: 10, d: 14, h: 19 },
      { side: 1, z: 11, w: 8.2, d: 12, h: 15 },
      { side: 1, z: 34, w: 9, d: 15, h: 20 },
      { side: 1, z: 58, w: 8.2, d: 14, h: 17 },
      { side: 1, z: 84, w: 9, d: 12, h: 14 },
    ];
    for (const r of rows) {
      const far = r.side < 0 ? FAR_W : FAR_E;
      const x = r.side * (far + r.w * 0.5);
      const wall = r.h > 17 ? (this._brickBound || this.mats.brick) : this._plasterOf({ x, z: r.z });
      this.addBox(x, r.h * 0.5, r.z, r.w, r.h, r.d, wall, false, r.h > 17 ? 2.8 : this._plasterTileOf({ x, z: r.z }));
      this.addBox(x, r.h + 0.22, r.z, r.w + 0.45, 0.44, r.d + 0.45, this.mats.concrete, false, 1.3);
      const face = r.side < 0 ? 1 : -1;
      const faceX = x + face * (r.w * 0.5);
      const floors = Math.floor(r.h / 3.15);
      for (let f = 0; f < floors; f += 2) {
        const wy = 2.15 + f * 3.0;
        const wz = r.z + ((f % 4) ? 0.18 : -0.18) * r.d;
        this._simpleWindow(faceX, wy, wz, face, rng() > 0.45, 0);
      }
      this._balcony(faceX, 6.35, r.z + r.d * 0.12, face);
      this._parapetKit(faceX, r.h, r.z, face, r.d * 0.62, rng, 0);
      this._roofKit(x, r.h, r.z, r.w * 0.55, r.d * 0.4, rng, true);
    }

    // East fillers between the Suq east-row roofs and the far skyline, so
    // the gap over the alley doesn't read as void. Windows every 2nd floor.
    const fillers = [
      [27.8, 20, 5.2, 10, 13.5], [28.3, 38, 5.6, 12, 12.2],
      [27.6, 56, 5.2, 10, 14.5], [28.1, 74, 5.6, 12, 12.6],
    ];
    for (const [x, z, w, d, h] of fillers) {
      const wall = this._plasterOf({ x, z });
      this.addBox(x, h * 0.5, z, w, h, d, wall, false, this._plasterTileOf({ x, z }));
      this.addBox(x, h + 0.2, z, w + 0.4, 0.4, d + 0.4, this.mats.concrete, false, 1.3);
      const faceX = x - w * 0.5;
      for (let f = 0; f < Math.floor(h / 3.1); f += 2) {
        this._simpleWindow(faceX, 2.4 + f * 3.0, z + ((f % 4) ? 0.16 : -0.16) * d, -1, rng() > 0.5, 0);
      }
      this._chimney(x + w * 0.2, h, z - d * 0.2);
    }
  }

  _cables() {
    const spans = [
      [-6.9, 8.6, 14, 4.9, 8.2, 24],
      [-7.0, 9.0, 48, 4.9, 8.4, 58],
      [-6.9, 8.8, 74, 4.9, 8.2, 84],
      // Suq signature: low cable runs between the block row and east row.
      [13.2, 7.6, 16, 20.8, 7.2, 24],
      [13.3, 7.4, 60, 20.8, 7.0, 70],
      [5.2, 9.2, 40.5, 20.8, 8.0, 49.5],
    ];
    for (const [x0, y0, z0, x1, y1, z1] of spans) {
      const sag = 0.45 + Math.abs(z1 - z0) * 0.03;
      const curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(x0, y0, z0),
        new THREE.Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5 - sag, (z0 + z1) * 0.5),
        new THREE.Vector3(x1, y1, z1),
      ]);
      const m = new THREE.Mesh(new THREE.TubeGeometry(curve, 10, 0.010, 5, false), this.mats.darkMetal);
      m.castShadow = false;
      this.group.add(m);
    }
  }

  _dustArch(z) {
    // Widened for the 12 m Main; lintel seats into both canyon walls.
    const west = this._plasterOf({ x: CX - 5.2, z });
    const east = this._plasterOf({ x: CX + 5.2, z });
    const stone = this.col.trim || this.mats.concrete;
    this.addBox(CX - 5.2, 2.15, z, 0.62, 4.3, 0.72, west, true, 1.2);
    this.addBox(CX + 5.2, 2.15, z, 0.62, 4.3, 0.72, east, true, 1.2);
    this.addBox(CX - 5.2, 0.24, z, 0.74, 0.48, 0.84, stone, false, 1);
    this.addBox(CX + 5.2, 0.24, z, 0.74, 0.48, 0.84, stone, false, 1);
    this.addBox(CX, 4.52, z, 12.6, 0.46, 0.88, west, false, 1.3);
    this.addBox(CX, 4.88, z, 12.8, 0.22, 1.04, stone, false, 1.2);
    this.addBox(CX, 4.26, z, 10.1, 0.14, 0.26, this.mats.darkMetal, false, 1);
    /* Wall pockets + corbels so the span does not end mid-air. */
    this.addBox(-6.85, 4.20, z, 0.55, 0.72, 0.78, stone, false, 0.9);
    this.addBox(4.85, 4.20, z, 0.55, 0.72, 0.78, stone, false, 0.9);
    this.addBox(-6.55, 3.72, z, 0.42, 0.28, 0.62, this.col.chipStone || stone, false, 0.8);
    this.addBox(4.55, 3.72, z, 0.42, 0.28, 0.62, this.col.chipStone || stone, false, 0.8);
    this._junctionBox(CX - 4.9, 2.85, z + 0.28, Math.PI);
    this._junctionBox(CX + 4.9, 2.85, z + 0.28, Math.PI);
    this._contactAt(CX - 5.2, z, 0.9, 1.0);
    this._contactAt(CX + 5.2, z, 0.9, 1.0);
  }

  // Small arch over a cut entrance on the Suq side (spans z at fixed x).
  _cutArch(x, z) {
    const plaster = this.mats.plasterSand || this.mats.plaster;
    this.addBox(x, 1.9, z - 2.26, 0.66, 3.8, 0.56, plaster, true, 1.2);
    this.addBox(x, 1.9, z + 2.26, 0.66, 3.8, 0.56, plaster, true, 1.2);
    this.addBox(x, 0.22, z - 2.26, 0.78, 0.44, 0.68, this.mats.concrete, false, 1);
    this.addBox(x, 0.22, z + 2.26, 0.78, 0.44, 0.68, this.mats.concrete, false, 1);
    this.addBox(x, 4.02, z, 0.78, 0.44, 5.1, plaster, false, 1.3);
    this.addBox(x, 4.34, z, 0.92, 0.2, 5.3, this.mats.concrete, false, 1.2);
    this._junctionBox(x + 0.28, 2.6, z - 2.0, -Math.PI * 0.5);
  }

  _cover(rng) {
    // Five gameplay piles only — jersey + bags, no fence/tarp dressing.
    const piles = [
      [-2.85, 25.2, 0.04],   // E2 Main
      [-2.4, 44.2, -0.03],   // plaza south
      [-2.3, 68.0, -0.05],   // E7 Main
      [2.5, 78.2, 0.05],     // extract west
      [18.6, 21.0, -0.06],   // E1 Suq
    ];
    for (const [x, z, yaw] of piles) {
      this._coverPile(x, z, yaw, rng);
    }
  }

  _coverPile(x, z, yaw, rng) {
    this._jersey(x, z, Math.PI * 0.5 + yaw);
    this._sandbagStack(x + (x > 0 ? -0.55 : 0.55), z + 0.85, yaw, 3, 3, rng);
  }

  _sandbagStack(x, z, yaw, rows, cols, rng) {
    this._rotAabb(x, z, yaw, cols * 0.24, 0.32, 0.18 + rows * 0.2);
    for (let r = 0; r < rows; r++) {
      const n = cols - (r === rows - 1 ? 1 : 0);
      for (let c = 0; c < n; c++) {
        const lx = (c - (n - 1) * 0.5) * 0.46 + (r % 2) * 0.08;
        const ly = 0.13 + r * 0.2;
        const lz = ((r % 2) - 0.5) * 0.06;
        const ca = Math.cos(yaw), sa = Math.sin(yaw);
        this._push(
          this.q.sand,
          x + lx * ca + lz * sa, ly, z - lx * sa + lz * ca,
          0.12 * (rng() - 0.5), yaw + (rng() - 0.5) * 0.18, 0.1 * (rng() - 0.5),
          0.46, 0.40, 0.58,
        );
      }
    }
  }

  _jersey(x, z, yaw) {
    if (!this._jerseyMat) {
      // Warm dusty tint so barriers read as sun-baked concrete, not raw cream.
      this._jerseyMat = this.mats.concrete.clone();
      this._jerseyMat.color.setHex(0xb7a17e);
    }
    const m = new THREE.Mesh(this.geo.jersey, this._jerseyMat);
    m.position.set(x, 0, z);
    m.rotation.y = yaw;
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    this._rotAabb(x, z, yaw, 0.26, 1.2, 1.0);
    this._push(this.q.bolt, x + Math.cos(yaw) * 0.08, 0.72, z + Math.sin(yaw) * 0.08);
    this._push(this.q.bolt, x - Math.cos(yaw) * 0.08, 0.72, z - Math.sin(yaw) * 0.08);
    this._contactAt(x, z, 1.35, 0.85, yaw);
  }

  _fence(x, z, yaw, width) {
    const n = Math.max(4, Math.round(width / 0.16));
    this._rotAabb(x, z, yaw, 0.06, width * 0.5, 1.25);
    for (let i = 0; i < n; i++) {
      const t = (i / (n - 1) - 0.5) * width;
      const ca = Math.cos(yaw), sa = Math.sin(yaw);
      this._push(this.q.fence, x + t * sa, 0.62, z + t * ca, 0, yaw, 0);
    }
    this.addBox(x, 1.18, z, 0.04, 0.04, width, this.mats.darkMetal, false, 1);
    this.addBox(x, 0.42, z, 0.04, 0.04, width, this.mats.metal, false, 1);
  }

  _dumpster(x, z, yaw, scale = 1) {
    const g = new THREE.Group();
    g.position.set(x, 0, z);
    g.rotation.y = yaw;
    g.scale.setScalar(scale);
    this._part(g, this._box, this.col.dump, 0, 0.68, 0, 1.28, 1.18, 0.82);
    this._part(g, this._box, this.col.dumpLid, 0, 1.30, 0, 1.34, 0.08, 0.86);
    this._part(g, this._box, this.mats.darkMetal, 0, 1.22, 0, 1.36, 0.06, 0.88);
    this._part(g, this._box, this.col.dumpLid, 0.04, 1.36, -0.04, 1.18, 0.05, 0.74, 0.06, 0, 0);
    for (const t of [-0.38, 0, 0.38]) {
      this._part(g, this._box, this.mats.darkMetal, t, 0.7, 0.42, 0.08, 1.05, 0.06);
    }
    this._part(g, this._box, this.col.navy, 0, 0.95, 0.44, 0.55, 0.22, 0.05);
    this._part(g, this.geo.tire, this.mats.rubber, -0.48, 0.14, 0.32, 0.4, 0.45, 0.4, 0, 0, Math.PI * 0.5);
    this._part(g, this.geo.tire, this.mats.rubber, 0.48, 0.14, 0.32, 0.4, 0.45, 0.4, 0, 0, Math.PI * 0.5);
    this._part(g, this._box, this.mats.rust, 0.66, 0.78, 0, 0.08, 0.32, 0.24);
    this.group.add(g);
    this._rotAabb(x, z, yaw, 0.7 * scale, 0.48 * scale, 1.5 * scale);
    this._contactAt(x, z, 1.35 * scale, 1.05 * scale, yaw);
    this._contactAt(x, z, 0.70 * scale, 0.55 * scale, yaw);
  }

  _cratePlaced(x, y, z, yaw) {
    /* c29: bigger yaw/size/height jitter so stacks stop reading as a grid. */
    const h = Math.abs(Math.sin(x * 12.9898 + z * 78.233) * 43758.5453) % 1;
    const h2 = Math.abs(Math.sin(x * 39.3468 + z * 11.135) * 27183.1) % 1;
    const h3 = Math.abs(Math.sin(x * 7.13 + z * 3.31 + y * 11.2) * 19283.3) % 1;
    yaw += (h - 0.5) * 0.85;
    const s = 0.78 + h2 * 0.40;
    const sy = 0.80 + h3 * 0.42;
    this._push(this.q.crate, x, y, z, 0, yaw, (h3 - 0.5) * 0.08, s, sy, s);
    this._push(this.q.crateBand, x, y - 0.14 * sy, z, 0, yaw, 0, s, sy, s);
    this._push(this.q.crateBand, x, y + 0.14 * sy, z, 0, yaw, 0, s, sy, s);
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    for (const t of [-0.16, 0.16]) {
      this._push(this.q.crateSlat, x + t * s * sa, y + 0.255 * sy, z + t * s * ca, 0, yaw, 0, s, sy, s);
    }
    this._push(this.q.crateEnd, x + 0.28 * s * ca, y, z - 0.28 * s * sa, 0, yaw, 0, 1, sy, s);
    this._push(this.q.crateEnd, x - 0.28 * s * ca, y, z + 0.28 * s * sa, 0, yaw, 0, 1, sy, s);
    for (const [cx, cz] of [[-0.27, -0.27], [0.27, -0.27], [-0.27, 0.27], [0.27, 0.27]]) {
      const dx = (cx * ca + cz * sa) * s;
      const dz = (-cx * sa + cz * ca) * s;
      this._push(this.q.crateBatten, x + dx, y, z + dz, 0, yaw, 0, 1, sy, 1);
    }
  }

  _drapeTarp(x, y, z, yaw, span = 1.45, depth = 1.15, opts = {}) {
    /* c32: rot.z 0.38 + rot.x 0.28 turned a rectangle into a free-flying
     * bat-wing (van 395-430,600-740 and 700-780,335-395). Cloth now sits
     * nearly level, corners high, hem hanging plumb; optional poles pin
     * every corner to something physical. */
    const sag = opts.sag ?? 0.22;
    const tone = opts.tone ?? 0;
    const tilt = opts.tilt ?? 0.035;
    const seed = opts.seed ?? (Math.abs((x * 7.3 + z * 3.1) | 0) & 15);
    const geo = this._tarpClothGeo(span, depth, seed, sag, tone);
    const m = new THREE.Mesh(geo, this._tarpClothMat());
    m.position.set(x, y, z);
    m.rotation.y = yaw;
    m.rotation.z = tilt;
    m.rotation.x = tilt * 0.35;
    m.castShadow = true;
    m.receiveShadow = true;
    this.group.add(m);
    if (!opts.poles) return;
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    const hw = depth * 0.40;
    const hl = span * 0.40;
    const post = this._mattePostMat();
    const cap = this.mats.rust || post;
    for (const [iu, iv] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
      const px = x + iu * hw * ca + iv * hl * sa;
      const pz = z - iu * hw * sa + iv * hl * ca;
      this.addCyl(px, (y + 0.06) * 0.5, pz, 0.032, y + 0.06, post, false);
      this.addBox(px, y + 0.04, pz, 0.07, 0.05, 0.07, cap, false, 1);
    }
  }

  _barrelLoose(x, y, z, yaw, tip = 0) {
    const g = new THREE.Group();
    g.position.set(x, y, z);
    g.rotation.set(tip, yaw, tip * 0.15);
    this._part(g, this.geo.barrel, this.mats.rust, 0, 0, 0);
    this._part(g, this.geo.barrelHoop, this.mats.darkMetal, 0, 0.18, 0, 1, 1, 1, Math.PI * 0.5);
    this._part(g, this.geo.barrelHoop, this.mats.darkMetal, 0, -0.16, 0, 1, 1, 1, Math.PI * 0.5);
    this.group.add(g);
    this._contactAt(x, z, 0.55, 0.70, yaw);
  }

  _crateAt(x, z, yaw) {
    this._cratePlaced(x, 0.26, z, yaw);
    this._rotAabb(x, z, yaw, 0.3, 0.3, 0.55);
    this._contactAt(x, z, 0.52, 0.52, yaw);
  }

  _pallet(x, z, yaw) {
    const g = new THREE.Group();
    g.position.set(x, 0, z);
    g.rotation.y = yaw;
    this._part(g, this._box, this.mats.wood, 0, 0.06, 0, 1.15, 0.05, 0.95);
    this._part(g, this._box, this.mats.wood, -0.4, 0.08, 0, 0.1, 0.1, 0.9);
    this._part(g, this._box, this.mats.wood, 0, 0.08, 0, 0.1, 0.1, 0.9);
    this._part(g, this._box, this.mats.wood, 0.4, 0.08, 0, 0.1, 0.1, 0.9);
    this._part(g, this._box, this.mats.wood, 0, 0.14, 0, 1.15, 0.04, 0.95);
    this.group.add(g);
    this._rotAabb(x, z, yaw, 0.58, 0.48, 0.22);
  }

  _planter(x, z) {
    this.addBox(x, 0.22, z, 0.85, 0.44, 0.7, this.mats.concrete, true, 1.1);
    this.addCyl(x - 0.15, 0.62, z, 0.16, 0.42, this.col.leaf, false);
    this.addCyl(x + 0.14, 0.7, z + 0.08, 0.14, 0.55, this.col.leaf, false);
  }

  _scaffold(x, z, face) {
    for (const [lx, ly] of [[-0.55, 1.4], [0.55, 1.4], [-0.55, 3.1], [0.55, 3.1]]) {
      this.addCyl(x + lx, ly, z, 0.04, 2.7, this.mats.darkMetal, false);
    }
    this.addBox(x, 1.55, z + face * 0.15, 1.25, 0.06, 0.85, this.mats.darkMetal, false, 1);
    this.addBox(x, 3.15, z + face * 0.15, 1.25, 0.06, 0.85, this.mats.darkMetal, false, 1);
    this.addBox(x, 2.35, z, 1.28, 0.04, 0.04, this.mats.metal, false, 1);
  }

  _alleyFill(rng) {
    // Spawn yard: west-wall dumpster + east van cluster; center slab open.
    this._dumpster(-4.7, 5.8, 0.1, 1.0);
    this._pipeRun(-6.94, 2.4, 3.6, -1);
    this._pipeRun(20.86, 2.6, 3.4, 1);
    this._junctionBox(-6.92, 1.85, 3.15, Math.PI * 0.5);
    this._junctionBox(20.8, 1.78, 3.35, -Math.PI * 0.5);
    // Dead van + north crate cluster — yard landmark.
    this._van(12.4, 3.3, 1.35, false, 1.0);
    /* Extra contact in the sun-fall (NW) so the yard van cannot float even
     * if a texel misses — still the translucent dirt, not a black hole. */
    this._push(this.q.contact, 11.15, 0.011, 2.55, 0, 0.35, 0, 2.6, 1, 2.0);
    const blob = this._blobGeo();
    const vanShade = new THREE.Mesh(blob, this._joistShadeMat());
    vanShade.position.set(10.5, 0.018, 2.45);
    vanShade.scale.set(3.4, 1, 2.6);
    vanShade.rotation.y = 0.55;
    vanShade.castShadow = false;
    vanShade.receiveShadow = false;
    this.group.add(vanShade);
    const vanShade2 = new THREE.Mesh(blob, this._joistShadeMat());
    vanShade2.position.set(9.2, 0.017, 2.05);
    vanShade2.scale.set(2.4, 1, 1.8);
    vanShade2.rotation.y = 0.22;
    vanShade2.castShadow = false;
    vanShade2.receiveShadow = false;
    this.group.add(vanShade2);
    // Crates hug the van's north side; floating mid-yard they pinched the
    // route to the Suq gate down to ~0.7m against the spawn wall.
    this._crateAt(11.1, 6.25, 0.35);
    this._crateAt(12.1, 6.55, -0.2);
    this._cratePlaced(11.6, 0.76, 6.4, 0.15);
    this._cratePlaced(11.35, 1.22, 6.65, -0.55);
    this._drapeTarp(11.55, 1.58, 6.45, 0.35, 1.55, 1.20, { sag: 0.20, tilt: 0.03, tone: 1 });
    this._push(this.q.barrel, 15.6, 0.34, 6.6, 0, 0.55, 0, 0.88, 0.92, 0.88);
  }

  _vanWall(rng) {
    const faceX = -INNER;
    const z = 35.8;
    const face = 1;
    this.addBox(faceX - 0.55, 1.72, z, 1.15, 2.6, 2.85, this.col.dimRoom || this.mats.darkRoom, false, 1);
    this.addBox(faceX + 0.08, 1.55, z, 0.55, 2.4, 2.45, this.col.warmIn || this.mats.interior, false, 1);
    // Timber frame around the dark opening so it reads as a doorway, not a void.
    this.addBox(faceX + 0.05, 3.06, z, 0.26, 0.26, 3.05, this.mats.wood, false, 1.1);
    this.addBox(faceX + 0.05, 1.55, z - 1.46, 0.24, 3.0, 0.20, this.mats.wood, false, 1.1);
    this.addBox(faceX + 0.05, 1.55, z + 1.46, 0.24, 3.0, 0.20, this.mats.wood, false, 1.1);
    this.addBox(faceX + 0.18, 1.65, z - 0.85, 0.32, 3.2, 1.25, this.mats.darkMetal, false, 1);
    this.addBox(faceX + 0.38, 1.55, z - 0.85, 0.12, 2.95, 1.02, this.col.door, false, 1);
    // Concrete jambs + lintel + panel insets so the shutter door has a frame.
    this.addBox(faceX + 0.30, 1.65, z - 1.52, 0.20, 3.34, 0.17, this.mats.sill, false, 1);
    this.addBox(faceX + 0.30, 1.65, z - 0.18, 0.20, 3.34, 0.17, this.mats.sill, false, 1);
    this.addBox(faceX + 0.30, 3.36, z - 0.85, 0.20, 0.18, 1.55, this.mats.sill, false, 1);
    this.addBox(faceX + 0.445, 2.10, z - 0.85, 0.02, 0.85, 0.66, this.col.doorInset, false, 1);
    this.addBox(faceX + 0.445, 0.95, z - 0.85, 0.02, 0.90, 0.66, this.col.doorInset, false, 1);
    this.addBox(faceX + 0.45, 0.30, z - 0.85, 0.02, 0.34, 0.92, this.mats.metal, false, 1);
    this.addBox(faceX + 0.48, 1.5, z - 0.55, 0.08, 0.05, 0.2, this.mats.metal, false, 1);
    this._shopPane(faceX, 1.62, z + 1.05, face, true, rng, 'x');
    this._awningX(faceX, 2.55, z, face, 3.6, 2.05, this.col.tarp || this.col.awnN);
    for (const [t, yo] of [[-0.55, -0.15], [0.15, 0.22], [0.62, -0.35], [-0.2, 0.45]]) {
      this.addBox(faceX + 0.15 + t * 0.15, 1.15 + yo, z + t, 0.38, 0.42, 0.28, this.col.goods, false, 1);
    }
    this._crateAt(-5.3, 36.4, 0.25);
    this.addCyl(faceX + 0.18, 1.1, 34.2, 0.055, 2.2, this.mats.darkMetal, false);
    this._point(0xc47840, 0.72, 6.5, faceX + 0.9, 2.45, z);
  }

  // One market stall: covered roof, collidable table (plaza hard cover),
  // crate/goods dressing.
  _stall(x, z, yaw, rng, idx = 0) {
    /* c32: one tarp-fin + one roof module was cloned across all 6 stalls
     * (market 650-1300,440-540). Per-instance sag/width/tone, and two
     * stalls drop the fin for bare poles or a different awning. */
    const roofs = [
      { sx: 1.95, sz: 2.15, sag: 0.15, mat: 'g' },
      { sx: 1.58, sz: 2.35, sag: 0.26, mat: 't' },
      { sx: 2.10, sz: 1.88, sag: 0.11, mat: 'r' },
      { sx: 1.72, sz: 2.05, sag: 0.20, mat: 'g' },
      { sx: 2.20, sz: 1.70, sag: 0.18, mat: 't' },
      { sx: 1.80, sz: 2.28, sag: 0.08, mat: 'r' },
    ];
    const rf = roofs[idx % 6];
    const roofMat = rf.mat === 't' ? (this.col.tarp || this.col.awnR)
      : rf.mat === 'r' ? this.col.awnR
      : this.col.awnG;
    this._stallRoof(x + 0.1, 2.32, z, rf.sx, rf.sz, roofMat, rf.sag);
    this.addBox(x, 0.48, z, 1.75, 0.9, 1.95, this._plankMat(0.75), true, 1);
    this.addBox(x, 1.00, z, 1.65, 0.05, 1.85, this._plankWearMat(), true, 1);
    this._plankDeck(x, 1.055, z, 1.68, 1.88, yaw);
    this._plankFace(x, 0.48, z + 0.99, 1.70, 0.86, yaw);
    this._plankFace(x, 0.48, z - 0.99, 1.70, 0.86, yaw);
    // Shelf lip + panel insets: catch light on the counter edges so the
    // stall masses stop reading as voids under the awning shade.
    this.addBox(x, 1.09, z + 0.96, 1.72, 0.06, 0.05, this.mats.cardboard, false, 1);
    this.addBox(x, 1.09, z - 0.96, 1.72, 0.06, 0.05, this.mats.cardboard, false, 1);
    this.addBox(x, 0.62, z + 0.99, 1.55, 0.05, 0.03, this.mats.cardboard, false, 1);
    this.addBox(x - 0.46, 0.44, z + 0.985, 0.58, 0.52, 0.025, this.mats.woodEnd || this.mats.wood, false, 1);
    this.addBox(x + 0.46, 0.44, z + 0.985, 0.58, 0.52, 0.025, this.mats.woodEnd || this.mats.wood, false, 1);
    this._cratePlaced(x + 0.12, 1.16, z - 0.28, yaw + 0.2);
    for (const [t, yo, mat] of [[-0.6, 1.62, this.col.goods], [0.05, 1.7, this.col.awnN], [0.6, 1.58, this.col.goods]]) {
      this.addBox(x - 0.02, yo, z + t, 0.12, 0.8, 0.26, mat, false, 1);
    }
  }

  _market(rng) {
    // Market Plaza: one E4 stall, fountain, burning van, balcony stairs.
    const stalls = [
      [5.6, 45.0, 0.06],   // E4 cover. Do not move. Chest at (10.8, 50.5) stays clear.
    ];
    for (let i = 0; i < stalls.length; i++) {
      const [x, z, yaw] = stalls[i];
      this._stall(x, z, yaw, rng, i);
    }

    // Fountain: OPEN curb wall so the water disc is visible from eye height.
    // The old solid cylinders capped the basin — mats.wet sat on granite
    // and read as a stone slab (market 94-516,586-703).
    if (!this._fountWallGeo) {
      this._fountWallGeo = new THREE.CylinderGeometry(1.50, 1.56, 0.48, 28, 1, true);
      const wp = this._fountWallGeo.attributes.position;
      const wc = new Float32Array(wp.count * 3);
      for (let i = 0; i < wp.count; i++) {
        const x = wp.getX(i);
        const y = wp.getY(i);
        const z = wp.getZ(i);
        const t = (y + 0.24) / 0.48;
        const h = Math.abs(Math.sin(x * 6.7 + z * 5.1) * 43758.5453) % 1;
        const s = 0.88 + t * 0.10 + h * 0.06;
        wc[i * 3] = s;
        wc[i * 3 + 1] = s * 0.985;
        wc[i * 3 + 2] = s * 0.96;
      }
      this._fountWallGeo.setAttribute('color', new THREE.BufferAttribute(wc, 3));
    }
    const wall = new THREE.Mesh(this._fountWallGeo, this._fountainCurbMat());
    wall.position.set(-1.2, 0.28, 49.2);
    wall.castShadow = true;
    wall.receiveShadow = true;
    this.group.add(wall);
    this._fountainRingColliders(-1.2, 49.2);
    const water = new THREE.Mesh(this._fountainWaterGeo(), this._fountainWaterMat());
    water.position.set(-1.2, 0.40, 49.2);
    water.scale.set(1.46, 1, 1.46);
    water.receiveShadow = true;
    water.castShadow = false;
    this.group.add(water);
    if (!this._fountRimGeo) {
      this._fountRimGeo = new THREE.RingGeometry(1.42, 1.60, 28);
      this._fountRimGeo.rotateX(-Math.PI / 2);
    }
    const rim = new THREE.Mesh(this._fountRimGeo, this._wellFillMat());
    rim.position.set(-1.2, 0.525, 49.2);
    rim.receiveShadow = true;
    rim.castShadow = false;
    this.group.add(rim);
    this._contactAt(-1.2, 49.2, 2.2, 2.2);

    // Plaza-facing block walls get windows + awnings so Mid reads dressed.
    for (const [z, face] of [[40, 1], [58, -1]]) {
      this._simpleWindow(7, 2.2, z + face * 0.02, face, true, Math.PI * 0.5);
      this._simpleWindow(10.5, 2.2, z + face * 0.02, face, false, Math.PI * 0.5);
      this._simpleWindow(8.6, 5.3, z + face * 0.02, face, true, Math.PI * 0.5);
      this._awningZ(7.2, 2.9, z, face, 4.4, 1.4, face > 0 ? this.col.awnR : this.col.awnG);
      this._stainDecal('stainC', 11.6, 2.3, z + face * 0.16, 1.5, 2.7, face > 0 ? 0 : Math.PI);
    }

    // Balcony: slab at y 2.6 (x 17..21, z 48..54), crate-stair ramp, rails.
    this.addBox(19.05, 2.42, 51, 4.1, 0.36, 6.2, this.mats.concrete, true, 1.3);
    this.addCyl(17.35, 1.12, 48.6, 0.14, 2.25, this.mats.concrete, true);
    this.addCyl(17.35, 1.12, 53.4, 0.14, 2.25, this.mats.concrete, true);
    this.addBox(17.15, 3.1, 51, 0.05, 0.06, 6.15, this.mats.rust, false, 1);
    this.addBox(17.15, 2.86, 51, 0.04, 0.05, 6.1, this.mats.metal, false, 1);
    for (const rz of [48.25, 49.65, 51.05, 52.45, 53.75]) {
      this.addBox(17.15, 2.86, rz, 0.05, 0.56, 0.05, this.mats.darkMetal, false, 1);
    }
    this.addBox(19.05, 3.1, 48.15, 3.9, 0.06, 0.05, this.mats.rust, false, 1);
    this._stainDecal('stainB', 17.12, 2.0, 51, 4.4, 0.85, Math.PI * 0.5);
    // Crate stair up from the plaza floor (south side).
    this.addBox(15.55, 0.33, 54.9, 1.35, 0.66, 1.3, this._plankMat(0.35), true, 1);
    this.addBox(16.9, 0.62, 54.9, 1.35, 1.24, 1.3, this._plankMat(0.55), true, 1);
    this.addBox(18.25, 0.95, 54.9, 1.35, 1.9, 1.3, this._plankMat(0.2), true, 1);
    this._plankDeck(15.55, 0.68, 54.9, 1.32, 1.26, 0.08);
    this._plankDeck(16.9, 1.26, 54.9, 1.32, 1.26, -0.12);
    this._plankDeck(18.25, 1.92, 54.9, 1.32, 1.26, 0.05);
    this._awningX(21, 5.28, 51, -1, 4.6, 1.5, this.col.awnG);
    this._contactAt(19, 51, 3.4, 5.2);
    this._point(0xc47840, 0.55, 5.5, 7.5, 2.28, 49.3);
  }

  // Suq alley dressing: parked cover, crates/pallets along the edges,
  // hanging cables — the lane's own visual signature vs the arched Main.
  _suqDress(rng) {
    this._sedan(19.1, 30.5, 0.12, this.col.silver, false, 1.0);
    this._dumpster(14.0, 65.0, -0.1, 1.0);
    for (const [x, z, sx, sz] of [[15.4, 15.8, 0.9, 0.35], [18.8, 32.4, 1.0, 0.4], [15.0, 66.8, 1.1, 0.42], [18.5, 72.6, 0.85, 0.32]]) {
      this._push(this.q.drift, x, 0.014, z, 0, rng() * 1.2, 0, sx, 1, sz);
    }
    this._stainDecal('stainD', 13.16, 2.8, 31.8, 1.3, 2.0, -Math.PI * 0.5);
    this._stainDecal('stainD', 20.84, 2.6, 29.2, 1.2, 1.8, Math.PI * 0.5);
    this._simpleWindow(8.5, 2.5, 18.05, 1, true, Math.PI * 0.5);
    this._simpleWindow(10.2, 2.5, 21.95, -1, false, Math.PI * 0.5);
    this._simpleWindow(8.5, 2.5, 62.05, 1, false, Math.PI * 0.5);
    this._simpleWindow(10.2, 2.5, 65.95, -1, true, Math.PI * 0.5);
  }

  _sidewalkProps(rng) {
    // Against the west wall — mid-lane it walled off the gate exit together
    // with the wrecked sedan at (-0.18, 12). x −5.15 clears the west facade.
    this._dumpster(-5.15, 13.6, -0.08, 1.0);

    // Forecourt: E8 crate stack only. Pad stays open.
    this._crateAt(6.2, 79.6, 0.25);
    this._crateAt(6.9, 80.1, -0.15);
    this._cratePlaced(6.55, 0.76, 79.9, 0.1);
  }

  _vehicles() {
    // Burning van relocated to the plaza's east half (was mid-Main at 32.2,
    // where it blocked over half the street).
    this._van(12.0, 44.0, -1.15, true, 1.20);
    // Shallow angle: a steep yaw turns the sedan's axis-aligned collider into
    // a ~5.5m square that sealed the lane against the west barrier.
    this._sedan(0.6, 12.05, 0.22, this.col.maroon, true, 1.15);
    this._sedan(2.8, 26.4, 0.55, this.col.taxi, true, 1.0);
    this._sedan(-3.0, 64.5, 0.30, this.col.maroon, true, 1.12);
    this._wreckWells();
  }

  _wreckWells() {
    const rubber = this.mats.wreckRubber || this.mats.rubber;
    const hub = this._hubMat();
    for (const [x, z] of [[10.95, 45.20], [12.75, 45.20], [10.95, 43.00], [12.75, 43.00]]) {
      this.addCyl(x, 0.32, z, 0.30, 0.18, rubber, false);
      this.addCyl(x, 0.32, z, 0.13, 0.22, hub, false);
    }
  }

  _grooveDarkMat() {
    if (this._grooveDark) return this._grooveDark;
    /* Mid-shadow, not near-black — a 1 cm 0x1a1816 strip reads as a
     * floating sticker-slot even with a highlight pair beside it. */
    this._grooveDark = new THREE.MeshStandardMaterial({
      color: 0x3a3632,
      roughness: 0.90,
      metalness: 0.04,
      envMapIntensity: 0.06,
    });
    return this._grooveDark;
  }

  _grooveHiMat() {
    if (this._grooveHi) return this._grooveHi;
    this._grooveHi = new THREE.MeshStandardMaterial({
      color: 0x7a7670,
      roughness: 0.62,
      metalness: 0.08,
      envMapIntensity: 0.14,
    });
    return this._grooveHi;
  }

  /* Recessed panel line: ONE channel + ONE highlight lip.
   * The old dark+hi+dark triple rendered as three parallel sticker strips
   * on hoods (scope 940-1280,430-560). */
  _seam(g, x, y, z, sx, sy, sz) {
    const dark = this._grooveDarkMat();
    const hi = this._grooveHiMat();
    this._part(g, this._box, dark, x, y, z, sx, sy, sz);
    const min = Math.min(sx, sy, sz);
    const lip = Math.max(0.007, min * 0.55);
    if (sx <= min + 1e-6) {
      this._part(g, this._box, hi, x + lip, y, z, 0.006, sy * 0.90, sz * 0.90);
    } else if (sy <= min + 1e-6) {
      this._part(g, this._box, hi, x, y + lip, z, sx * 0.90, 0.006, sz * 0.90);
    } else {
      this._part(g, this._box, hi, x, y, z + lip, sx * 0.90, sy * 0.90, 0.006);
    }
  }

  _railMat() {
    if (this._rail) return this._rail;
    /* Van rub-rail: dark khaki, fully matte — must stay under lum 160 in
     * noon sun (the grooveHi 0x7a7670 rough 0.62 version blew to white). */
    this._rail = new THREE.MeshStandardMaterial({
      color: 0x504b42,
      roughness: 0.90,
      metalness: 0.04,
      envMapIntensity: 0.06,
    });
    return this._rail;
  }

  _mattePostMat() {
    if (this._mattePost) return this._mattePost;
    /* darkMetal is 0xb0b0b4 / metal 0.86 — noon specks blast to 255 and
     * the stall upright reads as a white refrigerator slab. */
    this._mattePost = new THREE.MeshStandardMaterial({
      color: 0x3a3632,
      roughness: 0.92,
      metalness: 0.06,
      envMapIntensity: 0.06,
    });
    return this._mattePost;
  }

  _doorSkinMat() {
    if (this._doorSkin) return this._doorSkin;
    this._doorSkin = new THREE.MeshStandardMaterial({
      color: 0x3e3c38,
      roughness: 0.90,
      metalness: 0.04,
      envMapIntensity: 0.10,
    });
    return this._doorSkin;
  }

  _shut(g, x, y, z, sx, sy, sz) {
    this._seam(g, x, y, z, sx, sy, sz);
  }

  _archLipMat() {
    if (this._archLip) return this._archLip;
    /* Dark rubber/steel lip — a cream-ochre tube around the tire reads as
     * a whitewall. Taxi arches use this; other hulls keep body-color flare. */
    this._archLip = new THREE.MeshStandardMaterial({
      color: 0x2a2622,
      roughness: 0.90,
      metalness: 0.08,
      envMapIntensity: 0.08,
    });
    return this._archLip;
  }

  _tarpClothMat() {
    if (this._tarpCloth) return this._tarpCloth;
    /* c31: 0x3e4a38 was green-dominant (linear G/R 1.42) and the hard
     * min(outgoingLight, 0.34) clamp flattened every sunlit fold to one
     * constant tone — the critic's "flat saturated-green sail". Warm
     * desaturated olive-brown albedo (R >= G), vertex-color creases, and
     * a soft highlight shoulder that compresses instead of clipping so
     * fold shading survives full sun. */
    const m = new THREE.MeshStandardMaterial({
      color: 0x514b3f,
      roughness: 0.94,
      metalness: 0.0,
      envMapIntensity: 0.06,
      vertexColors: true,
    });
    m.onBeforeCompile = (shader) => {
      if (shader.fragmentShader.includes('tarpCapL')) return;
      shader.fragmentShader = shader.fragmentShader.replace(
        '#include <opaque_fragment>',
        `float tarpCapL = max(outgoingLight.r, max(outgoingLight.g, outgoingLight.b));
         if (tarpCapL > 0.24) outgoingLight *= (0.24 + (tarpCapL - 0.24) * 0.34) / tarpCapL;
         #include <opaque_fragment>`,
      );
    };
    m.customProgramCacheKey = () => 'tarp-cloth31';
    this._tarpCloth = m;
    return m;
  }

  _tarpClothGeo(span, depth, seed = 0, sagAmt = 0.22, tone = 0) {
    if (!this._tarpCache) this._tarpCache = new Map();
    const sd = seed & 15;
    const k = `${(span * 20) | 0}_${(depth * 20) | 0}_${sd}_${(sagAmt * 40) | 0}_${tone | 0}`;
    let g = this._tarpCache.get(k);
    if (g) return g;
    g = new THREE.PlaneGeometry(depth, span, 14, 16);
    g.rotateX(-Math.PI / 2);
    const pos = g.attributes.position;
    const folds = new Float32Array(pos.count);
    const ph = sd * 0.61 + tone * 1.17;
    let fMin = 1e9;
    let fMax = -1e9;
    const hash = (i) => {
      const j = Math.sin(i * 12.9898 + ph * 7.13) * 43758.5453;
      return j - Math.floor(j);
    };
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const z = pos.getZ(i);
      const u = depth ? x / depth : 0;
      const v = span ? z / span + 0.5 : 0.5;
      const tU = u * 2;
      const tV = (v - 0.5) * 2;
      /* High at the four tied corners, catenary sag between — not a
       * diagonal sail with free-floating spike tips. */
      const cat = (1 - tU * tU) * sagAmt * 0.55 + (1 - tV * tV) * sagAmt;
      const fold = Math.sin(v * 9.4 + ph) * 0.070 * Math.sin(Math.PI * v)
        + Math.sin(u * 7.6 + v * 3.2 + ph * 1.7) * 0.042
        + Math.sin(u * 14.0 - v * 8.1 + ph * 2.3) * 0.024;
      folds[i] = fold;
      if (fold < fMin) fMin = fold;
      if (fold > fMax) fMax = fold;
      let y = -cat + fold;
      const au = Math.abs(tU);
      const av = Math.abs(tV);
      const rim = Math.max(au, av);
      if (rim > 0.92) {
        const r = hash(i);
        const inset = 0.018 + r * 0.022;
        pos.setX(i, x * (1 - inset * 0.08));
        pos.setZ(i, z * (1 - inset * 0.08));
        y -= 0.04 + r * 0.05;
      }
      const corner = au * av;
      if (corner > 0.72) y -= (corner - 0.72) * 0.55;
      pos.setY(i, y);
    }
    /* Vertex-color creases + per-instance weathered tones (same material). */
    const col = new Float32Array(pos.count * 3);
    const fRange = Math.max(1e-5, fMax - fMin);
    const tr = [1.04, 1.10, 0.98][tone] || 1.04;
    const tg = [1.00, 0.94, 0.96][tone] || 1.00;
    const tb = [0.88, 0.80, 0.86][tone] || 0.88;
    const lift = [0, 0.04, 0.08][tone] || 0;
    for (let i = 0; i < pos.count; i++) {
      const t = (folds[i] - fMin) / fRange;
      const shade = 0.70 + 0.30 * t + lift;
      col[i * 3] = Math.min(1, shade * tr);
      col[i * 3 + 1] = Math.min(1, shade * tg);
      col[i * 3 + 2] = Math.min(1, shade * tb);
    }
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    g.computeVertexNormals();
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    this._tarpCache.set(k, g);
    return g;
  }

  _fountainRingColliders(cx, cz) {
    /* Hollow curb — the visual is an open cylinder. A solid AABB (x −2.75..0.35)
     * pinched the plaza dumpster to a 0.44m gap. 12 overlapping boxes follow
     * the 1.5 m rim; the basin stays walkable. */
    const n = 12;
    const r = 1.50;
    const t = 0.62;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2;
      this._aabb(cx + Math.cos(a) * r, 0.30, cz + Math.sin(a) * r, t, 0.60, t);
    }
  }

  _fountainCurbMat() {
    if (this._fountCurb) return this._fountCurb;
    const src = this.mats.sill || this.mats.concrete;
    const m = src.clone();
    m.vertexColors = true;
    this._fountCurb = m;
    return m;
  }

  _fountainWaterMat() {
    if (this._fountWater) return this._fountWater;
    /* c33: c32 emissive 0x0a242c @ 0.10 + B-led VC (0.72/0.90/1.00) read as
     * a swimming-pool disc (market 250,650 = 66/92/101). Dusty-market water
     * is murkier grey-teal with a warm film — keep a weak cool emissive so
     * noon sun cannot brown the disc back to 41/37/28. */
    this._fountWater = new THREE.MeshStandardMaterial({
      color: 0x152422,
      roughness: 0.20,
      metalness: 0.12,
      envMapIntensity: 0.36,
      emissive: 0x061210,
      emissiveIntensity: 0.036,
      vertexColors: true,
    });
    return this._fountWater;
  }

  _fountainWaterGeo() {
    if (this._fountGeo) return this._fountGeo;
    const g = new THREE.CircleGeometry(1, 48);
    g.rotateX(-Math.PI / 2);
    const pos = g.attributes.position;
    const col = new Float32Array(pos.count * 3);
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const z = pos.getZ(i);
      const r = Math.min(1, Math.sqrt(x * x + z * z));
      const sun = Math.max(-1, Math.min(1, x * 0.92 + z * 0.39));
      const rim = 1.0 - r * 0.18;
      const farLip = r > 0.82 ? 0.08 * Math.max(0, -z) : 0;
      const lum = (0.82 + sun * 0.12) * rim + farLip;
      const warm = 0.05 + r * 0.08;
      col[i * 3] = Math.min(1.08, lum * (0.90 + warm));
      col[i * 3 + 1] = Math.min(1.08, lum * 0.95);
      col[i * 3 + 2] = Math.min(1.08, lum * (0.93 - warm * 0.28));
      pos.setY(i, (1 - r) * -0.04);
    }
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    g.computeVertexNormals();
    const nrm = g.attributes.normal;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const z = pos.getZ(i);
      const r = Math.min(1, Math.hypot(x, z));
      let nx = nrm.getX(i) - 0.12 * r * 0.84 + x * r * 0.16;
      let ny = nrm.getY(i);
      let nz = nrm.getZ(i) - 0.12 * r * 0.36 + z * r * 0.16;
      const len = Math.hypot(nx, ny, nz) || 1;
      nrm.setXYZ(i, nx / len, ny / len, nz / len);
    }
    nrm.needsUpdate = true;
    if (g.attributes.uv) g.setAttribute('uv2', g.attributes.uv.clone());
    this._fountGeo = g;
    return g;
  }

  _plankMat(t) {
    if (!this._planks) this._planks = [];
    const i = Math.max(0, Math.min(3, (t * 4) | 0));
    if (this._planks[i]) return this._planks[i];
    const hex = [0x8a6a48, 0x5a422c, 0xa07a50, 0x3e2e20][i];
    this._planks[i] = new THREE.MeshStandardMaterial({
      color: hex,
      roughness: 0.90 + i * 0.02,
      metalness: 0.0,
      envMapIntensity: 0.07,
    });
    return this._planks[i];
  }

  _plankWearMat() {
    if (this._plankWear) return this._plankWear;
    this._plankWear = new THREE.MeshStandardMaterial({
      color: 0x2e241c,
      roughness: 0.96,
      metalness: 0.0,
      envMapIntensity: 0.04,
    });
    return this._plankWear;
  }

  /* Individual boards — kills the monolithic tiled wood-box read. */
  _plankDeck(x, y, z, w, d, yaw = 0) {
    const n = Math.max(5, Math.round(w / 0.148));
    const plankW = w / n;
    const gap = 0.038;
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    for (let i = 0; i < n; i++) {
      const h = Math.abs(Math.sin(x * 9.1 + z * 3.7 + i * 17.2) * 43758.5453) % 1;
      const h2 = Math.abs(Math.sin(x * 3.3 + z * 11.8 + i * 5.9) * 19283.3) % 1;
      const lx = ((i + 0.5) / n - 0.5) * w;
      const px = x + lx * ca;
      const pz = z - lx * sa;
      const sy = 0.042 + h * 0.014;
      const sz = d * (0.94 + h2 * 0.07);
      const rot = yaw + (h - 0.5) * 0.16;
      const g = new THREE.Group();
      g.position.set(px, y, pz);
      g.rotation.y = rot;
      this._part(g, this._box, this._plankMat(h), 0, 0, 0, plankW - gap, sy, sz);
      if (h > 0.58) {
        const end = h > 0.8 ? sz * 0.48 : -sz * 0.48;
        this._part(g, this._box, this._plankWearMat(), 0, sy * 0.42, end, (plankW - gap) * 0.92, 0.012, 0.028);
      }
      this.group.add(g);
    }
  }

  /* Vertical boards on a stall face so the side doesn't read as one tile. */
  _plankFace(x, y, z, w, h, yaw = 0) {
    const n = Math.max(4, Math.round(w / 0.16));
    const plankW = w / n;
    const gap = 0.018;
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    for (let i = 0; i < n; i++) {
      const t = Math.abs(Math.sin(x * 5.7 + z * 8.2 + i * 13.1) * 27183.1) % 1;
      const lx = ((i + 0.5) / n - 0.5) * w;
      const px = x + lx * ca;
      const pz = z - lx * sa;
      const sy = h * (0.92 + t * 0.08);
      this.addBox(px, y, pz, plankW - gap, sy, 0.04, this._plankMat(t), false, 0.4);
    }
  }

  _chromeTrim(g, x, y, z, sx, sy, sz, rx = 0, ry = 0, rz = 0) {
    this._part(g, this._box, this.col.agedChrome || this.mats.chrome || this.mats.metal, x, y, z, sx, sy, sz, rx, ry, rz);
  }

  /* Proud glass card: plane UVs put the diagonal band on the visible face
   * (a scaled box can hide the streak on a 4 cm edge). */
  _windFace(g, x, y, z, w, h, rx = 0, ry = 0) {
    const geo = this.geo.windPlane || this._box;
    const mat = this.col.wind || this.col.pane;
    const m = new THREE.Mesh(geo, mat);
    m.position.set(x, y, z);
    m.rotation.set(rx, ry, 0);
    m.scale.set(w, h, 1);
    m.castShadow = false;
    m.receiveShadow = false;
    g.add(m);
    return m;
  }

  _archAt(g, x, y, z, bodyMat, lip = null) {
    const side = Math.sign(x) || 1;
    const flare = lip || this._fenderMat(bodyMat);
    this._part(g, this.geo.archFlare, flare, x - side * 0.02, y + 0.02, z, 1.16, 1.10, 1.16);
    if (this.geo.wellInner) {
      this._part(g, this.geo.wellInner, this._wellFillMat(), x - side * 0.06, y, z, 0.78, 0.84, 0.78);
    }
    this._part(g, this._box, this._wellFillMat(), x - side * 0.10, y + 0.10, z, 0.16, 0.24, 0.48);
    this._part(g, this._box, flare, x - side * 0.04, y + 0.28, z, 0.18, 0.06, 0.58);
  }

  /* Dark disc + liner covering the loft cutout edge so cream hull cannot
   * form a whitewall crescent (street 1150-1600,560-900). */
  _plugWell(g, wx, y, wz) {
    const side = Math.sign(wx) || 1;
    const fill = this._wellFillMat();
    const lip = this._archLipMat();
    this._part(g, this._cyl, fill, wx - side * 0.04, y, wz, 0.38, 0.11, 0.38, 0, 0, Math.PI * 0.5);
    this._part(g, this._cyl, fill, wx - side * 0.12, y, wz, 0.32, 0.24, 0.32, 0, 0, Math.PI * 0.5);
    this._part(g, this._box, fill, wx - side * 0.14, y + 0.04, wz, 0.20, 0.38, 0.58);
    /* Eyebrow over 12-o'clock — leftover cream sat on the tire crown. */
    this._part(g, this._box, lip, wx - side * 0.02, y + 0.30, wz, 0.16, 0.10, 0.52);
    this._part(g, this.geo.archFlare, lip, wx - side * 0.00, y + 0.01, wz, 0.94, 1.18, 0.94);
  }

  _wheelAt(g, x, y, z, wreck = false, scl = 1) {
    const tire = wreck ? (this.mats.wreckRubber || this._tireMat()) : this._tireMat();
    const hub = this._hubMat();
    const wall = this._sidewallMat();
    const side = Math.sign(x) || 1;
    this._part(g, this.geo.wheelTire, tire, x, y, z, scl, scl, scl, 0, Math.PI * 0.5, 0);
    if (this.geo.rimBarrel) {
      this._part(g, this.geo.rimBarrel, hub, x + side * 0.01 * scl, y, z, scl, scl, scl, 0, 0, Math.PI * 0.5);
    }
    this._part(g, this.geo.wheelWall, wall, x + side * 0.05 * scl, y, z, scl, scl, scl, 0, 0, Math.PI * 0.5);
    this._part(g, this.geo.wheelHub, hub, x + side * 0.03 * scl, y, z, scl, scl, scl, 0, 0, Math.PI * 0.5);
    if (this.geo.wheelBolt) {
      for (let b = 0; b < 6; b++) {
        const a = b * (Math.PI / 3) + 0.28;
        this._part(g, this.geo.wheelBolt, hub, x + side * 0.048 * scl, y + Math.sin(a) * 0.038 * scl, z + Math.cos(a) * 0.038 * scl, scl, scl, scl, 0, 0, Math.PI * 0.5);
      }
    }
    this._part(g, this.geo.wheelCap, hub, x + side * 0.052 * scl, y, z, scl, scl, scl, 0, 0, Math.PI * 0.5);
    if (this.geo.rimLip) {
      this._part(g, this.geo.rimLip, hub, x + side * 0.04 * scl, y, z, scl, scl, scl, 0, Math.PI * 0.5, 0);
    }
  }

  _sedan(x, z, yaw, bodyMat, wreck, scale = 1) {
    const g = new THREE.Group();
    g.position.set(x, wreck ? 0.04 : 0, z);
    g.rotation.y = yaw;
    g.scale.setScalar(scale);
    if (wreck) g.rotation.z = 0.05;
    const pane = this.col.wind || this.mats.windshield || this.mats.cabGlass;
    const cabin = this._cabinMat();
    const taxi = bodyMat === this.col.taxi || bodyMat === this.mats.sedanTaxi;
    const hull = taxi ? this._taxiHullMat() : (wreck ? (this.mats.wreckCab || bodyMat) : bodyMat);
    const chrome = taxi
      ? (this.mats.darkMetal || this.col.agedChrome)
      : (this.col.agedChrome || this.mats.chrome || this.mats.metal);
    /* Taxi keeps the sedan cutouts — sedanSolid filled the well with
     * cream hull and the leftover crescent read as a whitewall. Dark
     * lip + well plug cover the cutout edge. */
    this._loftHull(g, 'sedan', hull);
    this._part(g, this._box, cabin, 0, 0.88, -0.12, 1.22, 0.48, 1.72);
    this._shut(g, 0, 0.74, 0.68, 1.58, 0.010, 0.012);
    this._shut(g, 0, 0.74, -0.72, 1.56, 0.010, 0.012);
    this._shut(g, 0.798, 0.58, 0.38, 0.010, 0.22, 0.010);
    this._shut(g, -0.798, 0.58, 0.38, 0.010, 0.22, 0.010);
    this._shut(g, 0.798, 0.58, -0.55, 0.010, 0.22, 0.010);
    this._shut(g, -0.798, 0.58, -0.55, 0.010, 0.22, 0.010);
    this._shut(g, 0, 0.88, 0.68, 1.48, 0.008, 0.010);
    this._shut(g, 0, 0.86, -0.72, 1.46, 0.008, 0.010);
    this._shut(g, 0.798, 0.70, 0.06, 0.010, 0.36, 1.42);
    this._shut(g, -0.798, 0.70, 0.06, 0.010, 0.36, 1.42);
    for (const sx of [1, -1]) {
      this._part(g, this._box, this._doorSkinMat(), sx * 0.802, 0.64, 0.06, 0.030, 0.42, 1.22);
      this._part(g, this._box, this._cabinMat(), sx * 0.818, 0.78, 0.04, 0.012, 0.16, 0.72);
      this._part(g, this._box, this._mattePostMat(), sx * 0.822, 0.58, 0.42, 0.028, 0.035, 0.12);
    }
    /* Pressed hood panel — replaces the three parallel hood stickers. */
    this._part(g, this._box, this._doorSkinMat(), 0, 0.505, 1.52, 1.32, 0.016, 0.82);
    this._shut(g, 0, 0.516, 1.12, 1.36, 0.010, 0.014);
    this._shut(g, 0, 0.516, 1.92, 1.22, 0.010, 0.014);
    this._shut(g, 0.66, 0.516, 1.52, 0.014, 0.010, 0.80);
    this._shut(g, -0.66, 0.516, 1.52, 0.014, 0.010, 0.80);
    const taxiLip = taxi ? this._archLipMat() : null;
    for (const [wx, wz] of [[0.82, 1.28], [-0.82, 1.28], [0.82, -1.32], [-0.82, -1.32]]) {
      this._archAt(g, wx, 0.333, wz, hull, taxiLip);
      if (taxiLip) {
        const side = Math.sign(wx) || 1;
        /* Tight dark flare — 1.40× opened a cream gap around the tire. */
        this._part(g, this.geo.archFlare, taxiLip, wx - side * 0.01, 0.348, wz, 1.06, 1.00, 1.06);
        this._plugWell(g, wx, 0.333, wz);
      }
    }
    if (wreck) {
      this._part(g, this._box, cabin, 0, 1.26, 0.78, 1.28, 0.34, 0.08, -0.36, 0, 0);
      /* c32: rubber gasket was 1.46x0.46 vs glass 1.38x0.38 — a proud lip
       * around the wreck windshield (weapon 585-720,660-700). Flush now. */
      this._part(g, this._box, this.mats.rubber, 0, 1.28, 0.90, 1.36, 0.36, 0.016, -0.36, 0, 0);
      this._part(g, this._box, pane, 0, 1.28, 0.90, 1.36, 0.36, 0.028, -0.36, 0, 0);
      this._windFace(g, 0, 1.28, 0.912, 1.34, 0.34, -0.36);
      /* c31: A-pillars + header + cowl so the wreck pane stops floating.
       * c32: cowl/header tucked onto the glass rake — the proud 1.08/1.00
       * slab was the windshield lip (weapon 585-720,660-700). */
      this._part(g, this._box, hull, 0.66, 1.26, 0.85, 0.09, 0.46, 0.10, -0.36, 0, 0);
      this._part(g, this._box, hull, -0.66, 1.26, 0.85, 0.09, 0.46, 0.10, -0.36, 0, 0);
      this._part(g, this._box, hull, 0, 1.42, 0.80, 1.36, 0.05, 0.12, -0.36, 0, 0);
      this._part(g, this._box, hull, 0, 1.14, 0.94, 1.38, 0.045, 0.10, -0.36, 0, 0);
      /* Rear glass — street camera looks at the north-facing wreck from the
       * south, so the old front-only streak sat off the (1480,600) rect. */
      this._part(g, this._box, cabin, 0, 1.18, -1.48, 1.24, 0.32, 0.08, 0.20, 0, 0);
      this._part(g, this._box, this.mats.rubber, 0, 1.20, -1.545, 1.40, 0.40, 0.024, 0.20, 0, 0);
      this._part(g, this._box, pane, 0, 1.20, -1.57, 1.32, 0.34, 0.04, 0.20, 0, 0);
      this._windFace(g, 0, 1.20, -1.595, 1.28, 0.32, 0.20);
      /* Side glass seated in the cabin opening — no free-floating shard. */
      this._part(g, this._box, cabin, -0.70, 1.08, -0.10, 0.08, 0.62, 1.35);
      this._part(g, this._box, this.mats.rubber, -0.78, 1.10, -0.08, 0.04, 0.68, 1.36);
      this._part(g, this._box, pane, -0.755, 1.08, -0.10, 0.035, 0.58, 1.22);
      this._windFace(g, -0.80, 1.10, -0.08, 1.18, 0.52, 0, Math.PI * 0.5);
      this._part(g, this._box, pane, 0.755, 1.08, -0.10, 0.035, 0.58, 1.22);
      this._windFace(g, 0.80, 1.10, -0.08, 1.18, 0.52, 0, -Math.PI * 0.5);
    } else {
      this._part(g, this._box, this.mats.darkRoom, 0, 1.30, 0.80, 1.32, 0.40, 0.08, -0.40, 0, 0);
      this._part(g, this._box, this.mats.rubber, 0, 1.32, 0.92, 1.40, 0.44, 0.016, -0.40, 0, 0);
      this._part(g, this._box, pane, 0, 1.32, 0.92, 1.40, 0.44, 0.028, -0.40, 0, 0);
      this._windFace(g, 0, 1.32, 0.932, 1.38, 0.42, -0.40);
      /* c31: frame the windshield — body-color A-pillars + header + cowl.
       * The street taxi's unframed black slab met the cream hood with a
       * hard edge (critic item 10). */
      this._part(g, this._box, hull, 0.70, 1.30, 0.86, 0.09, 0.52, 0.10, -0.40, 0, 0);
      this._part(g, this._box, hull, -0.70, 1.30, 0.86, 0.09, 0.52, 0.10, -0.40, 0, 0);
      this._part(g, this._box, hull, 0, 1.51, 0.76, 1.46, 0.08, 0.16);
      this._part(g, this._box, hull, 0, 1.09, 1.02, 1.50, 0.06, 0.16);
      this._part(g, this._box, this.mats.rubber, 0, 1.28, -1.365, 1.46, 0.36, 0.028, 0.22, 0, 0);
      this._part(g, this._box, pane, 0, 1.28, -1.38, 1.38, 0.30, 0.04, 0.22, 0, 0);
      /* c31: the rear pane hung 0.3 m past the roof's rear edge (z -1.055)
       * — package-shelf filler + C-pillars + deck bar seat the glass. */
      this._part(g, this._box, hull, 0, 1.435, -1.18, 1.40, 0.07, 0.38);
      this._part(g, this._box, hull, 0.66, 1.26, -1.36, 0.09, 0.42, 0.10, 0.22, 0, 0);
      this._part(g, this._box, hull, -0.66, 1.26, -1.36, 0.09, 0.42, 0.10, 0.22, 0, 0);
      this._part(g, this._box, hull, 0, 1.11, -1.46, 1.44, 0.06, 0.14);
      this._part(g, this._box, pane, 0.76, 1.26, -0.12, 0.03, 0.44, 0.92);
      this._part(g, this._box, pane, -0.76, 1.26, -0.12, 0.03, 0.44, 0.92);
      this._windFace(g, -0.78, 1.26, -0.12, 0.90, 0.42, 0, -Math.PI * 0.5);
      this._windFace(g, 0.78, 1.26, -0.12, 0.90, 0.42, 0, Math.PI * 0.5);
    }
    this._part(g, this._box, taxi ? this._taxiCreamMat() : this.mats.darkMetal, 0, wreck ? 1.42 : 1.48, -0.18, 1.36, 0.06, 1.75);
    this._part(g, this._box, this.mats.darkMetal, 0.68, 1.12, 0.78, 0.06, 0.28, 0.10, 0, 0, -0.22);
    this._part(g, this._box, this.mats.darkMetal, -0.68, 1.12, 0.78, 0.06, 0.28, 0.10, 0, 0, 0.22);
    /* c31 bumpers: widened past the hull (1.58 -> 1.70) with wrap-around
     * corner caps + a rubber shut strip into the body — the old same-width
     * slabs read as floating cream blocks off the taxi corners (street
     * 1180-1260, 715-765). */
    this._part(g, this._box, hull, 0, 0.28, 2.08, 1.70, 0.20, 0.28);
    this._part(g, this._box, hull, 0.83, 0.28, 1.94, 0.10, 0.20, 0.34);
    this._part(g, this._box, hull, -0.83, 0.28, 1.94, 0.10, 0.20, 0.34);
    this._part(g, this._box, this.mats.rubber, 0, 0.385, 2.10, 1.60, 0.024, 0.20);
    this._part(g, this._box, chrome, 0, 0.26, 2.18, 1.52, 0.10, 0.12);
    this._part(g, this._box, hull, 0, 0.26, -2.12, 1.70, 0.18, 0.24);
    this._part(g, this._box, hull, 0.83, 0.26, -1.99, 0.10, 0.18, 0.32);
    this._part(g, this._box, hull, -0.83, 0.26, -1.99, 0.10, 0.18, 0.32);
    this._part(g, this._box, this.mats.rubber, 0, 0.355, -2.13, 1.58, 0.022, 0.18);
    this._part(g, this._box, chrome, 0, 0.24, -2.20, 1.48, 0.09, 0.10);
    this._chromeTrim(g, 0, 0.56, 2.16, 0.72, 0.03, 0.03);
    if (taxi) {
      /* Cream belt + dirt skirt stay BETWEEN the axles (wheels at z ±1.28).
       * A full-length 1.64-wide cream slab poked through the wheel wells
       * and read as a whitewall ring; the dirt map tiled as dot rows. */
      this._part(g, this._box, this._taxiCreamMat(), 0, 0.96, 0.02, 1.50, 0.07, 1.72);
      this._uvPart(g, 1.52, 0.22, 1.70, this._taxiDirtMat(), 0, 0.18, 0.02, 0, 0, 0, 1);
      /* c32: hull was one cream mass at 20m (street 1150-1600,560-900).
       * Wider door grooves, B-pillars, window sills, arch shadows, and a
       * readable roof-sign block — value breaks, same material buckets. */
      const groove = this._railMat();
      this._part(g, this._box, groove, 0, 0.572, 1.50, 0.028, 0.012, 0.95);
      this._part(g, this._box, groove, 0.62, 0.50, 1.48, 0.016, 0.08, 0.85);
      this._part(g, this._box, groove, -0.62, 0.50, 1.48, 0.016, 0.08, 0.85);
      this._part(g, this._box, groove, 0.808, 0.52, 1.10, 0.024, 0.028, 1.20);
      this._part(g, this._box, groove, -0.808, 0.52, 1.10, 0.024, 0.028, 1.20);
      this._part(g, this._box, groove, 0.812, 0.68, 0.06, 0.028, 0.52, 1.48);
      this._part(g, this._box, groove, -0.812, 0.68, 0.06, 0.028, 0.52, 1.48);
      this._part(g, this._box, groove, 0.812, 0.44, 0.06, 0.022, 0.018, 1.42);
      this._part(g, this._box, groove, -0.812, 0.44, 0.06, 0.022, 0.018, 1.42);
      this._part(g, this._box, groove, 0.812, 0.68, 0.42, 0.024, 0.50, 0.018);
      this._part(g, this._box, groove, -0.812, 0.68, 0.42, 0.024, 0.50, 0.018);
      this._part(g, this._box, groove, 0.812, 0.68, -0.38, 0.024, 0.50, 0.018);
      this._part(g, this._box, groove, -0.812, 0.68, -0.38, 0.024, 0.50, 0.018);
      const post = this._mattePostMat();
      for (const sx of [1, -1]) {
        this._part(g, this._box, post, sx * 0.805, 1.14, 0.02, 0.055, 0.58, 0.09);
        this._part(g, this._box, post, sx * 0.800, 0.90, 0.04, 0.040, 0.045, 1.18);
        this._part(g, this._box, this.mats.darkMetal, sx * 0.818, 0.62, 0.28, 0.04, 0.035, 0.10);
        this._part(g, this._box, this._taxiDirtMat(), sx * 0.78, 0.42, 1.28, 0.14, 0.08, 0.44);
        this._part(g, this._box, this._taxiDirtMat(), sx * 0.78, 0.42, -1.32, 0.14, 0.08, 0.44);
      }
    }
    const lensOff = this._offLensMat();
    /* Recessed buckets, noon-off glass — no emissive headlight blast. */
    for (const sx of [1, -1]) {
      this._part(g, this._box, this.mats.rubber, sx * 0.48, 0.48, 2.20, 0.34, 0.16, 0.10);
      const lens = sx > 0 && wreck && !taxi ? this.mats.scorch : lensOff;
      this._part(g, this._box, lens, sx * 0.48, 0.48, 2.246, 0.24, 0.10, 0.03);
      this._part(g, this._box, lensOff, sx * 0.48, 0.48, 2.254, 0.19, 0.075, 0.02);
      this._part(g, this._box, this.mats.metal, sx * 0.48, 0.392, 2.24, 0.38, 0.022, 0.06);
    }
    /* Single red lens inset in a dark bezel — no Lego white reverse box. */
    for (const sx of [1, -1]) {
      this._part(g, this._box, hull, sx * 0.50, 0.50, -2.20, 0.34, 0.26, 0.14);
      this._part(g, this._box, this.col.agedChrome || this.mats.darkMetal, sx * 0.50, 0.50, -2.240, 0.28, 0.20, 0.040);
      this._part(g, this._box, this._bezelMat(), sx * 0.50, 0.50, -2.258, 0.22, 0.15, 0.028);
      this._part(g, this._box, this.mats.taillight, sx * 0.50, 0.50, -2.278, 0.10, 0.068, 0.016);
    }
    if (!taxi) {
      /* c31 mirrors: the y 1.18 chrome pair hovered above the loft rake
       * edge (hull top ~1.04 at z 0.72) — rebuilt as pad + stalk + head
       * welded to the beltline at z 0.55 where the hull is full height. */
      for (const msx of [1, -1]) {
        this._part(g, this._box, hull, msx * 0.795, 1.02, 0.55, 0.045, 0.09, 0.08);
        this._part(g, this._box, this.mats.darkMetal, msx * 0.85, 1.05, 0.55, 0.13, 0.022, 0.022);
        this._part(g, this._box, this.mats.darkMetal, msx * 0.915, 1.02, 0.55, 0.032, 0.14, 0.10);
      }
    }
    this._part(g, this._box, this.mats.rubber, 0.81, 1.22, -0.12, 0.018, 0.36, 0.92);
    this._part(g, this._box, this.mats.rubber, -0.81, 1.22, -0.12, 0.018, 0.36, 0.92);
    if (bodyMat === this.col.taxi || bodyMat === this.mats.sedanTaxi) {
      this._part(g, this._box, this.mats.darkMetal, 0, 1.52, -0.12, 0.42, 0.12, 0.85);
      this._part(g, this._box, this.mats.darkMetal, 0, 1.60, -0.10, 0.56, 0.18, 0.24);
      this._part(g, this._box, this._taxiCreamMat(), 0, 1.66, -0.10, 0.48, 0.10, 0.18);
    }
    if (wreck && !taxi) {
      this._part(g, this._box, this.mats.scorch, 0.2, 0.46, 1.35, 0.72, 0.14, 0.62);
      this._part(g, this._box, this.mats.rust, 0.82, 0.56, 0.18, 0.1, 0.26, 0.5, 0, 0, 0.28);
    } else if (wreck) {
      this._part(g, this._box, this.mats.scorch, 0.2, 0.42, 1.42, 0.62, 0.10, 0.48);
    }
    const wheels = [[-0.82, 1.28], [0.82, 1.28], [-0.82, -1.32], [0.82, -1.32]];
    const wScl = taxi ? 0.85 : 1;
    for (const [wx, wz] of wheels) {
      this._wheelAt(g, wx, 0.333 * (taxi ? 0.88 : 1), wz, wreck, wScl);
      this._wheelGround(x, z, yaw, wx, wz, scale);
    }
    this.group.add(g);
    this._mergeMeshes(g);
    this._rotAabb(x, z, yaw, 1.15 * scale, 2.35 * scale, 1.65 * scale);
    this._contactAt(x, z, 1.85 * scale, 2.55 * scale, yaw);
  }

  _van(x, z, yaw, burning, scale = 1, paint = '') {
    const g = new THREE.Group();
    g.position.set(x, burning ? 0.05 : 0, z);
    g.rotation.y = yaw;
    g.scale.setScalar(scale);
    if (burning) g.rotation.z = 0.04;
    const charcoal = paint === 'charcoal' || burning;
    const body = charcoal ? this._charcoalVanMat() : this._rustVanMat();
    const hull = body;
    const cargo = hull;
    const loftMat = charcoal ? this._charcoalHullMat() : body;
    const pane = this.col.wind || this.mats.windshield || this.mats.cabGlass;
    const chrome = this.col.agedChrome || this.mats.chrome || this.mats.metal;
    this._loftHull(g, 'van', loftMat);
    this._part(g, this._box, this._cabinMat(), 0, 1.05, 0.35, 1.28, 0.62, 1.55);
    this._part(g, this._box, cargo, 0.90, 1.05, -0.28, 0.04, 0.08, 1.10);
    this._part(g, this._box, cargo, -0.90, 1.05, -0.28, 0.04, 0.08, 1.10);
    /* Recessed cargo seams (inset past the loft wall) — the old 3cm
     * darkMetal strips sat proud and read as floating sticker-slots. */
    this._shut(g, 0.868, 1.34, -0.35, 0.012, 1.10, 0.012);
    this._shut(g, -0.868, 1.34, -0.35, 0.012, 1.10, 0.012);
    this._shut(g, 0.868, 1.34, -1.55, 0.012, 1.10, 0.012);
    this._shut(g, -0.868, 1.34, -1.55, 0.012, 1.10, 0.012);
    this._shut(g, 0.868, 1.05, -0.95, 0.012, 0.012, 2.40);
    this._shut(g, -0.868, 1.05, -0.95, 0.012, 0.012, 2.40);
    this._shut(g, 0.868, 0.62, -0.95, 0.012, 0.012, 2.35);
    this._shut(g, -0.868, 0.62, -0.95, 0.012, 0.012, 2.35);
    this._shut(g, 0.868, 1.68, -0.95, 0.010, 0.010, 2.20);
    this._shut(g, -0.868, 1.68, -0.95, 0.010, 0.010, 2.20);
    this._shut(g, 0.868, 1.36, -0.95, 0.010, 1.08, 0.010);
    this._shut(g, -0.868, 1.36, -0.95, 0.010, 1.08, 0.010);
    const skin = charcoal ? this._doorSkinMat() : hull;
    for (const sx of [1, -1]) {
      this._part(g, this._box, skin, sx * 0.888, 1.20, -0.95, 0.024, 1.00, 1.16);
      this._part(g, this._box, skin, sx * 0.888, 1.20, -0.32, 0.024, 1.00, 0.56);
      /* c31: the _cabinMat card here sat proud of the door skin and read
       * as a flat brown sticker on the balcony van side (380-420,470-500)
       * — deleted. */
      this._part(g, this._box, this._mattePostMat(), sx * 0.910, 1.02, -0.52, 0.030, 0.036, 0.14);
      /* c31: the two _grooveHiMat rails (0x7a7670, rough 0.62) at x 0.902
       * were coplanar with the 0.900 door-skin face — z-fighting white
       * dash rows at van (825-920,402-410)/(827-915,502-510). Darker matte
       * rub-rails pushed fully proud of the skin. */
      this._part(g, this._box, this._railMat(), sx * 0.916, 1.68, -0.95, 0.018, 0.022, 2.20);
      this._part(g, this._box, this._railMat(), sx * 0.916, 0.70, -0.95, 0.018, 0.022, 2.20);
    }
    const grit = charcoal ? hull : (this.mats.dirt || hull);
    this._uvPart(g, 1.70, 0.42, 0.03, grit, 0, 0.48, -0.95, 0, 0, 0, 0.7);
    this._part(g, this._box, chrome, 0.92, 1.02, -0.55, 0.05, 0.04, 0.16);
    this._part(g, this._box, chrome, -0.92, 1.02, -0.55, 0.05, 0.04, 0.16);
    this._uvPart(g, 1.68, 0.08, 2.45, hull, 0, 1.94, -0.95, 0, 0, 0, 0.9);
    /* Roof ribs + vent hatch so the cargo roof reads as pressed panels, not
     * one flat slab — this is the part of the van the balcony stop sees
     * (fix 8). */
    const matte = this._mattePostMat();
    for (const rz of [-1.72, -0.95, -0.18]) {
      this._part(g, this._box, matte, 0, 1.995, rz, 1.58, 0.028, 0.075);
    }
    this._part(g, this._box, matte, 0.34, 2.005, -1.34, 0.36, 0.06, 0.36);
    this._part(g, this._box, this._doorSkinMat(), 0.34, 2.042, -1.34, 0.27, 0.02, 0.27);
    this._shut(g, 0.34, 2.03, -1.34, 0.28, 0.008, 0.28);
    this._shut(g, 0.34, 2.03, -1.34, 0.008, 0.04, 0.28);
    this._part(g, this._box, matte, -0.55, 2.0, -0.56, 0.16, 0.05, 0.16);
    this._uvPart(g, 0.04, 0.85, 2.20, grit, 0.868, 1.05, -0.95, 0, 0, 0, 0.8);
    /* Extra cargo-face grime so the sun-side slab cannot read as a fridge. */
    this._uvPart(g, 0.03, 0.72, 2.05, grit, 0.870, 0.72, -0.95, 0, 0, 0, 0.8);
    this._uvPart(g, 0.03, 0.72, 2.05, grit, -0.870, 0.72, -0.95, 0, 0, 0, 0.8);
    this._uvPart(g, 1.55, 0.28, 0.03, grit, 0, 0.58, -0.18, 0, 0, 0, 0.7);
    this._uvPart(g, 1.55, 0.22, 0.03, grit, 0, 0.52, -1.72, 0, 0, 0, 0.7);
    /* Door slab in vanBlack warm-grey paint (fix 8, c20): as darkMetal the
     * whole rear read as a silhouette against the sunlit wall behind it. */
    this._part(g, this._box, hull, 0, 1.18, -2.18, 1.62, 1.35, 0.14);
    /* Rear doors re-cut (fix 8, c19): visible seam gaps, hinges, a handle,
     * matte glass and a grime band — the old rear was one flat slab with a
     * mirror-blue windshield-gradient pane glued on. */
    // Cut seams: center split + top/bottom shut-lines in near-black rubber.
    this._part(g, this._box, this.mats.rubber, 0, 1.18, -2.262, 0.030, 1.30, 0.012);
    this._part(g, this._box, this.mats.rubber, 0, 1.845, -2.262, 1.56, 0.028, 0.012);
    this._part(g, this._box, this.mats.rubber, 0, 0.52, -2.262, 1.56, 0.028, 0.012);
    // Hinge pairs on both outer door edges.
    for (const sx of [1, -1]) for (const hy of [0.78, 1.58]) {
      this._part(g, this._box, this.mats.metal, sx * 0.775, hy, -2.272, 0.055, 0.15, 0.035);
    }
    // Latch handle right of the center seam.
    this._part(g, this._box, this.mats.metal, 0.145, 1.00, -2.278, 0.19, 0.035, 0.035);
    this._part(g, this._box, this.mats.darkMetal, 0.06, 1.00, -2.272, 0.05, 0.09, 0.03);
    // Matte per-door panes seated in rubber (no windshield streak texture).
    for (const sx of [1, -1]) {
      this._part(g, this._box, this.mats.rubber, sx * 0.38, 1.50, -2.268, 0.56, 0.40, 0.02);
      this._part(g, this._box, this.col.pane || this.mats.windowDark || this.mats.darkRoom, sx * 0.38, 1.50, -2.280, 0.48, 0.32, 0.02);
    }
    /* Road grime band across the lower third of the doors. Dark gutter/soak
     * tone — the first try with mats.dirt rendered as a bright sand slab. */
    this._uvPart(g, 1.58, 0.44, 0.02, charcoal ? hull : (this.mats.gutter || this.mats.soak || this.mats.rust), 0, 0.58, -2.268, 0, 0, 0, 0.8);
    this._uvPart(g, 1.58, 0.10, 0.72, grit, 0, 0.48, 1.92, 0, 0, 0, 0.7);
    this._uvPart(g, 1.58, 0.04, 0.62, grit, 0, 0.62, 1.92, 0, 0, 0, 0.7);
    if (!charcoal) {
      this._part(g, this._box, this.mats.rust, 0.55, 0.58, 1.95, 0.42, 0.06, 0.55);
      this._part(g, this._box, this.mats.rust, -0.48, 0.50, 2.10, 0.36, 0.05, 0.40);
    }
    /* Pressed hood stamp — the old three 1 cm dark strips read as
     * racing-stripe stickers on scope (940,430)-(1530,680). */
    this._part(g, this._box, this._doorSkinMat(), 0, 0.768, 1.78, 1.28, 0.014, 0.92);
    this._shut(g, 0, 0.778, 1.32, 1.32, 0.010, 0.014);
    this._shut(g, 0, 0.778, 2.22, 1.18, 0.010, 0.014);
    this._shut(g, 0.64, 0.778, 1.78, 0.014, 0.010, 0.90);
    this._shut(g, -0.64, 0.778, 1.78, 0.014, 0.010, 0.90);
    this._shut(g, 0, 0.52, 1.14, 1.68, 0.010, 0.012);
    this._shut(g, 0, 0.52, 2.28, 1.58, 0.010, 0.012);
    this._shut(g, 0.848, 0.52, 1.78, 0.012, 0.48, 1.28);
    this._shut(g, -0.848, 0.52, 1.78, 0.012, 0.48, 1.28);
    this._shut(g, 0, 0.52, 1.78, 1.70, 0.010, 0.010);
    if (!charcoal) this._part(g, this._box, this.mats.rust, 0.62, 0.48, 2.05, 0.28, 0.08, 0.36);
    /* c31 windshield re-seat: the pane assembly sat at z ~2.03 (the old
     * box-cab position) — 0.6 m in FRONT of the loft's windshield rake
     * (z 1.48->1.08, y 0.74->1.32), floating over the hood with air gaps
     * on every edge (scope crop). Moved onto the rake plane (center
     * z 1.28, y 1.03, tilt matching atan(0.40/0.58) = 0.605) and framed
     * with body-color A-pillars + header + cowl so the glass reads seated. */
    const wsTilt = -0.605;
    this._part(g, this._box, this.mats.darkRoom, 0, 1.02, 1.26, 1.32, 0.58, 0.06, wsTilt, 0, 0);
    this._part(g, this._box, this.mats.rubber, 0, 1.041, 1.296, 1.58, 0.64, 0.040, wsTilt, 0, 0);
    this._part(g, this._box, pane, 0, 1.054, 1.315, 1.42, 0.52, 0.035, wsTilt, 0, 0);
    this._windFace(g, 0, 1.063, 1.328, 1.40, 0.50, wsTilt);
    this._part(g, this._box, hull, 0.82, 1.04, 1.30, 0.11, 0.72, 0.10, wsTilt, 0, 0);
    this._part(g, this._box, hull, -0.82, 1.04, 1.30, 0.11, 0.72, 0.10, wsTilt, 0, 0);
    this._part(g, this._box, hull, 0, 1.33, 1.10, 1.78, 0.09, 0.14);
    this._part(g, this._box, hull, 0, 0.76, 1.49, 1.78, 0.07, 0.18);
    this._part(g, this._box, this.mats.darkMetal, 0.30, 0.80, 1.46, 0.34, 0.022, 0.030, wsTilt, 0, -0.10);
    this._part(g, this._box, this.mats.darkMetal, -0.34, 0.80, 1.46, 0.34, 0.022, 0.030, wsTilt, 0, 0.10);
    this._part(g, this._box, pane, 0.77, 1.24, 0.62, 0.03, 0.36, 0.78);
    this._part(g, this._box, pane, -0.77, 1.24, 0.62, 0.03, 0.36, 0.78);
    this._part(g, this._box, hull, 0, 0.40, 2.42, 1.68, 0.22, 0.32);
    this._part(g, this._box, this.mats.darkMetal, 0, 0.36, 2.52, 1.58, 0.10, 0.14);
    this._part(g, this._box, hull, 0, 0.36, -2.20, 1.68, 0.22, 0.28);
    this._part(g, this._box, this.mats.darkMetal, 0, 0.32, -2.28, 1.56, 0.10, 0.12);
    for (const [wx, wz] of [[0.88, 1.48], [-0.88, 1.48], [0.88, -1.38], [-0.88, -1.38]]) {
      this._archAt(g, wx, 0.333, wz, hull);
    }
    if (charcoal) {
      /* Cab greenhouse + near-side arch so the balcony 3/4 reads as a van.
       * c31: the old side glass ran to z 2.1 (past the rake, hanging over
       * the hood) and a SECOND front pane doubled the re-seated windshield
       * — both were the scope-frame floating panes. Side glass now sits on
       * the full-height cab section only; front pane comes from the shared
       * rake assembly above. */
      this._part(g, this._box, this.mats.rubber, 0.878, 1.38, 0.42, 0.05, 0.40, 0.74);
      this._part(g, this._box, pane, 0.906, 1.38, 0.42, 0.030, 0.32, 0.62);
      this._windFace(g, 0.925, 1.38, 0.42, 0.60, 0.30, 0, -Math.PI * 0.5);
      this._part(g, this._box, hull, 0.92, 0.42, 1.48, 0.18, 0.24, 0.68);
      this._archAt(g, 0.94, 0.333, 1.48, hull);
    }
    /* Recessed buckets, noon-off glass — no emissive headlight blast. */
    const lensOff = this._offLensMat();
    for (const sx of [1, -1]) {
      this._part(g, this._box, this.mats.rubber, sx * 0.52, 0.54, 2.705, 0.40, 0.19, 0.09);
      const lens = sx > 0 && burning ? this.mats.scorch : lensOff;
      this._part(g, this._box, lens, sx * 0.52, 0.54, 2.726, 0.26, 0.10, 0.03);
      this._part(g, this._box, lensOff, sx * 0.52, 0.54, 2.734, 0.21, 0.075, 0.02);
      this._part(g, this._box, this.mats.metal, sx * 0.52, 0.452, 2.72, 0.40, 0.022, 0.06);
    }
    /* Single red lens inset in a dark bezel per side. */
    for (const sx of [1, -1]) {
      this._part(g, this._box, hull, sx * 0.58, 1.16, -2.20, 0.38, 0.32, 0.18);
      this._part(g, this._box, this.col.agedChrome || this.mats.darkMetal, sx * 0.58, 1.16, -2.252, 0.30, 0.24, 0.048);
      this._part(g, this._box, this._bezelMat(), sx * 0.58, 1.16, -2.276, 0.22, 0.16, 0.030);
      this._part(g, this._box, this.mats.taillight, sx * 0.58, 1.16, -2.298, 0.10, 0.078, 0.016);
    }
    /* c31 mirrors: the old chrome blocks hovered at y 1.42 over the HOOD
     * (hull top there is only ~0.6-0.9) — the "two mirror blocks fully
     * detached" in scope. Rebuilt as pad-on-body + stalk + head welded to
     * the full-height cab side at z 1.02 (hull top 1.38 there). */
    for (const sx of [1, -1]) {
      this._part(g, this._box, hull, sx * 0.885, 1.30, 1.02, 0.045, 0.11, 0.09);
      this._part(g, this._box, this.mats.darkMetal, sx * 0.95, 1.325, 1.02, 0.15, 0.024, 0.024);
      this._part(g, this._box, this.mats.darkMetal, sx * 1.025, 1.28, 1.02, 0.038, 0.17, 0.11);
      this._part(g, this._box, this._cabinMat(), sx * 1.025, 1.28, 0.962, 0.030, 0.13, 0.008);
    }
    this._uvPart(g, 0.04, 0.55, 0.70, hull, 0.90, 1.02, -0.85, 0, 0, 0, 0.7);
    this._part(g, this._box, this.mats.darkMetal, 0.92, 1.02, -0.85, 0.02, 0.02, 0.70);
    if (burning) {
      this._part(g, this._box, this.mats.scorch, -0.12, 0.2, -0.55, 0.55, 0.14, 0.62);
    }
    if (scale > 1.2) g.rotation.z += 0.05;
    for (const [wx, wz] of [[-0.88, 1.48], [0.88, 1.48], [-0.88, -1.38], [0.88, -1.38]]) {
      this._wheelAt(g, wx, 0.333, wz, burning);
      this._wheelGround(x, z, yaw, wx, wz, scale);
    }
    this.group.add(g);
    this._mergeMeshes(g);
    /* hx 1.05 hugs the loft (~1.74 m wide) — 1.20 inflated the rotated
     * plaza AABB past the neighboring pallet. */
    this._rotAabb(x, z, yaw, 1.05 * scale, 2.4 * scale, 2.2 * scale);
    this._contactAt(x, z, 1.95 * scale, 2.65 * scale, yaw);
  }

  _lamps() {
    const spots = [
      [-6.6, 2.2, true], [4.7, 8.8, false], [-6.6, 16, false],
      [4.7, 28, false], [-6.6, 40, true], [4.7, 54, false],
      [-6.6, 70, false], [4.7, 82, false],
      // Suq + plaza
      [16.1, 14, false], [17.9, 34, false], [16.1, 60, false], [17.9, 74, false],
      [11.2, 55.6, false],
    ];
    for (const [x, z, shadow] of spots) this._lamp(x, z, shadow);
  }

  _lamp(x, z, shadow) {
    const inward = Math.sign(-x);
    const base = new THREE.Mesh(this.geo.lampBase, this.mats.darkMetal);
    base.position.set(x, 0.12, z);
    base.castShadow = true;
    this.group.add(base);
    const pole = new THREE.Mesh(this.geo.lampPole, this.mats.darkMetal);
    pole.position.set(x, 2.95, z);
    pole.castShadow = true;
    this.group.add(pole);
    const arm = new THREE.Mesh(this.geo.lampArm, this.mats.metal);
    arm.position.set(x, 5.65, z);
    arm.rotation.y = inward > 0 ? 0 : Math.PI;
    this.group.add(arm);
    const head = new THREE.Mesh(this.geo.lampHead, this.mats.darkMetal);
    head.position.set(x + inward * 0.92, 5.48, z);
    head.rotation.z = inward * 0.15;
    this.group.add(head);
    const lens = new THREE.Mesh(this._box, this.mats.lamp);
    lens.position.set(x + inward * 0.92, 5.4, z);
    lens.scale.set(0.22, 0.05, 0.16);
    this.group.add(lens);
    this._aabb(x, 3.0, z, 0.16, 6.0, 0.16);
    this._spot(COLORS.SODIUM, 0.18, 8, 0.48, x + inward * 0.85, 5.35, z, x * 0.15, 0.2, z, false);
  }

  _fire(rng) {
    // Scorch + flames anchored to the burning van's plaza position.
    const fx = 10.9, fz = 42.6;
    for (let i = 0; i < 3; i++) {
      const p = new THREE.Mesh(new THREE.PlaneGeometry(0.32 + i * 0.06, 0.42 + i * 0.05), this.mats.fire);
      p.position.set(fx + (i - 1) * 0.08, 0.72 + i * 0.05, fz + (i % 2) * 0.05);
      p.rotation.y = 1.15 + i * 0.35;
      this.group.add(p);
      this._flames.push(p);
      p.userData.ph = 0.42 + i * 0.05;
      p.userData.fr = 14 + i * 5;
    }
    const sc = new THREE.Mesh(this.geo.puddle, this.mats.scorch);
    sc.position.set(fx, 0.016, fz);
    sc.scale.set(1.15, 1, 0.85);
    this.group.add(sc);
    /* c31 rubble: the old ring was 18 same-tone rust blocks all sitting
     * proud at y 0.06-0.14 — "uniform red Lego blocks" (balcony 234-359,
     * 664-703). Now: wider size spread, most half-buried in the ground,
     * strong tumble rotations, and every third piece swaps to a concrete
     * chip so the pile breaks tone. */
    for (let i = 0; i < 6; i++) {
      const a = rng() * Math.PI * 2;
      const r = 0.25 + rng() * 0.7;
      const buried = rng() > 0.42;
      const y = buried ? 0.008 + rng() * 0.022 : 0.035 + rng() * 0.06;
      this._push(
        i % 3 === 0 ? this.q.chip : this.q.debris,
        fx + Math.cos(a) * r, y, fz + Math.sin(a) * r,
        (rng() - 0.5) * 1.3, rng() * 6.28, (rng() - 0.5) * 1.3,
        0.35 + rng() * 1.55, 0.40 + rng() * 0.75, 0.45 + rng() * 1.25,
      );
    }
    this._fireLight = this._point(COLORS.FIRE, 2.2, 6.5, fx, 0.95, fz, 1.8);
  }

  _faceWindow(px, y, pz, face, lit, along = 0) {
    const alongZ = Math.abs(along) > 0.5;
    const dummy = () => 0.4;
    const cells = [
      [-0.64, -0.74, true],
      [0.64, -0.74, true],
      [-0.64, 0.74, true],
      [0.64, 0.74, true],
    ];
    for (const [t, yo, on] of cells) {
      const x = alongZ ? px + t : px;
      const z = alongZ ? pz : pz + t;
      this._queueWindow(x, y + yo, z, face, on, dummy, along, true);
    }
  }

  _pipeRun(x, z, h, side = Math.sign(x) || 1) {
    const wallX = side * (INNER - 0.06);
    this.addCyl(wallX, h * 0.42, z, 0.05, h * 0.82, this.mats.darkMetal, false);
    this.addCyl(wallX + side * 0.07, h * 0.36, z + 0.10, 0.038, h * 0.68, this.mats.rust, false);
    this.addBox(wallX + side * 0.10, 1.12, z, 0.20, 0.26, 0.28, this.mats.darkMetal, false, 1);
    this.addBox(wallX + side * 0.10, 2.02, z, 0.18, 0.20, 0.24, this.mats.rust, false, 1);
    this._contactAt(wallX + side * 0.12, z, 0.28, 0.30);
    this._stainDecal('stainC', wallX + side * 0.08, 0.85, z, 0.42, 1.15, side > 0 ? -Math.PI * 0.5 : Math.PI * 0.5);
  }

  _junctionBox(x, y, z, yaw) {
    const g = new THREE.Group();
    g.position.set(x, y, z);
    g.rotation.y = yaw;
    this._part(g, this._box, this.mats.darkMetal, 0, 0, 0.06, 0.36, 0.44, 0.14);
    this._part(g, this._box, this.mats.rust, 0, 0, 0.14, 0.30, 0.36, 0.04);
    this._part(g, this._cyl, this.mats.darkMetal, 0, 0.38, 0.02, 0.032, 0.48, 0.032);
    this._part(g, this._cyl, this.mats.rust, -0.10, -0.36, 0.02, 0.028, 0.38, 0.028);
    this._part(g, this._box, this.mats.metal, 0.08, 0.06, 0.15, 0.06, 0.06, 0.03);
    this.group.add(g);
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    this._contactAt(x + sa * 0.06, z + ca * 0.06, 0.32, 0.26);
    this._stainDecal('stainC', x + sa * 0.04, y - 0.52, z + ca * 0.04, 0.42, 1.05, yaw);
  }

  _sodiumCowl(x, y, z) {
    this.addBox(x, y + 0.18, z + 0.28, 0.08, 0.08, 0.62, this.mats.darkMetal, false, 1);
    const head = new THREE.Mesh(this.geo.lampHead, this.mats.darkMetal);
    head.position.set(x, y, z);
    head.scale.set(1.15, 1.1, 1.15);
    head.rotation.z = 0.18;
    head.castShadow = true;
    this.group.add(head);
    const lens = new THREE.Mesh(this._box, this.mats.lamp);
    lens.position.set(x, y - 0.05, z);
    lens.scale.set(0.16, 0.04, 0.12);
    this.group.add(lens);
    this.addBox(x, y + 0.08, z, 0.28, 0.06, 0.2, this.mats.darkMetal, false, 1);
  }

  _utilBoxMat() {
    if (this._utilBox) return this._utilBox;
    const m = new THREE.MeshStandardMaterial({
      color: 0x6a6860,
      roughness: 0.88,
      metalness: 0.08,
      envMapIntensity: 0.12,
    });
    m.customProgramCacheKey = () => 'util-box30';
    this._capGlass(m, 0.42);
    this._utilBox = m;
    return m;
  }

  _acHang(x, y, z, yaw = 0) {
    const g = new THREE.Group();
    g.position.set(x, y, z);
    g.rotation.y = yaw;
    const shell = this._utilBoxMat();
    this._part(g, this._box, this.mats.plasterSand || this.mats.plaster, 0, 0.02, -0.42, 1.42, 0.88, 0.18);
    this._part(g, this._box, this.mats.darkMetal, 0, 0.02, -0.34, 1.28, 0.74, 0.08);
    this._part(g, this._box, shell, 0, 0, 0.06, 1.16, 0.62, 0.68);
    this._part(g, this._box, this.mats.darkMetal, 0, 0, 0.38, 1.00, 0.48, 0.06);
    this._part(g, this.geo.acFan, this.mats.darkMetal, 0, 0, 0.42, 0.7, 0.7, 0.7, Math.PI * 0.5, 0, 0);
    this._part(g, this._box, shell, -0.32, 0, 0.4, 0.03, 0.48, 0.04);
    this._part(g, this._box, shell, -0.12, 0, 0.4, 0.03, 0.48, 0.04);
    this._part(g, this._box, shell, 0.12, 0, 0.4, 0.03, 0.48, 0.04);
    this._part(g, this._box, shell, 0.32, 0, 0.4, 0.03, 0.48, 0.04);
    this._shut(g, 0, 0.02, 0.405, 1.02, 0.010, 0.018);
    this._shut(g, 0, 0, 0.405, 0.010, 0.50, 0.018);
    this._uvPart(g, 1.10, 0.16, 0.04, this._taxiDirtMat(), 0, -0.24, 0.40, 0, 0, 0, 1);
    this._part(g, this._box, this.mats.rust, -0.44, -0.38, 0.02, 0.22, 0.12, 0.78);
    this._part(g, this._box, this.mats.darkMetal, -0.44, -0.12, -0.30, 0.22, 0.56, 0.16);
    this._part(g, this._box, this.mats.rust, 0.44, -0.38, 0.02, 0.22, 0.12, 0.78);
    this._part(g, this._box, this.mats.darkMetal, 0.44, -0.12, -0.30, 0.22, 0.56, 0.16);
    this._part(g, this._box, this.mats.darkMetal, 0, 0.06, -0.22, 0.10, 0.10, 0.36);
    this._part(g, this._box, this.mats.rust, 0, -0.72, -0.38, 0.18, 1.15, 0.06);
    this.group.add(g);
    const ca = Math.cos(yaw);
    const sa = Math.sin(yaw);
    this._stainDecal('stainC', x + sa * 0.06, y - 1.05, z + ca * 0.06, 0.78, 1.85, yaw);
    this._stainDecal('stainA', x + sa * 0.05, y - 0.55, z + ca * 0.05, 0.55, 1.15, yaw);
  }

  _dishHang(x, y, z, tilt = -0.55, yaw = 0) {
    const dish = new THREE.Mesh(this.geo.dish, this.mats.darkMetal);
    dish.position.set(x, y, z);
    dish.rotation.z = tilt;
    dish.rotation.y = yaw;
    dish.scale.setScalar(0.62);
    dish.castShadow = true;
    this.group.add(dish);
    this.addCyl(x, y - 0.55, z, 0.055, 1.15, this.mats.darkMetal, false);
    this.addBox(x, y - 1.05, z, 0.42, 0.08, 0.42, this.mats.darkMetal, false, 1);
  }

  _mastHang(x, y, z, h = 3.2) {
    this.addCyl(x, y + h * 0.5, z, 0.07, h, this.mats.metal, false);
    this.addBox(x, y + h * 0.42, z, 1.85, 0.055, 0.055, this.mats.darkMetal, false, 1);
    this.addBox(x, y + h * 0.68, z, 1.45, 0.05, 0.05, this.mats.metal, false, 1);
    this.addBox(x, y + h * 0.88, z, 0.95, 0.045, 0.045, this.mats.darkMetal, false, 1);
    this._junctionBox(x + 0.22, y + h * 0.55, z, 0);
  }

  _overhangRow(z, y) {
    this._junctionBox(-4.98, y - 0.85, z, Math.PI * 0.5);
    this._junctionBox(4.98, y - 0.90, z + 0.22, -Math.PI * 0.5);
    this._pipeRun(-4.95, z - 0.35, 3.2, -1);
    this._pipeRun(4.95, z + 0.40, 3.0, 1);
  }

  _streetAc() {
    this._junctionBox(4.98, 2.15, 16.35, -Math.PI * 0.5);
    this._pipeRun(4.95, 16.6, 3.4, 1);
    this._stainDecal('stainC', 4.92, 2.35, 16.35, 0.85, 2.05, -Math.PI * 0.5);
    this._stainDecal('stainA', 4.92, 2.85, 16.55, 0.55, 1.25, -Math.PI * 0.5);
  }

  _orielGrid(x, z, face, rng, floors = 1) {
    this._simpleWindow(x + face * 0.08, 2.35, z, face, true, 0);
    this._junctionBox(x + face * 0.12, 3.15, z + 0.55, face > 0 ? 0 : Math.PI);
    this._pipeRun(x + face * 0.04, z - 0.45, 3.1, face);
  }

  _frustumKit(rng) {
    this._overhangRow(12.4, 3.85);
    this._overhangRow(33.2, 3.75);
    this._overhangRow(70.4, 3.85);
    this._streetAc();
    this._orielGrid(-5.05, 12.4, 1, rng, 1);
    this._orielGrid(5.05, 33.6, -1, rng, 1);
    this._orielGrid(-5.05, 70.8, 1, rng, 1);
    this._mastHang(-4.85, 8.2, 32.4, 2.4);
    const sideWins = [
      [-INNER, 2.15, 1.45, 1, true, 0],
      [INNER, 2.15, 1.65, -1, true, 0],
      [-INNER, 2.15, 17.4, 1, true, 0],
      [INNER, 3.72, 33.2, -1, true, 0],
      [-INNER, 2.15, 76.2, 1, true, 0],
      [INNER, 3.72, 74.2, -1, true, 0],
    ];
    for (let i = 0; i < sideWins.length; i++) {
      const [x, y, z, face, , along] = sideWins[i];
      this._simpleWindow(x, y, z, face, i % 2 === 0, along);
    }
  }

  _sealCanyons() {
    const seals = [
      // West-row gap seals (track INNER = 7).
      [-INNER - 1.85, 6.4, 10.85, 4.2, 12.8, 1.25],
      [-INNER - 1.95, 7.0, 40.4, 4.2, 14.0, 2.3],
      [-INNER - 1.95, 7.0, 58.1, 4.2, 14.0, 2.5],
      [-INNER - 1.4, 6.0, 76.8, 2.4, 4.2, 3.4],
      // West face seam fills — split so they don't stamp as one rectangle.
      // Yard north lip + header above the extract gate (kept shallow so it
      // reads as a lintel, not a ceiling over the whole pad).
      [0.00, 3.40, -0.48, 14.80, 5.50, 0.85],
      [0.00, 8.4, 85.6, 8.6, 2.6, 1.8],
      // East-row seam seals along the Suq (small gaps at lot joins).
      [23.6, 5.6, 8.4, 4.6, 11.2, 1.2],
      [23.6, 5.2, 77.8, 4.6, 10.4, 1.4],
    ];
    for (const [x, y, z, sx, sy, sz] of seals) {
      this.addBox(x, y, z, sx, sy, sz, this._plasterOf({ x, z }), true, this._plasterTileOf({ x, z }));
    }
    this.addBox(-7.55, 2.40, 13.6, 1.20, 3.20, 1.80, this._plasterOf({ x: -7.55, z: 13.6 }), true, 2.2);
    this.addBox(-7.70, 4.80, 15.8, 1.10, 2.60, 1.50, this._plasterOf({ x: -7.7, z: 15.8 }), true, 4.6);
    this.addBox(-7.55, 2.60, 70.2, 1.20, 3.40, 2.20, this._plasterOf({ x: -7.55, z: 70.2 }), true, 2.4);
    this.addBox(-7.70, 5.10, 73.1, 1.10, 2.80, 2.40, this._plasterOf({ x: -7.7, z: 73.1 }), true, 5.2);
    /* Soffit under the extract-gate header: shadowed warm brown with wood
     * joist beams and a pale front edge lip so it reads as a built roof
     * underside, not a void-black rectangle (fix 8). */
    this.addBox(0, 7.06, 85.6, 8.62, 0.14, 1.82, this.mats.soffit || this.mats.interior, false, 1);
    const eJoist = this.col.joist || this.mats.wood;
    for (const bx of [-3.3, -1.65, 0, 1.65, 3.3]) {
      this.addBox(bx, 6.94, 85.6, 0.18, 0.16, 1.86, eJoist, false, 1);
      this.addBox(bx, 6.88, 84.72, 0.26, 0.26, 0.18, this.col.trim || this.mats.concrete, false, 0.7);
      this.addBox(bx, 6.88, 86.48, 0.26, 0.26, 0.18, this.col.trim || this.mats.concrete, false, 0.7);
    }
    this.addBox(0, 7.02, 84.76, 8.62, 0.16, 0.14, this.col.trim || this.mats.concrete, false, 1);
    // Bridges over Cut A / Cut B: the block mass continues above the
    // passages, so the cuts read as souk archways, not slots to the sky.
    for (const z of [20, 64]) {
      /* Upper mass only — a solid soffit+bridge down to y=3.6 sealed the
       * cut so joists could never stripe the floor. Keep the block reading
       * above the passage; let sun slip between the joists. */
      this.addBox(9, 7.15, z, 8.0, 2.1, 4.0, this._plasterOf({ x: 9, z }), true, this._plasterTileOf({ x: 9, z }));
      /* Cut flank plaster treatment — the maroon/cream slabs the cut stop stares at. */
      this._stringCourse(9, 3.05, z - 1.92, 7.4, 0.14, 0.22, 1.05);
      this._stringCourse(9, 3.05, z + 1.92, 7.4, 0.14, 0.22, 1.05);
      this.addBox(9, 0.42, z - 1.90, 7.6, 0.84, 0.16, this._dirtBand(), false, 0.7);
      this.addBox(9, 0.42, z + 1.90, 7.6, 0.84, 0.16, this._dirtBand(), false, 0.7);
      this._simpleWindow(7.2, 2.15, z - 1.95, 1, true, Math.PI * 0.5);
      this._simpleWindow(10.6, 2.15, z + 1.95, -1, false, Math.PI * 0.5);
      this.addBox(9, 8.35, z, 8.3, 0.3, 4.3, this.mats.concrete, false, 1.3);
      const joist = this.col.joist || this.mats.wood;
      const pocket = this.col.trim || this.mats.concrete;
      for (let i = 0; i < 9; i++) {
        const bx = 5.65 + i * 0.84;
        this.addBox(bx, 3.505, z, 0.30, 0.06, 4.02, this.mats.warmRoom || this.mats.darkRoom, false, 1);
        const j = this.addBox(bx, 3.435, z, 0.20, 0.18, 4.18, joist, false, 1);
        j.castShadow = true;
        j.receiveShadow = true;
        /* Art-directed floor stripes in the framed cut (sun throws the
         * real umbra ~8 m west, off the walkable pale floor). */
        const stripe = this.addBox(bx + 0.85, 0.016, z, 0.46, 0.010, 3.85, this._joistShadeMat(), false, 1);
        stripe.castShadow = false;
        stripe.receiveShadow = false;
        if (i >= 6) {
          const near = this.addBox(bx + 1.55, 0.015, z, 0.32, 0.008, 2.8, this._joistShadeMat(), false, 1);
          near.castShadow = false;
          near.receiveShadow = false;
        }
        /* Wall pockets + hangers so joists seat and catch light. */
        this.addBox(bx, 3.38, z - 2.08, 0.28, 0.28, 0.20, pocket, false, 0.7);
        this.addBox(bx, 3.38, z + 2.08, 0.28, 0.28, 0.20, pocket, false, 0.7);
        if (i % 3 === 1) {
          this.addBox(bx, 3.70, z - 1.85, 0.06, 0.38, 0.06, this.mats.darkMetal, false, 1);
          this.addBox(bx, 3.70, z + 1.85, 0.06, 0.38, 0.06, this.mats.darkMetal, false, 1);
        }
      }
      if (z === 20) {
        for (const sx of [13.55, 14.15, 14.72]) {
          const extra = this.addBox(sx, 0.015, 20.12, 0.36, 0.008, 2.35, this._joistShadeMat(), false, 1);
          extra.castShadow = false;
          extra.receiveShadow = false;
        }
      }
      this.addBox(9, 3.46, z - 1.99, 7.9, 0.13, 0.12, joist, false, 1.1);
      this.addBox(9, 3.46, z + 1.99, 7.9, 0.13, 0.12, joist, false, 1.1);
      this._stainDecal('stainA', 7.4, 3.515, z + 0.6, 3.2, 2.6, 0.3, Math.PI * 0.5);
      this._stainDecal('stainC', 10.8, 3.515, z - 0.7, 2.2, 1.8, -0.8, Math.PI * 0.5);
      // Damp streaks down the cut's flank walls (plaster variation).
      this._stainDecal('stainC', 7.0, 2.5, z - 1.83, 2.0, 2.4, Math.PI);
      this._stainDecal('stainA', 10.4, 2.2, z + 1.83, 2.6, 2.0, 0);
      this._simpleWindow(9, 6.3, z - 2.02, -1, true, Math.PI * 0.5);
      this._simpleWindow(9, 6.3, z + 2.02, 1, false, Math.PI * 0.5);
    }
    this._simpleWindow(-6.96, 2.35, 10.8, 1, true, 0);
  }

  /* Macro-scale weathering (fix 10, c20): the plaster shader tiles fine
   * noise, so from 10m every wall reads as one uniform sheet. Big 3-6m
   * stain blooms, crack streaks and a dark base-grime band on the walls the
   * street and alley stops stare at. */
  _macroGrime() {
    /* Stack each macro decal twice: a single soft-alpha stain spread over
     * 4-6m only darkened the wall ~8 RGB points — invisible at 1x. The
     * duplicate sits 2cm prouder along the wall normal (nx). */
    const dbl = (kind, x, y, z, sx, sy, yaw) => {
      this._stainDecal(kind, x, y, z, sx, sy, yaw);
    };
    // West Main wall: one blot + one leak, no stacked smear columns.
    dbl('stainD', -6.82, 2.8, 18.4, 1.6, 2.2, Math.PI * 0.5);
    dbl('stainB', -6.82, 0.85, 24.6, 1.8, 1.0, Math.PI * 0.5);
    // East side of Main in the same view (block-row west face, x = 5).
    dbl('stainD', 4.84, 3.1, 24.6, 1.8, 2.4, -Math.PI * 0.5, -1);
    dbl('stainB', 4.84, 0.95, 27.4, 2.0, 1.2, -Math.PI * 0.5, -1);
    dbl('stainC', 4.84, 2.4, 31.6, 1.5, 2.2, -Math.PI * 0.5, -1);
    /* Base-course only — the old 6.8 m card painted the whole east canyon
     * as a hole once real sun shadows landed (street rect 20/15/10). */
    this.addBox(4.90, 0.95, 27.0, 0.10, 1.7, 18.0, this._shadeBand(), false, 0.8);
    // Alley: one drip per face — coffee-rings read as pale swirls at 1x.
    dbl('stainD', 13.16, 3.1, 30.4, 1.4, 2.2, -Math.PI * 0.5, 1);
    dbl('stainD', 20.84, 3.2, 30.8, 1.3, 2.0, Math.PI * 0.5, -1);
  }

  _marketSkyCap() {
    /* Attached to the plaza north wall — was a floating slab at y=6. */
    this.addBox(6.5, 4.55, 40.15, 3.2, 0.10, 1.8, this.mats.darkMetal, false, 1);
    this.addBox(5.15, 2.28, 40.55, 0.10, 4.50, 0.10, this.mats.darkMetal, false, 1);
    this.addBox(7.85, 2.28, 40.55, 0.10, 4.50, 0.10, this.mats.darkMetal, false, 1);
    this.addBox(5.15, 2.28, 39.85, 0.10, 4.50, 0.10, this.mats.darkMetal, false, 1);
    this.addBox(7.85, 2.28, 39.85, 0.10, 4.50, 0.10, this.mats.darkMetal, false, 1);
  }

  _midHeightSeals() {
    /* Broken into offset chips so they don't read as a re-plaster grid
     * on the street-left west wall. */
    this._stainDecal('stainC', -6.90, 3.05, 33.15, 1.6, 2.2, Math.PI * 0.5);
    this._stainDecal('stainB', -6.90, 2.55, 35.05, 1.8, 1.4, Math.PI * 0.5);
    this._stainDecal('stainA', -6.90, 4.45, 69.40, 2.0, 1.8, Math.PI * 0.5);
  }

  _warmBay(x, y, z, face) {
    const n = face;
    const room = this.col.dimRoom || this.mats.darkRoom || this.mats.interior;
    const glass = this.col.pane || this.mats.windowDark || this.mats.paneGlass;
    this.addBox(x - n * 0.32, y, z, 0.55, 1.72, 1.42, room, false, 1);
    this.addBox(x + n * 0.14, y, z, 0.06, 1.58, 1.28, glass, false, 1);
    this.addBox(x + n * 0.22, y, z, 0.08, 1.62, 0.10, this.col.mull, false, 1);
    this.addBox(x + n * 0.22, y + 0.28, z, 0.08, 0.10, 1.22, this.col.mull, false, 1);
    this.addBox(x + n * 0.22, y - 0.28, z, 0.08, 0.10, 1.22, this.col.mull, false, 1);
    this.addBox(x + n * 0.26, y - 0.86, z, 0.22, 0.12, 1.48, this.col.sill, false, 1);
    this.addBox(x + n * 0.18, y, z + 0.72, 0.14, 1.78, 0.12, this.col.frame, false, 1);
    this.addBox(x + n * 0.18, y, z - 0.72, 0.14, 1.78, 0.12, this.col.frame, false, 1);
  }

  _warmBayZ(x, y, z) {
    const room = this.col.dimRoom || this.mats.darkRoom || this.mats.interior;
    const glass = this.col.pane || this.mats.windowDark || this.mats.paneGlass;
    this.addBox(x, y, z - 0.28, 1.28, 1.52, 0.48, room, false, 1);
    this.addBox(x, y, z + 0.06, 1.22, 1.42, 0.05, glass, false, 1);
    this.addBox(x, y, z + 0.12, 0.10, 1.46, 0.08, this.col.mull, false, 1);
    this.addBox(x, y + 0.26, z + 0.12, 1.18, 0.10, 0.08, this.col.mull, false, 1);
    this.addBox(x, y - 0.26, z + 0.12, 1.18, 0.10, 0.08, this.col.mull, false, 1);
    this.addBox(x, y - 0.82, z + 0.16, 1.42, 0.12, 0.16, this.col.sill, false, 1);
    this.addBox(x + 0.70, y, z + 0.10, 0.12, 1.68, 0.12, this.col.frame, false, 1);
    this.addBox(x - 0.70, y, z + 0.10, 0.12, 1.68, 0.12, this.col.frame, false, 1);
  }

  _faceBay(x, z, floors) {
    const glass = this.col.pane || this.mats.windowDark || this.mats.paneGlass;
    const tan = this.col.tan;
    const midY = floors[Math.floor(floors.length * 0.5)];
    this.addBox(x + 0.06, midY, z + 0.44, 0.11, 2.95, 0.11, tan, false, 1);
    this.addBox(x + 0.06, midY, z - 0.44, 0.11, 2.95, 0.11, tan, false, 1);
    for (const y of floors) {
      this.addBox(x - 0.16, y, z, 0.22, 0.88, 0.72, this.col.dimRoom || this.mats.darkRoom, false, 1);
      this.addBox(x + 0.02, y, z, 0.05, 0.80, 0.64, glass, false, 1);
      this.addBox(x + 0.06, y, z, 0.06, 0.82, 0.07, tan, false, 1);
      this.addBox(x + 0.06, y, z + 0.22, 0.06, 0.82, 0.07, tan, false, 1);
      this.addBox(x + 0.06, y, z - 0.22, 0.06, 0.82, 0.07, tan, false, 1);
      this.addBox(x + 0.06, y + 0.16, z, 0.06, 0.07, 0.60, this.col.mull, false, 1);
      this.addBox(x + 0.12, y - 0.44, z, 0.18, 0.10, 0.78, tan, false, 1);
    }
  }

  _litBay(x, y, z) {
    const room = this.col.warmIn || this.col.dimRoom || this.mats.darkRoom || this.mats.interior;
    const glass = this.col.pane || this.mats.windowDark || this.mats.paneGlass;
    const tan = this.col.tan;
    this.addBox(x - 0.28, y, z, 0.48, 0.98, 0.40, room, false, 1);
    this.addBox(x + 0.02, y, z, 0.06, 0.88, 0.34, glass, false, 1);
    this.addBox(x + 0.08, y, z, 0.07, 0.90, 0.07, tan, false, 1);
    this.addBox(x + 0.08, y, z + 0.14, 0.07, 0.90, 0.07, tan, false, 1);
    this.addBox(x + 0.08, y, z - 0.14, 0.07, 0.90, 0.07, tan, false, 1);
    this.addBox(x + 0.08, y + 0.14, z, 0.07, 0.07, 0.32, tan, false, 1);
    this.addBox(x + 0.14, y - 0.48, z, 0.16, 0.10, 0.42, tan, false, 1);
  }

  _warmWindowStacks() {
    this._warmBay(-INNER, 2.25, 17.4, 1);
    this._warmBay(-INNER, 2.25, 76.2, 1);
  }

  _flattenStatic(root) {
    const hold = new Set(this._flames || []);
    const move = [];
    root.traverse((o) => {
      if (!o.isMesh || o.isInstancedMesh) return;
      if (o.parent === root) return;
      if (hold.has(o)) return;
      move.push(o);
    });
    for (const o of move) root.attach(o);
  }

  /* Flatten leaves empty Groups behind; they still get walked every
   * shadow/frustum pass. Strip them after attach + after merge. */
  _pruneEmpty(root) {
    let again = true;
    while (again) {
      again = false;
      const dead = [];
      root.traverse((o) => {
        if (o !== root && o.isGroup && o.children.length === 0) dead.push(o);
      });
      for (const o of dead) {
        o.parent?.remove(o);
        again = true;
      }
    }
  }

  /* Same-material world pieces used to miss the merge when one had uv2
   * (meter-boxed) and the other only uv. Pad the common extras so they
   * batch — pixels stay the same because the material is shared. */
  _padMergeGeo(g, wantUv2, wantColor) {
    if (wantUv2 && !g.attributes.uv2 && g.attributes.uv) {
      g.setAttribute('uv2', g.attributes.uv.clone());
    }
    if (wantColor && !g.attributes.color && g.attributes.position) {
      const n = g.attributes.position.count;
      const col = new Float32Array(n * 3);
      col.fill(1);
      g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    }
    return g;
  }

  _trimShadows(root) {
    root.traverse((o) => {
      if (!o.isMesh || o.isInstancedMesh) return;
      const g = o.geometry;
      if (!g.boundingBox) g.computeBoundingBox();
      const bb = g.boundingBox;
      const sx = (bb.max.x - bb.min.x) * Math.abs(o.scale.x);
      const sy = (bb.max.y - bb.min.y) * Math.abs(o.scale.y);
      const sz = (bb.max.z - bb.min.z) * Math.abs(o.scale.z);
      if (sx * sy * sz < 0.28 && Math.max(sx, sy, sz) < 1.55) o.castShadow = false;
    });
  }

  _mergeMeshes(parent) {
    for (const child of [...parent.children]) {
      if (child.isGroup) this._mergeMeshes(child);
    }
    const CORE = { position: 1, normal: 1, uv: 1, uv2: 1, color: 1 };
    const buckets = new Map();
    for (const o of parent.children) {
      if (!o.isMesh || o.isInstancedMesh) continue;
      const mat = o.material;
      if (!mat || Array.isArray(mat)) continue;
      const names = Object.keys(o.geometry.attributes);
      let extra = '';
      for (const n of names) {
        if (!CORE[n]) extra += n + ',';
      }
      const key = `${mat.uuid}|${extra}|${o.castShadow ? 1 : 0}|${o.receiveShadow ? 1 : 0}|${o.renderOrder}`;
      let b = buckets.get(key);
      if (!b) {
        b = {
          mat, cast: o.castShadow, recv: o.receiveShadow, order: o.renderOrder,
          geos: [], meshes: [], wantUv2: false, wantColor: false,
        };
        buckets.set(key, b);
      }
      if (o.geometry.attributes.uv2) b.wantUv2 = true;
      if (o.geometry.attributes.color) b.wantColor = true;
      o.updateMatrix();
      let g = o.geometry.clone();
      if (g.index) {
        const ni = g.toNonIndexed();
        g.dispose();
        g = ni;
      }
      g.applyMatrix4(o.matrix);
      b.geos.push(g);
      b.meshes.push(o);
    }
    for (const b of buckets.values()) {
      if (b.geos.length < 2) {
        b.geos.forEach((g) => g.dispose());
        continue;
      }
      for (const g of b.geos) this._padMergeGeo(g, b.wantUv2, b.wantColor);
      let merged = null;
      try { merged = mergeGeometries(b.geos, false); } catch { merged = null; }
      b.geos.forEach((g) => g.dispose());
      if (!merged) continue;
      const m = new THREE.Mesh(merged, b.mat);
      m.castShadow = b.cast;
      m.receiveShadow = b.recv;
      m.renderOrder = b.order;
      parent.add(m);
      for (const old of b.meshes) parent.remove(old);
    }
  }

  _flush() {
    const g = this.geo;
    const m = this.mats;
    this._instanced(g.winRecess, m.plaster, this.q.recess);
    this._instanced(g.winJamb, m.plaster, this.q.jamb);
    this._instanced(g.winHead, m.plaster, this.q.head);
    this._instanced(g.winInterior, this.col.warmIn || m.interior, this.q.interior);
    this._instanced(g.winInterior, this.col.dimRoom || m.darkRoom, this.q.darkRoom);
    this._instanced(g.winBlind, m.blind, this.q.blind);
    this._instanced(g.winCurtain, m.curtain, this.q.curtain);
    this._instanced(g.winGlass, this.col.pane || m.windowDark, this.q.glassD);
    this._instanced(g.winGlass, this.col.paneLit || m.litGlass, this.q.glassC);
    this._instanced(g.winSill, this.col.sill, this.q.sill);
    this._instanced(g.winMullH, this.col.tan, this.q.mullH);
    this._instanced(g.winMullV, this.col.tan, this.q.mullV);
    this._instanced(g.winFrameH, this.col.sill, this.q.frameH);
    this._instanced(g.winFrameV, this.col.sill, this.q.frameV);
    this._instanced(g.sandbag, this.col.sand || m.burlap || m.concrete, this.q.sand);
    this._instanced(g.bolt, m.metal, this.q.bolt, false);
    /* c31: dust-tinted rust for the burn rubble — raw m.rust read as
     * saturated toy-red brick. q.debris is only used by _fire. */
    if (!this._brickDust) {
      this._brickDust = m.rust.clone();
      this._brickDust.color = new THREE.Color(0xb4a48c);
      this._brickDust.roughness = 0.96;
      if (this._brickDust.envMapIntensity != null) this._brickDust.envMapIntensity = 0.08;
    }
    this._instanced(g.debris, this._brickDust, this.q.debris, false);
    this._instanced(g.dash, this._laneMat(), this.q.dash, false);
    this._instanced(g.fenceBar, m.darkMetal, this.q.fence);
    this._instanced(g.crate, m.wood, this.q.crate);
    this._instanced(g.crateBand, m.crateMetal || m.darkMetal, this.q.crateBand);
    this._instanced(g.crateSlat, m.wood, this.q.crateSlat);
    this._instanced(g.crateEnd, m.woodEnd || m.wood, this.q.crateEnd);
    this._instanced(g.crateBatten, m.woodEnd || m.wood, this.q.crateBatten);
    this._instanced(g.card, m.cardboard, this.q.card);
    this._instanced(g.trash, m.trashBag, this.q.trash);
    this._instanced(g.cone, this.col.cone, this.q.cone);
    this._instanced(g.coneDirt, this.mats.dirt || this.mats.rubber, this.q.coneDirt, false);
    this._instanced(g.acBody, m.acShell, this.q.ac);
    this._instanced(g.acFan, m.rubber || m.darkMetal, this.q.fan);
    this._instanced(g.barrel, m.rust, this.q.barrel);
    for (const t of this.q.barrel) {
      const s = t[6] || 1;
      this._push(this.q.contact, t[0], 0.014, t[2], 0, 0, 0, 0.62 * s, 1, 0.62 * s);
    }
    const hoops = [];
    for (const t of this.q.barrel) {
      const sx = t[6] || 1, sy = t[7] || 1, sz = t[8] || 1;
      hoops.push([t[0], t[1] + 0.18 * sy, t[2], Math.PI * 0.5, t[4] || 0, 0, sx, sy, sz]);
      hoops.push([t[0], t[1] - 0.16 * sy, t[2], Math.PI * 0.5, t[4] || 0, 0, sx, sy, sz]);
    }
    this._instanced(g.barrelHoop, m.darkMetal, hoops);
    this._instanced(g.vent, m.acShell, this.q.vent);
    this._instanced(g.ventGrille, m.darkMetal, this.q.vent);
    this._instanced(g.ventCap, m.rust, this.q.vent);
    this._instanced(g.arch, m.sill || m.concrete, this.q.arch);
    this._instanced(g.archFill, this._nicheMat(), this.q.archFill);
    this._instanced(g.archGlass, this.col.pane || m.windowDark || m.glass, this.q.archGlass);
    this._instanced(g.disc || g.puddle, this._groundDirtMat(), this.q.contact, false);
    this._instanced(g.disc || g.puddle, m.sandDrift || m.dirt || m.asphalt, this.q.drift, false);
    this._instanced(g.winGrime, this._grimeMat(), this.q.grime, false);
    this._instanced(g.pebble, m.dirt || m.concrete, this.q.pebble, false);
    this._instanced(g.chip, m.concrete, this.q.chip, false);
  }

  _enemies(rng) {
    // Ashline Bazaar spawn table (plan §2.3). All ≥20m from player spawn,
    // none within 6m of the extract pad, none inside a collider.
    // E5 holds the plaza balcony — elevated:true so Enemy keeps authored y.
    const spots = [
      { p: [16.5, 24.0], y: 0.12, yaw: 3.08, seed: 0 },              // E1 Suq past Cut A
      { p: [-2.2, 27.0], y: 0.12, yaw: 3.02, seed: 1 },              // E2 Main sandbag line
      { p: [2.0, 29.5], y: 0.12, yaw: -3.05, seed: 2 },              // E3 crossfire pair
      /* E4 was (2.5, 48.0) — that point sits inside the plaza dumpster
       * AABB (2.15, 47.55) → [1.39,0,46.98]–[2.91,1.5,48.12], so a
       * Longshot aimed at the visible chest hit the bin first. Parked
       * north-west of stall (5.6, 45.0): counter hides the legs, head
       * and upper torso stay in the open from the street (~18 m). */
      { p: [4.4, 46.5], y: 0.12, yaw: 3.10, seed: 0 },               // E4 plaza stalls
      { p: [18.5, 51.0], y: 2.72, yaw: -1.74, seed: 1, elevated: true }, // E5 balcony
      { p: [16.0, 63.0], y: 0.12, yaw: 3.06, seed: 2 },              // E6 Suq past Cut B
      { p: [-2.5, 69.0], y: 0.12, yaw: 3.04, seed: 0 },              // E7 Main sandbags
      { p: [9.5, 81.0], y: 0.12, yaw: -1.68, seed: 1 },              // E8 forecourt flank
    ];
    for (const s of spots) {
      this.spawns.push({
        x: s.p[0], z: s.p[1], y: s.y || 0, yaw: s.yaw, seed: s.seed,
        elevated: !!s.elevated,
      });
    }
  }

  update(dt, time) {
    if (this._fireLight) {
      this._fireLight.intensity = 2.0 + Math.sin(time * 17.0) * 0.35 + Math.sin(time * 31.0) * 0.18;
    }
    for (const p of this._flames) {
      p.scale.y = p.userData.ph * (0.82 + Math.sin(time * p.userData.fr) * 0.18);
    }
  }
}

