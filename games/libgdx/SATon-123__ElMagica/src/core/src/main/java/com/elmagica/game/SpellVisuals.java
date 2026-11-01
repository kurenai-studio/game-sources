package com.elmagica.game;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class SpellVisuals {
    public static void projectile(ShapeRenderer shapes, Projectile shot, boolean hostile) {
        Vector2 direction = shot.getDirection();
        float x = shot.position.x, y = shot.position.y, size = Projectile.HALF_SIZE;
        float time = shot.getAge();
        // Хвост для красоты, попадание считаем по плотному ядру.
        for (int i = 5; i > 0; i--) {
            float distance = i * 5;
            float wave = MathUtils.sin(time * 18 - i) * (shot.element == ElementType.WATER ? 2 : 1);
            shapes.setColor(shot.element.color.r, shot.element.color.g, shot.element.color.b, (6 - i) * 0.1f);
            float width = size * (1 - i / 7f);
            shapes.rect(x - direction.x * distance - direction.y * wave - width,
                y - direction.y * distance + direction.x * wave - width, width * 2, width * 2);
        }
        shapes.setColor(shot.element.color);
        shapes.rect(x - size, y - size, size * 2, size * 2);
        shapes.setColor(hostile ? 1 : 0.9f, hostile ? 0.55f : 0.95f, hostile ? 0.55f : 1, 1);
        if (shot.element == ElementType.EARTH) {
            shapes.rect(x - 3, y - 3, 6, 6);
            shapes.setColor(0.25f, 0.16f, 0.08f, 1);
            shapes.rect(x - 4, y - 1, 5, 2);
        } else if (shot.element == ElementType.AIR) {
            ring(shapes, x, y, 3.5f, 1.5f, time * 360, 270);
        } else {
            shapes.rectLine(x - direction.x * 3, y - direction.y * 3,
                x + direction.x * 3, y + direction.y * 3, 3);
        }
    }
    public static void cast(ShapeRenderer shapes, ElementType element, float x, float y, float angle, float timer) {
        if (timer <= 0) return;
        float progress = 1 - timer / Player.CAST_TIME;
        float strength = 1 - progress;
        // Вспышка только после выстрела и в его сторону.
        float tipX = x + MathUtils.cosDeg(angle) * 25, tipY = y + MathUtils.sinDeg(angle) * 25;
        shapes.setColor(element.color.r, element.color.g, element.color.b, strength);
        ring(shapes, tipX, tipY, 8 + progress * 15, 2, angle + progress * 120, 300);
        for (int i = -1; i <= 1; i++) {
            float turn = angle + i * 25;
            float start = 12 + progress * 16;
            shapes.rectLine(x + MathUtils.cosDeg(turn) * start, y + MathUtils.sinDeg(turn) * start,
                x + MathUtils.cosDeg(turn) * (start + 8 * strength), y + MathUtils.sinDeg(turn) * (start + 8 * strength), 3);
        }
        shapes.setColor(1, 0.95f, 0.8f, strength);
        shapes.rect(tipX - 3 * strength, tipY - 3 * strength, 6 * strength, 6 * strength);
    }
    public static void ring(ShapeRenderer shapes, float x, float y, float radius, float width, float angle, float arc) {
        for (int i = 0; i < 32; i++) {
            float first = angle + i * arc / 32, next = angle + (i + 1) * arc / 32;
            shapes.rectLine(x + MathUtils.cosDeg(first) * radius, y + MathUtils.sinDeg(first) * radius,
                x + MathUtils.cosDeg(next) * radius, y + MathUtils.sinDeg(next) * radius, width);
        }
    }
}
