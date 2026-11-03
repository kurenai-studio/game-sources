const { Server, Room } = require('colyseus');
const { Schema, MapSchema, ArraySchema, defineTypes } = require('@colyseus/schema');
const http = require('http');
const fs = require('fs');
const path = require('path');
const express = require('express');

// Export/import endpoints are disabled unless this is set.
const EXPORT_TOKEN = process.env.EXPORT_TOKEN || '';

/* ==================================================================
   Dungeon generation (deterministic per floor)
   ================================================================== */
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const BOSSES = {
  1: { name: 'THE NIGHT STOCKER',       hp: 60,  speed: 2.2, radius: 2.2, dmg: 2, cd: 2.2 },
  2: { name: 'THE SEAM IN AISLE THREE', hp: 85,  speed: 2.4, radius: 2.4, dmg: 2, cd: 2.1 },
  3: { name: 'THE RETURNED CART',       hp: 110, speed: 2.6, radius: 2.6, dmg: 3, cd: 2.0 },
  4: { name: 'EMPLOYEE OF THE MONTH',   hp: 140, speed: 2.8, radius: 2.6, dmg: 3, cd: 1.9 },
  5: { name: 'THE LANDLORD',            hp: 260, speed: 2.4, radius: 2.8, dmg: 4, cd: 1.8 },
};

const PARTY_SCALE = { 1: 0.6, 2: 0.85, 3: 1.0 };
function scaleForPlayers(n) {
  if (n <= 1) return PARTY_SCALE[1];
  if (n === 2) return PARTY_SCALE[2];
  return PARTY_SCALE[3];
}

function generateDungeon(floor) {
  const W = 32, H = 32;
  const g = Array.from({ length: H }, () => new Array(W).fill(1));
  const rand = mulberry32(9001 + floor * 7919);
  const rooms = [];

  for (let attempt = 0; attempt < 200 && rooms.length < 9; attempt++) {
    const w = 4 + Math.floor(rand() * 5);
    const h = 4 + Math.floor(rand() * 5);
    const x = 2 + Math.floor(rand() * (W - w - 4));
    const y = 2 + Math.floor(rand() * (H - h - 4));
    if (rooms.some(o => x < o.x + o.w + 2 && x + w + 2 > o.x && y < o.y + o.h + 2 && y + h + 2 > o.y)) continue;
    rooms.push({ x, y, w, h });
  }
  if (rooms.length < 3) {
    rooms.length = 0;
    rooms.push({ x: 4, y: 4, w: 8, h: 8 }, { x: 20, y: 4, w: 8, h: 8 }, { x: 4, y: 20, w: 8, h: 8 });
  }

  for (const r of rooms)
    for (let y = r.y; y < r.y + r.h; y++)
      for (let x = r.x; x < r.x + r.w; x++) g[y][x] = 0;

  const carveH = (x1, x2, y) => { for (let x = Math.min(x1, x2); x <= Math.max(x1, x2); x++) if (g[y][x] === 1) g[y][x] = 0; };
  const carveV = (y1, y2, x) => { for (let y = Math.min(y1, y2); y <= Math.max(y1, y2); y++) if (g[y][x] === 1) g[y][x] = 0; };

  for (let i = 1; i < rooms.length; i++) {
    const a = rooms[i - 1], b = rooms[i];
    const ax = Math.floor(a.x + a.w / 2), ay = Math.floor(a.y + a.h / 2);
    const bx = Math.floor(b.x + b.w / 2), by = Math.floor(b.y + b.h / 2);
    if (rand() < 0.5) { carveH(ax, bx, ay); carveV(ay, by, bx); }
    else { carveV(ay, by, ax); carveH(ax, bx, by); }
  }

  const bossRoom = rooms.slice().sort((a, b) => b.w * b.h - a.w * a.h)[0];
  for (let y = bossRoom.y; y < bossRoom.y + bossRoom.h; y++)
    for (let x = bossRoom.x; x < bossRoom.x + bossRoom.w; x++) g[y][x] = 2;

  const first = rooms[0];
  const ex = Math.floor(first.x + first.w / 2);
  carveV(H - 2, first.y + first.h - 1, ex);
  for (let y = H - 3; y < H; y++)
    for (let x = Math.max(0, ex - 1); x <= Math.min(W - 1, ex + 1); x++) g[y][x] = 3;

  const spawn = { x: ex + 0.5, z: H - 2.5 };
  const bossPos = { x: bossRoom.x + bossRoom.w / 2, z: bossRoom.y + bossRoom.h / 2 };

  const candidates = [];
  for (let z = 1; z < H - 1; z++)
    for (let x = 1; x < W - 1; x++)
      if (g[z][x] === 0 && Math.hypot(x - spawn.x, z - spawn.z) > 9) candidates.push({ x: x + 0.5, z: z + 0.5 });

  const enemySpawns = [];
  for (let i = 0; i < 7 && candidates.length; i++) {
    const idx = Math.floor(rand() * candidates.length);
    enemySpawns.push(candidates.splice(idx, 1)[0]);
  }

  return {
    W, H,
    data: g.map(row => row.join('')).join(''),
    spawn, bossPos, enemySpawns,
    boss: BOSSES[floor] || BOSSES[1],
  };
}

