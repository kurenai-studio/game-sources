package com.stickman.tower.combat

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Merepresentasikan area serangan yang aktif pada frame tertentu.
 * Dilengkapi exclusion set untuk mencegah satu serangan melukai target berkali-kali.
 */
class Hitbox(
    val owner: Any,
    var damage: Float = 15f,
    var knockbackX: Float = 6f,
    var knockbackY: Float = 3f
) {
    val bounds = Rectangle()
    var isActive: Boolean = false
    var isCritical: Boolean = false
    val hitEntities = mutableSetOf<Any>()

    fun set(x: Float, y: Float, width: Float, height: Float, active: Boolean) {
        bounds.set(x, y, width, height)
        isActive = active
    }

    fun reset() {
        isActive = false
        isCritical = false
        hitEntities.clear()
    }

    fun renderDebug(shapeRenderer: ShapeRenderer) {
        if (isActive) {
            shapeRenderer.color = Color.RED
            shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)
        }
    }
}
