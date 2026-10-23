import * as THREE from "three";
import "./styles.css";

const gameRoot = document.querySelector("#game");
const scoreElement = document.querySelector("#score");
const crystalElement = document.querySelector("#crystals");
const speedElement = document.querySelector("#speed");
const gameOverPanel = document.querySelector("#game-over");
const finalScoreElement = document.querySelector("#final-score");
const restartButton = document.querySelector("#restart-button");

const laneCenters = [-5.6, -2.8, 0, 2.8, 5.6];
const playerCollisionRadius = 0.48;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x050816);
scene.fog = new THREE.Fog(0x050816, 18, 58);

const camera = new THREE.PerspectiveCamera(
  60,
  window.innerWidth / window.innerHeight,
  0.1,
  120,
);
camera.position.set(0, 8, 11);
camera.lookAt(0, 0, -7);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
gameRoot.appendChild(renderer.domElement);

const ambientLight = new THREE.AmbientLight(0x8fb9ff, 0.58);
scene.add(ambientLight);

const directionalLight = new THREE.DirectionalLight(0xffffff, 1.1);
directionalLight.position.set(7, 12, 8);
directionalLight.castShadow = true;
directionalLight.shadow.mapSize.set(1024, 1024);
scene.add(directionalLight);

const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(16, 64),
  new THREE.MeshStandardMaterial({
    color: 0x18243c,
    roughness: 0.82,
    metalness: 0.08,
  }),
);
ground.rotation.x = -Math.PI / 2;
ground.position.z = -12;
ground.receiveShadow = true;
scene.add(ground);

const laneLines = new THREE.Group();
const lineMaterial = new THREE.MeshBasicMaterial({ color: 0x335b8e });
const laneGlowMaterial = new THREE.MeshBasicMaterial({
  color: 0x4aa3ff,
  transparent: true,
  opacity: 0.22,
});

for (let x = -7; x <= 7; x += 2.8) {
  const line = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.04, 58), lineMaterial);
  line.position.set(x, 0.025, -12);
  laneLines.add(line);
}

for (const x of laneCenters) {
  const glow = new THREE.Mesh(new THREE.BoxGeometry(0.4, 0.025, 58), laneGlowMaterial);
  glow.position.set(x, 0.035, -12);
  laneLines.add(glow);
}
scene.add(laneLines);

const player = createShip();
player.position.set(0, 0.7, 3.2);
scene.add(player);

const clock = new THREE.Clock();
const keys = new Set();
const asteroids = [];
const crystals = [];

let spawnTimer = 1.2;
let crystalTimer = 0;
let elapsedActiveTime = 0;
let score = 0;
let crystalCount = 0;
let speedMultiplier = 1;
let boostPulseTime = 0;
let gameActive = true;

function createShip() {
  const ship = new THREE.Group();

  const hullMaterial = new THREE.MeshStandardMaterial({
    color: 0x4fc3ff,
    roughness: 0.38,
    metalness: 0.4,
  });
  const noseMaterial = new THREE.MeshStandardMaterial({
    color: 0xffe066,
    roughness: 0.3,
    metalness: 0.22,
  });
  const wingMaterial = new THREE.MeshStandardMaterial({
    color: 0xff6b6b,
    roughness: 0.48,
    metalness: 0.18,
  });

  const body = new THREE.Mesh(new THREE.ConeGeometry(0.48, 1.45, 5), hullMaterial);
  body.rotation.x = Math.PI / 2;
  body.castShadow = true;
  ship.add(body);

  const cockpit = new THREE.Mesh(new THREE.SphereGeometry(0.25, 16, 10), noseMaterial);
  cockpit.scale.set(1, 0.55, 1);
  cockpit.position.set(0, 0.27, 0.18);
  cockpit.castShadow = true;
  ship.add(cockpit);

  const leftWing = new THREE.Mesh(new THREE.BoxGeometry(0.72, 0.12, 0.34), wingMaterial);
  leftWing.position.set(-0.46, -0.04, 0.13);
  leftWing.rotation.z = -0.22;
  leftWing.castShadow = true;
  ship.add(leftWing);

  const rightWing = leftWing.clone();
  rightWing.position.x = 0.46;
  rightWing.rotation.z = 0.22;
  ship.add(rightWing);

  const engine = new THREE.Mesh(
    new THREE.CylinderGeometry(0.2, 0.24, 0.28, 12),
    new THREE.MeshStandardMaterial({ color: 0xa7b5c9, metalness: 0.55, roughness: 0.28 }),
  );
  engine.rotation.x = Math.PI / 2;
  engine.position.z = 0.72;
  engine.castShadow = true;
  ship.add(engine);

  const flame = new THREE.Mesh(
    new THREE.ConeGeometry(0.16, 0.55, 12),
    new THREE.MeshBasicMaterial({ color: 0xff9f1c, transparent: true, opacity: 0.7 }),
  );
  flame.name = "engineFlame";
  flame.rotation.x = -Math.PI / 2;
  flame.position.z = 1.14;
  flame.visible = false;
  ship.add(flame);

  return ship;
}

