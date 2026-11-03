import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { FXAAShader } from 'three/addons/shaders/FXAAShader.js';
import { STYLES, ARCHIVED } from './styles.js';
import { QUALITY, LEVELS, AutoQuality, initialLevel } from './quality.js';
import { World } from './world.js';
import { roadX, zInfo, LANE } from './road.js';
import { BIOMES, BIOME_IDS, dominantBiome, nextBiomeZ } from './biomes.js';
import { buildAssets, buildClouds, MAX_CLOUDS } from './assets.js';
import { CAR_MODELS, buildCarModel } from './cars.js';
import { createSky, createWater, createRain, neonTerrainMaterial, PainterlyShader, FinishShader } from './shaders.js';
import { AudioEngine, STATIONS } from './music.js';
import { Vehicle, Driver, MODES } from './vehicle.js';
import { Traffic, DENSITY, setLights } from './traffic.js';
import { CameraRig, CAMERAS } from './camera.js';
import { Input } from './input.js';
import { Environment, TIME_PRESETS, WEATHER } from './environment.js';
import { loadSettings, saveSettings, DEFAULTS } from './settings.js';
import { UI } from './ui.js';
import { smoothstep } from './noise.js';

const TONE = { neutral: THREE.NeutralToneMapping, aces: THREE.ACESFilmicToneMapping, none: THREE.NoToneMapping };
const LOOK_STATION = { golden: 'drift', synthwave: 'outrun', lowpoly: 'marimba', toon: 'breeze', watercolor: 'glass' };
const QUALITY_MODES = ['auto', ...LEVELS];
const ALL_LOOKS = [...STYLES, ...ARCHIVED];
const KMH = 1 / 3.6;

let S = loadSettings();
const save = () => saveSettings(S);

// ---------------------------------------------------------------- renderer & scene

const canvas = document.getElementById('c');
const renderer = new THREE.WebGLRenderer({ canvas, powerPreference: 'high-performance' });
const DPR = window.devicePixelRatio || 1;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0xffffff, 0.002);
const camera = new THREE.PerspectiveCamera(55, innerWidth / innerHeight, 0.25, 4000);
const hemi = new THREE.HemisphereLight();
const sun = new THREE.DirectionalLight();
Object.assign(sun.shadow.camera, { left: -45, right: 45, top: 45, bottom: -45, near: 1, far: 400 });
sun.shadow.camera.updateProjectionMatrix();
sun.shadow.bias = -0.0004;
sun.shadow.normalBias = 0.03;
scene.add(hemi, sun, sun.target);

// One headlight cone for the player; it stays in the scene (intensity 0 by day) so shaders never recompile.
const headlight = new THREE.SpotLight(0xfff1d6, 0, 70, 0.55, 0.65, 1.1);
const headTarget = new THREE.Object3D();

const sky = createSky();
const water = createWater(QUALITY.high.waterSegments);
const rain = createRain();
scene.add(sky.mesh, water.mesh, rain.mesh);
const pmrem = new THREE.PMREMGenerator(renderer);

// ---------------------------------------------------------------- game objects

const env = new Environment();
const audio = new AudioEngine();
const input = new Input(canvas);
const rig = new CameraRig(camera);
const vehicle = new Vehicle(CAR_MODELS.find((c) => c.id === S.car) ?? CAR_MODELS[0]);
const driver = new Driver(vehicle);
const traffic = new Traffic(scene, CAR_MODELS, () => null);
traffic.onHorn = (car, gap) => audio.horn(Math.sign(car.off - vehicle.offset) * 0.5, gap);

const quality = { mode: S.quality, level: S.quality === 'auto' || !QUALITY[S.quality] ? initialLevel() : S.quality };
const Q = () => QUALITY[quality.level];
const autoQuality = new AutoQuality((fps) => {
  if (quality.mode !== 'auto') return;
  const next = LEVELS[LEVELS.indexOf(quality.level) + 1];
  if (!next) return;
  console.info(`[quality] ${fps.toFixed(0)} fps on ${quality.level}, dropping to ${next}`);
  setQualityLevel(next);
});

