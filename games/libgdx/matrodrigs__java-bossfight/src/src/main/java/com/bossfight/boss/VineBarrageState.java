package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;
import com.bossfight.entities.Projectile;

import java.util.OptionalDouble;

final class VineBarrageState implements BossState {
    private static final int LANE_COUNT = 8;
    private static final int TOTAL_VINES = 8;
    private static final int MAX_PENDING_VINES = 3;
    private static final int MAX_SPORES = 8;
    private static final float FIRST_VINE_DELAY = 0.12f;
    private static final float VINE_INTERVAL = 0.28f;
    private static final float VINE_WARNING_TIME = 0.62f;
    private static final float VINE_ACTIVE_TIME = 0.36f;
    private static final float VINE_WIDTH = 52f;
    private static final float VINE_HEIGHT = 292f;
    private static final float WARNING_WIDTH = 78f;
    private static final float SPORE_INTERVAL = 0.34f;
    private static final float MIN_SPORE_DISTANCE_FROM_VINE = 100f;
    private static final float MIN_DURATION = 2.85f;

    private final PendingTelegraphs pendingVines = new PendingTelegraphs(MAX_PENDING_VINES);
    private float elapsed;
    private float vineTimer;
    private float sporeTimer;
    private int vinesQueued;
    private int sporesSpawned;
    private int lastLane;

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.VINE_STRIKE;
    }

    @Override
    public void enter(Boss boss) {
        elapsed = 0f;
        vineTimer = FIRST_VINE_DELAY;
        sporeTimer = 0.16f;
        pendingVines.clear();
        vinesQueued = 0;
        sporesSpawned = 0;
        lastLane = -1;
        boss.emitSound(BossSoundEvent.VINE_CHARGE);
        boss.showTelegraph(new Color(0.48f, 1f, 0.18f, 1f), VINE_WARNING_TIME);
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        elapsed += delta;
        vineTimer -= delta;
        sporeTimer -= delta;

        updatePendingVines(boss, delta, projectileSpawner);

        if (vineTimer <= 0f && vinesQueued < TOTAL_VINES && !pendingVines.isFull()) {
            queueVineWarning(boss, projectileSpawner, player);
            vinesQueued++;
            vineTimer = VINE_INTERVAL;
        }

        if (sporeTimer <= 0f && sporesSpawned < MAX_SPORES) {
            spawnSpore(projectileSpawner);
            sporesSpawned++;
            sporeTimer = SPORE_INTERVAL;
        }

        if (vinesQueued >= TOTAL_VINES && pendingVines.isEmpty() && elapsed >= MIN_DURATION) {
            boss.finishCurrentAttack();
        }
    }

    private void updatePendingVines(Boss boss, float delta, ProjectileSpawner projectileSpawner) {
        pendingVines.update(delta);
        OptionalDouble expiredPosition = pendingVines.pollExpiredPosition();
        while (expiredPosition.isPresent()) {
            spawnVine(boss, projectileSpawner, (float) expiredPosition.getAsDouble());
            expiredPosition = pendingVines.pollExpiredPosition();
        }
    }

    private void queueVineWarning(Boss boss, ProjectileSpawner projectileSpawner, Player player) {
        int lane = chooseLane(player);
        float x = laneCenterX(lane);

        pendingVines.add(x, VINE_WARNING_TIME);
        boss.showTelegraph(new Color(0.48f, 1f, 0.18f, 1f), VINE_WARNING_TIME);

        projectileSpawner.addProjectile(Projectile.bossVineWarning(
                x - WARNING_WIDTH * 0.5f,
                Constants.FLOOR_Y,
                WARNING_WIDTH,
                VINE_HEIGHT,
                VINE_WARNING_TIME
        ));
    }

    private int chooseLane(Player player) {
        int playerLane = laneFor(player.getCenterX());
        int lane = vinesQueued % 3 == 0
                ? playerLane
                : MathUtils.random(LANE_COUNT - 1);

        if (lane == lastLane) {
            lane = lane == LANE_COUNT - 1 ? lane - 1 : lane + 1;
        }

        lastLane = lane;
        return lane;
    }

    private int laneFor(float x) {
        float laneWidth = arenaWidth() / LANE_COUNT;
        return MathUtils.clamp((int) ((x - Constants.ARENA_LEFT) / laneWidth), 0, LANE_COUNT - 1);
    }

    private float laneCenterX(int lane) {
        float laneWidth = arenaWidth() / LANE_COUNT;
        float jitter = MathUtils.random(-laneWidth * 0.18f, laneWidth * 0.18f);
        return MathUtils.clamp(
                Constants.ARENA_LEFT + laneWidth * (lane + 0.5f) + jitter,
                Constants.ARENA_LEFT + VINE_WIDTH * 0.5f,
                Constants.ARENA_RIGHT - VINE_WIDTH * 0.5f
        );
    }

    private float arenaWidth() {
        return Constants.ARENA_RIGHT - Constants.ARENA_LEFT;
    }

    private void spawnVine(Boss boss, ProjectileSpawner projectileSpawner, float centerX) {
        boss.emitSound(BossSoundEvent.VINE_STRIKE);
        projectileSpawner.addProjectile(Projectile.bossThorn(
                centerX - VINE_WIDTH * 0.5f,
                Constants.FLOOR_Y,
                VINE_WIDTH,
                VINE_HEIGHT,
                VINE_ACTIVE_TIME
        ));
    }

    private void spawnSpore(ProjectileSpawner projectileSpawner) {
        float width = Constants.BOSS_PROJECTILE_WIDTH + 12f;
        float height = Constants.BOSS_PROJECTILE_HEIGHT + 12f;
        float centerX = chooseSporeX();

        projectileSpawner.addProjectile(Projectile.bossPollen(
                centerX - width * 0.5f,
                Constants.WORLD_HEIGHT + 28f,
                width,
                height,
                MathUtils.random(-72f, 72f),
                -380f,
                0f
        ));
    }

    private float chooseSporeX() {
        float x = MathUtils.random(Constants.ARENA_LEFT + 32f, Constants.ARENA_RIGHT - 32f);

        for (int attempt = 0; attempt < 4 && isNearPendingVine(x); attempt++) {
            x = MathUtils.random(Constants.ARENA_LEFT + 32f, Constants.ARENA_RIGHT - 32f);
        }

        return x;
    }

    private boolean isNearPendingVine(float x) {
        return pendingVines.hasPositionWithin(x, MIN_SPORE_DISTANCE_FROM_VINE);
    }
}
