package com.bossfight.boss;

import com.bossfight.entities.Player;

final class DefeatedState implements BossState {
    @Override
    public BossVisualState getVisualState() {
        return BossVisualState.DEFEATED;
    }

    @Override
    public void update(Boss boss, float delta, ProjectileSpawner projectileSpawner, Player player) {
    }

}
