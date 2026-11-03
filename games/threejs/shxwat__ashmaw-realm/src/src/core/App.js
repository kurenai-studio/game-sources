/**
 * App — the composition root.
 *
 * Owns the renderer, the scene graph, the frame loop and the wiring between
 * systems. Nothing here contains rendering *technique*; it's all delegation, so
 * this file stays readable as the map of the project.
 *
 * Build order matters and is deliberate:
 *   1. renderer + textures (everything else needs materials)
 *   2. sky → PMREM environment (materials need an envMap before first frame)
 *   3. terrain (structures need to know the ground)
 *   4. structures → vegetation → props (each queries the heightfield)
 *   5. dragon, particles, weather, post, camera, UI
 *
 * Each step yields to the browser so the loading bar actually animates instead
 * of freezing on a single long task.
 */
import * as THREE from 'three';
import { bus, EV } from './EventBus.js';
import { Settings, detectTier } from './Settings.js';
import { PerfMonitor } from './PerfMonitor.js';
import { AssetLoader } from '../loaders/AssetLoader.js';
import { buildTextures, loadScannedRock } from '../materials/ProceduralTextures.js';
import { MaterialLibrary } from '../materials/MaterialLibrary.js';
import { G, tickGlobals } from '../materials/GlobalUniforms.js';
import { Sky } from '../scene/Sky.js';
import { Clouds } from '../scene/Clouds.js';
import { LightRig } from '../lights/LightRig.js';
import { Terrain } from '../world/Terrain.js';
import { Lava } from '../world/Lava.js';
import { Water } from '../world/Water.js';
import { Ocean } from '../world/Ocean.js';
import { Volcano } from '../world/Volcano.js';
import { Rocks } from '../world/Rocks.js';
import { Forest, Grass } from '../world/Vegetation.js';
import { Birds } from '../world/Birds.js';
import { Castle } from '../structures/Castle.js';
import { Village } from '../structures/Village.js';
import { Ruins } from '../structures/Ruins.js';
import { Torches } from '../structures/Torches.js';
import { Props } from '../structures/Props.js';
import { Atmosphere, Rain } from '../particles/Atmosphere.js';
import { Dragon } from '../dragon/Dragon.js';
import { DragonAnimator } from '../dragon/DragonAnimator.js';
import { Flight } from '../dragon/Flight.js';
import { FireBreath } from '../dragon/FireBreath.js';
import { PostFX } from '../effects/PostFX.js';
import { CameraRig } from '../camera/CameraRig.js';
import { CinematicDirector } from '../camera/CinematicDirector.js';
import { WeatherSystem } from '../weather/WeatherSystem.js';
import { Eruption } from '../events/Eruption.js';
import { Lightning } from '../events/Lightning.js';
import { Cataclysm } from '../events/Cataclysm.js';
import { Wildfire } from '../world/Wildfire.js';
import { SoundEngine } from '../audio/SoundEngine.js';
import { UI } from '../ui/UI.js';
import { WORLD, height } from '../world/Heightfield.js';

/**
 * Yield to the browser between build steps so the loading bar actually animates.
 *
 * rAF alone is the natural choice, but a backgrounded tab throttles it to ~1 Hz
 * and Chrome freezes it outright after a few minutes — so someone who opens the
 * link and switches tabs while it loads comes back to a progress bar frozen on
 * step one, forever. Racing rAF against a MessageChannel tick (which background
 * throttling does not clamp) keeps the paint-synced yield while the tab is
 * visible and degrades to "just keep building" while it isn't.
 */
const nextFrame = () => new Promise((resolve) => {
  let done = false;
  const go = () => { if (!done) { done = true; resolve(); } };
  requestAnimationFrame(go);
  if (document.hidden) {
    const ch = new MessageChannel();
    ch.port1.onmessage = go;
    ch.port2.postMessage(0);
  }
});

export class App {
  constructor({ canvas, onProgress }) {
    this.canvas = canvas;
    this.onProgress = onProgress ?? (() => {});
    this.settings = new Settings(detectTier());
    this.paused = false;
    this.clock = new THREE.Clock();
    this.elapsed = 0;
    this._raf = 0;
  }

