/**
 * Lighting rig.
 *
 * Key    — the sun/moon. Casts the only shadow map, and its shadow frustum is
 *          re-centred on the camera each frame (a poor man's cascade) so a
 *          2–4k map covers a 2.4km world without visible acne.
 * Fill   — hemisphere light: cool sky above, ember-bounce below.
 * Caldera— two warm point lights sunk into the crater and the lava lake, so
 *          geometry near the molten stuff is genuinely uplit.
 * Rim    — a dim cold backlight opposite the sun; separates silhouettes from
 *          the sky the way a gaffer would.
 */
import * as THREE from 'three';
import { WORLD } from '../world/Heightfield.js';
import { damp } from '../utils/MathX.js';

export class LightRig {
  constructor(scene, settings) {
    this.scene = scene;
    this.settings = settings;
    this.group = new THREE.Group();
    this.group.name = 'LightRig';
    scene.add(this.group);

    // ── key ───────────────────────────────────────────────────────────
    this.sun = new THREE.DirectionalLight(0xffb173, 3.2);
    this.sun.castShadow = settings.shadows;
    this.sun.shadow.mapSize.set(settings.shadowMap, settings.shadowMap);
    this.sun.shadow.bias = -0.0006;
    this.sun.shadow.normalBias = 1.4;
    this.sun.shadow.radius = settings.softShadows ? 3.2 : 1;
    this.sun.shadow.blurSamples = settings.softShadows ? 12 : 4;
    const c = this.sun.shadow.camera;
    c.near = 20; c.far = 2600;
    this._setShadowExtent(620);
    this.sunTarget = new THREE.Object3D();
    this.group.add(this.sun, this.sunTarget);
    this.sun.target = this.sunTarget;

    // ── fill ──────────────────────────────────────────────────────────
    this.hemi = new THREE.HemisphereLight(0x5a6c9c, 0x3a1408, 0.9);
    this.group.add(this.hemi);

    this.ambient = new THREE.AmbientLight(0x2a1e22, 0.35);
    this.group.add(this.ambient);

    // ── rim ───────────────────────────────────────────────────────────
    this.rim = new THREE.DirectionalLight(0x6d84c8, 0.55);
    this.group.add(this.rim);

    // ── caldera uplight ───────────────────────────────────────────────
    const v = WORLD.volcano;
    this.craterLight = new THREE.PointLight(0xff4d10, 900, 900, 2.0);
    this.craterLight.position.set(v.x, v.height * 0.86, v.z);
    this.group.add(this.craterLight);

    const l = WORLD.lavaLake;
    this.lakeLight = new THREE.PointLight(0xff5a18, 420, 620, 2.0);
    this.lakeLight.position.set(l.x, l.y + 16, l.z);
    this.group.add(this.lakeLight);

    this.lavaLight = new THREE.PointLight(0xff6b22, 160, 340, 2.0);
    this.lavaLight.position.set(-190, 80, -120);
    this.group.add(this.lavaLight);

    // Hero light. A 90 m creature against a dark sky is a black hole without
    // one — this is the standard trick: a soft, wide, warm fill that travels
    // with the subject so it is always legible no matter the weather.
    this.hero = new THREE.PointLight(0xffc98a, 0, 480, 1.35);
    this.group.add(this.hero);

    // Lightning strobe (storm) — parented high, off by default.
    this.strike = new THREE.DirectionalLight(0xcfe0ff, 0);
    this.strike.position.set(300, 900, -200);
    this.group.add(this.strike);

    this._sunDist = 1500;
    this._craterBase = 900;
    this._lakeBase = 420;
    this._flicker = 0;
    this._shakeSeed = Math.random() * 100;
  }

  _setShadowExtent(half) {
    const c = this.sun.shadow.camera;
    c.left = -half; c.right = half; c.top = half; c.bottom = -half;
    c.updateProjectionMatrix();
  }

  /** Track the hero light onto the dragon; strength rises as the light falls. */
  followHero(pos, nightness = 0) {
    this.hero.position.copy(pos).add(new THREE.Vector3(0, 26, 0));
    this.hero.intensity = 2600 * (0.35 + nightness * 0.9);
  }

  /** @param dir unit vector pointing *towards* the sun. */
  setSunDirection(dir) {
    this.sun.position.copy(dir).multiplyScalar(this._sunDist);
    this.rim.position.copy(dir).multiplyScalar(-900).setY(320);
  }

  applyQuality(settings) {
    this.settings = settings;
    this.sun.castShadow = settings.shadows;
    this.sun.shadow.mapSize.set(settings.shadowMap, settings.shadowMap);
    this.sun.shadow.radius = settings.softShadows ? 3.2 : 1;
    this.sun.shadow.blurSamples = settings.softShadows ? 12 : 4;
    if (this.sun.shadow.map) { this.sun.shadow.map.dispose(); this.sun.shadow.map = null; }
  }

  /**
   * Re-centre the shadow frustum ahead of the camera and snap it to texel
   * increments — without the snap, panning makes shadow edges crawl.
   */
  update(dt, camera, focus) {
    const target = focus ?? camera.position;
    const half = this.sun.shadow.camera.right;
    const texel = (half * 2) / this.settings.shadowMap;

    const tx = Math.round(target.x / texel) * texel;
    const tz = Math.round(target.z / texel) * texel;
    const ty = Math.round(target.y / texel) * texel;

    this.sunTarget.position.set(tx, ty, tz);
    const dir = this.sun.position.clone().normalize();
    this.sun.position.copy(dir).multiplyScalar(this._sunDist).add(this.sunTarget.position);

    // Lava lights breathe, and flare when the volcano is angry.
    this._flicker += dt;
    const f = 0.86 + 0.14 * Math.sin(this._flicker * 1.7) * Math.sin(this._flicker * 0.53 + 1.2);
    this.craterLight.intensity = this._craterBase * f;
    this.lakeLight.intensity = this._lakeBase * (0.9 + 0.1 * Math.sin(this._flicker * 2.3));
  }

  set craterBase(v) { this._craterBase = v; }
  get craterBase() { return this._craterBase ?? 900; }
  set lakeBase(v) { this._lakeBase = v; }
  get lakeBase() { return this._lakeBase ?? 420; }

  /**
   * Apply a weather/time preset. Values are absolute so presets are
   * declarative and cross-fadable.
   */
  applyMood(m, t = 1) {
    const L = (a, b) => damp(a, b, 0.0001, t);
    this.sun.color.lerp(new THREE.Color(m.sunColor), t);
    this.sun.intensity = L(this.sun.intensity, m.sunIntensity);
    this.hemi.color.lerp(new THREE.Color(m.skyColor), t);
    this.hemi.groundColor.lerp(new THREE.Color(m.groundColor), t);
    this.hemi.intensity = L(this.hemi.intensity, m.hemiIntensity);
    this.ambient.intensity = L(this.ambient.intensity, m.ambientIntensity);
    this.ambient.color.lerp(new THREE.Color(m.ambientColor ?? m.skyColor), t);
    this.rim.intensity = L(this.rim.intensity, m.rimIntensity);
    this.rim.color.lerp(new THREE.Color(m.rimColor), t);
    this._craterBase = L(this.craterBase, m.craterIntensity);
    this._lakeBase = L(this.lakeBase, m.lakeIntensity);
    this.lavaLight.intensity = L(this.lavaLight.intensity, m.lakeIntensity * 0.4);
  }

  dispose() {
    this.sun.shadow.map?.dispose();
    this.scene.remove(this.group);
  }
}
