package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.darumahq.rainbowclimb.util.Constants

enum class CollectibleType {
    GEM,
    STAR,
    // Power-ups
    RAINBOW_BOOST,
    DOUBLE_JUMP,
    SHIELD,
    SLOW_TIME,
    MAGNET
}

class Collectible {
    val position = Vector2()
    val bounds = Rectangle()
    var type = CollectibleType.GEM
    var active = false
    var animTimer = 0f
    var scoreValue = 10

    fun activate(x: Float, y: Float, collectibleType: CollectibleType) {
        position.set(x, y)
        type = collectibleType
        active = true
        animTimer = 0f
        val size = if (isPowerUp()) Constants.COLLECTIBLE_SIZE else Constants.GEM_SIZE
        bounds.set(x, y, size, size)

        scoreValue = when (type) {
            CollectibleType.GEM -> 10
            CollectibleType.STAR -> 50
            else -> 25 // power-ups
        }
    }

    fun update(delta: Float) {
        if (!active) return
        animTimer += delta
        bounds.setPosition(position.x, position.y)
    }

    fun isPowerUp(): Boolean = type.ordinal >= CollectibleType.RAINBOW_BOOST.ordinal

    fun reset() {
        active = false
        animTimer = 0f
    }
}
