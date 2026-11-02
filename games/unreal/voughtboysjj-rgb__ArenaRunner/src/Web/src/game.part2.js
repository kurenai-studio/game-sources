// Arena Runner — WebGL edition (part 2: enemies, waves, upgrades, HUD, input, loop)

// =============================================================================
// 9. Audio — procedural, no asset files
// =============================================================================
var audioCtx = null;

function initAudio() {
  if (audioCtx) return;
  try {
    var Ctx = window.AudioContext || window.webkitAudioContext;
    if (Ctx) audioCtx = new Ctx();
  } catch (e) { audioCtx = null; }
}

function tone(freq, dur, type, gain, slideTo) {
  if (!audioCtx) return;
  try {
    var t0 = audioCtx.currentTime;
    var osc = audioCtx.createOscillator();
    var amp = audioCtx.createGain();
    osc.type = type || 'sine';
    osc.frequency.setValueAtTime(freq, t0);
    if (slideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(20, slideTo), t0 + dur);
    amp.gain.setValueAtTime(0.0001, t0);
    amp.gain.exponentialRampToValueAtTime(gain || 0.05, t0 + 0.012);
    amp.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(amp).connect(audioCtx.destination);
    osc.start(t0);
    osc.stop(t0 + dur + 0.03);
  } catch (e) { /* ignore */ }
}

function noiseBurst(dur, gain, filterFreq) {
  if (!audioCtx) return;
  try {
    var t0 = audioCtx.currentTime;
    var len = Math.floor(audioCtx.sampleRate * dur);
    var buf = audioCtx.createBuffer(1, len, audioCtx.sampleRate);
    var data = buf.getChannelData(0);
    for (var i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / len);
    var src = audioCtx.createBufferSource();
    src.buffer = buf;
    var filter = audioCtx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = filterFreq || 1200;
    var amp = audioCtx.createGain();
    amp.gain.value = gain || 0.05;
    src.connect(filter).connect(amp).connect(audioCtx.destination);
    src.start(t0);
  } catch (e) { /* ignore */ }
}

function sfxPickup() { tone(760, 0.10, 'triangle', 0.045, 1180); tone(1520, 0.09, 'sine', 0.025); }
function sfxWave() { tone(392, 0.16, 'square', 0.035); setTimeout(function () { tone(587, 0.2, 'square', 0.035); }, 120); setTimeout(function () { tone(784, 0.26, 'square', 0.03); }, 240); }
function sfxHurt() { tone(180, 0.18, 'sawtooth', 0.06, 90); noiseBurst(0.14, 0.05, 900); }
function sfxDeath() { tone(220, 0.5, 'sawtooth', 0.07, 60); noiseBurst(0.5, 0.06, 500); }
function sfxHit(heavy) { noiseBurst(0.09, heavy ? 0.075 : 0.05, heavy ? 700 : 1400); tone(heavy ? 120 : 220, 0.09, 'square', 0.035, heavy ? 70 : 160); }
function sfxSwing() { noiseBurst(0.06, 0.022, 2600); }
function sfxDash() { tone(520, 0.12, 'sine', 0.035, 220); noiseBurst(0.12, 0.03, 1800); }
function sfxJump() { tone(420, 0.1, 'sine', 0.028, 620); }
function sfxKill() { tone(150, 0.16, 'square', 0.045, 80); noiseBurst(0.16, 0.045, 800); }
function sfxBoss() { tone(70, 0.9, 'sawtooth', 0.07, 45); noiseBurst(0.8, 0.05, 300); }
function sfxUpgrade() { tone(523, 0.12, 'triangle', 0.04); setTimeout(function () { tone(784, 0.16, 'triangle', 0.04); }, 110); setTimeout(function () { tone(1046, 0.22, 'triangle', 0.035); }, 220); }

// =============================================================================
// 10. Enemies
// =============================================================================
function makeHunterMesh() {
  var g = new THREE.Group();
  var core = new THREE.MeshStandardMaterial({
    color: 0x8f160c, emissive: 0xff3a1a, emissiveIntensity: 1.5, roughness: 0.35, metalness: 0.4
  });
  var body = new THREE.Mesh(new THREE.SphereGeometry(0.55, 20, 16), core);
  body.castShadow = true;
  g.add(body);
  var ring = new THREE.Mesh(
    new THREE.TorusGeometry(0.82, 0.035, 8, 36),
    new THREE.MeshBasicMaterial({ color: 0xff7a33, transparent: true, opacity: 0.9 })
  );
  ring.rotation.x = Math.PI / 2;
  g.add(ring);
  return { group: g, ring: ring, body: body, material: core };
}

function makeChargerMesh() {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x8a4a08, emissive: 0xff9a20, emissiveIntensity: 1.2, roughness: 0.42, metalness: 0.45
  });
  var body = new THREE.Mesh(new THREE.OctahedronGeometry(0.62, 0), mat);
  body.castShadow = true;
  g.add(body);
  for (var i = 0; i < 3; i++) {
    var spike = new THREE.Mesh(new THREE.ConeGeometry(0.13, 0.5, 8), mat);
    var a = (TAU * i) / 3;
    spike.position.set(Math.cos(a) * 0.42, 0.1, Math.sin(a) * 0.42);
    spike.rotation.z = Math.PI / 2;
    spike.rotation.y = -a;
    g.add(spike);
  }
  var ring = new THREE.Mesh(
    new THREE.TorusGeometry(0.9, 0.03, 8, 32),
    new THREE.MeshBasicMaterial({ color: 0xffb066, transparent: true, opacity: 0.75 })
  );
  ring.rotation.x = Math.PI / 2;
  g.add(ring);
  return { group: g, ring: ring, body: body, material: mat };
}

function makeSpitterMesh() {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x4a1460, emissive: 0xc23bff, emissiveIntensity: 1.35, roughness: 0.3, metalness: 0.5
  });
  var body = new THREE.Mesh(new THREE.IcosahedronGeometry(0.5, 0), mat);
  body.castShadow = true;
  g.add(body);
  var orbits = [];
  for (var i = 0; i < 3; i++) {
    var orb = new THREE.Mesh(
      new THREE.SphereGeometry(0.09, 8, 6),
      new THREE.MeshBasicMaterial({ color: 0xf0a6ff })
    );
    g.add(orb);
    orbits.push(orb);
  }
  return { group: g, orbits: orbits, body: body, material: mat };
}

function makeBossMesh() {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x3a0a14, emissive: 0xff1f4a, emissiveIntensity: 1.25, roughness: 0.35, metalness: 0.6
  });
  var core = new THREE.Mesh(new THREE.SphereGeometry(1.25, 28, 22), mat);
  core.castShadow = true;
  g.add(core);

  var ringA = new THREE.Mesh(
    new THREE.TorusGeometry(1.85, 0.09, 10, 64),
    new THREE.MeshBasicMaterial({ color: 0xff6a8a, transparent: true, opacity: 0.85 })
  );
  ringA.rotation.x = Math.PI / 2.4;
  g.add(ringA);

  var ringB = new THREE.Mesh(
    new THREE.TorusGeometry(2.15, 0.05, 8, 64),
    new THREE.MeshBasicMaterial({ color: 0xffb04a, transparent: true, opacity: 0.6 })
  );
  ringB.rotation.x = Math.PI / 1.7;
  g.add(ringB);

  var crown = new THREE.Group();
  for (var i = 0; i < 6; i++) {
    var spike = new THREE.Mesh(new THREE.ConeGeometry(0.16, 0.75, 8), mat);
    var a = (TAU * i) / 6;
    spike.position.set(Math.cos(a) * 1.15, 0.85, Math.sin(a) * 1.15);
    spike.rotation.z = -Math.cos(a) * 0.4;
    spike.rotation.x = Math.sin(a) * 0.4;
    crown.add(spike);
  }
  g.add(crown);

  return { group: g, ringA: ringA, ringB: ringB, crown: crown, body: core, material: mat };
}

