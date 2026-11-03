import * as THREE from "three";
import { buildLevel, type Level } from "./level";
import {
  BODY,
  bodyReaction,
  canSee,
  canSeeBody,
  isBodyHidden,
  stepBodyMeter,
  clamp,
  detectionRate,
  dist2D,
  forceAlert,
  isBehind,
  newBrain,
  noiseRadius,
  raycastBoxes,
  stepBrain,
  stepMeter,
  wrapAngle,
  yawTo,
  type Box,
  type Brain,
  type GuardState,
  type Vec2,
} from "./logic";
import { NavDebug } from "./navDebug";
import { advanceIntro, cameraAt, captionAt, fadeAt, isSkipKey, skipIntro, startIntro, type IntroState } from "./intro";
import type { Checkpoint } from "./save";
import { QUALITY, pixelRatioFor, type Quality } from "./touch";
import { PAD_CONFIRM, PAD_KEYS, PAD_LOOK_RATE, PAD_RUN, PAD_START, diffButtons, pickPad, readPad } from "./gamepad";
import { PathAgent, buildNav, climbDuration, pathLen, sampleClimb, type ClimbLink, type NavGrid } from "./nav";

export type Phase = "title" | "intro" | "playing" | "paused" | "won" | "lost";
export type LoseReason = "caught" | null;

export interface HudState {
  meter: number;
  alert: GuardState | "calm";
  objective: string;
  northDeg: number;
  objDeg: number | null;
  eagle: boolean;
  crouched: boolean;
  hidden: boolean;
  knives: number;
  prompt: string;
  carrying: boolean;
  toast: string;
  caught: number;
}

export interface RunStats {
  /** seconds of play in this attempt (pauses excluded) */
  time: number;
  /** guards that went fully alert */
  alerts: number;
  /** the attempt began at the mission start rather than a later checkpoint */
  fromStart: boolean;
}

export interface GameCallbacks {
  onHud: (h: HudState) => void;
  onPhase: (p: Phase, reason: LoseReason) => void;
  /** a checkpoint was reached: at mission start, or when the Kapitan goes down */
  onCheckpoint?: (cp: Checkpoint) => void;
  /** intro cutscene view (caption, caption opacity, black fade), sent when it visibly changes */
  onIntro?: (v: IntroView) => void;
  /** the intro finished or was skipped; the caller must now call start() or showTitle() */
  onIntroEnd?: (skipped: boolean) => void;
  /** gamepad A or Start pressed on a menu screen (title, paused, won, lost) */
  onPadConfirm?: () => void;
}

export interface IntroView {
  text: string;
  /** 0..1 */
  opacity: number;
  /** black overlay alpha, 0..1 */
  fade: number;
}

const VIS = { range: 16, halfAngle: 0.6 };
const PLAYER_R = 0.4;
const FOG_DUSK = 0xc98259;
const FOG_EAGLE = 0x4a5878;
// dusk fill levels; Mata Helang drops them for contrast
const LIGHT = { hemi: 1.7, ambient: 0.55, sun: 2.4, eagleHemi: 0.85, eagleAmbient: 0.2, eagleSun: 1.5 };
const STEP_H = 0.6;
const CATCH_SECONDS = 2;
const START_KNIVES = 6;
const HEAD_H = 1.75;

interface Guard {
  id: number;
  isTarget: boolean;
  group: THREE.Group;
  body: THREE.Mesh;
  silhouette: THREE.Mesh;
  marker: THREE.Mesh;
  cone: THREE.Mesh;
  coneMat: THREE.MeshBasicMaterial;
  x: number;
  z: number;
  yaw: number;
  brain: Brain;
  meter: number;
  waypoints: Vec2[];
  wp: number;
  wait: number;
  stun: number;
  dead: boolean;
  fall: number;
  y: number;
  vy: number;
  climb: { t: number; dur: number; link: ClimbLink } | null;
  agent: PathAgent;
  investigateY: number;
  lastKnownY: number;
  bodyMeter: number;
  bodyTarget: Guard | null;
  carried: boolean;
  discovered: boolean;
  lastKnown: Vec2 | null;
  investigate: Vec2 | null;
  noiseFlag: boolean;
  seesPlayer: boolean;
}

const STATE_COLOR: Record<GuardState, number> = {
  patrol: 0xffffff,
  suspicious: 0xffd54a,
  alert: 0xff3b30,
  search: 0xff9a3c,
};

function pushOut(pos: { x: number; z: number }, r: number, boxes: Box[], feetY: number) {
  for (let pass = 0; pass < 2; pass++) {
    for (const b of boxes) {
      if (b.maxY <= feetY + STEP_H || b.minY >= feetY + HEAD_H) continue;
      const cx = clamp(pos.x, b.minX, b.maxX);
      const cz = clamp(pos.z, b.minZ, b.maxZ);
      const dx = pos.x - cx;
      const dz = pos.z - cz;
      const d2 = dx * dx + dz * dz;
      if (d2 >= r * r) continue;
      if (d2 > 1e-8) {
        const d = Math.sqrt(d2);
        pos.x += (dx / d) * (r - d);
        pos.z += (dz / d) * (r - d);
      } else {
        const opts = [
          { d: pos.x - b.minX, ax: -1, az: 0 },
          { d: b.maxX - pos.x, ax: 1, az: 0 },
          { d: pos.z - b.minZ, ax: 0, az: -1 },
          { d: b.maxZ - pos.z, ax: 0, az: 1 },
        ].sort((a, c) => a.d - c.d)[0];
        pos.x += opts.ax * (opts.d + r);
        pos.z += opts.az * (opts.d + r);
      }
    }
  }
}

function groundHeight(x: number, z: number, feetY: number, boxes: Box[]) {
  let g = 0;
  for (const b of boxes) {
    if (b.maxY <= feetY + STEP_H && b.maxY > g && x >= b.minX && x <= b.maxX && z >= b.minZ && z <= b.maxZ) g = b.maxY;
  }
  return g;
}

function std(color: number, extra: Partial<THREE.MeshStandardMaterialParameters> = {}) {
  return new THREE.MeshStandardMaterial({ color, roughness: 0.9, flatShading: true, ...extra });
}

function add<T extends THREE.Object3D>(parent: THREE.Object3D, o: T, x = 0, y = 0, z = 0): T {
  o.position.set(x, y, z);
  parent.add(o);
  return o;
}

function shadowMesh(geo: THREE.BufferGeometry, m: THREE.Material) {
  const o = new THREE.Mesh(geo, m);
  o.castShadow = true;
  return o;
}

function makePendekar() {
  const g = new THREE.Group();
  const body = add(g, shadowMesh(new THREE.CylinderGeometry(0.3, 0.42, 1.25, 8), std(0x23284a)), 0, 0.85);
  add(g, shadowMesh(new THREE.CylinderGeometry(0.43, 0.43, 0.14, 8), std(0x9a2b22)), 0, 0.95);
  add(g, shadowMesh(new THREE.SphereGeometry(0.2, 10, 8), std(0xc89a72)), 0, 1.65);
  const tanjak = add(g, shadowMesh(new THREE.ConeGeometry(0.24, 0.32, 6), std(0x7a1f1a)), 0, 1.92);
  tanjak.rotation.z = 0.15;
  add(g, shadowMesh(new THREE.CylinderGeometry(0.035, 0.05, 0.42, 5), std(0xd9a93a)), 0.34, 0.9).rotation.z = 0.5;
  return { group: g, body };
}

