package com.veilfall.game.enemies;

import com.veilfall.game.player.Player;

public final class EnemyAI {
    public void update(Enemy enemy, Player player, float delta) {
        enemy.updateTimers(delta);
        if (!enemy.isAlive() || enemy.isKnockedBack() || player.isDead()) return;

        float dx = player.getX() - enemy.getX();
        float dz = player.getZ() - enemy.getZ();
        float distance = (float) Math.sqrt(dx * dx + dz * dz);
        if (enemy.getData().isBoss()) {
            enemy.updateBossCombat(player, distance, delta);
            if (!enemy.isBossTelegraphing() && distance > enemy.getData().getRange() + 1.6f) {
                enemy.moveToward(player.getX(), player.getZ(), delta);
            }
            return;
        }
        if (distance <= enemy.getData().getRange()) {
            enemy.attack(player);
        } else {
            enemy.moveToward(player.getX(), player.getZ(), delta);
        }
    }
}
