/**
 * Weather & time of day.
 *
 * A preset is one declarative object describing *everything* — sun colour and
 * intensity, sky gradient, cloud cover, fog density and hue, particle loads,
 * post-grade, even how much the ember glow bleeds into the clouds. Switching
 * weather cross-fades every one of those numbers over a few seconds, so the
 * transition itself looks directed.
 *
 * Time of day is orthogonal: it drives the sun's *direction* and a warmth curve
 * that modulates the active preset. That's why "storm" at dawn and "storm" at
 * midnight look like the same weather in different light, rather than two
 * unrelated looks.
 */
import * as THREE from 'three';
import { gsap } from 'gsap';
import { bus, EV } from '../core/EventBus.js';
import { G } from '../materials/GlobalUniforms.js';
import { WORLD, height } from '../world/Heightfield.js';
import { clamp, lerp, smoothstep, TAU } from '../utils/MathX.js';

/* -- presets -------------------------------------------------------------- */
const P = {
  sunset: {
    label: 'Sunset',
    tod: 0.685,
    sun: { color: 0xffcf9d, intensity: 5.4 },
    sky: { zenith: 0x243f59, horizon: 0xc38d69, ground: 0x281c1a, haze: 0.20, cloudCover: 0.34, cloudSharp: 0.28, stars: 0.0, moon: 0 },
    cloud: { color: 0xf0c492, shadow: 0x4e4048, opacity: 0.34 },
    light: { hemi: 1.05, skyColor: 0x899aad, groundColor: 0x5e4333, ambient: 0.30, ambientColor: 0xd89a68, rim: 1.1, rimColor: 0xe8a875, crater: 1200, lake: 650 },
    fog: { color: 0x8c5e50, density: 0.00018, banks: 0.045, bankColor: 0xb0806c },
    ember: 1.25,
    particles: { ash: 0.35, ember: 1.1, dust: 1.0, wind: 0.1, leaf: 0.6, rain: 0 },
    wind: 0.85,
    grade: { exposure: 1.05, contrast: 1.20, saturation: 1.10, vignette: 0.42, bloom: 0.22, bloomRadius: 0.55, bloomThreshold: 0.86, lift: 0x241d1b, shadowTint: 0x5a4a50, highlightTint: 0xffd5b5, godRays: 0.28, dofBlur: 0.0018 },
    wet: 0,
  },

  sunny: {
    label: 'Clear Day',
    tod: 0.42,
    sun: { color: 0xfff6e8, intensity: 6.8 },
    sky: { zenith: 0x2f64b5, horizon: 0x9ec0e2, ground: 0x2c2622, haze: 0.16, cloudCover: 0.26, cloudSharp: 0.34, stars: 0, moon: 0 },
    cloud: { color: 0xf4f6f8, shadow: 0x667084, opacity: 0.36 },
    light: { hemi: 1.00, skyColor: 0xa8c6ee, groundColor: 0x8a6e54, ambient: 0.28, ambientColor: 0x8ea6ca, rim: 0.85, rimColor: 0x9fbcf0, crater: 850, lake: 440 },
    fog: { color: 0x8898ac, density: 0.00016, banks: 0.04, bankColor: 0xb0c0d0 },
    ember: 0.85,
    particles: { ash: 0.22, ember: 0.7, dust: 1.2, wind: 0.05, leaf: 0.5, rain: 0 },
    wind: 0.6,
    grade: { exposure: 1.05, contrast: 1.16, saturation: 1.04, vignette: 0.36, bloom: 0.18, bloomRadius: 0.52, bloomThreshold: 0.94, lift: 0x222936, shadowTint: 0x3f4c64, highlightTint: 0xfff0dc, godRays: 0.24, dofBlur: 0.0016 },
    wet: 0,
  },

  night: {
    label: 'Moonlight',
    tod: 0.02,
    sun: { color: 0xa8bcf0, intensity: 4.2 },
    sky: { zenith: 0x081024, horizon: 0x182648, ground: 0x080a14, haze: 0.20, cloudCover: 0.34, cloudSharp: 0.30, stars: 1.0, moon: 1.0 },
    cloud: { color: 0x8290b8, shadow: 0x161d30, opacity: 0.34 },
    light: { hemi: 1.15, skyColor: 0x7c92cf, groundColor: 0xaa4c1e, ambient: 0.34, ambientColor: 0x5c6c9e, rim: 1.2, rimColor: 0x6e88d8, crater: 1800, lake: 900 },
    fog: { color: 0x141f36, density: 0.00040, banks: 0.10, bankColor: 0x586a98 },
    ember: 1.8,
    particles: { ash: 0.35, ember: 1.5, dust: 0.5, wind: 0.08, leaf: 0.4, rain: 0 },
    wind: 0.5,
    grade: { exposure: 1.30, contrast: 1.22, saturation: 1.04, vignette: 0.50, bloom: 0.34, bloomRadius: 0.62, bloomThreshold: 0.60, lift: 0x222c48, shadowTint: 0x303f68, highlightTint: 0xffd2a0, godRays: 0.22, dofBlur: 0.002 },
    wet: 0,
  },

  storm: {
    label: 'Storm',
    tod: 0.60,
    sun: { color: 0xa8b4cc, intensity: 4.0 },
    sky: { zenith: 0x222a3a, horizon: 0x586072, ground: 0x1c2028, haze: 0.55, cloudCover: 0.90, cloudSharp: 0.12, stars: 0, moon: 0 },
    cloud: { color: 0x7c8698, shadow: 0x282e3c, opacity: 0.88 },
    light: { hemi: 0.95, skyColor: 0x788498, groundColor: 0x705240, ambient: 0.30, ambientColor: 0x626c7e, rim: 0.75, rimColor: 0x9aa8c4, crater: 1500, lake: 700 },
    fog: { color: 0x424854, density: 0.00065, banks: 0.15, bankColor: 0x7a8294 },
    ember: 1.35,
    particles: { ash: 0.6, ember: 1.2, dust: 0.4, wind: 1.0, leaf: 1.4, rain: 0.35 },
    wind: 1.9,
    grade: { exposure: 1.14, contrast: 1.24, saturation: 0.94, vignette: 0.52, bloom: 0.24, bloomRadius: 0.62, bloomThreshold: 0.78, lift: 0x202735, shadowTint: 0x33425e, highlightTint: 0xe4eaf4, godRays: 0.14, dofBlur: 0.002 },
    wet: 0.55,
    lightning: 1,
  },

  rain: {
    label: 'Rain',
    tod: 0.55,
    sun: { color: 0xb8c2d4, intensity: 2.7 },
    sky: { zenith: 0x263040, horizon: 0x5c6472, ground: 0x181b20, haze: 0.55, cloudCover: 0.85, cloudSharp: 0.16, stars: 0, moon: 0 },
    cloud: { color: 0x808898, shadow: 0x252a34, opacity: 0.85 },
    light: { hemi: 0.85, skyColor: 0x6e7888, groundColor: 0x60463a, ambient: 0.22, ambientColor: 0x505a66, rim: 0.45, rimColor: 0x92a0b8, crater: 950, lake: 440 },
    fog: { color: 0x424852, density: 0.00082, banks: 0.16, bankColor: 0x7a8290 },
    ember: 0.95,
    particles: { ash: 0.18, ember: 0.6, dust: 0.15, wind: 0.5, leaf: 0.9, rain: 1.0 },
    wind: 1.3,
    grade: { exposure: 1.12, contrast: 1.22, saturation: 0.92, vignette: 0.55, bloom: 0.20, bloomRadius: 0.58, bloomThreshold: 0.86, lift: 0x141b28, shadowTint: 0x26324a, highlightTint: 0xe2eaf6, godRays: 0.08, dofBlur: 0.002 },
    wet: 1.0,
  },

  fog: {
    label: 'Heavy Fog',
    tod: 0.30,
    sun: { color: 0xe4d8c4, intensity: 2.9 },
    sky: { zenith: 0x59606c, horizon: 0x8e939c, ground: 0x3c4048, haze: 0.95, cloudCover: 0.7, cloudSharp: 0.1, stars: 0, moon: 0 },
    cloud: { color: 0xa8aeb8, shadow: 0x5c626c, opacity: 0.7 },
    light: { hemi: 1.30, skyColor: 0x9aa0aa, groundColor: 0x6e6458, ambient: 0.45, ambientColor: 0x848a94, rim: 0.35, rimColor: 0x9aa0aa, crater: 800, lake: 420 },
    // 0.0022 was dense enough to swallow the volcano whole from 800 m — the
    // preset read as "grey screen" rather than as fog *around something*. Fog
    // needs a subject visible through it to be legible as fog at all.
    fog: { color: 0x7d838d, density: 0.00135, banks: 0.34, bankColor: 0xa8aeb6 },
    ember: 1.0,
    particles: { ash: 0.3, ember: 0.8, dust: 0.6, wind: 0.15, leaf: 0.3, rain: 0 },
    wind: 0.35,
    grade: { exposure: 1.05, contrast: 1.10, saturation: 0.82, vignette: 0.45, bloom: 0.22, bloomRadius: 0.66, bloomThreshold: 0.82, lift: 0x1c2028, shadowTint: 0x444c58, highlightTint: 0xecf0f6, godRays: 0.36, dofBlur: 0.0025 },
    wet: 0.25,
  },

  ashstorm: {
    label: 'Ash Storm',
    tod: 0.665,
    sun: { color: 0xe07a3c, intensity: 3.0 },
    sky: { zenith: 0x2a1a18, horizon: 0x7a3a1c, ground: 0x180d0a, haze: 0.85, cloudCover: 0.78, cloudSharp: 0.14, stars: 0, moon: 0 },
    cloud: { color: 0x8a5334, shadow: 0x2a1a18, opacity: 0.85 },
    light: { hemi: 0.90, skyColor: 0x9a5c40, groundColor: 0x8a3410, ambient: 0.26, ambientColor: 0x6e4438, rim: 0.55, rimColor: 0xa05a30, crater: 1600, lake: 760 },
    fog: { color: 0x51322a, density: 0.00160, banks: 0.24, bankColor: 0x8a5a48 },
    ember: 1.45,
    particles: { ash: 2.4, ember: 1.6, dust: 1.6, wind: 0.8, leaf: 0.8, rain: 0 },
    wind: 2.0,
    grade: { exposure: 1.10, contrast: 1.26, saturation: 1.04, vignette: 0.55, bloom: 0.26, bloomRadius: 0.64, bloomThreshold: 0.80, lift: 0x181014, shadowTint: 0x352428, highlightTint: 0xffc290, godRays: 0.30, dofBlur: 0.0024 },
    wet: 0,
    ashLoad: 0.85,
  },

  eruption: {
    label: 'Eruption',
    tod: 0.745,
    sun: { color: 0xff9a50, intensity: 2.6 },
    sky: { zenith: 0x1a0e14, horizon: 0x8c2c10, ground: 0x120708, haze: 0.75, cloudCover: 0.88, cloudSharp: 0.12, stars: 0.15, moon: 0 },
    cloud: { color: 0xb04a20, shadow: 0x24121a, opacity: 0.92 },
    light: { hemi: 0.85, skyColor: 0x8e3c26, groundColor: 0xa63410, ambient: 0.26, ambientColor: 0x6e2c28, rim: 0.65, rimColor: 0xc04a20, crater: 3200, lake: 1400 },
    fog: { color: 0x52201c, density: 0.00150, banks: 0.26, bankColor: 0x8a3a28 },
    ember: 1.65,
    particles: { ash: 3.0, ember: 2.6, dust: 2.0, wind: 0.6, leaf: 0.5, rain: 0 },
    wind: 1.5,
    grade: { exposure: 1.05, contrast: 1.30, saturation: 1.14, vignette: 0.58, bloom: 0.36, bloomRadius: 0.70, bloomThreshold: 0.70, lift: 0x180c10, shadowTint: 0x3c1822, highlightTint: 0xffbd86, godRays: 0.16, dofBlur: 0.0024 },
    wet: 0,
    ashLoad: 1.0,
  },
};

