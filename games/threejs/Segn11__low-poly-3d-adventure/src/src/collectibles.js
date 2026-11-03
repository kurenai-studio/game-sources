import * as THREE from 'three';
import { sounds } from './audio.js';

export class CollectiblesManager {
  constructor(scene) {
    this.scene = scene;
    this.coins = [];
    this.redCoins = [];
    this.stars = [];
    this.hearts = [];
    this.collectParticles = [];

    this.coinsCollected = 0;
    this.totalCoins = 0;
    this.redCoinsCollected = 0;
    this.totalRedCoins = 8;
    this.starsCollected = 0;
    this.totalStars = 5;

    this.initSparklePool();
    this.spawnWorldCollectibles();
  }

  initSparklePool() {
    const geo = new THREE.DodecahedronGeometry(0.14, 0);
    for (let i = 0; i < 60; i++) {
      const mat = new THREE.MeshBasicMaterial({
        color: 0xffd32a,
        transparent: true,
        opacity: 0.95
      });
      const p = new THREE.Mesh(geo, mat);
      p.visible = false;
      this.scene.add(p);
      this.collectParticles.push({
        mesh: p,
        life: 0,
        maxLife: 0.5,
        vel: new THREE.Vector3()
      });
    }
  }

  triggerSparkles(pos, color = 0xffd32a, count = 12) {
    let spawned = 0;
    for (const p of this.collectParticles) {
      if (p.life <= 0) {
        p.mesh.position.copy(pos);
        p.mesh.material.color.setHex(color);
        p.mesh.visible = true;
        p.life = p.maxLife;
        p.mesh.scale.setScalar(0.75 + Math.random() * 0.6);

        const angle = Math.random() * Math.PI * 2;
        const speed = 2.8 + Math.random() * 4.0;
        p.vel.set(
          Math.cos(angle) * speed,
          2.5 + Math.random() * 3.5,
          Math.sin(angle) * speed
        );

        spawned++;
        if (spawned >= count) break;
      }
    }
  }

  spawnWorldCollectibles() {
    // ----------------------------------------------------
    // 1. STANDARD COINS (Meadow, Canopy, Ruins, Chasm, Summit)
    // ----------------------------------------------------
    const meadowCoins = [
      [-3, 1.2, 2], [0, 1.2, 2], [3, 1.2, 2],
      [-2, 1.2, -2], [2, 1.2, -2],
      [-6, 1.2, 0], [6, 1.2, 0],
      [0, 2.7, 17], [0, 4.7, 23]
    ];
    meadowCoins.forEach(([x, y, z]) => this.spawnCoin(x, y, z));

    const island2Coins = [
      [-4, 6.2, 35], [4, 6.2, 35],
      [0, 11.5, 39],
      [0, 14.5, 39],
      [0, 8.7, 55]
    ];
    island2Coins.forEach(([x, y, z]) => this.spawnCoin(x, y, z));

    const ruinsCoins = [
      [-4, 11.2, 76], [4, 11.2, 76],
      [16, 13.5, 76],
      [16, 25.0, 62],
      [16, 28.5, 88],
      [9, 31.5, 99],
      [0, 34.5, 110]
    ];
    ruinsCoins.forEach(([x, y, z]) => this.spawnCoin(x, y, z));

    const summitCoins = [
      [-6, 38.5, 124], [6, 38.5, 124],
      [-6, 38.5, 136], [6, 38.5, 136],
      [0, 38.5, 136], [0, 38.5, 124]
    ];
    summitCoins.forEach(([x, y, z]) => this.spawnCoin(x, y, z));

    // ----------------------------------------------------
    // 2. THE 8 SECRET RED COINS QUEST
    // ----------------------------------------------------
    // Red Coin 1: Hidden behind tree on Island 1
    this.spawnRedCoin(-8, 1.3, -8);
    // Red Coin 2: Inside wooden crate on Island 1 (spawned dynamically or placed)
    this.spawnRedCoin(-7, 2.8, 7);
    // Red Coin 3: Mid-air bounce apex on Island 2
    this.spawnRedCoin(0, 17.5, 39);
    // Red Coin 4: Underneath the moving platform chasm
    this.spawnRedCoin(0, 5.0, 55);
    // Red Coin 5: On Island 3 wind updraft column
    this.spawnRedCoin(-12, 17.0, 76);
    // Red Coin 6: Rotating clockwork cog platform edge
    this.spawnRedCoin(19, 13.2, 76);
    // Red Coin 7: Crystal Peak high ledge
    this.spawnRedCoin(16, 26.2, 62);
    // Red Coin 8: Sacred temple orbital ring approach
    this.spawnRedCoin(0, 39.5, 122);

    // ----------------------------------------------------
    // 3. HEALTH HEARTS
    // ----------------------------------------------------
    this.spawnHeart(-9, 1.2, -6);
    this.spawnHeart(0, 11.2, 82);
    this.spawnHeart(0, 38.5, 134);

    // ----------------------------------------------------
    // 4. THE 5 GRAND POWER STARS (Odyssey/Mario 64 Missions)
    // ----------------------------------------------------
    // Star 1: Meadow Grove Discovery
    this.spawnStar(-8, 1.8, 7, "Meadow Grove Discovery");

    // Star 2: Crimson Constellation (Secret Red Coin reward - will appear when 8 red coins are collected)
    this.redCoinStar = this.spawnStar(0, 8.5, 35, "Crimson Constellation", false); // initially hidden

    // Star 3: High-Flying Hop (Super bounce apex)
    this.spawnStar(0, 20.0, 39, "High-Flying Hop");

    // Star 4: Gears of Antiquity (On ancient arch in ruins)
    this.spawnStar(0, 17.5, 76, "Gears of Antiquity");

    // Star 5: Celestial Apex Star (Temple Altar summit)
    this.spawnStar(0, 42.5, 130, "Celestial Apex Star");
  }

