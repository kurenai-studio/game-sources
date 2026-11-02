package com.darumahq.rainbowclimb.world

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2

enum class PlatformType {
    STATIC,
    MOVING,      // moves left-right
    CRUMBLING,   // disappears after being stood on
    ONE_WAY      // can only land from above
}

class Platform {
    val position = Vector2()
    val bounds = Rectangle()
    var type = PlatformType.STATIC
    var width = 48f
    var active = false

    // Moving platform
    var moveSpeed = 30f
    var moveMinX = 0f
    var moveMaxX = 0f

    // Crumbling platform
    var crumbleTimer = 0f
    var isCrumbling = false
    val crumbleDuration = 0.5f

    fun activate(x: Float, y: Float, w: Float, platformType: PlatformType) {
        position.set(x, y)
        width = w
        type = platformType
        active = true
        isCrumbling = false
        crumbleTimer = 0f
        updateBounds()
    }

    fun update(delta: Float) {
        if (!active) return

        when (type) {
            PlatformType.MOVING -> {
                position.x += moveSpeed * delta
                if (position.x <= moveMinX || position.x + width >= moveMaxX) {
                    moveSpeed = -moveSpeed
                }
                updateBounds()
            }
            PlatformType.CRUMBLING -> {
                if (isCrumbling) {
                    crumbleTimer += delta
                    if (crumbleTimer >= crumbleDuration) {
                        active = false
                    }
                }
            }
            else -> {}
        }
    }

    fun startCrumble() {
        if (type == PlatformType.CRUMBLING && !isCrumbling) {
            isCrumbling = true
            crumbleTimer = 0f
        }
    }

    private fun updateBounds() {
        bounds.set(position.x, position.y, width, 8f) // platforms are 8px tall
    }

    fun reset() {
        active = false
        isCrumbling = false
        crumbleTimer = 0f
    }
}
