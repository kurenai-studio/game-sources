/**
 * Balloon Ride boot. The reused Bay Ride environment (toon uber-shader, painted sky and cumulus,
 * time of day, painterly post chain) over the countryside of world/ (Phase 2: terrain, patchwork
 * fields, river and lake, village, woods, hedgerows, life). No gameplay yet, no text on screen.
 *
 * URL: ?time=sunrise|golden|sunset|blue (also ?tod=), ?seed=<n> (world layout seed), ?t=<seconds> freezes the clock
 * at that time (captures), ?capture=1 keeps the drawing buffer for screenshots, ?gpu logs the
 * WebGL adapter. `window.__game` drives it from scripts (see docs/PROGRESS.md).
 */
import * as THREE from "three";
import { G, specializeUber, uber } from "./render/materials";
import { leafAtlas } from "./render/leafAtlas";
import { PlanarReflection, SunShadow } from "./render/lightpasses";
import { Post } from "./render/post";
import { precompile } from "./render/precompile";
import { probeGpu } from "./render/gpucaps";
import { Sky } from "./world/sky";
import { TimeOfDay, parsePreset, PRESETS, type Preset } from "./world/timeofday";
import { buildWorld } from "./world/world";
import { TIER } from "./core/tier";
import { Ride } from "./flight/ride";
import { Controls } from "./flight/controls";
import { FlightAudio } from "./flight/audio";
import { PHYS } from "./flight/physics";
import { WIND_LAYERS } from "./flight/wind";
import type { View } from "./flight/cameras";
import { CINE_DURATION } from "./flight/cinematic";

const params = new URLSearchParams(location.search);
const CAPTURE = params.has("capture");
const SEED = Number(params.get("seed") ?? 1) || 1;
const FROZEN_T = params.has("t") ? Number(params.get("t")) : null;

// ------------------------------------------------------------------ renderer

const canvas = document.getElementById("game") as HTMLCanvasElement;
const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: false,
  powerPreference: "high-performance",
  stencil: false,
  preserveDrawingBuffer: CAPTURE,
});
const gl = renderer.getContext() as WebGL2RenderingContext;
if (params.has("gpu")) {
  const dbg = gl.getExtension("WEBGL_debug_renderer_info");
  console.info("[gpu]", dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : "unknown");
}
const caps = probeGpu(gl);
const COLOR_TYPE = caps.halfFloat ? THREE.HalfFloatType : THREE.UnsignedByteType;
const maxSamples = caps.halfFloat ? caps.samplesHalf : caps.samples8;
const samples = (want: number) => (maxSamples > 0 ? Math.min(want, maxSamples) : want);
renderer.setPixelRatio(Math.min(devicePixelRatio, TIER.dpr));
renderer.setSize(innerWidth, innerHeight, false);
renderer.autoClear = true;
renderer.info.autoReset = false;
renderer.outputColorSpace = THREE.SRGBColorSpace;
G.uLeafTex.value = leafAtlas(renderer);
{
  // No signage in this world: a blank 1x1 stands in for the sign atlas the uber shader samples.
  const t = new THREE.DataTexture(new Uint8Array([0, 0, 0, 0]), 1, 1);
  t.needsUpdate = true;
  G.uSignTex.value = t;
}
// Balloon world: haze that still reads from 500 m up, and the low-level wind drifting east.
G.uFogH.value = 220;
G.uWindDir.value.set(1, 0.15).normalize();

// ------------------------------------------------------------------ scene

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(50, innerWidth / innerHeight, 0.5, 16000);
camera.position.set(-260, 120, 340);
camera.lookAt(0, 20, 0);

const sky = new Sky();
scene.add(sky.group, sky.far, sky.motes);

const world = await buildWorld(SEED, () => new Promise((r) => setTimeout(r, 0)), (s, ms) => {
  if (params.has("gpu") || params.has("timing")) console.info(`[world] ${s} ${ms.toFixed(0)} ms`);
});
scene.add(world.group);
specializeUber(scene);

