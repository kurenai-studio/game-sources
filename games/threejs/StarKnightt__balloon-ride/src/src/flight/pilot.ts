/**
 * The pilot (public/models/pilot.glb, modelled, rigged and animated in Blender by tools/pilot.py):
 * an original toon character standing in the player's basket, one hand up on the burner's lever.
 *
 * Dressed in the game's own materials: each Blender material name picks an uber toon surface (M.*)
 * and outline group (ID.*, the character ids the ink pass draws in warm brown); her face and neck
 * take a small painted-face material (the skin toon with the face texture over it). Vertex colours
 * carry the albedo.
 *
 * The GLB's root sits at the balloon model's origin (basket floor centre), so it is added straight
 * to the balloon model. Clips: idle (loop, both hands on the rim), lookOver (once), burner (reach up
 * and pull the lever down 0-0.7 s, hold loop 0.7-2.7 s, release to 3.3 s). The mixer runs on game time, so frozen captures are deterministic.
 * The flame and the roar stay tied to the input (ride.ts); only the arm follows it.
 */
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { COMMON, G, OUT, SKIN_VS, specializeUber, uber } from "../render/materials";
import { ID, M } from "../world/geo";
import { LAYER_REFLECT, LAYER_SHADOW, onLayers } from "../render/lightpasses";

interface Role {
  id: number;
  mt: number;
  /** RIDER variant: her moonlit night shading (skin, hair). */
  her?: boolean;
  side?: THREE.Side;
  mask?: number;
}

const ROLES: Record<string, Role> = {
  skin: { id: ID.skin, mt: M.skin, her: true },
  hair: { id: ID.hair, mt: M.hair, her: true, side: THREE.DoubleSide },
  jacket: { id: ID.top, mt: M.cloth },
  // The fleece collar: its own id, so the ink draws its edge against the jacket.
  collar: { id: ID.rider, mt: M.cloth },
  scarf: { id: ID.hat, mt: M.cloth },
  trousers: { id: ID.shorts, mt: M.cloth },
  goggles: { id: ID.rider, mt: M.metal, mask: 0.8 },
  // The lever is the balloon's (the frame's metal and ink).
  lever: { id: ID.pole, mt: M.metal, mask: 0.6 },
};

/** Meshes drawn in the basket view: the lever, and her forearm and hand while they are up on it. */
const BASKET_KEEP = new Set(["lever"]);
const BASKET_ARM = new Set(["forearm_R", "hand_R"]);

/**
 * The burner's light on her: the balloon's own glow (uGlow, ride.ts) at a third of its strength. She
 * stands right under the nozzles, so at full strength the cream collar and her face blew out to white.
 */
const GLOW_K = 0.35;
const PILOT_GLOW = { value: new THREE.Vector4() };

/** Burner clip segments (seconds): pull, hold (looped while the burner is held), release. */
const PULL_END = 21 / 30;
const HOLD_END = 81 / 30;

/**
 * Her clothes' burner light, toned (her copies of the uber shader only): the glow is a warm wash
 * soft-clamped on its brightest channel (hue kept), so pale cloth (the cream collar) warms to
 * orange instead of blowing out to white, and it barely lifts the sun's shade, so her toon bands
 * stay under the glow.
 */
const TONE_GLSL = /* glsl */ `
vec3 pilotTone(vec3 e){
  float m = max(e.r, max(e.g, e.b));
  if (m <= 0.3) return e;
  float k = 0.3 + (m - 0.3) / (1.0 + (m - 0.3) * 3.0);
  return e * (k / m);
}
void main(`;

function toneGlow(fs: string): string {
  const swap = (src: string, a: string, b: string): string => {
    if (!src.includes(a)) throw new Error(`pilot: uber shader changed, "${a}" not found`);
    return src.replace(a, b);
  };
  let s = swap(fs, "void main(", TONE_GLSL);
  s = swap(s, "vec3 col = toonT(base, N, vWPos, jit, paint, rim, soft, shT) + emis;",
    "vec3 pGl = gLamp; gLamp *= 0.15; vec3 col = toonT(base, N, vWPos, jit, paint, rim, soft, shT) + emis; gLamp = pGl;");
  return swap(s, "gEmit += base * gLamp;", "gEmit += pilotTone(base * gLamp);");
}