let style, assets, world, carObj, clouds, composer, bloomPass, finishPass, paintPass, fxaaPass, envRT;
let envHour = -1, envOvercast = -1;
const game = {
  started: false, paused: false, t: 0, lights: 'auto', lightsOn: false, region: null, regionTimer: 0,
  prevV: 0, accel: 0, saveTimer: 0, hudTimer: 0, buildBoost: 0, roadBase: null,
};

// ---------------------------------------------------------------- look

function applyLook(s) {
  if (s === style) return;
  style = s;
  S.look = s.id;

  world?.dispose();
  if (clouds) scene.remove(clouds);
  assets?.dispose();

  assets = buildAssets(style, style.material === 'neon' ? neonTerrainMaterial(style) : undefined);
  world = new World(scene, style, assets);
  world.update(vehicle.z, vehicle.dir, game.t, 0, 99);
  buildPlayerCar();
  traffic.rebuild((id, paint) => buildCarModel(id, { paint, style, assets }));
  clouds = buildClouds(style, assets, camera.position);
  scene.add(clouds);
  game.roadBase = assets.mats.road.roughness !== undefined
    ? { roughness: assets.mats.road.roughness, color: assets.mats.road.color.clone() } : null;

  env.setLook(style);
  env.setTime(S.time);
  renderer.toneMapping = TONE[style.post.tone];
  envHour = -1;
  buildComposer();
  applyShadows();
  audio.setStation(stationId());
}

function buildPlayerCar() {
  if (carObj) {
    carObj.headAnchor.remove(headlight, headTarget);
    scene.remove(carObj.group);
    carObj.dispose();
  }
  const spec = CAR_MODELS.find((c) => c.id === S.car) ?? CAR_MODELS[0];
  S.car = spec.id;
  if (!spec.paints.includes(S.paint)) S.paint = spec.paints[0];
  vehicle.setSpec(spec);
  carObj = buildCarModel(spec.id, { paint: S.paint, style, assets });
  carObj.headAnchor.add(headlight, headTarget);
  headTarget.position.set(0, -1.2, -18);
  headlight.target = headTarget;
  scene.add(carObj.group);
  carObj.blob.visible = !sun.castShadow;
  placePlayer(0);
}

function stationId() {
  return S.station === 'auto' ? LOOK_STATION[style.id] ?? 'drift' : S.station;
}

// ---------------------------------------------------------------- quality & post

function setQualityLevel(level) {
  quality.level = level;
  water.setSegments(Q().waterSegments);
  applyShadows();
  buildComposer();
  autoQuality.settle(3);
}

function setQualityMode(mode) {
  quality.mode = mode;
  S.quality = mode;
  setQualityLevel(mode === 'auto' ? initialLevel() : mode);
}

function applyShadows() {
  const size = Q().shadowMap;
  sun.castShadow = style.lights.shadows && size > 0;
  if (size && sun.shadow.mapSize.x !== size) {
    sun.shadow.mapSize.set(size, size);
    sun.shadow.map?.dispose();
    sun.shadow.map = null;
  }
  for (const o of [carObj, ...traffic.cars.map((c) => c.obj)]) if (o) o.blob.visible = !sun.castShadow;
}

