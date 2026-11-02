package com.darumahq.rainbowclimb.input

import com.badlogic.gdx.InputAdapter
import com.darumahq.rainbowclimb.util.Constants

class TouchInputHandler : InputAdapter() {
    var moveDirection = 0    // -1 left, 0 none, 1 right
    var jumpRequested = false
    var rainbowDirection = -2 // -2 = none, -1 left, 0 up, 1 right

    private var touchX = 0f
    private var touchY = 0f
    private var touchStartX = 0f
    private var touchStartY = 0f
    private var isTouching = false

    override fun touchDown(screenX: Int, screenY: Int, pointer: Int, button: Int): Boolean {
        if (pointer > 0) {
            // Second finger = jump
            jumpRequested = true
            return true
        }

        isTouching = true
        touchX = screenX.toFloat()
        touchY = screenY.toFloat()
        touchStartX = touchX
        touchStartY = touchY

        updateMoveDirection()
        return true
    }

    override fun touchUp(screenX: Int, screenY: Int, pointer: Int, button: Int): Boolean {
        if (pointer == 0) {
            // Check for swipe (rainbow)
            val dx = screenX - touchStartX
            val dy = touchStartY - screenY // inverted Y
            val swipeThreshold = 50f

            if (Math.abs(dx) > swipeThreshold || Math.abs(dy) > swipeThreshold) {
                rainbowDirection = when {
                    Math.abs(dy) > Math.abs(dx) && dy > 0 -> 0  // swipe up
                    dx < 0 -> -1  // swipe left
                    else -> 1     // swipe right
                }
            }

            isTouching = false
            moveDirection = 0
        }
        return true
    }

    override fun touchDragged(screenX: Int, screenY: Int, pointer: Int): Boolean {
        if (pointer == 0) {
            touchX = screenX.toFloat()
            touchY = screenY.toFloat()
            updateMoveDirection()
        }
        return true
    }

    private fun updateMoveDirection() {
        // Left half = move left, right half = move right
        val screenMidX = com.badlogic.gdx.Gdx.graphics.width / 2f
        moveDirection = if (touchX < screenMidX) -1 else 1
    }

    fun consumeJump(): Boolean {
        if (jumpRequested) {
            jumpRequested = false
            return true
        }
        return false
    }

    fun consumeRainbow(): Int {
        val dir = rainbowDirection
        rainbowDirection = -2
        return dir
    }
}
