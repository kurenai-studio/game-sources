package com.stickman.tower.companion

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.stickman.tower.character.Player
import com.stickman.tower.combat.FloatingText
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.vfx.ParticleManager
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Proyektil magis yang ditembakkan oleh Roh Pendamping.
 */
class FamiliarProjectile(
    var x: Float,
    var y: Float,
    val vx: Float,
    val vy: Float,
    val damage: Float,
    val color: Color,
    var lifetime: Float = 1.0f
) {
    var isDestroyed: Boolean = false

    fun update(delta: Float) {
        x += vx * delta
        y += vy * delta
        lifetime -= delta
        if (lifetime <= 0f) isDestroyed = true
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (isDestroyed) return
        shapeRenderer.setColor(color)
        shapeRenderer.circle(x, y, 0.18f, 16)
        shapeRenderer.setColor(Color.WHITE)
        shapeRenderer.circle(x, y, 0.08f, 12)
    }
}

/**
 * Entitas Roh Pendamping Tinta (Ink Familiar Companion).
 * Melayang secara cerdas di belakang bahu ksatria dengan gerakan bobbing kinematik,
 * memberikan bantuan pasif magnetik dan serangan sinergis saat bertarung.
 */
class InkFamiliar(
    var type: FamiliarType = FamiliarType.ARIA_WISP
) {
    var x: Float = 0f
    var y: Float = 0f
    var targetX: Float = 0f
    var targetY: Float = 0f
    var animTime: Float = 0f
    var attackCooldown: Float = 0f

    val projectiles = mutableListOf<FamiliarProjectile>()

    fun resetPosition(spawnX: Float, spawnY: Float) {
        x = spawnX
        y = spawnY + 1.2f
        targetX = x
        targetY = y
        projectiles.clear()
        attackCooldown = 0f
    }

    fun update(
        delta: Float,
        player: Player,
        enemies: List<Enemy>,
        boss: BossEnemy?,
        particleManager: ParticleManager,
        floatingTexts: MutableList<FloatingText>
    ) {
        if (type == FamiliarType.NONE) return

        animTime += delta
        if (attackCooldown > 0f) {
            attackCooldown = (attackCooldown - delta).coerceAtLeast(0f)
        }

        // 1. Follow Kinematics (Melayang di belakang bahu ksatria)
        val shoulderOffset = if (player.facingRight) -0.75f else 0.75f
        val bob = sin(animTime * 3.5f) * 0.14f
        targetX = player.position.x + player.width / 2f + shoulderOffset
        targetY = player.position.y + player.height + 0.35f + bob

        // Lerp halus
        x += (targetX - x) * (7.0f * delta).coerceIn(0f, 1f)
        y += (targetY - y) * (7.0f * delta).coerceIn(0f, 1f)

        // 2. Partikel Ekor Mengambang Lembut
        if (animTime % 0.12f < delta) {
            particleManager.spawnHitSparks(
                x + MathUtils.random(-0.05f, 0.05f),
                y + MathUtils.random(-0.05f, 0.05f),
                count = 1,
                color = type.primaryColor
            )
        }

        // 3. Logika Sinergi Khusus per Tipe Roh
        when (type) {
            FamiliarType.ARIA_WISP -> {
                // Prismatic Spark: tembakkan proyektil setiap kelipatan 10 kombo
                val combo = player.comboManager.comboCount
                if (combo > 0 && combo % 10 == 0 && attackCooldown <= 0f) {
                    val target = findClosestEnemy(x, y, enemies, boss, maxRange = 10f)
                    if (target != null) {
                        firePrismaticSpark(target.first, target.second, particleManager, floatingTexts)
                        attackCooldown = 1.25f
                    }
                }
            }
            FamiliarType.VULCAN_SPARK -> {
                // Percikan api pasif di sekitar tubuh familiar
                if (MathUtils.randomBoolean(0.04f)) {
                    particleManager.spawnHitSparks(x, y, count = 2, color = Color.GOLD)
                }
            }
            FamiliarType.PHANTOM_SHADOW -> {
                // Aura bayangan astral
                if (MathUtils.randomBoolean(0.03f)) {
                    particleManager.spawnHitSparks(x, y, count = 2, color = Color.VIOLET)
                }
            }
            FamiliarType.NONE -> {}
        }

        // 4. Update dan Deteksi Tabrakan Proyektil Familiar
        val projIter = projectiles.iterator()
        while (projIter.hasNext()) {
            val proj = projIter.next()
            proj.update(delta)

            // Cek tabrakan dengan musuh biasa
            for (enemy in enemies) {
                if (!enemy.health.isDead && !proj.isDestroyed) {
                    val dx = (enemy.position.x + enemy.width / 2f) - proj.x
                    val dy = (enemy.position.y + enemy.height / 2f) - proj.y
                    if (sqrt(dx * dx + dy * dy) < 0.65f) {
                        enemy.takeHit(proj.damage, if (proj.vx > 0) 1.2f else -1.2f, 1.0f)
                        proj.isDestroyed = true
                        particleManager.spawnHitSparks(proj.x, proj.y, count = 8, color = proj.color)
                        floatingTexts.add(FloatingText("✦ ${proj.damage.toInt()} ✦", proj.x, proj.y + 0.5f, Color.CYAN))
                        break
                    }
                }
            }

            // Cek tabrakan dengan Boss
            if (boss != null && !boss.health.isDead && !proj.isDestroyed) {
                val dx = (boss.position.x + boss.width / 2f) - proj.x
                val dy = (boss.position.y + boss.height / 2f) - proj.y
                if (sqrt(dx * dx + dy * dy) < 1.0f) {
                    boss.takeHit(proj.damage, if (proj.vx > 0) 0.8f else -0.8f, 0.5f)
                    proj.isDestroyed = true
                    particleManager.spawnHitSparks(proj.x, proj.y, count = 12, color = proj.color)
                    floatingTexts.add(FloatingText("✦ ${proj.damage.toInt()} ✦", proj.x, proj.y + 0.8f, Color.CYAN))
                }
            }

            if (proj.isDestroyed) {
                projIter.remove()
            }
        }
    }

    private fun findClosestEnemy(
        fx: Float,
        fy: Float,
        enemies: List<Enemy>,
        boss: BossEnemy?,
        maxRange: Float
    ): Pair<Float, Float>? {
        var closestDistSq = maxRange * maxRange
        var closestTarget: Pair<Float, Float>? = null

        for (enemy in enemies) {
            if (!enemy.health.isDead) {
                val ex = enemy.position.x + enemy.width / 2f
                val ey = enemy.position.y + enemy.height / 2f
                val dSq = (ex - fx) * (ex - fx) + (ey - fy) * (ey - fy)
                if (dSq < closestDistSq) {
                    closestDistSq = dSq
                    closestTarget = Pair(ex, ey)
                }
            }
        }

        if (boss != null && !boss.health.isDead) {
            val bx = boss.position.x + boss.width / 2f
            val by = boss.position.y + boss.height / 2f
            val dSq = (bx - fx) * (bx - fx) + (by - fy) * (by - fy)
            if (dSq < closestDistSq) {
                closestTarget = Pair(bx, by)
            }
        }

        return closestTarget
    }

    private fun firePrismaticSpark(
        tx: Float,
        ty: Float,
        particleManager: ParticleManager,
        floatingTexts: MutableList<FloatingText>
    ) {
        val dx = tx - x
        val dy = ty - y
        val dist = sqrt(dx * dx + dy * dy).coerceAtLeast(0.01f)
        val speed = 15f
        val vx = (dx / dist) * speed
        val vy = (dy / dist) * speed

        projectiles.add(
            FamiliarProjectile(
                x = x,
                y = y,
                vx = vx,
                vy = vy,
                damage = 16f,
                color = type.primaryColor
            )
        )
        particleManager.spawnHitSparks(x, y, count = 6, color = type.secondaryColor)
        floatingTexts.add(FloatingText("✨ PRISMATIC SPARK ✨", x, y + 0.5f, Color.CYAN, duration = 1.0f))
    }

    /**
     * Efek proc saat serangan pedang pemain mengenai musuh (Vulcan's Spark: Molten Burn).
     */
    fun onAttackHitProc(
        enemy: Enemy,
        particleManager: ParticleManager,
        floatingTexts: MutableList<FloatingText>
    ) {
        if (type == FamiliarType.VULCAN_SPARK) {
            if (MathUtils.randomBoolean(0.25f)) {
                val burnDmg = 14f
                enemy.health.takeDamage(burnDmg)
                particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height / 2f, count = 10, color = Color.ORANGE)
                floatingTexts.add(FloatingText("🔥 BARA PENEMPA (-${burnDmg.toInt()})", enemy.position.x, enemy.position.y + enemy.height + 0.4f, Color.ORANGE))
            }
        }
    }

    /**
     * Efek proc saat serangan pedang pemain mengenai Boss (Vulcan's Spark: Molten Burn).
     */
    fun onAttackHitBossProc(
        boss: BossEnemy,
        particleManager: ParticleManager,
        floatingTexts: MutableList<FloatingText>
    ) {
        if (type == FamiliarType.VULCAN_SPARK) {
            if (MathUtils.randomBoolean(0.25f)) {
                val burnDmg = 20f
                boss.health.takeDamage(burnDmg)
                particleManager.spawnHitSparks(boss.position.x + boss.width / 2f, boss.position.y + boss.height / 2f, count = 14, color = Color.ORANGE)
                floatingTexts.add(FloatingText("🔥 BARA PENEMPA (-${burnDmg.toInt()})", boss.position.x, boss.position.y + boss.height + 0.6f, Color.ORANGE))
            }
        }
    }

    /**
     * Efek proc saat Perfect Parry terjadi (Phantom Shadow: Echo Slash).
     */
    fun onParryProc(
        targetX: Float,
        targetY: Float,
        enemies: List<Enemy>,
        boss: BossEnemy?,
        particleManager: ParticleManager,
        floatingTexts: MutableList<FloatingText>
    ) {
        if (type == FamiliarType.PHANTOM_SHADOW) {
            val echoDmg = 24f
            // Serang musuh di sekitar target
            for (enemy in enemies) {
                if (!enemy.health.isDead) {
                    val ex = enemy.position.x + enemy.width / 2f
                    val ey = enemy.position.y + enemy.height / 2f
                    val dSq = (ex - targetX) * (ex - targetX) + (ey - targetY) * (ey - targetY)
                    if (dSq < 9f) { // Radius 3m
                        enemy.takeHit(echoDmg, 1.5f, 1.2f)
                    }
                }
            }
            if (boss != null && !boss.health.isDead) {
                val bx = boss.position.x + boss.width / 2f
                val by = boss.position.y + boss.height / 2f
                val dSq = (bx - targetX) * (bx - targetX) + (by - targetY) * (by - targetY)
                if (dSq < 12f) {
                    boss.takeHit(echoDmg, 0.8f, 0.5f)
                }
            }

            particleManager.spawnHitSparks(targetX, targetY, count = 18, color = Color.VIOLET)
            floatingTexts.add(FloatingText("⚔ ECHO SLASH (-${echoDmg.toInt()}) ⚔", targetX, targetY + 1.2f, Color.MAGENTA, duration = 1.4f))
        }
    }

    /**
     * Render prosedural wujud siluet roh pendamping.
     */
    fun render(shapeRenderer: ShapeRenderer) {
        if (type == FamiliarType.NONE) return

        // 1. Proyektil Aktif
        for (proj in projectiles) {
            proj.render(shapeRenderer)
        }

        // 2. Badan Inti Familiar (Pendaran Sinusoidal)
        val pulse = 1.0f + 0.12f * sin(animTime * 6f)
        val baseRadius = 0.22f * pulse

        // Outer Aura Glow
        shapeRenderer.setColor(type.primaryColor.r, type.primaryColor.g, type.primaryColor.b, 0.40f)
        shapeRenderer.circle(x, y, baseRadius * 1.6f, 20)

        // Core Sphere
        shapeRenderer.setColor(type.primaryColor)
        shapeRenderer.circle(x, y, baseRadius, 18)

        // Inner Bright Star Spark
        shapeRenderer.setColor(type.secondaryColor)
        shapeRenderer.circle(x, y, baseRadius * 0.45f, 12)

        // Aksesoris Visual per Tipe
        when (type) {
            FamiliarType.ARIA_WISP -> {
                // Mahkota Lentera Kecil di atas Orb
                shapeRenderer.setColor(Color.WHITE)
                shapeRenderer.triangle(
                    x - 0.08f, y + baseRadius,
                    x + 0.08f, y + baseRadius,
                    x, y + baseRadius + 0.12f
                )
            }
            FamiliarType.VULCAN_SPARK -> {
                // Cincin Bara Berputar
                val ringAngle = animTime * 4f
                val rx = x + MathUtils.cos(ringAngle) * 0.32f
                val ry = y + MathUtils.sin(ringAngle) * 0.20f
                shapeRenderer.setColor(Color.ORANGE)
                shapeRenderer.circle(rx, ry, 0.06f, 8)
            }
            FamiliarType.PHANTOM_SHADOW -> {
                // Sayap Bayangan Mini di kiri-kanan
                val wingFlap = sin(animTime * 8f) * 0.08f
                shapeRenderer.setColor(Color(0.2f, 0.05f, 0.3f, 0.85f))
                shapeRenderer.triangle(
                    x - 0.05f, y,
                    x - 0.30f, y + 0.15f + wingFlap,
                    x - 0.15f, y - 0.10f
                )
                shapeRenderer.triangle(
                    x + 0.05f, y,
                    x + 0.30f, y + 0.15f + wingFlap,
                    x + 0.15f, y - 0.10f
                )
            }
            FamiliarType.NONE -> {}
        }
    }
}
