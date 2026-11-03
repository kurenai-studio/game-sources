import * as THREE from 'three';
import { sounds } from './audio.js';

export class Crate {
  constructor(scene, x, y, z, lootType = 'coin') {
    this.scene = scene;
    this.position = new THREE.Vector3(x, y, z);
    this.lootType = lootType; // 'coin', 'heart', or 'redCoin'
    this.broken = false;
    this.fragments = [];

    this.group = new THREE.Group();
    this.group.position.set(x, y, z);

    // Low-poly wooden crate
    const woodMat = new THREE.MeshStandardMaterial({
      color: 0x965d38,
      roughness: 0.85,
      flatShading: true
    });

    const ironTrimMat = new THREE.MeshStandardMaterial({
      color: 0x4a4a4a,
      metalness: 0.7,
      roughness: 0.4
    });

    // Main box
    const boxGeo = new THREE.BoxGeometry(1.3, 1.3, 1.3);
    const boxMesh = new THREE.Mesh(boxGeo, woodMat);
    boxMesh.castShadow = true;
    boxMesh.receiveShadow = true;
    this.group.add(boxMesh);

    // Cross braces / corners
    const braceGeo = new THREE.BoxGeometry(1.34, 0.16, 1.34);
    const topBrace = new THREE.Mesh(braceGeo, ironTrimMat);
    topBrace.position.y = 0.6;
    this.group.add(topBrace);

    const botBrace = new THREE.Mesh(braceGeo, ironTrimMat);
    botBrace.position.y = -0.6;
    this.group.add(botBrace);

    this.scene.add(this.group);

    // Collider object
    this.colliderObj = {
      box: new THREE.Box3(),
      mesh: boxMesh,
      isCrate: true,
      crateRef: this
    };
    this.colliderObj.box.setFromCenterAndSize(this.position, new THREE.Vector3(1.3, 1.3, 1.3));
  }

  breakCrate(collectibles = null) {
    if (this.broken) return;
    this.broken = true;
    this.group.visible = false;

    // Invalidate collider box so player can pass through
    this.colliderObj.box.makeEmpty();

    sounds.playCrateSmash();
    window.dispatchEvent(new CustomEvent('screenShake', { detail: { intensity: 9 } }));

    // Spawn 8 tumbling wooden splinter shards
    const fragMat = new THREE.MeshStandardMaterial({
      color: 0x8b5a2b,
      roughness: 0.9,
      flatShading: true
    });

    for (let i = 0; i < 8; i++) {
      const sx = 0.3 + Math.random() * 0.3;
      const sy = 0.15 + Math.random() * 0.25;
      const sz = 0.3 + Math.random() * 0.3;
      const fragGeo = new THREE.BoxGeometry(sx, sy, sz);
      const mesh = new THREE.Mesh(fragGeo, fragMat);
      mesh.position.copy(this.position);
      mesh.castShadow = true;
      this.scene.add(mesh);

      const angle = (i / 8) * Math.PI * 2 + Math.random() * 0.5;
      const hSpeed = 3.5 + Math.random() * 4.5;
      const vel = new THREE.Vector3(
        Math.cos(angle) * hSpeed,
        4.0 + Math.random() * 5.0,
        Math.sin(angle) * hSpeed
      );

      const rotSpeed = new THREE.Vector3(
        (Math.random() - 0.5) * 12,
        (Math.random() - 0.5) * 12,
        (Math.random() - 0.5) * 12
      );

      this.fragments.push({ mesh, vel, rotSpeed, life: 1.2 });
    }

    // Spawn loot!
    if (collectibles) {
      if (this.lootType === 'heart') {
        collectibles.spawnHeart(this.position.x, this.position.y + 0.6, this.position.z);
      } else if (this.lootType === 'redCoin') {
        collectibles.spawnRedCoin(this.position.x, this.position.y + 0.6, this.position.z);
      } else {
        collectibles.spawnCoin(this.position.x, this.position.y + 0.6, this.position.z);
      }
    }
  }

  update(delta) {
    if (!this.broken) return;

    for (let i = this.fragments.length - 1; i >= 0; i--) {
      const f = this.fragments[i];
      f.life -= delta;
      f.vel.y -= 24 * delta; // Gravity
      f.mesh.position.addScaledVector(f.vel, delta);
      f.mesh.rotation.x += f.rotSpeed.x * delta;
      f.mesh.rotation.y += f.rotSpeed.y * delta;
      f.mesh.rotation.z += f.rotSpeed.z * delta;

      if (f.life <= 0.4) {
        f.mesh.scale.setScalar(Math.max(0.01, f.life / 0.4));
      }

      if (f.life <= 0) {
        this.scene.remove(f.mesh);
        f.mesh.geometry.dispose();
        this.fragments.splice(i, 1);
      }
    }
  }
}

