package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.entities.Player;
import com.bossfight.entities.Projectile;
import com.bossfight.config.Constants;

final class VineStrikeState implements BossState {
    private static final float WARNING_TIME = 0.62f;
    private static final float CHAIN_WARNING_TIME = 0.58f;

    private final int forcedStrikeCount;
    private final boolean chainFollowUp;

    private float currentWarningTime;
    private float warningTimer;
    private float recoveryTimer;
    private boolean upperLane;
    private boolean warningSpawned;
    private boolean fired;
    private int strikesFired;
    private int strikesTotal;

    VineStrikeState() {
        this(0, false);
    }

    private VineStrikeState(int forcedStrikeCount, boolean chainFollowUp) {
        this.forcedStrikeCount = forcedStrikeCount;
        this.chainFollowUp = chainFollowUp;
    }

    static VineStrikeState chainedStrike() {
        return new VineStrikeState(1, true);
    }

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.VINE_STRIKE;
    }

    @Override
    public void enter(Boss boss) {
        strikesFired = 0;
        strikesTotal = forcedStrikeCount > 0 ? forcedStrikeCount : strikeCountFor(boss);
        startStrike(boss, MathUtils.randomBoolean());
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        if (!warningSpawned) {
            warningSpawned = true;
            projectileSpawner.addProjectile(Projectile.bossVineWarning(
                    Constants.ARENA_LEFT,
                    getLaneY(),
                    getThornHitboxWidth(),
                    getLaneHeight(),
                    currentWarningTime
            ));
        }

        if (!fired) {
            warningTimer -= delta;
        }

        if (!fired && warningTimer <= 0f) {
            fired = true;
            strikesFired++;
            recoveryTimer = boss.isPhaseTwo() ? 0.28f : 0.42f;
            boss.emitSound(BossSoundEvent.VINE_STRIKE);
            projectileSpawner.addProjectile(Projectile.bossThorn(
                    Constants.ARENA_LEFT,
                    getLaneY(),
                    getThornHitboxWidth(),
                    getLaneHeight(),
                    boss.isPhaseTwo() ? 0.42f : 0.34f
            ));
        }

        if (fired) {
            recoveryTimer -= delta;
            if (recoveryTimer <= 0f) {
                if (strikesFired < strikesTotal) {
                    startStrike(boss, !upperLane);
                } else {
                    boss.finishCurrentAttack();
                }
            }
        }
    }

    private void startStrike(Boss boss, boolean useUpperLane) {
        upperLane = useUpperLane;
        warningSpawned = false;
        fired = false;
        currentWarningTime = warningTimeFor(boss);
        warningTimer = currentWarningTime;
        recoveryTimer = 0f;
        boss.emitSound(chainFollowUp ? BossSoundEvent.CHAIN_WARNING : BossSoundEvent.VINE_CHARGE);
        Color color = chainFollowUp
                ? new Color(1f, 0.58f, 0.08f, 1f)
                : new Color(1f, 0.16f, 0.08f, 1f);
        boss.showTelegraph(color, warningTimer);
    }

    private float getLaneY() {
        return upperLane ? Constants.FLOOR_Y + 142f : Constants.FLOOR_Y + 8f;
    }

    private int strikeCountFor(Boss boss) {
        if (boss.isFinalRage()) {
            return 4;
        }
        return boss.isPhaseTwo() ? 3 : 1;
    }

    private float warningTimeFor(Boss boss) {
        if (chainFollowUp) {
            return CHAIN_WARNING_TIME;
        }
        if (boss.isFinalRage()) {
            return 0.48f;
        }
        return boss.isPhaseTwo() ? 0.52f : WARNING_TIME;
    }

    private float getLaneHeight() {
        return upperLane ? 54f : 50f;
    }

    private float getThornHitboxWidth() {
        return Constants.BOSS_START_X - Constants.ARENA_LEFT + 62f;
    }
}
