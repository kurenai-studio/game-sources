import { describe, expect, it } from 'vitest';
import { WeaponState } from '../src/core/WeaponState.js';

describe('WeaponState', () => {
  it('consumes one round and enforces the bolt cooldown', () => {
    const weapon = new WeaponState({ magazineSize: 5, reserve: 10, fireCooldown: 0.6 });

    expect(weapon.fire()).toBe(true);
    expect(weapon.ammo).toBe(4);
    expect(weapon.fire()).toBe(false);

    weapon.update(0.6);
    expect(weapon.fire()).toBe(true);
    expect(weapon.ammo).toBe(3);
  });

  it('reloads only the rounds available in reserve', () => {
    const weapon = new WeaponState({ magazineSize: 5, reserve: 2, reloadDuration: 1 });
    weapon.ammo = 1;

    expect(weapon.startReload()).toBe(true);
    weapon.update(1);

    expect(weapon.ammo).toBe(3);
    expect(weapon.reserve).toBe(0);
    expect(weapon.reloading).toBe(false);
  });
});
