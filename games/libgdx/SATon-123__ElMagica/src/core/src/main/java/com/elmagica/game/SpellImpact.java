package com.elmagica.game;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;

public class SpellImpact {
    public final ElementType element;
    private final float x, y;
    private float age;
    private final float fireRadius;
    public SpellImpact(ElementType element, float x, float y) {
        this(element, x, y, 48);
    }
    public SpellImpact(ElementType element, float x, float y, float fireRadius) {
        this.element = element;
        this.fireRadius = fireRadius;
        this.x = x;
        this.y = y;
    }
    public void update(float delta) { age += delta; }
    public boolean isFinished() { return age >= 0.25f; }
    public void draw(ShapeRenderer shapes) {
        float progress = age / 0.25f;
        float radius = element == ElementType.FIRE ? fireRadius : 12 + progress * 12;
        if (element == ElementType.FIRE) {
            // Взрыв бьёт сразу по всему радиусу, границу показываем с первого кадра.
            shapes.setColor(1, 0.35f, 0.1f, (1 - progress) * 0.28f);
            shapes.circle(x, y, fireRadius, 32);
            shapes.setColor(1, 0.8f, 0.3f, 1 - progress);
            SpellVisuals.ring(shapes, x, y, Math.max(1, fireRadius - 2), 3, 0, 360);
        }
        shapes.setColor(element.color.r, element.color.g, element.color.b, 1 - age / 0.25f);
        for (int i = 0; i < 12; i++) {
            float angle = i * 30;
            float distance = element == ElementType.FIRE ? Math.max(0, radius - 4) * (0.35f + progress * 0.6f) : radius;
            shapes.rect(x + MathUtils.cosDeg(angle) * distance - 3, y + MathUtils.sinDeg(angle) * distance - 3, 6, 6);
        }
    }
}
