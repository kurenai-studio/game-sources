package com.stickman.tower.combat

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2

/**
 * Merepresentasikan proyektil tebasan angin (Wind Slash) atau proyektil serangan jarak jauh musuh/boss.
 */
class Projectile(
    startX: Float,
    startY: Float,
    val velocityX: Float,
    val velocityY: Float = 0f,
    val damage: Float = 22f,
    val width: Float = 0.9f,
    val height: Float = 0.4f,
    val maxLifetime: Float = 3.5f,
    val color: Color = Color(1f, 0.3f, 0.2f, 1f)
) {
    val position = Vector2(startX, startY)
    val bounds = Rectangle(startX, startY, width, height)
    var lifetime = 0f
    var isDestroyed = false

    fun update(delta: Float) {
        if (isDestroyed) return
        lifetime += delta
        if (lifetime >= maxLifetime) {
            isDestroyed = true
            return
        }

        position.x += velocityX * delta
        position.y += velocityY * delta
        bounds.setPosition(position.x, position.y)
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (isDestroyed) return

        // Bilah Energi Tebasan Angin Menyala
        shapeRenderer.color = color
        shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)

        // Inti Cahaya Putih Menyala di Tengah
        shapeRenderer.color = Color.WHITE
        shapeRenderer.rect(bounds.x + 0.1f, bounds.y + 0.08f, bounds.width - 0.2f, bounds.height - 0.16f)
    }
}