function makeGuardFigure(isTarget: boolean) {
  const g = new THREE.Group();
  const coat = isTarget ? 0x3a1f4d : 0x5a1d1d;
  const body = add(g, shadowMesh(new THREE.CylinderGeometry(0.34, 0.42, 1.3, 8), std(coat)), 0, 0.85);
  add(g, shadowMesh(new THREE.CylinderGeometry(0.44, 0.44, 0.12, 8), std(isTarget ? 0xd9a93a : 0x1b1b1b)), 0, 0.95);
  add(g, shadowMesh(new THREE.SphereGeometry(0.2, 10, 8), std(0xe0b898)), 0, 1.68);
  add(g, shadowMesh(new THREE.TorusGeometry(0.2, 0.05, 6, 10), std(0xe8e4d8)), 0, 1.5).rotation.x = Math.PI / 2;
  // steel cap with brim
  add(g, shadowMesh(new THREE.SphereGeometry(0.23, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), std(0x9aa0a6, { metalness: 0.6, roughness: 0.4 })), 0, 1.74);
  add(g, shadowMesh(new THREE.CylinderGeometry(0.34, 0.34, 0.03, 12), std(0x9aa0a6, { metalness: 0.6 })), 0, 1.76);
  if (isTarget) add(g, shadowMesh(new THREE.ConeGeometry(0.06, 0.5, 5), std(0xc0392b)), 0, 2.12);
  // long firearm held across the body
  const gun = add(g, shadowMesh(new THREE.CylinderGeometry(0.035, 0.035, 1.5, 5), std(0x2a2118)), 0.38, 1.1);
  gun.rotation.x = Math.PI / 2;
  gun.rotation.z = 0.1;
  return { group: g, body };
}

function makeConeGeo(range: number, half: number) {
  const pos: number[] = [0, 0, 0];
  const n = 20;
  for (let i = 0; i <= n; i++) {
    const a = -half + (i / n) * half * 2;
    pos.push(Math.sin(a) * range, 0, Math.cos(a) * range);
  }
  const idx: number[] = [];
  for (let i = 1; i <= n; i++) idx.push(0, i, i + 1);
  const geo = new THREE.BufferGeometry();
  geo.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  geo.setIndex(idx);
  return geo;
}

export class Game {
  phase: Phase = "title";
  private renderer: THREE.WebGLRenderer;
  private scene = new THREE.Scene();
  private camera: THREE.PerspectiveCamera;
  private level: Level;
  private nav: NavGrid;
  private navDbg: NavDebug | null = null;
  private sky: THREE.Mesh;
  private player = makePendekar();
  private guards: Guard[] = [];
  private keys = new Set<string>();
  private raf = 0;
  private last = 0;
  private hudTimer = 0;
  private time = 0;

  // player state
  private p = { x: 0, y: 0, z: 0, vy: 0, grounded: true, yaw: 0, moving: false, running: false };
  private crouchToggle = false;
  private camYaw = (3 * Math.PI) / 4;
  private camPitch = 0.35;
  private camPos = new THREE.Vector3();
  private climb: { t: number; dur: number; from: THREE.Vector3; to: THREE.Vector3 } | null = null;
  private eagle = false;
  private knives = START_KNIVES;
  private knifeCd = 0;
  private caught = 0;
  private objective: "kill" | "escape" = "kill";
  private hidden = false;
  private carrying: Guard | null = null;
  private hemi!: THREE.HemisphereLight;
  private ambient!: THREE.AmbientLight;
  private sun!: THREE.DirectionalLight;
  private toastText = "";
  private toastT = 0;
  private lockedOnce = false;
  /** touch mode never takes pointer lock: while it is held, setPointerCapture in the touch controls throws */
  private touch = false;
  private intro: IntroState | null = null;
  private introKey = "";
  private knifeMesh: THREE.Mesh;
  private knifeFly: { t: number; from: THREE.Vector3; to: THREE.Vector3 } | null = null;
  private disposers: (() => void)[] = [];
  private touchMove = { x: 0, y: 0, run: false };
  private padMove = { x: 0, y: 0, run: false };
  private padPrev: boolean[] = [];
  private lookSens = 1;
  private invertY = false;
  private run: RunStats = { time: 0, alerts: 0, fromStart: true };
  readonly quality: Quality;

  constructor(
    private container: HTMLElement,
    private cb: GameCallbacks,
    opts: { quality?: Quality; touch?: boolean } = {},
  ) {
    this.touch = !!opts.touch;
    this.quality = opts.quality ?? "high";
    const Q = QUALITY[this.quality];
    this.renderer = new THREE.WebGLRenderer({ antialias: Q.antialias, powerPreference: "high-performance" });
    this.renderer.setPixelRatio(pixelRatioFor(this.quality, window.devicePixelRatio));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = Q.basicShadows ? THREE.BasicShadowMap : THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.2;
    container.appendChild(this.renderer.domElement);
    this.renderer.domElement.style.display = "block";

    this.camera = new THREE.PerspectiveCamera(62, 1, 0.1, 400);
    this.scene.fog = new THREE.Fog(FOG_DUSK, Q.fogNear, Q.fogFar);

    // sky dome
    this.sky = new THREE.Mesh(
      new THREE.SphereGeometry(300, 24, 12),
      new THREE.ShaderMaterial({
        side: THREE.BackSide,
        depthWrite: false,
        fog: false,
        vertexShader: "varying vec3 vP; void main(){ vP = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }",
        fragmentShader:
          "varying vec3 vP; void main(){ float h = normalize(vP).y; vec3 hor = vec3(0.98,0.56,0.32); vec3 mid = vec3(0.62,0.32,0.4); vec3 top = vec3(0.12,0.12,0.3); vec3 c = mix(hor, mid, smoothstep(0.0,0.22,h)); c = mix(c, top, smoothstep(0.18,0.75,h)); gl_FragColor = vec4(c,1.0); }",
      }),
    );
    this.scene.add(this.sky);

    // lights: warm low sun + cool fill
    this.hemi = new THREE.HemisphereLight(0xffd2a6, 0x6a5878, LIGHT.hemi);
    this.scene.add(this.hemi);
    this.ambient = new THREE.AmbientLight(0x9a86a8, LIGHT.ambient);
    this.scene.add(this.ambient);
    const sun = new THREE.DirectionalLight(0xffa860, LIGHT.sun);
    this.sun = sun;
    sun.position.set(-40, 24, 30);
    sun.castShadow = true;
    sun.shadow.mapSize.set(Q.shadowMapSize, Q.shadowMapSize);
    const sc = sun.shadow.camera;
    sc.left = -48;
    sc.right = 48;
    sc.top = 48;
    sc.bottom = -48;
    sc.near = 1;
    sc.far = 140;
    sun.shadow.bias = -0.0006;
    this.scene.add(sun);
    const sunDisc = new THREE.Mesh(new THREE.SphereGeometry(9, 16, 12), new THREE.MeshBasicMaterial({ color: 0xffd9a0, fog: false }));
    sunDisc.position.set(-180, 26, 140);
    this.scene.add(sunDisc);

    this.level = buildLevel({ lampLights: Q.lampLights });
    this.nav = buildNav(this.level.colliders, this.level.bounds);
    this.scene.add(this.level.root);
    this.scene.add(this.player.group);

    this.knifeMesh = new THREE.Mesh(new THREE.ConeGeometry(0.05, 0.4, 5), new THREE.MeshBasicMaterial({ color: 0xe6e6e6 }));
    this.knifeMesh.visible = false;
    this.scene.add(this.knifeMesh);
    // dev-only nav overlay (F3); never built in production
    if (process.env.NODE_ENV !== "production") {
      this.navDbg = new NavDebug(this.nav);
      this.scene.add(this.navDbg.group);
    }

    this.level.guards.forEach((def, i) => this.guards.push(this.makeGuard(def.waypoints, !!def.isTarget, i)));

    this.resetWorld();
    this.bindEvents();
    this.onResize();
    this.last = performance.now();
    this.raf = requestAnimationFrame(this.frame);
  }

