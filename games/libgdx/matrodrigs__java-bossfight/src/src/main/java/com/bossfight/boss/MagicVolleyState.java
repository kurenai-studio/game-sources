package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.bossfight.entities.Player;
import com.bossfight.entities.Projectile;
import com.bossfight.config.Constants;

final class MagicVolleyState implements BossState {
    private static final float PHASE_ONE_INITIAL_WARNING = 0.58f;
    private static final float PHASE_TWO_INITIAL_WARNING = 0.70f;
    private static final float PHASE_ONE_VOLLEY_INTERVAL = 0.52f;
    private static final float PHASE_TWO_VOLLEY_INTERVAL = 0.48f;
    private static final float PHASE_ONE_PROJECTILE_SPEED = 430f;
    private static final float PHASE_TWO_PROJECTILE_SPEED = 450f;
    private static final float PHASE_ONE_SPREAD = 0.16f;
    private static final float PHASE_TWO_MIN_SPREAD = 0.18f;
    private static final float PHASE_TWO_MAX_SPREAD = 0.42f;
    private static final float OBSTACLE_TRAVEL_TIME = 1.25f;
    private static final float OBSTACLE_WARNING_WIDTH = 48f;
    private static final float OBSTACLE_PLAYER_OFFSET = 190f;
    private static final float OBSTACLE_ARENA_MARGIN = 70f;
    private static final float OBSTACLE_BOSS_CLEARANCE = 170f;

    private float elapsed;
    private float burstTimer;
    private int volleys;
    private boolean fanOpens;

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.MAGIC_HANDS;
    }

    @Override
    public void enter(Boss boss) {
        elapsed = 0f;
        burstTimer = boss.isPhaseTwo() ? PHASE_TWO_INITIAL_WARNING : PHASE_ONE_INITIAL_WARNING;
        volleys = 0;
        fanOpens = MathUtils.randomBoolean();
        boss.emitSound(BossSoundEvent.MAGIC_CHARGE);
        boss.showTelegraph(new Color(0.96f, 0.74f, 0.18f, 1f), burstTimer);
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        elapsed += delta;
        burstTimer -= delta;

        if (burstTimer <= 0f) {
            boss.emitSound(BossSoundEvent.MAGIC_VOLLEY);
            fireVolley(boss, projectileSpawner, player);
            volleys++;
            burstTimer = boss.isPhaseTwo() ? PHASE_TWO_VOLLEY_INTERVAL : PHASE_ONE_VOLLEY_INTERVAL;
            boss.showTelegraph(new Color(0.96f, 0.74f, 0.18f, 1f), Math.min(0.32f, burstTimer));
        }

        int maxVolleys = boss.isPhaseTwo() ? 5 : 4;
        if (volleys >= maxVolleys && elapsed >= (boss.isPhaseTwo() ? 2.70f : 2.55f)) {
            boss.finishCurrentAttack();
        }
    }

    private void fireVolley(Boss boss, ProjectileSpawner projectileSpawner, Player player) {
        int projectileCount = boss.isPhaseTwo() && volleys == 2 ? 3 : 2;
        float speed = boss.isPhaseTwo() ? PHASE_TWO_PROJECTILE_SPEED : PHASE_ONE_PROJECTILE_SPEED;
        float originX = boss.getCenterX() - 126f;
        float originY = Constants.FLOOR_Y + (boss.isPhaseTwo() ? 392f : 372f);
        Vector2 baseDirection = new Vector2(
                player.getCenterX() - originX,
                player.getCenterY() - originY
        ).nor();

        for (int i = 0; i < projectileCount; i++) {
            float spreadStep = boss.isPhaseTwo() ? phaseTwoSpread() : PHASE_ONE_SPREAD;
            float spread = (i - (projectileCount - 1) * 0.5f)
                    * spreadStep;
            float angle = (float) Math.atan2(baseDirection.y, baseDirection.x)
                    + spread + MathUtils.random(-0.04f, 0.04f);
            Projectile.Kind kind = i % 2 == 0 ? Projectile.Kind.BOSS_ACORN : Projectile.Kind.BOSS_SEED;
            float sizeBonus = kind == Projectile.Kind.BOSS_ACORN ? 6f : 2f;
            float width = Constants.BOSS_PROJECTILE_WIDTH + sizeBonus;
            float height = Constants.BOSS_PROJECTILE_HEIGHT + sizeBonus * 0.45f;
            float velocityX = MathUtils.cos(angle) * speed;
            float velocityY = MathUtils.sin(angle) * speed;
            if (kind == Projectile.Kind.BOSS_ACORN) {
                projectileSpawner.addProjectile(Projectile.bossAcorn(
                        originX - width * 0.5f,
                        originY - height * 0.5f,
                        width,
                        height,
                        velocityX,
                        velocityY,
                        -70f
                ));
            } else {
                projectileSpawner.addProjectile(Projectile.bossSeed(
                        originX - width * 0.5f,
                        originY - height * 0.5f,
                        width,
                        height,
                        velocityX,
                        velocityY,
                        -70f
                ));
            }
        }

        if (boss.isPhaseTwo() && volleys == 2) {
            fireArcingAcorn(boss, projectileSpawner, player);
        }
    }

    private float phaseTwoSpread() {
        float progress = MathUtils.clamp(volleys / 4f, 0f, 1f);
        if (!fanOpens) {
            progress = 1f - progress;
        }
        return MathUtils.lerp(PHASE_TWO_MIN_SPREAD, PHASE_TWO_MAX_SPREAD, progress);
    }

    private void fireArcingAcorn(Boss boss, ProjectileSpawner projectileSpawner, Player player) {
        float originX = boss.getCenterX() - 112f;
        float originY = Constants.FLOOR_Y + 346f;
        float landingX = obstacleLandingX(boss, player);

        projectileSpawner.addProjectile(Projectile.bossImpactWarning(
                landingX - OBSTACLE_WARNING_WIDTH * 0.5f,
                Constants.FLOOR_Y,
                OBSTACLE_WARNING_WIDTH,
                Constants.WORLD_HEIGHT - Constants.FLOOR_Y,
                OBSTACLE_TRAVEL_TIME
        ));
        projectileSpawner.addProjectile(Projectile.bossAcornObstacle(
                originX,
                originY,
                landingX,
                OBSTACLE_TRAVEL_TIME
        ));
    }

    private float obstacleLandingX(Boss boss, Player player) {
        float arenaCenter = (Constants.ARENA_LEFT + Constants.ARENA_RIGHT) * 0.5f;
        float offset = player.getCenterX() < arenaCenter ? OBSTACLE_PLAYER_OFFSET : -OBSTACLE_PLAYER_OFFSET;
        return MathUtils.clamp(
                player.getCenterX() + offset,
                Constants.ARENA_LEFT + OBSTACLE_ARENA_MARGIN,
                boss.getCenterX() - OBSTACLE_BOSS_CLEARANCE);
    }
}
