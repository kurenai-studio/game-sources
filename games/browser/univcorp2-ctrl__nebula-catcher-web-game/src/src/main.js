import './styles.css';
import { WORLD, clamp, createFallingObject, createGameState, createRng, formatTime, getDifficulty, movePlayer, movePlayerToward, nextSpawnIntervalSeconds, resolveCollisions, updateEntities } from './gameLogic.js';

const canvas = document.querySelector('#game');
const ctx = canvas.getContext('2d');
const scoreEl = document.querySelector('#score');
const livesEl = document.querySelector('#lives');
const timeEl = document.querySelector('#time');
const highScoreEl = document.querySelector('#high-score');
const startButton = document.querySelector('#start-button');
const STORAGE_KEY = 'nebula-catcher-high-score';
const keys = new Set();
const stars = Array.from({ length: 86 }, (_, index) => ({ x: (index * 97) % WORLD.width, y: (index * 53) % WORLD.height, radius: 0.8 + (index % 4) * 0.45, alpha: 0.35 + (index % 5) * 0.12 }));
let state = createGameState();
let rng = createRng(Date.now());
let lastFrame = performance.now();
let running = false;
let targetX = null;

function readHighScore() {
  return Number.parseInt(localStorage.getItem(STORAGE_KEY) || '0', 10);
}

function writeHighScore(score) {
  const current = readHighScore();
  if (score > current) localStorage.setItem(STORAGE_KEY, String(score));
  highScoreEl.textContent = String(Math.max(score, current));
}

function resetGame() {
  state = createGameState();
  rng = createRng(Date.now());
  running = true;
  targetX = null;
  lastFrame = performance.now();
  writeHighScore(0);
  startButton.textContent = 'Restart';
}

function directionFromKeys() {
  const left = keys.has('ArrowLeft') || keys.has('KeyA');
  const right = keys.has('ArrowRight') || keys.has('KeyD');
  return (right ? 1 : 0) - (left ? 1 : 0);
}

function update(deltaSeconds) {
  if (!running || state.gameOver) return;
  const direction = directionFromKeys();
  if (direction !== 0) {
    targetX = null;
    state.player = movePlayer(state.player, direction, deltaSeconds);
  } else if (targetX !== null) {
    state.player = movePlayerToward(state.player, targetX, deltaSeconds);
  }
  state.elapsedMs += deltaSeconds * 1000;
  state.entities = updateEntities(state.entities, deltaSeconds);
  const difficulty = getDifficulty(state.score, state.elapsedMs);
  state.spawnTimer -= deltaSeconds;
  while (state.spawnTimer <= 0) {
    state.entities.push(createFallingObject(rng, difficulty, state.nextId++));
    state.spawnTimer += nextSpawnIntervalSeconds(difficulty);
  }
  state = resolveCollisions(state);
  if (state.gameOver) {
    running = false;
    startButton.textContent = 'Play Again';
    writeHighScore(state.score);
  }
}

function drawBackground(timeMs) {
  const gradient = ctx.createLinearGradient(0, 0, 0, WORLD.height);
  gradient.addColorStop(0, '#080b20');
  gradient.addColorStop(0.52, '#111a3f');
  gradient.addColorStop(1, '#26104a');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, WORLD.width, WORLD.height);
  for (const star of stars) {
    const twinkle = Math.sin(timeMs * 0.0015 + star.x) * 0.18;
    ctx.globalAlpha = clamp(star.alpha + twinkle, 0.15, 1);
    ctx.beginPath();
    ctx.arc(star.x, (star.y + timeMs * 0.008) % WORLD.height, star.radius, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.fill();
  }
  ctx.globalAlpha = 1;
}

