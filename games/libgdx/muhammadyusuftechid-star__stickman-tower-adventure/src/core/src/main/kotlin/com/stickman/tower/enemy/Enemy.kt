package com.stickman.tower.enemy

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.character.Player
import com.stickman.tower.combat.Health
import com.stickman.tower.combat.Hitbox
import com.stickman.tower.combat.Hurtbox
import com.stickman.tower.combat.Projectile
import com.stickman.tower.physics.Platform
import com.stickman.tower.world.GameConfig
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

/**
 * Entitas Musuh Stickman dengan AI Tingkat Lanjut (10/10 AI Architecture):
 * Mendukung 4 Arketipe Taktikal:
 * - MELEE: Petarung belati agresif, lompat menyeberangi jurang (gap-jump), koordinasi token director.
 * - RANGED: Pemanah sihir kiting, menjaga jarak pandang bebas (LoS), mundur saat terdesak.
 * - FLYING: Siluet gargoyle/kelelawar udara melayang dengan sinewave, menukik tajam (swoop divebomb).
 * - SHIELDED: Pasukan perisai menara obsidian, kebal serangan frontal normal, memerlukan backstab/cross-up
 *             atau Guard Break (heavy combo 3 / skill / ultimate / parry).
 */
class Enemy(
    spawnX: Float,
    val spawnY: Float,
    val type: EnemyType = EnemyType.MELEE
) {
    val position = Vector2(spawnX, spawnY)
    val velocity = Vector2(0f, 0f)

    val width = 0.8f
    val height = 1.8f
    val bounds = Rectangle(position.x, position.y, width, height)

    // Komponen Combat
    val health = Health(
        maxHp = when (type) {
            EnemyType.RANGED -> 40f
            EnemyType.FLYING -> 35f
            EnemyType.SHIELDED -> 75f
            else -> 50f
        },
        invulnerableDuration = 0.25f
    )
    val hurtbox = Hurtbox(this)
    val hitbox = Hitbox(
        this,
        damage = when (type) {
            EnemyType.RANGED -> 8f
            EnemyType.FLYING -> 11f
            EnemyType.SHIELDED -> 16f
            else -> 12f
        },
        knockbackX = when (type) {
            EnemyType.SHIELDED -> 10.0f
            EnemyType.FLYING -> 6.0f
            else -> 5.5f
        },
        knockbackY = when (type) {
            EnemyType.SHIELDED -> 4.5f
            else -> 3.0f
        }
    )
    val projectiles = mutableListOf<Projectile>()

    // RPG Progression Reward
    val expReward: Int = when (type) {
        EnemyType.RANGED -> 35
        EnemyType.FLYING -> 30
        EnemyType.SHIELDED -> 45
        else -> 25
    }
    val goldReward: Int = when (type) {
        EnemyType.RANGED -> 15
        EnemyType.FLYING -> 12
        EnemyType.SHIELDED -> 20
        else -> 10
    }
    var rewardClaimed: Boolean = false

    // AI & Parameter Status
    var state = EnemyState.PATROL
        private set
    var facingRight = true
        private set

    private var patrolDir = 1f
    private var attackCooldown = 0f
    private var attackTimer = 0f
    private var hasFiredProjectile = false
    private var deadTimer = 0f
    private var animTime = 0f
    var stunTimer = 0f
        private set
    var poisonTimer = 0f
        private set
    var poisonDps = 0f
        private set
    private var poisonTickTimer = 0f

    // Shield Phalanx Mechanics
    var isGuardBroken: Boolean = false
        private set
    var guardBreakTimer: Float = 0f
        private set

    // Flying Mechanics
    private var swoopTargetX = 0f
    private var swoopTargetY = 0f

    fun applyPoison(duration: Float = 3.5f, dps: Float = 12f) {
        poisonTimer = duration.coerceAtLeast(poisonTimer)
        poisonDps = dps.coerceAtLeast(poisonDps)
    }

    var isGrounded = false
        private set
    var isDespawned = false
        private set

    companion object {
        const val DETECTION_RADIUS = 6.5f
        const val ATTACK_RADIUS = 1.3f
        const val PATROL_SPEED = 2.2f
        const val CHASE_SPEED = 4.2f

        const val ATTACK_WINDUP = 0.25f
        const val ATTACK_ACTIVE = 0.12f
        const val ATTACK_RECOVERY = 0.20f
        const val TOTAL_ATTACK_TIME = ATTACK_WINDUP + ATTACK_ACTIVE + ATTACK_RECOVERY

        val COLOR_MELEE_BASE = Color(0.85f, 0.2f, 0.25f, 1f)
        val COLOR_RANGED_BASE = Color(0.68f, 0.28f, 0.95f, 1f)
        val COLOR_FLYING_BASE = Color(0.38f, 0.18f, 0.55f, 1f)
        val COLOR_SHIELDED_BASE = Color(0.28f, 0.38f, 0.52f, 1f)

        val COLOR_RANGED_EYE = Color(0.92f, 0.45f, 1f, 1f)
        val COLOR_MELEE_EYE = Color(0.4f, 0f, 0f, 1f)
        val COLOR_BOW_WOOD = Color(0.55f, 0.40f, 0.25f, 1f)
        val COLOR_BOW_STRING = Color(0.85f, 0.85f, 0.85f, 0.8f)
        val COLOR_BOW_ARROW = Color(0.85f, 0.35f, 1f, 1f)
        val COLOR_ENEMY_SLASH = Color(1f, 0.15f, 0.15f, 0.8f)
        val COLOR_ENEMY_DAGGER = Color(0.35f, 0.35f, 0.4f, 1f)

        val COLOR_SHIELD_BODY = Color(0.18f, 0.22f, 0.28f, 1f)
        val COLOR_SHIELD_BORDER = Color(0.55f, 0.65f, 0.80f, 1f)
        val COLOR_SHIELD_RUNE = Color(0.35f, 0.85f, 1f, 0.9f)
        val COLOR_WING_MEMBRANE = Color(0.28f, 0.12f, 0.42f, 0.85f)

        val COLOR_BAR_FRAME = Color(0.06f, 0.08f, 0.12f, 0.85f)
        val COLOR_BAR_FILL = Color(0.85f, 0.18f, 0.22f, 0.95f)
        val COLOR_PROJECTILE_HIT = Color(0.75f, 0.25f, 1f, 1f)
    }

    /**
     * Memeriksa apakah perisai pelindung aktif dan mampu menangkis serangan.
     */
    fun isShieldGuarding(): Boolean {
        return type == EnemyType.SHIELDED &&
                state != EnemyState.STUNNED &&
                state != EnemyState.DEAD &&
                !isGuardBroken
    }

    /**
     * Memeriksa apakah serangan pemain datang dari arah depan perisai.
     * Jika menyerang dari belakang (cross-up / backstab), perisai tidak memblokir.
     */
    fun canBlockHitFrom(attackerX: Float): Boolean {
        if (!isShieldGuarding()) return false
        return if (facingRight) {
            attackerX >= position.x
        } else {
            attackerX <= position.x + width
        }
    }

    /**
     * Menghancurkan pertahanan perisai (Guard Break) akibat heavy attack atau combo.
     */
    fun breakGuard(duration: Float = 1.8f) {
        isGuardBroken = true
        guardBreakTimer = duration
        stun(duration)
    }

    fun update(delta: Float, player: Player, platforms: List<Platform>) {
        if (isDespawned) return

        animTime += delta
        health.update(delta)

        if (attackCooldown > 0f) {
            attackCooldown = (attackCooldown - delta).coerceAtLeast(0f)
        }

        if (guardBreakTimer > 0f) {
            guardBreakTimer = (guardBreakTimer - delta).coerceAtLeast(0f)
            if (guardBreakTimer <= 0f) {
                isGuardBroken = false
            }
        }

        // Ticking Poison DoT
        if (poisonTimer > 0f && !health.isDead) {
            poisonTimer = (poisonTimer - delta).coerceAtLeast(0f)
            poisonTickTimer += delta
            if (poisonTickTimer >= 0.5f) {
                poisonTickTimer = 0f
                health.takeDamage(poisonDps * 0.5f)
            }
        }

        // Perbarui Proyektil Ranged
        if (projectiles.isNotEmpty()) {
            val it = projectiles.iterator()
            while (it.hasNext()) {
                val proj = it.next()
                proj.update(delta)
                for (platform in platforms) {
                    if (platform.isOneWay) continue
                    if (!proj.isDestroyed && proj.bounds.overlaps(platform.bounds)) {
                        proj.isDestroyed = true
                        break
                    }
                }
                if (proj.isDestroyed) {
                    it.remove()
                }
            }
        }

        // Jika Musuh Mati
        if (health.isDead) {
            CombatDirector.releaseToken(this)
            state = EnemyState.DEAD
            hitbox.reset()
            hurtbox.isActive = false
            deadTimer += delta
            if (deadTimer >= 1.0f) {
                isDespawned = true
            }
            // Gravitasi saat roboh
            velocity.y += GameConfig.GRAVITY * delta
            resolveCollision(delta, platforms)
            return
        }

        // Perbarui posisi Hurtbox
        hurtbox.set(position.x, position.y, width, height)

        // 1. Eksekusi AI State Machine
        when (state) {
            EnemyState.PATROL -> updatePatrolState(delta, player, platforms)
            EnemyState.CHASE -> updateChaseState(delta, player, platforms)
            EnemyState.ATTACK -> updateAttackState(delta, player)
            EnemyState.HURT -> updateHurtState(delta)
            EnemyState.STUNNED -> updateStunnedState(delta)
            EnemyState.DEAD -> {}
        }

        // 2. Gravitasi & Fisika (Tipe FLYING mengabaikan gravitasi kecuali saat stun/hurt)
        if (type == EnemyType.FLYING && state != EnemyState.STUNNED && state != EnemyState.HURT) {
            // Gaya aerodinamis melayang: menjaga elevasi melayang
            velocity.y = velocity.y.coerceIn(-10f, 10f)
        } else {
            velocity.y += GameConfig.GRAVITY * delta
            velocity.y = velocity.y.coerceAtLeast(-25f)
        }

        // 3. Resolusi Collision
        resolveCollision(delta, platforms)
    }

    private fun updatePatrolState(delta: Float, player: Player, platforms: List<Platform>) {
        val detectRadius = when (type) {
            EnemyType.RANGED -> 8.5f
            EnemyType.FLYING -> 8.0f
            else -> DETECTION_RADIUS
        }
        val dx = player.position.x - position.x
        val dy = abs(player.position.y - position.y)

        if (abs(dx) < detectRadius && dy < (if (type == EnemyType.FLYING) 4.5f else 3.2f) && !player.health.isDead) {
            state = EnemyState.CHASE
            return
        }

        if (type == EnemyType.FLYING) {
            // Hover Sinewave di udara
            val targetY = spawnY + sin(animTime * 3.0f) * 0.45f
            velocity.y = MathUtils.lerp(velocity.y, (targetY - position.y) * 4f, 8f * delta)

            // Balik arah patrol jika bergerak terlalu jauh dari spawn
            if (abs(position.x - (bounds.x)) > 5.0f || (patrolDir > 0 && position.x > 32f) || (patrolDir < 0 && position.x < -8f)) {
                patrolDir = -patrolDir
            }
        } else {
            // Deteksi Tepi Platform / Jurang (Cliff Avoidance)
            if (isGrounded) {
                val checkX = if (patrolDir > 0) position.x + width + 0.2f else position.x - 0.2f
                val checkY = position.y - 0.3f
                val groundAhead = platforms.any { checkX >= it.left && checkX <= it.right && checkY >= it.bottom && checkY <= it.top + 0.1f }

                if (!groundAhead) {
                    patrolDir = -patrolDir
                }
            }
        }

        facingRight = patrolDir > 0
        velocity.x = patrolDir * PATROL_SPEED
    }

    private fun updateChaseState(delta: Float, player: Player, platforms: List<Platform>) {
        val dx = player.position.x - position.x
        val dy = abs(player.position.y - position.y)
        val dist = abs(dx)
        val maxSight = when (type) {
            EnemyType.RANGED -> 12.0f
            EnemyType.FLYING -> 11.0f
            else -> DETECTION_RADIUS * 1.3f
        }

        // Jika pemain kabur terlalu jauh atau pemain sudah mati
        if (dist > maxSight || dy > (if (type == EnemyType.FLYING) 6.0f else 4.2f) || player.health.isDead) {
            state = EnemyState.PATROL
            velocity.x = 0f
            return
        }

        facingRight = dx > 0

        // =====================================================================
        // ARKETIPE 1: RANGED (Pemanah Sihir Amethyst)
        // =====================================================================
        if (type == EnemyType.RANGED) {
            if (dist < 3.2f) {
                // Kiting: Mundur menjauh jika ada pijakan
                val retreatDir = if (dx > 0) -1f else 1f
                var canRetreat = true
                if (isGrounded) {
                    val checkX = if (retreatDir > 0) position.x + width + 0.25f else position.x - 0.25f
                    val checkY = position.y - 0.3f
                    canRetreat = platforms.any { checkX >= it.left && checkX <= it.right && checkY >= it.bottom && checkY <= it.top + 0.1f }
                }
                velocity.x = if (canRetreat) retreatDir * (PATROL_SPEED * 1.3f) else 0f
            } else if (dist > 7.2f) {
                // Maju mendekat
                val approachDir = if (dx > 0) 1f else -1f
                var canApproach = true
                if (isGrounded) {
                    val checkX = if (approachDir > 0) position.x + width + 0.25f else position.x - 0.25f
                    val checkY = position.y - 0.3f
                    canApproach = platforms.any { checkX >= it.left && checkX <= it.right && checkY >= it.bottom && checkY <= it.top + 0.1f }
                }
                velocity.x = if (canApproach) approachDir * (CHASE_SPEED * 0.85f) else 0f
            } else {
                // Sweet spot tembakan: minta token ke CombatDirector
                val clearShot = hasLineOfSight(player, platforms)
                if (clearShot) {
                    velocity.x = MathUtils.lerp(velocity.x, 0f, 15f * delta)
                    if (attackCooldown <= 0f && dy < 2.5f) {
                        if (CombatDirector.requestRangedToken(this)) {
                            state = EnemyState.ATTACK
                            attackTimer = 0f
                            hasFiredProjectile = false
                            velocity.x = 0f
                        } else {
                            // Belum dapat token: Orbiting/menunggu giliran
                            velocity.x = sin(animTime * 4f) * 1.2f
                        }
                    }
                } else {
                    val approachDir = if (dx > 0) 1f else -1f
                    var canReposition = true
                    if (isGrounded) {
                        val checkX = if (approachDir > 0) position.x + width + 0.25f else position.x - 0.25f
                        val checkY = position.y - 0.3f
                        canReposition = platforms.any { checkX >= it.left && checkX <= it.right && checkY >= it.bottom && checkY <= it.top + 0.1f }
                    }
                    velocity.x = if (canReposition) approachDir * (PATROL_SPEED * 1.1f) else 0f
                }
            }
            return
        }

        // =====================================================================
        // ARKETIPE 2: FLYING (Gargoyle / Kelelawar Udara)
        // =====================================================================
        if (type == EnemyType.FLYING) {
            // Melayang di atas kepala pemain (+2.2m) dengan osilasi sinewave
            val targetHoverY = player.position.y + 2.2f + sin(animTime * 4.5f) * 0.35f
            velocity.y = MathUtils.lerp(velocity.y, (targetHoverY - position.y) * 4.5f, 10f * delta)

            if (dist <= 3.8f && dy <= 3.2f) {
                // Dalam jarak serangan menukik (Swoop Attack)
                if (attackCooldown <= 0f) {
                    if (CombatDirector.requestMeleeToken(this)) {
                        state = EnemyState.ATTACK
                        attackTimer = 0f
                        swoopTargetX = player.position.x
                        swoopTargetY = player.position.y
                        hitbox.reset()
                    } else {
                        // Tidak ada token: Orbiting di udara di atas pemain
                        val orbitVx = if (dx > 0) -1.8f else 1.8f
                        velocity.x = MathUtils.lerp(velocity.x, orbitVx, 6f * delta)
                    }
                } else {
                    // Masih cooldown: melayang menjaga jarak
                    val hoverVx = (if (dx > 0) 1f else -1f) * 1.5f
                    velocity.x = MathUtils.lerp(velocity.x, hoverVx, 8f * delta)
                }
            } else {
                // Terbang mendekati posisi horizontal pemain
                val flyDir = if (dx > 0) 1f else -1f
                velocity.x = MathUtils.lerp(velocity.x, flyDir * (CHASE_SPEED * 0.95f), 10f * delta)
            }
            return
        }

        // =====================================================================
        // ARKETIPE 3 & 4: MELEE & SHIELDED (Petarung & Ksatria Perisai)
        // =====================================================================
        val attackTriggerDist = if (type == EnemyType.SHIELDED) 1.5f else ATTACK_RADIUS

        if (dist <= attackTriggerDist && dy < 1.8f) {
            if (attackCooldown <= 0f) {
                if (CombatDirector.requestMeleeToken(this)) {
                    state = EnemyState.ATTACK
                    attackTimer = 0f
                    hitbox.reset()
                    velocity.x = 0f
                } else {
                    // Orbiting / Flanking: Berjalan pelan mengitari pemain tanpa menumpuk serangan
                    val flankDir = if (sin(animTime * 3f) > 0) 1f else -1f
                    velocity.x = MathUtils.lerp(velocity.x, flankDir * (PATROL_SPEED * 0.7f), 10f * delta)
                }
            } else {
                velocity.x = MathUtils.lerp(velocity.x, 0f, 15f * delta)
            }
            return
        }

        // Navigasi Mengejar Pemain: Gap Jumping & Drop-Through Platform
        val chaseDir = if (dx > 0) 1f else -1f
        var canAdvance = true

        if (isGrounded) {
            val checkX = if (chaseDir > 0) position.x + width + 0.25f else position.x - 0.25f
            val checkY = position.y - 0.3f
            canAdvance = platforms.any { checkX >= it.left && checkX <= it.right && checkY >= it.bottom && checkY <= it.top + 0.1f }
        }

        if (!canAdvance && isGrounded) {
            // Tepi Jurang Terdeteksi: Cek apakah ada platform seberang yang dapat dilompati (Gap Jump)
            val reachablePlatform = platforms.any { plat ->
                val isForward = if (chaseDir > 0) plat.left > position.x else plat.right < position.x
                val gapDist = if (chaseDir > 0) plat.left - (position.x + width) else position.x - plat.right
                val heightDiff = plat.top - position.y
                isForward && gapDist in 0.2f..3.8f && heightDiff in -2.0f..2.5f
            }

            if (reachablePlatform && dist > 1.2f) {
                // Melompat menyeberangi jurang ke arah pemain!
                velocity.y = 11.2f
                velocity.x = chaseDir * (CHASE_SPEED * 1.2f)
                isGrounded = false
            } else {
                // Jurang terlalu lebar / mematikan: berhenti di tepi
                velocity.x = MathUtils.lerp(velocity.x, 0f, 15f * delta)
            }
        } else {
            // Drop-Through: Jika pemain berada di bawah dan musuh berdiri di One-Way Platform
            if (isGrounded && player.position.y < position.y - 1.8f && dist < 3.5f) {
                val standingOnOneWay = platforms.any { it.isOneWay && position.y in (it.top - 0.2f)..(it.top + 0.2f) && position.x + width >= it.left && position.x <= it.right }
                if (standingOnOneWay) {
                    position.y -= 0.35f
                    velocity.y = -3.0f
                    isGrounded = false
                }
            }

            val targetVx = chaseDir * (if (type == EnemyType.SHIELDED) CHASE_SPEED * 0.8f else CHASE_SPEED)
            velocity.x = MathUtils.lerp(velocity.x, targetVx, 12f * delta)
        }
    }

    private fun updateAttackState(delta: Float, player: Player) {
        attackTimer += delta

        when (type) {
            EnemyType.RANGED -> {
                velocity.x = 0f
                val rangedWindup = 0.40f
                val rangedTotalTime = 0.70f

                if (attackTimer >= rangedWindup && !hasFiredProjectile) {
                    hasFiredProjectile = true
                    val projVx = if (facingRight) 9.5f else -9.5f
                    val projX = if (facingRight) position.x + width + 0.15f else position.x - 0.95f
                    val projY = position.y + height * 0.62f
                    projectiles.add(
                        Projectile(
                            startX = projX,
                            startY = projY,
                            velocityX = projVx,
                            velocityY = 0f,
                            damage = 14f,
                            width = 0.80f,
                            height = 0.35f,
                            maxLifetime = 2.5f,
                            color = COLOR_PROJECTILE_HIT
                        )
                    )
                    AudioManager.playSlashLight()
                }

                if (attackTimer >= rangedTotalTime) {
                    CombatDirector.releaseToken(this)
                    attackCooldown = 1.6f + MathUtils.random(0.1f, 0.4f)
                    state = EnemyState.CHASE
                }
            }

            EnemyType.FLYING -> {
                // Swoop Divebomb: Menukik tajam ke arah pemain lalu menanjak kembali
                val diveWindup = 0.25f
                val diveActive = 0.40f
                val diveRecovery = 0.30f
                val swoopDir = if (facingRight) 1f else -1f

                when {
                    attackTimer < diveWindup -> {
                        // Ancang-ancang di udara
                        velocity.x = MathUtils.lerp(velocity.x, 0f, 15f * delta)
                        velocity.y = MathUtils.lerp(velocity.y, 2.0f, 10f * delta)
                        hitbox.isActive = false
                    }
                    attackTimer < diveWindup + diveActive -> {
                        // Menukik kencang ke bawah (Divebomb swoop)
                        velocity.x = swoopDir * 8.5f
                        velocity.y = -6.5f

                        val hbW = 1.3f
                        val hbH = 1.2f
                        val hbX = if (facingRight) position.x + width * 0.4f else position.x - hbW + width * 0.6f
                        val hbY = position.y + 0.1f
                        hitbox.set(hbX, hbY, hbW, hbH, active = true)
                    }
                    attackTimer < diveWindup + diveActive + diveRecovery -> {
                        // Menanjak kembali ke atas (Ascend pull-up)
                        hitbox.isActive = false
                        velocity.x = swoopDir * 3.5f
                        velocity.y = 7.5f
                    }
                    else -> {
                        hitbox.reset()
                        CombatDirector.releaseToken(this)
                        attackCooldown = 1.4f + MathUtils.random(0.1f, 0.3f)
                        state = EnemyState.CHASE
                    }
                }
            }

            EnemyType.SHIELDED -> {
                // Shield Bash: Hantaman dorongan kuat perisai
                val shieldWindup = 0.35f
                val shieldActive = 0.18f
                val shieldRecovery = 0.35f
                velocity.x = 0f

                when {
                    attackTimer < shieldWindup -> {
                        hitbox.isActive = false
                    }
                    attackTimer < shieldWindup + shieldActive -> {
                        val hbW = 1.4f
                        val hbH = 1.5f
                        val hbX = if (facingRight) position.x + width * 0.7f else position.x - hbW + width * 0.3f
                        val hbY = position.y + 0.25f
                        hitbox.set(hbX, hbY, hbW, hbH, active = true)
                    }
                    attackTimer < shieldWindup + shieldActive + shieldRecovery -> {
                        hitbox.isActive = false
                    }
                    else -> {
                        hitbox.reset()
                        CombatDirector.releaseToken(this)
                        attackCooldown = 1.3f + MathUtils.random(0.1f, 0.3f)
                        state = EnemyState.CHASE
                    }
                }
            }

            EnemyType.MELEE -> {
                velocity.x = 0f
                when {
                    attackTimer < ATTACK_WINDUP -> {
                        hitbox.isActive = false
                    }
                    attackTimer < ATTACK_WINDUP + ATTACK_ACTIVE -> {
                        val hbW = 1.25f
                        val hbH = 1.25f
                        val hbX = if (facingRight) position.x + width * 0.6f else position.x - hbW + width * 0.4f
                        val hbY = position.y + 0.35f
                        hitbox.set(hbX, hbY, hbW, hbH, active = true)
                    }
                    attackTimer < TOTAL_ATTACK_TIME -> {
                        hitbox.isActive = false
                    }
                    else -> {
                        hitbox.reset()
                        CombatDirector.releaseToken(this)
                        attackCooldown = 1.0f + MathUtils.random(0.1f, 0.35f)
                        state = EnemyState.CHASE
                    }
                }
            }
        }
    }

    private fun updateHurtState(delta: Float) {
        CombatDirector.releaseToken(this)
        velocity.x = MathUtils.lerp(velocity.x, 0f, 10f * delta)
        if (!health.isFlashing) {
            state = EnemyState.CHASE
        }
    }

    private fun updateStunnedState(delta: Float) {
        CombatDirector.releaseToken(this)
        velocity.x = MathUtils.lerp(velocity.x, 0f, 12f * delta)
        hitbox.isActive = false
        stunTimer = (stunTimer - delta).coerceAtLeast(0f)
        if (stunTimer <= 0f) {
            state = EnemyState.CHASE
        }
    }

    private fun resolveCollision(delta: Float, platforms: List<Platform>) {
        // Sumbu X
        position.x += velocity.x * delta
        bounds.setPosition(position.x, position.y)

        for (platform in platforms) {
            if (platform.isOneWay) continue

            if (bounds.overlaps(platform.bounds)) {
                if (velocity.x > 0f) {
                    position.x = platform.left - width
                    patrolDir = -1f
                } else if (velocity.x < 0f) {
                    position.x = platform.right
                    patrolDir = 1f
                }
                velocity.x = 0f
                bounds.setPosition(position.x, position.y)
            }
        }

        // Sumbu Y
        val previousY = position.y
        isGrounded = false
        position.y += velocity.y * delta
        bounds.setPosition(position.x, position.y)

        for (platform in platforms) {
            if (platform.isOneWay) {
                if (velocity.y <= 0f && previousY >= platform.top - 0.20f) {
                    if (bounds.overlaps(platform.bounds)) {
                        position.y = platform.top
                        velocity.y = 0f
                        isGrounded = true
                        bounds.setPosition(position.x, position.y)
                    }
                }
                continue
            }

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
     * Menerima damage dari serangan pemain.
     */
    fun takeHit(damage: Float, knockX: Float, knockY: Float): Boolean {
        CombatDirector.releaseToken(this)
        if (health.takeDamage(damage)) {
            velocity.x = knockX
            velocity.y = knockY

            if (health.isDead) {
                state = EnemyState.DEAD
                hitbox.reset()
                hurtbox.isActive = false
                velocity.x = 0f
            } else if (state != EnemyState.STUNNED || stunTimer <= 0f) {
                state = EnemyState.HURT
                hitbox.isActive = false
            }
            return true
        }
        return false
    }

    /**
     * Memeriksa Line of Sight proyektil terhadap pemain.
     */
    fun hasLineOfSight(player: Player, platforms: List<Platform>): Boolean {
        val startX = if (facingRight) position.x + width else position.x
        val endX = if (facingRight) player.position.x else player.position.x + player.width
        val minX = kotlin.math.min(startX, endX)
        val maxX = kotlin.math.max(startX, endX)

        val arrowY = position.y + height * 0.62f

        for (platform in platforms) {
            if (platform.isOneWay) continue

            val overlapsX = platform.right > minX && platform.left < maxX
            val overlapsY = arrowY >= platform.bottom && arrowY <= platform.top

            if (overlapsX && overlapsY) {
                return false
            }
        }
        return true
    }

    /**
     * Mengaktifkan status Guard Break / Stun akibat Perfect Parry dari pemain.
     */
    fun stun(duration: Float = 1.5f) {
        CombatDirector.releaseToken(this)
        state = EnemyState.STUNNED
        stunTimer = duration
        velocity.x = 0f
        hitbox.isActive = false
        attackCooldown = 0.8f
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (isDespawned) return

        if (projectiles.isNotEmpty()) {
            for (proj in projectiles) {
                proj.render(shapeRenderer)
            }
        }

        val centerX = position.x + width / 2f
        val footY = position.y
        val headRadius = 0.22f
        val headCenterY = position.y + height - headRadius - 0.05f
        val neckY = headCenterY - headRadius
        val pelvisY = position.y + 0.75f
        val shoulderY = neckY - 0.15f
        val lookDir = if (facingRight) 1f else -1f

        val baseColor = when (type) {
            EnemyType.RANGED -> COLOR_RANGED_BASE
            EnemyType.FLYING -> COLOR_FLYING_BASE
            EnemyType.SHIELDED -> COLOR_SHIELDED_BASE
            else -> COLOR_MELEE_BASE
        }
        val bodyColor = if (health.isFlashing) Color.WHITE else baseColor
        shapeRenderer.color = bodyColor

        if (state == EnemyState.DEAD) {
            val fallProgress = (deadTimer / 1.0f).coerceIn(0f, 1f)
            val corpseAlpha = 1f - fallProgress
            shapeRenderer.setColor(bodyColor.r, bodyColor.g, bodyColor.b, corpseAlpha)
            shapeRenderer.rectLine(centerX - 0.5f, footY + 0.1f, centerX + 0.5f, footY + 0.1f, 0.1f)
            shapeRenderer.circle(centerX + 0.5f * lookDir, footY + 0.15f, 0.18f, 12)
            return
        }

        // =====================================================================
        // SAYAP KELELAWAR / GARGOYLE UNTUK TIPE FLYING
        // =====================================================================
        if (type == EnemyType.FLYING) {
            val wingFlap = sin(animTime * 14f) * 0.45f
            shapeRenderer.color = COLOR_WING_MEMBRANE

            // Sayap Kiri
            val wingLeftTipX = centerX - 0.85f
            val wingLeftTipY = shoulderY + 0.5f + wingFlap
            shapeRenderer.triangle(centerX, shoulderY, wingLeftTipX, wingLeftTipY, centerX - 0.35f, shoulderY - 0.2f)

            // Sayap Kanan
            val wingRightTipX = centerX + 0.85f
            val wingRightTipY = shoulderY + 0.5f + wingFlap
            shapeRenderer.triangle(centerX, shoulderY, wingRightTipX, wingRightTipY, centerX + 0.35f, shoulderY - 0.2f)
        }

        // 1. Kepala
        shapeRenderer.color = bodyColor
        shapeRenderer.circle(centerX, headCenterY, headRadius, 16)

        // 2. Mata Menyala
        val isTelegraphing = state == EnemyState.ATTACK && attackTimer < when (type) {
            EnemyType.RANGED -> 0.40f
            EnemyType.FLYING -> 0.25f
            EnemyType.SHIELDED -> 0.35f
            else -> ATTACK_WINDUP
        }
        val eyeColor = when {
            state == EnemyState.STUNNED -> Color.GOLD
            isTelegraphing -> Color.YELLOW
            type == EnemyType.RANGED -> COLOR_RANGED_EYE
            type == EnemyType.FLYING -> Color.SCARLET
            type == EnemyType.SHIELDED -> Color.CYAN
            else -> COLOR_MELEE_EYE
        }
        shapeRenderer.color = eyeColor
        val eyeX = centerX + (headRadius * 0.45f * lookDir)
        val eyeY = headCenterY + 0.04f
        shapeRenderer.circle(eyeX, eyeY, if (isTelegraphing) 0.07f else 0.045f, 8)

        // Visual Stun Stars
        if (state == EnemyState.STUNNED) {
            shapeRenderer.color = Color.GOLD
            val orbitRadius = 0.26f
            for (i in 0 until 3) {
                val angle = animTime * 6.5f + (i * 2.094f)
                val starX = centerX + cos(angle.toDouble()).toFloat() * orbitRadius
                val starY = headCenterY + headRadius + 0.22f + sin(angle.toDouble()).toFloat() * 0.08f
                shapeRenderer.circle(starX, starY, 0.04f, 6)
            }
        }

        // Peringatan Tanda Seru Bahaya
        if (isTelegraphing) {
            shapeRenderer.color = Color.YELLOW
            shapeRenderer.rectLine(centerX, headCenterY + 0.4f, centerX, headCenterY + 0.6f, 0.04f)
            shapeRenderer.circle(centerX, headCenterY + 0.32f, 0.03f, 6)
        }

        // 3. Tulang Belakang (Spine)
        shapeRenderer.color = bodyColor
        shapeRenderer.rectLine(centerX, neckY, centerX, pelvisY, 0.08f)

        // 4. Kaki Berjalan / Cakar Udara
        if (type == EnemyType.FLYING) {
            // Cakar gargoyle menggantung di udara
            shapeRenderer.color = bodyColor
            shapeRenderer.rectLine(centerX - 0.1f, pelvisY, centerX - 0.15f, footY + 0.3f, 0.06f)
            shapeRenderer.rectLine(centerX + 0.1f, pelvisY, centerX + 0.15f, footY + 0.3f, 0.06f)
        } else {
            var legSwing = 0f
            if (state == EnemyState.PATROL || state == EnemyState.CHASE) {
                val freq = if (state == EnemyState.CHASE) 15f else 8f
                legSwing = sin(animTime * freq) * 0.32f
            }
            val legLeftFootX = centerX - 0.12f * lookDir + (legSwing * lookDir)
            val legRightFootX = centerX + 0.12f * lookDir - (legSwing * lookDir)
            shapeRenderer.rectLine(centerX, pelvisY, legLeftFootX, footY, 0.07f)
            shapeRenderer.rectLine(centerX, pelvisY, legRightFootX, footY, 0.07f)
        }

        // 5. Tangan dan Senjata Sesuai Arketipe
        when (type) {
            EnemyType.RANGED -> {
                val bowX = centerX + 0.35f * lookDir
                val bowTopY = shoulderY + 0.35f
                val bowMidY = shoulderY
                val bowBotY = shoulderY - 0.35f

                shapeRenderer.color = COLOR_BOW_WOOD
                shapeRenderer.rectLine(bowX, bowMidY, bowX + 0.15f * lookDir, bowTopY, 0.05f)
                shapeRenderer.rectLine(bowX, bowMidY, bowX + 0.15f * lookDir, bowBotY, 0.05f)
                shapeRenderer.color = COLOR_BOW_STRING
                shapeRenderer.rectLine(bowX + 0.15f * lookDir, bowTopY, bowX + 0.15f * lookDir, bowBotY, 0.03f)

                shapeRenderer.color = bodyColor
                shapeRenderer.rectLine(centerX, shoulderY, bowX, bowMidY, 0.06f)

                if (isTelegraphing) {
                    val arrowTipX = bowX + 0.45f * lookDir
                    val arrowTailX = bowX - 0.20f * lookDir
                    shapeRenderer.color = COLOR_BOW_ARROW
                    shapeRenderer.rectLine(arrowTailX, bowMidY, arrowTipX, bowMidY, 0.06f)
                    val pulse = (sin(animTime * 15f) + 1f) * 0.03f
                    shapeRenderer.circle(arrowTipX, bowMidY, 0.10f + pulse, 10)
                }
            }

            EnemyType.SHIELDED -> {
                // Perisai Menara Obsidian di Tangan Depan
                val shieldW = 0.32f
                val shieldH = 1.35f
                val shieldThrust = if (state == EnemyState.ATTACK && attackTimer >= 0.35f && attackTimer < 0.53f) 0.35f * lookDir else 0f
                val shieldX = centerX + (0.35f * lookDir) + shieldThrust - (if (lookDir < 0) shieldW else 0f)
                val shieldY = position.y + 0.22f

                // Lengan memegang perisai
                shapeRenderer.color = bodyColor
                shapeRenderer.rectLine(centerX, shoulderY, shieldX + (shieldW / 2f), shieldY + shieldH * 0.6f, 0.08f)

                // Badan Perisai Baja Obsidian
                shapeRenderer.color = if (isGuardBroken) Color.GRAY else COLOR_SHIELD_BODY
                shapeRenderer.rect(shieldX, shieldY, shieldW, shieldH)

                // Bingkai Perisai
                shapeRenderer.color = if (isGuardBroken) Color.DARK_GRAY else COLOR_SHIELD_BORDER
                shapeRenderer.rectLine(shieldX, shieldY, shieldX + shieldW, shieldY, 0.04f)
                shapeRenderer.rectLine(shieldX, shieldY + shieldH, shieldX + shieldW, shieldY + shieldH, 0.04f)
                shapeRenderer.rectLine(shieldX, shieldY, shieldX, shieldY + shieldH, 0.04f)
                shapeRenderer.rectLine(shieldX + shieldW, shieldY, shieldX + shieldW, shieldY + shieldH, 0.04f)

                // Runic Sigil di Tengah Perisai
                if (!isGuardBroken) {
                    shapeRenderer.color = COLOR_SHIELD_RUNE
                    val runeMidY = shieldY + shieldH * 0.5f
                    shapeRenderer.rectLine(shieldX + 0.06f, runeMidY, shieldX + shieldW - 0.06f, runeMidY, 0.04f)
                    shapeRenderer.rectLine(shieldX + shieldW * 0.5f, runeMidY - 0.22f, shieldX + shieldW * 0.5f, runeMidY + 0.22f, 0.04f)
                }
            }

            EnemyType.FLYING -> {
                // Cakar Tajam di Tangan
                val talonX = centerX + 0.35f * lookDir
                val talonY = shoulderY - 0.3f
                shapeRenderer.color = bodyColor
                shapeRenderer.rectLine(centerX, shoulderY, talonX, talonY, 0.06f)
                shapeRenderer.color = Color.RED
                shapeRenderer.rectLine(talonX, talonY, talonX + 0.15f * lookDir, talonY - 0.15f, 0.05f)
            }

            EnemyType.MELEE -> {
                val armHandX: Float
                val armHandY: Float
                val weaponTipX: Float
                val weaponTipY: Float

                if (state == EnemyState.ATTACK && attackTimer >= ATTACK_WINDUP && attackTimer < ATTACK_WINDUP + ATTACK_ACTIVE) {
                    armHandX = centerX + 0.4f * lookDir
                    armHandY = shoulderY - 0.05f
                    weaponTipX = armHandX + 0.8f * lookDir
                    weaponTipY = armHandY - 0.25f

                    shapeRenderer.color = COLOR_ENEMY_SLASH
                    shapeRenderer.rectLine(armHandX, armHandY + 0.2f, weaponTipX, weaponTipY - 0.1f, 0.08f)
                } else {
                    armHandX = centerX + 0.22f * lookDir
                    armHandY = shoulderY - 0.35f
                    weaponTipX = armHandX + 0.5f * lookDir
                    weaponTipY = armHandY - 0.3f
                }

                shapeRenderer.color = bodyColor
                shapeRenderer.rectLine(centerX, shoulderY, armHandX, armHandY, 0.06f)
                shapeRenderer.color = COLOR_ENEMY_DAGGER
                shapeRenderer.rectLine(armHandX, armHandY, weaponTipX, weaponTipY, 0.07f)
            }
        }

        // 6. Mini HP Bar Musuh
        renderHealthBar(shapeRenderer, centerX, position.y + height + 0.2f)
    }

    private fun renderHealthBar(shapeRenderer: ShapeRenderer, centerX: Float, barY: Float) {
        if (health.isDead || (health.currentHp >= health.maxHp && state == EnemyState.PATROL)) return

        val barW = 0.85f
        val barH = 0.08f
        val barX = centerX - barW / 2f

        shapeRenderer.color = COLOR_BAR_FRAME
        shapeRenderer.rect(barX - 0.02f, barY - 0.02f, barW + 0.04f, barH + 0.04f)

        val hpPercent = (health.currentHp / health.maxHp).coerceIn(0f, 1f)
        shapeRenderer.color = COLOR_BAR_FILL
        shapeRenderer.rect(barX, barY, barW * hpPercent, barH)
    }

    fun renderDebug(shapeRenderer: ShapeRenderer) {
        if (isDespawned) return
        shapeRenderer.color = Color.GREEN
        shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)
        hurtbox.renderDebug(shapeRenderer)
        hitbox.renderDebug(shapeRenderer)
    }
}
