package com.stickman.tower.combat

import com.badlogic.gdx.graphics.Camera
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.SpriteBatch

/**
 * Merepresentasikan angka damage atau teks melayang yang muncul di dunia game
 * dan diproyeksikan ke virtual UI canvas (1280x720) dengan fade-out dan zero allocation.
 */
class FloatingText(
    val text: String,
    var worldX: Float,
    var worldY: Float,
    val color: Color = Color.RED,
    val duration: Float = 0.8f,
    val isCritical: Boolean = false
) {
    private var elapsed: Float = 0f

    val isExpired: Boolean get() = elapsed >= duration

    fun update(delta: Float) {
        elapsed += delta
        val speed = if (isCritical) 2.2f else 1.5f
        worldY += speed * delta
    }

    fun render(batch: SpriteBatch, font: BitmapFont, camera: Camera) {
        if (isExpired) return

        // Proyeksikan posisi dunia ke virtual UI canvas 1280x720 (1 meter = 80 virtual pixels)
        val uiX = (worldX - camera.position.x) * 80f + 640f
        val uiY = (worldY - camera.position.y) * 80f + 360f

        // Lewati jika di luar layar virtual
        if (uiX < -60f || uiX > 1340f || uiY < -30f || uiY > 750f) return

        // Hitung transparansi fade out
        val alpha = (1f - (elapsed / duration)).coerceIn(0f, 1f)

        font.setColor(color.r, color.g, color.b, alpha)
        font.draw(batch, text, uiX - (if (isCritical) 24f else 14f), uiY)
    }
}
