import * as THREE from 'three';
import { sounds } from './audio.js';

export class EnemyManager {
  constructor(scene) {
    this.scene = scene;
    this.enemies = [];
    this.deathParticles = [];
    this.initDeathParticles();
    this.spawnEnemies();
  }

  initDeathParticles() {
    const geo = new THREE.DodecahedronGeometry(0.18, 0);
    for (let i = 0; i < 50; i++) {
      const mat = new THREE.MeshStandardMaterial({
        color: 0xff6b81,
        roughness: 0.3,
        emissive: 0xff4757,
        emissiveIntensity: 0.4
      });
      const p = new THREE.Mesh(geo, mat);
      p.visible = false;
      this.scene.add(p);
      this.deathParticles.push({
        mesh: p,
        life: 0,
        maxLife: 0.65,
        vel: new THREE.Vector3()
      });
    }
  }

  triggerDeathParticles(pos, color = 0xff4757) {
    let spawned = 0;
    for (const p of this.deathParticles) {
      if (p.life <= 0) {
        p.mesh.position.copy(pos);
        p.mesh.material.color.setHex(color);
        p.mesh.material.emissive.setHex(color);
        p.mesh.visible = true;
        p.life = p.maxLife;
        p.mesh.scale.setScalar(0.7 + Math.random() * 0.5);

        const angle = Math.random() * Math.PI * 2;
        const speed = 4 + Math.random() * 5.5;
        p.vel.set(
          Math.cos(angle) * speed,
          3 + Math.random() * 5.5,
          Math.sin(angle) * speed
        );

        spawned++;
        if (spawned >= 14) break;
      }
    }
  }

  spawnEnemies() {
    // ----------------------------------------------------
    // BIOME 1: MEADOW (Spawn Island)
    // ----------------------------------------------------
    this.createStandardSlime({
      start: new THREE.Vector3(5, 0.5, 6),
      end: new THREE.Vector3(9, 0.5, 6),
      speed: 1.8
    });

    this.createStandardSlime({
      start: new THREE.Vector3(-8, 0.5, 3),
      end: new THREE.Vector3(-8, 0.5, -5),
      speed: 2.0
    });

    // ----------------------------------------------------
    // BIOME 2: BOUNCING CANOPY
    // ----------------------------------------------------
    this.createStandardSlime({
      start: new THREE.Vector3(-4, 5.5, 35),
      end: new THREE.Vector3(4, 5.5, 35),
      speed: 2.2
    });

    // Winged Slime hovering in mid-air near the moving platform
    this.createWingedSlime({
      start: new THREE.Vector3(0, 9.5, 45),
      end: new THREE.Vector3(0, 9.5, 55),
      speed: 1.6
    });

    // ----------------------------------------------------
    // BIOME 3: CLOCKWORK RUINS
    // ----------------------------------------------------
    // Armored Spiky Slime on Island 3 (defeat via ground pound shockwave!)
    this.createSpikySlime({
      start: new THREE.Vector3(-5, 10.5, 78),
      end: new THREE.Vector3(5, 10.5, 78),
      speed: 2.3
    });

    this.createStandardSlime({
      start: new THREE.Vector3(0, 10.5, 71),
      end: new THREE.Vector3(0, 10.5, 83),
      speed: 2.2
    });

    // ----------------------------------------------------
    // BIOME 4 & 5: CRYSTAL CHASM & CELESTIAL SUMMIT
    // ----------------------------------------------------
    // Winged Slime over the cloud gap to Summit
    this.createWingedSlime({
      start: new THREE.Vector3(4, 32.0, 105),
      end: new THREE.Vector3(-4, 32.0, 105),
      speed: 1.8
    });

    // Armored Guard on Summit Shrine
    this.createSpikySlime({
      start: new THREE.Vector3(-6, 37.5, 126),
      end: new THREE.Vector3(6, 37.5, 126),
      speed: 2.8
    });
  }