function buildComposer() {
  if (composer) {
    for (const p of composer.passes) p.dispose?.();
    composer.dispose();
  }
  const q = Q();
  const pr = Math.min(DPR, q.maxPixelRatio, style.post.painterly ? 1.25 : Infinity);
  renderer.setPixelRatio(pr);
  // A hidden window can report 0×0; never allocate zero-size render targets.
  const w = Math.max(innerWidth, 1), h = Math.max(innerHeight, 1);
  renderer.setSize(w, h);
  const rt = new THREE.WebGLRenderTarget(w * pr, h * pr, { type: THREE.HalfFloatType, samples: q.samples });
  composer = new EffectComposer(renderer, rt);
  composer.addPass(new RenderPass(scene, camera));
  const b = style.post.bloom;
  bloomPass = null;
  if (b && q.bloom) {
    bloomPass = new UnrealBloomPass(new THREE.Vector2(w, h), b.strength, b.radius, b.threshold);
    composer.addPass(bloomPass);
  }
  paintPass = null;
  if (style.post.painterly) {
    paintPass = new ShaderPass(PainterlyShader);
    composer.addPass(paintPass);
  }
  finishPass = new ShaderPass(FinishShader);
  const u = finishPass.uniforms;
  u.vignette.value = style.post.vignette;
  u.grain.value = style.post.grain;
  u.scan.value = style.post.scan;
  u.chroma.value = style.post.chroma;
  composer.addPass(finishPass);
  composer.addPass(new OutputPass());
  fxaaPass = null;
  if (q.fxaa) {
    fxaaPass = new ShaderPass(FXAAShader);
    composer.addPass(fxaaPass);
  }
  resize();
}

function resize() {
  const w = innerWidth, h = innerHeight, pr = renderer.getPixelRatio();
  if (!w || !h) return; // hidden window; zero-size targets break the GL context
  renderer.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  composer.setPixelRatio(pr);
  composer.setSize(w, h);
  for (const p of [paintPass, finishPass]) if (p) p.uniforms.resolution.value.set(w * pr, h * pr);
  if (fxaaPass) fxaaPass.uniforms.resolution.value.set(1 / (w * pr), 1 / (h * pr));
}
addEventListener('resize', resize);

// ---------------------------------------------------------------- environment

const _c = new THREE.Color();
function applyEnvironment(st) {
  sky.set(st.sky);
  water.set(st.water, st.sky, st.sky.sunDir, st.fog);
  scene.fog.color.copy(st.fog.color);
  scene.fog.density = st.fog.density;
  scene.background = scene.fog.color;
  const tu = assets.mats.terrain.uniforms;
  if (tu) { tu.fogColor.value.copy(st.fog.color); tu.fogDensity.value = st.fog.density; }

  hemi.color.copy(st.lights.hemiSky);
  hemi.groundColor.copy(st.lights.hemiGround);
  hemi.intensity = st.lights.hemi;
  sun.color.copy(st.lights.sun);
  sun.intensity = st.lights.sunIntensity;
  renderer.toneMappingExposure = st.exposure;
  if (bloomPass) bloomPass.strength = style.post.bloom.strength * st.bloom;

  // Night glow for windows, lamps and the lighthouse.
  const dark = Math.min(1, smoothstep(0.25, 0.8, st.night) + st.overcast * 0.25);
  const neon = style.material === 'neon';
  assets.mats.glow.color.setScalar(neon ? 1.8 : 0.32 + dark * (bloomPass ? 2.4 : 1.4));
  assets.mats.beam.opacity = smoothstep(0.4, 0.9, st.night) * 0.28;

  // Clouds: coverage and colour.
  const max = style.clouds.max ?? Math.max(style.clouds.count, 20);
  const visible = Math.round(max * st.cloudCover);
  clouds.children.forEach((m, i) => { m.visible = i < visible && i < MAX_CLOUDS; });
  const cm = assets.mats.cloud;
  if (style.material !== 'neon') {
    cm.color.copy(st.cloud);
    if (cm.emissive) cm.emissive.copy(st.cloud).multiplyScalar(style.material === 'pbr' ? 0.3 : 0.4);
  }

  // A wet road goes darker and glossier.
  if (game.roadBase) {
    const r = assets.mats.road;
    r.roughness = game.roadBase.roughness + (0.25 - game.roadBase.roughness) * st.wet;
    r.color.copy(game.roadBase.color).multiplyScalar(1 - 0.3 * st.wet);
  }

  // Refresh reflections on realistic materials as the light changes.
  if (style.env && (Math.abs(env.hour - envHour) > 0.25 || Math.abs(st.overcast - envOvercast) > 0.08)) {
    envHour = env.hour;
    envOvercast = st.overcast;
    envRT?.dispose();
    envRT = sky.environment(pmrem);
    scene.environment = envRT.texture;
    scene.environmentIntensity = style.env * (1 - 0.6 * st.night);
  } else if (!style.env && scene.environment) {
    envRT?.dispose();
    envRT = null;
    scene.environment = null;
  }

  const auto = st.night > 0.45 || st.rain > 0.4 || st.fogAmount > 0.6;
  game.lightsOn = game.lights === 'on' || (game.lights === 'auto' && auto);
  headlight.intensity = game.lightsOn ? 320 : 0;
}