export class World {
  constructor(scene) {
    this.scene = scene;
    this.colliders = []; // objects with .box: THREE.Box3, and optional .platformVelocity
    this.movingPlatforms = [];
    this.rotatingPlatforms = [];
    this.bouncePads = [];
    this.checkpoints = [];
    this.clouds = [];
    this.sparkles = [];
    this.hazardObstacles = [];
    this.crates = [];
    this.updrafts = [];

    this.initLighting();
    this.initSky();
    this.buildLevel();
    this.initWater();
    this.initDriftingClouds();
    this.initAmbientSparkles();
  }

  initLighting() {
    // Hemisphere light for vibrant, natural outdoor sky & ground bounce
    const hemiLight = new THREE.HemisphereLight(0xb1e1ff, 0x3b5828, 0.85);
    this.scene.add(hemiLight);

    // Main Sun light
    this.sunLight = new THREE.DirectionalLight(0xfffaed, 1.5);
    this.sunLight.position.set(45, 75, 40);
    this.sunLight.castShadow = true;
    this.sunLight.shadow.mapSize.width = 2048;
    this.sunLight.shadow.mapSize.height = 2048;
    this.sunLight.shadow.camera.near = 5;
    this.sunLight.shadow.camera.far = 200;

    const d = 65;
    this.sunLight.shadow.camera.left = -d;
    this.sunLight.shadow.camera.right = d;
    this.sunLight.shadow.camera.top = d;
    this.sunLight.shadow.camera.bottom = -d;
    this.sunLight.shadow.bias = -0.0004;
    this.scene.add(this.sunLight);

    // Warm rim light
    const rimLight = new THREE.DirectionalLight(0xffc078, 0.45);
    rimLight.position.set(-45, 25, -40);
    this.scene.add(rimLight);
  }

  initSky() {
    this.scene.background = new THREE.Color(0x70c5ff);
    this.scene.fog = new THREE.Fog(0x70c5ff, 100, 300);
  }

  initWater() {
    // Translucent low-poly animated lagoon water plane under Island 1 & 2
    const waterGeo = new THREE.PlaneGeometry(120, 120, 32, 32);
    waterGeo.rotateX(-Math.PI / 2);

    const waterMat = new THREE.MeshStandardMaterial({
      color: 0x1dd1a1,
      roughness: 0.15,
      metalness: 0.25,
      transparent: true,
      opacity: 0.72,
      flatShading: true
    });

    this.waterMesh = new THREE.Mesh(waterGeo, waterMat);
    this.waterMesh.position.set(0, -6.5, 30);
    this.scene.add(this.waterMesh);

    // Cache initial vertices for wave displacement
    this.waterInitialPositions = waterGeo.attributes.position.array.slice();
  }

