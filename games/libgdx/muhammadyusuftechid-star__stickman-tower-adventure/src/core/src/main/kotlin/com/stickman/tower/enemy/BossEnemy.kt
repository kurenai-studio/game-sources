package com.stickman.tower.enemy

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.stickman.tower.character.Player
import com.stickman.tower.combat.Health
import com.stickman.tower.combat.Hitbox
import com.stickman.tower.combat.Hurtbox
import com.stickman.tower.combat.Projectile
import com.stickman.tower.physics.Platform
import com.stickman.tower.world.GameConfig
import kotlin.math.abs
import kotlin.math.sin

enum class BossState {
    IDLE,
    CHASE,
    CLEAVE,
    GROUND_SLAM_UP,
    GROUND_SLAM_DOWN,
    ENRAGE_ROAR,
    WIND_SLASH,
    EVASIVE_LEAP,    // Matron: lompatan akrobatik mundur sambil menembak panah
    SHADOW_DODGE,    // Doppelganger: shadow roll cross-up menembus pemain ke belakang
    BLOOD_BLINK,     // Sovereign: teleportasi kabut darah ke belakang pemain
    SUMMON_RUNES,    // Calligrapher: memanggil segel tinta meledak di bawah pemain
    STUNNED,
    DEAD
}

enum class BossType {
    TOWER_GUARDIAN,      // Floor 3 (General Oakhaven)
    AMETHYST_MATRON,     // Floor 5 (Sang Ratu Busur Bayang)
    SHADOW_DOPPELGANGER, // Floor 8 (Cermin Jiwa Gelap)
    CRIMSON_SOVEREIGN,   // Floor 9 (Pangeran Belati Darah)
    GRAND_CALLIGRAPHER   // Floor 10 (Sang Penulis Takdir)
}

/**
 * Boss Menara dengan Arsitektur AI Kepribadian Taktikal Berbeda (10/10 AI Systems):
 * Masing-masing dari 5 Bos Legendaris memiliki pohon keputusan dan taktik khas:
 * - TOWER_GUARDIAN: Juggernaut tanky, Cleave jarak dekat, Ground Slam seismik, Wind Slash.
 * - AMETHYST_MATRON: Sniper kiter, Evasive Leap mundur saat didekati, Double/Triple Arrow Fan.
 * - SHADOW_DOPPELGANGER: Shinobi mirror, Shadow Roll menembus pemain untuk counter-backstab, Sabit Bayangan.
 * - CRIMSON_SOVEREIGN: Assassin darah, Blood Blink teleportasi instan ke belakang pemain, Berserk Flurry.
 * - GRAND_CALLIGRAPHER: Sorcerer kosmis, memanggil Rune Segel Tinta meledak, Komet Kosmis, Warp dimensi.
 */