  spawnCoin(x, y, z) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    const coinGeo = new THREE.CylinderGeometry(0.38, 0.38, 0.1, 14);
    coinGeo.rotateX(Math.PI / 2);

    const coinMat = new THREE.MeshStandardMaterial({
      color: 0xffd700,
      metalness: 0.85,
      roughness: 0.2,
      emissive: 0xff9900,
      emissiveIntensity: 0.25
    });

    const mesh = new THREE.Mesh(coinGeo, coinMat);
    mesh.castShadow = true;
    group.add(mesh);

    const starGeo = new THREE.OctahedronGeometry(0.18, 0);
    const starMat = new THREE.MeshBasicMaterial({ color: 0xfff275 });
    const star = new THREE.Mesh(starGeo, starMat);
    group.add(star);

    this.scene.add(group);

    this.coins.push({
      group,
      baseY: y,
      collected: false
    });
    this.totalCoins++;
  }

  spawnRedCoin(x, y, z) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    // Gleaming crimson red coin with glowing gold rim
    const coinGeo = new THREE.CylinderGeometry(0.48, 0.48, 0.12, 14);
    coinGeo.rotateX(Math.PI / 2);

    const redCoinMat = new THREE.MeshStandardMaterial({
      color: 0xff3838,
      metalness: 0.8,
      roughness: 0.15,
      emissive: 0xff4757,
      emissiveIntensity: 0.45
    });

    const mesh = new THREE.Mesh(coinGeo, redCoinMat);
    mesh.castShadow = true;
    group.add(mesh);

    // Glowing red ruby star center
    const starGeo = new THREE.OctahedronGeometry(0.24, 0);
    const starMat = new THREE.MeshBasicMaterial({ color: 0xffffff });
    const star = new THREE.Mesh(starGeo, starMat);
    group.add(star);

    // Subtle red halo ring
    const ringGeo = new THREE.TorusGeometry(0.65, 0.03, 6, 20);
    const ringMat = new THREE.MeshBasicMaterial({ color: 0xff6b81, transparent: true, opacity: 0.7 });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    group.add(ring);

    this.scene.add(group);

    this.redCoins.push({
      group,
      ring,
      baseY: y,
      collected: false
    });
  }

  spawnStar(x, y, z, name, visible = true) {
    const group = new THREE.Group();
    group.position.set(x, y, z);
    group.visible = visible;

    const starGroup = new THREE.Group();

    // 5-point star
    const starShape = new THREE.Shape();
    const points = 5;
    const outerRadius = 0.95;
    const innerRadius = 0.44;

    for (let i = 0; i < points * 2; i++) {
      const r = (i % 2 === 0) ? outerRadius : innerRadius;
      const angle = (i / (points * 2)) * Math.PI * 2 - Math.PI / 2;
      const px = Math.cos(angle) * r;
      const py = Math.sin(angle) * r;
      if (i === 0) starShape.moveTo(px, py);
      else starShape.lineTo(px, py);
    }
    starShape.closePath();

    const extrudeSettings = { depth: 0.38, bevelEnabled: true, bevelSegments: 2, steps: 1, bevelSize: 0.09, bevelThickness: 0.09 };
    const starGeo = new THREE.ExtrudeGeometry(starShape, extrudeSettings);
    starGeo.center();

    const starMat = new THREE.MeshStandardMaterial({
      color: 0xffe024,
      metalness: 0.45,
      roughness: 0.15,
      emissive: 0xffb703,
      emissiveIntensity: 0.65
    });

    const starMesh = new THREE.Mesh(starGeo, starMat);
    starGroup.add(starMesh);

    // Star Eyes
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0x1e272e });
    const eyeGeo = new THREE.CapsuleGeometry(0.045, 0.15, 4, 8);

    const leftEye = new THREE.Mesh(eyeGeo, eyeMat);
    leftEye.position.set(-0.18, 0.06, 0.3);
    starGroup.add(leftEye);

    const rightEye = new THREE.Mesh(eyeGeo, eyeMat);
    rightEye.position.set(0.18, 0.06, 0.3);
    starGroup.add(rightEye);

    // Rotating Glowing Aura Ring
    const ringGeo = new THREE.TorusGeometry(1.25, 0.045, 8, 28);
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0x00f2fe,
      transparent: true,
      opacity: 0.8
    });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    ring.rotation.x = Math.PI / 3;
    group.add(ring);

    group.add(starGroup);
    this.scene.add(group);

    const starObj = {
      group,
      starGroup,
      ring,
      baseY: y,
      name,
      collected: false
    };

    this.stars.push(starObj);
    return starObj;
  }

  spawnHeart(x, y, z) {
    const group = new THREE.Group();
    group.position.set(x, y, z);

    const heartShape = new THREE.Shape();
    const x0 = 0, y0 = 0;
    heartShape.moveTo(x0 + 0.25, y0 + 0.25);
    heartShape.bezierCurveTo(x0 + 0.25, y0 + 0.25, x0 + 0.2, y0, x0, y0);
    heartShape.bezierCurveTo(x0 - 0.3, y0, x0 - 0.3, y0 + 0.35, x0 - 0.3, y0 + 0.35);
    heartShape.bezierCurveTo(x0 - 0.3, y0 + 0.55, x0 - 0.1, y0 + 0.77, x0 + 0.25, y0 + 1.0);
    heartShape.bezierCurveTo(x0 + 0.6, y0 + 0.77, x0 + 0.8, y0 + 0.55, x0 + 0.8, y0 + 0.35);
    heartShape.bezierCurveTo(x0 + 0.8, y0 + 0.35, x0 + 0.8, y0, x0 + 0.5, y0);
    heartShape.bezierCurveTo(x0 + 0.35, y0, x0 + 0.25, y0 + 0.25, x0 + 0.25, y0 + 0.25);

    const extrudeSettings = { depth: 0.2, bevelEnabled: true, bevelSegments: 2, steps: 1, bevelSize: 0.05, bevelThickness: 0.05 };
    const heartGeo = new THREE.ExtrudeGeometry(heartShape, extrudeSettings);
    heartGeo.center();
    heartGeo.rotateZ(Math.PI);

    const heartMat = new THREE.MeshStandardMaterial({
      color: 0xff3838,
      emissive: 0xff4757,
      emissiveIntensity: 0.45,
      roughness: 0.3
    });

    const mesh = new THREE.Mesh(heartGeo, heartMat);
    mesh.scale.set(0.65, 0.65, 0.65);
    group.add(mesh);
    this.scene.add(group);

    this.hearts.push({
      group,
      mesh,
      baseY: y,
      collected: false
    });
  }

  update(delta, player) {
    const time = Date.now() * 0.003;
    const playerPos = player.mesh.position;

    // Update Sparkles
    for (const p of this.collectParticles) {
      if (p.life > 0) {
        p.life -= delta;
        p.vel.y -= 9 * delta;
        p.mesh.position.addScaledVector(p.vel, delta);
        const progress = 1 - (p.life / p.maxLife);
        p.mesh.scale.setScalar((1 - progress) * 0.8);
        if (p.life <= 0) p.mesh.visible = false;
      }
    }

    // 1. Update Standard Coins
    for (const coin of this.coins) {
      if (coin.collected) continue;

      coin.group.rotation.y += delta * 3.4;
      coin.group.position.y = coin.baseY + Math.sin(time * 3 + coin.group.position.x) * 0.18;

      const dist = coin.group.position.distanceTo(playerPos);
      if (dist < 4.2) {
        coin.group.position.lerp(playerPos.clone().add(new THREE.Vector3(0, 0.7, 0)), delta * 8);
      }

      if (dist < 1.35) {
        coin.collected = true;
        coin.group.visible = false;
        this.coinsCollected++;
        sounds.playCoin();
        this.triggerSparkles(coin.group.position, 0xffd32a, 8);

        window.dispatchEvent(new CustomEvent('coinCollected', {
          detail: { current: this.coinsCollected, total: this.totalCoins }
        }));
      }
    }

    // 2. Update Red Coins
    for (const redCoin of this.redCoins) {
      if (redCoin.collected) continue;

      redCoin.group.rotation.y += delta * 3.8;
      redCoin.ring.rotation.z += delta * 2.5;
      redCoin.group.position.y = redCoin.baseY + Math.sin(time * 3.5 + redCoin.group.position.z) * 0.22;

      const dist = redCoin.group.position.distanceTo(playerPos);
      if (dist < 4.5) {
        redCoin.group.position.lerp(playerPos.clone().add(new THREE.Vector3(0, 0.8, 0)), delta * 7);
      }

      if (dist < 1.4) {
        redCoin.collected = true;
        redCoin.group.visible = false;
        sounds.playRedCoin(this.redCoinsCollected);
        this.redCoinsCollected++;
        this.triggerSparkles(redCoin.group.position, 0xff3838, 16);

        window.dispatchEvent(new CustomEvent('redCoinCollected', {
          detail: { current: this.redCoinsCollected, total: this.totalRedCoins }
        }));

        // All 8 Red Coins Collected!
        if (this.redCoinsCollected >= this.totalRedCoins && this.redCoinStar && !this.redCoinStar.collected) {
          this.redCoinStar.group.visible = true;
          sounds.playVictory();
          window.dispatchEvent(new CustomEvent('notification', {
            detail: { text: "🌟 The Crimson Constellation Star has appeared at Bouncing Canopy!" }
          }));
          window.dispatchEvent(new CustomEvent('screenShake', { detail: { intensity: 14 } }));
        }
      }
    }

    // 3. Update Stars
    for (const star of this.stars) {
      if (star.collected || !star.group.visible) continue;

      star.starGroup.rotation.y += delta * 1.8;
      star.starGroup.rotation.z = Math.sin(time * 2) * 0.1;
      star.ring.rotation.z += delta * 2.5;
      star.ring.rotation.x = Math.PI / 3 + Math.cos(time * 1.5) * 0.2;
      star.group.position.y = star.baseY + Math.sin(time * 2) * 0.3;

      const dist = star.group.position.distanceTo(playerPos);
      if (dist < 1.9) {
        star.collected = true;
        star.group.visible = false;
        this.starsCollected++;
        sounds.playStarCollect();
        this.triggerSparkles(star.group.position, 0xfffa65, 30);

        window.dispatchEvent(new CustomEvent('starCollected', {
          detail: {
            current: this.starsCollected,
            total: this.totalStars,
            name: star.name
          }
        }));

        if (this.starsCollected >= this.totalStars) {
          sounds.playVictory();
          window.dispatchEvent(new CustomEvent('gameWon'));
        }
      }
    }

    // 4. Update Hearts
    for (const heart of this.hearts) {
      if (heart.collected) continue;

      heart.group.rotation.y += delta * 2.2;
      const pulse = 1 + Math.sin(time * 6) * 0.12;
      heart.mesh.scale.set(0.65 * pulse, 0.65 * pulse, 0.65 * pulse);
      heart.group.position.y = heart.baseY + Math.sin(time * 2.5) * 0.16;

      const dist = heart.group.position.distanceTo(playerPos);
      if (dist < 1.45) {
        if (player.health < player.maxHealth) {
          player.heal(1);
          heart.collected = true;
          heart.group.visible = false;
          sounds.playCheckpoint();
          this.triggerSparkles(heart.group.position, 0xff4757, 14);
          window.dispatchEvent(new CustomEvent('healthChanged', { detail: { health: player.health } }));
        }
      }
    }
  }

  resetAll() {
    this.coinsCollected = 0;
    this.redCoinsCollected = 0;
    this.starsCollected = 0;

    for (const c of this.coins) {
      c.collected = false;
      c.group.visible = true;
      c.group.position.y = c.baseY;
    }
    for (const rc of this.redCoins) {
      rc.collected = false;
      rc.group.visible = true;
      rc.group.position.y = rc.baseY;
    }
    for (const s of this.stars) {
      s.collected = false;
      // Crimson Constellation starts hidden
      s.group.visible = (s !== this.redCoinStar);
    }
    for (const h of this.hearts) {
      h.collected = false;
      h.group.visible = true;
    }
  }
}
