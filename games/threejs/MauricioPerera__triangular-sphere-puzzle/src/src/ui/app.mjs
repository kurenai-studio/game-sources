import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { Line2 } from 'three/addons/lines/Line2.js';
import { LineGeometry } from 'three/addons/lines/LineGeometry.js';
import { LineMaterial } from 'three/addons/lines/LineMaterial.js';
import { createTriangularSphere } from '../core/triangular-sphere.mjs';
import { applyMove, createPuzzleState, isSolved, shufflePuzzle } from '../core/puzzle-state.mjs';
import { createTargetLabels } from '../core/target-labels.mjs';

const subdivision = 1;
const topology = createTriangularSphere(subdivision);
const targetLabels = createTargetLabels(topology);
const targetLabelsByFace = new Map(targetLabels.map((label) => [label.faceId, label]));
const emptyFaceId = topology.faces.length - 1;
let puzzleState = createPuzzleState(topology, emptyFaceId);
const app = document.querySelector('#app');
const moveCount = document.querySelector('#move-count');
const selection = document.querySelector('#selection');
const targetInfo = document.querySelector('#target-info');
const targetSwatch = document.querySelector('#target-swatch');
const colorMatch = document.querySelector('#color-match');
const numberMatch = document.querySelector('#number-match');
const moveWarning = document.querySelector('#move-warning');
const status = document.querySelector('#status');
const difficultySelect = document.querySelector('#difficulty');
const shuffleButton = document.querySelector('#shuffle-button');
const hud = document.querySelector('.hud');
const panelToggle = document.querySelector('#panel-toggle');

const DIFFICULTY_STEPS = Object.freeze({ easy: 10, medium: 25, hard: 40, expert: 60 });

const scene = new THREE.Scene();
scene.background = new THREE.Color('#070b18');

const camera = new THREE.PerspectiveCamera(42, innerWidth / innerHeight, 0.1, 100);
camera.position.set(0, 0.2, 5.1);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
app.append(renderer.domElement);

scene.add(new THREE.HemisphereLight('#d7edff', '#1b2140', 2.4));
const keyLight = new THREE.DirectionalLight('#ffffff', 2.2);
keyLight.position.set(2, 3, 4);
scene.add(keyLight);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.minDistance = 3;
controls.maxDistance = 8;

function updateCameraFraming() {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  const visibleRadius = 2.25;
  const horizontalHalfFov = Math.atan(
    Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * camera.aspect,
  );
  const requiredDistance = visibleRadius / Math.tan(horizontalHalfFov) + 0.35;
  camera.position.z = Math.max(5.1, requiredDistance);
  controls.maxDistance = Math.max(8, requiredDistance * 1.5);
}

const board = new THREE.Group();
scene.add(board);
const faceMeshes = [];
const faceBordersById = new Map();
const sphereMeshesByBall = new Map();
const numberSpritesByBall = new Map();
const baseColor = new THREE.Color();
const sphereRadius = 0.105;
const sphereSurfaceOffset = 0.24;

function faceCenter(face) {
  const center = new THREE.Vector3();
  for (const vertexId of face.vertices) {
    center.add(new THREE.Vector3(...topology.vertices[vertexId].position));
  }
  return center.multiplyScalar(1 / face.vertices.length);
}

function createFaceMesh(face) {
  const positions = face.vertices.flatMap((vertexId) => topology.vertices[vertexId].position);
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geometry.computeVertexNormals();
  const targetLabel = targetLabelsByFace.get(face.id);
  if (targetLabel) baseColor.set(targetLabel.color);
  else baseColor.setHSL((face.id * 0.6180339887) % 1, 0.68, 0.52);
  const material = new THREE.MeshStandardMaterial({
    color: baseColor,
    roughness: 0.62,
    metalness: 0.08,
    side: THREE.DoubleSide,
  });
  const mesh = new THREE.Mesh(geometry, material);
  mesh.userData.faceId = face.id;
  faceMeshes.push(mesh);
  board.add(mesh);
  createFaceBorder(face);
  return mesh;
}