function createAsteroid() {
  const radius = randomBetween(0.44, 0.74);
  const asteroid = new THREE.Mesh(
    new THREE.DodecahedronGeometry(radius, 0),
    new THREE.MeshStandardMaterial({
      color: 0x8b6f55,
      roughness: 0.95,
      metalness: 0.02,
    }),
  );
  asteroid.position.set(randomLane(), randomBetween(0.52, 1.15), -40);
  asteroid.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, 0);
  asteroid.userData.speed = randomBetween(6.2, 8.4);
  asteroid.userData.collisionRadius = radius * 0.62;
  asteroid.userData.spin = new THREE.Vector3(
    randomBetween(-1.6, 1.6),
    randomBetween(-1.6, 1.6),
    randomBetween(-1.6, 1.6),
  );
  asteroid.castShadow = true;
  scene.add(asteroid);
  asteroids.push(asteroid);
}

function createCrystal() {
  const crystal = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.38, 0),
    new THREE.MeshStandardMaterial({
      color: 0x6df7d2,
      emissive: 0x155d55,
      roughness: 0.2,
      metalness: 0.28,
    }),
  );
  crystal.position.set(randomLane(), randomBetween(0.65, 1.35), -40);
  crystal.userData.speed = randomBetween(7.5, 10);
  crystal.userData.collisionRadius = 0.62;
  crystal.castShadow = true;
  scene.add(crystal);
  crystals.push(crystal);
}

function createStars() {
  const starGeometry = new THREE.BufferGeometry();
  const positions = [];

  for (let i = 0; i < 500; i += 1) {
    positions.push(randomBetween(-44, 44), randomBetween(6, 34), randomBetween(-62, 18));
  }

  starGeometry.setAttribute("position", new THREE.Float32BufferAttribute(positions, 3));

  const stars = new THREE.Points(
    starGeometry,
    new THREE.PointsMaterial({
      color: 0xdbe9ff,
      size: 0.08,
      sizeAttenuation: true,
    }),
  );
  scene.add(stars);
}

function updatePlayer(delta) {
  let moveX = 0;

  if (keys.has("arrowleft") || keys.has("a")) moveX -= 1;
  if (keys.has("arrowright") || keys.has("d")) moveX += 1;

  player.position.x += moveX * 7.4 * delta;
  player.position.x = THREE.MathUtils.clamp(player.position.x, -6.2, 6.2);

  boostPulseTime = Math.max(0, boostPulseTime - delta);

  const boosting = keys.has("arrowup") || keys.has("w") || boostPulseTime > 0;
  const braking = keys.has("arrowdown") || keys.has("s");
  const targetSpeed = boosting ? 1.75 : braking ? 0.7 : 1;
  speedMultiplier = THREE.MathUtils.lerp(speedMultiplier, targetSpeed, 4 * delta);
  speedElement.textContent = `${speedMultiplier.toFixed(1)}x`;

  const flame = player.getObjectByName("engineFlame");
  if (flame) {
    flame.visible = speedMultiplier > 1.15;
    flame.scale.z = 0.8 + (speedMultiplier - 1) * 0.85;
  }

  player.rotation.z = THREE.MathUtils.lerp(player.rotation.z, -moveX * 0.38, 8 * delta);
  player.rotation.x = THREE.MathUtils.lerp(player.rotation.x, boosting ? -0.15 : braking ? 0.12 : 0, 8 * delta);
}