  createStandardSlime({ start, end, speed }) {
    const group = new THREE.Group();
    group.position.copy(start);

    const blobMat = new THREE.MeshStandardMaterial({
      color: 0x9b59b6, // Amethyst purple
      roughness: 0.3,
      metalness: 0.1,
      flatShading: true
    });

    const eyeMat = new THREE.MeshBasicMaterial({ color: 0x2c3e50 });
    const eyeWhiteMat = new THREE.MeshBasicMaterial({ color: 0xffffff });

    const bodyGeo = new THREE.SphereGeometry(0.55, 8, 8);
    bodyGeo.scale(1, 0.85, 1);
    const body = new THREE.Mesh(bodyGeo, blobMat);
    body.position.y = 0.55;
    body.castShadow = true;
    group.add(body);

    const spikeGeo = new THREE.ConeGeometry(0.18, 0.35, 6);
    const spike = new THREE.Mesh(spikeGeo, new THREE.MeshStandardMaterial({ color: 0xf1c40f }));
    spike.position.y = 1.05;
    group.add(spike);

    // Eyes
    const eyeGeo = new THREE.SphereGeometry(0.14, 6, 6);
    const leftEye = new THREE.Mesh(eyeGeo, eyeWhiteMat);
    leftEye.position.set(-0.2, 0.65, 0.42);
    group.add(leftEye);

    const rightEye = new THREE.Mesh(eyeGeo, eyeWhiteMat);
    rightEye.position.set(0.2, 0.65, 0.42);
    group.add(rightEye);

    const pupilGeo = new THREE.SphereGeometry(0.06, 4, 4);
    const leftPupil = new THREE.Mesh(pupilGeo, eyeMat);
    leftPupil.position.set(-0.2, 0.65, 0.52);
    group.add(leftPupil);

    const rightPupil = new THREE.Mesh(pupilGeo, eyeMat);
    rightPupil.position.set(0.2, 0.65, 0.52);
    group.add(rightPupil);

    this.scene.add(group);

    this.enemies.push({
      type: 'standard',
      group,
      body,
      start,
      end,
      speed,
      progress: Math.random(),
      direction: 1,
      alive: true,
      squashProgress: 0,
      radius: 0.65,
      height: 1.1
    });
  }