// ------------------------------------------------------------------ face material

const FACE_VS = /* glsl */ `
${COMMON}
${SKIN_VS}
out vec3 vWPos; out vec3 vN; out vec3 vCol; out vec2 vUv; out float vFront;
void main(){
  vec3 p = position, n = normal;
  // Bind-pose normal: the face paint is projected straight onto the front (+z) of her head.
  vFront = normal.z;
  skinPN(p, n);
  vec4 wp = modelMatrix * vec4(p, 1.0);
  vWPos = wp.xyz;
  vN = normalize(mat3(modelMatrix) * n);
  vCol = color;
  vUv = uv;
  gl_Position = projectionMatrix * viewMatrix * wp;
}`;

const FACE_FS = /* glsl */ `
${COMMON}
${OUT}
uniform sampler2D uFace;
uniform vec4 uGlow;
in vec3 vWPos; in vec3 vN; in vec3 vCol; in vec2 vUv; in float vFront;
vec3 glowLight(vec3 p, vec3 N){
  if (uGlow.w <= 0.0) return vec3(0.0);
  vec3 d = uGlow.xyz - p;
  float d2 = dot(d, d);
  if (d2 > 900.0) return vec3(0.0);
  float ndl = clamp((dot(N, d) * inversesqrt(max(d2, 1e-4)) + 0.4) / 1.4, 0.0, 1.0);
  return vec3(1.0, 0.55, 0.22) * uGlow.w * ndl * (1.0 - smoothstep(200.0, 900.0, d2)) / (1.0 + d2 * 0.035);
}
void main(){
  gFoot = max(length(dFdx(vWPos)), length(dFdy(vWPos)));
  vec3 N = normalize(vN);
  vec4 f = texture(uFace, vUv);
  float a = f.a * smoothstep(0.2, 0.5, vFront);
  vec3 base = mix(vCol, f.rgb, a);
  // The skin toon: one clean cel step, soft cast shadows, warm shade, her moonlit night.
  gSoftCast = 1.0;
  gHer = 1.0;
  // The burner's light on her face, toned: a warm orange wash in one toon band (the side facing the
  // nozzles), soft-clamped so her bright skin never blows out to white. After dusk the flame is her
  // face's main light: a little more of it than on her clothes.
  vec3 gl = glowLight(vWPos, N);
  float gi = 1.0 - exp(-gl.r * 0.9);
  vec3 toG = uGlow.xyz - vWPos;
  float band = mix(0.4, 1.0, smoothstep(0.12, 0.22, dot(N, toG) * inversesqrt(max(dot(toG, toG), 1e-4))));
  vec3 lamp = vec3(1.0, 0.56, 0.28) * 0.36 * gi * band * mix(1.0, 1.6, uNight);
  // Only a little of it lifts the sun's shade, so her face keeps its own toon band.
  gLamp = lamp * 0.3;
  vec3 col = toonT(base, N, vWPos, 0.34, 0.0, 0.5, 0.065, herShade(vec3(0.9, 0.75, 0.7)));
  col = mix(col, col * vec3(1.06, 0.93, 0.84), gi * band * (1.0 - uNight));
  gEmit += base * lamp;
  col = applyFog(col, vWPos);
  writeOut(col, N, uMask);
}`;

function faceMaterial(map: THREE.Texture | null): THREE.ShaderMaterial {
  const m = new THREE.ShaderMaterial({
    glslVersion: THREE.GLSL3,
    uniforms: { ...G, uGlow: PILOT_GLOW, uId: { value: ID.eye }, uMask: { value: 1 }, uFace: { value: map } },
    vertexShader: FACE_VS,
    fragmentShader: FACE_FS,
    vertexColors: true,
  });
  m.name = "pilot face";
  return m;
}

// ------------------------------------------------------------------ the pilot

type Mode = "idle" | "look" | "pull" | "hold" | "release" | "posed";