const ride = await Ride.create(camera, canvas, world.groundHeight, SEED);
scene.add(ride.group);
const audio = new FlightAudio();
/** Clock time the cinematic began at (its time is t - cineStart). */
let cineStart = 0;
function toggleCinematic(on = !ride.cine): void {
  if (on) {
    const cine = ride.startCinematic();
    cineStart = t;
    ride.cineT = 0;
    // The reveal (round behind the balloon to the village) must not be wiped by a cloud parked
    // in front of the lens: clouds that would pass close in that stretch sit this flight out.
    ride.clouds.keepOffPath((s, cam) => cine.pose(s, cam), cineStart, 10, 30, 450);
  } else {
    ride.stopCinematic();
    ride.clouds.keepOffPath();
  }
  controls.setButtons(!ride.cine);
}
const controls = new Controls({
  view: () => {
    if (!ride.cine) ride.cams.toggle();
  },
  time: () => {
    const i = PRESETS.indexOf(tod.preset);
    tod.set(PRESETS[(i + 1) % PRESETS.length], false);
  },
  cinematic: () => toggleCinematic(),
  mute: () => audio.toggleMute(),
  first: () => audio.start(),
});

// ------------------------------------------------------------------ light, post, time of day

const shadow = new SunShadow(TIER.shadow * (TIER.shadow >= 2048 ? 2 : 1), 160);
const post = new Post(renderer, innerWidth, innerHeight, {
  kuwahara: params.get("kuwahara") !== "0" && TIER.paint > 0,
  msaa: samples(Number(params.get("msaa") ?? TIER.msaa)),
  res: TIER.res,
  bloom: TIER.bloom,
  fineLines: TIER.fineLines,
  colorType: COLOR_TYPE,
});
if (TIER.singlePass) post.singlePass = true;
if (post.paint && !params.has("paint")) post.paint.strength = TIER.paint;
post.setNear(camera.near);
post.setFar(camera.far);

// The river and the lake share one water level: one half-resolution mirror serves both.
const mirror = new PlanarReflection(Math.round(innerWidth / 2), Math.round(innerHeight / 2), samples(4), COLOR_TYPE);

const startPreset: Preset = parsePreset(params.get("time") ?? params.get("tod")) ?? "golden";
const tod = new TimeOfDay(post, shadow, startPreset);

// ------------------------------------------------------------------ boot

const nextFrame = () =>
  new Promise<void>((res) => {
    const to = setTimeout(res, 120); // hidden tabs never fire rAF
    requestAnimationFrame(() => setTimeout(() => (clearTimeout(to), res()), 0));
  });

let readyResolve!: () => void;
const ready = new Promise<void>((res) => (readyResolve = res));

const parts: THREE.Object3D[] = [sky.group, sky.far, sky.motes, world.group, ride.group];
// One-pass tier: both targets share one blend state, so a painted cloud's own normal-target blend
// (which drives the ink mask negative where it covers) must be the material's blend, or the fields'
// and hedges' ink lines show straight through every cloud. Its colour alpha is never read.
if (TIER.singlePass)
  for (const root of parts)
    root.traverse((o) => {
      const mats = (o as THREE.Mesh).material;
      for (const m of Array.isArray(mats) ? mats : mats ? [mats] : []) {
        const nb = m.userData.normalBlend as Partial<THREE.ShaderMaterial> | undefined;
        if (nb) Object.assign(m, nb);
      }
    });
await precompile(renderer, scene, camera, post, [shadow], parts, () => {}, nextFrame);
post.warmSmaa();

// ------------------------------------------------------------------ loop

const shadowCenter = new THREE.Vector3();
const _fwd = new THREE.Vector3();
let t = FROZEN_T ?? 0;
let paused = FROZEN_T !== null;
/** Set by cinematic.seek(): frames are then drawn only on demand (deterministic recording). */
let manual = false;
let last = performance.now();
let frames = 0;

/** Where the camera's view meets the ground (or a point ahead of it): the shadow map's centre. */
function groundFocus(out: THREE.Vector3): THREE.Vector3 {
  camera.getWorldDirection(_fwd);
  const h = Math.max(camera.position.y, 1);
  const s = _fwd.y < -0.05 ? Math.min(h / -_fwd.y, 600 + h * 1.5) : 120 + h;
  out.copy(camera.position).addScaledVector(_fwd, s);
  return out.setY(world.groundHeight(out.x, out.z));
}

