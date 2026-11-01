import { describe, it, expect } from 'vitest';
import { SHIPS, SHIP_KEYS, ShipStats, POWERUP_STATS } from './ships';

describe('Ship definitions', () => {
  it('should export all four ships', () => {
    expect(SHIP_KEYS).toEqual(['f35', 'valkyrie', 'titan', 'spectre']);
    for (const key of SHIP_KEYS) {
      expect(SHIPS[key]).toBeDefined();
    }
  });

  it('every ship should have all required stats', () => {
    const requiredKeys: (keyof ShipStats)[] = [
      'name',
      'description',
      'textureKey',
      'bulletTextureKey',
      'speed',
      'handling',
      'damage',
      'hp',
      'fireRate',
      'bulletSpeed',
    ];
    for (const key of SHIP_KEYS) {
      for (const prop of requiredKeys) {
        expect(SHIPS[key]).toHaveProperty(prop);
      }
    }
  });

  it('every ship should have positive numeric values', () => {
    for (const key of SHIP_KEYS) {
      const { speed, handling, damage, hp, fireRate, bulletSpeed } = SHIPS[key];
      expect(speed).toBeGreaterThan(0);
      expect(handling).toBeGreaterThan(0);
      expect(damage).toBeGreaterThan(0);
      expect(hp).toBeGreaterThan(0);
      expect(fireRate).toBeGreaterThan(0);
      expect(bulletSpeed).toBeGreaterThan(0);
    }
  });

  it('every ship should have non-empty name and description', () => {
    for (const key of SHIP_KEYS) {
      expect(SHIPS[key].name.length).toBeGreaterThan(0);
      expect(SHIPS[key].description.length).toBeGreaterThan(0);
    }
  });

  it('every ship should have non-empty texture keys', () => {
    for (const key of SHIP_KEYS) {
      expect(SHIPS[key].textureKey.length).toBeGreaterThan(0);
      expect(SHIPS[key].bulletTextureKey.length).toBeGreaterThan(0);
    }
  });

  it('every ship should have a unique texture key', () => {
    const textureKeys = SHIP_KEYS.map((k) => SHIPS[k].textureKey);
    expect(new Set(textureKeys).size).toBe(textureKeys.length);
  });

  it('every ship should have a unique bullet texture key', () => {
    const bulletKeys = SHIP_KEYS.map((k) => SHIPS[k].bulletTextureKey);
    expect(new Set(bulletKeys).size).toBe(bulletKeys.length);
  });

  it('f35 should be named "F-35 Lightning"', () => {
    expect(SHIPS.f35.name).toBe('F-35 Lightning');
  });

  it('valkyrie should be the fastest ship', () => {
    const valkSpeed = SHIPS.valkyrie.speed;
    for (const key of SHIP_KEYS) {
      if (key !== 'valkyrie') {
        expect(valkSpeed).toBeGreaterThan(SHIPS[key].speed);
      }
    }
  });

  it('titan should have the most HP', () => {
    const titanHp = SHIPS.titan.hp;
    for (const key of SHIP_KEYS) {
      if (key !== 'titan') {
        expect(titanHp).toBeGreaterThan(SHIPS[key].hp);
      }
    }
  });
});

describe('POWERUP_STATS', () => {
  it('should have all required ShipStats fields', () => {
    const requiredKeys: (keyof ShipStats)[] = [
      'name',
      'description',
      'textureKey',
      'bulletTextureKey',
      'speed',
      'handling',
      'damage',
      'hp',
      'fireRate',
      'bulletSpeed',
    ];
    for (const prop of requiredKeys) {
      expect(POWERUP_STATS).toHaveProperty(prop);
    }
  });

  it('should have positive numeric values', () => {
    const { speed, handling, damage, hp, fireRate, bulletSpeed } = POWERUP_STATS;
    expect(speed).toBeGreaterThan(0);
    expect(handling).toBeGreaterThan(0);
    expect(damage).toBeGreaterThan(0);
    expect(hp).toBeGreaterThan(0);
    expect(fireRate).toBeGreaterThan(0);
    expect(bulletSpeed).toBeGreaterThan(0);
  });

  it('should be stronger than every base ship', () => {
    for (const key of SHIP_KEYS) {
      const ship = SHIPS[key];
      expect(POWERUP_STATS.speed).toBeGreaterThanOrEqual(ship.speed);
      expect(POWERUP_STATS.damage).toBeGreaterThanOrEqual(ship.damage);
      expect(POWERUP_STATS.hp).toBeGreaterThanOrEqual(ship.hp);
      expect(POWERUP_STATS.fireRate).toBeGreaterThanOrEqual(ship.fireRate);
    }
  });

  it('should use its own unique texture keys', () => {
    expect(POWERUP_STATS.textureKey).toBe('powerup_disguise');
    expect(POWERUP_STATS.bulletTextureKey).toBe('bullet_powerup');
  });
});
