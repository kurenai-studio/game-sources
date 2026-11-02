package com.bossfight.boss;

import com.bossfight.entities.Player;

final class IdleState implements BossState {
    private final float duration;
    private float elapsed;

    IdleState(float duration) {
        this.duration = duration;
    }

    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.IDLE;
    }

    @Override
    public void enter(Boss boss) {
        elapsed = 0f;
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
        elapsed += delta;
        if (elapsed >= duration && !boss.isDefeated()) {
            boss.setState(boss.createNextAttackState());
        }
    }

}
