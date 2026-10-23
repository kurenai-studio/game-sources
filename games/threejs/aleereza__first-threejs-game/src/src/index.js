import * as THREE from "three";
import * as CANNON from "cannon-es";

// This code sets up a basic scene with a red sphere and a green ground plane.
// The sphere will fall under gravity and collide with the ground.
// This example demonstrates how to sync a Three.js mesh with a Cannon.js physics body, allowing you to visualize physics simulations.

let scene, camera, renderer, world;
let sphereMesh, sphereBody, groundMesh, groundBody;

function init() {
  // Scene setup
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 5, 10);

  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);

  // Lighting
  const ambientLight = new THREE.AmbientLight(0x404040); // Soft white light
  scene.add(ambientLight);
  const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
  directionalLight.position.set(5, 10, 7.5);
  scene.add(directionalLight);

  // Physics setup
  setupPhysics();

  // Render loop
  animate();
}

function setupPhysics() {
  // World setup
  world = new CANNON.World();
  world.gravity.set(0, -9.82, 0); // Set gravity

  // Sphere (creature)
  const sphereGeometry = new THREE.SphereGeometry(1, 32, 32);
  const sphereMaterial = new THREE.MeshStandardMaterial({ color: 0xff0000 });
  sphereMesh = new THREE.Mesh(sphereGeometry, sphereMaterial);
  scene.add(sphereMesh);
  sphereBody = new CANNON.Body({
    mass: 1,
    shape: new CANNON.Sphere(1),
    position: new CANNON.Vec3(0, 5, 0),
  });
  world.addBody(sphereBody);

  // Ground
  const groundGeometry = new THREE.PlaneGeometry(10, 10);
  const groundMaterial = new THREE.MeshStandardMaterial({
    color: 0x00ff00,
    side: THREE.DoubleSide,
  });
  groundMesh = new THREE.Mesh(groundGeometry, groundMaterial);
  groundMesh.rotation.x = -Math.PI / 2;
  scene.add(groundMesh);
  groundBody = new CANNON.Body({
    mass: 0, // mass = 0 makes the body static
    shape: new CANNON.Plane(),
    material: new CANNON.Material({ friction: 0.5, restitution: 0.7 }),
  });
  groundBody.quaternion.setFromEuler(-Math.PI / 2, 0, 0);
  world.addBody(groundBody);
}

function animate() {
  requestAnimationFrame(animate);

  // Update physics
  let deltaTime = 1 / 60; // Assuming 60 FPS
  world.step(deltaTime);

  // Sync Three.js meshes with Cannon.js bodies
  sphereMesh.position.copy(sphereBody.position);
  sphereMesh.quaternion.copy(sphereBody.quaternion);

  renderer.render(scene, camera);
}

init();