  buildLevel() {
    // Materials
    const grassMat = new THREE.MeshStandardMaterial({
      color: 0x48bb78, // Vibrant emerald meadow
      roughness: 0.6,
      flatShading: true
    });

    const dirtMat = new THREE.MeshStandardMaterial({
      color: 0x795548, // Earthy brown rock underbelly
      roughness: 0.8,
      flatShading: true
    });

    const stoneMat = new THREE.MeshStandardMaterial({
      color: 0x94a3b8, // Slate stone
      roughness: 0.7,
      flatShading: true
    });

    const darkStoneMat = new THREE.MeshStandardMaterial({
      color: 0x475569,
      roughness: 0.6,
      flatShading: true
    });

    const goldTrimMat = new THREE.MeshStandardMaterial({
      color: 0xf1c40f,
      metalness: 0.85,
      roughness: 0.2
    });

    const crystalMat = new THREE.MeshStandardMaterial({
      color: 0x9b59b6,
      emissive: 0x8e44ad,
      emissiveIntensity: 0.7,
      roughness: 0.1,
      flatShading: true
    });

    // ----------------------------------------------------
    // ISLAND 1: Emerald Meadow (Spawn Island)
    // ----------------------------------------------------
    this.createFloatingIsland({
      x: 0, y: 0, z: 0,
      width: 28, depth: 28, height: 7,
      topMat: grassMat, bottomMat: dirtMat
    });

    // Trees on Island 1
    this.createLowPolyTree(7, 0.5, 7, 1.2);
    this.createLowPolyTree(-8, 0.5, 6, 1.0);
    this.createLowPolyTree(-7, 0.5, -7, 1.3);
    this.createLowPolyTree(8, 0.5, -6, 0.9);

    // Flowers & Mushrooms
    this.createMushroom(4, 0.5, 5, 0xff4757, 0.8);
    this.createMushroom(-5, 0.5, 4, 0x3742fa, 0.6);
    this.createMushroom(5, 0.5, -4, 0xffa502, 0.7);

    // Welcome Signpost
    this.createSignpost(0, 0.5, 4.5, "Welcome to Starfall Isle!\nWASD Move, SPACE Jump, C Pound, SHIFT+SPACE Dive!");

    // Checkpoint 1 (Spawn)
    this.createCheckpointTotem(0, 0.5, 0, "Meadow Camp");

    // Wooden Crates on Island 1 (Breakable!)
    this.createCrate(6, 1.15, 2, 'coin');
    this.createCrate(7.5, 1.15, 2, 'coin');
    this.createCrate(6.75, 2.45, 2, 'heart'); // stacked!
    this.createCrate(-9, 1.15, -2, 'redCoin'); // Secret Red Coin in crate!

    // Stepping stones towards Island 2
    this.createStaticBlock(0, 1.5, 17, 4.0, 1.5, 4.0, stoneMat);
    this.createStaticBlock(0, 3.5, 23, 3.8, 1.5, 3.8, stoneMat);

    // ----------------------------------------------------
    // ISLAND 2: Bouncing Canopy & Azure Rapids
    // ----------------------------------------------------
    this.createFloatingIsland({
      x: 0, y: 5, z: 35,
      width: 18, depth: 18, height: 6,
      topMat: grassMat, bottomMat: dirtMat
    });

    this.createLowPolyTree(5, 5.5, 36, 1.2);
    this.createLowPolyTree(-5, 5.5, 33, 1.0);

    // Super Bounce Mushroom
    this.createBouncePad(0, 5.5, 39, 29, 0xff3838);

    // Crates on Island 2
    this.createCrate(-5, 6.15, 38, 'coin');
    this.createCrate(5, 6.15, 32, 'coin');

    // Horizontal Moving Platform towards Island 3
    this.createMovingPlatform({
      start: new THREE.Vector3(0, 7.5, 48),
      end: new THREE.Vector3(0, 7.5, 62),
      size: new THREE.Vector3(5.5, 1.2, 5.5),
      speed: 0.65,
      mat: stoneMat
    });

    // ----------------------------------------------------
    // ISLAND 3: The Ancient Clockwork Wind Ruins
    // ----------------------------------------------------
    this.createFloatingIsland({
      x: 0, y: 10, z: 76,
      width: 24, depth: 24, height: 8,
      topMat: darkStoneMat, bottomMat: dirtMat
    });

    // Stone Pillars & Arch
    this.createStonePillar(-7, 10.5, 76, 5.5, stoneMat);
    this.createStonePillar(7, 10.5, 76, 5.5, stoneMat);
    this.createStaticBlock(0, 16.0, 76, 16, 1.2, 2.8, stoneMat);

    // Checkpoint 2
    this.createCheckpointTotem(0, 10.5, 76, "Clockwork Ruins");

    // Rotating Mechanical Stone Cog Platform
    this.createRotatingCogPlatform(16, 12.0, 76, 6.5, 1.2, 0.5, darkStoneMat);

    // Updraft Wind Geyser / Air Column
    this.createUpdraftVent(-12, 10.5, 76, 18.0);

    // Rotating Hazard Beams on Island 3
    this.createRotatingHazardBeam(0, 11.2, 69, 7.5, 1.3);

    // Crates on Island 3
    this.createCrate(-7, 11.15, 82, 'redCoin'); // Red coin inside crate!
    this.createCrate(-7, 12.45, 82, 'coin');
    this.createCrate(7, 11.15, 82, 'heart');

    // ----------------------------------------------------
    // ISLAND 4: Neon Crystal Chasm
    // ----------------------------------------------------
    // Elevator Platform
    this.createMovingPlatform({
      start: new THREE.Vector3(16, 13, 76),
      end: new THREE.Vector3(16, 23, 76),
      size: new THREE.Vector3(5.0, 1.2, 5.0),
      speed: 0.55,
      mat: stoneMat
    });

    // Crystal Peak Stepping Stone
    this.createStaticBlock(16, 24.5, 62, 5, 1.6, 5, darkStoneMat);

    // Glowing Crystals
    this.createCrystalCluster(16, 25.3, 60, crystalMat);
    this.createCrystalCluster(-12, 10.8, 80, crystalMat);

    // High Bounce Pad
    this.createBouncePad(16, 25.5, 62, 33, 0x00d2d3);

    // Floating Cloud Archipelago leading to Summit
    this.createCloudIsland(16, 27.5, 88, 5.5, 2.2, 5.5);
    this.createCloudIsland(9, 30.5, 99, 5.5, 2.2, 5.5);
    this.createCloudIsland(0, 33.5, 110, 5.5, 2.2, 5.5);

    // ----------------------------------------------------
    // ISLAND 5: Celestial Summit ("Temple of the Stars")
    // ----------------------------------------------------
    this.createFloatingIsland({
      x: 0, y: 37, z: 130,
      width: 26, depth: 26, height: 9,
      topMat: darkStoneMat, bottomMat: dirtMat
    });

    // Golden Temple Pillars
    const shrinePillars = [
      [-8, -8], [8, -8], [-8, 8], [8, 8],
      [-8, 0], [8, 0]
    ];
    shrinePillars.forEach(([px, pz]) => {
      this.createStonePillar(px, 37.5, 130 + pz, 7, stoneMat, goldTrimMat);
    });

    // Star Altar in center of Summit
    this.createStaticBlock(0, 38.5, 130, 8, 2.0, 8, goldTrimMat);
    this.createStaticBlock(0, 40.0, 130, 5.0, 1.2, 5.0, stoneMat);

    // Checkpoint 3
    this.createCheckpointTotem(0, 37.5, 122, "Star Summit");

    // Celestial Orbital Ring around the Summit Shrine
    this.createOrbitingCelestialRing(0, 43, 130, 12, 0.4);
  }

