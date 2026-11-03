import * as THREE from 'three';
import './styles.css';
import { Input } from './Input.js';
import { World } from './World.js';
import { Mimic } from './Mimic.js';
import { Sniper } from './Sniper.js';
import { Effects } from './Effects.js';
import { UI } from './UI.js';
import { GameStateMachine, ROUND_STATES } from './core/GameStateMachine.js';
import { chooseTransformTarget } from './core/targetSelection.js';

const canvas = document.querySelector('#game');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.75));
renderer.setSize(innerWidth, innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(58, innerWidth / innerHeight, 0.1, 180);
const input = new Input(canvas);
const world = new World(scene);
const effects = new Effects(scene);
const mimic = new Mimic(scene);
const sniper = new Sniper(camera, input, effects);
const ui = new UI();
const machine = new GameStateMachine({ countdown: 2.5, roundDuration: 90 });
const clock = new THREE.Clock();
let transformTarget = null;

function targetCandidates() {
  return world.props.map((prop) => ({
    prop,
    id: prop.uuid,
    distance: prop.position.distanceTo(mimic.group.position),
    highlighted: false,
    eligible: true,
  }));
}

function updateTarget() {
  for (const prop of world.props) prop.material.emissive?.setHex(0x000000);
  const picked = chooseTransformTarget(targetCandidates(), 4);
  transformTarget = picked?.prop ?? null;
  if (transformTarget?.material.emissive) transformTarget.material.emissive.setHex(0x183d35);
}

function startRound() {
  ui.startScreen.classList.remove('visible');
  ui.roundEnd.classList.remove('visible');
  mimic.reset();
  sniper.reset();
  machine.start();
  canvas.requestPointerLock?.();
}

document.querySelector('#startButton').addEventListener('click', startRound);
document.querySelector('#restartButton').addEventListener('click', startRound);
canvas.addEventListener('click', () => {
  if (machine.state === ROUND_STATES.PLAYING && document.pointerLockElement !== canvas) canvas.requestPointerLock?.();
});

machine.onChange(({ state, winner }) => {
  if (state === ROUND_STATES.ROUND_END) {
    document.exitPointerLock?.();
    ui.showEnd(winner, sniper);
  }
});

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.05);
  machine.update(dt);
  const active = machine.state === ROUND_STATES.PLAYING;

  mimic.update(dt, input, active);
  sniper.update(dt, active);
  effects.update(dt);
  updateTarget();

  if (active && input.consumeTransform()) {
    if (mimic.disguise) mimic.reveal((p) => effects.burst(p));
    else if (transformTarget) mimic.transformInto(transformTarget, (p) => effects.burst(p));
  }

  if (active && input.consumeFire()) {
    const shootables = [...world.shootables, mimic.shootable()];
    const hit = sniper.fire(shootables);
    if (hit?.object.userData.isMimic) machine.mimicHit();
  }

  if (active && sniper.weapon.ammo === 0 && sniper.weapon.reserve === 0 && !sniper.weapon.reloading) machine.end('mimic');

  ui.update(machine, sniper, transformTarget);
  renderer.render(scene, camera);
}

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

animate();
window.__MIMIC_SNIPER__ = { scene, camera, renderer, mimic, sniper, machine, world };
window.__THREE_GAME_DIAGNOSTICS__ = { get state() { return { state: machine.state, ammo: sniper.weapon.ammo, mimicDisguised: Boolean(mimic.disguise), drawCalls: renderer.info.render.calls, triangles: renderer.info.render.triangles }; } };