function createFaceBorder(face) {
  const center = faceCenter(face);
  const normal = center.clone().normalize();
  const points = face.vertices.map((vertexId) => {
    const point = new THREE.Vector3(...topology.vertices[vertexId].position);
    point.lerp(center, 0.18);
    return point.addScaledVector(normal, 0.012);
  });
  const positions = [...points, points[0]].flatMap((point) => point.toArray());
  const geometry = new LineGeometry();
  geometry.setPositions(positions);
  const material = new LineMaterial({
    color: '#ff355d',
    linewidth: 5,
    transparent: true,
    opacity: 0.98,
  });
  material.resolution.set(innerWidth, innerHeight);
  const border = new Line2(geometry, material);
  border.computeLineDistances();
  border.visible = false;
  faceBordersById.set(face.id, border);
  board.add(border);
}

function surfacePosition(face, offset) {
  const center = faceCenter(face);
  const surfaceRadius = center.length();
  return center.normalize().multiplyScalar(surfaceRadius + offset);
}

function createSphereForFace(face) {
  const geometry = new THREE.SphereGeometry(sphereRadius, 16, 10);
  const targetLabel = targetLabelsByFace.get(face.id);
  if (targetLabel) baseColor.set(targetLabel.color);
  else baseColor.setHSL((face.id * 0.6180339887) % 1, 0.8, 0.62);
  const material = new THREE.MeshStandardMaterial({
    color: baseColor,
    roughness: 0.25,
    metalness: 0.18,
    emissive: '#000000',
    emissiveIntensity: 0,
  });
  const sphere = new THREE.Mesh(geometry, material);
  sphere.position.copy(surfacePosition(face, sphereSurfaceOffset));
  if (targetLabel) {
    const numberSprite = createNumberSprite(targetLabel.number, targetLabel.color);
    numberSpritesByBall.set(face.id, numberSprite);
    board.add(numberSprite);
  }
  sphereMeshesByBall.set(face.id, sphere);
  board.add(sphere);
}

function createNumberSprite(number, color) {
  const canvas = document.createElement('canvas');
  canvas.width = 128;
  canvas.height = 128;
  const context = canvas.getContext('2d');
  context.font = '700 82px system-ui, sans-serif';
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillStyle = color;
  context.beginPath();
  context.arc(64, 64, 52, 0, Math.PI * 2);
  context.fill();
  context.lineWidth = 5;
  context.strokeStyle = '#07101acc';
  context.stroke();
  context.lineWidth = 12;
  context.strokeStyle = '#07101fcc';
  context.strokeText(String(number), 64, 66);
  context.fillStyle = color === '#f1c40f' ? '#07101a' : '#ffffff';
  context.fillText(String(number), 64, 66);
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({
    map: new THREE.CanvasTexture(canvas),
    transparent: true,
    depthTest: true,
    depthWrite: false,
  }));
  sprite.scale.set(0.22, 0.22, 1);
  return sprite;
}

function updateNumberSpritePositions() {
  for (const [ballId, sprite] of numberSpritesByBall) {
    const sphere = sphereMeshesByBall.get(ballId);
    const sphereWorldPosition = sphere.getWorldPosition(new THREE.Vector3());
    const towardCamera = camera.position.clone().sub(sphereWorldPosition).normalize();
    const labelWorldPosition = sphereWorldPosition.add(towardCamera.multiplyScalar(sphereRadius + 0.035));
    sprite.position.copy(board.worldToLocal(labelWorldPosition));
  }
}

topology.faces.forEach((face) => {
  createFaceMesh(face);
  if (puzzleState.ballsByFace[face.id] !== null) createSphereForFace(face);
});

function updateSpherePositions() {
  for (const [ballId, sphere] of sphereMeshesByBall) {
    const faceId = puzzleState.ballsByFace.indexOf(ballId);
    sphere.position.copy(surfacePosition(topology.faces[faceId], sphereSurfaceOffset));
    sphere.material.emissive.set(faceId === ballId ? '#42ff8a' : '#000000');
    sphere.material.emissiveIntensity = faceId === ballId ? 0.18 : 0;
  }
  updateNumberSpritePositions();
}