// ---------------------------------------------------------------- simulation

function placePlayer(dt) {
  const g = carObj.group;
  g.position.set(vehicle.x, vehicle.y + 0.03, vehicle.z);
  g.rotation.set(vehicle.pitch, vehicle.yaw, 0, 'YXZ');
  carObj.body.rotation.z = vehicle.roll;
  carObj.body.rotation.x = THREE.MathUtils.clamp(-game.accel * 0.006, -0.04, 0.04);
  const spin = (vehicle.v * dt) / (vehicle.spec.dims.wheelRadius ?? 0.38);
  for (const w of carObj.wheels) w.rotation.x -= spin;
  for (const s of carObj.steer) s.rotation.y = -vehicle.steer;
  setLights(carObj, vehicle.brake > 0.1 && vehicle.v > 0.5, game.lightsOn ? 1 : 0);
}

function simulate(dt, controls) {
  const c = driver.update(dt, controls, traffic);
  vehicle.update(dt, c);
  const hit = traffic.collide(vehicle);
  if (hit) {
    audio.bump(hit.strength);
    rig.shake = Math.max(rig.shake, hit.strength * 0.25);
  }
  if (vehicle.impact > 2) {
    audio.bump(Math.min(1, vehicle.impact / 10));
    rig.shake = Math.max(rig.shake, Math.min(0.2, vehicle.impact * 0.02));
  }
  game.accel += ((vehicle.v - game.prevV) / Math.max(dt, 1e-3) - game.accel) * Math.min(1, dt * 6);
  game.prevV = vehicle.v;
  placePlayer(dt);
  traffic.update(dt, vehicle, game.lightsOn ? 1 : Math.min(1, env.state.night * 1.4));
  if (game.started) { // the drive behind the title screen doesn't count
    S.stats.distance += Math.abs(vehicle.v) * dt;
    S.stats.time += dt;
  }
}

function updateAudio(st) {
  const I = zInfo(vehicle.z, {});
  const toSea = I.sd - vehicle.offset;
  const near = (1 - smoothstep(8, 80, toSea)) * (1 - 0.6 * smoothstep(4, 18, I.ry));
  audio.setEngine({ rpm: vehicle.rpm, load: vehicle.throttle, speed: Math.abs(vehicle.v), profile: vehicle.spec.engine });
  audio.setRoad({ speed: Math.abs(vehicle.v), surface: vehicle.onShoulder ? 'gravel' : 'asphalt' });
  audio.setAmbience({ ocean: 0.3 + 0.7 * near, rain: st.rain, wind: st.wind + Math.abs(vehicle.v) / 80, night: st.night });
}

function trackRegion(dt) {
  const id = dominantBiome(vehicle.z);
  if (id === game.region) { game.regionTimer = 0; return; }
  game.regionTimer += dt;
  if (game.regionTimer > 1.5 || game.region === null) {
    game.region = id;
    game.regionTimer = 0;
    if (game.started) ui.region(BIOMES[id].name, `${env.clock} · ${WEATHER[env.weatherId].name}`);
  }
}