class BossEnemy(
    spawnX: Float = 14f,
    spawnY: Float = 2.5f,
    val type: BossType = BossType.TOWER_GUARDIAN,
    customMaxHp: Float? = null,
    customName: String? = null
) {
    val position = Vector2(spawnX, spawnY)
    val velocity = Vector2(0f, 0f)

    val width: Float = when (type) {
        BossType.AMETHYST_MATRON -> 1.2f
        BossType.SHADOW_DOPPELGANGER -> 1.1f
        BossType.CRIMSON_SOVEREIGN -> 1.3f
        BossType.GRAND_CALLIGRAPHER -> 1.8f
        else -> 1.4f
    }
    val height: Float = when (type) {
        BossType.AMETHYST_MATRON -> 2.5f
        BossType.SHADOW_DOPPELGANGER -> 2.2f
        BossType.CRIMSON_SOVEREIGN -> 2.6f
        BossType.GRAND_CALLIGRAPHER -> 3.4f
        else -> 2.8f
    }
    val bounds = Rectangle(position.x, position.y, width, height)

    val name: String = customName ?: when (type) {
        BossType.TOWER_GUARDIAN -> "TOWER GUARDIAN"
        BossType.AMETHYST_MATRON -> "THE AMETHYST MATRON"
        BossType.SHADOW_DOPPELGANGER -> "SHADOW DOPPELGANGER"
        BossType.CRIMSON_SOVEREIGN -> "CRIMSON SOVEREIGN"
        BossType.GRAND_CALLIGRAPHER -> "THE GRAND CALLIGRAPHER"
    }

    val subtitle: String = when (type) {
        BossType.TOWER_GUARDIAN -> "General Oakhaven"
        BossType.AMETHYST_MATRON -> "Queen of the Shadow Bow"
        BossType.SHADOW_DOPPELGANGER -> "Dark Reflection"
        BossType.CRIMSON_SOVEREIGN -> "Prince of Blood Daggers"
        BossType.GRAND_CALLIGRAPHER -> "Architect of Fate"
    }

    val enrageQuote: String = when (type) {
        BossType.TOWER_GUARDIAN -> "Segel ini tidak kubuat untuk melindungi menara dari kalian... TAPI UNTUK MELINDUNGI KALIAN DARI KEBIADABAN PUNCAK MENARA! TERIMALAH TEBASAN INI!"
        BossType.AMETHYST_MATRON -> "Hirup racun ini sampai paru-paru siluetmu membusuk! Tak ada seorang pun yang berhak melangkahi makam arsipku!"
        BossType.SHADOW_DOPPELGANGER -> "Aku adalah keputusasaanmu... Aku adalah setiap langkah ragu yang kau ambil. Kau takkan pernah bisa membunuh bayanganmu sendiri!"
        BossType.CRIMSON_SOVEREIGN -> "Darah kalian begitu manis... Menara ini membutuhkan persembahan segar agar gerhana darah tidak pernah berakhir!"
        BossType.GRAND_CALLIGRAPHER -> "KAU HANYALAH TINTA KOTOR DI ATAS KERTASKU! LENYAPLAH KEMBALI KE DALAM KETIADAAN ABADI!"
    }

    val deathQuote: String = when (type) {
        BossType.TOWER_GUARDIAN -> "Kau memiliki tekad ksatria masa lalu... Namun di atas sana, musuhmu adalah kebenaran mengerikan..."
        BossType.AMETHYST_MATRON -> "Tinta ini... akhirnya membebaskan kami dari kutukan panah..."
        BossType.SHADOW_DOPPELGANGER -> "Bayangan tak pernah mati... aku selalu ada di balik punggungmu..."
        BossType.CRIMSON_SOVEREIGN -> "Gerhana telah runtuh... darah ini akhirnya tenang kembali..."
        BossType.GRAND_CALLIGRAPHER -> "Pena takdir telah patah... Realitas ini kini terbelah menuju Paradoks Abadi..."
    }

    val health = Health(
        maxHp = customMaxHp ?: when (type) {
            BossType.TOWER_GUARDIAN -> 350f
            BossType.AMETHYST_MATRON -> 480f
            BossType.SHADOW_DOPPELGANGER -> 620f
            BossType.CRIMSON_SOVEREIGN -> 780f
            BossType.GRAND_CALLIGRAPHER -> 1100f
        },
        invulnerableDuration = 0.15f
    )
    val hurtbox = Hurtbox(this)
    val hitbox = Hitbox(
        this,
        damage = when (type) {
            BossType.TOWER_GUARDIAN -> 22f
            BossType.AMETHYST_MATRON -> 18f
            BossType.SHADOW_DOPPELGANGER -> 25f
            BossType.CRIMSON_SOVEREIGN -> 30f
            BossType.GRAND_CALLIGRAPHER -> 36f
        },
        knockbackX = 8.5f,
        knockbackY = 4.5f
    )

    // Hadiah Kemenangan Boss
    val expReward: Int = when (type) {
        BossType.TOWER_GUARDIAN -> 200
        BossType.AMETHYST_MATRON -> 350
        BossType.SHADOW_DOPPELGANGER -> 500
        BossType.CRIMSON_SOVEREIGN -> 700
        BossType.GRAND_CALLIGRAPHER -> 1200
    }
    val goldReward: Int = when (type) {
        BossType.TOWER_GUARDIAN -> 100
        BossType.AMETHYST_MATRON -> 180
        BossType.SHADOW_DOPPELGANGER -> 250
        BossType.CRIMSON_SOVEREIGN -> 350
        BossType.GRAND_CALLIGRAPHER -> 600
    }
    var rewardClaimed = false

    var state = BossState.IDLE
        internal set
    var facingRight = false
        private set
    var isPhase2 = false
        private set
    private var hasTriggeredEnrage = false

    private var actionTimer = 0f
    var attackCooldown = 0.4f
        internal set
    private var isGrounded = false
    private var animTime = 0f
    private var enragePulse = 0f
    var stunTimer = 0f
        private set
    var poisonTimer = 0f
        private set
    var poisonDps = 0f
        private set
    private var poisonTickTimer = 0f

    // Signature Boss Parameters
    private var runeTargetX = 0f
    private var runeTargetY = 0f
    private var runeExploded = false
    private var hasFiredLeapShot = false

    fun applyPoison(duration: Float = 3.5f, dps: Float = 12f) {
        poisonTimer = duration.coerceAtLeast(poisonTimer)
        poisonDps = dps.coerceAtLeast(poisonDps)
    }

    val projectiles = mutableListOf<Projectile>()
    private var hasFiredWindSlash = false
    private var hasLanded = false

    companion object {
        const val BASE_SPEED = 3.2f
        const val ENRAGE_SPEED = 4.8f
        const val CLEAVE_RANGE = 2.4f

        val COLOR_BOSS_DEAD = Color(0.25f, 0.25f, 0.25f, 1f)
        val COLOR_BOSS_PHASE2 = Color(0.85f, 0.18f, 0.18f, 1f)
        val COLOR_BOSS_NORMAL = Color(0.18f, 0.18f, 0.22f, 1f)
        val COLOR_BOSS_EYE = Color(1f, 0.15f, 0.15f, 1f)
        val COLOR_BOSS_HORN = Color(0.9f, 0.75f, 0.2f, 1f)
        val COLOR_BLADE_PHASE2 = Color(1f, 0.35f, 0.2f, 1f)
        val COLOR_BLADE_NORMAL = Color(0.85f, 0.85f, 0.9f, 1f)
        val COLOR_RUNE_WARNING = Color(1f, 0.85f, 0.2f, 0.8f)
    }

    fun update(delta: Float, player: Player, platforms: List<Platform>) {
        animTime += delta
        health.update(delta)

        // Ticking Poison DoT
        if (poisonTimer > 0f && !health.isDead) {
            poisonTimer = (poisonTimer - delta).coerceAtLeast(0f)
            poisonTickTimer += delta
            if (poisonTickTimer >= 0.5f) {
                poisonTickTimer = 0f
                health.takeDamage(poisonDps * 0.5f)
            }
        }

        // Update Proyektil Aktif
        val it = projectiles.iterator()
        while (it.hasNext()) {
            val p = it.next()
            p.update(delta)
            for (platform in platforms) {
                if (platform.isOneWay) continue
                if (!p.isDestroyed && p.bounds.overlaps(platform.bounds)) {
                    p.isDestroyed = true
                    break
                }
            }
            if (p.isDestroyed) it.remove()
        }

        // Cek Transisi Fase 2 (Enrage)
        if (!hasTriggeredEnrage && health.currentHp <= health.maxHp * 0.5f && !health.isDead) {
            hasTriggeredEnrage = true
            isPhase2 = true
            state = BossState.ENRAGE_ROAR
            actionTimer = 0f
            velocity.set(0f, 0f)
            hitbox.reset()
        }

        if (health.isDead) {
            state = BossState.DEAD
            hitbox.reset()
            hurtbox.isActive = false
            velocity.x = 0f
            velocity.y += GameConfig.GRAVITY * delta
            resolveCollision(delta, platforms)
            return
        }

        if (attackCooldown > 0f) {
            attackCooldown = (attackCooldown - delta).coerceAtLeast(0f)
        }

        hurtbox.set(position.x, position.y, width, height)

        val distToPlayer = player.position.x - (position.x + width / 2f)
        val absDist = abs(distToPlayer)

        // =====================================================================
        // AI STATE MACHINE DENGAN CABANG KEPRIBADIAN BOS
        // =====================================================================
        when (state) {
            BossState.IDLE -> {
                actionTimer += delta
                facingRight = distToPlayer > 0
                velocity.x = 0f
                if (actionTimer >= (if (isPhase2) 0.25f else 0.4f)) {
                    state = BossState.CHASE
                    actionTimer = 0f
                }
            }

            BossState.CHASE -> {
                facingRight = distToPlayer > 0
                val moveSpeed = if (isPhase2) ENRAGE_SPEED else BASE_SPEED

                // Logika Gerakan Khas Masing-Masing Bos:
                when (type) {
                    BossType.AMETHYST_MATRON -> {
                        // Kiter AI: jika pemain terlalu dekat (< 3.2m), mundur atau lakukan Evasive Leap
                        if (absDist < 3.2f) {
                            if (attackCooldown <= 0f) {
                                state = BossState.EVASIVE_LEAP
                                actionTimer = 0f
                                hasFiredLeapShot = false
                                velocity.y = 10.0f
                                velocity.x = (if (facingRight) -1f else 1f) * 7.5f
                                isGrounded = false
                            } else {
                                // Mundur sambil membidik
                                velocity.x = (if (facingRight) -moveSpeed else moveSpeed) * 0.8f
                            }
                        } else if (absDist > 7.5f) {
                            velocity.x = if (facingRight) moveSpeed else -moveSpeed
                        } else {
                            // Sweet spot: berhenti dan tembakkan panah kristal
                            velocity.x = MathUtils.lerp(velocity.x, 0f, 15f * delta)
                            if (attackCooldown <= 0f) {
                                state = BossState.WIND_SLASH
                                actionTimer = 0f
                                hasFiredWindSlash = false
                                velocity.x = 0f
                            }
                        }
                    }

                    BossType.SHADOW_DOPPELGANGER -> {
                        velocity.x = if (facingRight) moveSpeed * 1.1f else -moveSpeed * 1.1f
                        if (attackCooldown <= 0f) {
                            if (absDist <= 2.2f) {
                                // Taktik Ninja: 50% Shadow Roll menembus ke belakang pemain (Cross-up)
                                if (MathUtils.randomBoolean(0.55f)) {
                                    state = BossState.SHADOW_DODGE
                                    actionTimer = 0f
                                } else {
                                    state = BossState.CLEAVE
                                    actionTimer = 0f
                                    hitbox.damage = if (isPhase2) 30f else 25f
                                    hitbox.reset()
                                    velocity.x = 0f
                                }
                            } else if (absDist in 2.5f..6.5f) {
                                if (MathUtils.randomBoolean(0.4f)) {
                                    state = BossState.WIND_SLASH
                                    actionTimer = 0f
                                    hasFiredWindSlash = false
                                    velocity.x = 0f
                                } else {
                                    state = BossState.GROUND_SLAM_UP
                                    actionTimer = 0f
                                    velocity.y = 12.5f
                                    val leapVx = (distToPlayer / 0.45f).coerceIn(-moveSpeed * 1.5f, moveSpeed * 1.5f)
                                    velocity.x = leapVx
                                }
                            }
                        }
                    }

                    BossType.CRIMSON_SOVEREIGN -> {
                        velocity.x = if (facingRight) moveSpeed else -moveSpeed
                        if (attackCooldown <= 0f) {
                            if (absDist in 3.0f..8.5f && MathUtils.randomBoolean(0.6f)) {
                                // Taktik Vampiric: Blood Blink teleport ke belakang pemain
                                state = BossState.BLOOD_BLINK
                                actionTimer = 0f
                                velocity.set(0f, 0f)
                            } else if (absDist <= CLEAVE_RANGE) {
                                state = BossState.CLEAVE
                                actionTimer = 0f
                                hitbox.damage = if (isPhase2) 34f else 28f
                                hitbox.reset()
                                velocity.x = 0f
                            } else if (isPhase2 || absDist > 6.0f) {
                                state = BossState.WIND_SLASH
                                actionTimer = 0f
                                hasFiredWindSlash = false
                                velocity.x = 0f
                            }
                        }
                    }

                    BossType.GRAND_CALLIGRAPHER -> {
                        velocity.x = if (facingRight) moveSpeed * 0.75f else -moveSpeed * 0.75f
                        if (attackCooldown <= 0f) {
                            if (absDist in 3.0f..10.0f && MathUtils.randomBoolean(0.5f)) {
                                // Memanggil Ink Rune di bawah kaki pemain
                                state = BossState.SUMMON_RUNES
                                actionTimer = 0f
                                runeTargetX = player.position.x
                                runeTargetY = player.position.y
                                runeExploded = false
                                velocity.x = 0f
                            } else if (absDist <= CLEAVE_RANGE + 0.5f) {
                                state = BossState.CLEAVE
                                actionTimer = 0f
                                hitbox.damage = if (isPhase2) 40f else 35f
                                hitbox.reset()
                                velocity.x = 0f
                            } else {
                                state = BossState.WIND_SLASH
                                actionTimer = 0f
                                hasFiredWindSlash = false
                                velocity.x = 0f
                            }
                        }
                    }

                    BossType.TOWER_GUARDIAN -> {
                        // Pola Standar Bastion Juggernaut
                        velocity.x = if (facingRight) moveSpeed else -moveSpeed
                        if (attackCooldown <= 0f) {
                            if (absDist <= CLEAVE_RANGE) {
                                state = BossState.CLEAVE
                                actionTimer = 0f
                                hitbox.damage = if (isPhase2) 28f else 22f
                                hitbox.knockbackX = 8.5f
                                hitbox.knockbackY = 4.0f
                                hitbox.reset()
                                velocity.x = 0f
                            } else if (absDist in 2.5f..7.5f) {
                                state = BossState.GROUND_SLAM_UP
                                actionTimer = 0f
                                velocity.y = 12.5f
                                val leapTargetVx = (distToPlayer / 0.45f).coerceIn(-moveSpeed * 1.5f, moveSpeed * 1.5f)
                                velocity.x = leapTargetVx
                            } else if (isPhase2 && absDist > 6.0f) {
                                state = BossState.WIND_SLASH
                                actionTimer = 0f
                                hasFiredWindSlash = false
                                velocity.x = 0f
                            }
                        }
                    }
                }
            }

            BossState.CLEAVE -> {
                actionTimer += delta
                velocity.x = 0f
                when {
                    actionTimer < 0.28f -> {
                        hitbox.isActive = false
                    }
                    actionTimer < 0.44f -> {
                        val hbW = 2.4f
                        val hbH = 2.2f
                        val hbX = if (facingRight) position.x + width * 0.7f else position.x - hbW + width * 0.3f
                        val hbY = position.y + 0.3f
                        hitbox.set(hbX, hbY, hbW, hbH, active = true)
                    }
                    actionTimer < 0.70f -> {
                        hitbox.reset()
                    }
                    else -> {
                        hitbox.reset()
                        attackCooldown = if (isPhase2) 0.8f else 1.3f
                        state = BossState.IDLE
                        actionTimer = 0f
                    }
                }
            }

            BossState.GROUND_SLAM_UP -> {
                hitbox.isActive = false
                hasLanded = false
                if (velocity.y <= 0f) {
                    state = BossState.GROUND_SLAM_DOWN
                    velocity.y = -22.0f
                    velocity.x = 0f
                    actionTimer = 0f
                }
            }

            BossState.GROUND_SLAM_DOWN -> {
                if (isGrounded || hasLanded) {
                    hasLanded = true
                    actionTimer += delta
                    velocity.set(0f, 0f)

                    if (actionTimer < 0.18f) {
                        val shockW = 4.2f
                        val shockH = 1.0f
                        hitbox.damage = if (isPhase2) 32f else 25f
                        hitbox.knockbackX = 9.0f
                        hitbox.knockbackY = 6.0f
                        hitbox.set(position.x + width / 2f - shockW / 2f, position.y, shockW, shockH, active = true)
                    } else {
                        hitbox.reset()
                    }

                    if (actionTimer >= 0.65f) {
                        hitbox.reset()
                        hasLanded = false
                        attackCooldown = if (isPhase2) 0.9f else 1.4f
                        state = BossState.IDLE
                        actionTimer = 0f
                    }
                }
            }

            BossState.ENRAGE_ROAR -> {
                actionTimer += delta
                enragePulse += delta * 10f
                velocity.set(0f, 0f)
                hitbox.reset()
                if (actionTimer >= 1.2f) {
                    state = BossState.CHASE
                    attackCooldown = 0.4f
                }
            }

            BossState.WIND_SLASH -> {
                actionTimer += delta
                velocity.x = 0f
                if (actionTimer >= 0.25f && !hasFiredWindSlash) {
                    hasFiredWindSlash = true
                    val projVx = if (facingRight) 14f else -14f
                    val projStartX = if (facingRight) position.x + width else position.x - 0.8f
                    when (type) {
                        BossType.TOWER_GUARDIAN -> {
                            projectiles.add(
                                Projectile(
                                    startX = projStartX,
                                    startY = position.y + height * 0.45f,
                                    velocityX = projVx,
                                    damage = 22f,
                                    color = Color(0.3f, 0.85f, 1f, 1f)
                                )
                            )
                        }
                        BossType.AMETHYST_MATRON -> {
                            projectiles.add(Projectile(startX = projStartX, startY = position.y + height * 0.6f, velocityX = projVx * 1.15f, velocityY = 2.0f, damage = 16f, color = Color(0.85f, 0.45f, 1f, 1f)))
                            projectiles.add(Projectile(startX = projStartX, startY = position.y + height * 0.45f, velocityX = projVx * 1.25f, velocityY = 0f, damage = 18f, color = Color(0.85f, 0.45f, 1f, 1f)))
                            projectiles.add(Projectile(startX = projStartX, startY = position.y + height * 0.3f, velocityX = projVx * 1.15f, velocityY = -2.0f, damage = 16f, color = Color(0.85f, 0.45f, 1f, 1f)))
                        }
                        BossType.SHADOW_DOPPELGANGER -> {
                            projectiles.add(Projectile(startX = projStartX, startY = position.y + height * 0.45f, velocityX = projVx * 1.35f, damage = 24f, color = Color(0.4f, 0.85f, 1f, 1f)))
                        }
                        BossType.CRIMSON_SOVEREIGN -> {
                            projectiles.add(Projectile(startX = projStartX, startY = position.y + height * 0.45f, velocityX = projVx * 1.3f, damage = 28f, color = Color(1f, 0.2f, 0.25f, 1f)))
                        }
                        BossType.GRAND_CALLIGRAPHER -> {
                            projectiles.add(Projectile(startX = projStartX, startY = position.y + height * 0.5f, velocityX = projVx * 1.1f, damage = 35f, width = 1.6f, height = 0.8f, color = Color(1f, 0.85f, 0.25f, 1f)))
                        }
                    }
                }
                if (actionTimer >= 0.55f) {
                    attackCooldown = if (type == BossType.AMETHYST_MATRON) 0.8f else 1.1f
                    state = BossState.IDLE
                    actionTimer = 0f
                }
            }

            // =================================================================
            // SIGNATURE BOSS BEHAVIOR STATES
            // =================================================================
            BossState.EVASIVE_LEAP -> {
                actionTimer += delta
                if (actionTimer >= 0.20f && !hasFiredLeapShot) {
                    hasFiredLeapShot = true
                    val arrowVx = (if (facingRight) 1f else -1f) * 11f
                    projectiles.add(
                        Projectile(
                            startX = position.x + width / 2f,
                            startY = position.y + 0.5f,
                            velocityX = arrowVx,
                            velocityY = -4.5f,
                            damage = 18f,
                            color = Color(0.85f, 0.45f, 1f, 1f)
                        )
                    )
                }
                if (isGrounded && actionTimer >= 0.35f) {
                    attackCooldown = 0.6f
                    state = BossState.CHASE
                    actionTimer = 0f
                }
            }

            BossState.SHADOW_DODGE -> {
                actionTimer += delta
                val rollDir = if (facingRight) 1f else -1f
                velocity.x = rollDir * 11.5f

                if (actionTimer >= 0.22f) {
                    // Berbalik arah menghadap punggung pemain dan langsung lancarkan Cleave
                    facingRight = !facingRight
                    state = BossState.CLEAVE
                    actionTimer = 0f
                    hitbox.damage = if (isPhase2) 32f else 26f
                    hitbox.reset()
                    velocity.x = 0f
                }
            }

            BossState.BLOOD_BLINK -> {
                actionTimer += delta
                velocity.set(0f, 0f)
                if (actionTimer >= 0.15f) {
                    // Reappear di belakang punggung pemain
                    val targetX = player.position.x + (if (player.facingRight) -1.3f else 1.3f)
                    position.x = targetX.coerceIn(-8f, 30f)
                    position.y = player.position.y
                    facingRight = player.position.x > position.x
                    state = BossState.CLEAVE
                    actionTimer = 0f
                    hitbox.damage = if (isPhase2) 36f else 30f
                    hitbox.reset()
                }
            }

            BossState.SUMMON_RUNES -> {
                actionTimer += delta
                velocity.x = 0f
                if (actionTimer >= 0.55f && !runeExploded) {
                    runeExploded = true
                    // Erupsi Geyser Tinta Kosmis vertikal
                    projectiles.add(
                        Projectile(
                            startX = runeTargetX - 0.4f,
                            startY = runeTargetY,
                            velocityX = 0f,
                            velocityY = 13.0f,
                            damage = 32f,
                            width = 0.85f,
                            height = 1.8f,
                            maxLifetime = 0.7f,
                            color = Color.GOLD
                        )
                    )
                }
                if (actionTimer >= 0.85f) {
                    attackCooldown = 1.0f
                    state = BossState.IDLE
                    actionTimer = 0f
                }
            }

            BossState.STUNNED -> {
                actionTimer += delta
                velocity.x = 0f
                hitbox.reset()
                if (actionTimer >= stunTimer) {
                    state = BossState.CHASE
                    attackCooldown = 0.6f
                    actionTimer = 0f
                }
            }

            BossState.DEAD -> {}
        }

        // Gravitasi & Collision
        if (state != BossState.GROUND_SLAM_DOWN) {
            velocity.y += GameConfig.GRAVITY * delta
            velocity.y = velocity.y.coerceAtLeast(-25f)
        }

        resolveCollision(delta, platforms)
    }

    private fun resolveCollision(delta: Float, platforms: List<Platform>) {
        position.x += velocity.x * delta
        bounds.setPosition(position.x, position.y)

        for (platform in platforms) {
            if (platform.isOneWay) continue
            if (bounds.overlaps(platform.bounds)) {
                if (velocity.x > 0f) position.x = platform.left - width
                else if (velocity.x < 0f) position.x = platform.right
                velocity.x = 0f
                bounds.setPosition(position.x, position.y)
            }
        }

        isGrounded = false
        position.y += velocity.y * delta
        bounds.setPosition(position.x, position.y)

        for (platform in platforms) {
            if (platform.isOneWay && velocity.y > 0f) continue
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

    fun takeHit(amount: Float, knockX: Float, knockY: Float): Boolean {
        if (health.takeDamage(amount)) {
            // Boss memiliki hyper armor: resistensi knockback tinggi
            velocity.x += knockX * 0.25f
            return true
        }
        return false
    }

    /**
     * Mengaktifkan status Guard Break / Stun akibat Perfect Parry dari pemain.
     */
    fun stun(duration: Float = 1.5f) {
        state = BossState.STUNNED
        stunTimer = duration
        actionTimer = 0f
        velocity.x = 0f
        hitbox.reset()
    }

    fun render(shapeRenderer: ShapeRenderer) {
        val centerX = position.x + width / 2f
        val footY = position.y
        val headRadius = 0.35f
        val headCenterY = position.y + height - headRadius - 0.1f
        val neckY = headCenterY - headRadius
        val pelvisY = position.y + 1.15f
        val shoulderY = neckY - 0.22f
        val lookDir = if (facingRight) 1f else -1f

        // 1. Render Proyektil Aktif
        for (p in projectiles) p.render(shapeRenderer)

        // 1b. Render Indikator Visual Segel Tinta / Ink Rune Calligrapher
        if (state == BossState.SUMMON_RUNES && !runeExploded) {
            val runePulse = (sin(animTime * 18f) + 1f) * 0.15f
            shapeRenderer.color = COLOR_RUNE_WARNING
            shapeRenderer.circle(runeTargetX, runeTargetY + 0.1f, 0.75f + runePulse, 16)
            shapeRenderer.color = Color.RED
            shapeRenderer.circle(runeTargetX, runeTargetY + 0.1f, 0.3f, 10)
        }

        // 2. Aura Merah Membara di Fase 2 (Enrage Mode)
        if (isPhase2 && !health.isDead) {
            val pulse = (sin(animTime * 8f) * 0.15f) + 0.35f
            shapeRenderer.setColor(1f, 0.2f, 0.1f, pulse)
            shapeRenderer.circle(centerX, position.y + height / 2f, (height / 2f) + 0.3f, 20)
        }

        // 3. Warna Tubuh Boss
        val bodyColor = when {
            health.isFlashing -> Color.WHITE
            state == BossState.DEAD -> COLOR_BOSS_DEAD
            isPhase2 -> COLOR_BOSS_PHASE2
            else -> COLOR_BOSS_NORMAL
        }

        // Kepala Boss & Helm Tanduk
        shapeRenderer.color = bodyColor
        shapeRenderer.circle(centerX, headCenterY, headRadius, 16)

        // Mata Merah Menyala
        shapeRenderer.color = if (health.isDead) Color.GRAY else COLOR_BOSS_EYE
        shapeRenderer.circle(centerX + lookDir * 0.16f, headCenterY + 0.05f, 0.08f, 10)

        // Tanduk / Mahkota / Halo di Kepala sesuai Tipe Bos
        when (type) {
            BossType.TOWER_GUARDIAN -> {
                shapeRenderer.color = COLOR_BOSS_HORN
                shapeRenderer.rectLine(centerX, headCenterY + headRadius * 0.6f, centerX + lookDir * 0.45f, headCenterY + headRadius + 0.35f, 0.09f)
            }
            BossType.AMETHYST_MATRON -> {
                shapeRenderer.color = Color(0.85f, 0.45f, 1f, 1f)
                shapeRenderer.triangle(
                    centerX - 0.25f, headCenterY + headRadius,
                    centerX, headCenterY + headRadius + 0.35f,
                    centerX + 0.25f, headCenterY + headRadius
                )
            }
            BossType.SHADOW_DOPPELGANGER -> {
                shapeRenderer.color = Color.CYAN
                shapeRenderer.circle(centerX, headCenterY + headRadius + 0.15f, 0.14f, 10)
            }
            BossType.CRIMSON_SOVEREIGN -> {
                shapeRenderer.color = Color(1f, 0.15f, 0.25f, 1f)
                shapeRenderer.rectLine(centerX, headCenterY + headRadius * 0.6f, centerX + lookDir * 0.45f, headCenterY + headRadius + 0.4f, 0.08f)
                shapeRenderer.rectLine(centerX, headCenterY + headRadius * 0.6f, centerX - lookDir * 0.35f, headCenterY + headRadius + 0.35f, 0.08f)
            }
            BossType.GRAND_CALLIGRAPHER -> {
                shapeRenderer.color = Color.GOLD
                shapeRenderer.circle(centerX, headCenterY + 0.15f, headRadius + 0.28f, 20)
                shapeRenderer.color = Color.WHITE
                shapeRenderer.circle(centerX, headCenterY + 0.15f, headRadius + 0.20f, 16)
            }
        }

        // Visual Guard Break / Stun Stars
        if (state == BossState.STUNNED) {
            shapeRenderer.color = Color.GOLD
            val orbitRadius = 0.52f
            for (i in 0 until 4) {
                val angle = animTime * 5.5f + (i * 1.57f)
                val starX = centerX + kotlin.math.cos(angle.toDouble()).toFloat() * orbitRadius
                val starY = headCenterY + headRadius + 0.42f + kotlin.math.sin(angle.toDouble()).toFloat() * 0.12f
                shapeRenderer.circle(starX, starY, 0.08f, 8)
            }
        }

        // Tubuh / Torso
        shapeRenderer.color = bodyColor
        shapeRenderer.rectLine(centerX, neckY, centerX, pelvisY, 0.16f)

        // Kaki Boss
        val legAnim = sin(animTime * 6f) * 0.3f
        val footLeftX = if (state == BossState.CHASE) centerX - 0.35f - legAnim else centerX - 0.35f
        val footRightX = if (state == BossState.CHASE) centerX + 0.35f + legAnim else centerX + 0.35f
        shapeRenderer.rectLine(centerX, pelvisY, footLeftX, footY, 0.14f)
        shapeRenderer.rectLine(centerX, pelvisY, footRightX, footY, 0.14f)

        // Tangan & Senjata Sesuai Tipe Bos
        val handX = centerX + lookDir * 0.55f
        val handY = shoulderY - 0.25f
        shapeRenderer.rectLine(centerX, shoulderY, handX, handY, 0.12f)

        val bladeAngle = when (state) {
            BossState.CLEAVE -> if (facingRight) 25f else 155f
            BossState.GROUND_SLAM_DOWN -> -90f
            else -> if (facingRight) 65f else 115f
        }

        when (type) {
            BossType.AMETHYST_MATRON -> {
                val bowRadius = 1.1f
                shapeRenderer.color = Color(0.85f, 0.45f, 1f, 1f)
                shapeRenderer.rectLine(handX, handY - 0.8f, handX + lookDir * 0.4f, handY, 0.08f)
                shapeRenderer.rectLine(handX + lookDir * 0.4f, handY, handX, handY + 0.8f, 0.08f)
                shapeRenderer.color = Color.WHITE
                shapeRenderer.rectLine(handX, handY - 0.8f, handX, handY + 0.8f, 0.03f)
            }
            BossType.SHADOW_DOPPELGANGER -> {
                val daggerLen = 1.2f
                val tipX = handX + MathUtils.cosDeg(bladeAngle) * daggerLen
                val tipY = handY + MathUtils.sinDeg(bladeAngle) * daggerLen
                shapeRenderer.color = Color.CYAN
                shapeRenderer.rectLine(handX, handY, tipX, tipY, 0.08f)
            }
            BossType.CRIMSON_SOVEREIGN -> {
                val shaftLen = 2.2f
                val shaftEndX = handX + MathUtils.cosDeg(bladeAngle) * shaftLen
                val shaftEndY = handY + MathUtils.sinDeg(bladeAngle) * shaftLen
                shapeRenderer.color = Color(0.3f, 0.1f, 0.15f, 1f)
                shapeRenderer.rectLine(handX, handY, shaftEndX, shaftEndY, 0.10f)
                shapeRenderer.color = Color(1f, 0.2f, 0.25f, 1f)
                shapeRenderer.rectLine(shaftEndX, shaftEndY, shaftEndX + lookDir * 0.9f, shaftEndY - 0.6f, 0.16f)
            }
            BossType.GRAND_CALLIGRAPHER -> {
                val brushLen = 2.6f
                val brushEndX = handX + MathUtils.cosDeg(bladeAngle) * brushLen
                val brushEndY = handY + MathUtils.sinDeg(bladeAngle) * brushLen
                shapeRenderer.color = Color(0.85f, 0.70f, 0.25f, 1f)
                shapeRenderer.rectLine(handX, handY, brushEndX, brushEndY, 0.16f)
                shapeRenderer.color = Color.WHITE
                shapeRenderer.circle(brushEndX, brushEndY, 0.25f, 12)
                shapeRenderer.color = Color(0.2f, 0.8f, 1f, 0.8f)
                shapeRenderer.circle(brushEndX, brushEndY, 0.15f, 8)
            }
            else -> {
                val bladeLen = 2.0f
                val swordEndX = handX + MathUtils.cosDeg(bladeAngle) * bladeLen
                val swordEndY = handY + MathUtils.sinDeg(bladeAngle) * bladeLen
                shapeRenderer.color = if (isPhase2) COLOR_BLADE_PHASE2 else COLOR_BLADE_NORMAL
                shapeRenderer.rectLine(handX, handY, swordEndX, swordEndY, 0.15f)
            }
        }
    }

    fun renderDebug(shapeRenderer: ShapeRenderer) {
        shapeRenderer.color = Color.MAGENTA
        shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)
        hurtbox.renderDebug(shapeRenderer)
        hitbox.renderDebug(shapeRenderer)
    }
}