export const WEATHER_KEYS = Object.keys(P);

/* ── system ───────────────────────────────────────────────────────────── */

export class WeatherSystem {
  constructor({ sky, lights, clouds, atmosphere, rain, materials, birds }) {
    this.sky = sky;
    this.lights = lights;
    this.clouds = clouds;
    this.atmos = atmosphere;
    this.rain = rain;
    this.materials = materials;
    this.birds = birds;

    this.key = 'sunset';
    this.tod = P.sunset.tod;

    // The live, interpolated state. GSAP tweens *this*, and we push it out
    // to all the subsystems every frame.
    this.s = this._flatten(P.sunset);
    this.mood = {};

    this._lightningT = 0;
    this._nextStrike = 6;
    this._eruptionBoost = 0;

    this.apply('sunset', 0);
  }

  _flatten(p) {
    return {
      sunR: ((p.sun.color >> 16) & 255) / 255,
      sunG: ((p.sun.color >> 8) & 255) / 255,
      sunB: (p.sun.color & 255) / 255,
      sunI: p.sun.intensity,

      zenith: new THREE.Color(p.sky.zenith),
      horizon: new THREE.Color(p.sky.horizon),
      groundC: new THREE.Color(p.sky.ground),
      haze: p.sky.haze,
      cover: p.sky.cloudCover,
      sharp: p.sky.cloudSharp,
      stars: p.sky.stars,
      moon: p.sky.moon,

      cloudColor: new THREE.Color(p.cloud.color),
      cloudShadow: new THREE.Color(p.cloud.shadow),
      cloudOpacity: p.cloud.opacity,

      hemi: p.light.hemi,
      skyLight: new THREE.Color(p.light.skyColor),
      groundLight: new THREE.Color(p.light.groundColor),
      ambient: p.light.ambient,
      ambientColor: new THREE.Color(p.light.ambientColor),
      rim: p.light.rim,
      rimColor: new THREE.Color(p.light.rimColor),
      crater: p.light.crater,
      lake: p.light.lake,

      fogColor: new THREE.Color(p.fog.color),
      fogDensity: p.fog.density,
      banks: p.fog.banks,
      bankColor: new THREE.Color(p.fog.bankColor),

      ember: p.ember,
      wind: p.wind,
      wet: p.wet ?? 0,
      ashLoad: p.ashLoad ?? 0.07,

      pAsh: p.particles.ash,
      pEmber: p.particles.ember,
      pDust: p.particles.dust,
      pWind: p.particles.wind,
      pLeaf: p.particles.leaf,
      pRain: p.particles.rain,

      exposure: p.grade.exposure,
      contrast: p.grade.contrast,
      saturation: p.grade.saturation,
      vignette: p.grade.vignette,
      bloom: p.grade.bloom,
      bloomRadius: p.grade.bloomRadius,
      bloomThreshold: p.grade.bloomThreshold,
      lift: new THREE.Color(p.grade.lift ?? 0x121218),
      shadowTint: new THREE.Color(p.grade.shadowTint),
      highlightTint: new THREE.Color(p.grade.highlightTint),
      godRays: p.grade.godRays,
      dofBlur: p.grade.dofBlur,

      lightning: p.lightning ?? 0,
    };
  }

