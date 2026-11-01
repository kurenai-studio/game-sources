/* Game: owns the renderer, scene, camera, lights, input, the
   menu -> playing -> finished state machine, respawns and the timer. */
'use strict';

class Game {
  constructor() {
    const container = document.getElementById('game-container');

    this.renderer = new THREE.WebGLRenderer({ antialias: true }); // throws if WebGL is unavailable
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.outputEncoding = THREE.sRGBEncoding;
    container.appendChild(this.renderer.domElement);

    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.Fog(0xbfe9ff, 55, 190);

    this.camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
    this.camOffset = new THREE.Vector3(0, 4.4, 7.4);
    this.camLook = new THREE.Vector3();
    this.fovTarget = 60;

    const hemi = new THREE.HemisphereLight(0xbfe9ff, 0xffd9c4, 0.75);
    this.scene.add(hemi);

    this.sun = new THREE.DirectionalLight(0xffffff, 0.95);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(2048, 2048);
    this.sun.shadow.camera.left = -20;
    this.sun.shadow.camera.right = 20;
    this.sun.shadow.camera.top = 20;
    this.sun.shadow.camera.bottom = -20;
    this.sun.shadow.camera.near = 1;
    this.sun.shadow.camera.far = 45;
    this.sun.shadow.bias = -0.0005;
    this.scene.add(this.sun);
    this.scene.add(this.sun.target);

    this.effects = new Effects(this.scene);
    this.course = new Course(this.scene);
    this.player = new Player(this.scene);
    this.ui = new UI();
    this.audio = new GameAudio();

    this.state = 'menu';           // 'menu' | 'playing' | 'finished'
    this.time = 0;
    this.t = 0;
    this.cpCount = 0;
    this.spawnPos = this.course.startSpawn.clone();
    this.inputLock = 0;
    this.finishFxT = 0;
    this.snapCamera = true;
    this.keys = {};

    this.best = null;
    try {
      const stored = window.localStorage.getItem('wobbleRushBest');
      if (stored !== null) {
        const v = parseFloat(stored);
        if (isFinite(v)) this.best = v;
      }
    } catch (e) { /* storage unavailable (private mode etc.) — best time just won't persist */ }

    this.player.respawn(this.course.startSpawn);
    this.camera.position.copy(this.player.pos).add(this.camOffset);
    this.camLook.copy(this.player.pos).add(new THREE.Vector3(0, 1.4, -3));

    this.ui.onPlay(() => this.start());
    this.ui.onRestart(() => this.start());
    this.bindInput();

    window.addEventListener('resize', () => {
      this.camera.aspect = window.innerWidth / window.innerHeight;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(window.innerWidth, window.innerHeight);
    });

    this.last = 0;
    this.loop = this.loop.bind(this);
  }

  boot() {
    this.ui.showStart();
    requestAnimationFrame(this.loop);
  }

  /* ---------------- state changes ---------------- */

  start() {
    this.audio.ensure();
    this.state = 'playing';
    this.time = 0;
    this.cpCount = 0;
    this.finishFxT = 0;
    this.spawnPos.copy(this.course.startSpawn);
    this.course.reset();
    this.player.respawn(this.course.startSpawn);
    this.inputLock = 0.35;
    this.snapCamera = true;
    this.ui.showHUD();
    this.ui.hideFinish();
    this.ui.setTimer(0);
    this.ui.setCheckpoints(0, this.course.checkpoints.length);
    this.ui.showBestHUD(this.best);
    this.ui.flash('GO!');
  }

  respawnAtCheckpoint() {
    this.player.respawn(this.spawnPos);
    this.effects.respawn(this.spawnPos);
    this.audio.respawn();
    this.inputLock = 0.3;
    this.snapCamera = true;
  }

  finish() {
    this.state = 'finished';
    this.finishFxT = 1.8;
    const t = this.time;
    const isNewBest = this.best === null || t < this.best;
    if (isNewBest) {
      this.best = t;
      try { window.localStorage.setItem('wobbleRushBest', String(t)); } catch (e) { /* ignore */ }
    }
    this.audio.finish();
    this.ui.showBestHUD(this.best);
    // brief delay so the confetti is visible before the card pops in
    setTimeout(() => {
      if (this.state === 'finished') this.ui.showFinish(t, this.best, isNewBest);
    }, 900);
  }

  /* ---------------- input ---------------- */

