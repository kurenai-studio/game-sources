// Sky Isles — boot, game loop, interactions, debug handle.
import * as THREE from 'three';
import { Rng } from './sim/rng.js';
import { ChimePuzzle, CHIMES, MURAL_ORDER } from './sim/puzzle.js';
import { AudioEngine } from './sim/audio.js';
import { Player } from './sim/player.js';
import { UI } from './ui.js';
import { buildSky } from './world/sky.js';
import { buildIslands, updateJumpPads } from './world/islands.js';
import { buildBridges } from './world/bridges.js';
import { buildClouds } from './world/clouds.js';
import { buildProps } from './world/props.js';
import { buildChimes } from './world/chimes.js';
import { buildPortal, BONUS_POS } from './world/portal.js';

const canvas = document.getElementById('scene');
const isMobile = window.matchMedia('(pointer: coarse)').matches || 'ontouchstart' in window;

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, isMobile ? 1.5 : 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.12;

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.1, 900);
camera.position.set(0, 6, 12);

const rng = new Rng(20260718);

// ----- world -----
const sky = buildSky(scene);
const islands = buildIslands(scene, rng);
const bridges = buildBridges(scene, islands.islands, rng);
const clouds = buildClouds(scene, rng);
const props = buildProps(islands.islands, rng);
const chimes = buildChimes(islands.islands);
const portal = buildPortal(scene, islands.islands[0], rng);

const colliders = [
  ...islands.colliders,
  ...bridges.colliders,
  ...portal.bonusColliders
];

// ----- sim -----
const puzzle = new ChimePuzzle();
const audio = new AudioEngine();
const player = new Player(scene, camera, colliders);
if (isMobile) {
  // portrait screens show too much empty sky at the default pitch —
  // start a touch higher and closer so ground + nearby isles fill the frame
  player.orbit.pitch = 0.58;
  player.orbit.dist = 9;
  player.orbit.yaw = -1.08; // face the tree isle + bridge on load
}
const ui = new UI();

player.onJumpPad = () => {
  audio.boing();
  ui.hint('Boing! Hold jump to glide', 1800);
};

let started = false;
let onBonusIsland = false;

// ----- chime playing -----
function playChime(index) {
  const chime = chimes.chimes[index];
  if (!chime) return null;
  const result = puzzle.play(index);
  chime.playPulse = 1;
  if (result.type === 'correct' || result.type === 'replay') {
    audio.bell(CHIMES[index].note);
    audio.setUnlocked(puzzle.unlocked);
  } else {
    audio.lowTone();
  }
  ui.setChimes(puzzle.unlocked, MURAL_ORDER);
  if (result.type === 'wrong') {
    ui.hint('The chimes fall silent… follow the mural order', 2600);
  } else if (result.complete && result.type === 'correct') {
    portal.open();
    audio.portalWhoosh();
    ui.hint('A portal shimmers open on the home isle!', 4200);
  } else {
    ui.hint(`${CHIMES[index].id} chime rings — ${puzzle.unlocked} of ${MURAL_ORDER.length}`, 2000);
  }
  return result;
}

function tryInteract() {
  const near = chimes.nearest(player.pos);
  if (near) playChime(near.index);
}

// tap a chime directly (mobile friendly)
const tapRay = new THREE.Raycaster();
const tapNdc = new THREE.Vector2();
ui.onTap = (nx, ny) => {
  tapNdc.set(nx, ny);
  tapRay.setFromCamera(tapNdc, camera);
  const hits = tapRay.intersectObjects(chimes.hitMeshes, false);
  if (hits.length) {
    const idx = hits[0].object.userData.chimeIndex;
    const c = chimes.chimes[idx];
    if (c.worldPos.distanceTo(player.pos) < 5.5) playChime(idx);
    else ui.hint('Move closer to ring this chime', 1800);
  }
};
ui.onInteract = tryInteract;
ui.bindCanvas(canvas);

// ----- portal travel -----
function checkPortalTravel() {
  if (portal.state.open && !onBonusIsland) {
    if (player.pos.distanceTo(portal.homePortalWorld) < 1.7) {
      onBonusIsland = true;
      player.teleport(BONUS_POS.x + 1.5, BONUS_POS.y + 0.6, BONUS_POS.z + 1.5);
      audio.portalWhoosh();
      ui.hint('The star isle — a quiet reward among the stars', 4200);
    }
  } else if (onBonusIsland) {
    if (player.pos.distanceTo(portal.backPortalWorld) < 1.7) {
      onBonusIsland = false;
      const p = portal.homePortalWorld;
      player.teleport(p.x + 1.2, p.y + 0.4, p.z + 1.2);
      audio.portalWhoosh();
    }
  }
}

// ----- start flow -----
ui.onStart(() => {
  ui.hideTitle();
  audio.ensure();
  audio.startAmbient();
  started = true;
  ui.hint('Find the five chimes — the mural shows their song', 4200);
});

// ----- resize -----
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// ----- debug handle for e2e / QA -----
window.__skyisles = {
  getState() {
    return {
      chimesUnlocked: puzzle.unlocked,
      portalOpen: puzzle.portalOpen,
      playerPos: { x: player.pos.x, y: player.pos.y, z: player.pos.z },
      onBonusIsland,
      started,
      muralOrder: [...MURAL_ORDER],
      portalPos: {
        x: portal.homePortalWorld.x,
        y: portal.homePortalWorld.y,
        z: portal.homePortalWorld.z
      }
    };
  },
  teleport(x, y, z) {
    player.teleport(x, y, z);
  },
  playChime(index) {
    return playChime(index);
  },
  setOrbit(yaw, pitch, dist) {
    player.orbit.yaw = yaw;
    player.orbit.pitch = pitch;
    player.orbit.dist = dist;
  },
  start() {
    if (!started) {
      ui.hideTitle();
      started = true;
    }
  },
  world: { scene, camera, renderer, islands, bridges, portal, chimes, player, puzzle }
};

// ----- main loop -----
const clock = new THREE.Clock();
let firstFrame = true;
const playerCenter = new THREE.Vector3();

function frame() {
  requestAnimationFrame(frame);
  const dt = Math.min(clock.getDelta(), 0.05);
  const t = clock.elapsedTime;

  const input = started
    ? ui.poll(player.orbit)
    : { x: 0, z: 0, jumpPressed: false, jumpHeld: false };

  player.update(dt, input, t);
  checkPortalTravel();

  playerCenter.copy(player.pos);
  playerCenter.y += 1.2;
  chimes.update(t, dt, started ? playerCenter : null);
  sky.update(t, dt);
  clouds.update(t, dt, camera);
  bridges.update(t);
  props.update(t, dt);
  portal.update(t, dt);
  updateJumpPads(islands.jumpPads, t, dt);

  renderer.render(scene, camera);

  if (firstFrame) {
    firstFrame = false;
    ui.hideLoading();
  }
}
frame();