  /* ── build ────────────────────────────────────────────────────────── */

  async build() {
    const S = this.settings;
    const step = async (t, label, fn) => {
      this.onProgress(t, label);
      await nextFrame();
      return fn();
    };

    // ── renderer ─────────────────────────────────────────────────────
    await step(0.14, 'Forging the renderer', () => {
      this.renderer = new THREE.WebGLRenderer({
        canvas: this.canvas,
        antialias: false,           // handled in post (SMAA/FXAA)
        powerPreference: 'high-performance',
        stencil: false,
        depth: true,
        alpha: false,
      });
      this.renderer.setPixelRatio(S.pixelRatio);
      this.renderer.setSize(innerWidth, innerHeight, false);
      this.renderer.outputColorSpace = THREE.SRGBColorSpace;
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 0.92;
      this.renderer.shadowMap.enabled = S.shadows;
      this.renderer.shadowMap.type = S.softShadows
        ? THREE.PCFSoftShadowMap
        : THREE.PCFShadowMap;
      // The composer renders many passes per frame; auto-reset would leave
      // info reflecting only the last fullscreen quad. Reset once per frame.
      this.renderer.info.autoReset = false;

      this.scene = new THREE.Scene();
      this.scene.fog = new THREE.FogExp2(0x40242a, 0.00058);

      this.assets = new AssetLoader(this.renderer);
      this.perf = new PerfMonitor(this.renderer);
      this.perf.onScale = (s) => {
        this.renderer.setPixelRatio(S.pixelRatio * s);
        this.post?.setSize(innerWidth, innerHeight);
      };
    });

    // ── textures & materials ─────────────────────────────────────────
    await step(0.22, 'Weaving textures', async () => {
      this.textures = buildTextures();
      await loadScannedRock(this.textures);
    });

    // ── sky first: materials want an environment map ─────────────────
    await step(0.32, 'Raising the sky', () => {
      this.sky = new Sky(this.renderer, { envResolution: S.envResolution });
      this.scene.add(this.sky.mesh);
      this.sky.updateEnvironment(true);
      this.scene.environment = this.sky.envMap;

      this.materials = new MaterialLibrary(this.textures, this.sky.envMap);
      this.materials.T = this.textures;
      this.materials.env = this.sky.envMap;
      this.materials.setEnv(this.sky.envMap);
    });

    await step(0.40, 'Lighting the world', () => {
      this.lights = new LightRig(this.scene, S);
    });

    // ── terrain ──────────────────────────────────────────────────────
    await step(0.48, 'Raising mountains', () => {
      this.terrain = new Terrain(this.materials, S);
      this.scene.add(this.terrain.mesh);
    });

    await step(0.55, 'Opening the fissures', () => {
      this.lava = new Lava();
      this.scene.add(this.lava.group);
      this.volcano = new Volcano(this.materials, S);
      this.scene.add(this.volcano.group);
    });

    await step(0.61, 'Letting the rivers run', () => {
      this.water = new Water(this.materials, S);
      this.scene.add(this.water.group);
      this.ocean = new Ocean(this.materials, this.sky, this.terrain);
      this.scene.add(this.ocean.mesh);
    });

    // ── structures ───────────────────────────────────────────────────
    await step(0.67, 'Building Kaer Ashmaw', () => {
      this.castle = new Castle(this.materials, S);
      this.scene.add(this.castle.group);
    });

    await step(0.73, 'Settling Emberhold', () => {
      this.village = new Village(this.materials, S);
      this.scene.add(this.village.group);
    });

    await step(0.78, 'Raising the ruins', () => {
      this.ruins = new Ruins(this.materials, S);
      this.scene.add(this.ruins.group);

      // Torches get extra spots on the castle approach and both bridges.
      const extra = [];
      for (let i = 0; i < 6; i++) {
        const t = i / 5;
        extra.push([
          WORLD.castle.x + 120 + t * 90,
          WORLD.castle.z + 90 + t * 70,
          1.1,
        ]);
      }
      this.torches = new Torches(this.materials, S, { extraSpots: extra });
      this.scene.add(this.torches.group);
    });

    await step(0.81, 'Setting out the market', () => {
      this.props = new Props(this.materials, S, this.village);
      this.scene.add(this.props.group);
    });

    await step(0.84, 'Planting the ash-forest', () => {
      this.rocks = new Rocks(this.materials, S);
      this.scene.add(this.rocks.group);
      this.forest = new Forest(this.materials, S);
      this.scene.add(this.forest.group);
      this.grass = new Grass(this.materials, S);
      this.scene.add(this.grass.group);
    });

    // ── air ──────────────────────────────────────────────────────────
    await step(0.89, 'Filling the air with ash', () => {
      this.clouds = new Clouds(S);
      this.scene.add(this.clouds.group);
      this.atmos = new Atmosphere(this.materials, S);
      this.scene.add(this.atmos.group);
      this.rain = new Rain(S);
      this.scene.add(this.rain.group);
      this.birds = new Birds(S);
      this.scene.add(this.birds.group);
      this.wildfire = new Wildfire(S);
      this.scene.add(this.wildfire.group);
    });

    // ── the dragon ───────────────────────────────────────────────────
    await step(0.93, 'Waking the Emberwyrm', () => {
      const dragon = new Dragon(this.materials, S);
      dragon.setScale(1.35);
      this.scene.add(dragon.group);
      const animator = new DragonAnimator(dragon, {
        castle: this.castle,
        village: this.village,
      });
      this.fire = new FireBreath(this.materials, S);
      this.scene.add(this.fire.group);

      animator.onBreath = (duration) => {
        this.fire.ignite({
          origin: dragon.mouth.position.clone(),
          dir: dragon.mouthDir?.clone() ?? new THREE.Vector3(0, -1, 0),
          duration,
          length: 190,
        });
      };
      this.dragon = { dragon, animator };

      // Lesser wyrms on their own orbits. Scenery, not peers — see Flight.js
      // for why they are deliberately not wired into anything that says
      // "the dragon".
      this.flight = new Flight(this.materials, S);
      this.scene.add(this.flight.group);
    });

    // ── weather, post, camera, ui ────────────────────────────────────
    await step(0.96, 'Setting the weather', () => {
      this.weather = new WeatherSystem({
        sky: this.sky,
        lights: this.lights,
        clouds: this.clouds,
        atmosphere: this.atmos,
        rain: this.rain,
        materials: this.materials,
        birds: this.birds,
      });
      this.weather.scene = this.scene;
      this.weather.apply('sunset', 0);

      this.lightning = new Lightning({ lights: this.lights });
      this.scene.add(this.lightning.group);

      this.eruption = new Eruption({
        lightning: this.lightning,
        volcano: this.volcano,
        weather: this.weather,
        village: this.village,
        dragon: this.dragon,
        lava: this.lava,
      });
    });

    await step(0.985, 'Mounting the lens', () => {
      this.rig = new CameraRig(this.canvas, { aspect: innerWidth / innerHeight });
      this.camera = this.rig.camera;

      this.post = new PostFX(this.renderer, this.scene, this.camera, S, this.materials);

      this.director = new CinematicDirector(this.rig, {
        dragon: this.dragon,
        village: this.village,
        castle: this.castle,
        eruption: this.eruption,
      });

      this.cataclysm = new Cataclysm(this);
      this.sound = new SoundEngine({
        getListener: () => this.camera,
        getSurge: () => this.volcano.surge,
        getBurning: () => this.wildfire.activeCount,
      });

      // The roar's pressure wave: leaves the jaws, races out at ~300 m/s.
      this._roar = null;
      bus.on(EV.ROAR, ({ origin }) => {
        this._roar = { origin: origin.clone(), t: 0 };
      });

      this.ui = new UI(this);
      bus.emit(EV.QUALITY, { tier: S.tier, settings: S });

      addEventListener('resize', () => this._resize(), { passive: true });
      document.addEventListener('visibilitychange', () => {
        if (document.hidden) this.clock.getDelta();   // swallow the gap
      });
    });

    // Warm the shader cache — compiling 40 programs on frame 1 is a 2s hitch.
    await step(0.995, 'Compiling shaders', async () => {
      this.dragon.animator.update(0.016, this.camera);
      await this.renderer.compileAsync(this.scene, this.camera);
    });

    return this;
  }

