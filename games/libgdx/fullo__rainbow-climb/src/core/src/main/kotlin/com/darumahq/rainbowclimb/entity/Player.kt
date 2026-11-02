package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.darumahq.rainbowclimb.util.Constants

class Player {
    val position = Vector2(Constants.VIRTUAL_WIDTH / 2f - Constants.PLAYER_WIDTH / 2f,
        Constants.VIRTUAL_HEIGHT / 2f)
    val velocity = Vector2(0f, 0f)
    val bounds = Rectangle()

    var isOnGround = false
    var hasDoubleJump = false
    var doubleJumpUsed = false
    var isAlive = true
    var lives = 2

    // Rainbow ammo
    var rainbowAmmo = Constants.RAINBOW_MAX_AMMO
    var maxRainbowAmmo = Constants.RAINBOW_MAX_AMMO
    var rainbowRegenTimer = 0f

    // Invincibility (on respawn: 5 seconds, blinks 5 times)
    var invincibleTimer = 0f
    val isInvincible: Boolean get() = invincibleTimer > 0f

    // Power-up timers
    var shieldActive = false
    var magnetTimer = 0f
    var slowTimeTimer = 0f
    var rainbowBoostTimer = 0f
    var doubleJumpTimer = 0f

    // Facing direction: 1 = right, -1 = left
    var facing = 1

    // Animation
    var stateTime = 0f
    private var previousAnimState = "idle"

    fun animState(): String {
        if (!isAlive) return "hit"
        if (!isOnGround && velocity.y > 0) return "jump"
        if (!isOnGround && velocity.y <= 0) return "fall"
        if (velocity.x != 0f) return "run"
        return "idle"
    }

    fun update(delta: Float) {
        // Always update animation timing (even when dead, for death animation)
        val currentAnim = animState()
        if (currentAnim != previousAnimState) {
            stateTime = 0f
            previousAnimState = currentAnim
        }
        stateTime += delta

        if (!isAlive) return

        // Apply gravity
        velocity.y += Constants.GRAVITY * delta
        if (velocity.y < Constants.MAX_FALL_SPEED) {
            velocity.y = Constants.MAX_FALL_SPEED
        }

        // Move
        position.x += velocity.x * delta
        position.y += velocity.y * delta

        // Wrap horizontally
        if (position.x < -Constants.PLAYER_WIDTH) {
            position.x = Constants.VIRTUAL_WIDTH
        } else if (position.x > Constants.VIRTUAL_WIDTH) {
            position.x = -Constants.PLAYER_WIDTH
        }

        // Update bounds for collision
        bounds.set(position.x, position.y, Constants.PLAYER_WIDTH, Constants.PLAYER_HEIGHT)

        // Tick invincibility
        if (invincibleTimer > 0) invincibleTimer -= delta

        // Regenerate rainbow ammo
        rainbowRegenTimer += delta
        val regenTime = if (rainbowBoostTimer > 0) Constants.RAINBOW_REGEN_TIME / 2f else Constants.RAINBOW_REGEN_TIME
        if (rainbowRegenTimer >= regenTime && rainbowAmmo < maxRainbowAmmo) {
            rainbowAmmo++
            rainbowRegenTimer = 0f
        }

        // Tick power-up timers
        if (rainbowBoostTimer > 0) {
            rainbowBoostTimer -= delta
            if (rainbowBoostTimer <= 0) {
                maxRainbowAmmo = Constants.RAINBOW_MAX_AMMO
                rainbowAmmo = rainbowAmmo.coerceAtMost(maxRainbowAmmo)
            }
        }
        if (doubleJumpTimer > 0) {
            doubleJumpTimer -= delta
            if (doubleJumpTimer <= 0) hasDoubleJump = false
        }
        if (magnetTimer > 0) magnetTimer -= delta
        if (slowTimeTimer > 0) slowTimeTimer -= delta
    }

    fun jump() {
        if (isOnGround) {
            velocity.y = Constants.JUMP_VELOCITY
            isOnGround = false
            doubleJumpUsed = false
        } else if (hasDoubleJump && !doubleJumpUsed) {
            velocity.y = Constants.JUMP_VELOCITY
            doubleJumpUsed = true
        }
    }

    fun moveLeft() {
        velocity.x = -Constants.MOVE_SPEED
        facing = -1
    }

    fun moveRight() {
        velocity.x = Constants.MOVE_SPEED
        facing = 1
    }

    fun stopMoving() {
        velocity.x = 0f
    }

    fun canShootRainbow(): Boolean = rainbowAmmo > 0 && isAlive

    fun shootRainbow(): Boolean {
        if (!canShootRainbow()) return false
        rainbowAmmo--
        rainbowRegenTimer = 0f
        return true
    }

    fun reset() {
        position.set(Constants.VIRTUAL_WIDTH / 2f - Constants.PLAYER_WIDTH / 2f,
            Constants.VIRTUAL_HEIGHT / 2f)
        velocity.set(0f, 0f)
        isOnGround = false
        isAlive = true
        lives = 2
        rainbowAmmo = Constants.RAINBOW_MAX_AMMO
        maxRainbowAmmo = Constants.RAINBOW_MAX_AMMO
        rainbowRegenTimer = 0f
        invincibleTimer = 0f
        shieldActive = false
        magnetTimer = 0f
        slowTimeTimer = 0f
        rainbowBoostTimer = 0f
        doubleJumpTimer = 0f
        hasDoubleJump = false
        doubleJumpUsed = false
        facing = 1
        stateTime = 0f
        previousAnimState = "idle"
    }
}