function Enemy(type, x, z) {
  this.type = type;
  this.pos = new THREE.Vector3(x, 0, z);
  this.vel = new THREE.Vector3();
  this.hitFlash = 0;
  this.dead = false;
  this.t = rand(0, 10);
  this.state = 'idle';
  this.stateTimer = 0;
  this.attackTimer = rand(0.6, 2.0);

  if (type === 'hunter') {
    this.radius = CFG.hunterRadius;
    this.hp = this.maxHp = CFG.hunterHp + Math.max(0, game.wave - 1) * 5;
    this.speed = CFG.hunterSpeed + Math.max(0, game.wave - 1) * 0.07;
    this.damage = CFG.hunterDamage;
    this.score = CFG.hunterScore;
    this.mesh = makeHunterMesh();
    this.hover = 1.05;
  } else if (type === 'charger') {
    this.radius = CFG.chargerRadius;
    this.hp = this.maxHp = CFG.chargerHp + Math.max(0, game.wave - 1) * 9;
    this.speed = CFG.chargerSpeed;
    this.damage = CFG.chargerDamage;
    this.score = CFG.chargerScore;
    this.mesh = makeChargerMesh();
    this.hover = 0.85;
  } else if (type === 'spitter') {
    this.radius = CFG.spitterRadius;
    this.hp = this.maxHp = CFG.spitterHp + Math.max(0, game.wave - 1) * 7;
    this.speed = CFG.spitterSpeed;
    this.damage = CFG.spitterDamage;
    this.score = CFG.spitterScore;
    this.mesh = makeSpitterMesh();
    this.hover = 1.35;
  } else {
    this.radius = CFG.bossRadius;
    this.hp = this.maxHp = CFG.bossHp + Math.max(0, game.wave - CFG.bossEvery) * 120;
    this.speed = CFG.bossSpeed;
    this.damage = CFG.bossDamage;
    this.score = CFG.bossScore;
    this.mesh = makeBossMesh();
    this.hover = 1.9;
    this.shockTimer = 3.2;
    this.summonTimer = 6.5;
    this.state = 'idle';
  }

  this.mesh.group.position.copy(this.pos);
  scene.add(this.mesh.group);
}

Enemy.prototype.hurt = function (amount, fromX, fromZ, heavy) {
  if (this.dead) return;
  this.hp -= amount;
  this.hitFlash = 1;

  var dx = this.pos.x - fromX;
  var dz = this.pos.z - fromZ;
  var len = Math.hypot(dx, dz) || 1;
  var push = heavy ? 4.2 : 2.4;
  if (this.type !== 'boss') {
    this.vel.x += (dx / len) * push;
    this.vel.z += (dz / len) * push;
  }

  FX.burst(new THREE.Vector3(this.pos.x, this.hover, this.pos.z), this.type === 'boss' ? 0xff5c7a : 0xffd08a, 10,
    { speed: 5, size: 0.42, life: 0.35, gravity: 6 });

  if (this.hp <= 0) this.kill();
};

Enemy.prototype.kill = function () {
  if (this.dead) return;
  this.dead = true;
  scene.remove(this.mesh.group);

  var color = this.type === 'boss' ? 0xff4a7a : (this.type === 'charger' ? 0xffa347 : (this.type === 'spitter' ? 0xd06bff : 0xff6a4a));
  FX.burst(new THREE.Vector3(this.pos.x, this.hover, this.pos.z), color, this.type === 'boss' ? 160 : 26,
    { speed: this.type === 'boss' ? 12 : 7, size: this.type === 'boss' ? 1.0 : 0.55, life: this.type === 'boss' ? 1.3 : 0.6, gravity: 7 });

  addComboKill(this);
  game.score += Math.round(this.score * game.comboMult);
  sfxKill();
  game.shake = Math.min(1.4, game.shake + (this.type === 'boss' ? 1.2 : 0.18));
  game.hitStop = Math.max(game.hitStop, this.type === 'boss' ? 0.22 : 0.07);

  if (this.type === 'boss') {
    game.boss = null;
    setBossBar(null);
    showMessage('WARDEN DESTROYED', '#ffd166', 2.6);
    arenaPulse(0xff6a8a);
    onWaveCleared();
  }

  // small chance to drop health
  if (Math.random() < 0.16 && player.stats.health < player.stats.maxHealth) {
    player.stats.health = Math.min(player.stats.maxHealth, player.stats.health + 8);
    FX.burst(new THREE.Vector3(player.pos.x, player.pos.y + 1, player.pos.z), 0x4dffa6, 12, { speed: 2, size: 0.4, life: 0.6, gravity: -2 });
  }
};

