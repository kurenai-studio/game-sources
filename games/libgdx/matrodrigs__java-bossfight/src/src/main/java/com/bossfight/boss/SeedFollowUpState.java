package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;
import com.bossfight.entities.Projectile;

final class SeedFollowUpState implements BossState {
    private static final float WARNING_TIME = 0.46f;
    private static final float RECOVERY_TIME = 0.48f;
    private static final float SEED_SPEED = 470f;
    private static final float SEED_SPREAD = 0.13f;

    private float timer;
    private boolean fired;

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.MAGIC_HANDS;
    }

    @Override
    public void enter(Boss boss) {
        timer = WARNING_TIME;
        fired = false;
        boss.emitSound(BossSoundEvent.CHAIN_WARNING);
        boss.showTelegraph(new Color(0.92f, 0.34f, 1f, 1f), WARNING_TIME);
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        timer -= delta;
        if (!fired && timer <= 0f) {
            fireSeeds(boss, projectileSpawner, player);
            fired = true;
            timer = RECOVERY_TIME;
        } else if (fired && timer <= 0f) {
            boss.finishCurrentAttack();
        }
    }

    private void fireSeeds(Boss boss, ProjectileSpawner projectileSpawner, Player player) {
        float originX = boss.getCenterX() - 126f;
        float originY = Constants.FLOOR_Y + 350f;
        Vector2 direction = new Vector2(
                player.getCenterX() - originX,
                player.getCenterY() - originY).nor();
        float baseAngle = MathUtils.atan2(direction.y, direction.x);

        boss.emitSound(BossSoundEvent.MAGIC_VOLLEY);
        for (int i = 0; i < 2; i++) {
            float spread = i == 0 ? -SEED_SPREAD : SEED_SPREAD;
            float angle = baseAngle + spread;
            projectileSpawner.addProjectile(Projectile.bossSeed(
                    originX,
                    originY,
                    Constants.BOSS_PROJECTILE_WIDTH + 2f,
                    Constants.BOSS_PROJECTILE_HEIGHT + 1f,
                    MathUtils.cos(angle) * SEED_SPEED,
                    MathUtils.sin(angle) * SEED_SPEED,
                    -55f));
        }
    }
}
