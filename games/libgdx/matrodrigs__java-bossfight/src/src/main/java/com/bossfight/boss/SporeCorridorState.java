package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;
import com.bossfight.entities.Projectile;

final class SporeCorridorState implements BossState {
    private static final int TOTAL_CORRIDOR_SPORES = 7;
    private static final int MAX_REPEATED_LANES = 2;
    private static final float FIRST_SPORE_DELAY = 0.32f;
    private static final float MIN_SPORE_INTERVAL = 0.34f;
    private static final float MAX_SPORE_INTERVAL = 0.44f;
    private static final float LOW_TO_HIGH_INTERVAL = 0.80f;
    private static final float LAST_SPORE_ANIMATION_HOLD = 0.85f;
    private static final float SPORE_SPEED = 690f;
    private static final float SPORE_WIDTH = Constants.BOSS_PROJECTILE_WIDTH + 32f;
    private static final float SPORE_HEIGHT = Constants.BOSS_PROJECTILE_HEIGHT + 28f;
    private static final float LOW_LANE_Y = Constants.FLOOR_Y + 3f;
    private static final float HIGH_LANE_Y = Constants.FLOOR_Y + Constants.PLAYER_HEIGHT + 42f;

    private float puffTimer;
    private float finishTimer;
    private int puffsSpawned;
    private int repeatedLanes;
    private SporeLane nextLane;

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.POLLEN_BREATH;
    }

    @Override
    public void enter(Boss boss) {
        puffTimer = FIRST_SPORE_DELAY;
        finishTimer = -1f;
        puffsSpawned = 0;
        repeatedLanes = 1;
        nextLane = randomLane();
        boss.emitSound(BossSoundEvent.POLLEN_CHARGE);
        boss.showTelegraph(new Color(0.74f, 0.32f, 1f, 1f), 0.58f);
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        puffTimer -= delta;

        if (puffTimer <= 0f && puffsSpawned < TOTAL_CORRIDOR_SPORES) {
            SporeLane spawnedLane = nextLane;
            spawnCorridorSpore(boss, projectileSpawner, spawnedLane);
            puffsSpawned++;
            boss.emitSound(BossSoundEvent.POLLEN_DROP);

            if (puffsSpawned == TOTAL_CORRIDOR_SPORES) {
                finishTimer = LAST_SPORE_ANIMATION_HOLD;
            } else {
                nextLane = chooseNextLane(spawnedLane);
                puffTimer = intervalBetween(spawnedLane, nextLane);
            }
        }

        if (finishTimer > 0f) {
            finishTimer -= delta;
        }

        if (finishTimer <= 0f && puffsSpawned == TOTAL_CORRIDOR_SPORES) {
            boss.finishCurrentAttack(VineStrikeState.chainedStrike());
        }
    }

    private void spawnCorridorSpore(Boss boss, ProjectileSpawner projectileSpawner, SporeLane lane) {
        float centerX = boss.getCenterX() - Constants.BOSS_WIDTH * 0.82f;
        float y = lane == SporeLane.LOW ? LOW_LANE_Y : HIGH_LANE_Y;

        projectileSpawner.addProjectile(Projectile.bossPollen(
                centerX - SPORE_WIDTH * 0.5f,
                y,
                SPORE_WIDTH,
                SPORE_HEIGHT,
                -SPORE_SPEED,
                0f,
                0f
        ));
    }

    private SporeLane chooseNextLane(SporeLane currentLane) {
        SporeLane candidate = randomLane();

        if (candidate == currentLane && repeatedLanes >= MAX_REPEATED_LANES) {
            candidate = currentLane.opposite();
        }

        repeatedLanes = candidate == currentLane ? repeatedLanes + 1 : 1;
        return candidate;
    }

    private float intervalBetween(SporeLane currentLane, SporeLane followingLane) {
        if (currentLane == SporeLane.LOW && followingLane == SporeLane.HIGH) {
            return LOW_TO_HIGH_INTERVAL;
        }

        return MathUtils.random(MIN_SPORE_INTERVAL, MAX_SPORE_INTERVAL);
    }

    private SporeLane randomLane() {
        return MathUtils.randomBoolean() ? SporeLane.LOW : SporeLane.HIGH;
    }

    private enum SporeLane {
        LOW,
        HIGH;

        private SporeLane opposite() {
            return this == LOW ? HIGH : LOW;
        }
    }
}