Enemy.prototype.update = function (dt) {
  if (this.dead) return;

  this.t += dt;
  this.hitFlash = Math.max(0, this.hitFlash - dt * 4);

  var dx = player.pos.x - this.pos.x;
  var dz = player.pos.z - this.pos.z;
  var dist = Math.hypot(dx, dz) || 0.0001;
  var nx = dx / dist;
  var nz = dz / dist;

  var desiredX = 0;
  var desiredZ = 0;

  if (this.type === 'hunter') {
    desiredX = nx * this.speed;
    desiredZ = nz * this.speed;
  } else if (this.type === 'charger') {
    this.stateTimer -= dt;

    if (this.state === 'idle') {
      desiredX = nx * this.speed;
      desiredZ = nz * this.speed;
      if (dist < 9 && this.stateTimer <= 0) {
        this.state = 'wind';
        this.stateTimer = 0.75;
        this.targetX = player.pos.x;
        this.targetZ = player.pos.z;
      }
    } else if (this.state === 'wind') {
      desiredX = 0;
      desiredZ = 0;
      if (this.stateTimer <= 0) {
        this.state = 'dash';
        this.stateTimer = 0.45;
        var ax = this.targetX - this.pos.x;
        var az = this.targetZ - this.pos.z;
        var al = Math.hypot(ax, az) || 1;
        this.dirX = ax / al;
        this.dirZ = az / al;
        sfxSwing();
      }
    } else if (this.state === 'dash') {
      desiredX = this.dirX * CFG.chargerDash;
      desiredZ = this.dirZ * CFG.chargerDash;
      if (Math.random() < dt * 40) {
        FX.stream(new THREE.Vector3(this.pos.x, 0.4, this.pos.z), 0xffa347, dt, { rate: 40, size: 0.4, life: 0.28, gravity: 0 });
      }
      if (this.stateTimer <= 0) {
        this.state = 'recover';
        this.stateTimer = 0.9;
      }
    } else {
      desiredX = -nx * this.speed * 0.4;
      desiredZ = -nz * this.speed * 0.4;
      if (this.stateTimer <= 0) {
        this.state = 'idle';
        this.stateTimer = 0.2;
      }
    }
  } else if (this.type === 'spitter') {
    var want = 10.5;
    if (dist > want + 1.5) {
      desiredX = nx * this.speed;
      desiredZ = nz * this.speed;
    } else if (dist < want - 1.5) {
      desiredX = -nx * this.speed;
      desiredZ = -nz * this.speed;
    }
    // strafe
    desiredX += -nz * this.speed * 0.45;
    desiredZ += nx * this.speed * 0.45;

    this.attackTimer -= dt;
    if (this.attackTimer <= 0 && dist < 22) {
      this.attackTimer = Math.max(1.1, 2.5 - game.wave * 0.06);
      fireProjectile(this.pos.x, this.hover, this.pos.z, nx, nz, this.damage);
    }
  } else if (this.type === 'boss') {
    desiredX = nx * this.speed;
    desiredZ = nz * this.speed;

    this.shockTimer -= dt;
    this.summonTimer -= dt;

    if (this.shockTimer <= 0) {
      this.shockTimer = Math.max(2.6, 4.6 - game.wave * 0.05);
      spawnShockwave(this.pos.x, this.pos.z, this.damage * 0.8);
      fxRing(this.pos.x, this.pos.z, 0xff4a6a, 0.09);
      sfxBoss();
      game.shake = Math.min(1.5, game.shake + 0.5);
    }

    if (this.summonTimer <= 0) {
      this.summonTimer = Math.max(6, 9 - game.wave * 0.1);
      for (var s = 0; s < 3; s++) {
        var a = rand(0, TAU);
        var sx = this.pos.x + Math.cos(a) * 3.2;
        var sz = this.pos.z + Math.sin(a) * 3.2;
        var lim = CFG.arenaRadius - 1.5;
        var fl = Math.hypot(sx, sz);
        if (fl > lim) { sx *= lim / fl; sz *= lim / fl; }
        enemies.push(new Enemy('hunter', sx, sz));
        FX.burst(new THREE.Vector3(sx, 1, sz), 0xff4a3a, 14, { speed: 4, size: 0.5, life: 0.5 });
      }
      showMessage('WARDEN SUMMONS', '#ff8fa6', 1.4);
    }
  }

  // steering + separation
  this.vel.x = damp(this.vel.x, desiredX, 6, dt);
  this.vel.z = damp(this.vel.z, desiredZ, 6, dt);

  for (var i = 0; i < enemies.length; i++) {
    var o = enemies[i];
    if (o === this || o.dead) continue;
    var ox = this.pos.x - o.pos.x;
    var oz = this.pos.z - o.pos.z;
    var od = Math.hypot(ox, oz);
    var minD = this.radius + o.radius;
    if (od > 0.0001 && od < minD) {
      var push = (minD - od) * 3.0;
      this.vel.x += (ox / od) * push;
      this.vel.z += (oz / od) * push;
    }
  }

  this.pos.x += this.vel.x * dt;
  this.pos.z += this.vel.z * dt;

  var lim = CFG.arenaRadius - this.radius - 0.3;
  var flat = Math.hypot(this.pos.x, this.pos.z);
  if (flat > lim) {
    this.pos.x *= lim / flat;
    this.pos.z *= lim / flat;
  }

  // pillars are solid
  for (var p = 0; p < arena.pillars.length; p++) {
    var pil = arena.pillars[p];
    var px = this.pos.x - pil.x;
    var pz = this.pos.z - pil.z;
    var pd = Math.hypot(px, pz);
    var minP = pil.r + this.radius;
    if (pd < minP && pd > 0.0001) {
      this.pos.x = pil.x + (px / pd) * minP;
      this.pos.z = pil.z + (pz / pd) * minP;
    }
  }

  // visuals
  var hover = this.hover + Math.sin(this.t * 2.4) * (this.type === 'boss' ? 0.22 : 0.09);
  this.mesh.group.position.set(this.pos.x, hover, this.pos.z);

  if (this.mesh.ring) this.mesh.ring.rotation.z += dt * (this.type === 'boss' ? 1.4 : 3.0);
  if (this.mesh.orbits) {
    for (var k = 0; k < this.mesh.orbits.length; k++) {
      var oa = this.t * 2.2 + (TAU * k) / 3;
      this.mesh.orbits[k].position.set(Math.cos(oa) * 0.85, Math.sin(oa * 1.3) * 0.3, Math.sin(oa) * 0.85);
    }
  }
  if (this.mesh.ringA) {
    this.mesh.ringA.rotation.z += dt * 0.9;
    this.mesh.ringB.rotation.z -= dt * 1.4;
    this.mesh.crown.rotation.y += dt * 0.6;
  }

  // hit flash / telegraph glow
  var mat = this.mesh.material;
  if (mat) {
    var base = this.type === 'hunter' ? 1.5 : (this.type === 'charger' ? 1.2 : (this.type === 'spitter' ? 1.35 : 1.25));
    var extra = this.hitFlash * 3.2;
    if (this.type === 'charger' && this.state === 'wind') {
      var pulse = 0.5 + 0.5 * Math.sin(this.t * 26);
      extra += pulse * 2.4;
      this.mesh.group.scale.setScalar(1 + pulse * 0.12);
    } else if (this.mesh.group.scale.x !== 1) {
      this.mesh.group.scale.setScalar(damp(this.mesh.group.scale.x, 1, 12, dt));
    }
    mat.emissiveIntensity = base + extra;
  }

  // contact damage
  if (this.type !== 'spitter') {
    var touch = this.radius + CFG.playerRadius + 0.15;
    if (dist < touch) {
      player.hurt(this.damage, this.pos.x, this.pos.z);
    }
  }
};

// ---- projectiles -----------------------------------------------------------
var orbGeo = new THREE.SphereGeometry(0.22, 12, 10);
var orbMat = new THREE.MeshBasicMaterial({ color: 0xe58cff });

function fireProjectile(x, y, z, nx, nz, damage) {
  var mesh = new THREE.Mesh(orbGeo, orbMat);
  mesh.position.set(x, y, z);
  var spr = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTex, color: 0xd06bff, transparent: true, opacity: 0.9,
    blending: THREE.AdditiveBlending, depthWrite: false
  }));
  spr.scale.set(1.4, 1.4, 1);
  mesh.add(spr);
  scene.add(mesh);

  projectiles.push({
    mesh: mesh, pos: new THREE.Vector3(x, y, z),
    vel: new THREE.Vector3(nx * 9.5, 0, nz * 9.5),
    damage: damage, life: 4.5
  });
  tone(300, 0.12, 'sine', 0.03, 520);
}

function updateProjectiles(dt) {
  for (var i = projectiles.length - 1; i >= 0; i--) {
    var p = projectiles[i];
    p.life -= dt;
    p.pos.addScaledVector(p.vel, dt);
    p.mesh.position.copy(p.pos);

    FX.stream(p.pos, 0xc06bff, dt, { rate: 30, size: 0.28, life: 0.25, gravity: 0 });

    var hitPlayer = Math.hypot(p.pos.x - player.pos.x, p.pos.z - player.pos.z) < 0.72 &&
      Math.abs(p.pos.y - (player.pos.y + 1.0)) < 1.3;

    var outOfArena = Math.hypot(p.pos.x, p.pos.z) > CFG.arenaRadius - 0.4;

    if (hitPlayer) {
      player.hurt(p.damage, p.pos.x, p.pos.z);
      FX.burst(p.pos, 0xc06bff, 18, { speed: 5, size: 0.45, life: 0.4 });
    }

    if (hitPlayer || outOfArena || p.life <= 0) {
      scene.remove(p.mesh);
      projectiles.splice(i, 1);
    }
  }
}

// ---- boss shockwave --------------------------------------------------------
var shockwaves = [];

