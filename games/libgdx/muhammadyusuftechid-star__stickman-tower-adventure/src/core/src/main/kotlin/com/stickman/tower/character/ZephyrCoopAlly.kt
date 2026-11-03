package com.stickman.tower.character

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.stickman.tower.enemy.BossEnemy
import kotlin.math.sin

/**
 * ZephyrCoopAlly:
 * Rekan bertarung AI (Co-op Tag-Team Ally) yang aktif setelah Zephyr diselamatkan di Lantai 10.
 * Bertarung bersama Kaelen melawan Lady Vespera dengan mobilitas tinggi (Shadow Dash),
 * serangan belati ganda (Dual Dagger Flurry), serta interupsi hujan panah racun.
 */
class ZephyrCoopAlly(
    spawnX: Float,
    spawnY: Float
) {
    val position = Vector2(spawnX, spawnY)
    val velocity = Vector2(0f, 0f)
    val width = 0.8f
    val height = 1.9f
    val bounds = Rectangle(position.x, position.y, width, height)

    var facingRight = true
    var animTime = 0f
    private var attackCooldown = 0.8f
    private var isAttacking = false
    private var attackTimer = 0f
    private var dashCooldown = 3.0f

    var isActive: Boolean = true
    var onBossHit: ((damage: Float, isCritical: Boolean) -> Unit)? = null

    val attackBounds = Rectangle(0f, 0f, 1.8f, 1.6f)

    fun update(delta: Float, boss: BossEnemy?, playerPos: Vector2) {
        if (!isActive) return
        animTime += delta
        if (attackCooldown > 0f) attackCooldown -= delta
        if (dashCooldown > 0f) dashCooldown -= delta

        if (isAttacking) {
            attackTimer -= delta
            if (attackTimer <= 0f) {
                isAttacking = false
            }
        }

        if (boss == null || boss.health.isDead) {
            // Mengikuti pemain dengan tenang
            val distToPlayer = playerPos.x - position.x
            if (kotlin.math.abs(distToPlayer) > 2.5f) {
                val dir = if (distToPlayer > 0) 1f else -1f
                position.x += dir * 5.5f * delta
                facingRight = dir > 0
            }
            bounds.setPosition(position.x, position.y)
            return
        }

        val distToBoss = boss.position.x - position.x
        val absDist = kotlin.math.abs(distToBoss)
        facingRight = distToBoss > 0

        // AI Taktikal Melawan Lady Vespera
        if (absDist > 3.0f) {
            // Kejar bos dengan Shadow Dash jika siap, atau lari cepat
            val dir = if (distToBoss > 0) 1f else -1f
            val moveSpeed = if (dashCooldown <= 0f) 12.0f else 6.5f
            if (dashCooldown <= 0f) {
                dashCooldown = 3.5f
            }
            position.x += dir * moveSpeed * delta
        } else {
            // Berada dalam jangkauan serang belati
            if (attackCooldown <= 0f && !isAttacking) {
                isAttacking = true
                attackTimer = 0.35f
                attackCooldown = 0.9f

                // Tentukan hitbox serangan
                val atkX = if (facingRight) position.x else position.x - 1.2f
                attackBounds.set(atkX, position.y, 1.8f, height)

                // Serang bos jika terkena
                if (attackBounds.overlaps(boss.bounds)) {
                    val hitSuccess = boss.takeHit(28f, if (facingRight) 4f else -4f, 1.5f)
                    if (hitSuccess) {
                        onBossHit?.invoke(28f, false)
                    }
                    // Jika bos sedang dalam fase serang panah, interupsi konsentrasi bos
                    if (boss.health.currentHp > 0f && Math.random() < 0.45) {
                        boss.velocity.x *= 0.5f
                    }
                }
            }
        }

        // Batasi koordinat Y dasar lantai
        if (position.y < boss.position.y) {
            position.y = boss.position.y
        }
        bounds.setPosition(position.x, position.y)
    }

    fun render(shapeRenderer: ShapeRenderer) {
        val breath = sin(animTime * 4f) * 0.04f
        val headRadius = 0.22f
        val headY = position.y + height - headRadius + breath
        val neckY = headY - headRadius
        val pelvisY = position.y + 0.65f
        val shoulderY = neckY - 0.10f
        val cx = position.x + width / 2f

        // 1. Syal Bayangan Melayang di Belakang (Shadow Scarf Cyan)
        val scarfDir = if (facingRight) -1f else 1f
        val scarfWave = sin(animTime * 6f) * 0.12f
        shapeRenderer.setColor(0.2f, 0.9f, 0.85f, 0.75f)
        shapeRenderer.rectLine(cx, shoulderY + 0.05f, cx + scarfDir * 0.85f, shoulderY - 0.25f + scarfWave, 0.08f)
        shapeRenderer.rectLine(cx + scarfDir * 0.85f, shoulderY - 0.25f + scarfWave, cx + scarfDir * 1.35f, shoulderY - 0.45f + scarfWave * 1.5f, 0.06f)

        // 2. Kepala Siluet Zephyr dengan Topeng Bayangan
        shapeRenderer.setColor(0.12f, 0.14f, 0.18f, 1f)
        shapeRenderer.circle(cx, headY, headRadius, 14)

        // Mata Cyan Menyala Zephyr
        val eyeOffsetX = if (facingRight) 0.08f else -0.08f
        shapeRenderer.setColor(0.25f, 1f, 0.9f, 1f)
        shapeRenderer.circle(cx + eyeOffsetX, headY + 0.02f, 0.045f, 6)

        // 3. Badan & Tulang Belakang
        shapeRenderer.setColor(0.16f, 0.20f, 0.26f, 1f)
        shapeRenderer.rectLine(cx, neckY, cx, pelvisY, 0.09f)

        // 4. Kaki Bergerak
        val legSwing = if (isAttacking) 0.2f else sin(animTime * 8f) * 0.15f
        shapeRenderer.rectLine(cx, pelvisY, cx - 0.25f + legSwing, position.y, 0.07f)
        shapeRenderer.rectLine(cx, pelvisY, cx + 0.25f - legSwing, position.y, 0.07f)

        // 5. Lengan & Belati Kembar (Dual Daggers Cyan Glow)
        val handDir = if (facingRight) 1f else -1f
        val leftHandX = cx - handDir * 0.25f
        val rightHandX = cx + handDir * 0.35f
        val handY = shoulderY - 0.12f + (if (isAttacking) 0.25f else 0f)

        shapeRenderer.rectLine(cx, shoulderY, leftHandX, handY, 0.06f)
        shapeRenderer.rectLine(cx, shoulderY, rightHandX, handY, 0.06f)

        // Bilah Belati Kembar Cyan
        val daggerLength = if (isAttacking) 0.65f else 0.45f
        shapeRenderer.setColor(0.3f, 1f, 0.85f, 0.95f)
        shapeRenderer.rectLine(leftHandX, handY, leftHandX - handDir * 0.2f, handY - daggerLength, 0.06f)
        shapeRenderer.rectLine(rightHandX, handY, rightHandX + handDir * 0.45f, handY + daggerLength * 0.6f, 0.07f)

        // Efek Kilatan Tebasan saat menyerang
        if (isAttacking) {
            shapeRenderer.setColor(0.4f, 1f, 0.9f, 0.7f)
            shapeRenderer.arc(cx + handDir * 0.5f, handY + 0.1f, 0.85f, if (facingRight) -30f else 150f, 60f)
        }
    }
}
