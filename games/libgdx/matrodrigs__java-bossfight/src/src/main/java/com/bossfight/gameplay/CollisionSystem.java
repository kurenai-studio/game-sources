package com.bossfight.gameplay;

import com.bossfight.boss.Boss;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;
import com.bossfight.entities.Projectile;

public class CollisionSystem {
    private static final float BASIC_BOSS_HIT_SHAKE = 0.75f;
    private static final float SPECIAL_BOSS_HIT_SHAKE = 5f;

    public interface Feedback {
        void onBossHit(float x, float y, boolean special, boolean defeated);

        void onPlayerHit(float x, float y);
    }

    private final Feedback feedback;
    private float bossContactCooldown;
    private float requestedHitstop;
    private float requestedShake;

    public CollisionSystem(Feedback feedback) {
        this.feedback = feedback;
    }

    public void resolve(Player player, Boss boss, ProjectileSystem projectileSystem, float delta) {
        requestedHitstop = 0f;
        requestedShake = 0f;
        bossContactCooldown = Math.max(0f, bossContactCooldown - delta);
        resolvePlayerProjectiles(player, boss, projectileSystem);
        resolveBossProjectiles(player, boss, projectileSystem);
        resolveBossContact(player, boss);
    }

    public float consumeRequestedHitstop() {
        float value = requestedHitstop;
        requestedHitstop = 0f;
        return value;
    }

    public float consumeRequestedShake() {
        float value = requestedShake;
        requestedShake = 0f;
        return value;
    }

    private void resolvePlayerProjectiles(Player player, Boss boss, ProjectileSystem projectileSystem) {
        projectileSystem.removePlayerProjectilesIf(projectile -> {
            if (!boss.isDefeated() && projectile.getHitbox().overlaps(boss.getHitbox())) {
                boolean special = projectile.isSpecial();
                boolean hit = boss.takeDamage(projectile.getDamage(), special);
                if (hit) {
                    feedback.onBossHit(projectile.getCenterX(), projectile.getCenterY(), special, boss.isDefeated());
                    player.addSpecialEnergy(special ? 0f : Constants.PLAYER_SPECIAL_HIT_CHARGE);
                    if (special) {
                        requestedHitstop = Math.max(requestedHitstop, 0.08f);
                    }
                    requestedShake = Math.max(requestedShake,
                            special ? SPECIAL_BOSS_HIT_SHAKE : BASIC_BOSS_HIT_SHAKE);
                }
                return true;
            }
            return false;
        });
    }

    private void resolveBossProjectiles(Player player, Boss boss, ProjectileSystem projectileSystem) {
        projectileSystem.removeBossProjectilesIf(projectile -> {
            if (player.isInvulnerableAfterHit()) {
                return false;
            }

            if (projectile.getDamage() > 0 && projectile.getHitbox().overlaps(player.getHitbox())) {
                boolean damaged = player.takeDamage(projectile.getDamage(), boss.getCenterX());
                if (damaged) {
                    feedback.onPlayerHit(player.getCenterX(), player.getCenterY());
                    requestedHitstop = Math.max(requestedHitstop, 0.07f);
                    requestedShake = Math.max(requestedShake, 8f);
                }
                return projectile.shouldRemoveOnHit();
            }
            return false;
        });
    }

    private void resolveBossContact(Player player, Boss boss) {
        if (boss.isDefeated() || bossContactCooldown > 0f) {
            return;
        }

        if (player.getHitbox().overlaps(boss.getHitbox())) {
            boolean damaged = player.takeDamage(1, boss.getCenterX());
            if (damaged) {
                feedback.onPlayerHit(player.getCenterX(), player.getCenterY());
                requestedHitstop = Math.max(requestedHitstop, 0.07f);
                requestedShake = Math.max(requestedShake, 8f);
                bossContactCooldown = 0.8f;
            }
        }
    }
}
