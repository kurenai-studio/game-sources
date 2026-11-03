package com.stickman.tower.combat

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Merepresentasikan area tubuh karakter yang dapat menerima damage.
 */
class Hurtbox(
    val owner: Any
) {
    val bounds = Rectangle()
    var isActive: Boolean = true

    fun set(x: Float, y: Float, width: Float, height: Float) {
        bounds.set(x, y, width, height)
    }

    fun renderDebug(shapeRenderer: ShapeRenderer) {
        if (isActive) {
            shapeRenderer.color = Color.CYAN
            shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)
        }
    }
}
