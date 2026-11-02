package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.darumahq.rainbowclimb.util.Constants

/**
 * King Pig boss — appears every 5 biomes.
 * Stays near top of screen. Leaves after 15 seconds if not killed.
 * HP = boss number (1st boss: 1 hit, 2nd: 2 hits, 3rd: 3 hits...).
 * Drops 50 gems when killed.
 */
class Boss {
    val position = Vector2()
    val velocity = Vector2()
    val bounds = Rectangle()
    var active = false
    var hp = 1
    var maxHp = 1
    var stateTime = 0f
    var facingRight = false
    var bossNumber = 1  // which boss encounter (1st, 2nd, 3rd...)

    enum class State { IDLE, SWOOP, RETREAT, HIT, DEAD, FLEEING }
    var state = State.IDLE
    private var stateTimer = 0f
    private var lifeTimer = 0f  // 15 seconds total on screen

    // Camera-relative positioning
    var cameraY = 0f
    private var highY = 0f     // high position (near top of screen)
    private var swoopTargetX = 0f

    companion object {
        const val WIDTH = 64f
        const val HEIGHT = 48f
        const val SPEED = 250f
        const val SWOOP_SPEED = 400f
        const val LIFE_DURATION = 15f  // seconds before fleeing
    }

    fun activate(x: Float, y: Float, camY: Float, bossNum: Int) {
        position.set(x, y)
        cameraY = camY
        bossNumber = bossNum
        hp = bossNum         // 1st boss = 1 HP, 2nd = 2, etc.
        maxHp = hp
        active = true
        stateTime = 0f
        state = State.IDLE
        stateTimer = 1.5f
        lifeTimer = LIFE_DURATION
        velocity.set(0f, 0f)
        bounds.set(x, y, WIDTH, HEIGHT)

        // Boss stays between 35% and 60% of the screen height
        highY = Constants.VIRTUAL_HEIGHT * 0.55f  // idle position (55%)
    }

    fun update(delta: Float, playerX: Float, playerY: Float) {
        if (!active) return

        stateTime += delta
        stateTimer -= delta
        lifeTimer -= delta

        facingRight = playerX > position.x

        // Time's up — flee!
        if (lifeTimer <= 0f && state != State.DEAD && state != State.FLEEING) {
            state = State.FLEEING
            stateTimer = 2f
            stateTime = 0f
        }

        // Target Y: boss prefers to stay high
        val targetHighY = cameraY + highY

        when (state) {
            State.IDLE -> {
                // Patrol horizontally near top of screen
                val dir = if (facingRight) 1f else -1f
                velocity.x = dir * SPEED * 0.5f

                // Float toward high position
                position.y += (targetHighY - position.y) * 4f * delta

                if (stateTimer <= 0f) {
                    // Swoop down toward player
                    state = State.SWOOP
                    swoopTargetX = playerX
                    stateTimer = 1.0f
                    stateTime = 0f
                }
            }
            State.SWOOP -> {
                // Dive toward player position
                val dx = swoopTargetX - position.x
                val dy = (playerY + 60f) - position.y  // aim slightly above player
                velocity.x = dx.coerceIn(-SWOOP_SPEED, SWOOP_SPEED)
                velocity.y = dy.coerceIn(-SWOOP_SPEED, SWOOP_SPEED)

                if (stateTimer <= 0f) {
                    state = State.RETREAT
                    stateTimer = 1.2f
                    stateTime = 0f
                }
            }
            State.RETREAT -> {
                // Go back up
                velocity.x *= 0.95f
                position.y += (targetHighY - position.y) * 5f * delta
                velocity.y = 0f

                if (stateTimer <= 0f || kotlin.math.abs(position.y - targetHighY) < 10f) {
                    state = State.IDLE
                    stateTimer = 1.5f
                    stateTime = 0f
                }
            }
            State.HIT -> {
                // Brief stun
                velocity.x *= 0.7f
                velocity.y = 0f
                // Drift upward during hit stun
                position.y += (targetHighY - position.y) * 2f * delta

                if (stateTimer <= 0f) {
                    if (hp <= 0) {
                        state = State.DEAD
                        stateTimer = 1.5f
                        stateTime = 0f
                    } else {
                        state = State.RETREAT
                        stateTimer = 1.0f
                        stateTime = 0f
                    }
                }
            }
            State.DEAD -> {
                velocity.x = 0f
                velocity.y -= 400f * delta  // fall off screen
                if (stateTimer <= 0f) {
                    active = false
                }
            }
            State.FLEEING -> {
                // Fly off the top of the screen
                velocity.x = 0f
                velocity.y = 300f  // go up fast
                if (stateTimer <= 0f || position.y > cameraY + Constants.VIRTUAL_HEIGHT + HEIGHT) {
                    active = false
                }
            }
        }

        position.x += velocity.x * delta
        position.y += velocity.y * delta
        position.x = position.x.coerceIn(0f, Constants.VIRTUAL_WIDTH - WIDTH)

        // Clamp Y between 35% and 60% of screen (except when DEAD or FLEEING)
        if (state != State.DEAD && state != State.FLEEING) {
            val minY = cameraY + Constants.VIRTUAL_HEIGHT * 0.35f
            val maxY = cameraY + Constants.VIRTUAL_HEIGHT * 0.60f
            position.y = position.y.coerceIn(minY, maxY)
        }

        bounds.set(position.x, position.y, WIDTH, HEIGHT)
    }

    fun takeDamage() {
        if (state == State.DEAD || state == State.HIT || state == State.FLEEING) return
        hp--
        state = State.HIT
        stateTimer = 0.4f
        stateTime = 0f
        // Knockback upward
        velocity.x = if (facingRight) -150f else 150f
        velocity.y = 100f
    }

    /** Remaining time as fraction (1.0 = full, 0.0 = expired) */
    fun timeRemaining(): Float = (lifeTimer / LIFE_DURATION).coerceIn(0f, 1f)

    fun animState(): String = when (state) {
        State.IDLE -> "idle"
        State.SWOOP -> "attack"
        State.RETREAT -> "run"
        State.HIT -> "hit"
        State.DEAD -> "dead"
        State.FLEEING -> "run"
    }

    fun reset() {
        active = false
        hp = 0
    }
}
