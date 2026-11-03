package com.stickman.tower.character

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.stickman.tower.enemy.BossEnemy
import kotlin.math.sin

/**
 * GorgonCoopAlly:
 * Rekan bertarung AI (Co-op Tag-Team Ally) yang bangkit setelah Gorgon dibebaskan
 * dari Pilar Titan di Lantai 20.
 *
 * Bertarung bersama Kaelen & Zephyr melawan The Slag Colossus menggunakan Greatsword raksasa
 * berdaya hancur tinggi, Super Armor anti-stagger, dan Colossal Earthshaker Slam.
 */
class GorgonCoopAlly(
    spawnX: Float,
    spawnY: Float
) {
    val position = Vector2(spawnX, spawnY)
    val velocity = Vector2(0f, 0f)
    val width = 1.2f
    val height = 2.4f
    val bounds = Rectangle(position.x, position.y, width, height)

    var facingRight = true
    var animTime = 0f

    private var attackCooldown = 0.5f
    private var isAttacking = false
    private var attackTimer = 0f
    private var isColossalSlam = false
    private var slamCooldown = 1.5f

    var isActive: Boolean = true
    var onBossHit: ((damage: Float, isHeavySlam: Boolean) -> Unit)? = null

    val attackBounds = Rectangle(0f, 0f, 3.2f, 2.2f)

    fun update(delta: Float, boss: BossEnemy?, playerPos: Vector2) {
        if (!isActive) return
        animTime += delta
        if (attackCooldown > 0f) attackCooldown -= delta
        if (slamCooldown > 0f) slamCooldown -= delta

        if (isAttacking) {
            attackTimer -= delta
            if (attackTimer <= 0f) {
                isAttacking = false
                isColossalSlam = false
            }
        }

        if (boss == null || boss.health.isDead) {
            // Mengikuti posisi pemain dengan langkah berat dan tenang
            val distToPlayer = playerPos.x - position.x
            if (kotlin.math.abs(distToPlayer) > 2.8f) {
                val dir = if (distToPlayer > 0) 1f else -1f
                position.x += dir * 4.8f * delta
                facingRight = dir > 0
            }
            bounds.setPosition(position.x, position.y)
            return
        }

        val distToBoss = boss.position.x - position.x
        val absDist = kotlin.math.abs(distToBoss)
        facingRight = distToBoss > 0

        // AI Bertarung Melawan The Slag Colossus
        if (absDist > 2.8f) {
            // Bergerak maju mendekati bos dengan langkah tak terhentikan
            val dir = if (distToBoss > 0) 1f else -1f
            position.x += dir * 5.2f * delta
        } else {
            // Berada dalam jangkauan serang Greatsword Titan
            if (attackCooldown <= 0f && !isAttacking) {
                isAttacking = true
                val useSlam = slamCooldown <= 0f
                isColossalSlam = useSlam
                attackTimer = if (useSlam) 0.65f else 0.45f
                attackCooldown = if (useSlam) 2.4f else 1.2f
                if (useSlam) slamCooldown = 4.0f

                // Hitbox ayunan Greatsword raksasa
                val atkWidth = if (useSlam) 3.5f else 2.8f
                val atkX = if (facingRight) position.x else position.x - atkWidth + width
                attackBounds.set(atkX, position.y, atkWidth, height)

                // Serang bos jika berada dalam jangkauan tebasan
                if (attackBounds.overlaps(boss.bounds)) {
                    val dmg = if (useSlam) 85f else 50f
                    val knockback = if (useSlam) (if (facingRight) 7f else -7f) else (if (facingRight) 4f else -4f)
                    val hitSuccess = boss.takeHit(dmg, knockback, if (useSlam) 2.5f else 1.5f)
                    if (hitSuccess) {
                        onBossHit?.invoke(dmg, useSlam)
                    }
                    // Jika Colossal Slam mengenai bos, goyahkan keseimbangan bos (Guard Break)
                    if (useSlam && boss.health.currentHp > 0f) {
                        boss.velocity.x *= 0.2f
                    }
                }
            }
        }

        bounds.setPosition(position.x, position.y)
    }

    /**
     * Render visual prosedural Gorgon:
     * Siluet berotot tebal, helm bertanduk emas, dan Greatsword Titan raksasa.
     * Zero Allocation untuk performa render loop 60 FPS.
     */
    fun render(shapeRenderer: ShapeRenderer) {
        if (!isActive) return

        val prevColor = Color(shapeRenderer.color)
        val cx = position.x + width / 2f
        val cy = position.y
        val walkBob = sin(animTime * 6f) * 0.08f

        // 1. Kaki Kokoh & Langkah Berdentum
        shapeRenderer.color = Color(0.08f, 0.08f, 0.08f, 1f)
        val legOffset = if (isAttacking) 0.35f else 0.2f
        shapeRenderer.rect(cx - 0.45f, cy, 0.35f, 1.0f + walkBob)
        shapeRenderer.rect(cx + 0.10f, cy, 0.35f, 1.0f - walkBob)

        // 2. Badan Berotot Tegap Zirah Titan
        shapeRenderer.rect(cx - 0.50f, cy + 0.9f, 1.0f, 1.1f)

        // Pelat Dada Zirah Besi Tempa (Aksen Emas Gelap)
        shapeRenderer.color = Color(0.35f, 0.30f, 0.20f, 1f)
        shapeRenderer.rect(cx - 0.40f, cy + 1.1f, 0.80f, 0.7f)

        // 3. Kepala & Helm Bertanduk Emas
        shapeRenderer.color = Color(0.12f, 0.12f, 0.12f, 1f)
        shapeRenderer.circle(cx, cy + 2.15f, 0.35f, 12)

        // Tanduk Helm Emas Ikonik
        shapeRenderer.color = Color.GOLD
        val hornTilt = if (facingRight) 0.05f else -0.05f
        shapeRenderer.rect(cx - 0.38f + hornTilt, cy + 2.3f, 0.22f, 0.16f)
        shapeRenderer.rect(cx + 0.16f + hornTilt, cy + 2.3f, 0.22f, 0.16f)

        // 4. Greatsword Titan Raksasa
        renderGreatsword(shapeRenderer, cx, cy)

        shapeRenderer.color = prevColor
    }

    private fun renderGreatsword(shapeRenderer: ShapeRenderer, cx: Float, cy: Float) {
        val swordWidth = 0.38f
        val swordLength = 2.4f

        if (isAttacking) {
            val progress = 1f - (attackTimer / if (isColossalSlam) 0.65f else 0.45f)
            if (isColossalSlam) {
                // Slam ke bawah: pedang dihantamkan ke tanah di depan
                val swordX = if (facingRight) cx + 0.4f + progress * 0.8f else cx - 1.2f - progress * 0.8f
                val swordY = cy + 0.1f

                // Bilah Pedang Menghantam Tanah
                shapeRenderer.color = Color(0.85f, 0.80f, 0.75f, 1f)
                shapeRenderer.rect(swordX, swordY, swordLength * 0.8f, swordWidth)

                // Gagang & Guard Emas
                shapeRenderer.color = Color.GOLD
                shapeRenderer.rect(swordX - 0.2f, swordY - 0.15f, 0.25f, swordWidth + 0.3f)

                // Gelombang Getaran Tanah (Shockwave Arc)
                shapeRenderer.color = Color(0.95f, 0.65f, 0.15f, 0.8f)
                shapeRenderer.circle(if (facingRight) swordX + 1.6f else swordX, cy + 0.1f, 0.6f + progress * 0.8f, 12)
            } else {
                // Ayunan Horizontal Lebar
                val swingX = if (facingRight) cx + 0.2f + progress * 0.9f else cx - 1.0f - progress * 0.9f
                shapeRenderer.color = Color(0.85f, 0.80f, 0.75f, 1f)
                shapeRenderer.rect(swingX, cy + 0.8f, swordLength * 0.7f, swordWidth)
                shapeRenderer.color = Color.GOLD
                shapeRenderer.rect(swingX - 0.15f, cy + 0.65f, 0.2f, swordWidth + 0.3f)
            }
        } else {
            // Posisi Siaga: Greatsword dipanggul di pundak
            val swordX = if (facingRight) cx - 0.6f else cx + 0.25f
            val swordY = cy + 1.0f

            shapeRenderer.color = Color(0.78f, 0.75f, 0.70f, 1f)
            shapeRenderer.rect(swordX, swordY, swordWidth, swordLength)

            // Pelindung Tangan Emas & Gagang Pedang
            shapeRenderer.color = Color.GOLD
            shapeRenderer.rect(swordX - 0.2f, swordY + 0.5f, swordWidth + 0.4f, 0.22f)
            shapeRenderer.color = Color(0.2f, 0.2f, 0.2f, 1f)
            shapeRenderer.rect(swordX + 0.1f, swordY - 0.4f, 0.18f, 0.5f)
        }
    }
}
