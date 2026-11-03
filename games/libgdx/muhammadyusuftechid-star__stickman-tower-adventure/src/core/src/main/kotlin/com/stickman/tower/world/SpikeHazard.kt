package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Objek rintangan duri lantai (Spike Hazard).
 * Memberikan damage instan dan melentingkan karakter ke atas saat terinjak.
 */
class SpikeHazard(
    val x: Float,
    val y: Float,
    val width: Float = 2.0f,
    val height: Float = 0.5f,
    val damage: Float = 18f
) {
    val bounds = Rectangle(x, y, width, height)

    companion object {
        private val COLOR_SPIKE = Color(0.85f, 0.25f, 0.25f, 1f)
        private val COLOR_BASE = Color(0.2f, 0.22f, 0.28f, 1f)
    }

    fun checkCollision(playerBounds: Rectangle): Boolean {
        return bounds.overlaps(playerBounds)
    }

    fun render(shapeRenderer: ShapeRenderer) {
        val spikeCount = (width / 0.4f).toInt().coerceAtLeast(2)
        val spikeWidth = width / spikeCount

        // Render segitiga-segitiga duri baja merah tajam
        for (i in 0 until spikeCount) {
            val x1 = x + i * spikeWidth
            val y1 = y
            val x2 = x1 + spikeWidth / 2f
            val y2 = y + height
            val x3 = x1 + spikeWidth
            val y3 = y

            shapeRenderer.color = COLOR_SPIKE
            shapeRenderer.triangle(x1, y1, x2, y2, x3, y3)

            // Highlight puncak duri putih tajam
            shapeRenderer.color = Color.WHITE
            shapeRenderer.rectLine(x1, y1, x2, y2, 0.03f)
        }

        // Garis dasar logam penyangga duri
        shapeRenderer.color = COLOR_BASE
        shapeRenderer.rect(x, y, width, 0.08f)
    }
}
