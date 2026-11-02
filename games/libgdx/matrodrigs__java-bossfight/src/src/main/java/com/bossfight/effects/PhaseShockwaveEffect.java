package com.bossfight.effects;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;

public final class PhaseShockwaveEffect {
    private static final int MAX_ACTIVE_SHOCKWAVES = 8;
    private static final float DURATION = 0.72f;
    private static final float START_RADIUS_X = 48f;
    private static final float END_RADIUS_X = 650f;
    private static final float START_RADIUS_Y = 18f;
    private static final float END_RADIUS_Y = 150f;

    private final float[] timers = new float[MAX_ACTIVE_SHOCKWAVES];
    private final float[] strengths = new float[MAX_ACTIVE_SHOCKWAVES];

    public void update(float delta) {
        for (int i = 0; i < timers.length; i++) {
            timers[i] = Math.max(0f, timers[i] - delta);
        }
    }

    public void spawn(float strength) {
        int slot = findAvailableSlot();
        timers[slot] = DURATION;
        strengths[slot] = strength;
    }

    public boolean isActive() {
        for (float timer : timers) {
            if (timer > 0f) {
                return true;
            }
        }
        return false;
    }

    public void render(ShapeRenderer shapeRenderer, float centerX, float centerY) {
        for (int i = 0; i < timers.length; i++) {
            if (timers[i] > 0f) {
                renderShockwave(shapeRenderer, centerX, centerY, timers[i], strengths[i]);
            }
        }
    }

    private int findAvailableSlot() {
        int oldestSlot = 0;
        for (int i = 0; i < timers.length; i++) {
            if (timers[i] <= 0f) {
                return i;
            }
            if (timers[i] < timers[oldestSlot]) {
                oldestSlot = i;
            }
        }
        return oldestSlot;
    }

    private void renderShockwave(ShapeRenderer shapeRenderer, float centerX, float centerY,
                                 float timer, float strength) {
        float progress = 1f - MathUtils.clamp(timer / DURATION, 0f, 1f);
        float eased = 1f - (1f - progress) * (1f - progress);
        float radiusX = MathUtils.lerp(START_RADIUS_X, END_RADIUS_X, eased) * strength;
        float radiusY = MathUtils.lerp(START_RADIUS_Y, END_RADIUS_Y, eased) * strength;
        float alpha = (1f - progress) * (1f - progress) * 0.5f;

        shapeRenderer.setColor(1f, 0.9f, 0.36f, alpha);
        shapeRenderer.ellipse(centerX - radiusX, centerY - radiusY, radiusX * 2f, radiusY * 2f);
        shapeRenderer.setColor(1f, 0.28f, 0.12f, alpha * 0.42f);
        shapeRenderer.ellipse(centerX - radiusX * 0.72f, centerY - radiusY * 0.72f,
                radiusX * 1.44f, radiusY * 1.44f);
    }
}