function spawnShockwave(x, z, damage) {
  var ring = new THREE.Mesh(
    new THREE.RingGeometry(0.9, 1.15, 72),
    new THREE.MeshBasicMaterial({ color: 0xff3f6a, transparent: true, opacity: 0.9, side: THREE.DoubleSide, blending: THREE.AdditiveBlending })
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.set(x, 0.08, z);
  scene.add(ring);
  shockwaves.push({ mesh: ring, x: x, z: z, r: 1.0, speed: 11, damage: damage, hit: false, life: 1.8 });
}

function updateShockwaves(dt) {
  for (var i = shockwaves.length - 1; i >= 0; i--) {
    var s = shockwaves[i];
    s.r += s.speed * dt;
    s.life -= dt;
    s.mesh.scale.setScalar(s.r);
    s.mesh.material.opacity = clamp(s.life / 1.8, 0, 1) * 0.9;

    var d = Math.hypot(player.pos.x - s.x, player.pos.z - s.z);
    if (!s.hit && Math.abs(d - s.r * 0.95) < 1.0 && player.pos.y < 1.2) {
      s.hit = true;
      player.hurt(s.damage, s.x, s.z);
      FX.burst(new THREE.Vector3(player.pos.x, 0.6, player.pos.z), 0xff4a6a, 20, { speed: 6, size: 0.55, life: 0.5 });
    }

    if (s.life <= 0) {
      scene.remove(s.mesh);
      shockwaves.splice(i, 1);
    }
  }
}

// =============================================================================
// 11. Cores
// =============================================================================
var coreGeo = new THREE.OctahedronGeometry(0.42, 0);
var haloGeo = new THREE.TorusGeometry(0.72, 0.03, 8, 48);

function spawnCore(x, z) {
  var g = new THREE.Group();
  var mat = new THREE.MeshStandardMaterial({
    color: 0x0d8f88, emissive: 0x2afff0, emissiveIntensity: 1.6, roughness: 0.2, metalness: 0.5
  });
  var gem = new THREE.Mesh(coreGeo, mat);
  gem.castShadow = true;
  g.add(gem);

  var halo = new THREE.Mesh(haloGeo, new THREE.MeshBasicMaterial({ color: 0x9bfcff, transparent: true, opacity: 0.85 }));
  halo.rotation.x = Math.PI / 2;
  g.add(halo);

  var spr = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTex, color: 0x35f5e8, transparent: true, opacity: 0.8,
    blending: THREE.AdditiveBlending, depthWrite: false
  }));
  spr.scale.set(2.6, 2.6, 1);
  g.add(spr);

  g.position.set(x, 1.25, z);
  scene.add(g);

  cores.push({ group: g, gem: gem, halo: halo, baseY: 1.25, phase: rand(0, TAU), x: x, z: z });
}

function updateCores(dt) {
  for (var i = cores.length - 1; i >= 0; i--) {
    var c = cores[i];
    c.phase += dt;
    c.group.position.y = c.baseY + Math.sin(c.phase * 2.2) * 0.16;
    c.gem.rotation.y += dt * 2.6;
    c.gem.rotation.x += dt * 1.1;
    c.halo.rotation.z += dt * 1.8;

    if (player.dead) continue;

    var d = Math.hypot(player.pos.x - c.x, player.pos.z - c.z);
    if (d < 1.15 && Math.abs((player.pos.y + 0.9) - c.group.position.y) < 1.7) {
      scene.remove(c.group);
      cores.splice(i, 1);
      game.cores++;
      game.score += CFG.scorePerCore;
      arenaPulse(0x54e8ff);
      sfxPickup();
      FX.burst(c.group.position.clone(), 0x5ff0e6, 22, { speed: 5.5, size: 0.45, life: 0.5, gravity: 3 });
      showMessage('CORE ' + game.cores + ' / ' + game.coresTotal, '#6fe9ff', 0.9);

      if (cores.length === 0) onWaveCleared();
    }
  }
}

// =============================================================================
// 12. Combo
// =============================================================================
function addComboKill(enemy) {
  game.combo++;
  game.comboTimer = player.stats.comboWindow;
  game.comboMult = Math.min(CFG.comboMax, 1 + game.combo * CFG.comboStep);
  if (game.combo >= 3) {
    showMessage('x' + game.comboMult.toFixed(1) + '  ' + game.combo + ' CHAIN', '#ff7ac4', 0.9);
  }
}

function breakCombo() {
  if (game.combo >= 3) showMessage('COMBO LOST', '#8fa6bd', 0.8);
  game.combo = 0;
  game.comboMult = 1;
  game.comboTimer = 0;
}

function updateCombo(dt) {
  if (game.comboTimer > 0) {
    game.comboTimer -= dt;
    if (game.comboTimer <= 0) breakCombo();
  }
}

// =============================================================================
// 13. Waves / upgrades
// =============================================================================
var UPGRADES = [
  { id: 'edge', icon: '⚔', name: 'Edge', max: 5, desc: '+25% melee damage', apply: function () { player.stats.damage *= 1.25; } },
  { id: 'rhythm', icon: '⏱', name: 'Rhythm', max: 5, desc: '+18% attack speed', apply: function () { player.stats.attackCooldown *= 0.82; } },
  { id: 'stride', icon: '🏃', name: 'Stride', max: 4, desc: '+10% movement speed', apply: function () { player.stats.moveSpeed *= 1.1; player.stats.sprintSpeed *= 1.1; } },
  { id: 'core', icon: '❤', name: 'Core', max: 4, desc: '+25 max HP and heal 25', apply: function () { player.stats.maxHealth += 25; player.stats.health = Math.min(player.stats.maxHealth, player.stats.health + 25); } },
  { id: 'phase', icon: '⚡', name: 'Phase', max: 3, desc: '-22% dash cooldown', apply: function () { player.stats.dashCooldown *= 0.78; } },
  { id: 'leech', icon: '🩸', name: 'Leech', max: 3, desc: '+3 HP per hit landed', apply: function () { player.stats.lifesteal += 3; } },
  { id: 'reach', icon: '↗', name: 'Reach', max: 3, desc: '+0.45m range, wider arc', apply: function () { player.stats.range += 0.45; player.stats.arc += 12; } },
  { id: 'momentum', icon: '🔥', name: 'Momentum', max: 3, desc: '+0.8s combo window', apply: function () { player.stats.comboWindow += 0.8; } }
];

function upgradeLevel(id) { return game.upgrades[id] || 0; }

function rollUpgrades() {
  var pool = UPGRADES.filter(function (u) { return upgradeLevel(u.id) < u.max; });
  var out = [];
  while (out.length < 3 && pool.length) {
    var idx = randInt(0, pool.length - 1);
    out.push(pool[idx]);
    pool.splice(idx, 1);
  }
  return out;
}

function showUpgrades() {
  var cards = document.getElementById('cards');
  cards.innerHTML = '';
  var options = rollUpgrades();

  options.forEach(function (u) {
    var btn = document.createElement('button');
    btn.className = 'ucard';
    var lvl = upgradeLevel(u.id);
    btn.innerHTML = '<div class="lvl">LV ' + (lvl + 1) + '/' + u.max + '</div>' +
      '<div class="ico">' + u.icon + '</div>' +
      '<h4>' + u.name + '</h4><p>' + u.desc + '</p>';
    btn.addEventListener('click', function (ev) {
      ev.preventDefault();
      ev.stopPropagation();
      applyUpgrade(u);
    });
    cards.appendChild(btn);
  });

  if (!options.length) {
    // everything maxed: just continue
    setTimeout(function () { applyUpgrade(null); }, 400);
  }

  if (document.exitPointerLock) { try { document.exitPointerLock(); } catch (e) { /* ignore */ } }
  document.getElementById('upgrade').classList.add('on');
  game.state = 'upgrade';
}

function applyUpgrade(u) {
  if (u) {
    u.apply();
    game.upgrades[u.id] = upgradeLevel(u.id) + 1;
    sfxUpgrade();
  }
  document.getElementById('upgrade').classList.remove('on');
  game.wave++;
  startWave();

  if (!IS_TOUCH && canvas.requestPointerLock) {
    try { canvas.requestPointerLock(); } catch (e) { /* ignore */ }
  }
}