// ---------------------------------------------------------------- formatting

const fmtSpeed = (v) => (S.units === 'mph' ? `${Math.round(v * 2.237)} mph` : `${Math.round(v * 3.6)} km/h`);
const fmtDist = (m) => (S.units === 'mph' ? `${(m / 1609.34).toFixed(1)} mi` : `${(m / 1000).toFixed(1)} km`);
function fmtTime(sec) {
  const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
  return h ? `${h} h ${m} min` : `${m} min`;
}

function updateHud() {
  const np = audio.nowPlaying?.() ?? {};
  const modeText = driver.mode === 'manual' ? 'Manual' : `${MODES[driver.mode]} ${fmtSpeed(driver.setSpeed).split(' ')[0]}`;
  ui.hud({
    speed: Math.round(Math.abs(vehicle.v) * (S.units === 'mph' ? 2.237 : 3.6)),
    unit: S.units === 'mph' ? 'mph' : 'km/h',
    gear: vehicle.gearLabel,
    mode: driver.mode,
    modeText,
    lights: game.lightsOn,
    clock: env.clock,
    weather: WEATHER[env.weatherId].name,
    odo: fmtDist(S.stats.distance),
    station: np.name ?? STATIONS.find((s) => s.id === stationId())?.name ?? 'Radio',
    meta: np.key ? `${np.key} · ${Math.round(np.bpm)} bpm` : (stationId() === 'off' ? 'ambience only' : ''),
    camera: CAMERAS.find((c) => c.id === rig.mode).name,
  });
}

// ---------------------------------------------------------------- actions

function toast(text) { ui.toast(text); }

function travelTo(id) {
  const dir = vehicle.dir;
  const z = nextBiomeZ(vehicle.z, id, dir);
  const v = vehicle.v;
  vehicle.place(z, (dir < 0 ? 1 : -1) * LANE, dir);
  vehicle.v = v;
  driver.laneOff = vehicle.offset;
  world.dispose();
  world.update(vehicle.z, dir, game.t, 0, 99);
  traffic.clear();
  water.update(game.t, camera.position, shoreAt, true);
  rig.snap = true;
  game.region = null;
  placePlayer(0);
}

function turnAround() {
  const dir = -vehicle.dir;
  const v = vehicle.v;
  vehicle.place(vehicle.z, (dir < 0 ? 1 : -1) * LANE, dir);
  vehicle.v = Math.max(0, v);
  driver.laneOff = vehicle.offset;
  driver.overtaking = null;
  game.buildBoost = 1.5;
  rig.snap = true;
  placePlayer(0);
}

function cycle(list, current) {
  return list[(list.indexOf(current) + 1) % list.length];
}

function saveScreenshot() {
  composer.render(0);
  const url = renderer.domElement.toDataURL('image/png');
  const a = document.createElement('a');
  const stamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-');
  a.href = url;
  a.download = `beach-road-${stamp}.png`;
  a.click();
  toast('Screenshot saved');
}

