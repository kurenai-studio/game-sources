package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.darumahq.rainbowclimb.util.Constants

class Rainbow {
    val position = Vector2()
    val bounds = Rectangle()
    var active = false
    var timer = 0f
    var direction = 1 // -1 left, 1 right

    fun activate(startX: Float, startY: Float, dir: Int, onGround: Boolean) {
        active = true
        timer = Constants.RAINBOW_DURATION
        direction = if (dir >= 0) 1 else -1

        // Y position depends on player state:
        // - On ground: platform created 48px ABOVE player (to climb onto)
        // - In air/jumping: platform created 6px BELOW player (to land on)
        val platformY = if (onGround) {
            startY + 48f
        } else {
            startY - 6f
        }

        // X position: extends in the direction the player faces
        val platformX = if (direction == -1) {
            startX - Constants.RAINBOW_LENGTH
        } else {
            startX + Constants.PLAYER_WIDTH
        }

        position.set(platformX, platformY)
        bounds.set(platformX, platformY, Constants.RAINBOW_LENGTH, Constants.RAINBOW_WIDTH)
    }

    fun update(delta: Float) {
        if (!active) return
        timer -= delta
        if (timer <= 0f) {
            active = false
        }
    }

    fun reset() {
        active = false
        timer = 0f
    }
}
