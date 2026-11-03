package com.stickman.tower.character

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.stickman.tower.combat.Health
import com.stickman.tower.combat.Hurtbox
import com.stickman.tower.physics.Platform
import com.stickman.tower.world.GameConfig

/**
 * Entitas boneka latihan (Training Dummy) untuk memvalidasi sistem pertarungan,
 * deteksi hitbox, damage, knockback, dan visual feedback (flash red).
 */
class TrainingDummy(val spawnX: Float = 6f, val spawnY: Float = 2f) {
    val position = Vector2(spawnX, spawnY)
    val velocity = Vector2(0f, 0f)

    val width = 0.8f
    val height = 1.8f
    val bounds = Rectangle(position.x, position.y, width, height)

    val health = Health(maxHp = 100f, invulnerableDuration = 0.25f)
    val hurtbox = Hurtbox(this)

    // RPG Progression Reward
    val expReward: Int = 10
    val goldReward: Int = 3
    var rewardClaimed: Boolean = false

    private var respawnTimer: Float = 0f
    var isGrounded: Boolean = false
        private set

    fun update(delta: Float, platforms: List<Platform>) {
        health.update(delta)

        // Jika dummy mati, hitung mundur untuk respawn otomatis
        if (health.isDead) {
            respawnTimer += delta
            if (respawnTimer >= 1.5f) {
                respawn()
            }
        }

        // Terapkan gravitasi dan gesekan pada velocity knockback
        velocity.y += GameConfig.GRAVITY * delta
        velocity.y = velocity.y.coerceAtLeast(-25f)
        velocity.x = MathUtils.lerp(velocity.x, 0f, 10f * delta)

        // Resolusi collision platform
        resolveCollision(delta, platforms)

        // Perbarui letak hurtbox
        hurtbox.set(position.x, position.y, width, height)
    }

    private fun resolveCollision(delta: Float, platforms: List<Platform>) {
        // Sumbu X
        position.x += velocity.x * delta
        bounds.setPosition(position.x, position.y)
        for (platform in platforms) {
            if (bounds.overlaps(platform.bounds)) {
                if (velocity.x > 0f) position.x = platform.left - width
                else if (velocity.x < 0f) position.x = platform.right
                velocity.x = 0f
                bounds.setPosition(position.x, position.y)
            }
        }

        // Sumbu Y
        isGrounded = false
        position.y += velocity.y * delta
        bounds.setPosition(position.x, position.y)
        for (platform in platforms) {
            if (bounds.overlaps(platform.bounds)) {
                if (velocity.y <= 0f) {
                    position.y = platform.top
                    velocity.y = 0f
                    isGrounded = true
                } else if (velocity.y > 0f) {
                    position.y = platform.bottom - height
                    velocity.y = 0f
                }
                bounds.setPosition(position.x, position.y)
            }
        }
    }

    /**
     * Menerima damage dan knockback dari tebasan pemain.
     */
    fun takeHit(damage: Float, knockX: Float, knockY: Float): Boolean {
        if (health.takeDamage(damage)) {
            velocity.x = knockX
            velocity.y = knockY
            return true
        }
        return false
    }

    private fun respawn() {
        position.set(spawnX, spawnY)
        velocity.set(0f, 0f)
        health.reset()
        respawnTimer = 0f
        rewardClaimed = false
    }

    fun render(shapeRenderer: ShapeRenderer) {
        val centerX = position.x + width / 2f
        val footY = position.y
        val headRadius = 0.22f
        val headCenterY = position.y + height - headRadius - 0.05f
        val neckY = headCenterY - headRadius
        val pelvisY = position.y + 0.75f
        val shoulderY = neckY - 0.15f

        // Warna tubuh: Oranye Amber saat normal, Merah saat terkena hit
        val bodyColor = if (health.isFlashing) Color.RED else Color(0.95f, 0.6f, 0.2f, 1f)
        shapeRenderer.color = bodyColor

        // Kepala
        shapeRenderer.circle(centerX, headCenterY, headRadius, 16)

        // Mata "X" (Ciri khas dummy sasaran latihan)
        shapeRenderer.color = Color.BLACK
        val eyeLeftX = centerX - 0.08f
        val eyeRightX = centerX + 0.08f
        val eyeY = headCenterY + 0.03f
        shapeRenderer.rectLine(eyeLeftX - 0.03f, eyeY - 0.03f, eyeLeftX + 0.03f, eyeY + 0.03f, 0.02f)
        shapeRenderer.rectLine(eyeLeftX - 0.03f, eyeY + 0.03f, eyeLeftX + 0.03f, eyeY - 0.03f, 0.02f)
        shapeRenderer.rectLine(eyeRightX - 0.03f, eyeY - 0.03f, eyeRightX + 0.03f, eyeY + 0.03f, 0.02f)
        shapeRenderer.rectLine(eyeRightX - 0.03f, eyeY + 0.03f, eyeRightX + 0.03f, eyeY - 0.03f, 0.02f)

        // Tulang belakang (Spine)
        shapeRenderer.color = bodyColor
        shapeRenderer.rectLine(centerX, neckY, centerX, pelvisY, 0.08f)

        // Kaki
        shapeRenderer.rectLine(centerX, pelvisY, centerX - 0.15f, footY, 0.07f)
        shapeRenderer.rectLine(centerX, pelvisY, centerX + 0.15f, footY, 0.07f)

        // Tangan pasif di samping tubuh
        shapeRenderer.rectLine(centerX, shoulderY, centerX - 0.25f, shoulderY - 0.4f, 0.06f)
        shapeRenderer.rectLine(centerX, shoulderY, centerX + 0.25f, shoulderY - 0.4f, 0.06f)

        // Mini HP Bar di atas kepala dummy
        renderHealthBar(shapeRenderer, centerX, position.y + height + 0.2f)
    }

    companion object {
        private val COLOR_BAR_BG = Color(0.1f, 0.1f, 0.15f, 0.8f)
    }

    private fun renderHealthBar(shapeRenderer: ShapeRenderer, centerX: Float, barY: Float) {
        val barW = 1.0f
        val barH = 0.12f
        val barX = centerX - barW / 2f

        // Background Bar (Hitam / Gelap)
        shapeRenderer.color = COLOR_BAR_BG
        shapeRenderer.rect(barX, barY, barW, barH)

        // Fill Bar (Hijau / Kuning / Merah berdasarkan sisa HP)
        val hpPercent = (health.currentHp / health.maxHp).coerceIn(0f, 1f)
        shapeRenderer.color = when {
            hpPercent > 0.5f -> Color.GREEN
            hpPercent > 0.25f -> Color.YELLOW
            else -> Color.RED
        }
        shapeRenderer.rect(barX, barY, barW * hpPercent, barH)
    }

    fun renderDebug(shapeRenderer: ShapeRenderer) {
        shapeRenderer.color = Color.GREEN
        shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)

        hurtbox.renderDebug(shapeRenderer)
    }
}
