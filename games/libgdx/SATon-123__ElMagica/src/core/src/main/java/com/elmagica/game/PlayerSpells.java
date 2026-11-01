package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class PlayerSpells {
    public static final float FIRE_RADIUS = 48;
    public static final float AIR_RANGE = 128;

    // true — снаряд продолжает лететь после попадания.
    public static boolean hit(Projectile shot, Enemy target, Array<Enemy> enemies, CombatSession session, Player player) {
        if (shot.hasHit(target) || !target.isAlive()) return false;
        int limit = player == null ? (shot.element == ElementType.WATER || shot.element == ElementType.AIR ? 2 : 1)
            : player.targetLimit(shot.element);
        if (shot.getHitCount() >= limit) return false;
        shot.markHit(target);
        session.hit(target, shot.element, player);
        if (shot.element == ElementType.FIRE) {
            float x = target.x + target.getSize() / 2;
            float y = target.y + target.getSize() / 2;
            for (Enemy enemy : enemies) {
                if (enemy == target || !enemy.isAlive()) continue;
                float nearX = MathUtils.clamp(x, enemy.x, enemy.x + enemy.getSize());
                float nearY = MathUtils.clamp(y, enemy.y, enemy.y + enemy.getSize());
                boolean visible = player == null || player.room == null
                    || player.room.shotTime(new Vector2(x, y), new Vector2(nearX, nearY), 0) >= 1;
                if (visible && Vector2.dst(x, y, nearX, nearY) <= (player == null ? FIRE_RADIUS : player.explosionRadius)) session.hit(enemy, shot.element, player);
            }
        }
        if (shot.element == ElementType.EARTH && target.isAlive()) {
            if (player == null) target.knockBack(shot.getDirection(), 64);
            else target.knockBack(shot.getDirection(), player.knockback, player.slowStrength, player.slowDuration);
        }
        if (shot.element == ElementType.WATER) return shot.getHitCount() < limit;
        if (shot.element == ElementType.AIR && shot.getHitCount() < limit) {
            Enemy next = null;
            float nearest = AIR_RANGE;
            for (Enemy enemy : enemies) {
                if (!enemy.isAlive() || shot.hasHit(enemy)) continue;
                if (player != null && player.room != null && player.room.shotTime(
                    new Vector2(target.x + target.getSize() / 2, target.y + target.getSize() / 2),
                    new Vector2(enemy.x + enemy.getSize() / 2, enemy.y + enemy.getSize() / 2), Projectile.HALF_SIZE) < 1) continue;
                float distance = Vector2.dst(target.x + target.getSize() / 2, target.y + target.getSize() / 2,
                    enemy.x + enemy.getSize() / 2, enemy.y + enemy.getSize() / 2);
                if (distance <= nearest) {
                    nearest = distance;
                    next = enemy;
                }
            }
            if (next != null) {
                shot.ricochet(target, next);
                return true;
            }
        }
        return false;
    }
}