function updateObjects(delta) {
  spawnTimer -= delta;
  crystalTimer -= delta;

  if (spawnTimer <= 0) {
    createAsteroid();
    spawnTimer = randomBetween(0.9, 1.45);
  }

  if (crystalTimer <= 0) {
    createCrystal();
    crystalTimer = randomBetween(1.25, 2.2);
  }

  moveObjects(asteroids, delta, false);
  moveObjects(crystals, delta, true);
}

function moveObjects(objects, delta, isCrystal) {
  for (let i = objects.length - 1; i >= 0; i -= 1) {
    const object = objects[i];
    object.position.z += object.userData.speed * speedMultiplier * delta;

    if (isCrystal) {
      object.rotation.y += delta * 2.7;
      object.rotation.z += delta * 1.6;
    } else {
      object.rotation.x += object.userData.spin.x * delta;
      object.rotation.y += object.userData.spin.y * delta;
      object.rotation.z += object.userData.spin.z * delta;
    }

    if (object.position.z > 8) {
      scene.remove(object);
      objects.splice(i, 1);
    }
  }
}

function checkCollisions() {
  for (const asteroid of asteroids) {
    if (hasPlayerCollision(asteroid)) {
      endGame();
      return;
    }
  }

  for (let i = crystals.length - 1; i >= 0; i -= 1) {
    const crystal = crystals[i];
    if (hasPlayerCollision(crystal)) {
      crystalCount += 1;
      score += 50;
      crystalElement.textContent = crystalCount;
      scene.remove(crystal);
      crystals.splice(i, 1);
    }
  }
}

function updateScore() {
  score = Math.floor(elapsedActiveTime * 10 * speedMultiplier) + crystalCount * 50;
  scoreElement.textContent = score;
}

function endGame() {
  gameActive = false;
  finalScoreElement.textContent = `Score: ${score}`;
  gameOverPanel.classList.remove("hidden");
}

function restartGame() {
  for (const object of [...asteroids, ...crystals]) {
    scene.remove(object);
  }
  asteroids.length = 0;
  crystals.length = 0;

  player.position.set(0, 0.7, 3.2);
  player.rotation.set(0, 0, 0);
  spawnTimer = 1.2;
  crystalTimer = 0.8;
  elapsedActiveTime = 0;
  score = 0;
  crystalCount = 0;
  speedMultiplier = 1;
  boostPulseTime = 0;
  gameActive = true;
  scoreElement.textContent = "0";
  crystalElement.textContent = "0";
  speedElement.textContent = "1.0x";
  gameOverPanel.classList.add("hidden");
  clock.getDelta();
}

function animate() {
  requestAnimationFrame(animate);
  const delta = Math.min(clock.getDelta(), 0.05);

  if (gameActive) {
    elapsedActiveTime += delta;
    updatePlayer(delta);
    updateObjects(delta);
    checkCollisions();
    updateScore();
  }

  camera.position.x = THREE.MathUtils.lerp(camera.position.x, player.position.x * 0.18, 3 * delta);
  camera.lookAt(player.position.x * 0.12, 0.25, -7);
  renderer.render(scene, camera);
}

function randomBetween(min, max) {
  return min + Math.random() * (max - min);
}

function randomLane() {
  return laneCenters[Math.floor(Math.random() * laneCenters.length)];
}

function hasPlayerCollision(object) {
  const dx = player.position.x - object.position.x;
  const dy = player.position.y - object.position.y;
  const dz = player.position.z - object.position.z;
  const distance = Math.sqrt(dx * dx + dy * dy * 0.35 + dz * dz);
  return distance < playerCollisionRadius + object.userData.collisionRadius;
}

window.addEventListener("keydown", (event) => {
  const key = event.key.toLowerCase();
  keys.add(key);

  if (key === "w" || key === "arrowup") {
    boostPulseTime = 0.55;
  }

  if (key === "r" && !gameActive) {
    restartGame();
  }
});

window.addEventListener("keyup", (event) => {
  keys.delete(event.key.toLowerCase());
});

window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

restartButton.addEventListener("click", restartGame);

createStars();
animate();
