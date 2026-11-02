package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.bossfight.entities.Player;

final class FinalRageState implements BossState {
    private static final float DURATION = 0.82f;
    private static final float[] SHOCKWAVE_TIMES = {0.22f, 0.54f};

    private float elapsed;
    private int shockwavesPlayed;

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.ENRAGING;
    }

    @Override
    public boolean isInvulnerable() {
        return true;
    }

    @Override
    public void enter(Boss boss) {
        elapsed = 0f;
        shockwavesPlayed = 0;
        boss.emitSound(BossSoundEvent.FINAL_RAGE);
        boss.showTelegraph(new Color(1f, 0.08f, 0.02f, 1f), DURATION);
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        elapsed += delta;

        while (shockwavesPlayed < SHOCKWAVE_TIMES.length && elapsed >= SHOCKWAVE_TIMES[shockwavesPlayed]) {
            shockwavesPlayed++;
            boss.emitSound(BossSoundEvent.PHASE_SHOCKWAVE);
        }

        if (elapsed >= DURATION) {
            boss.finishCurrentAttack();
        }
    }
}