  /** Cross-fade to a preset. */
  apply(key, duration = 3.5) {
    const p = P[key];
    if (!p) return;
    this.key = key;
    const target = this._flatten(p);

    gsap.killTweensOf(this.s);
    const scalars = {};
    for (const [k, v] of Object.entries(target)) {
      if (typeof v === 'number') scalars[k] = v;
    }
    if (duration <= 0) {
      Object.assign(this.s, scalars);
      for (const [k, v] of Object.entries(target)) {
        if (v instanceof THREE.Color) this.s[k].copy(v);
      }
    } else {
      gsap.to(this.s, { duration, ease: 'sine.inOut', ...scalars });
      for (const [k, v] of Object.entries(target)) {
        if (v instanceof THREE.Color) {
          const from = this.s[k];
          const proxy = { t: 0 };
          const start = from.clone();
          gsap.to(proxy, {
            t: 1, duration, ease: 'sine.inOut',
            onUpdate: () => from.copy(start).lerp(v, proxy.t),
          });
        }
      }
    }

    // Time of day follows the preset unless the user has taken it over.
    if (!this._todLocked) this.setTimeOfDay(p.tod, duration);
    bus.emit(EV.WEATHER, { key, preset: p });
  }

  /** @param t 0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk */
  setTimeOfDay(t, duration = 0) {
    const target = ((t % 1) + 1) % 1;
    if (duration <= 0) { this.tod = target; }
    else gsap.to(this, { tod: target, duration, ease: 'sine.inOut' });
    bus.emit(EV.TIME_OF_DAY, { t: target });
  }