/* ==================================================================
   Profile store — server-owned progress, one record per player id
   ================================================================== */
const PROFILES_PATH = path.join(__dirname, 'profiles.json');

function atomicWrite(filePath, data) {
  const tmp = filePath + '.tmp';
  fs.writeFileSync(tmp, data, 'utf8');
  try { fs.renameSync(tmp, filePath); }
  catch { fs.copyFileSync(tmp, filePath); fs.unlinkSync(tmp); }
}

const profileStore = {
  profiles: new Map(),

  load() {
    try {
      const obj = JSON.parse(fs.readFileSync(PROFILES_PATH, 'utf8'));
      this.profiles = new Map(Object.entries(obj));
    } catch { this.profiles = new Map(); }
  },

  save() {
    try { atomicWrite(PROFILES_PATH, JSON.stringify(Object.fromEntries(this.profiles))); }
    catch (e) { console.error('profile save failed', e); }
  },

  newId() {
    let id;
    do { id = Math.random().toString(16).slice(2, 18).padEnd(16, '0'); }
    while (this.profiles.has(id));
    return id;
  },

  authenticate(suppliedId) {
    if (suppliedId && this.profiles.has(suppliedId)) {
      const profile = this.profiles.get(suppliedId);
      profile.lastPlayed = Date.now();
      return { playerId: suppliedId, profile };
    }
    const newId = this.newId();
    const profile = {
      questStage: 0, seals: 0, hasBadge: false, cleared: [],
      createdAt: Date.now(), lastPlayed: Date.now(),
    };
    this.profiles.set(newId, profile);
    this.save();
    return { playerId: newId, profile, isNew: true };
  },

  get(playerId) { return this.profiles.get(playerId) || null; },

  awardFloor(playerId, floor) {
    const p = this.profiles.get(playerId);
    if (!p) return null;
    if (!p.cleared.includes(floor)) {
      p.cleared.push(floor);
      p.cleared = [...new Set(p.cleared)].sort();
    }
    if (floor === 1) { p.hasBadge = true; p.questStage = Math.max(p.questStage, 2); }
    if (floor >= 2 && floor <= 4) {
      p.seals |= (1 << (floor - 2));
      if ([2, 3, 4].every(f => p.cleared.includes(f))) p.questStage = Math.max(p.questStage, 4);
    }
    if (floor === 5) p.questStage = 6;
    p.lastPlayed = Date.now();
    this.save();
    return p;
  },

  advanceStage(playerId, target) {
    const p = this.profiles.get(playerId);
    if (!p) return null;
    let allowed = p.questStage;
    if (target === 1 && p.questStage === 0) allowed = 1;
    if (target === 3 && p.hasBadge && p.questStage < 3) allowed = 3;
    if (target === 5 && p.seals === 7 && p.questStage < 5) allowed = 5;
    if (allowed > p.questStage) { p.questStage = allowed; this.save(); }
    return p;
  },
};
profileStore.load();