function onWaveCleared() {
  if (game.state !== 'playing') return;
  game.state = 'upgrade';
  game.score += CFG.waveBonus + game.wave * 40;
  sfxWave();
  arenaPulse(0x66ffc2);
  showMessage('WAVE ' + game.wave + ' CLEAR', '#3fffb0', 2.0);
  setBossBar(null);
  setTimeout(showUpgrades, 850);
}

function startWave() {
  game.state = 'playing';
  game.cores = 0;
  game.coresTotal = 0;
  game.spawnTimer = 0.8;

  var isBossWave = (game.wave % CFG.bossEvery) === 0;

  // clear leftover projectiles / shockwaves
  for (var i = projectiles.length - 1; i >= 0; i--) { scene.remove(projectiles[i].mesh); }
  projectiles.length = 0;
  for (var s = shockwaves.length - 1; s >= 0; s--) { scene.remove(shockwaves[s].mesh); }
  shockwaves.length = 0;

  if (isBossWave) {
    game.coresTotal = 0;
    var boss = new Enemy('boss', 0, -CFG.arenaRadius * 0.68);
    enemies.push(boss);
    game.boss = boss;
    setBossBar(boss);
    showMessage('WARDEN AWAKENS', '#ff5c7a', 2.4);
    sfxBoss();
    game.shake = 1.2;
    arenaPulse(0xff4a6a);
  } else {
    var count = Math.min(CFG.maxCores, Math.round(CFG.coreCount0 + CFG.corePerWave * (game.wave - 1)));
    game.coresTotal = count;
    var placed = [];
    for (var c = 0; c < count; c++) {
      var spot = placeInArena(6, 3.2, placed);
      placed.push(spot);
      spawnCore(spot.x, spot.z);
    }
    showMessage('WAVE ' + game.wave, '#7fe3ff', 1.4);
    arenaPulse(0x54e8ff);
  }

  updateHud(true);
}

function placeInArena(minFromPlayer, minFromOthers, others) {
  for (var attempt = 0; attempt < 40; attempt++) {
    var a = Math.random() * TAU;
    var r = 4.5 + Math.random() * (CFG.arenaRadius - 4.5 - 3.2);
    var x = Math.cos(a) * r;
    var z = Math.sin(a) * r;

    if (Math.hypot(x - player.pos.x, z - player.pos.z) < minFromPlayer) continue;

    var tooClose = false;
    for (var i = 0; i < others.length; i++) {
      if (Math.hypot(x - others[i].x, z - others[i].z) < minFromOthers) { tooClose = true; break; }
    }
    if (tooClose) continue;

    // keep off the pillars
    var blocked = false;
    for (var p = 0; p < arena.pillars.length; p++) {
      if (Math.hypot(x - arena.pillars[p].x, z - arena.pillars[p].z) < 2) { blocked = true; break; }
    }
    if (blocked) continue;

    return { x: x, z: z };
  }
  var fa = Math.random() * TAU;
  return { x: Math.cos(fa) * (CFG.arenaRadius * 0.6), z: Math.sin(fa) * (CFG.arenaRadius * 0.6) };
}

function aliveEnemies() {
  var n = 0;
  for (var i = 0; i < enemies.length; i++) if (!enemies[i].dead) n++;
  return n;
}

function enemyTypeForWave(wave) {
  if (wave < 2) return 'hunter';
  if (wave < 4) return Math.random() < 0.7 ? 'hunter' : 'charger';
  if (wave < 7) return Math.random() < 0.5 ? 'hunter' : (Math.random() < 0.55 ? 'charger' : 'spitter');
  var r = Math.random();
  if (r < 0.35) return 'hunter';
  if (r < 0.68) return 'charger';
  return 'spitter';
}

function updateSpawns(dt) {
  game.spawnTimer -= dt;
  if (game.spawnTimer > 0) return;

  var interval = Math.max(CFG.spawnIntervalMin, CFG.spawnInterval0 - game.wave * 0.12);
  game.spawnTimer = interval;

  var cap = Math.min(CFG.maxAliveCap, CFG.maxAliveBase + Math.floor(game.wave * 0.8));
  if (aliveEnemies() >= cap) return;

  var spot = placeInArena(9, 2.0, enemies.filter(function (e) { return !e.dead; }).map(function (e) {
    return { x: e.pos.x, z: e.pos.z };
  }));

  var type = enemyTypeForWave(game.wave);
  enemies.push(new Enemy(type, spot.x, spot.z));
  FX.burst(new THREE.Vector3(spot.x, 1, spot.z), 0xff6a4a, 12, { speed: 4, size: 0.45, life: 0.45 });
}

// =============================================================================
// 14. Run lifecycle
// =============================================================================
function resetRun() {
  // clear the field
  for (var i = enemies.length - 1; i >= 0; i--) scene.remove(enemies[i].mesh.group);
  enemies.length = 0;
  for (var c = cores.length - 1; c >= 0; c--) scene.remove(cores[c].group);
  cores.length = 0;
  for (var p = projectiles.length - 1; p >= 0; p--) scene.remove(projectiles[p].mesh);
  projectiles.length = 0;
  for (var s = shockwaves.length - 1; s >= 0; s--) scene.remove(shockwaves[s].mesh);
  shockwaves.length = 0;

  // reset player
  player.dead = false;
  player.root.visible = true;
  player.pos.set(0, 0, 0);
  player.vel.set(0, 0, 0);
  player.knock.set(0, 0, 0);
  player.yaw = Math.PI;
  player.lastDamage = -999;
  player.attackTimer = 0;
  player.dashCd = 0;
  player.dashTimer = 0;
  player.invuln = 0;
  player.stats = {
    maxHealth: CFG.maxHealth, health: CFG.maxHealth,
    damage: CFG.attackDamage, attackCooldown: CFG.attackCooldown,
    moveSpeed: CFG.walkSpeed, sprintSpeed: CFG.sprintSpeed,
    dashCooldown: CFG.dashCooldown, lifesteal: 0,
    range: CFG.attackRange, arc: CFG.attackArc, comboWindow: CFG.comboWindow
  };

  game.score = 0;
  game.wave = 1;
  game.combo = 0;
  game.comboMult = 1;
  game.comboTimer = 0;
  game.upgrades = {};
  game.boss = null;
  game.time = 0;
  game.shake = 0;
  game.hitStop = 0;
  game.fovKick = 0;
  setBossBar(null);

  camYaw = Math.PI;
  camPitch = 0.26;
  camPos.set(0, 3.0, 6.6);
  camLook.set(0, 1.4, 0);

  startWave();
}

function onPlayerDied() {
  game.state = 'dead';
  game.slowmo = 1;
  if (game.score > game.best) {
    game.best = game.score;
    try { localStorage.setItem('arenaRunnerBestV2', String(game.best)); } catch (e) { /* ignore */ }
  }
  setTimeout(showRunOver, 1500);
}

function showRunOver() {
  var overlay = document.getElementById('start');
  var h1 = overlay.querySelector('h1');
  var tag = overlay.querySelector('.tagline');
  var btn = document.getElementById('startBtn');
  h1.textContent = 'RUN OVER';
  tag.textContent = 'SCORE ' + game.score + '  ·  WAVE ' + game.wave + '  ·  BEST ' + game.best;
  btn.textContent = 'Run again';
  document.getElementById('bestHint').textContent = String(game.best);
  if (document.exitPointerLock) { try { document.exitPointerLock(); } catch (e) { /* ignore */ } }
  overlay.classList.remove('hidden');
  game.state = 'menu';
}

