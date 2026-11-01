package com.elmagica.game;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class SnakeCombat {
    public static final float APPROACH_SPEED = 100;
    public static final float DASH_SPEED = 560;
    public static final float DASH_DISTANCE = 256;
    public static final float WARNING_TIME = 0.5f;
    public static final float RECOVERY_TIME = 1.2f;
    private final Enemy owner;
    private final Vector2 direction = new Vector2(1, 0);
    private float warning;
    private float remaining;
    private float recovery;
    private boolean charging;
    private boolean dashing;

    public SnakeCombat(Enemy owner) { this.owner = owner; }
    public boolean isCharging() { return charging; }
    public boolean isDashing() { return dashing; }
    public boolean isRecovering() { return recovery > 0; }
    public float getCharge() { return warning / WARNING_TIME; }
    public float getAngle() { return direction.angleDeg(); }

    public void update(float delta, Player player) {
        if (!owner.isAlive() || !player.isAlive()) { clear(); return; }
        if (recovery > 0) {
            recovery = Math.max(0, recovery - delta * owner.attackRate());
            return;
        }
        if (charging) {
            warning += delta;
            if (warning >= WARNING_TIME) {
                charging = false;
                dashing = true;
                remaining = DASH_DISTANCE * owner.rangeScale();
            }
            return;
        }
        if (dashing) {
            float step = Math.min(DASH_SPEED * owner.speedScale() * owner.slowScale() * delta, remaining);
            float oldX = owner.x, oldY = owner.y;
            move(direction.x * step, direction.y * step);
            remaining -= step;
            // Проверяем весь путь рывка, иначе змея проскочит сквозь мага.
            float hit = hitTime(oldX, oldY, owner.x, owner.y, player);
            if (Float.isFinite(hit)) {
                owner.x = oldX + (owner.x - oldX) * hit;
                owner.y = oldY + (owner.y - oldY) * hit;
                player.takeDamage(owner.attackDamage(owner.element, player.element), DamageSystem.damageToPlayer(owner.element, player.element));
                finishDash();
            } else if (remaining <= 0 || Math.abs(owner.x - oldX - direction.x * step) > 0.01f
                || Math.abs(owner.y - oldY - direction.y * step) > 0.01f) {
                finishDash();
            }
            return;
        }
        float dx = player.x + Player.SIZE / 2 - owner.x - owner.getSize() / 2;
        float dy = player.y + Player.SIZE / 2 - owner.y - owner.getSize() / 2;
        float distance = Vector2.len(dx, dy);
        boolean clear = owner.room == null || owner.room.motionTime(owner.x, owner.y, owner.getSize(), dx, dy) >= 1;
        if (distance <= DASH_DISTANCE * owner.rangeScale() && clear) {
            // Направление рывка фиксируем до атаки.
            direction.set(dx, dy).nor();
            if (direction.isZero()) direction.set(1, 0);
            charging = true;
            warning = 0;
        } else {
            if (!clear && owner.room != null) direction.set(owner.room.direction(owner.x, owner.y, owner.getSize(), player));
            else direction.set(dx, dy);
            float speed = APPROACH_SPEED * owner.speedScale() * owner.slowScale();
            float step = Math.min(speed * delta, clear ? distance - DASH_DISTANCE * owner.rangeScale() : direction.len());
            direction.nor();
            move(direction.x * step, direction.y * step);
        }
    }

    private void move(float dx, float dy) {
        if (owner.room != null) {
            if (!dashing) {
                Vector2 position = owner.room.move(owner.x, owner.y, owner.getSize(), dx, dy);
                owner.x = position.x; owner.y = position.y;
                return;
            }
            float time = owner.room.motionTime(owner.x, owner.y, owner.getSize(), dx, dy);
            dx *= time; dy *= time;
        }
        owner.x = MathUtils.clamp(owner.x + dx, 64, ElMagicaGame.WORLD_WIDTH - 64 - owner.getSize());
        owner.y = MathUtils.clamp(owner.y + dy, 64, ElMagicaGame.WORLD_HEIGHT - 64 - owner.getSize());
    }

    private float hitTime(float fromX, float fromY, float toX, float toY, Player player) {
        float half = owner.getSize() / 2;
        return player.hitTime(fromX + half, fromY + half, toX + half, toY + half, half);
    }

    private void finishDash() {
        dashing = false;
        recovery = RECOVERY_TIME;
        remaining = 0;
    }

    public void draw(ShapeRenderer shapes) {
        float x = owner.x + owner.getSize() / 2, y = owner.y + owner.getSize() / 2;
        // Задержку перед рывком оставляем, подсказку не рисуем.
        if (dashing) {
            shapes.setColor(owner.element.color.r, owner.element.color.g, owner.element.color.b, 0.45f);
            for (int i = 1; i <= 3; i++) {
                shapes.circle(x - direction.x * i * 18, y - direction.y * i * 18, 13 - i * 2, 10);
            }
        }
    }

    public void clear() { warning = 0; remaining = 0; recovery = 0; charging = false; dashing = false; }
}