/* ==================================================================
   Schemas
   ================================================================== */
class Player extends Schema {
  constructor() {
    super();
    this.sessionId = '';
    this.playerId = '';
    this.x = 0; this.z = 0; this.ry = 0;
    this.name = 'anon'; this.color = 0xffff00;
    this.party = '';
    this.hp = 8; this.maxHp = 8;
    this.questStage = 0; this.seals = 0; this.hasBadge = false;
    this.inDungeon = false; this.dungeonFloor = 0;
  }
}
defineTypes(Player, {
  sessionId: 'string', playerId: 'string',
  x: 'number', z: 'number', ry: 'number',
  name: 'string', color: 'number', party: 'string',
  hp: 'number', maxHp: 'number',
  questStage: 'number', seals: 'number', hasBadge: 'boolean',
  inDungeon: 'boolean', dungeonFloor: 'number',
});

class ChatMsg extends Schema {
  constructor() { super(); this.name = ''; this.text = ''; }
}
defineTypes(ChatMsg, { name: 'string', text: 'string' });

class Enemy extends Schema {
  constructor() {
    super();
    this.id = ''; this.x = 0; this.z = 0;
    this.hp = 3; this.maxHp = 3; this.alive = true; this.cooldown = 0;
  }
}
defineTypes(Enemy, {
  id: 'string', x: 'number', z: 'number',
  hp: 'number', maxHp: 'number', alive: 'boolean', cooldown: 'number',
});

class Boss extends Schema {
  constructor() {
    super();
    this.x = 0; this.z = 0; this.hp = 40; this.maxHp = 40;
    this.alive = true; this.name = 'THING';
    this.slamTelegraph = 0; this.attackCooldown = 0;
    this.phase = 1; this.difficulty = 'party';
  }
}
defineTypes(Boss, {
  x: 'number', z: 'number', hp: 'number', maxHp: 'number',
  alive: 'boolean', name: 'string',
  slamTelegraph: 'number', attackCooldown: 'number',
  phase: 'number', difficulty: 'string',
});

/* ==================================================================
   Overworld
   ================================================================== */
class OverworldState extends Schema {
  constructor() {
    super();
    this.players = new MapSchema();
    this.chat = new ArraySchema();
  }
}
defineTypes(OverworldState, { players: { map: Player }, chat: { array: ChatMsg } });

