import * as THREE from 'three';
import { CAMERA, COLORS, QUALITY, SHADOW, TIER, WORLD } from './Constants.js';
import { eventBus, Events } from './EventBus.js';
import { gameState } from './GameState.js';
import { bakeWorldMaterials } from '../gfx/materials.js';
import { DaySky } from '../render/sky.js';
import { Pipeline } from '../render/pipeline.js';
import { LevelBuilder } from '../level/LevelBuilder.js';
import { InputSystem } from '../systems/InputSystem.js';
import { VfxSystem } from '../systems/VfxSystem.js';
import { PickupSystem } from '../systems/Pickups.js';
import { Player } from '../gameplay/Player.js';
import { Weapon } from '../gameplay/Weapon.js';
import { EnemySquad } from '../gameplay/Enemies.js';
import { Combat } from '../gameplay/Combat.js';
import { Hud } from '../ui/Hud.js';
import { AudioEngine } from '../audio/engine.js';
import { perf } from './Perf.js';

const FPS_KEY = 'cinder.fpsCap';
const FPS_OPTS = [0, 200, 180, 144, 120, 60];
const FPS_DEFAULT = 180;
const FPS_EPS_MS = 0.2;
const QUALITY_KEY = 'cinder.quality';
const QUALITY_DEFAULT = 'cinematic';

function loadFpsCap() {
  try {
    const v = parseInt(localStorage.getItem(FPS_KEY), 10);
    if (v === 0 || FPS_OPTS.includes(v)) return v;
  } catch { /* storage unavailable */ }
  return FPS_DEFAULT;
}

function loadQuality() {
  try {
    const q = new URLSearchParams(location.search).get('quality');
    if (q && QUALITY[q]) return q;
  } catch { /* ignore */ }
  try {
    const v = localStorage.getItem(QUALITY_KEY);
    if (v && QUALITY[v]) return v;
  } catch { /* storage unavailable */ }
  return QUALITY_DEFAULT;
}

function yieldPaint() {
  return new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
}

export class Game {
  constructor(canvas) {
    this.canvas = canvas;
    this.clock = new THREE.Clock();
    this.paused = false;
    this.running = false;
    this.fps = 0;
    this.frameMs = 0;
    this.tier = 'high';
    this._frames = 0;
    this._fpsT = 0;
    this._time = 0;
    this._stride = 0;
    this._fitCx = null;
    this._fitCz = null;
    this._fitPt = { cx: 0, cz: 0 };
    this._shadowRefit = 0;
    this._shadowUpdated = 0;
    this._shadowTick = 0;
    /* 1 = every frame (Three default). 2/3 = every Nth frame. 0 = refit only.
     * Confirm soak (refs/combat-soak-refit.json): >8ms frames had 0% refit,
     * 0 tex uploads, 0 compiles — the tail is GPU-queue, not a refit hitch.
     * Three still re-rendered the 4096 sun map every frame; cadence 3
     * measured better than 2. renderOnce() forces a refresh so shots match. */
    this._shadowCadence = 3;
    this._shadowForce = false;
    this._gpuProbe = { tex: 0, compile: 0, link: 0 };
    this._ft = new Float64Array(512);
    this._ftI = 0;
    this._ftN = 0;
    this._pi = new Float64Array(512);
    this._piI = 0;
    this._piN = 0;
    this._fpsCap = loadFpsCap();
    this._quality = loadQuality();
    this._lastPresent = 0;
    this._wake = 0;
    this.shell = null;
    this.manual = false;
  }

  /* Staged boot so the loader can paint real progress. Yields a frame
   * before each heavy step; reports after the work actually finished. */
  async init({ onProgress, uncapped = false } = {}) {
    const report = (pct, label) => onProgress?.({ pct, label });
    if (uncapped) this._fpsCap = 0;

    report(0.06, 'Initializing renderer…');
    await yieldPaint();
    this._initRenderer();

    report(0.16, 'Lighting the district…');
    await yieldPaint();
    this._initScene();

    report(0.28, 'Baking materials…');
    await yieldPaint();
    this.mats = bakeWorldMaterials(this.renderer, TIER.high.aniso);

    report(0.58, 'Building Ashline Block…');
    await yieldPaint();
    this.level = new LevelBuilder(this.scene, this.mats);

    report(0.82, 'Deploying hostiles…');
    await yieldPaint();
    this._initPlay();

    report(0.94, 'Warming shaders…');
    await yieldPaint();
    this.player._applyCamera();
    this.renderOnce();
    this._warmCombatShaders();
    this.renderOnce();
    if (!uncapped) this._poseMenuView();

    report(1, 'Ready');
    await yieldPaint();
  }

