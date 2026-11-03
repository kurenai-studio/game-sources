// Time of day and weather. A look provides lighting keyframes by hour (style.times); this module
// interpolates them, moves the sun and moon, then layers the weather on top. The result is one
// `state` object that main.js applies to the sky, ocean, fog, lights and post effects every frame.
import * as THREE from 'three';
import { smoothstep } from './noise.js';

export const TIME_PRESETS = [
  { id: 'sunrise', name: 'Sunrise', hour: 6.3 },
  { id: 'morning', name: 'Morning', hour: 8.5 },
  { id: 'midday', name: 'Midday', hour: 12.5 },
  { id: 'afternoon', name: 'Afternoon', hour: 16 },
  { id: 'golden', name: 'Golden hour', hour: 18.6 },
  { id: 'dusk', name: 'Dusk', hour: 19.6 },
  { id: 'night', name: 'Night', hour: 23 },
];

export const WEATHER = {
  clear: { name: 'Clear', cloud: 0.3, overcast: 0, rain: 0, fog: 0 },
  cloudy: { name: 'Cloudy', cloud: 0.75, overcast: 0.3, rain: 0, fog: 0.1 },
  overcast: { name: 'Overcast', cloud: 1, overcast: 0.75, rain: 0, fog: 0.3 },
  rain: { name: 'Rain', cloud: 1, overcast: 0.9, rain: 1, fog: 0.45 },
  fog: { name: 'Sea fog', cloud: 0.4, overcast: 0.45, rain: 0, fog: 1 },
};
const AUTO_WEIGHTS = { clear: 0.4, cloudy: 0.25, overcast: 0.12, rain: 0.13, fog: 0.1 };

const HOUR_SECONDS = 75;    // a full day cycle takes 30 minutes
const SUNRISE = 6, SUNSET = 19, MAX_ELEV = 0.8;
const SET_DIR = new THREE.Vector3(0.45, 0, -1).normalize();   // sun sets ahead and over the sea
const SIDE_DIR = new THREE.Vector3(1, 0, 0.45).normalize();

const COLOR_PATHS = [
  ['sky', 'top'], ['sky', 'horizon'], ['sky', 'bottom'], ['sky', 'sunColor'], ['fog', 'color'],
  ['lights', 'hemiSky'], ['lights', 'hemiGround'], ['lights', 'sun'], ['water', 'deep'], ['water', 'shallow'], ['water', 'foam'],
];
const NUMBER_PATHS = [
  ['sky', 'glow'], ['sky', 'sunSize'], ['fog', 'density'], ['lights', 'hemi'], ['lights', 'sunIntensity'],
  ['water', 'spec'], ['water', 'reflect'],
];

function keyframeFrom(style) {
  return {
    h: 0,
    sky: style.sky, fog: style.fog, lights: style.lights,
    water: style.water, exposure: style.post.exposure, night: style.sky.mode === 1 ? 1 : 0, cloud: style.flora.cloud,
  };
}

// Pre-convert hex strings to colours once.
function prepare(k) {
  const out = { h: k.h, exposure: k.exposure ?? 1, night: k.night ?? 0, cloud: new THREE.Color(k.cloud ?? '#ffffff'), bloom: k.bloom ?? 1 };
  for (const [g, key] of COLOR_PATHS) (out[g] ??= {})[key] = new THREE.Color(k[g][key]);
  for (const [g, key] of NUMBER_PATHS) (out[g] ??= {})[key] = k[g][key];
  return out;
}

function sunPath(hour, out) {
  const a = ((hour - SUNRISE) / (SUNSET - SUNRISE)) * Math.PI;
  out.copy(SET_DIR).multiplyScalar(-Math.cos(a)).addScaledVector(SIDE_DIR, Math.sin(a) * 0.55).normalize();
  const e = Math.sin(a) * MAX_ELEV;
  out.multiplyScalar(Math.cos(e)).setY(Math.sin(e));
  return out;
}

export class Environment {
  constructor() {
    this.hour = 18.6;
    this.cycle = false;
    this.weatherAuto = false;
    this.weatherId = 'clear';
    this.w = { ...WEATHER.clear };
    this.wTarget = { ...WEATHER.clear };
    this.wet = 0;
    this.weatherTimer = 0;
    this.keys = [];
    this.style = null;
    const C = () => new THREE.Color();
    this.state = {
      sky: { top: C(), horizon: C(), bottom: C(), sunColor: C(), sunDir: new THREE.Vector3(), sunSize: 0, glow: 0, mode: 0, stars: 0, disc: 1 },
      fog: { color: C(), density: 0 },
      lights: { hemiSky: C(), hemiGround: C(), hemi: 0, sun: C(), sunIntensity: 0 },
      lightDir: new THREE.Vector3(0, 1, 0),
      water: { deep: C(), shallow: C(), foam: C(), grid: C(), mode: 0, spec: 0, shininess: 0, reflect: 0, amp: 1 },
      exposure: 1, bloom: 1, night: 0, cloud: C(), cloudCover: 0.3, rain: 0, wet: 0, wind: 0.2, overcast: 0, fogAmount: 0,
    };
    this._sun = new THREE.Vector3();
    this._moon = new THREE.Vector3();
  }

  get dynamicTime() { return !!this.style?.times; }

  setLook(style) {
    this.style = style;
    this.keys = (style.times ?? [keyframeFrom(style)]).map(prepare).sort((a, b) => a.h - b.h);
    const s = this.state;
    s.water.grid.set(style.water.grid);
    s.water.mode = style.water.mode;
    s.water.shininess = style.water.shininess;
    s.water.amp = style.water.amp;
    s.sky.mode = style.sky.mode;
  }