let lastNear = camera.near;
function render(dt: number, gameDt: number): void {
  G.uTime.value = t;
  tod.update(dt);
  if (ride.cine) {
    ride.cineT = t - cineStart;
    // Played live it ends by itself; a recording seeks it and never runs past the end.
    if (!manual && ride.cineT > ride.cine.duration) toggleCinematic(false);
  }
  ride.update(t, gameDt, dt, controls.burning, controls.venting, camera);
  {
    const f = ride.flight;
    audio.update({
      burner: f.burner, vent: f.vent, agl: f.agl, speed: Math.hypot(f.vel.x, f.vel.z), climb: f.vel.y,
      village: Math.hypot(f.pos.x, f.pos.z), night: tod.night, evening: tod.evening,
    });
  }
  if (camera.near !== lastNear) {
    lastNear = camera.near;
    post.setNear(camera.near);
  }
  sky.follow(camera.position);
  world.update(camera, t, dt);
  renderer.info.reset();
  // The shadow map covers more ground the higher the camera is (texels grow with it, as does the view's footprint).
  const hAbove = Math.max(0, camera.position.y - world.groundHeight(camera.position.x, camera.position.z));
  shadow.setHalf(Math.min(900, 160 + hAbove * 1.3));
  shadow.update(renderer, scene, groundFocus(shadowCenter));
  // Ink stays crisp on the near world wherever the camera is: from altitude everything is far.
  const h = Math.max(0, camera.position.y);
  post.setInkFade(40 + h * 0.6, 300 + h * 2.0);
  mirror.update(renderer, scene, camera, 0);
  post.render(scene, camera, t);
}