  _initRenderer() {
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: false,
      powerPreference: 'high-performance',
    });
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.NoToneMapping;
    this.renderer.shadowMap.enabled = true;
    /* c28: keep PCFSoft, tighten radius 2.1 -> 1.35 for a crisper sun edge. */
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, TIER.high.dpr));
    this.camera = new THREE.PerspectiveCamera(CAMERA.FOV, 1, CAMERA.NEAR, CAMERA.FAR);
    this.pipeline = new Pipeline(this.renderer, QUALITY[this._quality]);
    this.resize();
    addEventListener('resize', () => this.resize());
    this._bindContextLost();
    this._installGpuProbe();
  }

  /* Count real GPU uploads / shader compiles so soak spikes can be
   * attributed to first-visibility work vs. a shadow refit. */
  _installGpuProbe() {
    const gl = this.renderer.getContext();
    const c = this._gpuProbe;
    const wrap = (name, key) => {
      const orig = gl[name];
      if (typeof orig !== 'function') return;
      gl[name] = function () {
        c[key]++;
        return orig.apply(this, arguments);
      };
    };
    wrap('texImage2D', 'tex');
    wrap('texSubImage2D', 'tex');
    wrap('compressedTexImage2D', 'tex');
    wrap('compileShader', 'compile');
    wrap('linkProgram', 'link');
  }

  /* Context loss is the mid-session black screen (VFX/material leak used
   * to trigger it). Pause the loop and offer a reload instead of a dead
   * canvas. preventDefault() so we can restore if the browser allows it. */
  _bindContextLost() {
    const el = this.canvas;
    el.addEventListener('webglcontextlost', (e) => {
      e.preventDefault();
      this.paused = true;
      this.running = false;
      this.renderer.setAnimationLoop(null);
      this._showContextLost();
    });
    el.addEventListener('webglcontextrestored', () => { location.reload(); });
  }

  _showContextLost() {
    if (this.lostEl) {
      this.lostEl.hidden = false;
      return;
    }
    const box = document.createElement('div');
    box.className = 'overlay shell-over';
    box.innerHTML = '<div class="shell-col"><p class="shell-kicker">Signal lost</p><h2>GPU context lost</h2><p>GPU context lost — click to reload</p><button type="button">Reload</button></div>';
    box.querySelector('button').addEventListener('click', () => location.reload());
    box.addEventListener('click', (e) => {
      if (e.target === box) location.reload();
    });
    document.body.appendChild(box);
    this.lostEl = box;
    document.exitPointerLock?.();
    if (this.lockEl) this.lockEl.hidden = true;
  }

  _initScene() {
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xc8d4dc);
    this.scene.fog = new THREE.FogExp2(WORLD.FOG_COLOR, WORLD.FOG_DENSITY);

    this.sky = new DaySky();
    /* c26: c25 hemi 0.24 crushed shadowed plaster to unlit black (street
     * rect 20/15/10). Italy-sun shadows stay dusty and luminous — warm
     * fill ~0.46, sun still outruns it so the canyon ratio stays <0.60. */
    this.hemi = new THREE.HemisphereLight(0xe8d8bc, 0xd4ae72, 0.64);
    this.scene.add(this.hemi);
    this.sun = new THREE.DirectionalLight(COLORS.SUN, 8.70);
    this.sun.target.position.set(6.5, 1.2, 44);
    /* Ortho shadows: closer sun shrinks near/far (72 wasted depth + FPS). */
    this._sunDist = 44;
    this.sun.position.copy(this.sky.sunDir).multiplyScalar(this._sunDist).add(this.sun.target.position);
    /* Camera dummy — Object3D.lookAt faces +Z, which inverted the c25
     * near/far and parked the look-point (van, joists) past far=50. */
    this._fitDummy = new THREE.OrthographicCamera(-1, 1, 1, -1, 1, 10);
    this._fitInv = new THREE.Matrix4();
    this._fitV = new THREE.Vector3();
    this._fitFwd = new THREE.Vector3();
    this.sun.castShadow = true;
    /* Static sun + mostly-static world: do not rebuild the 4096 map every
     * frame. needsUpdate is pulsed on refit / cadence / renderOnce. */
    this.sun.shadow.autoUpdate = false;
    this.sun.shadow.needsUpdate = true;
    this.sun.shadow.mapSize.set(QUALITY[this._quality].shadow, QUALITY[this._quality].shadow);
    this.sun.shadow.bias = -0.00045;
    this.sun.shadow.normalBias = 0.010;
    this.sun.shadow.radius = 1.35;
    this.scene.add(this.sun);
    this.scene.add(this.sun.target);
    this._fitSunShadow();
    this.moon = this.sun;
    this.bounce = this.hemi;

    this.sky.attach(this.scene);
    this.scene.add(this.camera);

    const pmrem = new THREE.PMREMGenerator(this.renderer);
    const envScene = new THREE.Scene();
    const envSky = new THREE.Mesh(
      new THREE.SphereGeometry(10, 24, 16),
      new THREE.ShaderMaterial({
        side: THREE.BackSide,
        depthWrite: false,
        uniforms: {
          uZenith: { value: new THREE.Color(0x6aa8d0) },
          uHorizon: { value: new THREE.Color(0xdeccaa) },
          uSunDir: { value: this.sky.sunDir.clone() },
        },
        vertexShader: 'varying vec3 vDir; void main(){ vDir = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }',
        fragmentShader: [
          'varying vec3 vDir;',
          'uniform vec3 uZenith;',
          'uniform vec3 uHorizon;',
          'uniform vec3 uSunDir;',
          'void main(){',
          '  vec3 d = normalize(vDir);',
          '  float h = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);',
          '  vec3 col = mix(uHorizon, uZenith, h);',
          '  float sun = pow(max(0.0, dot(d, normalize(uSunDir))), 28.0);',
          '  col += vec3(1.0, 0.92, 0.74) * sun * 2.6;',
          '  gl_FragColor = vec4(col, 1.0);',
          '}',
        ].join('\n'),
      }),
    );
    envScene.add(envSky);
    const envGnd = new THREE.Mesh(
      new THREE.CircleGeometry(12, 24),
      new THREE.MeshBasicMaterial({ color: 0xc4a878 }),
    );
    envGnd.rotation.x = -Math.PI / 2;
    envGnd.position.y = -1.4;
    envScene.add(envGnd);
    this.scene.environment = pmrem.fromScene(envScene, 0.05).texture;
    this.scene.environmentIntensity = 0.58;
    pmrem.dispose();
    envSky.material.dispose();
    envSky.geometry.dispose();
    envGnd.material.dispose();
    envGnd.geometry.dispose();

  }

  _initPlay() {
    this.input = new InputSystem();
    this.player = new Player(this.camera, this.level.colliders);
    this.weapon = new Weapon(this.camera, this.mats);
    this.vfx = new VfxSystem(this.scene);
    this.squad = new EnemySquad(this.scene, this.level.spawns, this.mats, this.level.colliders, this.vfx);
    /* Enemies spawn after world flatten, so same-material siblings (jacket
     * plates, trouser volumes, rifle parts) never got batched. Merge is
     * per-group — animated bones stay separate, pixels stay identical. */
    for (const e of this.squad.list) this.level._mergeMeshes(e.root);
    this.combat = new Combat(this.camera, this.squad, this.vfx, this.level.extract);
    this.combat.player = this.player;
    this.pickups = new PickupSystem(this.scene);
    eventBus.on(Events.WEAPON_FIRE, (d) => {
      // No trauma on fire (autopsy fix 3): the per-shot shake aliased into
      // white noise while spraying. The clean vertical kick that recovers is
      // the pattern-recoil pitch impulse below — that's the whole read.
      // Skipped in manual/screenshot mode so framing stays pinned; tests
      // drive kick()/stepRecoil() directly.
      if (d && !this.manual) {
        this.player.kick(d.recoilVy || 0, d.recoilVx || 0);
        this.player.addFovKick(d.fovKick || 0);
      }
    });
    eventBus.on(Events.PLAYER_HIT, () => this.player.addTrauma(0.45));
    // Picking up a heavy while HOLDING the other one swaps in-hand.
    eventBus.on(Events.PICKUP, (d) => { if (d.swap) this.weapon.equip(d.id); });
    this.hud = new Hud(document.getElementById('hud'));
    this.audio = new AudioEngine();
    this._bindUi();
    this.player._applyCamera();
    if (typeof window !== 'undefined') {
      window.__THREE_GAME_DIAGNOSTICS__ = {
        get renderer() { return this._g.renderer.info; },
        get state() { return this._g.info(); },
        _g: this,
      };
      window.__perf = perf;
    }
  }

  /* Touch every runtime program the first shotgun / scope / kill / chest
   * used to compile mid-fight. State is snapshotted and restored so the
   * menu (and tests) see a clean loadout. Loader overlay hides the frames. */
  _warmCombatShaders() {
    const st = gameState;
    const snap = {
      weapon: this.weapon.id,
      health: st.player.health,
      armor: st.player.armor,
      kills: st.game.kills,
      remaining: st.game.remaining,
      extract: st.game.extractOpen,
      playing: st.game.isPlaying,
      started: st.game.started,
      grace: st.game.grace,
      headshots: st.game.headshots,
      shotsFired: st.game.shotsFired,
      shotsHit: st.game.shotsHit,
      damageTaken: st.game.damageTaken,
      startedAt: st.game.startedAt,
      enemies: this.squad.list.map((e) => ({
        alive: e.alive, health: e.health,
        rx: e.root.rotation.x, y: e.root.position.y,
      })),
      weapons: {},
      pickups: st.pickups.map((p) => ({ taken: p.taken, refill: p.refill, grace: p.grace })),
    };
    for (const id of ['rifle', 'sniper', 'shotgun', 'pistol']) {
      const w = st.weapons[id];
      snap.weapons[id] = { mag: w.mag, reserve: w.reserve, reloading: w.reloading, owned: w.owned };
      w.owned = true;
      w.mag = 30;
      w.reloading = false;
    }
    st.game.isPlaying = true;
    st.game.started = true;
    st.game.grace = 0;
    st.player.alive = true;
    this.audio.resume();

    const origin = new THREE.Vector3(0.2, 1.15, 22);
    const dir = new THREE.Vector3(0, 0.02, -1).normalize();
    this.vfx.impact(origin, false);
    this.vfx.impact(origin, true);
    this.vfx.dust(origin, true);
    this.vfx.muzzleFlash(origin);
    this.vfx.tracer(origin, dir, 'warm', 14);
    this.vfx.tracer(origin, dir, 'bright', 14);
    this.vfx.tracer(origin, dir, 'faint2nd', 14);
    this.vfx.tracer(origin, dir, 'enemy', 14);
    this.renderOnce();

    for (const id of ['rifle', 'sniper', 'shotgun', 'pistol']) {
      this.equip(id);
      this.weapon.tryFire();
      this.renderOnce();
    }

    this.equip('sniper');
    this.setAds(1);
    this.hud.update(0.016, this.player, this.squad.list);
    this.renderOnce();
    this.setAds(2);
    this.hud.update(0.016, this.player, this.squad.list);
    this.renderOnce();
    this.setAds(0);
    this.hud.update(0.016, this.player, this.squad.list);
    this.renderOnce();

    const e0 = this.squad.list[0];
    e0.hit(999, true);
    this.hud.update(0.016, this.player, this.squad.list);
    this.renderOnce();

    this.squad.list.forEach((en, i) => {
      const s = snap.enemies[i];
      en.alive = s.alive;
      en.health = s.health;
      en.resetCombat();
      en.root.rotation.x = s.rx;
      en.root.position.y = s.y;
    });
    st.game.kills = snap.kills;
    st.game.remaining = snap.remaining;
    st.game.extractOpen = snap.extract;
    st.game.isPlaying = snap.playing;
    st.game.started = snap.started;
    st.game.grace = snap.grace;
    st.game.headshots = snap.headshots;
    st.game.shotsFired = snap.shotsFired;
    st.game.shotsHit = snap.shotsHit;
    st.game.damageTaken = snap.damageTaken;
    st.game.startedAt = snap.startedAt;
    st.player.health = snap.health;
    st.player.armor = snap.armor;
    st.player.alive = true;
    for (const id of ['rifle', 'sniper', 'shotgun', 'pistol']) {
      Object.assign(st.weapons[id], snap.weapons[id]);
    }
    st.pickups.forEach((p, i) => {
      p.taken = snap.pickups[i].taken;
      p.refill = snap.pickups[i].refill;
      p.grace = snap.pickups[i].grace;
    });
    this.pickups.sync();
    this.vfx.update(10);
    this.equip(snap.weapon);
    this.weapon._flash = 0;
    if (this.weapon.muzzle) this.weapon.muzzle.material.opacity = 0;
    if (this.weapon.muzzleLight) this.weapon.muzzleLight.intensity = 0;
    this.weapon._forceUnscope();
    this.hud._feeds.length = 0;
    this.hud._feedHtml = '';
    this.hud.feed.innerHTML = '';
    this.hud._hitT = 0;
    this.hud.update(0.016, this.player, this.squad.list);
  }

  attachShell(shell) {
    this.shell = shell;
    shell.on('play', () => this._startFromMenu());
    shell.on('resume', () => this._resumeFromMenu());
    shell.on('restart', () => this.restart());
    shell.bindSettings({
      getSens: () => this.player.sensMult,
      setSens: (v) => this.player.setSens(v),
      getVol: () => this.audio.getVolume(),
      setVol: (v) => this.audio.setVolume(v),
      getFpsCap: () => this.getFpsCap(),
      setFpsCap: (v) => this.setFpsCap(v),
      getQuality: () => this.getQuality(),
      setQuality: (v) => this.setQuality(v),
      getFps: () => this.fps,
    });
  }

  _bindUi() {
    this.lockEl = document.getElementById('lock');
    this.overEl = document.getElementById('over');
    if (!this.overEl) {
      this.overEl = document.createElement('div');
      this.overEl.className = 'overlay';
      this.overEl.hidden = true;
      this.overEl.innerHTML = '<div><h2></h2><p></p><button type="button">Restart</button></div>';
      document.body.appendChild(this.overEl);
      this.overEl.querySelector('button').addEventListener('click', () => this.restart());
    }

    this.canvas.addEventListener('click', () => {
      if (this.shell && !this.shell.root?.hidden) return;
      if (!gameState.game.over && !gameState.game.won) this._requestLock();
    });
    document.addEventListener('pointerlockerror', () => {
      this.player.enabled = false;
      if (gameState.game.over || gameState.game.won) return;
      if (gameState.game.started) this._pauseToMenu();
      else this.shell?.showMenu({ resume: false });
    });
    document.addEventListener('pointerlockchange', () => {
      const on = document.pointerLockElement === this.canvas;
      this.player.enabled = on;
      if (on) this._onLocked();
      else if (gameState.game.started && !gameState.game.over && !gameState.game.won) {
        this._pauseToMenu();
      }
    });
    document.addEventListener('keydown', (e) => {
      if (e.code !== 'Escape') return;
      if (document.pointerLockElement) return;
      if (gameState.game.over || gameState.game.won) return;
      this.shell?.handleEscape();
    });
    eventBus.on(Events.GAME_OVER, () => this._showOver('KIA', 'You were dropped in Ashline.', 'kia'));
    eventBus.on(Events.GAME_WIN, () => this._showOver('RAID COMPLETE', 'Block is clear. Bird inbound.', 'extract'));
    eventBus.on(Events.GAME_START, () => {
      if (!gameState.game.startedAt) gameState.game.startedAt = performance.now();
    });
  }

  _requestLock() {
    try {
      const p = this.canvas.requestPointerLock?.({ unadjustedMovement: true });
      p?.catch?.(() => this.canvas.requestPointerLock?.());
    } catch {
      this.canvas.requestPointerLock?.();
    }
    this.audio.resume();
  }

  _onLocked() {
    this.shell?.hide();
    this._setHud(true);
    this.setPaused(false);
    gameState.game.paused = false;
    gameState.game.isPlaying = true;
    if (!gameState.game.started) {
      gameState.game.started = true;
      eventBus.emit(Events.GAME_START);
    }
  }

  _poseMenuView() {
    this.player.place(-1.0, 0, 30.0, 0.14, 0.12);
    this.renderOnce();
  }

  _poseSpawn() {
    this.player.place(0.35, 0, 3.8, 0.06, 0.02);
  }

  _startFromMenu() {
    this._poseSpawn();
    this.setPaused(false);
    this.begin();
    this._requestLock();
  }

  _resumeFromMenu() {
    this.setPaused(false);
    gameState.game.paused = false;
    gameState.game.isPlaying = true;
    this._requestLock();
  }

  _pauseToMenu() {
    if (gameState.game.over || gameState.game.won) return;
    this.setPaused(true);
    gameState.game.paused = true;
    this.player.enabled = false;
    this._setHud(false);
    this.shell?.showMenu({ resume: !!gameState.game.started });
  }

  _setHud(on) {
    const hud = document.getElementById('hud');
    if (hud) hud.hidden = !on;
  }

  skipMenu() {
    this.shell?.dismiss();
    this._setHud(true);
    gameState.game.started = true;
    gameState.game.isPlaying = true;
    if (!gameState.game.startedAt) gameState.game.startedAt = performance.now();
    if (this.manual) {
      this.player.enabled = false;
      this.renderOnce();
    } else {
      this.begin();
    }
  }

  getFpsCap() { return this._fpsCap; }

  getQuality() { return this._quality; }

  setQuality(v, { persist = true } = {}) {
    const id = QUALITY[v] ? v : QUALITY_DEFAULT;
    const spec = QUALITY[id];
    this._quality = id;
    if (this.sun) this._applyShadowSize(spec.shadow);
    if (this.pipeline) this.pipeline.setQuality(spec);
    if (persist) {
      try { localStorage.setItem(QUALITY_KEY, id); } catch { /* ignore */ }
    }
    if (this.paused) this.renderOnce();
  }

  /* Shadow map SIZE only — type stays PCFSoft, radius stays 1.35. */
  _applyShadowSize(size) {
    const shadow = this.sun.shadow;
    if (shadow.mapSize.x === size && shadow.mapSize.y === size) return;
    if (shadow.map) {
      shadow.map.dispose();
      shadow.map = null;
    }
    shadow.mapSize.set(size, size);
    this._fitCx = null;
    this._fitCz = null;
    this._fitSunShadow();
    shadow.needsUpdate = true;
    this._shadowTick = 0;
  }

  /* Harness / A-B: cadence 1 = every frame, 2/3 = every N, 0 = refit only. */
  setShadowCadence(n) {
    const v = n | 0;
    this._shadowCadence = v < 0 ? 1 : v;
    if (this.sun) {
      this.sun.shadow.autoUpdate = this._shadowCadence === 1;
      this.sun.shadow.needsUpdate = true;
    }
    this._shadowTick = 0;
  }

  setFpsCap(v, { persist = true } = {}) {
    const n = +v;
    this._fpsCap = (n === 0 || FPS_OPTS.includes(n)) ? n : FPS_DEFAULT;
    this._lastPresent = 0;
    this._piN = 0;
    this._piI = 0;
    this._frames = 0;
    this._fpsT = 0;
    this._disarmWake();
    if (persist) {
      try { localStorage.setItem(FPS_KEY, String(this._fpsCap)); } catch { /* ignore */ }
    }
  }

  _showOver(title, body, kind = 'kia') {
    document.exitPointerLock?.();
    this.setPaused(true);
    this.player.enabled = false;
    this._setHud(false);
    const stats = gameState.raidStats();
    if (this.shell) this.shell.showOver(title, body, kind, stats);
    else if (this.overEl) {
      this.overEl.hidden = false;
      this.overEl.querySelector('h2').textContent = title;
      this.overEl.querySelector('p').textContent = body;
    }
    if (this.lockEl) this.lockEl.hidden = true;
  }

  /* Test-only hooks. Inert unless a harness calls them — not auto-run. */
  forceObjective() {
    if (gameState.game.won || gameState.game.over) return;
    gameState.game.remaining = 0;
    gameState.game.extractOpen = true;
    eventBus.emit(Events.EXTRACT_READY);
  }

  forceWin() {
    if (gameState.game.over) return;
    if (!gameState.game.extractOpen) this.forceObjective();
    if (gameState.game.won) return;
    gameState.game.won = true;
    gameState.game.isPlaying = false;
    eventBus.emit(Events.GAME_WIN);
  }

  forceKia() {
    if (gameState.game.won || gameState.game.over) return;
    gameState.player.health = 0;
    gameState.player.alive = false;
    gameState.game.over = true;
    gameState.game.isPlaying = false;
    eventBus.emit(Events.PLAYER_DIE);
    eventBus.emit(Events.GAME_OVER);
  }

  restart() {
    gameState.reset();
    this.weapon.equip('rifle');
    this.pickups.sync();
    this.setPaused(false);
    this.player.place(0.35, 0, 3.8, 0.06, 0.02);
    for (const e of this.squad.list) {
      e.alive = true;
      e.health = 90;
      e.resetCombat();
      e.root.rotation.x = 0;
      e.root.position.y = e.spawnY;
    }
    gameState.game.remaining = this.squad.list.length;
    this._setHud(false);
    if (this.shell) this.shell.showMenu({ resume: false });
    else if (this.lockEl) this.lockEl.hidden = false;
    if (this.overEl && !this.shell) this.overEl.hidden = true;
    eventBus.emit(Events.GAME_RESTART);
  }

  /* Quantized look point for the shadow fit: 2 m grid, so tiny mouse/walk
   * motion can't slide the frustum (autopsy fix 4 — CSM stabilization). */
  _fitPoint() {
    const px = this.camera ? this.camera.position.x : 0;
    const pz = this.camera ? this.camera.position.z : 30;
    const fwd = this._fitFwd.set(0, 0, -1);
    if (this.camera) this.camera.getWorldDirection(fwd);
    this._fitPt.cx = Math.round(THREE.MathUtils.clamp(px + fwd.x * 12, -6, 20) / 2) * 2;
    this._fitPt.cz = Math.round(THREE.MathUtils.clamp(pz + fwd.z * 12, 2, 88) / 2) * 2;
    return this._fitPt;
  }

  /* Refit only when the quantized look point actually moves — the per-frame
   * refit translated/resized the frustum every frame, crawling every shadow
   * edge on every mouse turn. */
  _updateSunShadow() {
    const { cx, cz } = this._fitPoint();
    const refit = cx !== this._fitCx || cz !== this._fitCz;
    if (refit) this._fitSunShadow();
    this._shadowRefit = refit ? 1 : 0;
    this._driveShadowUpdate(refit);
  }

  /* Three re-renders the whole sun shadow map every frame while
   * shadow.autoUpdate is true (the default). A static sun + mostly-static
   * world does not need that; we flip autoUpdate off and pulse needsUpdate
   * on refit and on a measured cadence. Cadence 1 keeps the legacy path
   * for the confirm soak. */
  _driveShadowUpdate(didRefit) {
    const shadow = this.sun.shadow;
    this._shadowTick++;
    const cadence = this._shadowCadence;
    let update = didRefit;
    if (!update && cadence > 0) {
      update = cadence === 1 || (this._shadowTick % cadence) === 0;
    }
    if (didRefit) this._shadowTick = 0;
    if (this._shadowForce) update = true;
    if (!shadow.autoUpdate) shadow.needsUpdate = update;
    this._shadowUpdated = (shadow.autoUpdate || update) ? 1 : 0;
  }

  /* Fit-to-view: retarget the sun at the framed look point, then take a
   * light-space AABB of that box plus must-cover casters (yard van, cut
   * joists, both canyon walls) and a pad in the shadow-fall direction so
   * the landing stays on-map. Fixed target at z=44 was why the yard van
   * and south street sat in a 40-unit far clip. Falls back to SHADOW.
   * Bounds snap to shadow-texel multiples so a refit moves the shadow map
   * by at most one texel. */
  _fitSunShadow() {
    const px = this.camera ? this.camera.position.x : 0;
    const pz = this.camera ? this.camera.position.z : 30;
    const { cx, cz } = this._fitPoint();
    this._fitCx = cx;
    this._fitCz = cz;
    this.sun.target.position.set(cx, 1.35, cz);
    this.sun.position.copy(this.sky.sunDir).multiplyScalar(this._sunDist).add(this.sun.target.position);
    this.sun.updateMatrixWorld(true);
    this.sun.target.updateMatrixWorld(true);
    const dummy = this._fitDummy;
    dummy.position.copy(this.sun.position);
    dummy.up.set(0, 1, 0);
    dummy.lookAt(this.sun.target.position);
    dummy.updateMatrixWorld(true);
    const inv = this._fitInv.copy(dummy.matrixWorld).invert();
    const v = this._fitV;
    let minX = Infinity, maxX = -Infinity;
    let minY = Infinity, maxY = -Infinity;
    let minZ = Infinity, maxZ = -Infinity;
    const acc = (x, y, z) => {
      v.set(x, y, z).applyMatrix4(inv);
      if (v.x < minX) minX = v.x;
      if (v.x > maxX) maxX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.y > maxY) maxY = v.y;
      if (v.z < minZ) minZ = v.z;
      if (v.z > maxZ) maxZ = v.z;
    };
    /* Shadow falls along -sunDir; pad receivers so the truck/wall blobs land. */
    const fx = -this.sky.sunDir.x * 12;
    const fz = -this.sky.sunDir.z * 12;
    for (const x of [cx - 15, cx + 15]) {
      for (const y of [0, 8]) {
        for (const z of [cz - 12, cz + 16]) {
          acc(x, y, z);
          acc(x + fx, y, z + fz);
        }
      }
    }
    const extras = [
      [2.8, 1.5, 26.4], [0.6, 1.3, 12.0], [3.4, 1.7, 15.4],
      [-7, 5, cz], [5, 5, cz],
    ];
    if (pz < 20 || cz < 14) {
      extras.push([12.4, 2.1, 3.3], [11.0, 0.05, 2.6], [9.4, 0.05, 2.0]);
    }
    if (px > 8 || (cz > 12 && cz < 28)) {
      extras.push([9, 3.5, 20], [13.5, 0.05, 20], [14.6, 0.05, 20.2]);
    }
    if (pz > 48) extras.push([9, 3.5, 64], [12, 0.05, 44]);
    for (const [x, y, z] of extras) {
      if (Math.abs(x - cx) < 32 && Math.abs(z - cz) < 34) acc(x, y, z);
    }
    const cam = this.sun.shadow.camera;
    const pad = 4;
    cam.left = minX - pad;
    cam.right = maxX + pad;
    cam.top = maxY + pad;
    cam.bottom = minY - pad;
    /* Camera-space Z is negative in front; near/far are positive distances. */
    cam.near = Math.max(2, -maxZ - 8);
    cam.far = Math.max(cam.near + 44, -minZ + 12);
    const spanX = cam.right - cam.left;
    const spanY = cam.top - cam.bottom;
    const zOk = cam.far > cam.near + 20 && Number.isFinite(cam.near);
    if (!zOk || !Number.isFinite(spanX) || spanX < 24 || spanX > 170 || spanY < 24 || spanY > 170) {
      cam.left = SHADOW.LEFT;
      cam.right = SHADOW.RIGHT;
      cam.top = SHADOW.TOP;
      cam.bottom = SHADOW.BOTTOM;
      cam.near = SHADOW.NEAR;
      cam.far = SHADOW.FAR;
    }
    // Texel snap: quantize the ortho bounds to shadow-map texel multiples
    // (outward, so coverage never shrinks) — stops sub-texel shadow swim.
    const mapSize = this.sun.shadow.mapSize.x || 4096;
    const tx = (cam.right - cam.left) / mapSize;
    const ty = (cam.top - cam.bottom) / mapSize;
    cam.left = Math.floor(cam.left / tx) * tx;
    cam.right = Math.ceil(cam.right / tx) * tx;
    cam.bottom = Math.floor(cam.bottom / ty) * ty;
    cam.top = Math.ceil(cam.top / ty) * ty;
    cam.updateProjectionMatrix();
    this._shadowBox = {
      l: +cam.left.toFixed(1), r: +cam.right.toFixed(1),
      t: +cam.top.toFixed(1), b: +cam.bottom.toFixed(1),
      n: +cam.near.toFixed(1), f: +cam.far.toFixed(1),
    };
  }

  resize() {
    const w = innerWidth, h = innerHeight;
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.pipeline.resize(this.canvas.width, this.canvas.height);
  }

  step(dt) {
    const input = this.input.sample();
    if (this.manual) {
      input.lookX = 0;
      input.lookY = 0;
      input.fire = false;
    }
    if ((gameState.player.alive && gameState.game.isPlaying) || this.manual) {
      if (this.manual) this.player._applyCamera();
      else this.player.update(dt, input);
      if (input.wheel) this._wheelSwitch(input.wheel);
      perf.mark('weapon');
      this.weapon.update(dt, input, Math.hypot(this.player.vel.x, this.player.vel.z) > 0.4);
      perf.done('weapon');
      const hostile = !this.manual && gameState.game.isPlaying && gameState.game.grace <= 0;
      perf.mark('ai');
      this.squad.update(dt, this.player.pos, hostile);
      perf.done('ai');
      this.combat.tryExtract(this.player.pos);
      this.pickups.update(dt, this._time, this.player.pos);
      if (gameState.game.isPlaying && gameState.game.grace > 0) {
        gameState.game.grace = Math.max(0, gameState.game.grace - dt);
      }
    }
    this.level.update(dt, this._time);
    perf.mark('vfx');
    this.vfx.update(dt);
    perf.done('vfx');
    // Footstep per full bob cycle (~3.4 Hz at speed) — grounds the new
    // movement pace. Volume tracks stance, silent in manual/harness mode.
    const strideNow = Math.floor(this.player.bob / (Math.PI * 2));
    if (strideNow !== this._stride) {
      this._stride = strideNow;
      if (!this.manual && this.player.grounded && gameState.game.isPlaying
        && Math.hypot(this.player.vel.x, this.player.vel.z) > 1.2) {
        this.audio.footstep(gameState.player.crouching ? 0.4
          : gameState.player.sprinting ? 1.1 : 0.75);
      }
    }
    perf.mark('audio');
    this.audio.update?.(dt);
    perf.done('audio');
    perf.mark('hud');
    this.hud.update(dt, this.player, this.squad.list);
    perf.done('hud');
    this._time += dt;
  }

  /** Scroll-wheel switching: cycle every owned weapon (AK → Longshot →
   * Rampart → pistol), wrapping. Mid-switch scrolls advance from the
   * pending target so two fast notches move two slots. */
  _wheelSwitch(dir) {
    const order = gameState.ownedWeapons();
    if (order.length < 2) return;
    const cur = this.weapon._switch?.next ?? gameState.activeWeapon;
    const i = Math.max(0, order.indexOf(cur));
    const step = dir > 0 ? 1 : -1;
    const next = order[(i + step + order.length) % order.length];
    this.weapon.requestSwitch(next);
  }

  render() {
    this.camera.updateMatrixWorld();
    perf.mark('shadow');
    this._updateSunShadow();
    perf.done('shadow');
    const probe = perf.on;
    let tex0 = 0, geo0 = 0, prog0 = 0, up0 = 0, c0 = 0, l0 = 0;
    if (probe) {
      const mem = this.renderer.info.memory;
      tex0 = mem.textures;
      geo0 = mem.geometries;
      prog0 = this.renderer.info.programs ? this.renderer.info.programs.length : 0;
      up0 = this._gpuProbe.tex;
      c0 = this._gpuProbe.compile;
      l0 = this._gpuProbe.link;
    }
    perf.mark('render');
    this.pipeline.render(this.scene, this.camera, this._time);
    perf.done('render');
    if (probe) {
      const mem = this.renderer.info.memory;
      const acc = perf.acc;
      acc.refit = this._shadowRefit;
      acc.shUp = this._shadowUpdated;
      acc.dTex = mem.textures - tex0;
      acc.dGeo = mem.geometries - geo0;
      acc.dProg = (this.renderer.info.programs ? this.renderer.info.programs.length : 0) - prog0;
      acc.texUp = this._gpuProbe.tex - up0;
      acc.compile = this._gpuProbe.compile - c0;
      acc.link = this._gpuProbe.link - l0;
      acc.calls = this.pipeline._calls;
    }
    this._sceneCalls = this.pipeline._calls;
    this._sceneTris = this.pipeline._tris;
  }

  renderOnce() {
    this._shadowForce = true;
    this.render();
    this._shadowForce = false;
  }

  begin() {
    if (this.running) return;
    this.running = true;
    if (this.manual) {
      this.player.enabled = false;
      gameState.game.started = true;
      gameState.game.isPlaying = true;
      if (!gameState.game.startedAt) gameState.game.startedAt = performance.now();
      if (this.lockEl) this.lockEl.hidden = true;
      this.shell?.dismiss();
    }
    this._lastPresent = 0;
    this.clock.getDelta();
    // Bare rAF cadence (autopsy fix 1) plus an optional present cap.
    // Skips do not call getDelta() so the next presented dt is the full
    // interval; look deltas keep accumulating on mousemove. A setTimeout
    // wake covers the case where the compositor throttles rAF because
    // we stopped presenting (headless uncapped, or 60-cap on 200 Hz).
    this.renderer.setAnimationLoop(() => this._frame());
  }

  _keepAlive() {
    if (!this._tick2d) {
      const c = document.createElement('canvas');
      c.width = 1;
      c.height = 1;
      c.setAttribute('aria-hidden', 'true');
      c.style.cssText = 'position:fixed;left:-2px;top:-2px;width:1px;height:1px;opacity:.01;pointer-events:none';
      document.body.appendChild(c);
      this._tick2d = c.getContext('2d');
    }
    this._tick2d.fillRect(0, 0, 1, 1);
  }

  _armWake(delay) {
    if (this._wake) return;
    this._wake = setTimeout(() => {
      this._wake = 0;
      this._frame();
    }, Math.max(0, delay));
  }

  _disarmWake() {
    if (this._wake) {
      clearTimeout(this._wake);
      this._wake = 0;
    }
  }

  _frame() {
    if (this.paused) return;
    const now = performance.now();
    const cap = this._fpsCap;
    if (cap > 0 && this._lastPresent > 0) {
      const earliest = this._lastPresent + 1000 / cap - FPS_EPS_MS;
      if (now < earliest) {
        this._keepAlive();
        this._armWake(earliest - now);
        return;
      }
    }
    this._disarmWake();
    if (this._lastPresent > 0) {
      this._pi[this._piI] = now - this._lastPresent;
      this._piI = (this._piI + 1) & 511;
      if (this._piN < 512) this._piN++;
    }
    this._lastPresent = now;
    const raw = this.clock.getDelta();
    const dt = Math.min(raw, 0.05);
    const t0 = now;
    this.step(dt);
    this.render();
    const ft = performance.now() - t0;
    perf.commit(ft);
    this.frameMs += (ft - this.frameMs) * 0.12;
    this._ft[this._ftI] = ft;
    this._ftI = (this._ftI + 1) & 511;
    if (this._ftN < 512) this._ftN++;
    this._frames++;
    this._fpsT += raw;
    if (this._fpsT >= 0.5) {
      this.fps = this._frames / this._fpsT;
      this._frames = 0;
      this._fpsT = 0;
    }
  }

  setPaused(p) {
    this.paused = !!p;
    if (this.paused) this._disarmWake();
  }

  warp(seconds, stepSize = 1 / 60) {
    const pin = this.manual;
    const x = this.player.pos.x;
    const z = this.player.pos.z;
    const yaw = this.player.yaw;
    const pitch = this.player.pitch;
    for (let t = 0; t < seconds; t += stepSize) this.step(stepSize);
    if (pin) this.player.place(x, 0, z, yaw, pitch);
  }

  place(x, y, z, yaw, pitch) {
    this.player.place(x, y, z, yaw, pitch);
  }

  /* Debug API (plan §11 / tools). setAds(true|false) = hold-ADS stage 0 of
   * the active weapon — for the rifle that is exactly the legacy behavior,
   * preserving the `ads` stop's framing. setAds(n>0) on a stage-cycling
   * weapon (sniper) drives scope stage n directly. */
  setAds(v) {
    const stages = this.weapon.cfg.zoom.stages;
    if (typeof v === 'number' && stages.length > 1) {
      this.weapon.setScope(v);
      gameState.player.fovTarget = v > 0 ? stages[v - 1] : 0;
      this.camera.fov = v > 0 ? stages[v - 1] : CAMERA.FOV;
      this.camera.updateProjectionMatrix();
      return;
    }
    const on = !!v;
    this.weapon.setAds(on);
    this.weapon._ads = on ? 1 : 0;
    this.camera.fov = on ? stages[0] : CAMERA.FOV;
    this.camera.updateProjectionMatrix();
  }

  /** Grant + instantly switch to a weapon (harness/testing, no pickup walk). */
  equip(id) {
    if (!gameState.weapons[id]) return;
    gameState.weapons[id].owned = true;
    this.weapon.equip(id);
    this.player._applyCamera();
  }

  probe(sampleStep = 4) {
    const w = this.renderer.domElement.width, h = this.renderer.domElement.height;
    const gl = this.renderer.getContext();
    const px = new Uint8Array(w * h * 4);
    this.render();
    gl.readPixels(0, 0, w, h, gl.RGBA, gl.UNSIGNED_BYTE, px);
    const lum = [];
    let skyL = 0, skyN = 0, gndL = 0, gndN = 0, black = 0, blown = 0, total = 0;
    for (let j = 0; j < h; j += sampleStep) {
      for (let i = 0; i < w; i += sampleStep) {
        const k = (j * w + i) * 4;
        const l = (px[k] * 0.2126 + px[k + 1] * 0.7152 + px[k + 2] * 0.0722) / 255;
        lum.push(l);
        total++;
        if (l < 0.02) black++;
        if (l > 0.98) blown++;
        if (j > h * 0.62) { skyL += l; skyN++; } else { gndL += l; gndN++; }
      }
    }
    lum.sort((a, b) => a - b);
    const q = (p) => +lum[Math.min(lum.length - 1, Math.floor(p * lum.length))].toFixed(3);
    return {
      p01: q(0.01), p10: q(0.10), median: q(0.5), p90: q(0.90), p99: q(0.99),
      mean: +(lum.reduce((a, b) => a + b, 0) / lum.length).toFixed(3),
      contrast: +((q(0.95) - q(0.05)) * 255).toFixed(0),
      blackPct: +(100 * black / total).toFixed(1),
      blownPct: +(100 * blown / total).toFixed(1),
      upper: +(skyL / Math.max(1, skyN)).toFixed(3),
      lower: +(gndL / Math.max(1, gndN)).toFixed(3),
    };
  }

  frameStats() {
    const n = this._ftN;
    if (!n) return { n: 0, p50: 0, p95: 0, p99: 0, mean: 0 };
    const a = Array.from(this._ft.subarray(0, n)).sort((x, y) => x - y);
    const q = (p) => +a[Math.min(n - 1, Math.floor(p * (n - 1)))].toFixed(3);
    let sum = 0;
    for (let i = 0; i < n; i++) sum += a[i];
    return { n, p50: q(0.5), p95: q(0.95), p99: q(0.99), mean: +(sum / n).toFixed(3) };
  }

  /* Inter-present intervals (ms) — pacing regularity, not GPU work time. */
  paceStats() {
    const n = this._piN;
    if (!n) return { n: 0, p50: 0, p95: 0, p99: 0, mean: 0, std: 0 };
    const a = Array.from(this._pi.subarray(0, n)).sort((x, y) => x - y);
    const q = (p) => +a[Math.min(n - 1, Math.floor(p * (n - 1)))].toFixed(3);
    let sum = 0;
    for (let i = 0; i < n; i++) sum += a[i];
    const mean = sum / n;
    let varSum = 0;
    for (let i = 0; i < n; i++) {
      const d = a[i] - mean;
      varSum += d * d;
    }
    return {
      n, p50: q(0.5), p95: q(0.95), p99: q(0.99),
      mean: +mean.toFixed(3),
      std: +Math.sqrt(varSum / n).toFixed(3),
    };
  }

  info() {
    const i = this.renderer.info;
    const mem = typeof performance !== 'undefined' && performance.memory;
    return {
      calls: this._sceneCalls ?? i.render.calls,
      triangles: this._sceneTris ?? i.render.triangles,
      geometries: i.memory.geometries,
      textures: i.memory.textures,
      programs: i.programs ? i.programs.length : 0,
      quality: this._quality,
      shadowSize: this.sun?.shadow.mapSize.x ?? 0,
      shadowCadence: this._shadowCadence,
      shadowAutoUpdate: this.sun ? this.sun.shadow.autoUpdate : true,
      msaa: this.pipeline?._msaa ?? 4,
      shadow: this._shadowBox || null,
      heap: mem ? mem.usedJSHeapSize : 0,
      vfxLive: this.vfx ? this.vfx.impacts.length : 0,
      vfxCreated: this.vfx ? { ...this.vfx.created } : null,
    };
  }
}
