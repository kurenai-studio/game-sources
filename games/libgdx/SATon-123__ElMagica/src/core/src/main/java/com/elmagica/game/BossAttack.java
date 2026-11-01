package com.elmagica.game;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class BossAttack {
    public static final float WARNING_TIME = 0.65f;
    private static final int WATER_RAY_ANGLE = 16;
    private static final float WATER_HALF_WIDTH = 14;
    private static final float EARTH_HALF_WIDTH = 10;
    private static final float AIR_HALF_SIZE = 12;
    private static final int FIRE_HALF_ANGLE = 45;
    public final ElementType element;
    public final float x;
    public final float y;
    public final float angle;
    public final float range;
    private final float startRadius;
    private float age;
    public final boolean enraged;
    private final float warningTime;
    private final Enemy owner;
    private boolean hit;
    private final boolean[] spiralHits = new boolean[12];

    public BossAttack(ElementType element, Enemy boss, Player player) {
        this.element = element;
        owner = boss;
        enraged = boss.isEnraged();
        warningTime = Math.max(0.3f, (enraged ? 0.5f : WARNING_TIME) / boss.attackRate());
        x = boss.x + boss.getSize() / 2;
        y = boss.y + boss.getSize() / 2;
        angle = MathUtils.atan2(player.y + Player.SIZE / 2 - y, player.x + Player.SIZE / 2 - x)
            * MathUtils.radiansToDegrees;
        startRadius = boss.getSize() / 2;
        if (element == ElementType.EARTH) range = startRadius + MathUtils.random(4, 5) * 64 * boss.rangeScale();
        else if (element == ElementType.FIRE) range = MathUtils.random(5, 6) * 64 * boss.rangeScale();
        else if (element == ElementType.WATER) range = Vector2.len(ElMagicaGame.WORLD_WIDTH, ElMagicaGame.WORLD_HEIGHT);
        else range = 400;
    }

    public BossAttack(ElementType element, Enemy boss, Player player, float delay) {
        this(element, boss, player);
        age = -delay;
    }

    public float getWarningTime() { return warningTime; }
    public float getAngle() {
        if (element == ElementType.FIRE && !isWarning()) {
            float sweep = enraged ? 90 : 60;
            return angle - sweep / 2 + sweep * MathUtils.clamp((age - warningTime) / getDuration(), 0, 1);
        }
        return angle;
    }

    public float getAge() { return age; }
    public boolean isWarning() { return age < warningTime; }
    public float getDuration() {
        if (element == ElementType.EARTH) return 0.75f;
        if (element == ElementType.WATER) return 0.3f;
        if (element == ElementType.FIRE) return 0.85f;
        return 3f;
    }
    public boolean isFinished() { return age >= warningTime + getDuration(); }

    public void update(float delta, Player player) {
        // Дробим длинный кадр, чтобы атака не проскочила сквозь мага.
        while (delta > 0 && !isFinished() && player.isAlive()) {
            float step = Math.min(delta, 1f / 60f);
            float previous = age;
            age = Math.min(age + step, warningTime + getDuration());
            delta -= step;
            if (isWarning()) continue;
            float time = age - warningTime;
            if (element == ElementType.AIR) {
                for (int i = 0; i < spiralHits.length; i++) {
                    if (spiralHits[i]) continue;
                    Vector2 oldPoint = spiral(i, Math.max(0, previous - warningTime));
                    Vector2 point = spiral(i, time);
                    if (lineHitsPlayer(oldPoint.x, oldPoint.y, point.x, point.y, AIR_HALF_SIZE, player)) {
                        player.takeDamage(owner.attackDamage(element, player.element), DamageSystem.damageToPlayer(element, player.element));
                        spiralHits[i] = true;
                        if (!player.isAlive()) break;
                    }
                }
            } else if (!hit && hitsPlayer(player, previous)) {
                player.takeDamage(owner.attackDamage(element, player.element), DamageSystem.damageToPlayer(element, player.element));
                hit = true;
            }
        }
    }

    private boolean hitsPlayer(Player player, float previousAge) {
        if (element == ElementType.WATER) {
            // Даже на пересечении струй залп бьёт только раз.
            for (int offset = -WATER_RAY_ANGLE; offset <= WATER_RAY_ANGLE; offset += WATER_RAY_ANGLE) {
                if (lineHitsPlayer(x, y, x + MathUtils.cosDeg(getAngle() + offset) * range,
                    y + MathUtils.sinDeg(getAngle() + offset) * range, WATER_HALF_WIDTH, player)) return true;
            }
            return false;
        }
        if (element == ElementType.FIRE) {
            // Проверяем весь поворачивающийся конус лучами.
            for (int offset = -FIRE_HALF_ANGLE; offset <= FIRE_HALF_ANGLE; offset += 3) {
                if (lineHitsPlayer(x, y, x + MathUtils.cosDeg(getAngle() + offset) * range,
                    y + MathUtils.sinDeg(getAngle() + offset) * range, 0, player)) return true;
            }
            return false;
        }
        float radius = earthRadius(age - warningTime);
        float oldRadius = earthRadius(Math.max(0, previousAge - warningTime));
        float distance = Vector2.dst(x, y, player.hurtX(), player.hurtY());
        float nearest = Math.max(0, distance - Player.HURT_RADIUS);
        float farthest = distance + Player.HURT_RADIUS;
        return nearest <= radius + EARTH_HALF_WIDTH && farthest >= oldRadius - EARTH_HALF_WIDTH;
    }

    private float earthRadius(float time) {
        return startRadius + (range - startRadius) * MathUtils.clamp(time / getDuration(), 0, 1);
    }

    private Vector2 spiral(int index, float time) {
        float radius = startRadius + 18 + time * (enraged ? 250 : 210) * owner.speedScale();
        float spin = index % 2 == 1 ? -1 : 1;
        float turn = angle + index * 30 + time * 110 * spin;
        return new Vector2(x + MathUtils.cosDeg(turn) * radius, y + MathUtils.sinDeg(turn) * radius);
    }

    private boolean lineHitsPlayer(float fromX, float fromY, float toX, float toY, float padding, Player player) {
        // Учитываем толщину струи вокруг круглого хитбокса мага.
        return Float.isFinite(player.hitTime(fromX, fromY, toX, toY, padding));
    }

    public void draw(ShapeRenderer shapes) {
        float time = Math.max(0, age - warningTime);
        float alpha = isWarning() ? 0.2f : 0.8f;
        shapes.setColor(element.color.r, element.color.g, element.color.b, alpha);
        if (element == ElementType.EARTH) {
            float radius = isWarning() ? range : earthRadius(time);
            ring(shapes, radius, isWarning() ? 3 : EARTH_HALF_WIDTH * 2);
            if (!isWarning()) {
                shapes.setColor(1, 0.86f, 0.55f, 0.95f);
                ring(shapes, radius, 3);
                // Камни показывают край волны, который наносит урон.
                for (int i = 0; i < 48; i++) {
                    float turn = i * 7.5f;
                    float stone = radius + MathUtils.sin(age * 24 + i * 3) * 5;
                    float size = i % 3 == 0 ? 7 : 4;
                    shapes.setColor(i % 2 == 0 ? 0.55f : 0.9f, 0.48f, 0.25f, 0.95f);
                    shapes.rect(x + MathUtils.cosDeg(turn) * stone - size / 2,
                        y + MathUtils.sinDeg(turn) * stone - size / 2, size, size);
                }
            }
        } else if (element == ElementType.WATER) {
            for (int offset = -WATER_RAY_ANGLE; offset <= WATER_RAY_ANGLE; offset += WATER_RAY_ANGLE) {
                float endX = x + MathUtils.cosDeg(getAngle() + offset) * range;
                float endY = y + MathUtils.sinDeg(getAngle() + offset) * range;
                shapes.setColor(element.color.r, element.color.g, element.color.b, alpha);
                shapes.rectLine(x, y, endX, endY, WATER_HALF_WIDTH * 2);
                if (!isWarning()) {
                    shapes.setColor(0.45f, 0.9f, 1, 0.85f);
                    shapes.rectLine(x, y, endX, endY, 18);
                    float dx = MathUtils.cosDeg(getAngle() + offset), dy = MathUtils.sinDeg(getAngle() + offset);
                    for (float distance = 20; distance < range - 24; distance += 48) {
                        float front = Math.min(range - 20, distance + time * 420 % 48);
                        float side = MathUtils.sin(distance * 0.06f + age * 20) * 7;
                        shapes.setColor(0.85f, 0.98f, 1, 0.95f);
                        shapes.rectLine(x + dx * front - dy * side, y + dy * front + dx * side,
                            x + dx * (front + 20) - dy * side, y + dy * (front + 20) + dx * side, 3);
                    }
                }
            }
        } else if (element == ElementType.FIRE) {
            int half = isWarning() ? (enraged ? 90 : 75) : FIRE_HALF_ANGLE;
            for (int i = -half; i < half; i += 3) {
                shapes.triangle(x, y, x + MathUtils.cosDeg(getAngle() + i) * range,
                    y + MathUtils.sinDeg(getAngle() + i) * range,
                    x + MathUtils.cosDeg(getAngle() + i + 3) * range,
                    y + MathUtils.sinDeg(getAngle() + i + 3) * range);
            }
            shapes.setColor(1, 0.65f, 0.2f, isWarning() ? 0.5f : 1);
            for (int i = -half; i <= half; i += half * 2) {
                shapes.rectLine(x, y, x + MathUtils.cosDeg(getAngle() + i) * range,
                    y + MathUtils.sinDeg(getAngle() + i) * range, 3);
            }
            if (!isWarning()) {
                // Пламя держим внутри хитбокса, дугой показываем дальность.
                shapes.setColor(1, 0.85f, 0.35f, 0.7f);
                SpellVisuals.ring(shapes, x, y, range, 3, getAngle() - half, half * 2);
                for (int i = 0; i < 42; i++) {
                    float turn = getAngle() - 40 + i % 9 * 10;
                    float progress = (time * 1.8f + i * 0.137f) % 1;
                    float distance = startRadius + (range - startRadius - 18) * progress;
                    float size = 4 + progress * 8;
                    float flameX = x + MathUtils.cosDeg(turn) * distance;
                    float flameY = y + MathUtils.sinDeg(turn) * distance;
                    shapes.setColor(1, 0.35f + (1 - progress) * 0.5f, 0.12f, 0.9f);
                    shapes.rect(flameX - size / 2, flameY - size / 2, size, size);
                    shapes.setColor(1, 0.93f, 0.6f, 0.9f);
                    shapes.rect(flameX - size / 4, flameY - size / 4, size / 2, size / 2);
                }
            }
        } else {
            for (int i = 0; i < spiralHits.length; i++) {
                if (spiralHits[i]) continue;
                Vector2 point = spiral(i, time);
                if (isWarning()) {
                    shapes.rectLine(x, y, point.x, point.y, 2);
                } else {
                    for (int trail = 6; trail > 0; trail--) {
                        Vector2 tail = spiral(i, Math.max(0, time - trail * 0.025f));
                        shapes.setColor(0.7f, 0.9f, 1, (7 - trail) * 0.05f);
                        shapes.rect(tail.x - 3, tail.y - 3, 6, 6);
                    }
                    shapes.setColor(0.35f, 0.65f, 0.8f, 0.4f);
                    shapes.rect(point.x - AIR_HALF_SIZE, point.y - AIR_HALF_SIZE, AIR_HALF_SIZE * 2, AIR_HALF_SIZE * 2);
                }
                shapes.setColor(0.8f, 0.95f, 1, isWarning() ? 0.3f : 0.95f);
                float lastX = point.x, lastY = point.y;
                for (int segment = 1; segment <= 16; segment++) {
                    float turn = segment * 35 + age * 280;
                    float radius = segment * (AIR_HALF_SIZE - 2) / 16;
                    float nextX = point.x + MathUtils.cosDeg(turn) * radius;
                    float nextY = point.y + MathUtils.sinDeg(turn) * radius;
                    shapes.rectLine(lastX, lastY, nextX, nextY, 3);
                    lastX = nextX;
                    lastY = nextY;
                }
            }
        }
    }

    private void ring(ShapeRenderer shapes, float radius, float width) {
        for (int i = 0; i < 64; i++) {
            float first = i * 360f / 64;
            float second = (i + 1) * 360f / 64;
            shapes.rectLine(x + MathUtils.cosDeg(first) * radius, y + MathUtils.sinDeg(first) * radius,
                x + MathUtils.cosDeg(second) * radius, y + MathUtils.sinDeg(second) * radius, width);
        }
    }
}
