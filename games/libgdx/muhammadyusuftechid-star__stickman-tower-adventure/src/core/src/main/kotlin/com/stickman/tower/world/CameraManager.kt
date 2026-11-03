package com.stickman.tower.world

import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Vector2
import com.badlogic.gdx.utils.viewport.FitViewport

/**
 * Mengelola kamera 2D dan viewport responsif.
 * Mendukung smooth lerp follow target dan batas level (clamping).
 */
class CameraManager(
    virtualWidth: Float = GameConfig.VIRTUAL_WIDTH,
    virtualHeight: Float = GameConfig.VIRTUAL_HEIGHT
) {
    val camera = OrthographicCamera()
    val viewport = FitViewport(virtualWidth, virtualHeight, camera)

    // Batasan Kamera (Level Boundaries)
    var minX: Float = Float.NEGATIVE_INFINITY
    var maxX: Float = Float.POSITIVE_INFINITY
    var minY: Float = Float.NEGATIVE_INFINITY
    var maxY: Float = Float.POSITIVE_INFINITY

    init {
        camera.setToOrtho(false, virtualWidth, virtualHeight)
    }

    fun setBounds(left: Float, bottom: Float, right: Float, top: Float) {
        val halfW = viewport.worldWidth / 2f
        val halfH = viewport.worldHeight / 2f
        minX = left + halfW
        maxX = if (right - halfW >= minX) right - halfW else minX
        minY = bottom + halfH
        maxY = if (top - halfH >= minY) top - halfH else minY
    }

    /**
     * Memperbarui posisi kamera dengan algoritma linear interpolation (lerp).
     */
    fun update(targetX: Float, targetY: Float, delta: Float) {
        val halfW = viewport.worldWidth / 2f
        val halfH = viewport.worldHeight / 2f

        var desiredX = targetX
        var desiredY = targetY

        // Lakukan clamp jika batasan level ditentukan
        if (minX.isFinite() && maxX.isFinite()) {
            desiredX = MathUtils.clamp(desiredX, minX, maxX)
        }
        if (minY.isFinite() && maxY.isFinite()) {
            desiredY = MathUtils.clamp(desiredY, minY, maxY)
        }

        // Lerp smoothing
        val lerpFactor = MathUtils.clamp(GameConfig.CAMERA_LERP_SPEED * delta, 0f, 1f)
        camera.position.x += (desiredX - camera.position.x) * lerpFactor
        camera.position.y += (desiredY - camera.position.y) * lerpFactor

        // Screen Shake Trauma Decay
        if (shakeTimer > 0f) {
            shakeTimer = (shakeTimer - delta).coerceAtLeast(0f)
            val currentIntensity = shakeIntensity * (if (shakeDuration > 0f) shakeTimer / shakeDuration else 0f)
            camera.position.x += MathUtils.random(-currentIntensity, currentIntensity)
            camera.position.y += MathUtils.random(-currentIntensity, currentIntensity)
        }

        camera.update()
    }

    private var shakeIntensity = 0f
    private var shakeDuration = 0f
    private var shakeTimer = 0f

    /**
     * Memulai getaran kamera (screen shake) dengan intensitas dan durasi tertentu.
     */
    fun shake(intensity: Float, duration: Float) {
        shakeIntensity = intensity
        shakeDuration = duration
        shakeTimer = duration
    }

    fun resize(width: Int, height: Int) {
        viewport.update(width, height)
    }
}