  createCrate(x, y, z, lootType = 'coin') {
    const crate = new Crate(this.scene, x, y, z, lootType);
    this.crates.push(crate);
    this.colliders.push(crate.colliderObj);
    return crate;
  }

  createFloatingIsland({ x, y, z, width, depth, height, topMat, bottomMat }) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    // Top lush layer
    const topGeo = new THREE.BoxGeometry(width, 1.6, depth);
    const topMesh = new THREE.Mesh(topGeo, topMat);
    topMesh.position.y = 0;
    topMesh.castShadow = true;
    topMesh.receiveShadow = true;
    group.add(topMesh);

    // Low-poly tapered rock underbelly
    const coneGeo = new THREE.ConeGeometry(Math.max(width, depth) * 0.65, height, 8);
    coneGeo.rotateX(Math.PI);
    const underMesh = new THREE.Mesh(coneGeo, bottomMat);
    underMesh.position.y = -height / 2;
    underMesh.castShadow = true;
    underMesh.receiveShadow = true;
    group.add(underMesh);

    this.scene.add(group);

    // Register primary walkable collider
    const box = new THREE.Box3();
    box.setFromCenterAndSize(
      new THREE.Vector3(x, y, z),
      new THREE.Vector3(width, 1.6, depth)
    );
    this.colliders.push({ box, mesh: topMesh });
  }

  createCloudIsland(x, y, z, w, h, d) {
    const cloudMat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      roughness: 0.35,
      flatShading: true
    });

    const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), cloudMat);
    mesh.position.set(x, y, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    this.scene.add(mesh);

    // Bubbly cloud puffs
    const puffGeo = new THREE.DodecahedronGeometry(h * 0.9, 1);
    const offsets = [
      [w / 2, 0, 0], [-w / 2, 0, 0], [0, 0, d / 2], [0, 0, -d / 2]
    ];
    offsets.forEach(([ox, oy, oz]) => {
      const puff = new THREE.Mesh(puffGeo, cloudMat);
      puff.position.set(x + ox, y + oy, z + oz);
      this.scene.add(puff);
    });

    const box = new THREE.Box3();
    box.setFromCenterAndSize(new THREE.Vector3(x, y, z), new THREE.Vector3(w + 1, h, d + 1));
    this.colliders.push({ box, mesh });
  }

  createStaticBlock(x, y, z, w, h, d, mat) {
    const geo = new THREE.BoxGeometry(w, h, d);
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(x, y, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    this.scene.add(mesh);

    const box = new THREE.Box3();
    box.setFromCenterAndSize(new THREE.Vector3(x, y, z), new THREE.Vector3(w, h, d));
    this.colliders.push({ box, mesh });
  }

  createStonePillar(x, y, z, height, mat, trimMat = null) {
    const geo = new THREE.CylinderGeometry(1.0, 1.2, height, 8);
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(x, y + height / 2, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    this.scene.add(mesh);

    if (trimMat) {
      const capGeo = new THREE.BoxGeometry(2.4, 0.65, 2.4);
      const capMesh = new THREE.Mesh(capGeo, trimMat);
      capMesh.position.set(x, y + height + 0.32, z);
      this.scene.add(capMesh);
    }

    const box = new THREE.Box3();
    box.setFromCenterAndSize(new THREE.Vector3(x, y + height / 2, z), new THREE.Vector3(2.2, height, 2.2));
    this.colliders.push({ box, mesh });
  }

  createLowPolyTree(x, y, z, scale = 1.0) {
    const group = new THREE.Group();
    group.position.set(x, y, z);
    group.scale.setScalar(scale);

    const trunkMat = new THREE.MeshStandardMaterial({ color: 0x5d4037, roughness: 0.9 });
    const foliageMat = new THREE.MeshStandardMaterial({
      color: 0x2ed573,
      roughness: 0.5,
      flatShading: true
    });

    const trunkGeo = new THREE.CylinderGeometry(0.32, 0.48, 2.4, 6);
    const trunk = new THREE.Mesh(trunkGeo, trunkMat);
    trunk.position.y = 1.2;
    trunk.castShadow = true;
    group.add(trunk);

    const f1 = new THREE.Mesh(new THREE.ConeGeometry(1.9, 2.3, 7), foliageMat);
    f1.position.y = 2.5;
    f1.castShadow = true;
    group.add(f1);

    const f2 = new THREE.Mesh(new THREE.ConeGeometry(1.5, 2.0, 7), foliageMat);
    f2.position.y = 3.8;
    f2.castShadow = true;
    group.add(f2);

    const f3 = new THREE.Mesh(new THREE.ConeGeometry(1.0, 1.6, 7), foliageMat);
    f3.position.y = 5.0;
    f3.castShadow = true;
    group.add(f3);

    this.scene.add(group);
  }

  createMushroom(x, y, z, capColor, scale = 1.0) {
    const group = new THREE.Group();
    group.position.set(x, y, z);
    group.scale.setScalar(scale);

    const stemMat = new THREE.MeshStandardMaterial({ color: 0xf5f6fa, roughness: 0.5 });
    const capMat = new THREE.MeshStandardMaterial({ color: capColor, roughness: 0.3, metalness: 0.1 });
    const spotMat = new THREE.MeshStandardMaterial({ color: 0xffffff });

    const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.3, 1.0, 8), stemMat);
    stem.position.y = 0.5;
    group.add(stem);

    const cap = new THREE.Mesh(new THREE.SphereGeometry(0.75, 8, 8, 0, Math.PI * 2, 0, Math.PI * 0.5), capMat);
    cap.position.y = 0.95;
    group.add(cap);

    for (let i = 0; i < 4; i++) {
      const spot = new THREE.Mesh(new THREE.CircleGeometry(0.13, 6), spotMat);
      const angle = (i / 4) * Math.PI * 2;
      spot.position.set(Math.cos(angle) * 0.5, 1.2, Math.sin(angle) * 0.5);
      spot.rotation.x = -0.4;
      group.add(spot);
    }

    this.scene.add(group);
  }

  createCrystalCluster(x, y, z, mat) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    for (let i = 0; i < 5; i++) {
      const h = 1.2 + Math.random() * 1.5;
      const crystal = new THREE.Mesh(new THREE.ConeGeometry(0.3, h, 5), mat);
      crystal.position.set((Math.random() - 0.5) * 1.2, h / 2, (Math.random() - 0.5) * 1.2);
      crystal.rotation.x = (Math.random() - 0.5) * 0.4;
      crystal.rotation.z = (Math.random() - 0.5) * 0.4;
      crystal.castShadow = true;
      group.add(crystal);
    }

    // Point light to illuminate nearby cavern area
    const light = new THREE.PointLight(0xa55eea, 1.2, 8);
    light.position.set(0, 1.5, 0);
    group.add(light);

    this.scene.add(group);
  }

  createRotatingCogPlatform(x, y, z, radius, thickness, speed, mat) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    // Main wheel cylinder
    const cylGeo = new THREE.CylinderGeometry(radius, radius, thickness, 16);
    const cylMesh = new THREE.Mesh(cylGeo, mat);
    cylMesh.castShadow = true;
    cylMesh.receiveShadow = true;
    group.add(cylMesh);

    // Cog teeth along rim
    const toothGeo = new THREE.BoxGeometry(0.8, thickness * 0.9, 1.2);
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2;
      const tooth = new THREE.Mesh(toothGeo, mat);
      tooth.position.set(Math.cos(angle) * (radius + 0.3), 0, Math.sin(angle) * (radius + 0.3));
      tooth.rotation.y = -angle;
      tooth.castShadow = true;
      group.add(tooth);
    }

    this.scene.add(group);

    const colliderObj = {
      box: new THREE.Box3(),
      mesh: group,
      platformVelocity: new THREE.Vector3()
    };
    colliderObj.box.setFromCenterAndSize(group.position, new THREE.Vector3(radius * 2, thickness, radius * 2));
    this.colliders.push(colliderObj);

    this.rotatingPlatforms.push({
      group,
      colliderObj,
      radius,
      speed,
      rotation: 0
    });
  }

  createUpdraftVent(x, y, z, height = 18.0) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    // Base grate
    const grateMat = new THREE.MeshStandardMaterial({ color: 0x2f3542, metalness: 0.8 });
    const grate = new THREE.Mesh(new THREE.CylinderGeometry(2.0, 2.2, 0.4, 8), grateMat);
    grate.position.y = 0.2;
    group.add(grate);

    // Updraft swirl particles
    const particleCount = 20;
    const pGeo = new THREE.DodecahedronGeometry(0.15, 0);
    const pMat = new THREE.MeshBasicMaterial({ color: 0x70a1ff, transparent: true, opacity: 0.65 });
    const particles = [];

    for (let i = 0; i < particleCount; i++) {
      const p = new THREE.Mesh(pGeo, pMat);
      p.position.set((Math.random() - 0.5) * 2.5, Math.random() * height, (Math.random() - 0.5) * 2.5);
      group.add(p);
      particles.push({ mesh: p, speed: 6 + Math.random() * 6 });
    }

    this.scene.add(group);

    this.updrafts.push({
      position: new THREE.Vector3(x, y, z),
      radius: 2.2,
      height,
      particles
    });
  }

  createOrbitingCelestialRing(x, y, z, radius, tubeRadius) {
    const ringGeo = new THREE.TorusGeometry(radius, tubeRadius, 8, 36);
    const ringMat = new THREE.MeshStandardMaterial({
      color: 0x00d2d3,
      emissive: 0x00cec9,
      emissiveIntensity: 0.6,
      metalness: 0.8,
      roughness: 0.2
    });

    this.celestialRing = new THREE.Mesh(ringGeo, ringMat);
    this.celestialRing.position.set(x, y, z);
    this.celestialRing.rotation.x = Math.PI / 4;
    this.scene.add(this.celestialRing);
  }

  createSignpost(x, y, z, text) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    const woodMat = new THREE.MeshStandardMaterial({ color: 0x8b5a2b });
    const post = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 1.5, 6), woodMat);
    post.position.y = 0.75;
    group.add(post);

    const board = new THREE.Mesh(new THREE.BoxGeometry(1.8, 0.9, 0.18), woodMat);
    board.position.y = 1.3;
    group.add(board);

    this.scene.add(group);
  }

  createBouncePad(x, y, z, bounceForce = 29, color = 0xff3838) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    // Pad rim
    const rimMat = new THREE.MeshStandardMaterial({ color: 0x2f3542, roughness: 0.4 });
    const rim = new THREE.Mesh(new THREE.CylinderGeometry(1.6, 1.8, 0.45, 12), rimMat);
    rim.position.y = 0.22;
    group.add(rim);

    // Spring center surface
    const springMat = new THREE.MeshStandardMaterial({
      color: color,
      roughness: 0.2,
      emissive: color,
      emissiveIntensity: 0.4
    });
    const cap = new THREE.Mesh(new THREE.CylinderGeometry(1.3, 1.3, 0.5, 12), springMat);
    cap.position.y = 0.28;
    group.add(cap);

    this.scene.add(group);

    this.bouncePads.push({
      position: new THREE.Vector3(x, y + 0.35, z),
      radius: 1.5,
      bounceForce,
      mesh: group
    });
  }

  createCheckpointTotem(x, y, z, name) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    const stoneMat = new THREE.MeshStandardMaterial({ color: 0x57606f });
    const base = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 1.0, 0.65, 8), stoneMat);
    base.position.y = 0.32;
    group.add(base);

    const pillar = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.48, 2.2, 8), stoneMat);
    pillar.position.y = 1.4;
    group.add(pillar);

    // Glowing Crystal
    const crystalGeo = new THREE.OctahedronGeometry(0.5, 0);
    const crystalMat = new THREE.MeshStandardMaterial({
      color: 0x00d2d3,
      emissive: 0x00d2d3,
      emissiveIntensity: 0.85,
      roughness: 0.1
    });
    const crystal = new THREE.Mesh(crystalGeo, crystalMat);
    crystal.position.y = 3.0;
    group.add(crystal);

    this.scene.add(group);

    this.checkpoints.push({
      position: new THREE.Vector3(x, y, z),
      name,
      crystal,
      crystalMat,
      activated: false
    });
  }

  createMovingPlatform({ start, end, size, speed, mat }) {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(size.x, size.y, size.z), mat);
    mesh.position.copy(start);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    this.scene.add(mesh);

    const colliderObj = {
      box: new THREE.Box3(),
      mesh,
      platformVelocity: new THREE.Vector3()
    };
    colliderObj.box.setFromCenterAndSize(mesh.position, size);
    this.colliders.push(colliderObj);

    this.movingPlatforms.push({
      start,
      end,
      size,
      speed,
      colliderObj,
      progress: 0,
      direction: 1
    });
  }

  createRotatingHazardBeam(x, y, z, length = 7.5, speed = 1.3) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    const centerPillar = new THREE.Mesh(
      new THREE.CylinderGeometry(0.55, 0.55, 1.3, 8),
      new THREE.MeshStandardMaterial({ color: 0x2d3436 })
    );
    group.add(centerPillar);

    const hazardMat = new THREE.MeshStandardMaterial({
      color: 0xff3838,
      emissive: 0xff4757,
      emissiveIntensity: 0.55
    });

    const beamMesh = new THREE.Mesh(new THREE.BoxGeometry(length, 0.65, 0.65), hazardMat);
    beamMesh.position.y = 0.35;
    group.add(beamMesh);

    this.scene.add(group);

    this.hazardObstacles.push({
      group,
      beamMesh,
      length,
      speed,
      rotation: 0
    });
  }

  initDriftingClouds() {
    const cloudMat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      roughness: 0.4,
      flatShading: true
    });

    for (let i = 0; i < 24; i++) {
      const cloudGroup = new THREE.Group();
      const puffCount = 3 + Math.floor(Math.random() * 4);

      for (let j = 0; j < puffCount; j++) {
        const r = 2.5 + Math.random() * 2.8;
        const puff = new THREE.Mesh(new THREE.DodecahedronGeometry(r, 1), cloudMat);
        puff.position.set(
          (j - puffCount / 2) * 2.4,
          (Math.random() - 0.5) * 1.5,
          (Math.random() - 0.5) * 1.5
        );
        cloudGroup.add(puff);
      }

      cloudGroup.position.set(
        (Math.random() - 0.5) * 220,
        15 + Math.random() * 45,
        (Math.random() - 0.5) * 220
      );

      this.scene.add(cloudGroup);
      this.clouds.push({
        group: cloudGroup,
        speed: 1.2 + Math.random() * 2.0
      });
    }
  }

  initAmbientSparkles() {
    const sparkleGeo = new THREE.BufferGeometry();
    const count = 160;
    const positions = new Float32Array(count * 3);

    for (let i = 0; i < count * 3; i += 3) {
      positions[i] = (Math.random() - 0.5) * 110;
      positions[i + 1] = 2 + Math.random() * 50;
      positions[i + 2] = (Math.random() - 0.5) * 130;
    }

    sparkleGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const sparkleMat = new THREE.PointsMaterial({
      color: 0xfffa65,
      size: 0.48,
      transparent: true,
      opacity: 0.75,
      blending: THREE.AdditiveBlending
    });

    this.sparkleSystem = new THREE.Points(sparkleGeo, sparkleMat);
    this.scene.add(this.sparkleSystem);
  }

  update(delta, player, collectibles = null) {
    const time = Date.now() * 0.001;

    // 1. Moving Platforms
    for (const plat of this.movingPlatforms) {
      const prevPos = plat.colliderObj.mesh.position.clone();
      plat.progress += plat.speed * delta * plat.direction;

      if (plat.progress >= 1) {
        plat.progress = 1;
        plat.direction = -1;
      } else if (plat.progress <= 0) {
        plat.progress = 0;
        plat.direction = 1;
      }

      const ease = (1 - Math.cos(plat.progress * Math.PI)) / 2;
      plat.colliderObj.mesh.position.lerpVectors(plat.start, plat.end, ease);
      plat.colliderObj.platformVelocity.copy(plat.colliderObj.mesh.position).sub(prevPos).divideScalar(delta);
      plat.colliderObj.box.setFromCenterAndSize(plat.colliderObj.mesh.position, plat.size);
    }

    // 2. Rotating Platforms (Clockwork Cogs)
    for (const rotPlat of this.rotatingPlatforms) {
      rotPlat.rotation += rotPlat.speed * delta;
      rotPlat.group.rotation.y = rotPlat.rotation;
    }

    // 3. Rotating Hazard Beams
    for (const h of this.hazardObstacles) {
      h.rotation += h.speed * delta;
      h.group.rotation.y = h.rotation;

      const beamWorldPos = new THREE.Vector3();
      h.group.getWorldPosition(beamWorldPos);

      const d = player.mesh.position.distanceTo(beamWorldPos);
      if (d < h.length / 2 + player.radius) {
        const dy = Math.abs(player.mesh.position.y - beamWorldPos.y);
        if (dy < 1.0) {
          const angleToPlayer = Math.atan2(
            player.mesh.position.x - beamWorldPos.x,
            player.mesh.position.z - beamWorldPos.z
          );
          const relativeAngle = Math.abs(angleToPlayer - h.rotation) % Math.PI;
          if (relativeAngle < 0.32 || relativeAngle > Math.PI - 0.32) {
            const knockDir = player.mesh.position.clone().sub(beamWorldPos).normalize();
            player.takeDamage(1, knockDir);
          }
        }
      }
    }

    // 4. Checkpoint Totems
    for (const cp of this.checkpoints) {
      cp.crystal.rotation.y += delta * 2;
      cp.crystal.position.y = 3.0 + Math.sin(time * 3) * 0.15;

      const dist = player.mesh.position.distanceTo(cp.position);
      if (dist < 3.8 && !cp.activated) {
        cp.activated = true;
        cp.crystalMat.color.setHex(0x2ed573);
        cp.crystalMat.emissive.setHex(0x2ed573);
        player.setCheckpoint(cp.position);
        window.dispatchEvent(new CustomEvent('checkpointReached', { detail: { name: cp.name } }));
      }
    }

    // 5. Updraft Air Vents (propel player upward)
    for (const updraft of this.updrafts) {
      for (const p of updraft.particles) {
        p.mesh.position.y += p.speed * delta;
        p.mesh.rotation.y += delta * 4;
        if (p.mesh.position.y > updraft.height) {
          p.mesh.position.y = 0.5;
        }
      }

      // Check player in wind column
      const hDist = Math.hypot(player.mesh.position.x - updraft.position.x, player.mesh.position.z - updraft.position.z);
      const vDist = player.mesh.position.y - updraft.position.y;
      if (hDist < updraft.radius && vDist >= 0 && vDist <= updraft.height) {
        player.velocity.y = Math.max(player.velocity.y, 22.0);
        player.isGrounded = false;
        player.canDoubleJump = true;
        if (Math.random() < 0.2) {
          sounds.playWhoosh();
        }
      }
    }

    // 6. Water Ripple Shader Animation
    if (this.waterMesh) {
      const posAttr = this.waterMesh.geometry.attributes.position;
      const initial = this.waterInitialPositions;
      for (let i = 0; i < posAttr.count; i++) {
        const x = initial[i * 3];
        const z = initial[i * 3 + 2];
        posAttr.setY(i, initial[i * 3 + 1] + Math.sin(time * 2.0 + x * 0.15 + z * 0.15) * 0.28);
      }
      posAttr.needsUpdate = true;
    }

    // 7. Celestial Orbital Ring
    if (this.celestialRing) {
      this.celestialRing.rotation.z += delta * 0.4;
      this.celestialRing.rotation.y += delta * 0.25;
    }

    // 8. Drifting Clouds
    for (const cloud of this.clouds) {
      cloud.group.position.x += cloud.speed * delta;
      if (cloud.group.position.x > 120) {
        cloud.group.position.x = -120;
      }
    }

    // 9. Ambient Sparkles
    if (this.sparkleSystem) {
      const positions = this.sparkleSystem.geometry.attributes.position.array;
      for (let i = 1; i < positions.length; i += 3) {
        positions[i] += Math.sin(time + positions[i]) * 0.02;
      }
      this.sparkleSystem.geometry.attributes.position.needsUpdate = true;
    }

    // 10. Update Crates
    for (const crate of this.crates) {
      crate.update(delta);
    }

    // 11. Bounce pad animations
    for (const pad of this.bouncePads) {
      if (pad.mesh.scale.x > 1.0) {
        pad.mesh.scale.lerp(new THREE.Vector3(1, 1, 1), Math.min(10 * delta, 1));
      }
    }
  }
}