  /* ── loop ─────────────────────────────────────────────────────────── */

  start() {
    this.started = true;
    this.clock.start();
    this.director.start(0);
    this.dragon.animator.circle({ radius: 520, altitude: 420, speed: 44 });
    const loop = () => {
      this._raf = requestAnimationFrame(loop);
      this._frame();
    };
    loop();
  }

  _frame() {
    this.renderer.info.reset();
    const raw = this.clock.getDelta();
    // Clamp: a tab-switch or a GC pause must not teleport the simulation.
    const dt = this.paused ? 0 : Math.min(raw, 1 / 20);
    this.elapsed += dt;

    tickGlobals(dt, this.elapsed);

    if (dt > 0) {
      // ── world ──────────────────────────────────────────────────────
      this.weather.update(dt);
      this.eruption.update(dt);
      this.sky.update(dt, this.elapsed);

      // Refresh the IBL a few times a minute, and whenever the light changes a
      // lot — a full PMREM every frame would cost more than the whole scene.
      this._envTimer = (this._envTimer ?? 0) + dt;
      if (this._envTimer > 2.5) {
        this._envTimer = 0;
        this.sky.markEnvDirty();
        const env = this.sky.updateEnvironment();
        if (env && env !== this.scene.environment) {
          this.scene.environment = env;
          this.materials.setEnv(env);
          this.ocean?.setEnv(env);
        }
      }

      this.dragon.animator.update(dt, this.camera);
      this.flight.update(dt, this.camera);
      this.fire.update(dt, this.camera);
      this.wildfire.update(dt, this.camera, this.fire.group.visible);
      this.lightning.update(dt);
      this._updateRoar(dt);
      this.volcano.update(dt, this.camera);
      this.lava.update(dt, this.camera);
      this.water.update(dt, this.camera);
      this.birds.update(dt, this.dragon.animator.pos);
      this.village.update(dt, this.elapsed, this.weather.nightness, this.eruption.disturbance);
      this.castle.update(dt, this.elapsed);
      this.forest.update(dt, this.camera);
      this.clouds.update(dt, this.camera);
      this.atmos.update(dt, this.camera);
      this.rain.update(dt, this.camera);
      this.torches.update(dt, this.camera, this.elapsed, 0.35 + this.weather.nightness * 1.15);
      this.torches.setNightness(this.weather.nightness);
      this.props.update(dt, this.elapsed);

      // ── camera ─────────────────────────────────────────────────────
      this.director.update(dt);
      this.rig.update(dt, { dragon: this.dragon.animator });

      // Shadows follow whatever we're looking at; the hero light follows the wyrm.
      this.lights.update(dt, this.camera, this.rig.focus);
      this.lights.followHero(this.dragon.animator.pos, this.weather.nightness);
    }

    // ── post ─────────────────────────────────────────────────────────
    const sunWorld = G.uSunDir.value.clone()
      .multiplyScalar(6000).add(this.camera.position);
    this.post.update(Math.max(dt, 1e-4), {
      sunWorld,
      fireWorld: this.fire.group.visible ? G.uFirePos.value.clone() : null,
      fireStrength: G.uFireIntensity.value,
      ventWorld: this.volcano.vent,
      ventStrength: 0.16 + this.volcano.surge * 0.7,
      focusTarget: this.rig.focus,
      mood: this.weather.mood,
      waves: this._waves(),
    });
    this.sound.update(dt);

    this.post.render(Math.max(dt, 1e-4));
    this.perf.update(Math.max(raw, 1e-4));
  }

