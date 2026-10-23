import { WEAPONS, WEAPON_KEYS } from '../config.js';

export default class WeaponSystem {
  constructor() {
    this.currentIndex = 0;
    this.damageMultiplier = 1;
    this.damageBoostTimer = 0;
  }

  getCurrent() {
    return WEAPONS[WEAPON_KEYS[this.currentIndex]];
  }

  getCurrentKey() {
    return WEAPON_KEYS[this.currentIndex];
  }

  select(index) {
    if (index >= 0 && index < WEAPON_KEYS.length) {
      this.currentIndex = index;
    }
  }

  selectByKeyCode(keyCode) {
    // Keys 1, 2, 3
    const index = keyCode - 49; // KeyCode for '1' is 49
    if (index >= 0 && index < WEAPON_KEYS.length) {
      this.currentIndex = index;
      return true;
    }
    return false;
  }

  applyDamageBoost(multiplier, duration) {
    this.damageMultiplier = multiplier;
    this.damageBoostTimer = duration;
  }

  update(delta) {
    if (this.damageBoostTimer > 0) {
      this.damageBoostTimer -= delta;
      if (this.damageBoostTimer <= 0) {
        this.damageMultiplier = 1;
        this.damageBoostTimer = 0;
      }
    }
  }

  getEffectiveDamage() {
    return this.getCurrent().damage * this.damageMultiplier;
  }

  reset() {
    this.currentIndex = 0;
    this.damageMultiplier = 1;
    this.damageBoostTimer = 0;
  }
}
