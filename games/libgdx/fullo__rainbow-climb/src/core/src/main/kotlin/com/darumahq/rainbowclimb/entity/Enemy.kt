package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.darumahq.rainbowclimb.util.Constants

enum class EnemyType {
    WALKER,
    FLYER,
    HOPPER,
    SHOOTER,
    BOMBER,
    CHASER
}

class Enemy {
    val position = Vector2()
    val velocity = Vector2()
    val bounds = Rectangle()
    var type = EnemyType.WALKER
    var active = false
    var baseSpeed = 40f

    // Patrol bounds
    var patrolMinX = 0f
    var patrolMaxX = 0f

    // Sine wave movement (for flyers)
    var sineTimer = 0f
    var sineAmplitude = 30f
    var baseY = 0f

    // Shooter/Bomber AI
    var shootTimer = 0f

    // Chaser AI
    var chaseTimer = 0f
    var isChasing = false
    var chaseTargetX = 0f
    var chaseTargetY = 0f

    // Animation
    var stateTime = 0f
    var facingRight = true
    var attackAnimTimer = 0f

    fun activate(x: Float, y: Float, enemyType: EnemyType, speed: Float = 40f) {
        position.set(x, y)
        type = enemyType
        active = true
        baseSpeed = speed
        baseY = y
        sineTimer = 0f
        shootTimer = 0f
        wantsToFire = false
        chaseTimer = 0f
        isChasing = false
        stateTime = 0f
        facingRight = true
        attackAnimTimer = 0f

        when (type) {
            EnemyType.WALKER -> {
                velocity.set(baseSpeed, 0f)
            }
            EnemyType.FLYER -> {
                velocity.set(baseSpeed * 0.5f, 0f)
                sineAmplitude = 30f
            }
            EnemyType.HOPPER -> {
                velocity.set(baseSpeed * 0.8f, 0f)
            }
            EnemyType.SHOOTER -> {
                velocity.set(0f, 0f)
                shootTimer = Constants.SHOOTER_COOLDOWN * 0.5f // stagger first shot
            }
            EnemyType.BOMBER -> {
                velocity.set(baseSpeed * 0.5f, 0f)
                sineAmplitude = 15f
                baseY = y + Constants.BOMBER_HEIGHT_OFFSET
                position.y = baseY
                shootTimer = Constants.BOMBER_COOLDOWN
                bounds.set(position.x, position.y, Constants.BOMBER_WIDTH, Constants.BOMBER_HEIGHT)
            }
            EnemyType.CHASER -> {
                velocity.set(0f, 0f)
            }
        }
    }

    fun animState(): String {
        if (attackAnimTimer > 0) return when (type) {
            EnemyType.SHOOTER -> "attack"
            EnemyType.BOMBER -> "throw"
            else -> "idle"
        }
        return when (type) {
            EnemyType.WALKER -> if (velocity.x != 0f) "run" else "idle"
            EnemyType.FLYER -> "spin"
            EnemyType.HOPPER -> when {
                velocity.y > 0 -> "jump"
                velocity.y < -50f -> "fall"
                else -> "idle"
            }
            EnemyType.SHOOTER -> "idle"
            EnemyType.BOMBER -> if (velocity.x != 0f) "run" else "idle"
            EnemyType.CHASER -> if (isChasing) "run" else "idle"
        }
    }

    fun update(delta: Float) {
        if (!active) return

        stateTime += delta
        if (attackAnimTimer > 0) attackAnimTimer -= delta

        when (type) {
            EnemyType.WALKER -> updateWalker(delta)
            EnemyType.FLYER -> updateFlyer(delta)
            EnemyType.HOPPER -> updateHopper(delta)
            EnemyType.SHOOTER -> updateShooter(delta)
            EnemyType.BOMBER -> updateBomber(delta)
            EnemyType.CHASER -> updateChaser(delta)
        }

        val w = if (type == EnemyType.BOMBER) Constants.BOMBER_WIDTH else Constants.ENEMY_SIZE
        val h = if (type == EnemyType.BOMBER) Constants.BOMBER_HEIGHT else Constants.ENEMY_SIZE
        bounds.set(position.x, position.y, w, h)
    }

    private fun updateWalker(delta: Float) {
        position.x += velocity.x * delta
        clampPatrol()
    }

    private fun updateFlyer(delta: Float) {
        position.x += velocity.x * delta
        sineTimer += delta * 3f
        position.y = baseY + kotlin.math.sin(sineTimer.toDouble()).toFloat() * sineAmplitude
        clampPatrol()
    }

    private fun clampPatrol() {
        if (position.x <= patrolMinX) {
            position.x = patrolMinX
            velocity.x = kotlin.math.abs(velocity.x)
            facingRight = true
        } else if (position.x >= patrolMaxX) {
            position.x = patrolMaxX
            velocity.x = -kotlin.math.abs(velocity.x)
            facingRight = false
        }
    }

    private fun updateHopper(delta: Float) {
        position.x += velocity.x * delta
        position.y += velocity.y * delta
        velocity.y += Constants.GRAVITY * delta * 0.3f // lighter gravity for hoppers

        // Jump when landing back at or below baseY
        if (position.y <= baseY && velocity.y <= 0f) {
            position.y = baseY
            velocity.y = Constants.JUMP_VELOCITY * 0.6f // shorter jump than player
        }

        clampPatrol()
    }

    // Set to true when shootTimer expires; World reads and resets this flag
    var wantsToFire = false

    private fun updateShooter(delta: Float) {
        // Stationary — fire when cooldown expires
        shootTimer -= delta
        if (shootTimer <= 0f) {
            wantsToFire = true
            attackAnimTimer = 0.3f
            shootTimer = Constants.SHOOTER_COOLDOWN
        }
    }

    private fun updateBomber(delta: Float) {
        // Horizontal patrol + sine wave at elevated height
        position.x += velocity.x * delta
        sineTimer += delta * 2f
        position.y = baseY + kotlin.math.sin(sineTimer.toDouble()).toFloat() * sineAmplitude

        if (position.x <= patrolMinX) {
            position.x = patrolMinX
            velocity.x = kotlin.math.abs(velocity.x)
        } else if (position.x >= patrolMaxX) {
            position.x = patrolMaxX
            velocity.x = -kotlin.math.abs(velocity.x)
        }

        shootTimer -= delta
        if (shootTimer <= 0f) {
            wantsToFire = true
            attackAnimTimer = 0.25f
            shootTimer = Constants.BOMBER_COOLDOWN
        }
    }

    private fun updateChaser(delta: Float) {
        if (!isChasing) return

        chaseTimer -= delta
        if (chaseTimer <= 0f) {
            isChasing = false
            velocity.set(0f, 0f)
            return
        }

        // Move toward target
        val dx = chaseTargetX - position.x
        val dy = chaseTargetY - position.y
        val dist = kotlin.math.sqrt((dx * dx + dy * dy).toDouble()).toFloat()
        if (dist > 1f) {
            val chaseSpeed = baseSpeed * Constants.CHASER_SPEED_MULT
            velocity.x = (dx / dist) * chaseSpeed
            velocity.y = (dy / dist) * chaseSpeed
        }

        position.x += velocity.x * delta
        position.y += velocity.y * delta
    }

    fun reset() {
        active = false
        position.set(0f, 0f)
        velocity.set(0f, 0f)
        shootTimer = 0f
        wantsToFire = false
        chaseTimer = 0f
        isChasing = false
        stateTime = 0f
        facingRight = true
        attackAnimTimer = 0f
    }
}
