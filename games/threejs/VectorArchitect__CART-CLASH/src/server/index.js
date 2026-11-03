const express = require('express');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const { randomBytes } = require('crypto');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });
const PORT = process.env.PORT || 3000;
const TICK_RATE = 30;
const ARENA_LIMIT = 27.5; // keeps carts inside the visible walls (inner face at 29)
const BULLET_LIMIT = 29;
const MATCH_SECONDS = 180;
const rooms = new Map();

app.use(express.static(path.join(__dirname, '..', 'client')));
app.get('/health', (_req, res) => res.json({ ok: true, rooms: rooms.size }));
app.get('*', (_req, res) => res.sendFile(path.join(__dirname, '..', 'client', 'index.html')));

function makeCode() {
  let code;
  do { code = randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(code));
  return code;
}
function cleanPlayer(p) {
  return { id: p.id, name: p.name, x: p.x, z: p.z, yaw: p.yaw, aimYaw: p.aimYaw, health: p.health, score: p.score, color: p.color, alive: p.alive };
}
function roomSnapshot(room) {
  return {
    code: room.code,
    status: room.status,
    timeLeft: room.timeLeft,
    players: [...room.players.values()].map(cleanPlayer),
    bullets: room.bullets.map(b => ({ id: b.id, x: b.x, z: b.z, yaw: b.yaw, owner: b.owner }))
  };
}
function startRoom(room) {
  if (room.players.size !== 2 || room.status !== 'waiting') return;
  room.status = 'playing';
  room.timeLeft = MATCH_SECONDS;
  room.lastTick = Date.now();
  const players = [...room.players.values()];
  players[0].x = -18; players[0].z = 0; players[0].yaw = Math.PI / 2; players[0].color = 0x36a2ff;
  players[1].x = 18; players[1].z = 0; players[1].yaw = -Math.PI / 2; players[1].color = 0xff5c68;
  room.players.forEach(p => { p.health = 100; p.score = 0; p.alive = true; p.input = { forward: 0, turn: 0, aimYaw: p.yaw, fire: false }; });
  io.to(room.code).emit('gameStarted', roomSnapshot(room));
}
function finishRoom(room, reason) {
  if (room.status !== 'playing') return;
  room.status = 'finished';
  const players = [...room.players.values()];
  let winner = null;
  if (players.length === 2) {
    if (players[0].health !== players[1].health) winner = players[0].health > players[1].health ? players[0].id : players[1].id;
    else if (players[0].score !== players[1].score) winner = players[0].score > players[1].score ? players[0].id : players[1].id;
  }
  io.to(room.code).emit('gameOver', { reason, winner, players: players.map(cleanPlayer) });
}

io.on('connection', socket => {
  socket.on('createRoom', ({ name } = {}, callback = () => {}) => {
    const code = makeCode();
    const player = { id: socket.id, name: String(name || 'Player 1').slice(0, 16), x: -18, z: 0, yaw: Math.PI / 2, aimYaw: Math.PI / 2, health: 100, score: 0, color: 0x36a2ff, alive: true, input: { forward: 0, turn: 0, aimYaw: Math.PI / 2, fire: false }, lastShot: 0 };
    const room = { code, status: 'waiting', players: new Map([[socket.id, player]]), bullets: [], timeLeft: MATCH_SECONDS, lastTick: Date.now(), createdAt: Date.now() };
    rooms.set(code, room); socket.join(code); socket.data.roomCode = code;
    callback({ ok: true, code, playerId: socket.id, snapshot: roomSnapshot(room) });
  });
  socket.on('joinRoom', ({ code, name } = {}, callback = () => {}) => {
    const room = rooms.get(String(code || '').trim().toUpperCase());
    if (!room) return callback({ ok: false, error: 'Room not found. Check the code and try again.' });
    if (room.players.size >= 2) return callback({ ok: false, error: 'This room is full.' });
    if (room.status !== 'waiting') return callback({ ok: false, error: 'This match has already started.' });
    const player = { id: socket.id, name: String(name || 'Player 2').slice(0, 16), x: 18, z: 0, yaw: -Math.PI / 2, aimYaw: -Math.PI / 2, health: 100, score: 0, color: 0xff5c68, alive: true, input: { forward: 0, turn: 0, aimYaw: -Math.PI / 2, fire: false }, lastShot: 0 };
    room.players.set(socket.id, player); socket.join(room.code); socket.data.roomCode = room.code;
    callback({ ok: true, code: room.code, playerId: socket.id, snapshot: roomSnapshot(room) });
    io.to(room.code).emit('lobbyUpdate', roomSnapshot(room));
    startRoom(room);
  });
  socket.on('input', input => {
    const room = rooms.get(socket.data.roomCode);
    if (!room || room.status !== 'playing') return;
    const p = room.players.get(socket.id);
    if (!p || !p.alive) return;
    p.input = {
      forward: Math.max(-1, Math.min(1, Number(input?.forward) || 0)),
      turn: Math.max(-1, Math.min(1, Number(input?.turn) || 0)),
      aimYaw: Number.isFinite(input?.aimYaw) ? input.aimYaw : p.aimYaw,
      fire: Boolean(input?.fire)
    };
  });
  socket.on('leaveRoom', () => socket.disconnect(true));
  socket.on('disconnect', () => {
    const code = socket.data.roomCode;
    const room = rooms.get(code);
    if (!room) return;
    room.players.delete(socket.id);
    if (room.status === 'playing') io.to(code).emit('opponentDisconnected');
    if (room.players.size === 0 || room.status === 'playing') rooms.delete(code);
    else io.to(code).emit('lobbyUpdate', roomSnapshot(room));
  });
});