  lockTimeOfDay(locked = true) { this._todLocked = locked; }

  /** Eruption pushes the whole world hotter for a while. */
  setEruptionBoost(v) { this._eruptionBoost = v; }

  get nightness() {
    // 1 when the sun is well below the horizon.
    const el = Math.sin((this.tod - 0.25) * TAU);
    return clamp(1 - smoothstep(-0.10, 0.18, el), 0, 1);
  }

  /**
   * Solar arc.
   *
   * AZIMUTH is a deliberate art choice, not a detail: the landmarks (volcano,
   * castle, temple) all sit north-west of the village, and with the sun on that
   * same bearing every hero shot came out as a pure backlit silhouette. Swinging
   * the arc round to the south-west gives the same low sunset light as *raking
   * side light* across the structures, which is what actually models them.
   */
  sunDirection(out = new THREE.Vector3()) {
    const a = (this.tod - 0.25) * TAU;
    const el = Math.sin(a);                 // elevation
    const c = Math.cos(a);                  // horizontal sweep
    const AZIMUTH = 2.05;                   // radians, rotates the whole arc
    const hx = c * 0.86 + 0.08;
    const hz = c * 0.30 - 0.34;
    return out.set(
      hx * Math.cos(AZIMUTH) - hz * Math.sin(AZIMUTH),
      el,
      hx * Math.sin(AZIMUTH) + hz * Math.cos(AZIMUTH),
    ).normalize();
  }