class OverworldRoom extends Room {
  clientOf(sessionId) { return this.clients.find((c) => c.sessionId === sessionId) || null; }
  onCreate() {
    this.maxClients = 20;
    this.setState(new OverworldState());
    this.partyCounter = 0;

    this.onMessage('move', (client, data) => {
      const p = this.state.players.get(client.sessionId);
      if (!p || !data) return;
      if (typeof data.x === 'number') p.x = Math.max(-9.5, Math.min(9.5, data.x));
      if (typeof data.z === 'number') p.z = Math.max(-11.5, Math.min(11.5, data.z));
      if (typeof data.ry === 'number') p.ry = data.ry;
    });

    this.onMessage('chat', (client, text) => {
      const p = this.state.players.get(client.sessionId);
      if (!p || typeof text !== 'string') return;
      const m = new ChatMsg();
      m.name = p.name; m.text = text.slice(0, 140);
      this.state.chat.push(m);
      while (this.state.chat.length > 30) this.state.chat.shift();
    });

    this.onMessage('request-profile', (client) => {
      const p = this.state.players.get(client.sessionId);
      if (!p) return;
      const prof = profileStore.get(p.playerId);
      if (!prof) return;
      p.questStage = prof.questStage;
      p.seals = prof.seals;
      p.hasBadge = prof.hasBadge;
      client.send('profile-loaded', { playerId: p.playerId, profile: prof });
    });

    this.onMessage('advance-quest', (client, data) => {
      const p = this.state.players.get(client.sessionId);
      if (!p) return;
      const target = Number(data && data.stage) | 0;
      const prof = profileStore.advanceStage(p.playerId, target);
      if (!prof) return;
      p.questStage = prof.questStage;
      client.send('profile-loaded', { playerId: p.playerId, profile: prof });
    });

    this.onMessage('heal', (client) => {
      const p = this.state.players.get(client.sessionId);
      if (p) p.hp = p.maxHp;
    });

    this.onMessage('party-invite', (client, data) => {
      const from = this.state.players.get(client.sessionId);
      const to = data && this.state.players.get(data.targetSessionId);
      if (!from || !to) return;
      if (to.party && to.party !== from.party) {
        client.send('party-error', 'That player is already in a party.');
        return;
      }
      if (!from.party && !to.party) {
        this.partyCounter++;
        from.party = 'party-' + this.partyCounter;
      }
      if (from.party && !to.party) to.party = from.party;
      to.send('party-invite-from', { fromSessionId: client.sessionId, fromName: from.name });
      this.broadcast('party-updated');
    });

    this.onMessage('party-leave', (client) => {
      const p = this.state.players.get(client.sessionId);
      if (p) p.party = '';
      this.broadcast('party-updated');
    });

    this.onMessage('enter-dungeon', (client, data) => {
      const p = this.state.players.get(client.sessionId);
      if (!p) return;
      const floor = data && data.floor | 0;
      if (floor < 1 || floor > 5) { client.send('party-error', 'No such floor.'); return; }
      const prof = profileStore.get(p.playerId);
      if (!prof) { client.send('party-error', 'Profile missing.'); return; }
      if (floor === 1 && prof.questStage < 1) { client.send('party-error', 'The door is shut. Talk to the clerk.'); return; }
      if (floor >= 2 && floor <= 4 && prof.questStage < 3) { client.send('party-error', 'That seam has not opened yet.'); return; }
      if (floor === 5 && prof.questStage < 5) { client.send('party-error', 'The freezer is still closed.'); return; }

      p.inDungeon = true;
      p.dungeonFloor = floor;
      this.broadcast('party-updated');
      client.send('enter-dungeon-ok', { floor });
    });

    this.onMessage('leave-dungeon', (client) => {
      const p = this.state.players.get(client.sessionId);
      if (!p) return;
      p.inDungeon = false;
      p.dungeonFloor = 0;
      this.broadcast('party-updated');
    });
  }

  async onAuth(client, options, request) {
    const auth = profileStore.authenticate((options && options.playerId) || null);
    client.userData = auth;
    return auth;
  }

  onJoin(client, options, auth) {
    const a = auth || client.userData || {};
    const { playerId, profile } = a;

    const p = new Player();
    p.sessionId = client.sessionId;
    p.playerId = playerId || '';
    p.name = String((options && options.name) || 'anon').slice(0, 16);
    p.color = (Math.floor(Math.random() * 0xffffff) | 0x111111) & 0xffffff;
    const ang = Math.random() * Math.PI * 2;
    p.x = Math.cos(ang) * 2.5;
    p.z = Math.sin(ang) * 2.5;
    if (profile) {
      p.questStage = profile.questStage;
      p.seals = profile.seals;
      p.hasBadge = profile.hasBadge;
    }
    this.state.players.set(client.sessionId, p);

    // Tell the client who it is and what it owns.
    client.send('profile-loaded', { playerId: p.playerId, profile: profile || null });

    // If the client presented an id the store does not know, say so plainly.
    const supplied = options && options.playerId;
    if (supplied && supplied !== playerId) {
      client.send('profile-replaced', { oldId: supplied, newId: playerId });
    }
  }

  onLeave(client) {
    this.state.players.delete(client.sessionId);
    this.broadcast('party-updated');
  }
}

/* ==================================================================
   Dungeon
   ================================================================== */