  createWingedSlime({ start, end, speed }) {
    const group = new THREE.Group();
    group.position.copy(start);

    const wingSlimeMat = new THREE.MeshStandardMaterial({
      color: 0x00d2d3, // Cyan electric slime
      roughness: 0.25,
      metalness: 0.2,
      flatShading: true
    });

    const bodyGeo = new THREE.SphereGeometry(0.55, 8, 8);
    const body = new THREE.Mesh(bodyGeo, wingSlimeMat);
    body.position.y = 0.55;
    body.castShadow = true;
    group.add(body);

    // Cute animated bat wings
    const wingGeo = new THREE.BoxGeometry(0.7, 0.35, 0.05);
    const wingMat = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.4 });

    const leftWing = new THREE.Mesh(wingGeo, wingMat);
    leftWing.position.set(-0.65, 0.7, 0);
    group.add(leftWing);

    const rightWing = new THREE.Mesh(wingGeo, wingMat);
    rightWing.position.set(0.65, 0.7, 0);
    group.add(rightWing);

    // Eyes
    const eyeGeo = new THREE.SphereGeometry(0.13, 6, 6);
    const leftEye = new THREE.Mesh(eyeGeo, new THREE.MeshBasicMaterial({ color: 0xffffff }));
    leftEye.position.set(-0.18, 0.65, 0.45);
    group.add(leftEye);

    const rightEye = new THREE.Mesh(eyeGeo, new THREE.MeshBasicMaterial({ color: 0xffffff }));
    rightEye.position.set(0.18, 0.65, 0.45);
    group.add(rightEye);

    this.scene.add(group);

    this.enemies.push({
      type: 'winged',
      group,
      body,
      leftWing,
      rightWing,
      start,
      end,
      speed,
      progress: Math.random(),
      direction: 1,
      alive: true,
      squashProgress: 0,
      radius: 0.7,
      height: 1.1
    });
  }

  createSpikySlime({ start, end, speed }) {
    const group = new THREE.Group();
    group.position.copy(start);

    const ironMat = new THREE.MeshStandardMaterial({
      color: 0xe74c3c, // Menacing Crimson Iron
      roughness: 0.4,
      metalness: 0.5,
      flatShading: true
    });

    const bodyGeo = new THREE.DodecahedronGeometry(0.65, 0);
    const body = new THREE.Mesh(bodyGeo, ironMat);
    body.position.y = 0.65;
    body.castShadow = true;
    group.add(body);

    // Sharp golden spikes protruding all over
    const spikeGeo = new THREE.ConeGeometry(0.16, 0.45, 5);
    const spikeMat = new THREE.MeshStandardMaterial({ color: 0xf39c12, metalness: 0.7 });

    const spikePositions = [
      [0, 1.3, 0, 0, 0, 0],
      [0.6, 0.8, 0, 0, 0, -Math.PI / 3],
      [-0.6, 0.8, 0, 0, 0, Math.PI / 3],
      [0, 0.8, 0.6, Math.PI / 3, 0, 0],
      [0, 0.8, -0.6, -Math.PI / 3, 0, 0]
    ];

    spikePositions.forEach(([sx, sy, sz, rx, ry, rz]) => {
      const sp = new THREE.Mesh(spikeGeo, spikeMat);
      sp.position.set(sx, sy, sz);
      sp.rotation.set(rx, ry, rz);
      group.add(sp);
    });

    // Glowing menacing eyes
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0xfffa65 });
    const eyeGeo = new THREE.SphereGeometry(0.12, 6, 6);
    const leftEye = new THREE.Mesh(eyeGeo, eyeMat);
    leftEye.position.set(-0.22, 0.7, 0.5);
    group.add(leftEye);

    const rightEye = new THREE.Mesh(eyeGeo, eyeMat);
    rightEye.position.set(0.22, 0.7, 0.5);
    group.add(rightEye);

    this.scene.add(group);

    this.enemies.push({
      type: 'spiky',
      group,
      body,
      start,
      end,
      speed,
      progress: Math.random(),
      direction: 1,
      alive: true,
      squashProgress: 0,
      radius: 0.75,
      height: 1.2
    });
  }

  update(delta, player, collectibles) {
    const time = Date.now() * 0.005;

    // Update Death particles
    for (const p of this.deathParticles) {
      if (p.life > 0) {
        p.life -= delta;
        p.vel.y -= 19 * delta; // Gravity
        p.mesh.position.addScaledVector(p.vel, delta);
        p.mesh.scale.multiplyScalar(0.96);
        if (p.life <= 0) p.mesh.visible = false;
      }
    }

    for (const enemy of this.enemies) {
      if (!enemy.alive) {
        if (enemy.squashProgress < 1) {
          enemy.squashProgress += delta * 4;
          enemy.group.scale.set(1.4, Math.max(0.05, 1 - enemy.squashProgress), 1.4);
          if (enemy.squashProgress >= 1) {
            enemy.group.visible = false;
          }
        }
        continue;
      }

      // Patrol movement
      enemy.progress += enemy.speed * 0.1 * delta * enemy.direction;
      if (enemy.progress >= 1) {
        enemy.progress = 1;
        enemy.direction = -1;
      } else if (enemy.progress <= 0) {
        enemy.progress = 0;
        enemy.direction = 1;
      }

      enemy.group.position.lerpVectors(enemy.start, enemy.end, enemy.progress);

      // Animation per type
      if (enemy.type === 'winged') {
        // Floating hover + flapping wings
        const hover = Math.sin(time * 3 + enemy.progress * 5) * 0.35;
        enemy.body.position.y = 0.55 + hover;
        enemy.leftWing.rotation.z = Math.sin(time * 12) * 0.55;
        enemy.rightWing.rotation.z = -Math.sin(time * 12) * 0.55;
      } else {
        // Bouncy walk hop
        const hop = Math.abs(Math.sin(time * 3 + enemy.progress * 10)) * 0.2;
        enemy.body.position.y = 0.55 + hop;
        enemy.group.scale.set(1 + hop * 0.3, 1 - hop * 0.2, 1 + hop * 0.3);
      }

      // Face patrol movement direction
      const moveDir = enemy.direction > 0
        ? enemy.end.clone().sub(enemy.start).normalize()
        : enemy.start.clone().sub(enemy.end).normalize();
      const faceAngle = Math.atan2(moveDir.x, moveDir.z);
      enemy.group.rotation.y = faceAngle;

      // Collision detection with player
      const ePos = enemy.group.position;
      const pPos = player.mesh.position;

      const horizDist = Math.hypot(pPos.x - ePos.x, pPos.z - ePos.z);
      const vertDist = pPos.y - ePos.y;

      if (horizDist < enemy.radius + player.radius) {
        // 1. Belly Dive Smash (crushes standard and spiky enemies directly in front!)
        if (player.isDiving && Math.abs(vertDist) < 1.4) {
          enemy.alive = false;
          sounds.playStomp();
          sounds.playCrateSmash();
          window.dispatchEvent(new CustomEvent('screenShake', { detail: { intensity: 10 } }));
          this.triggerDeathParticles(ePos, 0xffa502);

          if (collectibles) {
            collectibles.spawnCoin(ePos.x, ePos.y + 0.8, ePos.z);
          }

          window.dispatchEvent(new CustomEvent('scorePopup', {
            detail: { text: '+200 Dive Smash!', x: ePos.x, y: ePos.y + 1, z: ePos.z }
          }));
          continue;
        }

        // 2. Stomp condition (falling from above)
        const isFalling = (player.velocity.y < -0.5 || player.isGroundPounding);
        if (isFalling && vertDist > 0.4 && vertDist < 2.2) {
          // SPIKY SLIME CHECK: Cannot be stomped from above!
          if (enemy.type === 'spiky') {
            const knockDir = pPos.clone().sub(ePos).normalize();
            player.takeDamage(1, knockDir);
            sounds.playHurt();
            window.dispatchEvent(new CustomEvent('screenShake', { detail: { intensity: 12 } }));
            continue;
          }

          // Stomp successful for standard & winged slimes!
          enemy.alive = false;
          sounds.playStomp();
          this.triggerDeathParticles(ePos, enemy.type === 'winged' ? 0x00d2d3 : 0xff4757);

          // Player acrobatic rebound bounce
          player.velocity.y = player.isGroundPounding ? 22 : (enemy.type === 'winged' ? 18.5 : 15.5);
          player.isGrounded = false;
          player.canDoubleJump = true; // RESETS DOUBLE JUMP!
          player.isGroundPounding = false;
          player.isDiving = false;
          player.spawnDust(8, 0.5, 3.5);

          if (collectibles) {
            collectibles.spawnCoin(ePos.x, ePos.y + 0.8, ePos.z);
          }

          const bonusText = enemy.type === 'winged' ? '+150 Aerial Jump Reset!' : '+100 Stomp!';
          window.dispatchEvent(new CustomEvent('scorePopup', { detail: { text: bonusText, x: ePos.x, y: ePos.y + 1, z: ePos.z } }));
        }
        // 3. Normal horizontal touch damage
        else if (Math.abs(vertDist) < 1.1) {
          const knockDir = pPos.clone().sub(ePos).normalize();
          player.takeDamage(1, knockDir);
        }
      }
    }
  }

  resetAll() {
    for (const enemy of this.enemies) {
      enemy.alive = true;
      enemy.squashProgress = 0;
      enemy.group.visible = true;
      enemy.group.scale.set(1, 1, 1);
      enemy.progress = 0;
      enemy.direction = 1;
      enemy.group.position.copy(enemy.start);
    }
  }
}
