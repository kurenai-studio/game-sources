package com.stickman.tower.vfx

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Vector2

class Particle {
    val position = Vector2()
    val velocity = Vector2()
    var size: Float = 0f
    val color = Color(Color.WHITE)
    var maxLife: Float = 0f
    var life: Float = 0f

    val isExpired: Boolean get() = life >= maxLife

    fun reset(x: Float, y: Float, vx: Float, vy: Float, pSize: Float, pColor: Color, pMaxLife: Float) {
        position.set(x, y)
        velocity.set(vx, vy)
        size = pSize
        color.set(pColor)
        maxLife = pMaxLife
        life = 0f
    }
}

class SlashEffect {
    var centerX: Float = 0f
    var centerY: Float = 0f
    var radius: Float = 0f
    var startAngle: Float = 0f
    var endAngle: Float = 0f
    val color = Color(Color.WHITE)
    var maxLife: Float = 0.18f
    var life: Float = 0f

    val isExpired: Boolean get() = life >= maxLife

    fun reset(cx: Float, cy: Float, r: Float, sAng: Float, eAng: Float, pColor: Color, pMaxLife: Float = 0.18f) {
        centerX = cx
        centerY = cy
        radius = r
        startAngle = sAng
        endAngle = eAng
        color.set(pColor)
        maxLife = pMaxLife
        life = 0f
    }
}

/**
 * Manajer Efek Visual Partikel (VFX) Zero-Allocation:
 * Menggunakan Object Pooling untuk mendaur ulang partikel dan tebasan senjata,
 * menghilangkan Garbage Collection stutters pada perangkat mobile berdaya rendah.
 */
class ParticleManager {
    private val activeParticles = mutableListOf<Particle>()
    private val particlePool = ArrayDeque<Particle>()
    val activeParticleCount: Int get() = activeParticles.size

    private val activeSlashes = mutableListOf<SlashEffect>()
    private val slashPool = ArrayDeque<SlashEffect>()

    private fun obtainParticle(): Particle {
        return if (particlePool.isNotEmpty()) particlePool.removeLast() else Particle()
    }

    private fun obtainSlash(): SlashEffect {
        return if (slashPool.isNotEmpty()) slashPool.removeLast() else SlashEffect()
    }

    companion object {
        private val DUST_COLOR = Color(0.6f, 0.65f, 0.7f, 0.6f)
    }

    fun spawnDust(x: Float, y: Float, count: Int = 5) {
        for (i in 0 until count) {
            val vx = MathUtils.random(-1.8f, 1.8f)
            val vy = MathUtils.random(0.3f, 1.4f)
            val size = MathUtils.random(0.06f, 0.12f)
            val life = MathUtils.random(0.2f, 0.4f)
            val p = obtainParticle()
            p.reset(x, y, vx, vy, size, DUST_COLOR, life)
            activeParticles.add(p)
        }
    }

    fun spawnHitSparks(x: Float, y: Float, count: Int = 8, color: Color = Color.GOLD) {
        for (i in 0 until count) {
            val angle = MathUtils.random(0f, 360f)
            val speed = MathUtils.random(4f, 10f)
            val vx = MathUtils.cosDeg(angle) * speed
            val vy = MathUtils.sinDeg(angle) * speed
            val size = MathUtils.random(0.04f, 0.08f)
            val life = MathUtils.random(0.12f, 0.25f)
            val p = obtainParticle()
            p.reset(x, y, vx, vy, size, color, life)
            activeParticles.add(p)
        }
    }

    fun spawnSlash(centerX: Float, centerY: Float, radius: Float, startAngle: Float, endAngle: Float, color: Color) {
        val s = obtainSlash()
        s.reset(centerX, centerY, radius, startAngle, endAngle, color)
        activeSlashes.add(s)
    }

    fun update(delta: Float) {
        val pIt = activeParticles.iterator()
        while (pIt.hasNext()) {
            val p = pIt.next()
            p.life += delta
            p.position.x += p.velocity.x * delta
            p.position.y += p.velocity.y * delta
            p.velocity.y -= 4f * delta // gravitasi ringan pada partikel
            if (p.isExpired) {
                pIt.remove()
                if (particlePool.size < 120) particlePool.add(p)
            }
        }

        val sIt = activeSlashes.iterator()
        while (sIt.hasNext()) {
            val s = sIt.next()
            s.life += delta
            if (s.isExpired) {
                sIt.remove()
                if (slashPool.size < 20) slashPool.add(s)
            }
        }
    }

    fun render(shapeRenderer: ShapeRenderer, minX: Float = Float.NEGATIVE_INFINITY, maxX: Float = Float.POSITIVE_INFINITY) {
        // Render Partikel tanpa alokasi Color baru dengan Frustum Bounding Box Culling
        for (p in activeParticles) {
            if (p.position.x < minX || p.position.x > maxX) continue
            val alpha = (1f - (p.life / p.maxLife)).coerceIn(0f, 1f)
            shapeRenderer.setColor(p.color.r, p.color.g, p.color.b, alpha)
            shapeRenderer.circle(p.position.x, p.position.y, p.size, 8)
        }

        // Render Garis Lengkung Tebasan (Slash Arcs) tanpa alokasi Color baru
        for (s in activeSlashes) {
            if (s.centerX + s.radius < minX || s.centerX - s.radius > maxX) continue
            val alpha = (1f - (s.life / s.maxLife)).coerceIn(0f, 1f)
            shapeRenderer.setColor(s.color.r, s.color.g, s.color.b, alpha * 0.8f)

            val segments = 8
            val sweep = s.endAngle - s.startAngle
            var prevX = s.centerX + MathUtils.cosDeg(s.startAngle) * s.radius
            var prevY = s.centerY + MathUtils.sinDeg(s.startAngle) * s.radius

            for (i in 1..segments) {
                val ang = s.startAngle + sweep * (i.toFloat() / segments)
                val curX = s.centerX + MathUtils.cosDeg(ang) * s.radius
                val curY = s.centerY + MathUtils.sinDeg(ang) * s.radius
                shapeRenderer.rectLine(prevX, prevY, curX, curY, 0.08f * alpha)
                prevX = curX
                prevY = curY
            }
        }
    }

    fun clear() {
        particlePool.addAll(activeParticles)
        activeParticles.clear()
        slashPool.addAll(activeSlashes)
        activeSlashes.clear()
    }
}
