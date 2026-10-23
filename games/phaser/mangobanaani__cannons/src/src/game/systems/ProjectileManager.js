import Projectile from '../objects/Projectile.js';
import * as Config from '../config.js';

export default class ProjectileManager {
  constructor(scene) {
    this.scene = scene;
    this.projectiles = [];
  }

  fire(cannon, weapon, wind, owner) {
    const tip = cannon.getBarrelTip();
    const dir = cannon.isPlayer ? 1 : -1;
    const speedMult = weapon.speedMultiplier || 1;
    const vx = cannon.power * Math.cos(cannon.angle) * dir * speedMult;
    const vy = -cannon.power * Math.sin(cannon.angle) * speedMult;

    const proj = new Projectile(this.scene, tip.x, tip.y, vx, vy, {
      owner,
      weapon,
      wind,
      isCluster: false,
    });
    this.projectiles.push(proj);
    return proj;
  }

  spawnClusterSub(x, y, baseVx, baseVy, weapon, wind, owner) {
    const offsets = [-0.3, 0, 0.3];
    for (const offset of offsets) {
      const vx = baseVx * (1 + offset * 0.5);
      const vy = baseVy * 0.5;
      const proj = new Projectile(this.scene, x, y, vx, vy, {
        owner,
        weapon: { ...weapon, projectileCount: 1 }, // sub-projectiles don't split again
        wind,
        isCluster: true,
      });
      this.projectiles.push(proj);
    }
  }

  update(terrain, playerCannon, aiCannon, windSystem, callbacks) {
    const wind = windSystem.getWind();
    const toRemove = [];

    for (let i = 0; i < this.projectiles.length; i++) {
      const proj = this.projectiles[i];
      if (!proj.alive) {
        toRemove.push(i);
        continue;
      }

      // Apply wind force per frame
      proj.applyWind(wind);
      proj.updateTrail();

      const pos = proj.getPosition();
      const ix = Math.floor(pos.x);

      // Check water kill
      if (pos.y >= Config.WATER_LEVEL) {
        proj.destroy();
        toRemove.push(i);
        callbacks.onWaterSplash?.(pos.x, pos.y);
        continue;
      }

      // Check terrain collision
      if (ix >= 0 && ix < Config.GAME_WIDTH && pos.y >= terrain.getHeightAt(ix)) {
        // Check cluster split
        if (proj.options.weapon.projectileCount === 3 && !proj.options.isCluster) {
          const vel = proj.getVelocity();
          this.spawnClusterSub(pos.x, pos.y - 20, vel.x, vel.y, proj.options.weapon, wind, proj.options.owner);
          proj.destroy();
          toRemove.push(i);
          continue;
        }

        proj.destroy();
        toRemove.push(i);
        callbacks.onImpact?.(pos.x, pos.y, proj.options);
        continue;
      }

      // Off-screen check
      if (pos.x < -50 || pos.x > Config.GAME_WIDTH + 50 ||
          pos.y > Config.GAME_HEIGHT + 50 || pos.y < -1000) {
        proj.destroy();
        toRemove.push(i);
        continue;
      }
    }

    // Remove dead projectiles (reverse order to preserve indices)
    for (let i = toRemove.length - 1; i >= 0; i--) {
      this.projectiles.splice(toRemove[i], 1);
    }
  }

  hasActiveProjectiles(owner) {
    return this.projectiles.some(p => p.alive && p.options.owner === owner);
  }

  getActiveCount() {
    return this.projectiles.filter(p => p.alive).length;
  }

  destroyAll() {
    for (const proj of this.projectiles) {
      if (proj.alive) proj.destroy();
    }
    this.projectiles = [];
  }
}