function drawPlayer() {
  const player = state.player;
  ctx.save();
  ctx.translate(player.x + player.width / 2, player.y + player.height / 2);
  ctx.shadowColor = '#80f5ff';
  ctx.shadowBlur = 20;
  ctx.fillStyle = '#70f5ff';
  ctx.beginPath();
  ctx.moveTo(0, -player.height / 2);
  ctx.lineTo(player.width / 2, player.height / 2);
  ctx.lineTo(0, player.height / 3);
  ctx.lineTo(-player.width / 2, player.height / 2);
  ctx.closePath();
  ctx.fill();
  ctx.shadowBlur = 0;
  ctx.fillStyle = '#17234f';
  ctx.beginPath();
  ctx.ellipse(0, 0, player.width * 0.18, player.height * 0.22, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

function drawStar(entity) {
  ctx.save();
  ctx.translate(entity.x + entity.width / 2, entity.y + entity.height / 2);
  ctx.rotate(entity.rotation);
  ctx.shadowColor = '#ffe66d';
  ctx.shadowBlur = 18;
  ctx.fillStyle = '#ffe66d';
  ctx.beginPath();
  for (let point = 0; point < 10; point += 1) {
    const radius = point % 2 === 0 ? entity.width / 2 : entity.width / 5;
    const angle = (Math.PI / 5) * point - Math.PI / 2;
    const x = Math.cos(angle) * radius;
    const y = Math.sin(angle) * radius;
    if (point === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

function drawMeteor(entity) {
  ctx.save();
  ctx.translate(entity.x + entity.width / 2, entity.y + entity.height / 2);
  ctx.rotate(entity.rotation);
  ctx.shadowColor = '#ff7a45';
  ctx.shadowBlur = 14;
  ctx.fillStyle = '#ff7a45';
  ctx.beginPath();
  ctx.ellipse(0, 0, entity.width / 2, entity.height / 2.6, 0.25, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

function drawGameOver() {
  if (!state.gameOver) return;
  ctx.save();
  ctx.fillStyle = 'rgba(5, 8, 20, 0.72)';
  ctx.fillRect(0, 0, WORLD.width, WORLD.height);
  ctx.textAlign = 'center';
  ctx.fillStyle = '#ffffff';
  ctx.font = '700 48px Inter, system-ui, sans-serif';
  ctx.fillText('Game Over', WORLD.width / 2, WORLD.height / 2 - 20);
  ctx.font = '500 22px Inter, system-ui, sans-serif';
  ctx.fillText(`Score: ${state.score}`, WORLD.width / 2, WORLD.height / 2 + 24);
  ctx.fillText('Start / Restart で再挑戦', WORLD.width / 2, WORLD.height / 2 + 62);
  ctx.restore();
}

function render(timeMs = performance.now()) {
  drawBackground(timeMs);
  for (const entity of state.entities) entity.type === 'star' ? drawStar(entity) : drawMeteor(entity);
  drawPlayer();
  drawGameOver();
  scoreEl.textContent = String(state.score);
  livesEl.textContent = String(Math.max(0, state.lives));
  timeEl.textContent = formatTime(state.elapsedMs);
}

function loop(now) {
  const deltaSeconds = Math.min((now - lastFrame) / 1000, 0.033);
  lastFrame = now;
  update(deltaSeconds);
  render(now);
  requestAnimationFrame(loop);
}

function canvasPointerToWorldX(event) {
  const rect = canvas.getBoundingClientRect();
  return ((event.clientX - rect.left) / rect.width) * WORLD.width;
}

window.addEventListener('keydown', (event) => {
  if (['ArrowLeft', 'ArrowRight', 'KeyA', 'KeyD', 'Space', 'Enter'].includes(event.code)) event.preventDefault();
  if (event.code === 'Space' || event.code === 'Enter') resetGame();
  keys.add(event.code);
});
window.addEventListener('keyup', (event) => keys.delete(event.code));
canvas.addEventListener('pointerdown', (event) => {
  targetX = canvasPointerToWorldX(event);
  canvas.setPointerCapture(event.pointerId);
});
canvas.addEventListener('pointermove', (event) => {
  if (event.buttons > 0) targetX = canvasPointerToWorldX(event);
});
canvas.addEventListener('pointerup', () => {
  targetX = null;
});
startButton.addEventListener('click', resetGame);
writeHighScore(0);
render();
requestAnimationFrame(loop);