  update(dt) {
    const s = this.s;
    const boost = this._eruptionBoost;

    // ── sun / moon ───────────────────────────────────────────────────
    const dir = this.sunDirection();
    G.uSunDir.value.copy(dir);
    this.lights.setSunDirection(dir);

    const el = dir.y;
    // Below the horizon the "sun" becomes the moon: cooler, dimmer.
    const day = smoothstep(-0.12, 0.16, el);
    const sunColor = new THREE.Color(s.sunR, s.sunG, s.sunB);
    const moonColor = new THREE.Color(0x93aee0);
    const keyColor = sunColor.clone().lerp(moonColor, 1 - day);
    // Horizon reddening.
    if (el > -0.2 && el < 0.35) {
      keyColor.lerp(new THREE.Color(0xff7a35), (1 - smoothstep(0.0, 0.35, el)) * 0.55 * day);
    }
    // Moonlight floor. Night must be *blue and readable*, never black — and it
    // must not depend on the preset's solar intensity, which is what pinned the
    // key light to 0.5 and made 00:00 unusable.
    const MOON_KEY = 1.85;
    const keyI = lerp(MOON_KEY, Math.max(s.sunI, MOON_KEY * 0.9), day);

    this.lights.applyMood({
      sunColor: keyColor.getHex(),
      sunIntensity: keyI * (1 + boost * 0.15),
      skyColor: s.skyLight.getHex(),
      groundColor: s.groundLight.getHex(),
      hemiIntensity: s.hemi * 0.65,
      ambientIntensity: s.ambient * 0.42,
      ambientColor: s.ambientColor.getHex(),
      rimIntensity: s.rim * 0.72,
      rimColor: s.rimColor.getHex(),
      craterIntensity: s.crater * (1 + boost * 2.2),
      lakeIntensity: s.lake * (1 + boost * 1.6),
    }, Math.min(1, dt * 2.5));

    // ── sky ──────────────────────────────────────────────────────────
    const u = this.sky.uniforms;
    u.uSunDir.value.copy(dir);
    u.uSunColor.value.copy(keyColor);
    u.uSunIntensity.value = lerp(0.25, 1.0, day) * (0.6 + s.sunI * 0.12);
    u.uZenith.value.copy(s.zenith);
    u.uHorizon.value.copy(s.horizon);
    u.uGround.value.copy(s.groundC);
    u.uHaze.value = s.haze;
    u.uCloudCover.value = s.cover;
    u.uCloudSharp.value = s.sharp;
    u.uCloudColor.value.copy(s.cloudColor);
    u.uCloudShadow.value.copy(s.cloudShadow);
    u.uStars.value = s.stars * this.nightness;
    u.uMoon.value = s.moon * this.nightness;
    u.uEmberGlow.value = s.ember * 0.42 * (1 + boost * 0.5);
    u.uWindDir.value.copy(G.uWindDir.value);

    // Ember direction = the caldera, as seen from the camera-ish origin.
    u.uEmberDir.value.set(WORLD.volcano.x, 130, WORLD.volcano.z).normalize();

    // ── globals ──────────────────────────────────────────────────────
    // The boost is a *nudge*, not a doubling — compounding it with the preset's
    // own ember value is what blew the eruption out to white.
    G.uEmberMood.value = s.ember * (1 + boost * 0.30);
    G.uFogColor.value.copy(s.fogColor);
    G.uFogDensity.value = s.fogDensity;
    G.uWetness.value = s.wet;
    G.uAshLoad.value = s.ashLoad * (1 + boost * 0.6);
    G.uWindStrength.value = s.wind * (1 + boost * 0.35);
    G.uSunColor.value.copy(keyColor);
    G.uSkyColor.value.copy(s.skyLight);

    // ── clouds & fog banks ───────────────────────────────────────────
    this.clouds.setMood({
      cloudOpacity: s.cloudOpacity,
      sunColor: s.cloudColor.getHex(),
      shadowColor: s.cloudShadow.getHex(),
      emberGlow: s.ember * 0.3 * (1 + boost),
      fogOpacity: s.banks,
      fogColor: s.bankColor.getHex(),
    });

    // ── particles ────────────────────────────────────────────────────
    this.atmos.setWeather({
      ash: s.pAsh * (1 + boost * 0.45),
      ember: s.pEmber * (1 + boost * 0.4),
      dust: s.pDust,
      wind: s.pWind,
      leaf: s.pLeaf,
    });
    this.rain.setStrength(s.pRain);

    this.birds?.setMood(this.nightness > 0.6 ? 0x0a0a10 : 0x14100f);

    // ── lightning ────────────────────────────────────────────────────
    this._updateLightning(dt, s.lightning);

    // ── grade handed to PostFX ───────────────────────────────────────
    this.mood = {
      exposure: s.exposure * (1 - boost * 0.14),
      contrast: s.contrast,
      saturation: s.saturation,
      vignette: s.vignette,
      bloom: s.bloom * (1 + boost * 0.18),
      bloomRadius: s.bloomRadius,
      bloomThreshold: Math.max(0.2, s.bloomThreshold - boost * 0.12),
      lift: s.lift.getHex(),
      shadowTint: s.shadowTint.getHex(),
      highlightTint: s.highlightTint.getHex(),
      godRays: s.godRays,
      dofBlur: s.dofBlur,
    };

    // Fog on the scene object itself (three's built-in, for standard materials).
    if (this.scene) {
      this.scene.fog.color.copy(s.fogColor);
      this.scene.fog.density = s.fogDensity;
    }
  }

  _updateLightning(dt, enable) {
    if (enable < 0.1) return;
    this._lightningT += dt;
    if (this._lightningT > this._nextStrike) {
      this._lightningT = 0;
      // Storms cluster: a strike makes a quick follow-up likely.
      this._nextStrike = Math.random() < 0.35 ? 0.4 + Math.random() * 1.2 : 3 + Math.random() * 9;
      // The bolt itself, the light and the flash belong to Lightning (events/);
      // the weather only decides *when* and roughly *where*.
      const x = (Math.random() - 0.5) * 1800, z = 150 + (Math.random() - 0.5) * 1600;
      const to = new THREE.Vector3(x, height(x, z), z);
      const from = new THREE.Vector3(x + (Math.random() - 0.5) * 300, 820 + Math.random() * 160, z + (Math.random() - 0.5) * 300);
      bus.emit(EV.LIGHTNING, { from, to });
    }
  }

}
