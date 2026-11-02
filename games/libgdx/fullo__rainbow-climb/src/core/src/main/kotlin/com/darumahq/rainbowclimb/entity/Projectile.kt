package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.darumahq.rainbowclimb.util.Constants

enum class ProjectileType {
    HORIZONTAL,
    VERTICAL
}

class Projectile {
    val position = Vector2()
    val velocity = Vector2()
    val bounds = Rectangle()
    var active = false
    var timer = 0f
    var type = ProjectileType.HORIZONTAL

    fun activate(x: Float, y: Float, projType: ProjectileType, direction: Int) {
        position.set(x, y)
        type = projType
        active = true
        timer = Constants.PROJECTILE_LIFETIME

        when (projType) {
            ProjectileType.HORIZONTAL -> velocity.set(Constants.PROJECTILE_SPEED * direction, 0f)
            ProjectileType.VERTICAL -> velocity.set(0f, Constants.BOMB_FALL_SPEED)
        }

        bounds.set(x, y, Constants.PROJECTILE_SIZE, Constants.PROJECTILE_SIZE)
    }

    fun update(delta: Float) {
        if (!active) return

        position.x += velocity.x * delta
        position.y += velocity.y * delta
        bounds.setPosition(position.x, position.y)

        timer -= delta
        if (timer <= 0f) {
            active = false
        }
    }

    fun reset() {
        active = false
        timer = 0f
        velocity.set(0f, 0f)
    }
}