const ACTIONS = {
  autodrive() { driver.toggleAuto(); toast(driver.mode === 'auto' ? `Autodrive on · ${fmtSpeed(driver.setSpeed)}` : 'Autodrive off'); },
  cruise() { driver.toggleCruise(); toast(driver.mode === 'cruise' ? `Cruise control · ${fmtSpeed(driver.setSpeed)}` : 'Cruise off'); },
  speedUp() { driver.adjustSpeed(5 * KMH * (S.units === 'mph' ? 1.609 : 1)); toast(`Set speed ${fmtSpeed(driver.setSpeed)}`); },
  speedDown() { driver.adjustSpeed(-5 * KMH * (S.units === 'mph' ? 1.609 : 1)); toast(`Set speed ${fmtSpeed(driver.setSpeed)}`); },
  camera() { rig.next(); S.camera = rig.mode; toast(CAMERAS.find((c) => c.id === rig.mode).name); },
  nextStation() { stepStation(1); },
  prevStation() { stepStation(-1); },
  lights() { game.lights = cycle(['auto', 'on', 'off'], game.lights); toast(`Headlights: ${game.lights}`); },
  horn() { audio.horn(0, 0); },
  hud() { S.hud = !S.hud; ui.setHudVisible(S.hud); },
  mute() { S.muted = !S.muted; audio.setMuted(S.muted); toast(S.muted ? 'Sound off' : 'Sound on'); },
  screenshot: saveScreenshot,
  menu() { if (ui.open) resume(); else pause(); },
  resume,
  time() {
    if (!env.dynamicTime) { toast('This look is always night'); return; }
    S.time = cycle(['default', ...TIME_PRESETS.map((p) => p.id), 'cycle'], S.time);
    env.setTime(S.time);
    toast(S.time === 'cycle' ? 'Day cycle' : S.time === 'default' ? 'Look default time' : TIME_PRESETS.find((p) => p.id === S.time).name);
  },
  weather() {
    S.weather = cycle([...Object.keys(WEATHER), 'auto'], S.weather);
    env.setWeather(S.weather);
    toast(S.weather === 'auto' ? 'Changing weather' : WEATHER[S.weather].name);
  },
  look1() { setLook(STYLES[0]); },
  look2() { setLook(STYLES[1]); },
  look3() { setLook(STYLES[2]); },
  turnAround() {
    if (vehicle.misalignment > 0.8) {
      vehicle.recover();
      driver.laneOff = vehicle.offset;
      rig.snap = true;
      toast('Back on the road');
    } else {
      turnAround();
      toast('Turned around');
    }
  },
  reset() {
    const stats = S.stats;
    S = JSON.parse(JSON.stringify(DEFAULTS));
    S.stats = stats;
    applySettings();
    toast('Settings reset');
  },
  tab(id) { rig.showroom = id === 'garage'; },
};

function stepStation(step) {
  const ids = STATIONS.map((s) => s.id);
  const cur = stationId();
  S.station = ids[(ids.indexOf(cur) + step + ids.length) % ids.length];
  audio.setStation(S.station);
  toast(STATIONS.find((s) => s.id === S.station)?.name ?? S.station);
  save();
}

function setLook(s) {
  applyLook(s);
  toast(s.name);
  save();
}

function pause() {
  if (!game.started) return;
  game.paused = true;
  input.enabled = false;
  ui.show('drive');
}

function resume() {
  if (!game.started) {
    game.started = true;
    audio.start();
    audio.setStation(stationId());
    rig.setMode(S.camera);
    ui.started = true;
    ui.hint(true);
    setTimeout(() => ui.hint(false), 14000);
    setTimeout(() => game.region && ui.region(BIOMES[game.region].name, `${env.clock} · ${WEATHER[env.weatherId].name}`), 900);
    if (driver.mode === 'auto') setTimeout(() => toast('Autodrive is on · brake or steer to take over'), 2500);
  }
  game.paused = false;
  input.enabled = true;
  rig.showroom = false;
  ui.hide();
  save();
}

function onSet(key, value) {
  audio.click?.();
  switch (key) {
    case 'mode': driver.setMode(value); break;
    case 'camera': rig.setMode(value); S.camera = value; break;
    case 'car': S.car = value; S.paint = null; buildPlayerCar(); break;
    case 'paint': S.paint = value; buildPlayerCar(); break;
    case 'look': applyLook(ALL_LOOKS.find((l) => l.id === value)); break;
    case 'time': S.time = value; env.setTime(value); break;
    case 'weather': S.weather = value; env.setWeather(value, game.paused); break;
    case 'traffic': S.traffic = value; traffic.setDensity(value); break;
    case 'station': S.station = value; audio.setStation(stationId()); break;
    case 'muted': S.muted = value === 'true'; audio.setMuted(S.muted); break;
    case 'quality': setQualityMode(value); break;
    case 'units': S.units = value; break;
    case 'hud': S.hud = value === 'true'; ui.setHudVisible(S.hud); break;
    default:
      if (key.startsWith('volume.')) {
        S.volume[key.slice(7)] = value;
        audio.setVolumes(S.volume);
      }
  }
  save();
}