function updateEmptyPosition() {
  const emptyCenter = surfacePosition(topology.faces[puzzleState.emptyFaceId], 0.14);
  emptyRing.position.copy(emptyCenter);
  emptyRing.lookAt(emptyCenter.clone().multiplyScalar(2));
}

const emptyCenter = surfacePosition(topology.faces[puzzleState.emptyFaceId], 0.14);
const emptyRing = new THREE.Mesh(
  new THREE.RingGeometry(0.12, 0.15, 3),
  new THREE.MeshBasicMaterial({ color: '#ffffff', side: THREE.DoubleSide }),
);
emptyRing.position.copy(emptyCenter);
emptyRing.lookAt(emptyCenter.clone().multiplyScalar(2));
board.add(emptyRing);

// Presenta el hueco inicial de frente para que el jugador no tenga que buscarlo.
const emptyNormal = emptyCenter.clone().normalize();
board.quaternion.setFromUnitVectors(emptyNormal, new THREE.Vector3(0, 0, 1));

moveCount.textContent = String(puzzleState.moves);
updateSpherePositions();
updateShuffleButton();
updateCameraFraming();

function startPuzzle() {
  const steps = DIFFICULTY_STEPS[difficultySelect.value];
  puzzleState = shufflePuzzle(createPuzzleState(topology, emptyFaceId), steps);
  updateSpherePositions();
  updateEmptyPosition();
  moveCount.textContent = String(puzzleState.moves);
  clearSelection();
  status.textContent = 'Puzzle desordenado · encuentra las posiciones correctas';
  updateShuffleButton();
}

function updateShuffleButton() {
  const isReady = isSolved(puzzleState);
  shuffleButton.disabled = !isReady;
  difficultySelect.disabled = !isReady;
}

const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();
let selectedMesh = null;
let selectedFaceId = null;

function clearSelection() {
  if (selectedMesh) {
    selectedMesh.material.emissive.set('#000000');
    selectedMesh.material.emissiveIntensity = 0;
  }
  selectedMesh = null;
  selectedFaceId = null;
  selection.textContent = 'ninguna';
  targetInfo.textContent = 'Selecciona una cara';
  targetSwatch.style.backgroundColor = 'transparent';
  colorMatch.textContent = 'Color: —';
  colorMatch.className = 'match pending';
  numberMatch.textContent = 'Número: —';
  numberMatch.className = 'match pending';
  moveWarning.textContent = '';
  updateFaceBorders();
}

function updateSelectionAnalysis(faceId) {
  const targetLabel = targetLabelsByFace.get(faceId);
  const ballId = puzzleState.ballsByFace[faceId];
  targetInfo.textContent = `número ${targetLabel.number} · ${targetLabel.colorName}`;
  targetSwatch.style.backgroundColor = targetLabel.color;

  if (ballId === null) {
    colorMatch.textContent = 'Color: hueco vacío';
    colorMatch.className = 'match pending';
    numberMatch.textContent = 'Número: hueco vacío';
    numberMatch.className = 'match pending';
    moveWarning.textContent = '';
    return;
  }

  const ballLabel = targetLabelsByFace.get(ballId);
  const matchesColor = ballLabel.color === targetLabel.color;
  const matchesNumber = ballLabel.number === targetLabel.number;
  colorMatch.textContent = `Color: ${matchesColor ? '✓ coincide' : '✗ no coincide'}`;
  colorMatch.className = `match ${matchesColor ? 'correct' : 'incorrect'}`;
  numberMatch.textContent = `Número: ${matchesNumber ? '✓ coincide' : '✗ no coincide'}`;
  numberMatch.className = `match ${matchesNumber ? 'correct' : 'incorrect'}`;

  if (matchesColor && matchesNumber) {
    moveWarning.textContent = '⚠ Esta esfera está completamente correcta; moverla puede hacerte perder progreso.';
  } else if (matchesColor) {
    moveWarning.textContent = '⚠ El color ya coincide; moverla puede hacerte perder progreso parcial.';
  } else if (matchesNumber) {
    moveWarning.textContent = '⚠ El número ya coincide; moverla puede hacerte perder progreso parcial.';
  } else {
    moveWarning.textContent = '';
  }
}