export class Pilot {
  readonly root: THREE.Object3D;
  readonly mixer: THREE.AnimationMixer;
  readonly clips = new Map<string, THREE.AnimationClip>();
  readonly meshes: THREE.Mesh[] = [];
  tris = 0;
  private readonly act = new Map<string, THREE.AnimationAction>();
  private cur: THREE.AnimationAction | null = null;
  private mode: Mode = "idle";
  /** Seconds of idle before she next looks over the edge on her own. */
  private nextLook = 9;
  private idleFor = 0;
  private lookCool = 0;
  private basket = false;

  private constructor(scene: THREE.Group, anims: THREE.AnimationClip[]) {
    this.root = scene;
    this.root.name = "pilot";
    this.mixer = new THREE.AnimationMixer(scene);
    for (const c of anims) this.clips.set(c.name, c);
    const burner = this.clips.get("burner")!;
    const fps = 30;
    this.clips.set("pull", THREE.AnimationUtils.subclip(burner, "pull", 0, PULL_END * fps, fps));
    this.clips.set("hold", THREE.AnimationUtils.subclip(burner, "hold", PULL_END * fps, HOLD_END * fps, fps));
    this.clips.set("release", THREE.AnimationUtils.subclip(burner, "release", HOLD_END * fps, Math.round(burner.duration * fps), fps));
    for (const [name, clip] of this.clips) {
      const a = this.mixer.clipAction(clip);
      const once = name !== "idle" && name !== "hold";
      a.setLoop(once ? THREE.LoopOnce : THREE.LoopRepeat, Infinity);
      a.clampWhenFinished = once;
      this.act.set(name, a);
    }
    this.play("idle", 0);
  }

  static async load(url = `${import.meta.env.BASE_URL}models/pilot.glb`): Promise<Pilot> {
    const gltf = await new GLTFLoader().loadAsync(url);
    const p = new Pilot(gltf.scene, gltf.animations);
    p.dress();
    return p;
  }

  private dress(): void {
    const mats = new Map<string, THREE.Material>();
    this.root.traverse((o) => {
      const mesh = o as THREE.SkinnedMesh;
      if (!mesh.isMesh) return;
      const src = mesh.material as THREE.MeshStandardMaterial;
      const name = src.name.replace(/\.\d+$/, "");
      const g = mesh.geometry;
      const n = g.attributes.position.count;
      // The uber shaders read float RGB albedo (glTF colours arrive as RGBA, maybe normalised ints).
      const col = g.getAttribute("color") as THREE.BufferAttribute | undefined;
      const rgb = new Float32Array(n * 3).fill(1);
      if (col) for (let i = 0; i < n; i++) {
        rgb[i * 3] = col.getX(i);
        rgb[i * 3 + 1] = col.getY(i);
        rgb[i * 3 + 2] = col.getZ(i);
      }
      g.setAttribute("color", new THREE.BufferAttribute(rgb, 3));
      g.setAttribute("aWind", new THREE.BufferAttribute(new Float32Array(n), 1));
      const role = ROLES[name];
      g.setAttribute("aMat", new THREE.BufferAttribute(new Float32Array(n).fill(role ? role.mt : M.skin), 1));
      if (!g.getAttribute("uv")) g.setAttribute("uv", new THREE.BufferAttribute(new Float32Array(n * 2), 2));
      let m = mats.get(name);
      if (!m) {
        m = name === "face" ? faceMaterial(src.map ?? null) : uber(role?.id ?? ID.skin, role?.mask ?? 1, role?.side ?? THREE.FrontSide, 0, role?.her ?? false);
        mats.set(name, m);
      }
      src.dispose();
      mesh.material = m;
      // Skinned: the bind-pose bounds don't follow the pose.
      mesh.frustumCulled = false;
      this.tris += (g.index ? g.index.count : n) / 3;
      this.meshes.push(mesh);
    });
    specializeUber(this.root);
    // Her own copies of the (specialised) uber materials, sharing every uniform but the burner glow.
    const own = new Map<THREE.Material, THREE.ShaderMaterial>();
    for (const mesh of this.meshes) {
      const m = mesh.material as THREE.ShaderMaterial;
      if (!m.userData.uber) continue;
      let c = own.get(m);
      if (!c) {
        c = m.clone();
        c.uniforms = { ...m.uniforms, uGlow: PILOT_GLOW };
        c.fragmentShader = toneGlow(c.fragmentShader);
        own.set(m, c);
      }
      mesh.material = c;
    }
    onLayers(this.root, LAYER_SHADOW, LAYER_REFLECT);
  }

