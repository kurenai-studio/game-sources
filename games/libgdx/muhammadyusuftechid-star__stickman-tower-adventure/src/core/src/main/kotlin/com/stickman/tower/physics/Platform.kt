package com.stickman.tower.physics

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Merepresentasikan platform statis atau rintangan di dalam dunia game.
 */
class Platform(
    x: Float,
    y: Float,
    width: Float,
    height: Float,
    val isOneWay: Boolean = false,
    val color: Color = Color(0.25f, 0.35f, 0.45f, 1f)
) {
    val bounds = Rectangle(x, y, width, height)
    private val highlightColor = Color(
        (color.r + 0.15f).coerceAtMost(1f),
        (color.g + 0.15f).coerceAtMost(1f),
        (color.b + 0.15f).coerceAtMost(1f),
        1f
    )

    companion object {
        private val ONE_WAY_BODY = Color(0.35f, 0.42f, 0.50f, 0.85f)
        private val ONE_WAY_HIGHLIGHT = Color(0.6f, 0.85f, 1.0f, 1f)
    }

    val left: Float get() = bounds.x
    val right: Float get() = bounds.x + bounds.width
    val bottom: Float get() = bounds.y
    val top: Float get() = bounds.y + bounds.height

    fun render(shapeRenderer: ShapeRenderer) {
        if (isOneWay) {
            // Platform Tembus Bawah: Visual balok kayu/baja dengan garis penyangga
            shapeRenderer.color = ONE_WAY_BODY
            shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)

            // Garis tepi atas menyala cerah (menandakan lantai pijakan)
            shapeRenderer.color = ONE_WAY_HIGHLIGHT
            shapeRenderer.rect(bounds.x, top - 0.08f, bounds.width, 0.08f)
        } else {
            shapeRenderer.color = color
            shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)

            // Render garis tepi atas (top highlight) untuk visual lebih jelas
            shapeRenderer.color = highlightColor
            val highlightHeight = 0.08f.coerceAtMost(bounds.height * 0.2f)
            shapeRenderer.rect(bounds.x, top - highlightHeight, bounds.width, highlightHeight)
        }
    }
}