class DungeonState extends Schema {
  constructor() {
    super();
    this.players = new MapSchema();
    this.enemies = new MapSchema();
    this.boss = new Boss();
    this.party = '';
    this.floor = 1;
    this.mapData = '';
    this.width = 32;
    this.height = 32;
    this.exitOpen = false;
  }
}
defineTypes(DungeonState, {
  players: { map: Player },
  enemies: { map: Enemy },
  boss: Boss,
  party: 'string', floor: 'number',
  mapData: 'string', width: 'number', height: 'number',
  exitOpen: 'boolean',
});

class DungeonRoom extends Room {
  clientOf(sessionId) { return this.clients.find((c) => c.sessionId === sessionId) || null; }
  onCreate(options) {
    this.maxClients = 10;
    const floor = Math.max(1, Math.min(5, (options && options.floor) | 0 || 1));
    const d = generateDungeon(floor);

    this.setState(new DungeonState());
    this.state.floor = floor;
    this.state.party = (options && options.party) || 'solo';
    this.state.mapData = d.data;
    this.state.width = d.W;
    this.state.height = d.H;
    this.spawn = d.spawn;
    this.baseBossHp = d.boss.hp;

    const b = new Boss();
    b.x = d.bossPos.x; b.z = d.bossPos.z;
    b.hp = d.boss.hp; b.maxHp = d.boss.hp;
    b.name = d.boss.name;
    this.state.boss = b;
    this.bossConf = d.boss;

    this.enemyCounter = 0;
    for (const s of d.enemySpawns) this.spawnEnemy(s.x, s.z);

    // The server update loop. Without this, nothing on the server ticks.
    this.setSimulationInterval((deltaMs) => this.tick(deltaMs), 50);

    this.onMessage('move', (client, data) => {
      const p = this.state.players.get(client.sessionId);
      if (!p || !data) return;
      const nx = Number(data.x), nz = Number(data.z);
      if (!isFinite(nx) || !isFinite(nz)) return;
      const row = this.tileRow(Math.floor(nz));
      if (!row || row[Math.floor(nx)] === '1') return;
      p.x = Math.max(0.6, Math.min(d.W - 0.6, nx));
      p.z = Math.max(0.6, Math.min(d.H - 0.6, nz));
      p.ry = Number(data.ry) || 0;
    });

    this.onMessage('attack', (client, data) => {
      const p = this.state.players.get(client.sessionId);
      if (!p || !data) return;
      if (data.boss) {
        const b = this.state.boss;
        if (!b.alive) return;
        if (Math.hypot(p.x - b.x, p.z - b.z) > 2.4) return;
        b.hp = Math.max(0, b.hp - 2);
        this.broadcast('boss-hit', { hp: b.hp, maxHp: b.maxHp });
        if (b.hp <= 0) this.killBoss();
      } else {
        const e = this.state.enemies.get(data.enemyId);
        if (!e || !e.alive) return;
        if (Math.hypot(p.x - e.x, p.z - e.z) > 2.0) return;
        e.hp = Math.max(0, e.hp - 2);
        if (e.hp <= 0) e.alive = false;
      }
    });
  }

  tileRow(z) {
    if (z < 0 || z >= this.state.height) return null;
    return this.state.mapData.slice(z * this.state.width, (z + 1) * this.state.width);
  }

  spawnEnemy(x, z) {
    this.enemyCounter++;
    const e = new Enemy();
    e.id = 'e' + this.enemyCounter;
    e.x = x; e.z = z;
    this.state.enemies.set(e.id, e);
  }

  recomputeBossHp() {
    const b = this.state.boss;
    if (!b || !b.alive) return;
    const n = this.state.players.size;
    const newMax = Math.max(1, Math.round(this.baseBossHp * scaleForPlayers(n)));
    const ratio = b.maxHp > 0 ? b.hp / b.maxHp : 1;
    b.maxHp = newMax;
    b.hp = Math.max(1, Math.round(newMax * ratio));
    b.difficulty = n <= 1 ? 'solo' : (n === 2 ? 'duo' : 'party');
    this.broadcast('boss-scaled', { maxHp: b.maxHp, difficulty: b.difficulty });
  }

