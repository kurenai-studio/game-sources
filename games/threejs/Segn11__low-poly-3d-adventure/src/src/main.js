import * as THREE from 'three';
import './style.css';
import { Player } from './player.js';
import { World } from './world.js';
import { EnemyManager } from './enemies.js';
import { CollectiblesManager } from './collectibles.js';
import { ThirdPersonCamera } from './camera.js';
import { UIManager } from './ui.js';

class Game {
  constructor() {
    // Initialize UI and DOM (creates canvas element)
    this.ui = new UIManager(this);

    this.initThree();

    // Instantiate game systems
    this.world = new World(this.scene);
    this.player = new Player(this.scene);
    this.enemies = new EnemyManager(this.scene);
    this.collectibles = new CollectiblesManager(this.scene);
    this.cameraController = new ThirdPersonCamera(this.camera, this.renderer.domElement);

    this.clock = new THREE.Clock();
    this.lastHealth = this.player.health;
    window.game = this;

    // Window resize handler
    window.addEventListener('resize', () => this.onWindowResize());

    // Game loop
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  initThree() {
    this.scene = new THREE.Scene();

    // Camera setup
    this.camera = new THREE.PerspectiveCamera(
      60,
      window.innerWidth / window.innerHeight,
      0.1,
      500
    );

    // High performance antialiased WebGL renderer
    const canvas = document.getElementById('game-canvas');
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      powerPreference: 'high-performance'
    });

    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.15;
  }

  onWindowResize() {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  }

  restart() {
    this.player.health = this.player.maxHealth;
    this.player.checkpoint.set(0, 0.75, 0);
    this.player.resetPosition();
    this.enemies.resetAll();
    this.collectibles.resetAll();
    this.ui.updateHealth(this.player.health);
    this.ui.coinsCount.textContent = '0';
    this.ui.redCoinsCount.textContent = '0 / 8';
    this.ui.starsCount.textContent = '0 / 5';
    this.ui.starsCollectedState = [false, false, false, false, false];
    this.ui.renderMissionsList();
    this.ui.startTimer();
  }

  animate() {
    requestAnimationFrame(this.animate);

    const now = performance.now();
    const delta = Math.min((now - (this.lastTime || now)) / 1000, 0.05);
    this.lastTime = now;

    if (!this.ui.isPaused) {
      // 1. Poll Gamepad Controller input
      this.ui.pollGamepad(delta);

      const input = this.ui.consumeInput();

      // 2. Update Player (physics, wall jumps, belly dive, shockwave, crates)
      this.player.update(
        delta,
        input,
        this.cameraController.yaw,
        this.world.colliders,
        this.world.bouncePads,
        this.enemies.enemies,
        this.world.crates
      );

      // 3. Health HUD Sync
      if (this.player.health !== this.lastHealth) {
        this.ui.updateHealth(this.player.health);
        this.lastHealth = this.player.health;
      }

      // 4. Update Third Person Camera (FOV expansion, trauma shake, orbit)
      this.cameraController.update(delta, this.player, this.world.colliders);

      // 5. Update World (moving platforms, water ripples, rotating cogs, updrafts, crates)
      this.world.update(delta, this.player, this.collectibles);

      // 6. Update Enemies (standard slimes, winged slimes, spiky iron slimes)
      this.enemies.update(delta, this.player, this.collectibles);

      // 7. Update Collectibles (coins, red coins quest, 5 power stars, hearts)
      this.collectibles.update(delta, this.player);
    }

    // Render Scene
    this.renderer.render(this.scene, this.camera);
  }
}

// Start Game on Page Load
window.addEventListener('DOMContentLoaded', () => {
  new Game();
});