setInterval(() => {
  const now = Date.now();
  for (const room of rooms.values()) {
    if (room.status !== 'playing') continue;
    const dt = Math.min(0.05, (now - room.lastTick) / 1000 || 1 / TICK_RATE);
    room.lastTick = now;
    room.timeLeft = Math.max(0, room.timeLeft - dt);
    for (const p of room.players.values()) {
      if (!p.alive) continue;
      const input = p.input;
      p.yaw += input.turn * 2.35 * dt;
      p.aimYaw = input.aimYaw;
      const speed = input.forward < 0 ? 8 : 13;
      p.x += Math.sin(p.yaw) * input.forward * speed * dt;
      p.z += Math.cos(p.yaw) * input.forward * speed * dt;
      p.x = Math.max(-ARENA_LIMIT, Math.min(ARENA_LIMIT, p.x));
      p.z = Math.max(-ARENA_LIMIT, Math.min(ARENA_LIMIT, p.z));
      if (input.fire && now - p.lastShot > 420) {
        p.lastShot = now;
        const id = randomBytes(4).toString('hex');
        room.bullets.push({ id, owner: p.id, x: p.x + Math.sin(p.aimYaw) * 2.2, z: p.z + Math.cos(p.aimYaw) * 2.2, yaw: p.aimYaw, life: 2.2 });
      }
    }
    for (const b of room.bullets) {
      const velocity = 31 * dt;
      b.x += Math.sin(b.yaw) * velocity;
      b.z += Math.cos(b.yaw) * velocity;
      b.life -= dt;
      for (const p of room.players.values()) {
        if (p.id === b.owner || !p.alive) continue;
        if (Math.hypot(p.x - b.x, p.z - b.z) < 1.65) {
          p.health = Math.max(0, p.health - 12);
          b.life = 0;
          const shooter = room.players.get(b.owner);
          if (shooter) shooter.score += 12;
          if (p.health <= 0) { p.alive = false; finishRoom(room, 'elimination'); }
        }
      }
    }
    room.bullets = room.bullets.filter(b => b.life > 0 && Math.abs(b.x) < BULLET_LIMIT && Math.abs(b.z) < BULLET_LIMIT);
    if (room.timeLeft <= 0) finishRoom(room, 'timer');
    io.to(room.code).emit('state', roomSnapshot(room));
  }
}, 1000 / TICK_RATE);

// Remove abandoned waiting rooms after 30 minutes.
setInterval(() => {
  const cutoff = Date.now() - 30 * 60 * 1000;
  for (const [code, room] of rooms) if (room.status === 'waiting' && room.createdAt < cutoff) rooms.delete(code);
}, 60 * 1000);

server.listen(PORT, () => console.log(`CART CLASH running at http://localhost:${PORT}`));