  // id: 'default' | preset id | 'cycle'
  setTime(id) {
    this.cycle = id === 'cycle';
    const preset = TIME_PRESETS.find((p) => p.id === (id === 'default' || id === 'cycle' ? this.style?.defaultTime : id))
      ?? TIME_PRESETS.find((p) => p.id === this.style?.defaultTime);
    if (!this.cycle || this.hour === undefined) this.hour = preset?.hour ?? 18.6;
  }

  // id: preset id | 'auto'
  setWeather(id, instant = false) {
    this.weatherAuto = id === 'auto';
    if (!this.weatherAuto) this.weatherId = id;
    this.weatherTimer = 0;
    Object.assign(this.wTarget, WEATHER[this.weatherId]);
    if (instant) {
      Object.assign(this.w, this.wTarget);
      this.wet = this.wTarget.rain;
    }
  }

  get weatherName() {
    return WEATHER[this.weatherId].name + (this.weatherAuto ? ' (changing)' : '');
  }

  get clock() {
    const h = Math.floor(this.hour), m = Math.floor((this.hour - h) * 60);
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }

  update(dt) {
    if (this.cycle && this.dynamicTime) this.hour = (this.hour + dt / HOUR_SECONDS) % 24;

    if (this.weatherAuto && (this.weatherTimer -= dt) <= 0) {
      this.weatherTimer = 240 + Math.random() * 300;
      let r = Math.random(), next = 'clear';
      for (const [id, wgt] of Object.entries(AUTO_WEIGHTS)) { if ((r -= wgt) <= 0) { next = id; break; } }
      this.weatherId = next;
      Object.assign(this.wTarget, WEATHER[next]);
    }
    const blend = Math.min(1, dt / 25);
    for (const k of ['cloud', 'overcast', 'rain', 'fog']) this.w[k] += (this.wTarget[k] - this.w[k]) * blend;
    this.wet += (this.w.rain - this.wet) * Math.min(1, dt / (this.w.rain > this.wet ? 40 : 120));

    this.interpolate();
    this.applyWeather();
    return this.state;
  }

  interpolate() {
    const s = this.state, keys = this.keys, h = this.hour;
    let a = keys[keys.length - 1], b = keys[0];
    for (let i = 0; i < keys.length; i++) {
      if (keys[i].h > h) { b = keys[i]; a = keys[(i - 1 + keys.length) % keys.length]; break; }
      if (i === keys.length - 1) { a = keys[i]; b = keys[0]; }
    }
    const span = (b.h - a.h + 24) % 24 || 24;
    const t = keys.length === 1 ? 0 : smoothstep(0, 1, ((h - a.h + 24) % 24) / span);
    for (const [g, key] of COLOR_PATHS) s[g][key].copy(a[g][key]).lerp(b[g][key], t);
    for (const [g, key] of NUMBER_PATHS) s[g][key] = a[g][key] + (b[g][key] - a[g][key]) * t;
    s.exposure = a.exposure + (b.exposure - a.exposure) * t;
    s.night = a.night + (b.night - a.night) * t;
    s.bloom = a.bloom + (b.bloom - a.bloom) * t;
    s.cloud.copy(a.cloud).lerp(b.cloud, t);

    if (!this.dynamicTime) {
      s.sky.sunDir.set(...this.style.sky.sunDir).normalize();
      s.sky.disc = 1;
      s.sky.stars = s.night;
    } else {
      const sun = sunPath(h, this._sun);
      if (sun.y > -0.06) {
        s.sky.sunDir.copy(sun);
        s.sky.disc = smoothstep(-0.06, -0.02, sun.y);
      } else {
        // The moon follows the same arc through the night.
        const mh = SUNRISE + (((h - SUNSET + 24) % 24) / (24 - (SUNSET - SUNRISE))) * (SUNSET - SUNRISE);
        s.sky.sunDir.copy(sunPath(mh, this._moon));
        s.sky.sunSize = 0.022;
        s.sky.disc = smoothstep(-0.02, 0.06, s.sky.sunDir.y) * 0.9;
      }
      s.sky.stars = smoothstep(0.3, 0.9, s.night);
    }
    const d = s.sky.sunDir;
    s.lightDir.set(d.x, Math.max(d.y, 0.45), d.z).normalize();
  }

  applyWeather() {
    const s = this.state, w = this.w, k = this.style.weatherScale ?? 1;
    const o = w.overcast * k;
    const grey = (c, amt) => {
      const l = c.r * 0.3 + c.g * 0.59 + c.b * 0.11;
      c.lerp(_grey.setRGB(l * 0.92, l * 0.95, l), amt);
    };
    for (const c of [s.sky.top, s.sky.horizon, s.sky.bottom, s.fog.color]) grey(c, o * 0.8);
    grey(s.cloud, o * 0.5);
    s.cloud.multiplyScalar(1 - o * 0.35);
    grey(s.water.deep, o * 0.5);
    grey(s.water.shallow, o * 0.5);
    s.lights.sunIntensity *= 1 - 0.85 * o;
    s.lights.hemi *= 1 + 0.35 * o;
    s.sky.glow *= 1 - 0.8 * o;
    s.sky.disc *= 1 - o;
    s.sky.stars *= 1 - o;
    s.water.spec *= 1 - 0.85 * o;
    s.fog.density *= 1 + (2.4 * w.fog + 0.9 * w.rain) * k;
    s.bloom *= 1 - 0.5 * o;
    s.cloudCover = w.cloud;
    s.rain = w.rain;
    s.wet = this.wet;
    s.overcast = o;
    s.fogAmount = w.fog;
    s.wind = 0.25 + 0.35 * w.overcast + 0.4 * w.rain;
  }
}

const _grey = new THREE.Color();
