export const WORLD = Object.freeze({ width: 800, height: 520 });
export const PLAYER = Object.freeze({ width: 58, height: 48, speed: 470 });

export function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

export function createRng(seed = Date.now()) {
  let state = seed >>> 0;
  return function random() {
    state += 0x6d2b79f5;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function createGameState() {
  return {
    score: 0,
    lives: 3,
    elapsedMs: 0,
    spawnTimer: 0,
    nextId: 1,
    gameOver: false,
    player: {
      x: WORLD.width / 2 - PLAYER.width / 2,
      y: WORLD.height - PLAYER.height - 26,
      width: PLAYER.width,
      height: PLAYER.height,
      speed: PLAYER.speed
    },
    entities: []
  };
}

export function getDifficulty(score, elapsedMs) {
  const timeFactor = elapsedMs / 30000;
  const scoreFactor = score / 180;
  return clamp(1 + timeFactor + scoreFactor, 1, 4.5);
}

export function movePlayer(player, direction, deltaSeconds, bounds = WORLD) {
  return {
    ...player,
    x: clamp(player.x + direction * player.speed * deltaSeconds, 0, bounds.width - player.width)
  };
}

export function movePlayerToward(player, targetX, deltaSeconds, bounds = WORLD) {
  const centerX = player.x + player.width / 2;
  const distance = targetX - centerX;
  if (Math.abs(distance) < 2) return player;
  const maxStep = player.speed * deltaSeconds;
  const nextCenter = Math.abs(distance) <= maxStep ? targetX : centerX + Math.sign(distance) * maxStep;
  return { ...player, x: clamp(nextCenter - player.width / 2, 0, bounds.width - player.width) };
}

export function rectsOverlap(a, b) {
  return a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y;
}

export function createFallingObject(rng, difficulty, id, bounds = WORLD) {
  const isStar = rng() < 0.74;
  const size = isStar ? 28 + rng() * 10 : 34 + rng() * 20;
  const speed = (isStar ? 145 : 185) + rng() * 120 + difficulty * 34;
  return {
    id,
    type: isStar ? 'star' : 'meteor',
    x: rng() * (bounds.width - size),
    y: -size - rng() * 90,
    width: size,
    height: size,
    speed,
    rotation: rng() * Math.PI * 2,
    spin: (rng() - 0.5) * 4
  };
}

export function updateEntities(entities, deltaSeconds, bounds = WORLD) {
  return entities
    .map((entity) => ({ ...entity, y: entity.y + entity.speed * deltaSeconds, rotation: entity.rotation + entity.spin * deltaSeconds }))
    .filter((entity) => entity.y < bounds.height + entity.height);
}

export function resolveCollisions(state) {
  let scoreDelta = 0;
  let livesDelta = 0;
  const remaining = [];
  for (const entity of state.entities) {
    if (!rectsOverlap(state.player, entity)) {
      remaining.push(entity);
    } else if (entity.type === 'star') {
      scoreDelta += 10;
    } else {
      livesDelta -= 1;
    }
  }
  return { ...state, score: state.score + scoreDelta, lives: state.lives + livesDelta, entities: remaining, gameOver: state.lives + livesDelta <= 0 };
}

export function formatTime(milliseconds) {
  return `${(milliseconds / 1000).toFixed(1)}s`;
}

export function nextSpawnIntervalSeconds(difficulty) {
  return clamp(0.86 - difficulty * 0.095, 0.28, 0.78);
}
