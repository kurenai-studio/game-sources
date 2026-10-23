// Day/night cycle: one sun (directional + shadows), one hemisphere fill,
// fog + sky color lerped through keyframes. No per-lamp point lights.
import * as THREE from 'three';

const KEYS = [ // t, sky, fog, sun color, sun intensity, hemi intensity
  { t: 0.00, sky: 0x0a0e1e, fog: 0x0a0e1e, sun: 0x223355, si: 0.05, hi: 0.18 }, // midnight
  { t: 0.22, sky: 0x0d1226, fog: 0x0d1226, sun: 0x334466, si: 0.06, hi: 0.20 },
  { t: 0.28, sky: 0xd97b4f, fog: 0xc98a63, sun: 0xffb27a, si: 0.55, hi: 0.42 }, // dawn
  { t: 0.38, sky: 0x87b6e8, fog: 0xa8c6de, sun: 0xfff2d8, si: 1.05, hi: 0.75 }, // morning
  { t: 0.55, sky: 0x8ec2f2, fog: 0xb5d2e8, sun: 0xffffff, si: 1.15, hi: 0.85 }, // noon
  { t: 0.72, sky: 0xe8955e, fog: 0xd8905e, sun: 0xffc188, si: 0.70, hi: 0.50 }, // golden hour
  { t: 0.78, sky: 0x4a3560, fog: 0x3d2f52, sun: 0x8866aa, si: 0.22, hi: 0.30 }, // dusk
  { t: 0.85, sky: 0x0e1328, fog: 0x0e1328, sun: 0x223355, si: 0.06, hi: 0.20 }, // night
  { t: 1.00, sky: 0x0a0e1e, fog: 0x0a0e1e, sun: 0x223355, si: 0.05, hi: 0.18 },
];

export class DayNight {
  constructor(scene, cfg) {
    this.cfg = cfg;
    this.time = cfg.DAY_START; // 0..1
    this.scene = scene;

    scene.fog = new THREE.Fog(0x8ec2f2, 90, 420);

    this.sun = new THREE.DirectionalLight(0xffffff, 1);
    this.sun.castShadow = true;
    const sc = this.sun.shadow.camera;
    sc.left = -70; sc.right = 70; sc.top = 70; sc.bottom = -70; sc.far = 400;
    this.sun.shadow.mapSize.set(2048, 2048);
    this.sun.shadow.bias = -0.0004;
    scene.add(this.sun, this.sun.target);

    this.hemi = new THREE.HemisphereLight(0xbcd8f5, 0x3a4030, 0.8);
    scene.add(this.hemi);

    this._sky = new THREE.Color();
    this._fog = new THREE.Color();
    this._sunc = new THREE.Color();
  }

  get nightFactor() {
    // 1 deep night … 0 full day, smooth ramps at dawn/dusk
    const t = this.time;
    if (t > 0.30 && t < 0.72) return 0;
    if (t >= 0.72 && t < 0.82) return (t - 0.72) / 0.10;
    if (t >= 0.20 && t <= 0.30) return 1 - (t - 0.20) / 0.10;
    return 1;
  }
  get isNight() { return this.nightFactor > 0.5; }

  clockText() {
    const h = Math.floor(this.time * 24), m = Math.floor((this.time * 24 - h) * 60);
    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0');
  }

  update(dt, focus) {
    this.time = (this.time + dt / this.cfg.DAY_LENGTH) % 1;
    const t = this.time;
    let a = KEYS[0], b = KEYS[KEYS.length - 1];
    for (let i = 0; i < KEYS.length - 1; i++)
      if (t >= KEYS[i].t && t <= KEYS[i + 1].t) { a = KEYS[i]; b = KEYS[i + 1]; break; }
    const f = (t - a.t) / Math.max(1e-6, b.t - a.t);

    this._sky.setHex(a.sky).lerp(this._fog.setHex(b.sky), f);
    if (!this.scene.background) this.scene.background = new THREE.Color();
    this.scene.background.copy(this._sky);
    this.scene.fog.color.setHex(a.fog).lerp(this._fog.setHex(b.fog), f);
    this.scene.fog.near = 90 - this.nightFactor * 40;
    this.scene.fog.far = 420 - this.nightFactor * 180;

    this.sun.color.setHex(a.sun).lerp(this._sunc.setHex(b.sun), f);
    this.sun.intensity = a.si + (b.si - a.si) * f;
    this.hemi.intensity = a.hi + (b.hi - a.hi) * f;

    // sun orbits; shadow camera follows the player so the map stays sharp
    const ang = (t - 0.25) * Math.PI * 2; // sunrise east at t=.25
    const el = Math.max(0.12, Math.sin(ang));
    this.sun.position.set(
      focus.x + Math.cos(ang) * 120,
      el * 150 + 20,
      focus.z + Math.sin(ang * 0.7) * 60,
    );
    this.sun.target.position.set(focus.x, 0, focus.z);
  }
}
