package com.bossfight.effects;

import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;

public final class CameraShake {
    private float timer;
    private float duration;
    private float magnitude;

    public void update(float delta) {
        timer = Math.max(0f, timer - delta);
        if (timer <= 0f) {
            magnitude = 0f;
        }
    }

    public void request(float requestedMagnitude, float requestedDuration) {
        float activeStrength = duration <= 0f ? 0f : magnitude * MathUtils.clamp(timer / duration, 0f, 1f);
        if (requestedMagnitude < activeStrength) {
            return;
        }

        magnitude = requestedMagnitude;
        duration = Math.max(0.01f, requestedDuration);
        timer = duration;
    }

    public void apply(OrthographicCamera camera, float elapsed) {
        float alpha = duration <= 0f ? 0f : MathUtils.clamp(timer / duration, 0f, 1f);
        float easedAlpha = alpha * alpha;
        float shakeTime = elapsed * 46f;
        float offsetX = smoothNoise(shakeTime, 0.3f) * magnitude * easedAlpha;
        float offsetY = smoothNoise(shakeTime, 2.1f) * magnitude * easedAlpha;

        camera.position.set(
                Constants.WORLD_WIDTH * 0.5f + offsetX,
                Constants.WORLD_HEIGHT * 0.5f + offsetY,
                0f);
        camera.update();
    }

    private float smoothNoise(float time, float phase) {
        return (MathUtils.sin(time + phase)
                + MathUtils.sin(time * 1.73f + phase * 1.9f) * 0.5f
                + MathUtils.sin(time * 2.41f + phase * 0.7f) * 0.25f) / 1.75f;
    }
}