function startGame() {
  initAudio();
  document.getElementById('start').classList.add('hidden');
  document.getElementById('upgrade').classList.remove('on');
  resetRun();
  if (!IS_TOUCH && canvas.requestPointerLock) {
    try { canvas.requestPointerLock(); } catch (e) { /* ignore */ }
  }
}

function togglePause() {
  if (game.state === 'playing') {
    game.state = 'paused';
    document.getElementById('pauseBadge').classList.add('on');
    if (document.exitPointerLock) document.exitPointerLock();
  } else if (game.state === 'paused') {
    game.state = 'playing';
    document.getElementById('pauseBadge').classList.remove('on');
  }
}

// =============================================================================
// 15. HUD
// =============================================================================
var el = {
  score: document.getElementById('score'),
  wave: document.getElementById('wave'),
  cores: document.getElementById('cores'),
  best: document.getElementById('best'),
  healthFill: document.getElementById('healthFill'),
  healthText: document.getElementById('healthText'),
  sprintTag: document.getElementById('sprintTag'),
  comboWrap: document.getElementById('comboWrap'),
  comboVal: document.getElementById('comboVal'),
  comboBar: document.getElementById('comboBar'),
  messages: document.getElementById('messages'),
  danger: document.getElementById('danger'),
  hurtFlash: document.getElementById('hurtFlash'),
  minimap: document.getElementById('minimap'),
  dashFill: document.getElementById('dashFill'),
  bossWrap: document.getElementById('bossWrap'),
  bossFill: document.getElementById('bossFill'),
  bossName: document.getElementById('bossName')
};
var mapCtx = el.minimap.getContext('2d');
var hudCache = { score: -1, wave: -1, cores: '', best: -1, hp: -1, combo: -1, sprint: null };

function showMessage(text, color, duration) {
  var node = document.createElement('div');
  node.className = 'msg';
  node.textContent = text;
  node.style.color = color || '#eaf4ff';
  el.messages.appendChild(node);
  msgs.push({ node: node, until: game.time + (duration || 1.6) });
  while (msgs.length > 4) {
    var old = msgs.shift();
    if (old.node.parentNode) old.node.parentNode.removeChild(old.node);
  }
}

var msgs = [];

function updateMessages() {
  for (var i = msgs.length - 1; i >= 0; i--) {
    var m = msgs[i];
    var left = m.until - game.time;
    if (left <= 0) {
      if (m.node.parentNode) m.node.parentNode.removeChild(m.node);
      msgs.splice(i, 1);
    } else if (left < 0.4) {
      m.node.style.opacity = String(clamp(left / 0.4, 0, 1));
    }
  }
}

function flashHurt() {
  el.hurtFlash.style.opacity = '0.9';
  setTimeout(function () { el.hurtFlash.style.opacity = '0'; }, 80);
}

function setBossBar(boss) {
  if (boss) {
    el.bossWrap.classList.add('on');
    el.bossName.textContent = 'WARDEN  ·  WAVE ' + game.wave;
  } else {
    el.bossWrap.classList.remove('on');
  }
}

function updateHud(force) {
  var scoreStr = pad(Math.round(game.score), 6);
  if (force || hudCache.score !== scoreStr) { el.score.textContent = scoreStr; hudCache.score = scoreStr; }
  if (force || hudCache.wave !== game.wave) { el.wave.textContent = String(game.wave); hudCache.wave = game.wave; }

  var coresStr = game.coresTotal ? (game.cores + ' / ' + game.coresTotal) : '—';
  if (force || hudCache.cores !== coresStr) { el.cores.textContent = coresStr; hudCache.cores = coresStr; }
  if (force || hudCache.best !== game.best) { el.best.textContent = String(game.best); hudCache.best = game.best; }

  var pct = clamp(player.stats.health / player.stats.maxHealth, 0, 1);
  if (force || Math.abs(hudCache.hp - pct) > 0.002) {
    el.healthFill.style.transform = 'scaleX(' + pct + ')';
    el.healthFill.style.background = pct < 0.3
      ? 'linear-gradient(90deg,#ff3b30,#ff7a45)'
      : (pct < 0.6 ? 'linear-gradient(90deg,#ffb62b,#ffd166)' : 'linear-gradient(90deg,#12e08a,#28f5c0)');
    el.healthText.textContent = Math.ceil(player.stats.health) + ' / ' + Math.round(player.stats.maxHealth);
    hudCache.hp = pct;
  }

  var showCombo = game.combo > 1;
  if (force || hudCache.combo !== game.combo) {
    el.comboWrap.classList.toggle('on', showCombo);
    el.comboVal.textContent = 'x' + game.comboMult.toFixed(1);
    hudCache.combo = game.combo;
  }
  if (showCombo) {
    var k = clamp(game.comboTimer / Math.max(0.1, player.stats.comboWindow), 0, 1);
    el.comboBar.style.transform = 'scaleX(' + k + ')';
  }

  var sprinting = player.sprinting;
  if (force || hudCache.sprint !== sprinting) {
    el.sprintTag.classList.toggle('on', sprinting);
    hudCache.sprint = sprinting;
  }

  var dashK = clamp(1 - player.dashCd / Math.max(0.01, player.stats.dashCooldown), 0, 1);
  el.dashFill.style.transform = 'scaleY(' + dashK + ')';

  if (game.boss && !game.boss.dead) {
    el.bossFill.style.transform = 'scaleX(' + clamp(game.boss.hp / game.boss.maxHp, 0, 1) + ')';
  }
}

function drawMinimap() {
  var w = el.minimap.width, h = el.minimap.height;
  var cx = w / 2, cy = h / 2;
  var scale = (w / 2 - 8) / (CFG.arenaRadius + 1);

  mapCtx.clearRect(0, 0, w, h);
  mapCtx.fillStyle = 'rgba(6,14,22,0.92)';
  mapCtx.fillRect(0, 0, w, h);

  mapCtx.strokeStyle = 'rgba(67,230,255,0.45)';
  mapCtx.lineWidth = 3;
  mapCtx.beginPath();
  mapCtx.arc(cx, cy, CFG.arenaRadius * scale, 0, TAU);
  mapCtx.stroke();

  mapCtx.strokeStyle = 'rgba(67,230,255,0.12)';
  mapCtx.lineWidth = 1.5;
  mapCtx.beginPath();
  mapCtx.arc(cx, cy, CFG.arenaRadius * scale * 0.55, 0, TAU);
  mapCtx.stroke();

  mapCtx.fillStyle = 'rgba(255,138,61,0.55)';
  for (var p = 0; p < arena.pillars.length; p++) {
    mapCtx.beginPath();
    mapCtx.arc(cx + arena.pillars[p].x * scale, cy + arena.pillars[p].z * scale, 2.4, 0, TAU);
    mapCtx.fill();
  }

  for (var i = 0; i < cores.length; i++) {
    mapCtx.fillStyle = '#63f7ea';
    mapCtx.beginPath();
    mapCtx.arc(cx + cores[i].x * scale, cy + cores[i].z * scale, 3.2, 0, TAU);
    mapCtx.fill();
  }

  for (var e = 0; e < enemies.length; e++) {
    var en = enemies[e];
    if (en.dead) continue;
    mapCtx.fillStyle = en.type === 'boss' ? '#ff2f6d' : (en.type === 'charger' ? '#ff9a3c' : (en.type === 'spitter' ? '#c76bff' : '#ff4b2b'));
    mapCtx.beginPath();
    mapCtx.arc(cx + en.pos.x * scale, cy + en.pos.z * scale, en.type === 'boss' ? 6 : 3.6, 0, TAU);
    mapCtx.fill();
  }

  if (!player.dead) {
    var px = cx + player.pos.x * scale;
    var py = cy + player.pos.z * scale;
    mapCtx.fillStyle = '#ffffff';
    mapCtx.beginPath();
    mapCtx.arc(px, py, 4.2, 0, TAU);
    mapCtx.fill();

    mapCtx.strokeStyle = '#3fd8ff';
    mapCtx.lineWidth = 2.5;
    mapCtx.beginPath();
    mapCtx.moveTo(px, py);
    mapCtx.lineTo(px + Math.sin(player.yaw) * 13, py + Math.cos(player.yaw) * 13);
    mapCtx.stroke();
  }
}

