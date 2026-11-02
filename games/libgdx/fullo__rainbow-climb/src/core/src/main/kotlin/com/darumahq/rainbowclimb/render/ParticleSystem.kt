package com.darumahq.rainbowclimb.render

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.darumahq.rainbowclimb.util.SeededRandom

/**
 * Lightweight particle system for visual effects.
 * Uses ShapeRenderer (no textures) for 4x4 pixel particles.
 */
class ParticleSystem {

    data class Particle(
        var x: Float = 0f,
        var y: Float = 0f,
        var vx: Float = 0f,
        var vy: Float = 0f,
        var life: Float = 0f,
        var maxLife: Float = 1f,
        var size: Float = 2f,
        var r: Float = 1f,
        var g: Float = 1f,
        var b: Float = 1f,
        var active: Boolean = false
    )

    private val particles = Array(200) { Particle() }
    private val random = SeededRandom()

    fun update(delta: Float) {
        for (p in particles) {
            if (!p.active) continue
            p.x += p.vx * delta
            p.y += p.vy * delta
            p.vy -= 200f * delta // gravity on particles
            p.life -= delta
            if (p.life <= 0f) p.active = false
        }
    }

    fun render(shapeRenderer: ShapeRenderer) {
        for (p in particles) {
            if (!p.active) continue
            val alpha = (p.life / p.maxLife).coerceIn(0f, 1f)
            shapeRenderer.setColor(p.r, p.g, p.b, alpha)
            shapeRenderer.rect(p.x, p.y, p.size, p.size)
        }
    }

    /** Burst of colored particles (collect item, enemy death) */
    fun burst(x: Float, y: Float, count: Int, color: Color) {
        var spawned = 0
        for (p in particles) {
            if (p.active) continue
            p.active = true
            p.x = x + random.nextFloat(-4f, 4f)
            p.y = y + random.nextFloat(-4f, 4f)
            p.vx = random.nextFloat(-80f, 80f)
            p.vy = random.nextFloat(20f, 120f)
            p.life = random.nextFloat(0.3f, 0.8f)
            p.maxLife = p.life
            p.size = random.nextFloat(1f, 3f)
            p.r = color.r
            p.g = color.g
            p.b = color.b
            spawned++
            if (spawned >= count) break
        }
    }

    /** Rainbow-colored burst (rainbow mechanic) */
    fun rainbowBurst(x: Float, y: Float, count: Int) {
        val colors = listOf(Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.VIOLET)
        var spawned = 0
        for (p in particles) {
            if (p.active) continue
            val c = colors[spawned % colors.size]
            p.active = true
            p.x = x + random.nextFloat(-2f, 2f)
            p.y = y + random.nextFloat(-2f, 2f)
            p.vx = random.nextFloat(-50f, 50f)
            p.vy = random.nextFloat(30f, 100f)
            p.life = random.nextFloat(0.2f, 0.5f)
            p.maxLife = p.life
            p.size = 2f
            p.r = c.r
            p.g = c.g
            p.b = c.b
            spawned++
            if (spawned >= count) break
        }
    }

    /** Small sparkle (collectible pickup) */
    fun sparkle(x: Float, y: Float) {
        burst(x, y, 5, Color.YELLOW)
    }

    /** Death explosion */
    fun deathExplosion(x: Float, y: Float) {
        burst(x, y, 20, Color.WHITE)
        burst(x, y, 10, Color.RED)
    }

    /** Enemy defeated */
    fun enemyPoof(x: Float, y: Float) {
        burst(x, y, 8, Color.ORANGE)
    }

    fun clear() {
        for (p in particles) p.active = false
    }
}