  bindInput() {
    window.addEventListener('keydown', (e) => {
      if (e.code === 'Space' || e.code.indexOf('Arrow') === 0) e.preventDefault();
      this.keys[e.code] = true;
      if (e.repeat) return;
      switch (e.code) {
        case 'Space':
          if (this.state === 'playing') this.player.requestJump();
          else if (this.state === 'menu') this.start();
          break;
        case 'ShiftLeft':
        case 'ShiftRight':
          if (this.state === 'playing') this.player.requestDive();
          break;
        case 'KeyR':
          if (this.state === 'playing') this.respawnAtCheckpoint();
          else if (this.state === 'finished') this.start();
          break;
        case 'Enter':
          if (this.state !== 'playing') this.start();
          break;
      }
    });
    window.addEventListener('keyup', (e) => { this.keys[e.code] = false; });
    window.addEventListener('blur', () => { this.keys = {}; });
  }

  readInput() {
    const k = this.keys;
    return {
      x: ((k.KeyD || k.ArrowRight) ? 1 : 0) - ((k.KeyA || k.ArrowLeft) ? 1 : 0),
      z: ((k.KeyS || k.ArrowDown) ? 1 : 0) - ((k.KeyW || k.ArrowUp) ? 1 : 0)
    };
  }

  /* ---------------- per-frame ---------------- */

  loop(ts) {
    requestAnimationFrame(this.loop);
    const dt = Math.min(this.last ? (ts - this.last) / 1000 : 0.016, 0.05);
    this.last = ts;
    this.t += dt;

    if (this.state === 'playing') {
      this.time += dt;
      this.ui.setTimer(this.time);
    }

    this.course.update(dt, this.t);

    if (this.inputLock > 0) this.inputLock -= dt;
    const input = (this.state === 'playing' && this.inputLock <= 0)
      ? this.readInput()
      : { x: 0, z: 0 };
    this.player.update(dt, input, this.course, { effects: this.effects, audio: this.audio });

    if (this.state === 'playing') {
      // checkpoints
      for (const cp of this.course.checkpoints) {
        if (cp.check(this.player) && cp.index > this.cpCount) {
          this.cpCount = cp.index;
          cp.activate();
          this.spawnPos.copy(cp.spawnPos);
          const fxPos = cp.pos.clone();
          fxPos.y += 0.5;
          this.effects.checkpoint(fxPos);
          this.audio.checkpoint();
          this.ui.setCheckpoints(this.cpCount, this.course.checkpoints.length);
          this.ui.toast('CHECKPOINT ' + cp.index + '!');
        }
      }
      // finish
      if (this.course.finishGate.checkFinish(this.player)) this.finish();
      // fell off the course
      if (this.player.pos.y < this.course.killY || !isFinite(this.player.pos.y)) {
        this.respawnAtCheckpoint();
      }
    }

    if (this.state === 'finished' && this.finishFxT > 0) {
      this.finishFxT -= dt;
      const p = this.player.pos.clone();
      p.y += 1;
      this.effects.finish(p);
      const gp = this.course.finishGate.group.position;
      this.effects.finish(new THREE.Vector3(gp.x - 3, gp.y + 4, gp.z));
      this.effects.finish(new THREE.Vector3(gp.x + 3, gp.y + 4, gp.z));
    }

    this.updateCamera(dt);
    this.effects.update(dt);
    this.renderer.render(this.scene, this.camera);
  }

  updateCamera(dt) {
    const p = this.player.pos;
    const desired = new THREE.Vector3(p.x + this.camOffset.x, p.y + this.camOffset.y, p.z + this.camOffset.z);
    const look = new THREE.Vector3(p.x, p.y + 1.4, p.z - 3);
    if (this.snapCamera) {
      this.camera.position.copy(desired);
      this.camLook.copy(look);
      this.snapCamera = false;
    } else {
      this.camera.position.x = WRUtils.damp(this.camera.position.x, desired.x, 5, dt);
      this.camera.position.y = WRUtils.damp(this.camera.position.y, desired.y, 5, dt);
      this.camera.position.z = WRUtils.damp(this.camera.position.z, desired.z, 5, dt);
      this.camLook.x = WRUtils.damp(this.camLook.x, look.x, 9, dt);
      this.camLook.y = WRUtils.damp(this.camLook.y, look.y, 9, dt);
      this.camLook.z = WRUtils.damp(this.camLook.z, look.z, 9, dt);
    }
    this.camera.lookAt(this.camLook);

    // subtle speed kick while diving
    this.fovTarget = (this.player.diving && !this.player.grounded) ? 68 : 60;
    if (Math.abs(this.camera.fov - this.fovTarget) > 0.05) {
      this.camera.fov = WRUtils.damp(this.camera.fov, this.fovTarget, 6, dt);
      this.camera.updateProjectionMatrix();
    }

    // shadow light follows the player
    this.sun.position.set(p.x + 6, p.y + 13, p.z + 5);
    this.sun.target.position.set(p.x, p.y, p.z);
    this.sun.target.updateMatrixWorld();
  }
}