function updateDanger() {
  if (game.state !== 'playing' || player.dead) { el.danger.style.opacity = '0'; return; }
  var nearest = Infinity;
  for (var i = 0; i < enemies.length; i++) {
    if (enemies[i].dead) continue;
    var d = Math.hypot(enemies[i].pos.x - player.pos.x, enemies[i].pos.z - player.pos.z) - enemies[i].radius;
    nearest = Math.min(nearest, d);
  }
  var danger = nearest < 4 ? clamp(1 - nearest / 4, 0, 1) : 0;
  el.danger.style.opacity = String(danger * 0.55);
}

// =============================================================================
// 16. Camera
// =============================================================================
function updateCamera(dt) {
  var target = new THREE.Vector3(player.pos.x, player.pos.y + CFG.cameraHeight, player.pos.z);

  var horiz = Math.cos(camPitch);
  var offset = new THREE.Vector3(Math.sin(camYaw) * horiz, Math.sin(camPitch), Math.cos(camYaw) * horiz)
    .multiplyScalar(CFG.cameraDist);

  var desired = target.clone().add(offset);
  desired.y = Math.max(desired.y, 0.75);

  var flat = Math.hypot(desired.x, desired.z);
  var maxFlat = CFG.arenaRadius - 0.6;
  if (flat > maxFlat) {
    desired.x *= maxFlat / flat;
    desired.z *= maxFlat / flat;
  }

  camPos.lerp(desired, 1 - Math.exp(-10 * dt));
  camLook.lerp(target, 1 - Math.exp(-16 * dt));

  var sprintK = player.sprinting ? 1 : 0;
  var targetFov = 72 + sprintK * 5 + game.fovKick;
  camera.fov = damp(camera.fov, targetFov, 8, dt);
  camera.updateProjectionMatrix();

  game.fovKick = damp(game.fovKick, 0, 7, dt);

  var shake = game.shake;
  if (shake > 0.001) {
    var s = shake * 0.22;
    camera.position.set(
      camPos.x + rand(-s, s),
      camPos.y + rand(-s, s),
      camPos.z + rand(-s, s)
    );
    game.shake = damp(game.shake, 0, 6, dt);
  } else {
    camera.position.copy(camPos);
  }

  camera.lookAt(camLook);
  camera.rotation.z += clamp(-(player.vel.x * Math.cos(camYaw) - player.vel.z * Math.sin(camYaw)) * 0.004, -0.03, 0.03);
}

// =============================================================================
// 17. Input
// =============================================================================
var keys = Object.create(null);
var stick = { active: false, id: null, ox: 0, oy: 0, dx: 0, dy: 0, radius: 92 };
var lookFinger = { active: false, id: null, x: 0, y: 0 };
var runToggle = false;
var attackHeld = false;

var stickBase = document.getElementById('stickBase');
var stickKnob = document.getElementById('stickKnob');

function setStickVisual(x, y, on) {
  stickBase.style.left = x + 'px';
  stickBase.style.top = y + 'px';
  stickBase.style.transform = 'translate(-50%,-50%)';
  stickKnob.style.left = x + 'px';
  stickKnob.style.top = y + 'px';
  stickKnob.style.transform = 'translate(-50%,-50%)';
  stickBase.classList.toggle('on', !!on);
}

function hideStickVisual() {
  stickBase.style.left = '-999px';
  stickKnob.style.left = '-999px';
  stickBase.classList.remove('on');
}

function onPointerDown(e) {
  initAudio();
  if (game.state !== 'playing') {
    if (e.target && e.target.closest && e.target.closest('.ucard, #startBtn, .tbtn, .overlay')) return;
  }

  if (e.target && e.target.closest && e.target.closest('.tbtn, .ucard, #startBtn')) return;

  if (!IS_TOUCH) {
    if (document.pointerLockElement !== canvas && canvas.requestPointerLock) {
      try { canvas.requestPointerLock(); } catch (err) { /* ignore */ }
    }
    if (game.state === 'playing') {
      if (e.button === 0) tryPlayerAttack();
      else if (e.button === 2) player.tryDash();
    }
    return;
  }

  if (game.state !== 'playing') return;

  var x = e.clientX, y = e.clientY;
  if (x < window.innerWidth * 0.5) {
    if (stick.active) return;
    stick.active = true;
    stick.id = e.pointerId;
    stick.ox = x;
    stick.oy = y;
    stick.dx = 0;
    stick.dy = 0;
    setStickVisual(x, y, true);
  } else if (!lookFinger.active) {
    lookFinger.active = true;
    lookFinger.id = e.pointerId;
    lookFinger.x = x;
    lookFinger.y = y;
  }
}

function onPointerMove(e) {
  if (!IS_TOUCH) {
    if (document.pointerLockElement === canvas) {
      camYaw -= (e.movementX || 0) * 0.0024;
      camPitch += (e.movementY || 0) * 0.0020;
      camPitch = clamp(camPitch, -0.45, 0.95);
    }
    return;
  }

  if (stick.active && e.pointerId === stick.id) {
    var dx = e.clientX - stick.ox;
    var dy = e.clientY - stick.oy;
    var len = Math.hypot(dx, dy);
    if (len > stick.radius) {
      dx = (dx / len) * stick.radius;
      dy = (dy / len) * stick.radius;
    }
    stick.dx = dx / stick.radius;
    stick.dy = dy / stick.radius;
    setStickVisual(stick.ox + dx, stick.oy + dy, true);
  } else if (lookFinger.active && e.pointerId === lookFinger.id) {
    camYaw -= (e.clientX - lookFinger.x) * 0.0044;
    camPitch += (e.clientY - lookFinger.y) * 0.0034;
    camPitch = clamp(camPitch, -0.45, 0.95);
    lookFinger.x = e.clientX;
    lookFinger.y = e.clientY;
  }
}

function onPointerUp(e) {
  if (stick.active && e.pointerId === stick.id) {
    stick.active = false;
    stick.id = null;
    stick.dx = 0;
    stick.dy = 0;
    hideStickVisual();
  }
  if (lookFinger.active && e.pointerId === lookFinger.id) {
    lookFinger.active = false;
    lookFinger.id = null;
  }
}

function tryPlayerAttack() {
  if (game.state !== 'playing' || player.dead) return;
  player.tryAttack();
}

window.addEventListener('pointerdown', onPointerDown, { passive: true });
window.addEventListener('pointermove', onPointerMove, { passive: true });
window.addEventListener('pointerup', onPointerUp, { passive: true });
window.addEventListener('pointercancel', onPointerUp, { passive: true });
window.addEventListener('contextmenu', function (e) { e.preventDefault(); });

window.addEventListener('keydown', function (e) {
  var k = e.key.toLowerCase();
  keys[k] = true;
  if (k === 'p' || k === 'escape') togglePause();
  if (k === ' ') {
    e.preventDefault();
    if (game.state === 'playing') player.jump();
  }
  if (k === 'q') player.tryDash();
  if (k === 'j') tryPlayerAttack();
});
window.addEventListener('keyup', function (e) { keys[e.key.toLowerCase()] = false; });