  private play(name: string, fade: number): void {
    const next = this.act.get(name)!;
    if (this.cur === next) return;
    next.reset();
    next.setEffectiveTimeScale(1);
    next.setEffectiveWeight(1);
    if (this.cur && fade > 0) {
      next.play();
      next.crossFadeFrom(this.cur, fade, false);
    } else {
      for (const a of this.act.values()) if (a !== next) a.stop();
      next.play();
    }
    this.cur = next;
  }

  private done(): boolean {
    const a = this.cur;
    return !!a && a.time >= a.getClip().duration - 1e-3;
  }

  /** Basket view (V): only her raised forearm and hand on the lever are drawn. */
  setBasketView(on: boolean): void {
    this.basket = on;
    this.applyVisibility();
  }

  private applyVisibility(): void {
    // Her arm shows in the basket view only while it is up on the lever (pull, hold, release).
    const arm = this.mode === "pull" || this.mode === "hold" || this.mode === "release";
    // Mesh nodes share names with bones (hand_R, lever): GLTFLoader suffixes one of each pair "_1".
    for (const m of this.meshes) {
      const n = m.name.replace(/_\d+$/, "");
      m.visible = !this.basket || BASKET_KEEP.has(n) || (arm && BASKET_ARM.has(n));
    }
  }

  /**
   * dt = game seconds (0 while paused). `burner` = the burner is firing, `lookDown` = the basket
   * view looks down over the rim.
   */
  update(dt: number, burner: boolean, lookDown: boolean): void {
    const gl = G.uGlow.value;
    PILOT_GLOW.value.set(gl.x, gl.y, gl.z, gl.w * GLOW_K);
    if (this.mode === "posed") return;
    switch (this.mode) {
      case "idle":
        this.idleFor += dt;
        this.lookCool = Math.max(0, this.lookCool - dt);
        if (burner) this.go("pull", 0.2);
        else if (this.idleFor > this.nextLook || (lookDown && this.idleFor > 1.2 && this.lookCool <= 0)) this.go("look", 0.4);
        break;
      case "look":
        if (burner) this.go("pull", 0.35);
        else if (this.done()) this.go("idle", 0.5);
        break;
      case "pull":
        if (!burner) this.go("release", 0.15);
        else if (this.done()) this.go("hold", 0.08);
        break;
      case "hold":
        if (!burner) this.go("release", 0.15);
        break;
      case "release":
        if (burner) this.go("pull", 0.15);
        else if (this.done()) this.go("idle", 0.3);
        break;
    }
    this.mixer.update(dt);
  }

  private go(mode: Mode, fade: number): void {
    if (mode === "idle") {
      this.idleFor = 0;
      // Every 14-26 s (deterministic sequence, no Math.random: captures stay reproducible).
      this.nextLook = 14 + ((this.nextLook * 7.31) % 12);
    }
    if (mode === "look") this.lookCool = 9;
    this.mode = mode;
    this.play(mode === "look" ? "lookOver" : mode, fade);
    this.applyVisibility();
  }

  /** Freeze her on clip `name` at `t` seconds (captures); null goes back to the live state machine. */
  pose(name: string | null, t = 0): void {
    if (name === null) {
      this.mode = "posed";
      this.go("idle", 0);
      return;
    }
    const a = this.act.get(name);
    if (!a) throw new Error(`pilot: no clip "${name}" (have ${[...this.act.keys()].join(", ")})`);
    for (const x of this.act.values()) x.stop();
    a.reset();
    a.setEffectiveWeight(1);
    a.play();
    a.time = Math.min(t, a.getClip().duration);
    this.cur = a;
    this.mode = "posed";
    this.mixer.update(0);
  }
}
