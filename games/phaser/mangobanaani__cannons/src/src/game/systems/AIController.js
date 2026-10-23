import { calculateAIShot, calculateBracketedShot } from '../utils/ai.js';
import { getDifficultyConfig, getAIName } from '../utils/difficulty.js';
import * as Config from '../config.js';

export default class AIController {
  constructor(difficulty = 'medium') {
    this.setDifficulty(difficulty);
    this.cooldownTimer = 0;
    this.cooldownDuration = 0;
    this.lastMiss = null;
    this.resetCooldown();
  }

  setDifficulty(difficulty) {
    this.difficulty = difficulty;
    this.config = getDifficultyConfig(difficulty);
    this.name = getAIName(difficulty);
  }

  resetCooldown() {
    const { cooldownMin, cooldownMax } = this.config;
    this.cooldownDuration = cooldownMin + Math.random() * (cooldownMax - cooldownMin);
    this.cooldownTimer = 0;
  }

  update(delta, aiCannon, playerCannon, windSystem, projectileManager, weaponSystem) {
    this.cooldownTimer += delta;

    if (this.cooldownTimer < this.cooldownDuration) return null;
    if (projectileManager.hasActiveProjectiles('ai')) return null;

    // Ready to fire
    this.cooldownTimer = 0;
    this.resetCooldown();

    const wind = windSystem.getWind();
    const maxPower = aiCannon.getEffectiveMaxPower();

    let shot;
    if (this.config.learns && this.lastMiss) {
      shot = calculateBracketedShot(
        aiCannon.x, aiCannon.y,
        playerCannon.x, playerCannon.y,
        Config.GRAVITY, maxPower,
        this.config.errorFactor,
        wind, this.config.windCompensation,
        this.lastMiss
      );
    } else {
      shot = calculateAIShot(
        aiCannon.x, aiCannon.y,
        playerCannon.x, playerCannon.y,
        Config.GRAVITY, maxPower,
        this.config.errorFactor,
        wind, this.config.windCompensation
      );
    }

    aiCannon.angle = shot.angle;
    aiCannon.power = shot.power;
    aiCannon.draw();

    // AI uses standard weapon
    const weapon = Config.WEAPONS.standard;
    return { weapon, owner: 'ai' };
  }

  recordMiss(impactX, impactY) {
    this.lastMiss = { x: impactX, y: impactY };
  }

  reset() {
    this.cooldownTimer = 0;
    this.lastMiss = null;
    this.resetCooldown();
  }
}