  _updateRoar(dt) {
    const r = this._roar;
    if (!r) return;
    r.t += dt;
    const R = r.t * 300;
    if (R > 900) { this._roar = null; G.uRoarWave.value.w = -1; return; }
    G.uRoarWave.value.set(r.origin.x, r.origin.y, r.origin.z, R);
  }

  /** Expanding pressure fronts the grade pass should refract. */
  _waves() {
    const out = [];
    const S = G.uShockwave.value;
    if (S.w > 0) {
      out.push({ origin: this.volcano.vent, radius: S.w, strength: 1.4 * (1 - Math.min(1, S.w / 1500)) });
    }
    if (this._roar) {
      const R = this._roar.t * 300;
      out.push({ origin: this._roar.origin, radius: R, strength: 0.9 * (1 - R / 900) });
    }
    return out;
  }

  /* ── commands (called by UI) ──────────────────────────────────────── */

  setCameraMode(mode) {
    if (mode === 'cinematic') this.director.start(this.director.index);
    else this.director.stop();
    this.rig.setMode(mode === 'cinematic' ? 'cinematic' : mode);
  }

  setWeather(key) { this.weather.apply(key, 3.5); }

  setTimeOfDay(t) {
    this.weather.lockTimeOfDay(true);
    this.weather.setTimeOfDay(t, 0);
    this.sky.markEnvDirty();
  }

