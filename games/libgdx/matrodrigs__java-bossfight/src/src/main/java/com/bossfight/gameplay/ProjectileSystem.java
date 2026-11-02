package com.bossfight.gameplay;

import com.badlogic.gdx.utils.Array;
import com.bossfight.boss.ProjectileSpawner;
import com.bossfight.entities.Projectile;

import java.util.function.Predicate;

public final class ProjectileSystem implements ProjectileSpawner {
    private final Array<Projectile> playerProjectiles = new Array<>();
    private final Array<Projectile> bossProjectiles = new Array<>();

    @Override
    public void addProjectile(Projectile projectile) {
        if (projectile.getOwner() == Projectile.Owner.PLAYER) {
            playerProjectiles.add(projectile);
        } else {
            bossProjectiles.add(projectile);
        }
    }

    public void update(float delta) {
        updateProjectiles(playerProjectiles, delta);
        updateProjectiles(bossProjectiles, delta);
    }

    public void clear() {
        playerProjectiles.clear();
        bossProjectiles.clear();
    }

    public void removePlayerProjectilesIf(Predicate<Projectile> removalRule) {
        removeProjectilesIf(playerProjectiles, removalRule);
    }

    public void removeBossProjectilesIf(Predicate<Projectile> removalRule) {
        removeProjectilesIf(bossProjectiles, removalRule);
    }

    public Iterable<Projectile> playerProjectiles() {
        return playerProjectiles;
    }

    public Iterable<Projectile> bossProjectiles() {
        return bossProjectiles;
    }

    private void updateProjectiles(Array<Projectile> projectiles, float delta) {
        for (int i = projectiles.size - 1; i >= 0; i--) {
            Projectile projectile = projectiles.get(i);
            projectile.update(delta);

            if (!projectile.isActive() || projectile.isOutsideWorld()) {
                projectiles.removeIndex(i);
            }
        }
    }

    private void removeProjectilesIf(Array<Projectile> projectiles, Predicate<Projectile> removalRule) {
        for (int i = projectiles.size - 1; i >= 0; i--) {
            Projectile projectile = projectiles.get(i);
            if (removalRule.test(projectile)) {
                projectiles.removeIndex(i);
            }
        }
    }
}