  killBoss() {
    const b = this.state.boss;
    b.alive = false;
    b.slamTelegraph = 0;
    this.state.exitOpen = true;

    // Award the floor server-side, per player, and tell each one.
    this.state.players.forEach((p) => {
      if (!p.playerId) return;
      const updated = profileStore.awardFloor(p.playerId, this.state.floor);
      const c = this.clientOf(p.sessionId);
      if (c && updated) c.send('profile-updated', { profile: updated });
    });

    this.broadcast('floor-cleared', { floor: this.state.floor });
  }

  async onAuth(client, options, request) {
    const auth = profileStore.authenticate((options && options.playerId) || null);
    client.userData = auth;
    return auth;
  }

  onJoin(client, options, auth) {
    const a = auth || client.userData || {};
    const p = new Player();
    p.sessionId = client.sessionId;
    p.playerId = a.playerId || '';
    p.name = String((options && options.name) || 'anon').slice(0, 16);
    p.color = (Math.floor(Math.random() * 0xffffff) | 0x111111) & 0xffffff;
    p.party = this.state.party;
    p.x = this.spawn.x;
    p.z = this.spawn.z;
    p.hp = 8; p.maxHp = 8;
    this.state.players.set(client.sessionId, p);
    this.recomputeBossHp();
  }

  onLeave(client) {
    this.state.players.delete(client.sessionId);
    this.recomputeBossHp();
  }

  // deltaMs is milliseconds — convert before using.
  tick(deltaMs) {
    const dt = Math.min(deltaMs, 120) / 1000;
    if (!this.state) return;

    this.state.enemies.forEach((e) => {
      if (!e.alive) return;
      e.cooldown = Math.max(0, e.cooldown - dt);

      let target = null, best = 9;
      this.state.players.forEach((p) => {
        const d = Math.hypot(p.x - e.x, p.z - e.z);
        if (d < best) { best = d; target = p; }
      });
      if (!target) return;

      if (best > 1.25) {
        const sp = 1.5 * dt;
        e.x += ((target.x - e.x) / best) * sp;
        e.z += ((target.z - e.z) / best) * sp;
      } else if (e.cooldown <= 0) {
        e.cooldown = 1.4;
        this.hurtPlayer(target, 1);
      }
    });

    const b = this.state.boss;
    if (!b.alive) return;

    const conf = this.bossConf;
    if (b.phase === 1 && b.hp <= b.maxHp / 2 && this.state.floor === 5) {
      b.phase = 2;
      this.broadcast('boss-phase', { phase: 2 });
    }
    const speedMul = b.phase === 2 ? 1.5 : 1;
    const radius = conf.radius + (b.phase === 2 ? 0.6 : 0);

    if (b.slamTelegraph > 0) {
      b.slamTelegraph -= dt;
      if (b.slamTelegraph <= 0) {
        b.slamTelegraph = 0;
        this.state.players.forEach((p) => {
          if (p.hp <= 0) return;
          if (Math.hypot(p.x - b.x, p.z - b.z) < radius) this.hurtPlayer(p, conf.dmg);
        });
        b.attackCooldown = conf.cd;
      }
      return;
    }

    b.attackCooldown = Math.max(0, b.attackCooldown - dt);

    let target = null, best = Infinity;
    this.state.players.forEach((p) => {
      if (p.hp <= 0) return;
      const d = Math.hypot(p.x - b.x, p.z - b.z);
      if (d < best) { best = d; target = p; }
    });
    if (!target) return;

    if (best > radius * 0.75) {
      const sp = conf.speed * speedMul * dt;
      b.x += ((target.x - b.x) / best) * sp;
      b.z += ((target.z - b.z) / best) * sp;
    } else if (b.attackCooldown <= 0) {
      b.slamTelegraph = 1.15;
    }
  }

  hurtPlayer(p, dmg) {
    p.hp = Math.max(0, p.hp - dmg);
    const target = this.clientOf(p.sessionId);
    if (target) target.send('player-hurt', { hp: p.hp, maxHp: p.maxHp });
    if (p.hp <= 0) {
      p.hp = Math.floor(p.maxHp / 2);
      p.x = this.spawn.x;
      p.z = this.spawn.z;
      if (target) target.send('player-downed', {});
    }
  }
}