  nudgeTime(d) {
    const t = (this.weather.tod + d + 1) % 1;
    this.setTimeOfDay(t);
    bus.emit(EV.TIME_OF_DAY, { t });
  }

  action(kind) {
    const a = this.dragon.animator;
    switch (kind) {
      case 'fire': {
        // Aim at whatever is in front of the dragon, biased at the ground.
        const target = this.village.plaza.clone();
        if (a.state === 'perched') {
          // Perched: breathe outward over the courtyard.
          const dir = a.forward.clone().setY(-0.28).normalize();
          const origin = this.dragon.dragon.mouth.position.clone();
          a.p.mouthOpen = 1;
          a.p.charge = 1;
          this.fire.ignite({ origin, dir, duration: 3.2, length: 175 });
          setTimeout(() => { a.p.mouthOpen = 0; a.p.charge = 0; }, 3600);
        } else {
          a.attack(target);
        }
        break;
      }
      case 'land': a.land(this.castle.perch); break;
      case 'takeoff': a.takeoff(); break;
      case 'roar': a.roar(); break;
      case 'erupt': this.eruption.trigger(); break;
      case 'flyby': a.flyby(); break;
      case 'lightning': this.lightning.stormStrike(this.rig.focus, 450); break;
      case 'cataclysm': this.cataclysm.trigger(); break;
      case 'mute': {
        const m = this.sound.toggleMute();
        document.querySelectorAll('[data-act="mute"]').forEach((b) => {
          b.textContent = m ? 'Sound Off' : 'Sound On';
          b.classList.toggle('is-on', !m);
        });
        break;
      }
    }
  }

  setFx(key, on) {
    if (key === 'wire') { this.materials.setWireframe(on); return; }
    this.post.set(key, on);
  }

  setQuality(tier) {
    const S = this.settings.apply(tier);
    this.renderer.setPixelRatio(S.pixelRatio);
    this.renderer.shadowMap.enabled = S.shadows;
    this.renderer.shadowMap.type = S.softShadows ? THREE.PCFSoftShadowMap : THREE.PCFShadowMap;
    this.lights.applyQuality(S);
    this.torches.applyQuality(S);
    this.post.applyQuality(S);
    this.perf.scale = 1;
    bus.emit(EV.QUALITY, { tier, settings: S });
    // Counts (trees, particles) are baked at build time; a full rebuild of the
    // world for a tier change isn't worth the hitch, so we scale what's cheap
    // and note it in the readout.
  }

  togglePause() {
    this.paused = !this.paused;
    bus.emit(EV.PAUSE, { paused: this.paused });
  }

  _resize() {
    const w = innerWidth, h = innerHeight;
    this.renderer.setSize(w, h, false);
    this.rig.resize(w / h);
    this.post.setSize(w, h);
  }

  dispose() {
    cancelAnimationFrame(this._raf);
    for (const s of [this.terrain, this.lava, this.water, this.ocean, this.volcano, this.rocks,
      this.forest, this.grass, this.castle, this.village, this.ruins, this.torches,
      this.atmos, this.rain, this.clouds, this.birds, this.fire, this.sky, this.post,
      this.props, this.flight, this.wildfire, this.lightning, this.sound]) {
      s?.dispose?.();
    }
    this.renderer.dispose();
  }
}
