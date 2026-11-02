package com.bossfight.boss;

import com.bossfight.entities.Projectile;

@FunctionalInterface
public interface ProjectileSpawner {
    void addProjectile(Projectile projectile);
}