/* ==================================================================
   HTTP + game server
   ================================================================== */
const app = express();
app.use(express.json({ limit: '2mb' }));
app.use(express.static(path.join(__dirname, 'public')));
app.get('/health', (req, res) => res.status(200).send('ok'));

function requireExportToken(req, res) {
  if (!EXPORT_TOKEN) {
    res.status(503).json({ error: 'Export disabled: EXPORT_TOKEN not set.' });
    return false;
  }
  const supplied = req.get('X-Export-Token') || req.query.token;
  if (supplied !== EXPORT_TOKEN) {
    res.status(403).json({ error: 'Forbidden.' });
    return false;
  }
  return true;
}

app.get('/profiles/export', (req, res) => {
  if (!requireExportToken(req, res)) return;
  const payload = JSON.stringify(Object.fromEntries(profileStore.profiles));
  const filename = 'underlay-profiles-' + new Date().toISOString().slice(0, 10) + '.json';
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Disposition', 'attachment; filename="' + filename + '"');
  res.send(payload);
});

app.post('/profiles/import', (req, res) => {
  if (!requireExportToken(req, res)) return;
  const incoming = req.body;
  if (!incoming || typeof incoming !== 'object' || Array.isArray(incoming)) {
    return res.status(400).json({ error: 'Expected a JSON object of playerId -> profile.' });
  }

  let merged = 0, skipped = 0;
  for (const [id, profile] of Object.entries(incoming)) {
    if (typeof id !== 'string' || id.length < 8) { skipped++; continue; }
    if (!profile || typeof profile !== 'object') { skipped++; continue; }

    const clean = {
      questStage: Math.max(0, Math.min(6, Number(profile.questStage) | 0 || 0)),
      seals: Math.max(0, Math.min(7, Number(profile.seals) | 0 || 0)),
      hasBadge: !!profile.hasBadge,
      cleared: Array.isArray(profile.cleared)
        ? [...new Set(profile.cleared.filter(f => Number.isInteger(f) && f >= 1 && f <= 5))].sort()
        : [],
      createdAt: Number(profile.createdAt) || Date.now(),
      lastPlayed: Date.now(),
    };

    const existing = profileStore.profiles.get(id);
    if (existing) {
      clean.questStage = Math.max(existing.questStage, clean.questStage);
      clean.seals = existing.seals | clean.seals;
      clean.hasBadge = existing.hasBadge || clean.hasBadge;
      clean.cleared = [...new Set([...existing.cleared, ...clean.cleared])].sort();
      clean.createdAt = existing.createdAt;
    }

    profileStore.profiles.set(id, clean);
    merged++;
  }

  profileStore.save();
  res.json({ ok: true, merged, skipped, total: profileStore.profiles.size });
});

app.get('/profiles/count', (req, res) => {
  if (!requireExportToken(req, res)) return;
  const profiles = [...profileStore.profiles.values()];
  res.json({
    count: profiles.length,
    clearedByFloor: [1, 2, 3, 4, 5].map(f => ({
      floor: f,
      players: profiles.filter(p => p.cleared.includes(f)).length,
    })),
  });
});

const server = http.createServer(app);
const gameServer = new Server({ server });
gameServer.define('overworld', OverworldRoom);
for (let f = 1; f <= 5; f++) gameServer.define('dungeon_' + f, DungeonRoom);

const port = process.env.PORT || 2567;
gameServer.listen(port).then(() => {
  const n = profileStore.profiles.size;
  console.log('Underlay v7 listening on :' + port);
  console.log('Profiles loaded: ' + n + (n === 0 ? ' (empty — first run or after redeploy)' : ''));
  console.log(EXPORT_TOKEN
    ? 'Export/import: ENABLED'
    : 'Export/import: DISABLED (set EXPORT_TOKEN to enable)');
});