function onAction(name, arg) {
  if (name.startsWith('travel:')) {
    const id = name.slice(7);
    travelTo(id);
    toast(`Travelling to ${BIOMES[id].name}`);
    ui.render();
    return;
  }
  ACTIONS[name]?.(arg);
}

for (const name of Object.keys(ACTIONS)) {
  if (!['resume', 'reset', 'tab'].includes(name)) {
    input.on(name, () => {
      if (ui.open && name !== 'menu') return;
      if (!game.started && name === 'menu') return;
      ACTIONS[name]();
    });
  }
}

// ---------------------------------------------------------------- UI

const ui = new UI({
  model: () => ({
    modes: [{ id: 'manual', name: 'Manual' }, { id: 'cruise', name: 'Cruise control' }, { id: 'auto', name: 'Autodrive' }],
    mode: driver.mode,
    setSpeed: fmtSpeed(driver.setSpeed),
    cameras: CAMERAS,
    camera: rig.mode,
    stats: { distance: fmtDist(S.stats.distance), time: fmtTime(S.stats.time) },
    region: BIOMES[game.region ?? 'tropical'].name,
    regionId: game.region,
    cars: CAR_MODELS.map((c) => ({
      id: c.id, name: c.name, blurb: c.blurb, paints: c.paints, topSpeed: c.stats.topSpeed, accel: c.stats.accel,
      handling: Math.min(1, (c.stats.steer / 0.65) * 0.5 + c.stats.grip * 0.5),
      engine: c.engine.character === 'electric' ? 'electric' : `${c.engine.cylinders}-cylinder, ${c.engine.gears} gears`,
    })),
    car: S.car,
    paint: S.paint,
    looks: STYLES.map((l) => ({ id: l.id, name: l.name, tagline: l.tagline, swatch: `linear-gradient(135deg, ${l.sky.top}, ${l.sky.horizon} 55%, ${l.water.deep})` })),
    look: style.id,
    timeEnabled: env.dynamicTime,
    times: TIME_PRESETS,
    time: S.time,
    clock: env.clock,
    weathers: Object.entries(WEATHER).map(([id, w]) => ({ id, name: w.name })),
    weather: S.weather,
    densities: Object.keys(DENSITY),
    traffic: S.traffic,
    regions: BIOME_IDS.map((id) => ({ id, name: BIOMES[id].name })),
    stations: [{ id: 'auto', name: 'Match the look', description: 'Each look picks its own station' }, ...STATIONS],
    station: S.station,
    nowPlaying: (() => { const n = audio.nowPlaying?.(); return n?.name ? `${n.name}${n.key ? ` · ${n.key}` : ''}` : 'press Start to hear it'; })(),
    volume: S.volume,
    muted: S.muted,
    quality: quality.mode,
    qualityLevel: QUALITY[quality.level].label,
    units: S.units,
    hud: S.hud,
  }),
  onSet,
  onAction,
});

function shoreAt(z) {
  const I = zInfo(z, {});
  return [I.sd, I.m.shape.rough];
}

// ---------------------------------------------------------------- loop

const clock = new THREE.Clock();
function frame() {
  const raw = clock.getDelta();
  if (!game.paused) autoQuality.sample(raw);
  update(Math.min(raw, 1 / 20));
  requestAnimationFrame(frame);
}