  // ------------------------------------------------------------------ setup

  private makeGuard(waypoints: Vec2[], isTarget: boolean, id: number): Guard {
    const fig = makeGuardFigure(isTarget);
    const silhouette = new THREE.Mesh(
      new THREE.CapsuleGeometry(0.45, 1.1, 4, 8),
      new THREE.MeshBasicMaterial({
        color: isTarget ? 0xffd24a : 0xff5a4a,
        transparent: true,
        opacity: 0.85,
        depthFunc: THREE.GreaterDepth,
        depthWrite: false,
      }),
    );
    silhouette.position.y = 1.0;
    silhouette.visible = false;
    silhouette.renderOrder = 5;
    fig.group.add(silhouette);

    const marker = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.2),
      new THREE.MeshBasicMaterial({ color: 0xffffff, depthTest: false, transparent: true }),
    );
    marker.position.y = 2.7;
    marker.renderOrder = 999;
    marker.visible = false;
    fig.group.add(marker);

    const coneMat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.2, side: THREE.DoubleSide, depthWrite: false });
    const cone = new THREE.Mesh(makeConeGeo(VIS.range, VIS.halfAngle), coneMat);
    cone.position.y = 0.06;
    cone.visible = false;
    fig.group.add(cone);

    if (isTarget) {
      const beam = new THREE.Mesh(
        new THREE.CylinderGeometry(0.12, 0.12, 40, 8, 1, true),
        new THREE.MeshBasicMaterial({ color: 0xffd24a, transparent: true, opacity: 0.18, depthWrite: false }),
      );
      beam.position.y = 20;
      fig.group.add(beam);
      beam.name = "beam";
    }

    this.scene.add(fig.group);
    return {
      id,
      isTarget,
      group: fig.group,
      body: fig.body,
      silhouette,
      marker,
      cone,
      coneMat,
      x: waypoints[0].x,
      z: waypoints[0].z,
      yaw: 0,
      brain: newBrain(),
      meter: 0,
      waypoints,
      wp: 1 % waypoints.length,
      wait: 0,
      stun: 0,
      dead: false,
      fall: 0,
      y: 0,
      vy: 0,
      climb: null,
      lastKnownY: 0,
      bodyMeter: 0,
      bodyTarget: null,
      carried: false,
      discovered: false,
      lastKnown: null,
      investigate: null,
      investigateY: 0,
      agent: new PathAgent(this.nav),
      noiseFlag: false,
      seesPlayer: false,
    };
  }

  private resetWorld() {
    const s = this.level.start;
    this.p = { x: s.x, y: 0, z: s.z, vy: 0, grounded: true, yaw: (3 * Math.PI) / 4, moving: false, running: false };
    this.camYaw = (3 * Math.PI) / 4;
    this.camPitch = 0.35;
    this.climb = null;
    this.eagle = false;
    this.knives = START_KNIVES;
    this.knifeCd = 0;
    this.caught = 0;
    this.objective = "kill";
    this.hidden = false;
    this.carrying = null;
    this.crouchToggle = false;
    this.toastText = "";
    (this.level.exitBeam.material as THREE.MeshBasicMaterial).opacity = 0;
    for (const g of this.guards) {
      g.x = g.waypoints[0].x;
      g.z = g.waypoints[0].z;
      g.wp = 1 % g.waypoints.length;
      g.yaw = yawTo(g, g.waypoints[g.wp]);
      g.brain = newBrain();
      g.meter = 0;
      g.stun = 0;
      g.dead = false;
      g.fall = 0;
      g.wait = 0;
      g.lastKnown = null;
      g.lastKnownY = 0;
      g.investigateY = 0;
      g.agent.reset();
      g.y = 0;
      g.vy = 0;
      g.climb = null;
      g.bodyMeter = 0;
      g.bodyTarget = null;
      g.carried = false;
      g.discovered = false;
      g.investigate = null;
      g.noiseFlag = false;
      g.group.rotation.x = 0;
      g.group.visible = true;
    }
    this.syncMeshes();
  }

  private bindEvents() {
    const el = this.renderer.domElement;
    const on = <K extends keyof WindowEventMap>(t: K, fn: (e: WindowEventMap[K]) => void, target: Window = window) => {
      target.addEventListener(t, fn as EventListener);
      this.disposers.push(() => target.removeEventListener(t, fn as EventListener));
    };
    on("resize", () => this.onResize());
    on("keydown", (e) => {
      if (e.code === "F3" && this.navDbg) {
        e.preventDefault();
        this.navDbg.toggle();
        return;
      }
      if (this.phase === "intro") {
        if (isSkipKey(e.code)) {
          e.preventDefault();
          this.skipIntro();
        }
        return;
      }
      if (this.phase !== "playing") return;
      if (["Space", "ArrowUp", "ArrowDown", "Tab"].includes(e.code)) e.preventDefault();
      if (e.repeat) return;
      this.pressKey(e.code);
    });
    on("keyup", (e) => this.keys.delete(e.code));
    // mouse look needs the pointer captured; after an intro that ended on its own there was no click to do it
    el.addEventListener("click", () => {
      if (this.phase === "playing" && document.pointerLockElement !== el) this.lock();
    });
    on("blur", () => this.keys.clear());
    on("mousemove", (e) => {
      if (this.phase === "playing" && document.pointerLockElement === el) this.look(e.movementX, e.movementY);
    });
    const lockChange = () => {
      if (document.pointerLockElement === el) this.lockedOnce = true;
      else if (this.lockedOnce && this.phase === "playing") this.pause();
    };
    document.addEventListener("pointerlockchange", lockChange);
    this.disposers.push(() => document.removeEventListener("pointerlockchange", lockChange));
    const vis = () => {
      if (document.hidden && this.phase === "playing") this.pause();
    };
    document.addEventListener("visibilitychange", vis);
    this.disposers.push(() => document.removeEventListener("visibilitychange", vis));
  }

  private onResize() {
    const w = this.container.clientWidth || window.innerWidth;
    const h = this.container.clientHeight || window.innerHeight;
    this.renderer.setSize(w, h);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  // ------------------------------------------------------------------ public API

  /** Play the intro cutscene. The caller reacts to onIntroEnd with start() or showTitle(). */
  playIntro(reduced = false) {
    this.resetWorld();
    this.intro = startIntro(reduced);
    this.introKey = "";
    this.setPhase("intro");
    this.stepIntro(0);
  }
  /** Skip (or finish) the intro now. Safe to call at any time and more than once. */
  skipIntro() {
    if (this.phase !== "intro" || !this.intro) return;
    this.intro = skipIntro(this.intro);
    this.finishIntro();
  }
  /** Back to the title screen (after a replayed intro). */
  showTitle() {
    this.intro = null;
    this.resetWorld();
    this.setPhase("title");
  }
  /** Test hook: jump the cutscene to time t. */
  debugIntroSeek(t: number) {
    if (this.phase === "intro" && this.intro) this.intro = { ...this.intro, t };
  }
  private finishIntro() {
    const s = this.intro;
    if (!s || !s.done) return;
    this.intro = null;
    this.cb.onIntroEnd?.(s.skipped);
  }
  private stepIntro(dt: number) {
    if (!this.intro) return;
    this.intro = advanceIntro(this.intro, dt);
    const { t, reduced } = this.intro;
    const c = cameraAt(t, reduced);
    this.camera.position.set(...c.pos);
    this.camera.lookAt(...c.look);
    const cap = captionAt(t, reduced);
    const view: IntroView = { text: cap?.text ?? "", opacity: cap ? cap.opacity : 0, fade: fadeAt(t, reduced) };
    const key = `${view.text}|${view.opacity.toFixed(2)}|${view.fade.toFixed(2)}`;
    if (key !== this.introKey) {
      this.introKey = key;
      this.cb.onIntro?.(view);
    }
    if (this.intro.done) this.finishIntro();
  }

  /** Begin the mission, from the beginning or from the "Kapitan down" checkpoint. Guard and alert state is never restored. */
  start(from: Checkpoint = "start") {
    this.resetWorld();
    this.run = { time: 0, alerts: 0, fromStart: from === "start" };
    if (from === "kapitan") this.applyKapitanCheckpoint();
    this.cb.onCheckpoint?.(from);
    this.setPhase("playing");
    this.lock();
  }
  private applyKapitanCheckpoint() {
    const t = this.guards.find((g) => g.isTarget);
    if (!t) return;
    t.dead = true;
    this.p.x = t.x;
    this.p.z = t.z;
    this.objective = "escape";
    (this.level.exitBeam.material as THREE.MeshBasicMaterial).opacity = 0.35;
    this.syncMeshes();
  }
  /** Play stats for the current attempt (read when it ends). */
  stats(): RunStats {
    return { ...this.run };
  }
  /** Mouse and touch look settings: sensitivity multiplier and inverted vertical look. */
  setLookSettings(sens: number, invertY: boolean) {
    this.lookSens = Number.isFinite(sens) && sens > 0 ? sens : 1;
    this.invertY = invertY;
  }
  resume() {
    if (this.phase === "paused") {
      this.setPhase("playing");
      this.lock();
    }
  }
  pause() {
    if (this.phase === "playing") {
      this.keys.clear();
      this.setTouchMove(0, 0, false);
      this.setPhase("paused");
    }
  }
  private lock() {
    if (this.touch) return;
    try {
      const r = this.renderer.domElement.requestPointerLock() as unknown as Promise<void> | undefined;
      r?.catch?.(() => {});
    } catch {
      /* pointer lock unavailable (e.g. headless); keyboard still works */
    }
  }
  /** Key press as the keyboard handler sees it. Touch buttons call this with the same codes (KeyE, KeyQ, KeyF, KeyV, KeyC, Space). */
  pressKey(code: string) {
    if (this.phase !== "playing") return;
    this.keys.add(code);
    if (code === "KeyE") this.tryTakedown();
    if (code === "KeyQ") this.tryThrow();
    if (code === "KeyF") this.tryCarry();
    if (code === "KeyV") this.eagle = !this.eagle;
    if (code === "KeyC") this.crouchToggle = !this.crouchToggle;
    if (code === "Space") this.tryJumpOrClimb();
  }
  releaseKey(code: string) {
    this.keys.delete(code);
  }
  /** Analog movement from the touch joystick: x strafe, y forward, both -1..1 already deadzoned. */
  setTouchMove(x: number, y: number, run: boolean) {
    this.touchMove.x = x;
    this.touchMove.y = y;
    this.touchMove.run = run;
  }
  look(dx: number, dy: number) {
    const k = 0.0022 * this.lookSens;
    this.camYaw -= dx * k;
    this.camPitch = clamp(this.camPitch + dy * k * (this.invertY ? -1 : 1), -0.25, 1.2);
  }
  /** Small read-only snapshot used by the automated browser check. */
  debug() {
    return {
      phase: this.phase,
      introT: this.intro?.t ?? null,
      player: { x: this.p.x, y: this.p.y, z: this.p.z },
      guards: this.guards.map((g) => ({ x: g.x, y: g.y, z: g.z, climbing: !!g.climb, state: g.brain.state, dead: g.dead, target: g.isTarget })),
      objective: this.objective,
      exit: { x: this.level.exit.x, z: this.level.exit.z },
      drawCalls: this.renderer.info.render.calls,
      quality: this.quality,
      camYaw: this.camYaw,
      camPitch: this.camPitch,
      crouched: this.crouched,
      eagle: this.eagle,
      knives: this.knives,
      pixelRatio: this.renderer.getPixelRatio(),
    };
  }
  /** Test hook: a rooftop spot a guard can path to by climbing (used by the automated browser check). */
  debugRoofSpot(): { x: number; y: number; z: number } | null {
    const g0 = this.guards[0];
    let best: { x: number; y: number; z: number } | null = null;
    let bestLen = 0;
    for (let l = 1; l < this.nav.layers; l++)
      for (let iz = 0; iz < this.nav.h; iz += 6)
        for (let ix = 0; ix < this.nav.w; ix += 6) {
          if (!this.nav.isWalkable(l, ix, iz)) continue;
          const goal = { x: this.nav.cx(ix), y: this.nav.heights[l], z: this.nav.cz(iz) };
          const path = this.nav.findPath({ x: g0.x, y: 0, z: g0.z }, goal);
          if (!path?.found || !path.points.some((q) => q.via)) continue;
          const len = pathLen(path.points);
          if (len > bestLen && len < 60) {
            bestLen = len;
            best = goal;
          }
        }
    return best;
  }
  /** Test hook: put the player at a spot and alert every guard to it. */
  debugAlertAt(x: number, y: number, z: number) {
    this.p.x = x;
    this.p.y = y;
    this.p.z = z;
    this.p.vy = 0;
    for (const g of this.guards) {
      if (g.dead) continue;
      g.brain = forceAlert();
      g.meter = 1;
      g.lastKnown = { x, z };
      g.lastKnownY = y;
    }
  }
  dispose() {
    cancelAnimationFrame(this.raf);
    this.disposers.forEach((d) => d());
    this.renderer.dispose();
    this.renderer.domElement.remove();
  }
  private setPhase(p: Phase, reason: LoseReason = null) {
    this.phase = p;
    if (p !== "playing" && document.pointerLockElement) document.exitPointerLock();
    this.cb.onPhase(p, reason);
  }
  private toast(t: string) {
    this.toastText = t;
    this.toastT = 2.2;
  }

  // ------------------------------------------------------------------ loop

  private frame = (now: number) => {
    this.raf = requestAnimationFrame(this.frame);
    const dt = Math.min(0.05, (now - this.last) / 1000);
    this.last = now;
    this.time += dt;
    this.pollPad(dt);
    if (this.phase === "playing") this.update(dt);
    if (this.phase === "title") this.attractCamera();
    if (this.phase === "intro") this.stepIntro(dt);
    this.render(dt);
  };

  /** Gamepad buttons act as their key codes; sticks move and look. Polled each frame (the Gamepad API has no input events). */
  private pollPad(dt: number) {
    const pad = typeof navigator !== "undefined" && navigator.getGamepads ? pickPad([...navigator.getGamepads()]) : null;
    const s = pad ? readPad(pad) : null;
    const { down, up } = diffButtons(this.padPrev, s?.buttons ?? []);
    this.padPrev = s?.buttons ?? [];
    for (const i of up) if (PAD_KEYS[i]) this.releaseKey(PAD_KEYS[i]);
    this.padMove = { x: 0, y: 0, run: false };
    if (!s) return;
    const pressed = (i: number) => down.includes(i);
    if (this.phase === "intro") {
      if (pressed(PAD_CONFIRM) || pressed(PAD_START)) this.skipIntro();
      return;
    }
    if (this.phase !== "playing") {
      if (pressed(PAD_CONFIRM) || pressed(PAD_START)) this.cb.onPadConfirm?.();
      return;
    }
    if (pressed(PAD_START)) {
      this.pause();
      return;
    }
    for (const i of down) if (PAD_KEYS[i]) this.pressKey(PAD_KEYS[i]);
    this.padMove = { ...s.move, run: PAD_RUN.some((i) => s.buttons[i]) };
    if (s.look.x || s.look.y) this.look(s.look.x * PAD_LOOK_RATE * dt, s.look.y * PAD_LOOK_RATE * dt);
  }

  private attractCamera() {
    const a = this.time * 0.08;
    this.camera.position.set(Math.sin(a) * 34, 15, Math.cos(a) * 34);
    this.camera.lookAt(0, 3, 0);
  }

  private get crouched() {
    return this.keys.has("ControlLeft") || this.keys.has("ControlRight") || this.crouchToggle;
  }

  private update(dt: number) {
    this.run.time += dt;
    this.toastT = Math.max(0, this.toastT - dt);
    this.knifeCd = Math.max(0, this.knifeCd - dt);
    const L = this.level;
    const p = this.p;

    // ---- player movement
    let fwd = (this.keys.has("KeyW") ? 1 : 0) - (this.keys.has("KeyS") ? 1 : 0);
    let str = (this.keys.has("KeyD") ? 1 : 0) - (this.keys.has("KeyA") ? 1 : 0);
    let len = Math.hypot(fwd, str);
    // keyboard wins, then the touch joystick, then the gamepad stick
    const tm = this.touchMove.x !== 0 || this.touchMove.y !== 0 ? this.touchMove : this.padMove;
    const touchActive = len === 0 && (tm.x !== 0 || tm.y !== 0);
    if (touchActive) {
      fwd = tm.y;
      str = tm.x;
      len = Math.hypot(fwd, str); // normalised below: direction only, gait is walk or run like the keyboard
    }
    if (len > 0) {
      fwd /= len;
      str /= len;
    }
    const crouched = this.crouched;
    p.running = (this.keys.has("ShiftLeft") || this.keys.has("ShiftRight") || (touchActive && tm.run)) && !crouched && !this.carrying && len > 0;

    if (this.climb) {
      const c = this.climb;
      c.t += dt;
      const k = clamp(c.t / c.dur, 0, 1);
      const e = k * k * (3 - 2 * k);
      p.x = c.from.x + (c.to.x - c.from.x) * e;
      p.z = c.from.z + (c.to.z - c.from.z) * e;
      // rise first, then pull forward
      const rise = clamp(k * 1.6, 0, 1);
      p.y = c.from.y + (c.to.y - c.from.y) * rise;
      if (k >= 1) {
        this.climb = null;
        p.vy = 0;
        p.grounded = true;
      }
      p.moving = false;
    } else {
      const speed = this.carrying ? 2.2 : crouched ? 1.7 : p.running ? 6.2 : 3.4;
      const fx = Math.sin(this.camYaw);
      const fz = Math.cos(this.camYaw);
      const rx = -Math.cos(this.camYaw);
      const rz = Math.sin(this.camYaw);
      const mx = fx * fwd + rx * str;
      const mz = fz * fwd + rz * str;
      p.moving = len > 0;
      if (p.moving) {
        const target = Math.atan2(mx, mz);
        p.yaw += clamp(wrapAngle(target - p.yaw), -12 * dt, 12 * dt);
        p.x += mx * speed * dt;
        p.z += mz * speed * dt;
      }
      pushOut(p, PLAYER_R, L.colliders, p.y);
      this.applyBounds();

      // vertical
      p.vy -= 20 * dt;
      p.y += p.vy * dt;
      const g = groundHeight(p.x, p.z, p.y, L.colliders);
      if (p.y <= g) {
        p.y = g;
        p.vy = 0;
        p.grounded = true;
      } else if (p.y > g + 0.05) p.grounded = false;

      // holding Space against a wall climbs it
      if (this.keys.has("Space") && p.moving) this.tryClimb();
    }

    // ---- hiding
    this.hidden = L.hides.some((h) => p.y < 1 && dist2D(p, h) < h.r);

    // ---- noise
    const stance = { crouched, running: p.running };
    const nr = this.hidden ? 0 : noiseRadius(stance, p.moving && p.grounded);
    if (nr > 0) for (const g of this.guards) if (!g.dead && dist2D(g, p) < nr * (Math.abs(g.y - p.y) > 2 ? 0.5 : 1)) this.hear(g, p);

    // ---- guards
    for (const g of this.guards) this.updateGuard(g, dt, stance);

    // ---- caught
    const grabbing = this.guards.some((g) => !g.dead && g.stun <= 0 && g.brain.state === "alert" && dist2D(g, p) < 2.3 && Math.abs(p.y - g.y) < 2.2);
    this.caught = clamp(this.caught + (grabbing ? dt : -dt * 0.6), 0, CATCH_SECONDS);
    if (this.caught >= CATCH_SECONDS) {
      this.setPhase("lost", "caught");
      return;
    }

    // ---- escape
    if (this.objective === "escape" && dist2D(p, L.exit) < 2.4) {
      this.setPhase("won");
      return;
    }

    this.hudTimer -= dt;
    if (this.hudTimer <= 0) {
      this.hudTimer = 0.08;
      this.cb.onHud(this.buildHud());
    }
  }

  private applyBounds() {
    const b = this.level.bounds;
    const p = this.p;
    p.x = clamp(p.x, b.minX, b.maxX);
    p.z = clamp(p.z, b.minZ, b.maxZ);
    if (p.z < b.jettyZ) p.x = clamp(p.x, -b.jettyHalf, b.jettyHalf);
  }

  private tryJumpOrClimb() {
    if (this.climb) return;
    if (this.tryClimb()) return;
    if (this.p.grounded) {
      this.p.vy = 7.2;
      this.p.grounded = false;
    }
  }

  /** Vault / climb onto a ledge in front of the player (up to ~3.7 m). */
  private tryClimb(): boolean {
    if (this.climb) return false;
    const p = this.p;
    const dx = Math.sin(p.yaw);
    const dz = Math.cos(p.yaw);
    let best: Box | null = null;
    for (const reach of [0.5, 0.85]) {
      const px = p.x + dx * (PLAYER_R + reach);
      const pz = p.z + dz * (PLAYER_R + reach);
      for (const b of this.level.colliders) {
        if (b.maxY <= p.y + STEP_H || b.maxY > p.y + 3.7) continue;
        // standing under a raised floor: do not climb up through it
        if (b.minY > p.y && p.x >= b.minX && p.x <= b.maxX && p.z >= b.minZ && p.z <= b.maxZ) continue;
        if (px < b.minX - 0.05 || px > b.maxX + 0.05 || pz < b.minZ - 0.05 || pz > b.maxZ + 0.05) continue;
        if (!best || b.maxY < best.maxY) best = b;
      }
      if (best) break;
    }
    if (!best) return false;
    const tx = clamp(p.x + dx * (PLAYER_R + 0.95), best.minX + 0.5, best.maxX - 0.5);
    const tz = clamp(p.z + dz * (PLAYER_R + 0.95), best.minZ + 0.5, best.maxZ - 0.5);
    const h = best.maxY - p.y;
    this.climb = {
      t: 0,
      dur: 0.35 + h * 0.13,
      from: new THREE.Vector3(p.x, p.y, p.z),
      to: new THREE.Vector3(tx, best.maxY, tz),
    };
    p.vy = 0;
    return true;
  }

  // ------------------------------------------------------------------ guards

  private hear(g: Guard, src: Vec2 & { y?: number }) {
    if (g.brain.state === "alert") return;
    g.noiseFlag = true;
    g.investigate = { x: src.x, z: src.z };
    g.investigateY = src.y ?? 0;
  }

  private updateGuard(g: Guard, dt: number, stance: { crouched: boolean; running: boolean }) {
    if (g.dead) {
      g.fall = Math.min(1, g.fall + dt * 3);
      if (g.carried) {
        g.x = this.p.x;
        g.z = this.p.z;
        g.y = this.p.y + 0.9;
      }
      return;
    }
    const p = this.p;
    const L = this.level;

    // gravity: guards that walk off a roof drop to the ground
    if (!g.climb) {
      const gh = groundHeight(g.x, g.z, g.y, L.colliders);
      if (g.y > gh + 0.01) {
        g.vy -= 20 * dt;
        g.y = Math.max(gh, g.y + g.vy * dt);
      } else {
        if (g.vy < -3) g.agent.reset(); // dropped off a roof: the old path is on the wrong layer
        g.y = gh;
        g.vy = 0;
      }
    }

    if (g.stun > 0) {
      g.stun -= dt;
      g.meter = Math.max(0, g.meter - dt * 0.3);
      if (g.stun <= 0) {
        g.brain = { state: "suspicious", timer: 0 };
        g.investigate = { x: p.x, z: p.z };
        g.investigateY = p.y;
      }
      return;
    }

    // ---- senses
    const alertNow = g.brain.state === "alert";
    const eye = { x: g.x, y: g.y + 1.7, z: g.z };
    const chest = { x: p.x, y: p.y + (stance.crouched ? 0.6 : 1.1), z: p.z };
    const seen = canSee(eye, g.yaw, chest, VIS, L.occluders, this.hidden);
    g.seesPlayer = seen;
    if (seen) {
      g.lastKnown = { x: p.x, z: p.z };
      g.lastKnownY = p.y;
      g.meter = alertNow ? 1 : stepMeter(g.meter, true, detectionRate(dist2D(g, p), VIS.range, stance), dt);
    } else {
      g.meter = stepMeter(g.meter, false, 0, dt, alertNow || g.brain.state === "search" ? 0.1 : 0.25);
    }

    // ---- bodies: a guard whose cone catches a downed guard investigates, then raises the alarm
    const prev = g.brain.state;
    const found = alertNow ? false : this.noticeBodies(g, eye, dt);

    // ---- brain
    g.brain = stepBrain(g.brain, { meter: g.meter, seesPlayer: seen, heardNoise: g.noiseFlag }, dt);
    const noisePoint = g.noiseFlag ? g.investigate : null;
    g.noiseFlag = false;
    const now = g.brain.state;
    if (now !== prev) {
      if (now === "alert") {
        this.run.alerts++;
        g.meter = 1;
        if (!g.lastKnown) {
          g.lastKnown = { x: p.x, z: p.z };
          g.lastKnownY = p.y;
        }
        this.toast(found ? "A body was found!" : g.isTarget ? "The Kapitan has seen you!" : "Spotted!");
        for (const o of this.guards) {
          if (o !== g && !o.dead && o.stun <= 0 && o.brain.state !== "alert" && dist2D(o, g) < 14) {
            o.brain = forceAlert();
            o.meter = 1;
            o.lastKnown = g.lastKnown;
            o.lastKnownY = g.lastKnownY;
          }
        }
      } else if (now === "patrol") {
        g.meter = 0;
        g.investigate = null;
        let bi = 0;
        let bd = Infinity;
        g.waypoints.forEach((w, i) => {
          const d = dist2D(g, w);
          if (d < bd) {
            bd = d;
            bi = i;
          }
        });
        g.wp = bi;
      } else if (now === "suspicious") {
        g.investigate = noisePoint ?? g.lastKnown ?? g.investigate;
        if (!noisePoint && g.lastKnown) g.investigateY = g.lastKnownY;
      }
    }

    // ---- movement per state
    if (g.climb) {
      this.advanceClimb(g, dt);
      return;
    }
    switch (g.brain.state) {
      case "patrol": {
        const w = g.waypoints[g.wp];
        if (g.wait > 0) {
          g.wait -= dt;
          g.yaw += Math.sin(this.time * 1.3 + g.id) * dt * 0.8;
        } else if (this.navMove(g, w, 0, 1.7, dt, 4) < 0.5) {
          g.wp = (g.wp + 1) % g.waypoints.length;
          g.wait = 1.2;
        }
        break;
      }
      case "suspicious": {
        if (seen) this.turnToward(g, yawTo(g, p), 6, dt);
        else {
          const pt = g.investigate ?? g.lastKnown;
          if (pt && dist2D(g, pt) > 2) this.navMove(g, pt, g.investigate ? g.investigateY : g.lastKnownY, 1.3, dt, 5);
          else g.yaw += Math.sin(this.time * 2 + g.id) * dt * 1.5;
        }
        break;
      }
      case "alert": {
        const pt = g.lastKnown ?? { x: p.x, z: p.z };
        const ptY = g.lastKnown ? g.lastKnownY : p.y;
        if (dist2D(g, pt) > 1.0 || ptY > g.y + 0.6) this.chase(g, pt, ptY, 4.0, dt, 9);
        else this.turnToward(g, yawTo(g, p), 9, dt);
        break;
      }
      case "search": {
        const pt = g.lastKnown;
        if (pt && (dist2D(g, pt) > 1.2 || g.lastKnownY > g.y + 0.6)) this.chase(g, pt, g.lastKnownY, 2.4, dt, 6);
        else g.yaw += 1.4 * dt;
        break;
      }
    }
  }

  /** Pursue a point (possibly on a roof) along the nav graph, climbing links where the path says so. */
  private chase(g: Guard, pt: Vec2, ptY: number, speed: number, dt: number, turn: number) {
    return this.navMove(g, pt, ptY, speed, dt, turn);
  }

  /**
   * Walk toward a world point using A* over the nav grid. Falls back to straight-line
   * movement if navigation has nothing to offer. Returns the remaining distance.
   */
  private navMove(g: Guard, pt: Vec2, ptY: number, speed: number, dt: number, turn: number): number {
    const cmd = g.agent.update({ x: g.x, y: g.y, z: g.z }, { x: pt.x, y: ptY, z: pt.z }, dt);
    const d = dist2D(g, pt);
    switch (cmd.kind) {
      case "walk":
        this.moveToward(g, cmd.to, speed, dt, turn);
        return d;
      case "climb":
        g.climb = { t: 0, dur: climbDuration(cmd.link.keys), link: cmd.link };
        g.vy = 0;
        if (cmd.link.up) g.yaw = cmd.link.faceYaw;
        return d;
      case "wait":
        return d;
      case "arrived":
        return Math.min(d, 0.4);
      case "fallback":
        return this.moveToward(g, pt, speed, dt, turn);
    }
  }

  private advanceClimb(g: Guard, dt: number) {
    const c = g.climb;
    if (!c) return;
    c.t += dt;
    const q = sampleClimb(c.link.keys, c.t);
    g.x = q.x;
    g.y = q.y;
    g.z = q.z;
    if (c.t >= c.dur) {
      g.climb = null;
      g.agent.finishClimb();
    }
  }

  /** Look for undiscovered bodies in the cone. Returns true on the frame the guard discovers one. */
  private noticeBodies(g: Guard, eye: { x: number; y: number; z: number }, dt: number): boolean {
    let seen: Guard | null = null;
    let sd = Infinity;
    for (const b of this.guards) {
      if (!b.dead || b.carried || b.discovered) continue;
      const hidden = isBodyHidden(b, this.level.hides);
      if (!canSeeBody(eye, g.yaw, b, VIS, this.level.occluders, hidden, b.y)) continue;
      const d = dist2D(g, b);
      if (d < sd) {
        sd = d;
        seen = b;
      }
    }
    if (seen) g.bodyTarget = seen;
    g.bodyMeter = stepBodyMeter(g.bodyMeter, !!seen, seen ? sd : BODY.range, dt);
    const t = g.bodyTarget;
    if (!t || t.discovered || !t.dead) return false;
    const r = bodyReaction(g.bodyMeter);
    if (r === "discovered") {
      t.discovered = true;
      g.bodyMeter = 0;
      g.bodyTarget = null;
      g.brain = forceAlert();
      g.lastKnown = { x: t.x, z: t.z };
      g.lastKnownY = t.y;
      return true;
    }
    if (r === "suspicious") {
      g.noiseFlag = true;
      g.investigate = { x: t.x, z: t.z };
      g.investigateY = t.y;
    }
    return false;
  }

  private turnToward(g: Guard, target: number, rate: number, dt: number) {
    g.yaw += clamp(wrapAngle(target - g.yaw), -rate * dt, rate * dt);
  }

  /** Turn then walk toward `pt`; returns the remaining distance. */
  private moveToward(g: Guard, pt: Vec2, speed: number, dt: number, turnRate: number) {
    const want = yawTo(g, pt);
    this.turnToward(g, want, turnRate, dt);
    const d = dist2D(g, pt);
    if (Math.abs(wrapAngle(want - g.yaw)) < 0.9) {
      const step = Math.min(speed * dt, d);
      g.x += Math.sin(g.yaw) * step;
      g.z += Math.cos(g.yaw) * step;
      pushOut(g, 0.45, this.level.colliders, g.y);
    }
    return d;
  }

  // ------------------------------------------------------------------ actions

  private takedownTarget(): { guard: Guard | null; near: boolean } {
    const p = this.p;
    let best: Guard | null = null;
    let near = false;
    for (const g of this.guards) {
      if (g.dead) continue;
      const d = dist2D(g, p);
      if (d > 2.0 || Math.abs(p.y - g.y) > 1.8) continue;
      near = true;
      const ok = g.stun > 0 || (g.brain.state !== "alert" && isBehind(g, g.yaw, p));
      if (ok && (!best || d < dist2D(best, p))) best = g;
    }
    return { guard: best, near };
  }

  private tryTakedown() {
    if (this.climb || this.carrying) return;
    const { guard } = this.takedownTarget();
    if (!guard) return;
    guard.dead = true;
    guard.meter = 0;
    guard.climb = null;
    guard.agent.reset();
    // a takedown made from inside a haystack or bush drags the body into the cover
    const cover = this.level.hides.find((h) => this.hidden && dist2D(this.p, h) < h.r);
    if (cover) {
      guard.x = cover.x + (guard.x - cover.x) * 0.2;
      guard.z = cover.z + (guard.z - cover.z) * 0.2;
    }
    this.p.yaw = yawTo(this.p, guard);
    for (const o of this.guards) if (!o.dead && o !== guard && dist2D(o, guard) < 5) this.hear(o, guard);
    if (guard.isTarget) {
      this.objective = "escape";
      (this.level.exitBeam.material as THREE.MeshBasicMaterial).opacity = 0.35;
      this.toast("The Kapitan is down. Reach the jetty.");
      this.cb.onCheckpoint?.("kapitan");
    } else this.toast(cover ? "Silent kill. Body hidden in cover." : "Silent kill.");
  }

  /** F: pick up the nearest body, or drop the one being carried (hidden if dropped inside cover). */
  private tryCarry() {
    if (this.climb) return;
    const p = this.p;
    if (this.carrying) {
      const b = this.carrying;
      this.carrying = null;
      b.carried = false;
      b.x = p.x + Math.sin(p.yaw) * 0.6;
      b.z = p.z + Math.cos(p.yaw) * 0.6;
      b.y = p.y;
      this.toast(isBodyHidden(b, this.level.hides) ? "Body hidden." : "Body dropped. Hide it in a haystack or bush.");
      return;
    }
    const b = this.nearestBody();
    if (!b) return;
    this.carrying = b;
    b.carried = true;
    this.toast("Carrying body. F to drop.");
  }

  private nearestBody(): Guard | null {
    let best: Guard | null = null;
    for (const g of this.guards) {
      if (!g.dead || g.carried) continue;
      const d = dist2D(g, this.p);
      if (d < 2.0 && Math.abs(this.p.y - g.y) < 1.8 && (!best || d < dist2D(best, this.p))) best = g;
    }
    return best;
  }

  private tryThrow() {
    if (this.knives <= 0 || this.knifeCd > 0 || this.climb) return;
    this.knives--;
    this.knifeCd = 0.8;
    const dir = new THREE.Vector3();
    this.camera.getWorldDirection(dir);
    const o = this.camera.position;
    let tMax = 40;
    const wall = raycastBoxes({ x: o.x, y: o.y, z: o.z }, dir, this.level.colliders, tMax);
    if (wall !== null) tMax = wall;
    let hitGuard: Guard | null = null;
    let tg = tMax;
    for (const g of this.guards) {
      if (g.dead) continue;
      const c = new THREE.Vector3(g.x, g.group.position.y + 1.1, g.z).sub(o);
      const t = c.dot(dir);
      if (t < 0 || t > tg) continue;
      const perp = c.addScaledVector(dir, -t).length();
      if (perp < 0.8) {
        hitGuard = g;
        tg = t;
      }
    }
    const t = hitGuard ? tg : tMax;
    const hit = o.clone().addScaledVector(dir, t);
    const chest = new THREE.Vector3(this.p.x, this.p.y + 1.3, this.p.z);
    this.knifeFly = { t: 0, from: chest, to: hit };
    if (hitGuard) {
      hitGuard.stun = 5;
      hitGuard.meter = 0;
      this.toast("Guard stunned.");
    } else {
      // clatter: guards near the landing point go and look
      for (const g of this.guards) if (!g.dead && dist2D(g, hit) < 11) this.hear(g, { x: hit.x, z: hit.z });
      this.toast("Distraction thrown.");
    }
  }

  // ------------------------------------------------------------------ HUD

  private buildHud(): HudState {
    const p = this.p;
    let meter = 0;
    let rank = 0;
    let alert: GuardState | "calm" = "calm";
    const order: Record<GuardState, number> = { patrol: 0, suspicious: 1, search: 2, alert: 3 };
    for (const g of this.guards) {
      if (g.dead) continue;
      meter = Math.max(meter, g.meter);
      if (g.brain.state !== "patrol" && order[g.brain.state] >= rank) {
        rank = order[g.brain.state];
        alert = g.brain.state;
      }
    }
    const tg = this.takedownTarget();
    let prompt = "";
    if (this.climb) prompt = "";
    else if (tg.guard) prompt = tg.guard.isTarget ? "E  Strike the Kapitan with the keris" : tg.guard.stun > 0 ? "E  Finish stunned guard" : "E  Keris takedown";
    else if (this.carrying) prompt = "F  Drop body (inside a haystack or bush to hide it)";
    else if (tg.near) prompt = "Get behind him";
    else if (this.nearestBody()) prompt = "F  Carry body";
    else if (this.hidden) prompt = "Hidden";

    const tgt = this.objective === "kill" ? this.guards.find((g) => g.isTarget && !g.dead) : null;
    const obj: Vec2 = tgt ?? this.level.exit;
    const rel = wrapAngle(yawTo(p, obj) - this.camYaw);
    return {
      meter,
      alert,
      objective: this.objective === "kill" ? "Find and silence the Kapitan of the bridge battery" : "Slip away to the jetty",
      northDeg: (this.camYaw * 180) / Math.PI,
      objDeg: (-rel * 180) / Math.PI,
      eagle: this.eagle,
      crouched: this.crouched,
      hidden: this.hidden,
      knives: this.knives,
      prompt,
      carrying: !!this.carrying,
      toast: this.toastT > 0 ? this.toastText : "",
      caught: this.caught / CATCH_SECONDS,
    };
  }

  // ------------------------------------------------------------------ render

  private syncMeshes() {
    const p = this.p;
    this.player.group.position.set(p.x, p.y, p.z);
    this.player.group.rotation.y = p.yaw;
    for (const g of this.guards) {
      g.group.position.set(g.x, g.y + (g.dead && !g.carried ? 0.25 * g.fall : 0), g.z);
      g.group.rotation.y = g.yaw;
      g.group.rotation.x = g.dead ? -g.fall * (Math.PI / 2) : 0;
    }
  }

  private render(dt: number) {
    const p = this.p;
    this.syncMeshes();
    this.navDbg?.updatePaths(this.guards);

    const crouch = this.phase !== "title" && this.crouched;
    const bob = p.moving && p.grounded ? Math.sin(this.time * (p.running ? 13 : 8)) * 0.04 : 0;
    this.player.group.scale.y = crouch ? 0.72 : 1;
    this.player.body.rotation.z = p.running ? 0.12 : 0;
    this.player.group.position.y = p.y + bob;
    this.player.group.visible = this.phase !== "title" && this.phase !== "intro";

    for (const g of this.guards) {
      const showState = g.brain.state !== "patrol" && !g.dead;
      const showAll = this.eagle && !g.dead;
      g.silhouette.visible = showAll;
      g.cone.visible = showAll;
      g.marker.visible = showAll || showState;
      g.marker.rotation.y += dt * 2.5;
      g.marker.scale.setScalar(1 + Math.sin(this.time * 6) * 0.12 * (g.brain.state === "alert" ? 1.5 : 0.5));
      const col = g.brain.state === "patrol" && g.isTarget ? 0xffd24a : STATE_COLOR[g.brain.state];
      (g.marker.material as THREE.MeshBasicMaterial).color.setHex(col);
      g.coneMat.color.setHex(col);
      const beam = g.group.getObjectByName("beam");
      if (beam) beam.visible = !g.dead;
    }

    // camera
    if (this.phase === "playing" || this.phase === "paused" || this.phase === "won" || this.phase === "lost") {
      const look = new THREE.Vector3(p.x, p.y + (crouch ? 1.1 : 1.55), p.z);
      const rx = -Math.cos(this.camYaw) * 0.45;
      const rz = Math.sin(this.camYaw) * 0.45;
      look.x += rx;
      look.z += rz;
      const dist = 5.4;
      const cp = Math.cos(this.camPitch);
      const off = new THREE.Vector3(-Math.sin(this.camYaw) * cp, Math.sin(this.camPitch), -Math.cos(this.camYaw) * cp);
      const hit = raycastBoxes({ x: look.x, y: look.y, z: look.z }, off, this.level.colliders, dist);
      const d = hit === null ? dist : Math.max(1.0, hit - 0.35);
      const want = look.clone().addScaledVector(off, d);
      want.y = Math.max(want.y, 0.4);
      if (this.camPos.lengthSq() === 0) this.camPos.copy(want);
      this.camPos.lerp(want, 1 - Math.pow(0.0005, dt));
      this.camera.position.copy(this.camPos);
      this.camera.lookAt(look);
    }
    this.sky.position.copy(this.camera.position);

    // Mata Helang look: darker, bluish world so guards and cones stand out
    const e = this.eagle;
    this.renderer.toneMappingExposure = e ? 0.85 : 1.2;
    this.hemi.intensity = e ? LIGHT.eagleHemi : LIGHT.hemi;
    this.ambient.intensity = e ? LIGHT.eagleAmbient : LIGHT.ambient;
    this.sun.intensity = e ? LIGHT.eagleSun : LIGHT.sun;
    (this.scene.fog as THREE.Fog).color.setHex(e ? FOG_EAGLE : FOG_DUSK);

    // exit beam pulse
    const eb = this.level.exitBeam.material as THREE.MeshBasicMaterial;
    if (eb.opacity > 0) eb.opacity = 0.3 + Math.sin(this.time * 3) * 0.08;

    // knife flight
    if (this.knifeFly) {
      const k = this.knifeFly;
      k.t += dt / 0.2;
      this.knifeMesh.visible = true;
      this.knifeMesh.position.lerpVectors(k.from, k.to, clamp(k.t, 0, 1));
      this.knifeMesh.lookAt(k.to);
      this.knifeMesh.rotateX(Math.PI / 2);
      if (k.t >= 1) {
        this.knifeFly = null;
        this.knifeMesh.visible = false;
      }
    }

    this.renderer.render(this.scene, this.camera);
  }
}