function setSelection(mesh) {
  if (selectedMesh) {
    selectedMesh.material.emissive.set('#000000');
    selectedMesh.material.emissiveIntensity = 0;
  }
  selectedMesh = mesh;
  selectedFaceId = mesh.userData.faceId;
  selectedMesh.material.emissive.set('#ffffff');
  selectedMesh.material.emissiveIntensity = 0.45;
  selection.textContent = `cara ${selectedFaceId}`;
  updateSelectionAnalysis(selectedFaceId);
  updateFaceBorders();
}

function faceMatchColor(faceId) {
  const ballId = puzzleState.ballsByFace[faceId];
  if (ballId === null) return '#ffffff';
  const targetLabel = targetLabelsByFace.get(faceId);
  const ballLabel = targetLabelsByFace.get(ballId);
  const matchesColor = ballLabel.color === targetLabel.color;
  const matchesNumber = ballLabel.number === targetLabel.number;
  if (matchesColor && matchesNumber) return '#35ff7a';
  if (matchesColor || matchesNumber) return '#ffe14a';
  return '#ff355d';
}

function updateFaceBorders() {
  for (const border of faceBordersById.values()) border.visible = false;
  if (selectedFaceId === null) return;
  const visibleFaceIds = [selectedFaceId, ...topology.faces[selectedFaceId].neighbors];
  for (const faceId of visibleFaceIds) {
    const border = faceBordersById.get(faceId);
    border.material.color.set(faceMatchColor(faceId));
    border.visible = true;
  }
}

function selectFace(event) {
  pointer.x = (event.clientX / innerWidth) * 2 - 1;
  pointer.y = -(event.clientY / innerHeight) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);
  const [hit] = raycaster.intersectObjects(faceMeshes);
  if (!hit) {
    clearSelection();
    status.textContent = 'Selecciona una esfera para moverla';
    return;
  }

  const faceId = hit.object.userData.faceId;
  if (selectedFaceId === null) {
    setSelection(hit.object);
    status.textContent = 'Cara seleccionada · elige otra cara';
    return;
  }

  if (selectedFaceId === faceId) {
    clearSelection();
    status.textContent = 'Selección cancelada';
    return;
  }

  const facesAreNeighbors = topology.faces[selectedFaceId].neighbors.includes(faceId);
  const firstIsEmpty = selectedFaceId === puzzleState.emptyFaceId;
  const secondIsEmpty = faceId === puzzleState.emptyFaceId;
  if (facesAreNeighbors && firstIsEmpty !== secondIsEmpty) {
    const fromFaceId = firstIsEmpty ? faceId : selectedFaceId;
    const nextState = applyMove(puzzleState, fromFaceId);
    puzzleState = nextState;
    clearSelection();
    updateSpherePositions();
    updateEmptyPosition();
    moveCount.textContent = String(puzzleState.moves);
    status.textContent = isSolved(puzzleState) ? 'Tablero resuelto' : 'Movimiento realizado';
    updateShuffleButton();
    return;
  }

  setSelection(hit.object);
  status.textContent = 'Selección cambiada · elige una cara vecina al hueco';
}

renderer.domElement.addEventListener('click', selectFace);
shuffleButton.addEventListener('click', startPuzzle);
panelToggle.addEventListener('click', () => {
  const collapsed = hud.classList.toggle('collapsed');
  panelToggle.textContent = collapsed ? '+' : '−';
  panelToggle.setAttribute('aria-expanded', String(!collapsed));
});
addEventListener('resize', () => {
  updateCameraFraming();
  renderer.setSize(innerWidth, innerHeight);
  for (const border of faceBordersById.values()) {
    border.material.resolution.set(innerWidth, innerHeight);
  }
});

function animate() {
  controls.update();
  updateNumberSpritePositions();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}

animate();
