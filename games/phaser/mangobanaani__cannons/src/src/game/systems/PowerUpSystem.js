import PowerUp from '../objects/PowerUp.js';
import * as Config from '../config.js';

const POWERUP_KEYS = Object.keys(Config.POWERUP_TYPES);

export default class PowerUpSystem {
  constructor(scene) {
    this.scene = scene;
    this.activePowerUps = [];
    this.spawnTimer = 0;
    this.nextSpawnTime = this.randomSpawnTime();
  }

  randomSpawnTime() {
    return Config.POWERUP_INTERVAL_MIN +
      Math.random() * (Config.POWERUP_INTERVAL_MAX - Config.POWERUP_INTERVAL_MIN);
  }

  update(delta, terrain, playerCannon, aiCannon, weaponSystem) {
    this.spawnTimer += delta;

    if (this.spawnTimer >= this.nextSpawnTime) {
      this.spawnTimer = 0;
      this.nextSpawnTime = this.randomSpawnTime();
      this.spawn();
    }

    const toRemove = [];

    for (let i = 0; i < this.activePowerUps.length; i++) {
      const pu = this.activePowerUps[i];
      pu.update();

      // Check terrain collision (remove if hits ground)
      const ix = Math.floor(pu.x);
      if (ix >= 0 && ix < Config.GAME_WIDTH && pu.y >= terrain.getHeightAt(ix)) {
        pu.destroy();
        toRemove.push(i);
        continue;
      }

      // Check water
      if (pu.y >= Config.WATER_LEVEL) {
        pu.destroy();
        toRemove.push(i);
        continue;
      }

      // Check player collection
      const distToPlayer = Math.sqrt(
        (pu.x - playerCannon.x) ** 2 + (pu.y - playerCannon.y) ** 2
      );
      if (distToPlayer < 30) {
        this.applyEffect(pu.type, playerCannon, weaponSystem);
        pu.destroy();
        toRemove.push(i);
        continue;
      }

      // Check AI collection
      const distToAI = Math.sqrt(
        (pu.x - aiCannon.x) ** 2 + (pu.y - aiCannon.y) ** 2
      );
      if (distToAI < 30) {
        this.applyEffect(pu.type, aiCannon, null);
        pu.destroy();
        toRemove.push(i);
        continue;
      }
    }

    for (let i = toRemove.length - 1; i >= 0; i--) {
      this.activePowerUps.splice(toRemove[i], 1);
    }
  }

  spawn() {
    const typeKey = POWERUP_KEYS[Math.floor(Math.random() * POWERUP_KEYS.length)];
    const x = 100 + Math.random() * (Config.GAME_WIDTH - 200);
    const pu = new PowerUp(this.scene, x, -20, typeKey);
    this.activePowerUps.push(pu);
  }

  applyEffect(type, cannon, weaponSystem) {
    const config = Config.POWERUP_TYPES[type];
    if (!config) return;

    switch (type) {
      case 'health':
        cannon.heal(config.value);
        break;
      case 'damage':
        if (weaponSystem) {
          weaponSystem.applyDamageBoost(config.value, config.duration);
        }
        break;
      case 'shield':
        cannon.addShield(config.value);
        break;
    }
  }

  destroyAll() {
    for (const pu of this.activePowerUps) {
      pu.destroy();
    }
    this.activePowerUps = [];
    this.spawnTimer = 0;
    this.nextSpawnTime = this.randomSpawnTime();
  }
}
