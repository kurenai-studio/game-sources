export class WeaponState {
  constructor({ magazineSize = 5, reserve = 10, fireCooldown = 0.6, reloadDuration = 1.8 } = {}) {
    this.magazineSize = magazineSize;
    this.ammo = magazineSize;
    this.reserve = reserve;
    this.fireCooldown = fireCooldown;
    this.reloadDuration = reloadDuration;
    this.cooldownRemaining = 0;
    this.reloadRemaining = 0;
    this.reloading = false;
  }

  fire() {
    if (this.reloading || this.cooldownRemaining > 0 || this.ammo <= 0) return false;
    this.ammo -= 1;
    this.cooldownRemaining = this.fireCooldown;
    return true;
  }

  startReload() {
    if (this.reloading || this.ammo >= this.magazineSize || this.reserve <= 0) return false;
    this.reloading = true;
    this.reloadRemaining = this.reloadDuration;
    return true;
  }

  update(dt) {
    this.cooldownRemaining = Math.max(0, this.cooldownRemaining - dt);
    if (!this.reloading) return;

    this.reloadRemaining -= dt;
    if (this.reloadRemaining > 0) return;

    const rounds = Math.min(this.magazineSize - this.ammo, this.reserve);
    this.ammo += rounds;
    this.reserve -= rounds;
    this.reloading = false;
    this.reloadRemaining = 0;
  }

  reset() {
    this.ammo = this.magazineSize;
    this.reserve = 10;
    this.cooldownRemaining = 0;
    this.reloadRemaining = 0;
    this.reloading = false;
  }
}