function bindHold(button, onDown, onUp) {
  button.addEventListener('pointerdown', function (e) {
    e.preventDefault();
    e.stopPropagation();
    initAudio();
    button.classList.add('hot');
    if (onDown) onDown();
  });
  ['pointerup', 'pointercancel', 'pointerleave'].forEach(function (evt) {
    button.addEventListener(evt, function () {
      button.classList.remove('hot');
      if (onUp) onUp();
    });
  });
}

var btnAttack = document.getElementById('btnAttack');
var btnRun = document.getElementById('btnRun');

bindHold(btnAttack, function () { attackHeld = true; tryPlayerAttack(); }, function () { attackHeld = false; });
bindHold(document.getElementById('btnJump'), function () { if (game.state === 'playing') player.jump(); });
bindHold(document.getElementById('btnDash'), function () { if (game.state === 'playing') player.tryDash(); });
bindHold(btnRun, function () {
  runToggle = !runToggle;
  btnRun.classList.toggle('on', runToggle);
});

document.getElementById('startBtn').addEventListener('click', function (e) {
  e.preventDefault();
  e.stopPropagation();
  startGame();
});

document.addEventListener('visibilitychange', function () {
  if (document.hidden && game.state === 'playing') togglePause();
});

// touch UI visibility
if (IS_TOUCH) {
  document.getElementById('touch').classList.add('on');
  document.getElementById('touchHelp').style.display = '';
  document.getElementById('startBtn').textContent = 'Tap to enter';
  hideStickVisual();
}

// =============================================================================
// 18. Main update + loop
// =============================================================================
function update(dt) {
  game.time += dt;

  // ---- movement input ----
  var mx = 0, mz = 0;
  if (keys['w'] || keys['arrowup']) mz += 1;
  if (keys['s'] || keys['arrowdown']) mz -= 1;
  if (keys['d'] || keys['arrowright']) mx += 1;
  if (keys['a'] || keys['arrowleft']) mx -= 1;
  if (stick.active) { mz += -stick.dy; mx += stick.dx; }

  var mag = Math.hypot(mx, mz);
  if (mag > 1) { mx /= mag; mz /= mag; }

  var sprinting = !!keys['shift'] || runToggle;
  player.update(dt, mx, mz, sprinting);

  // auto-attack while the button is held
  if (attackHeld) tryPlayerAttack();

  updateCombo(dt);

  // ---- enemies ----
  for (var i = enemies.length - 1; i >= 0; i--) {
    var e = enemies[i];
    e.update(dt);
    if (e.dead) enemies.splice(i, 1);
  }

  updateSpawns(dt);
  updateCores(dt);
  updateProjectiles(dt);
  updateShockwaves(dt);
  FX.update(dt);

  // ---- transient vfx ----
  for (var v = vfx.length - 1; v >= 0; v--) {
    var item = vfx[v];
    item.life -= dt;
    var t = 1 - item.life / item.max;
    if (item.kind === 'arc') {
      item.mesh.material.opacity = 0.85 * (1 - t);
      item.mesh.scale.setScalar(1 + t * 0.12);
    }
    if (item.life <= 0) {
      scene.remove(item.mesh);
      item.mesh.geometry.dispose();
      item.mesh.material.dispose();
      vfx.splice(v, 1);
    }
  }

  // arena pulse
  if (arena.pulse > 0) {
    arena.pulse = Math.max(0, arena.pulse - dt * 1.6);
    var pr = (1 - arena.pulse) * CFG.arenaRadius;
    arena.pulseMesh.scale.setScalar(Math.max(0.1, pr));
    arena.pulseMat.opacity = arena.pulse * 0.55;
  }

  // ambient dust drift
  if (arena.dust) {
    arena.dust.rotation.y += dt * 0.02;
  }

  updateDanger();
  updateHud(false);
  updateMessages();
  drawMinimap();
}

// ---- adaptive quality: keep the frame rate playable on weak phones ----------
var perf = { frames: 0, acc: 0, level: 0, bloomOn: QUALITY.bloom };

function adaptQuality(realDt) {
  perf.frames++;
  perf.acc += realDt;
  if (perf.frames < 45) return;

  var avg = perf.acc / perf.frames;
  perf.frames = 0;
  perf.acc = 0;

  if (avg > 0.030 && perf.level < 3) {
    perf.level++;
    if (perf.level === 1) {
      renderer.setPixelRatio(Math.max(0.8, QUALITY.pixelRatio * 0.8));
    } else if (perf.level === 2) {
      renderer.setPixelRatio(Math.max(0.65, QUALITY.pixelRatio * 0.65));
    } else {
      QUALITY.bloom = false;
      renderer.shadowMap.enabled = false;
      renderer.shadowMap.needsUpdate = true;
    }
    resize();
  }
}

var lastTime = performance.now();

function frame(now) {
  requestAnimationFrame(frame);

  var realDt = Math.min(0.1, (now - lastTime) / 1000);
  lastTime = now;

  var dt = realDt;

  if (game.hitStop > 0) {
    game.hitStop -= realDt;
    dt *= 0.08;
  }

  if (game.state === 'playing') {
    update(dt);
  } else if (game.state === 'dead') {
    // slow-mo death camera
    game.time += dt * 0.35;
    if (arena.dust) arena.dust.rotation.y += dt * 0.01;
    FX.update(realDt * 0.4);
  }

  updateCamera(realDt);
  updateHud(false);
  adaptQuality(realDt);
  PostFX.render(realDt);
}

// =============================================================================
// 19. Boot
// =============================================================================
function resize() {
  var w = window.innerWidth;
  var h = window.innerHeight;
  renderer.setPixelRatio(QUALITY.pixelRatio);
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  PostFX.setSize(Math.floor(w * QUALITY.pixelRatio), Math.floor(h * QUALITY.pixelRatio));

  stick.radius = clamp(Math.min(w, h) * 0.16, 58, 108);
  var size = stick.radius * 1.7;
  stickBase.style.width = size + 'px';
  stickBase.style.height = size + 'px';
  stickKnob.style.width = (size * 0.42) + 'px';
  stickKnob.style.height = (size * 0.42) + 'px';
}

window.addEventListener('resize', resize);
window.addEventListener('orientationchange', function () { setTimeout(resize, 120); });

resize();
hideStickVisual();

document.getElementById('bestHint').textContent = String(game.best);
updateHud(true);
drawMinimap();
camera.lookAt(0, 1.4, 0);
PostFX.render(0.016);
requestAnimationFrame(frame);

// expose a tiny debug hook for automated smoke tests
window.__arena = {
  state: game,
  player: player,
  enemies: enemies,
  cores: cores,
  start: startGame,
  attack: tryPlayerAttack,
  dash: function () { player.tryDash(); },
  jump: function () { player.jump(); },
  spawn: function (type, x, z) { var e = new Enemy(type || 'hunter', x == null ? 3 : x, z == null ? 3 : z); enemies.push(e); return e; },
  killAll: function () { for (var i = enemies.length - 1; i >= 0; i--) enemies[i].kill(); },
  winWave: function () { for (var i = cores.length - 1; i >= 0; i--) scene.remove(cores[i].group); cores.length = 0; onWaveCleared(); },
  startWave: function () { startWave(); },
  hurt: function (n) { player.hurt(n || 10, player.pos.x + 1, player.pos.z); },
  upgradeOptions: function () { return rollUpgrades(); },
  applyUpgrade: function (id) {
    var u = null;
    for (var i = 0; i < UPGRADES.length; i++) if (UPGRADES[i].id === id) u = UPGRADES[i];
    applyUpgrade(u);
  }
};

})();