function update(dt) {
  const controls = input.poll(dt);
  if (controls.orbitX || controls.orbitY) rig.drag(controls.orbitX, controls.orbitY);
  if (controls.zoom) rig.wheel(controls.zoom);

  if (!game.paused) {
    game.t += dt;
    simulate(dt, controls);
    const st = env.update(dt);
    applyEnvironment(st);
    updateAudio(st);
    trackRegion(dt);
    world.update(vehicle.z, vehicle.dir, game.t, dt, game.buildBoost > 0 ? 4 : 1);
    game.buildBoost -= dt;
  } else {
    applyEnvironment(env.update(0)); // menu changes to time and look show straight away
  }
  if (!game.paused || rig.showroom) rig.update(dt, vehicle, carObj, game.t);

  sky.mesh.position.copy(camera.position);
  sky.material.uniforms.time.value = game.t;
  water.update(game.t, camera.position, shoreAt);
  rain.update(game.t, camera.position, env.state.rain, style.rainColor);
  sun.target.position.copy(carObj.group.position);
  sun.position.copy(carObj.group.position).addScaledVector(env.state.lightDir, 150);
  updateClouds(dt);
  finishPass.uniforms.time.value = game.t;
  if (!game.noRender) composer.render(dt);

  if ((game.hudTimer -= dt) < 0) { game.hudTimer = 0.2; updateHud(); }
  if ((game.saveTimer += dt) > 10) { game.saveTimer = 0; save(); }
}

function updateClouds(dt) {
  for (const m of clouds.children) {
    m.position.x += dt * (1.5 + env.state.wind * 4);
    while (m.position.z - camera.position.z > 600) m.position.z -= 1500;
    while (m.position.z - camera.position.z < -900) m.position.z += 1500;
    while (m.position.x - camera.position.x > 700) m.position.x -= 1400;
    while (m.position.x - camera.position.x < -700) m.position.x += 1400;
  }
}

// ---------------------------------------------------------------- start

function applySettings() {
  quality.mode = S.quality;
  quality.level = S.quality === 'auto' || !QUALITY[S.quality] ? initialLevel() : S.quality;
  water.setSegments(Q().waterSegments);
  traffic.setDensity(S.traffic);
  env.setWeather(S.weather, true);
  const look = ALL_LOOKS.find((l) => l.id === S.look) ?? STYLES[0];
  style = null;
  applyLook(look);
  audio.setVolumes(S.volume);
  audio.setMuted(S.muted);
  ui.setHudVisible(S.hud);
  if (game.started) rig.setMode(S.camera);
  ui.render();
}

const requested = new URLSearchParams(location.search).get('style');
if (requested && ALL_LOOKS.some((l) => l.id === requested)) S.look = requested;

vehicle.place(-40, LANE, -1);
vehicle.v = 22;
driver.setMode('auto');
driver.setSpeed = 22;
rig.setMode('cinematic');
applySettings();
ui.show('drive');
frame();

addEventListener('visibilitychange', () => { if (document.hidden) save(); });
addEventListener('pagehide', save);

// Debug hooks. step(n) advances frames by hand (useful when the tab is throttled);
// bench(n) returns the average milliseconds per frame, waiting for the GPU to finish.
window.beachRoad = {
  vehicle, driver, traffic, env, rig, game, input, renderer, ui, scene, headlight, settings: () => S, onSet, onAction,
  applyLook: (id) => applyLook(ALL_LOOKS.find((l) => l.id === id)),
  setQualityLevel, travelTo,
  step(n = 1, dt = 1 / 60) { for (let i = 0; i < n; i++) update(dt); },
  // Like step() but only renders the last frame: fast-forwards the simulation.
  sim(n = 1, dt = 1 / 60) {
    game.noRender = true;
    for (let i = 0; i < n - 1; i++) update(dt);
    game.noRender = false;
    update(dt);
  },
  bench(n = 60) {
    const gl = renderer.getContext(), px = new Uint8Array(4);
    const sync = () => gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px);
    update(1 / 60);
    sync();
    const t0 = performance.now();
    for (let i = 0; i < n; i++) { update(1 / 60); sync(); }
    return (performance.now() - t0) / n;
  },
};