function frame(now: number): void {
  const dt = Math.min(0.1, (now - last) / 1000);
  last = now;
  if (!manual) {
    if (!paused) t += dt;
    render(dt, paused ? 0 : dt);
    frames++;
  }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

addEventListener("resize", () => {
  renderer.setSize(innerWidth, innerHeight, false);
  post.setSize(innerWidth, innerHeight);
  mirror.setSize(Math.round(innerWidth / 2), Math.round(innerHeight / 2));
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
});

// ------------------------------------------------------------------ script API

const afterFrames = (n: number) =>
  new Promise<void>((res) => {
    const goal = frames + n;
    const check = () => (frames >= goal ? res() : requestAnimationFrame(check));
    requestAnimationFrame(check);
  });

const game = {
  /** Resolves once every program is compiled and a few frames have drawn. */
  ready,
  /** Place the camera at `pos` looking at `target` (world metres, y up). */
  setCamera(pos: [number, number, number], target: [number, number, number]): void {
    ride.cams.setView("free");
    if (camera.near !== ride.cams.baseNear || camera.fov !== ride.cams.baseFov) {
      camera.near = ride.cams.baseNear;
      camera.fov = ride.cams.baseFov;
      camera.updateProjectionMatrix();
    }
    camera.position.set(...pos);
    camera.lookAt(...target);
    camera.updateMatrixWorld();
  },
  /** Switch the time of day (sunrise | golden | sunset | blue); `instant` skips the cross-fade. */
  setTime(name: string, instant = true): boolean {
    const p = parsePreset(name);
    if (!p) return false;
    tod.set(p, instant);
    tod.update(0);
    return true;
  },
  /** Freeze or run the clock (cloud drift, wind sway). */
  pause(on = true): void {
    paused = on;
  },
  /** Set the frozen clock (seconds). */
  setClock(seconds: number): void {
    t = seconds;
  },
  /** Resolves after `n` more frames have rendered. */
  frames: afterFrames,
  presets: PRESETS,
  get time(): Preset {
    return tod.preset;
  },
  stats: () => ({ calls: post.sceneCalls, tris: post.sceneTris, programs: renderer.info.programs?.length ?? 0, scale: post.scale, ...world.info() }),
  /** Ground height (m) under world (x, z): the terrain surface (river / lake beds are below WATER_Y = 0). */
  groundHeight: (x: number, z: number) => world.groundHeight(x, z),
  /** The player's balloon, cameras, clouds (see docs/PROGRESS.md, Phase 3). */
  flight: {
    /** Put the balloon's basket floor at world (x, y, z); level flight, cameras snap. */
    place(x: number, y: number, z: number): void {
      ride.flight.place(x, y, z, t);
      ride.snap();
    },
    /** Turn the balloon (basket heading, degrees). */
    yaw(deg: number): void {
      ride.flight.yaw = (deg * Math.PI) / 180;
      ride.snap();
    },
    /** Put the balloon `m` metres above the ground at its current (or given) x, z. */
    alt(m: number, x = ride.flight.pos.x, z = ride.flight.pos.z): void {
      ride.flight.place(x, Math.max(0, world.groundHeight(x, z)) + m, z, t);
      ride.snap();
    },
    state: () => ({ pos: ride.flight.pos.toArray(), vel: ride.flight.vel.toArray(), heat: ride.flight.heat, lift: ride.flight.lift, agl: ride.flight.agl, grounded: ride.flight.grounded, burner: ride.flight.burner, yaw: ride.flight.yaw, view: ride.cams.view, whiteout: ride.clouds.whiteout }),
    /** Force the burner on/off regardless of input (null = back to the keys). */
    burner(on: boolean | null): void {
      ride.forceBurner = on;
    },
    /** chase | basket | free. */
    view(v: View): void {
      ride.cams.setView(v);
      ride.snap();
    },
    /** Chase orbit (degrees, metres); omitted values keep theirs. */
    chase(yawDeg?: number, pitchDeg?: number, dist?: number): void {
      const c = ride.cams.chase;
      if (yawDeg !== undefined) c.yaw = (yawDeg * Math.PI) / 180;
      if (pitchDeg !== undefined) c.pitch = (pitchDeg * Math.PI) / 180;
      if (dist !== undefined) c.dist = dist;
      ride.snap();
    },
    /** Point the chase camera so the balloon is seen in front of world point (x, z) (degrees pitch). */
    chaseToward(x: number, z: number, pitchDeg?: number, dist?: number): void {
      const p = ride.flight.pos;
      ride.cams.behind(x - p.x, z - p.z);
      if (pitchDeg !== undefined) ride.cams.chase.pitch = (pitchDeg * Math.PI) / 180;
      if (dist !== undefined) ride.cams.chase.dist = dist;
      ride.snap();
    },
    /** Basket look (degrees; yaw 0 = north (-z), pitch negative = down). */
    look(yawDeg: number, pitchDeg: number): void {
      ride.cams.look.yaw = (yawDeg * Math.PI) / 180;
      ride.cams.look.pitch = (pitchDeg * Math.PI) / 180;
      ride.snap();
    },
    /** Basket look toward world point (x, z) at pitch (degrees). */
    lookToward(x: number, z: number, pitchDeg: number): void {
      const p = ride.flight.pos;
      ride.cams.look.yaw = Math.atan2(-(x - p.x), -(z - p.z));
      ride.cams.look.pitch = (pitchDeg * Math.PI) / 180;
      ride.snap();
    },
    /** Nearest cloud of layer i (0 low puffs, 1 mid cumulus) to (x, z) as drawn now. */
    nearestCloud: (i: number, x: number, z: number) => ride.clouds.layers[i].nearest(x, z, camera.position),
    others: () => ride.others.list.map((o) => o.pos.toArray()),
    /** Lay the other balloons out in a fan ahead of the current view, round the player (or x, z). */
    resetOthers(x?: number, z?: number): void {
      ride.resetOthers(camera, x === undefined || z === undefined ? ride.flight.pos : new THREE.Vector3(x, ride.flight.pos.y, z));
    },
    physics: PHYS,
    wind: WIND_LAYERS,
  },
  /** Cinematic mode (C). seek(s) switches to on-demand frames and draws the frame at time s. */
  cinematic: {
    start(): void {
      manual = false;
      toggleCinematic(true);
    },
    stop(): void {
      manual = false;
      toggleCinematic(false);
    },
    get duration(): number {
      return CINE_DURATION;
    },
    get running(): boolean {
      return !!ride.cine;
    },
    /** Draw the cinematic frame at time s (seconds from its start), one fixed 1/60 s step. */
    seek(s: number): void {
      if (!ride.cine) toggleCinematic(true);
      manual = true;
      t = cineStart + s;
      render(1 / 60, 1 / 60);
      frames++;
    },
  },
  /** The pilot (Phase 7): pose(clip, s) freezes her on a clip (idle | lookOver | burner | pull | hold | release); pose(null) resumes. */
  pilot: {
    pose: (clip: string | null, s = 0) => ride.pilot.pose(clip, s),
    clips: () => [...ride.pilot.clips.keys()],
    tris: () => ride.pilot.tris,
  },
  /** Debug access for capture scripts. */
  ride,
  scene,
  camera,
  renderer: () => {
    const dbg = gl.getExtension("WEBGL_debug_renderer_info");
    return dbg ? (gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) as string) : "unknown";
  },
};

declare global {
  interface Window {
    __game: typeof game;
  }
}
window.__game = game;

if (params.get("cinematic") === "1") toggleCinematic(true);
await afterFrames(4);
readyResolve();
