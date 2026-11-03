package com.stickman.tower.character

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector2
import com.stickman.tower.combat.AttackPhase
import com.stickman.tower.combat.ComboManager
import com.stickman.tower.combat.ComboStep
import com.stickman.tower.combat.Health
import com.stickman.tower.combat.Hitbox
import com.stickman.tower.combat.Hurtbox
import com.stickman.tower.combat.Projectile
import com.stickman.tower.combat.Skill
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.combat.UltimateEnergy
import com.stickman.tower.input.GameInput
import com.stickman.tower.physics.Platform
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.world.GameConfig
import kotlin.math.abs
import kotlin.math.sin
import kotlin.random.Random

/**
 * Entitas Karakter Pemain Fase 7:
 * Didukung 3 Arketipe (BALANCED, AGILE, HEAVY), model RPG CharacterStats,
 * Combo Hit Chain, Dodge Roll ber-i-frames, Skill & Ultimate unik,
 * serta integrasi Audio SFX & Partikel VFX.
 */
class Player(
    spawnX: Float = 0f,
    spawnY: Float = 2f,
    val stats: CharacterStats = CharacterStats(),
    var archetype: CharacterArchetype = CharacterArchetype.BALANCED
) {
    val position = Vector2(spawnX, spawnY)
    val velocity = Vector2(0f, 0f)

    val width = 0.8f
    val height = 1.8f
    val bounds = Rectangle(position.x, position.y, width, height)

    // Komponen Pertarungan & RPG
    val health = Health(maxHp = stats.maxHp, invulnerableDuration = 0.35f)
    val hurtbox = Hurtbox(this)
    val hitbox = Hitbox(this, damage = stats.calculateDamage(12f).first * archetype.baseDamageMultiplier, knockbackX = 4f, knockbackY = 2.5f)

    val comboManager = ComboManager()
    val skill1 = Skill(
        name = archetype.skill1Name,
        cooldown = archetype.skill1Cooldown
    )
    val skill2 = Skill(
        name = archetype.skill2Name,
        cooldown = archetype.skill2Cooldown
    )
    val skill3 = Skill(
        name = archetype.skill3Name,
        cooldown = archetype.skill3Cooldown
    )
    val ultimate = UltimateEnergy(maxEnergy = archetype.ultEnergyCost)
    val projectiles = mutableListOf<Projectile>()
    val baseAttackPower: Float get() = stats.attackPower

    // Callbacks untuk efek partikel & visual luar
    var onLand: ((Float, Float) -> Unit)? = null
    var onJump: ((Float, Float) -> Unit)? = null
    var onDodge: ((Float, Float) -> Unit)? = null

    // Siklus Fase Serangan Kombo
    var attackPhase: AttackPhase = AttackPhase.INACTIVE
        private set
    private var attackTimer: Float = 0f

    // Parameter Dodge / Dash Roll
    var isDodging = false
        private set
    private var dodgeTimer = 0f
    var dodgeCooldown = 0f
        private set
    private val afterimagePool = Array(4) { Vector2() }
    private var afterimageCount = 0

    // Parameter Multi-Skill (Skill 1, 2, 3)
    var isSkillStriking = false // Skill 1
        private set
    var isSkill2Active = false  // Skill 2
        private set
    var isSkill3Active = false  // Skill 3
        private set
    private var skillTimer = 0f
    private var skill2Timer = 0f
    private var skill3Timer = 0f

    // Parameter Ultimate (Bladestorm / Phantom Flurry / Meteor Cleave)
    var isUlting = false
        private set
    private var ultTimer = 0f
    val ultRadius = 3.6f

    // Parameter Tangkisan Sempurna (Perfect Parry / Deflect - Fase 11)
    val isParrying: Boolean get() = isDodging && dodgeTimer <= PARRY_WINDOW
    var hasParryBuff: Boolean = false
        private set
    var parryBuffTimer: Float = 0f
        private set
    var onParry: ((Float, Float) -> Unit)? = null

    // God Mode Toggle untuk QA & Testing Tooling
    var isGodMode: Boolean = false

    /**
     * Hot-swap arketipe karakter secara real-time untuk developer & QA tooling.
     */
    fun switchArchetype(newArchetype: CharacterArchetype) {
        this.archetype = newArchetype
        skill1.name = newArchetype.skill1Name
        skill1.cooldown = newArchetype.skill1Cooldown
        skill2.name = newArchetype.skill2Name
        skill2.cooldown = newArchetype.skill2Cooldown
        skill3.name = newArchetype.skill3Name
        skill3.cooldown = newArchetype.skill3Cooldown
        ultimate.maxEnergy = newArchetype.ultEnergyCost
        attackPhase = AttackPhase.INACTIVE
        isSkillStriking = false
        isSkill2Active = false
        isSkill3Active = false
        isUlting = false
    }

    companion object {
        const val DODGE_DURATION = 0.22f
        const val DODGE_SPEED = 14.5f
        const val DODGE_COOLDOWN = 0.65f
        const val PARRY_WINDOW = 0.12f // Jendela 0.12s (7 frame) saat awal dodge roll

        const val SKILL_DURATION = 0.18f
        const val SKILL_SPEED = 22.0f

        const val ULT_DURATION = 0.45f

        val COLOR_PARRY_BODY = Color(1f, 0.95f, 0.4f, 1f)
        val COLOR_DODGE_BODY = Color(0.4f, 0.8f, 1f, 1f)
        val COLOR_SKILL_BODY = Color(0.85f, 0.45f, 1f, 1f)

        val COLOR_DAGGER = Color(0.4f, 0.9f, 1f, 0.95f)
        val COLOR_GREATSWORD_CORE = Color(0.3f, 0.3f, 0.35f, 1f)

        val COLOR_HEAVY_RUNE_HIT1 = Color(1f, 0.55f, 0.1f, 1f)
        val COLOR_HEAVY_RUNE_HIT2 = Color(1f, 0.25f, 0.1f, 1f)
        val COLOR_HEAVY_RUNE_HIT3 = Color(1f, 0.85f, 0.2f, 1f)

        val COLOR_SWORD_HIT1 = Color(0.9f, 0.95f, 1f, 1f)
        val COLOR_SWORD_HIT2 = Color(1f, 0.85f, 0.4f, 1f)
        val COLOR_SWORD_HIT3 = Color(1f, 0.45f, 0.2f, 1f)

        val COLOR_SLASH_AGILE = Color(0.3f, 0.95f, 1f, 0.95f)
        val COLOR_SLASH_HEAVY = Color(1f, 0.35f, 0.1f, 0.95f)
        val COLOR_SLASH_HIT1 = Color(1f, 0.95f, 0.3f, 0.85f)
        val COLOR_SLASH_HIT2 = Color(1f, 0.6f, 0.15f, 0.9f)
        val COLOR_SLASH_HIT3 = Color(1f, 0.2f, 0.25f, 0.95f)
    }

    var state: CharacterState = CharacterState.IDLE
        private set
    var isGrounded: Boolean = false
        private set
    var facingRight: Boolean = true
        internal set

    private var coyoteTimer: Float = 0f
    private var jumpBufferTimer: Float = 0f
    private var animTime: Float = 0f

    var maxAirJumps: Int = 1
    var airJumpsRemaining: Int = 1
    var cooldownMultiplier: Float = 1.0f

    // Modifikator Talent & Endless Mutator (Fase 13)
    var gravityScale: Float = 1.0f
    var damageReductionMultiplier: Float = 1.0f
    var hasSuperArmor: Boolean = false
    var hasUndyingWill: Boolean = false
    var undyingWillUsed: Boolean = false

    // Platforming & Combat Feel Enhancement (Senior Gameplay Programming)
    var ignoreOneWayTimer: Float = 0f

    fun update(delta: Float, input: GameInput, platforms: List<Platform>) {
        animTime += delta
        health.update(delta)
        skill1.update(delta)
        skill2.update(delta)
        skill3.update(delta)
        comboManager.update(delta, attackPhase != AttackPhase.INACTIVE)

        if (ignoreOneWayTimer > 0f) {
            ignoreOneWayTimer = (ignoreOneWayTimer - delta).coerceAtLeast(0f)
        }

        // Update proyektil aktif pemain
        val projIter = projectiles.iterator()
        while (projIter.hasNext()) {
            val p = projIter.next()
            p.update(delta)
            if (p.isDestroyed) projIter.remove()
        }

        if (dodgeCooldown > 0f) {
            dodgeCooldown = (dodgeCooldown - delta).coerceAtLeast(0f)
        }

        if (hasParryBuff) {
            parryBuffTimer = (parryBuffTimer - delta).coerceAtLeast(0f)
            if (parryBuffTimer <= 0f) {
                hasParryBuff = false
            }
        }

        hurtbox.set(position.x, position.y, width, height)

        if (!health.isDead) {
            // 1. Cek Pemicu Aksi Khusus
            handleActionTriggers(input, platforms)
        }

        // 2. Pembaruan State Khusus (Dodge, Skill, Ultimate, Combo)
        updateSpecialActions(delta)

        // 3. Gerak Horizontal & Fisika (Jika tidak dalam Dodge / Skill / Attack Startup)
        val canControlMove = !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting &&
                             (attackPhase == AttackPhase.INACTIVE || attackPhase == AttackPhase.RECOVERY)

        val moveDir = when {
            canControlMove && input.isMoveLeft() -> -1f
            canControlMove && input.isMoveRight() -> 1f
            else -> 0f
        }

        if (canControlMove) {
            if (moveDir != 0f) {
                facingRight = moveDir > 0
                val targetVx = moveDir * archetype.moveSpeed * (1f + stats.weaponSpdBonus)
                velocity.x = MathUtils.lerp(velocity.x, targetVx, (GameConfig.ACCELERATION * delta).coerceAtMost(1f))
            } else {
                velocity.x = MathUtils.lerp(velocity.x, 0f, (GameConfig.DECELERATION * delta).coerceAtMost(1f))
                if (abs(velocity.x) < 0.05f) velocity.x = 0f
            }
        }

        // 4. Coyote Time & Jump Buffer
        if (isGrounded) coyoteTimer = GameConfig.COYOTE_TIME
        else coyoteTimer = (coyoteTimer - delta).coerceAtLeast(0f)

        // Drop-through One-Way Platform (Down + Jump)
        if (input.isMoveDown() && input.isJumpJustPressed() && canControlMove && isGrounded) {
            val isOnOneWay = platforms.any {
                it.isOneWay && (bounds.overlaps(it.bounds) || (abs(position.y - it.top) < 0.25f && position.x + width > it.left && position.x < it.right))
            }
            if (isOnOneWay) {
                ignoreOneWayTimer = 0.28f
                position.y -= 0.18f
                velocity.y = -3.5f
                isGrounded = false
                jumpBufferTimer = 0f
                AudioManager.playDodge()
            }
        }

        if (input.isJumpJustPressed() && canControlMove && ignoreOneWayTimer <= 0f) jumpBufferTimer = GameConfig.JUMP_BUFFER_TIME
        else jumpBufferTimer = (jumpBufferTimer - delta).coerceAtLeast(0f)

        if (jumpBufferTimer > 0f) {
            if (coyoteTimer > 0f) {
                velocity.y = archetype.jumpVelocity
                jumpBufferTimer = 0f
                coyoteTimer = 0f
                isGrounded = false
                // Jump cancel on attack recovery untuk fluid action-combat
                if (attackPhase == AttackPhase.RECOVERY) {
                    attackPhase = AttackPhase.INACTIVE
                    hitbox.reset()
                }
                AudioManager.playJump()
                onJump?.invoke(position.x + width / 2f, position.y)
            } else if (airJumpsRemaining > 0 && canControlMove) {
                velocity.y = archetype.jumpVelocity * 0.95f
                airJumpsRemaining--
                jumpBufferTimer = 0f
                isGrounded = false
                if (attackPhase == AttackPhase.RECOVERY) {
                    attackPhase = AttackPhase.INACTIVE
                    hitbox.reset()
                }
                AudioManager.playJump()
                onJump?.invoke(position.x + width / 2f, position.y)
            }
        }

        // 5. Gravitasi & Kalibrasi Kurva Lompatan (Responsive Jump Curve & Apex Hang Time)
        val isFastFalling = !isGrounded && velocity.y < 0f && input.isMoveDown()
        val gravityMultiplier = when {
            isFastFalling -> 1.55f // Fast Fall saat menahan bawah di udara
            velocity.y > 0f && !input.isJumpPressed() -> 2.3f // Snappy Short-Hop Cut
            abs(velocity.y) < 1.8f && !isGrounded -> 0.75f // Apex Hang Time di puncak busur lompatan
            velocity.y < 0f -> 1.15f // Penurunan yang tegas & responsif
            else -> 1.0f
        }
        val maxFallSpeed = if (isFastFalling) -32f else -25f
        velocity.y += GameConfig.GRAVITY * gravityMultiplier * gravityScale * delta
        velocity.y = velocity.y.coerceAtLeast(maxFallSpeed)

        // 6. Resolusi Collision
        resolveCollisionX(delta, platforms)
        resolveCollisionY(delta, platforms)

        // 7. Update State Machine
        updateState()
    }

    /**
     * Mengeksekusi Tangkisan Sempurna (Perfect Parry):
     * Memulihkan +35% Ultimate Energy, memberikan buff +25% ATK balasan,
     * serta memicu dentingan logam dan getaran haptic berat.
     */
    fun triggerParry(): Boolean {
        ultimate.addEnergy(35f)
        hasParryBuff = true
        parryBuffTimer = 4.0f
        AudioManager.playParry()
        HapticManager.vibrateHeavy()
        onParry?.invoke(position.x + width / 2f, position.y + height / 2f)
        return true
    }

    private fun handleActionTriggers(input: GameInput, platforms: List<Platform>) {
        // Pemicu Dodge Roll
        if (input.isDodgeJustPressed() && !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting && dodgeCooldown <= 0f) {
            isDodging = true
            dodgeTimer = 0f
            dodgeCooldown = DODGE_COOLDOWN * cooldownMultiplier
            attackPhase = AttackPhase.INACTIVE
            hitbox.reset()
            afterimageCount = 0
            // Berikan i-Frames kebal penuh selama dodge
            health.takeDamage(0f)
            AudioManager.playDodge()
            HapticManager.vibrateLight()
            onDodge?.invoke(position.x + width / 2f, position.y)
            return
        }

        // Pemicu Skill 1 (Gale Crescent / Shadow Shuriken / Earth Shockwave)
        if ((input.isSkill1JustPressed() || input.isSkillJustPressed()) && skill1.isReady && !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting) {
            if (skill1.use(cooldownMultiplier)) {
                isSkillStriking = true
                skillTimer = 0f
                attackPhase = AttackPhase.INACTIVE
                val parryBonus = if (hasParryBuff) 1.25f else 1.0f
                if (hasParryBuff) {
                    hasParryBuff = false
                    parryBuffTimer = 0f
                }
                val dir = if (facingRight) 1f else -1f
                when (archetype) {
                    CharacterArchetype.BALANCED -> {
                        val (baseDmg, isCrit) = stats.calculateDamage(30f)
                        val finalDmg = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        projectiles.add(
                            Projectile(
                                startX = position.x + (if (facingRight) width + 0.1f else -1.3f),
                                startY = position.y + 0.5f,
                                velocityX = dir * 18f,
                                damage = finalDmg * 0.95f,
                                width = 1.2f,
                                height = 0.5f,
                                color = Color.CYAN
                            )
                        )
                        hitbox.damage = finalDmg
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 8.0f
                        hitbox.knockbackY = 3.5f
                        hitbox.reset()
                        AudioManager.playSlashHeavy()
                    }
                    CharacterArchetype.AGILE -> {
                        val (baseDmg, isCrit) = stats.calculateDamage(20f)
                        val finalDmg = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        val startPx = position.x + (if (facingRight) width else -0.6f)
                        projectiles.add(Projectile(startPx, position.y + 0.6f, dir * 22f, velocityY = 2.0f, damage = finalDmg * 0.75f, width = 0.5f, height = 0.5f, color = Color(0.85f, 0.45f, 1f, 1f)))
                        projectiles.add(Projectile(startPx, position.y + 0.6f, dir * 24f, velocityY = 0f, damage = finalDmg * 0.85f, width = 0.6f, height = 0.5f, color = Color(0.85f, 0.45f, 1f, 1f)))
                        projectiles.add(Projectile(startPx, position.y + 0.6f, dir * 22f, velocityY = -2.0f, damage = finalDmg * 0.75f, width = 0.5f, height = 0.5f, color = Color(0.85f, 0.45f, 1f, 1f)))
                        hitbox.damage = finalDmg
                        hitbox.isCritical = isCrit || (Random.nextFloat() < 0.25f)
                        hitbox.knockbackX = 6.0f
                        hitbox.knockbackY = 2.0f
                        hitbox.reset()
                        AudioManager.playSlashLight()
                    }
                    CharacterArchetype.HEAVY -> {
                        val (baseDmg, isCrit) = stats.calculateDamage(44f)
                        val finalDmg = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        projectiles.add(
                            Projectile(
                                startX = position.x + (if (facingRight) width + 0.1f else -1.5f),
                                startY = position.y,
                                velocityX = dir * 13f,
                                damage = finalDmg,
                                width = 1.4f,
                                height = 1.1f,
                                color = Color(1f, 0.55f, 0.15f, 1f)
                            )
                        )
                        hitbox.damage = finalDmg
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 12.0f
                        hitbox.knockbackY = 5.5f
                        hitbox.reset()
                        AudioManager.playSlashHeavy()
                    }
                }
                HapticManager.vibrateMedium()
                return
            }
        }

        // Pemicu Skill 2 (Rising Dragon / Venom Flurry / Cyclone Cleave)
        if (input.isSkill2JustPressed() && skill2.isReady && !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting) {
            if (skill2.use(cooldownMultiplier)) {
                isSkill2Active = true
                skill2Timer = 0f
                attackPhase = AttackPhase.INACTIVE
                val parryBonus = if (hasParryBuff) 1.25f else 1.0f
                if (hasParryBuff) {
                    hasParryBuff = false
                    parryBuffTimer = 0f
                }
                val dir = if (facingRight) 1f else -1f
                when (archetype) {
                    CharacterArchetype.BALANCED -> {
                        velocity.y = 11.5f
                        velocity.x = dir * 3.5f
                        isGrounded = false
                        val (baseDmg, isCrit) = stats.calculateDamage(36f)
                        hitbox.damage = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 3.5f
                        hitbox.knockbackY = 10.5f
                        hitbox.reset()
                        AudioManager.playJump()
                        AudioManager.playSlashHeavy()
                    }
                    CharacterArchetype.AGILE -> {
                        velocity.x = dir * 3.0f
                        val (baseDmg, isCrit) = stats.calculateDamage(38f)
                        hitbox.damage = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 4.5f
                        hitbox.knockbackY = 2.0f
                        hitbox.reset()
                        AudioManager.playSlashLight()
                    }
                    CharacterArchetype.HEAVY -> {
                        velocity.x = dir * 4.5f
                        val (baseDmg, isCrit) = stats.calculateDamage(52f)
                        hitbox.damage = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 12.0f
                        hitbox.knockbackY = 4.0f
                        hitbox.reset()
                        AudioManager.playSlashHeavy()
                    }
                }
                HapticManager.vibrateMedium()
                return
            }
        }

        // Pemicu Skill 3 (Dash Strike / Phantom Blink / Titan Roar)
        if (input.isSkill3JustPressed() && skill3.isReady && !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting) {
            if (skill3.use(cooldownMultiplier)) {
                isSkill3Active = true
                skill3Timer = 0f
                attackPhase = AttackPhase.INACTIVE
                val parryBonus = if (hasParryBuff) 1.25f else 1.0f
                if (hasParryBuff) {
                    hasParryBuff = false
                    parryBuffTimer = 0f
                }
                val dir = if (facingRight) 1f else -1f
                when (archetype) {
                    CharacterArchetype.BALANCED -> {
                        velocity.x = dir * SKILL_SPEED
                        velocity.y = 0f
                        val (baseDmg, isCrit) = stats.calculateDamage(35f)
                        hitbox.damage = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 9.0f
                        hitbox.knockbackY = 3.5f
                        hitbox.reset()
                        AudioManager.playSlashHeavy()
                    }
                    CharacterArchetype.AGILE -> {
                        var targetX = position.x + dir * 4.5f
                        // Cek tabrakan terhadap platform solid (non one-way) di sepanjang lintasan teleportasi agar tidak tembus dinding
                        for (platform in platforms) {
                            if (platform.isOneWay) continue
                            val yOverlap = (position.y < platform.top) && (position.y + height > platform.bottom)
                            if (yOverlap) {
                                if (dir > 0f && position.x + width <= platform.left && targetX + width > platform.left) {
                                    targetX = platform.left - width - 0.05f
                                } else if (dir < 0f && position.x >= platform.right && targetX < platform.right) {
                                    targetX = platform.right + 0.05f
                                }
                            }
                        }
                        position.x = targetX
                        velocity.x = dir * 1.5f
                        bounds.setPosition(position.x, position.y)
                        val (baseDmg, _) = stats.calculateDamage(44f)
                        hitbox.damage = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        hitbox.isCritical = true
                        hitbox.knockbackX = 8.0f
                        hitbox.knockbackY = 2.5f
                        hitbox.reset()
                        AudioManager.playDodge()
                        AudioManager.playSlashHeavy()
                    }
                    CharacterArchetype.HEAVY -> {
                        health.heal(health.maxHp * 0.15f)
                        val (baseDmg, isCrit) = stats.calculateDamage(34f)
                        hitbox.damage = baseDmg * archetype.baseDamageMultiplier * parryBonus
                        hitbox.isCritical = isCrit
                        hitbox.knockbackX = 14.0f
                        hitbox.knockbackY = 5.0f
                        hitbox.reset()
                        AudioManager.playHit()
                        AudioManager.playSlashHeavy()
                    }
                }
                HapticManager.vibrateMedium()
                return
            }
        }

        // Pemicu Ultimate (Bladestorm / Phantom Flurry / Meteor Cleave)
        if (input.isUltimateJustPressed() && ultimate.isReady && !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting) {
            if (ultimate.consume()) {
                isUlting = true
                ultTimer = 0f
                attackPhase = AttackPhase.INACTIVE
                velocity.set(0f, 0f)
                val parryBonus = if (hasParryBuff) 1.25f else 1.0f
                if (hasParryBuff) {
                    hasParryBuff = false
                    parryBuffTimer = 0f
                }
                val (baseDmg, isCrit) = stats.calculateDamage(65f)
                val finalDmg = baseDmg * archetype.baseDamageMultiplier * parryBonus
                val finalCrit = isCrit || (Random.nextFloat() < archetype.baseCritBonus)
                hitbox.damage = finalDmg
                hitbox.isCritical = finalCrit
                hitbox.knockbackX = 14.0f
                hitbox.knockbackY = 7.0f
                hitbox.reset()
                AudioManager.playSlashHeavy()
                HapticManager.vibrateHeavy()
                return
            }
        }

        // Pemicu Serangan Kombo (Attack)
        if (input.isAttackJustPressed() && !isDodging && !isSkillStriking && !isSkill2Active && !isSkill3Active && !isUlting) {
            if (attackPhase == AttackPhase.INACTIVE) {
                val hitConfig = comboManager.startNextHit()
                attackPhase = AttackPhase.STARTUP
                attackTimer = 0f
                val parryBonus = if (hasParryBuff) 1.25f else 1.0f
                if (hasParryBuff) {
                    hasParryBuff = false
                    parryBuffTimer = 0f
                }
                val (baseDmg, isCrit) = stats.calculateDamage(hitConfig.damage)
                val finalDmg = baseDmg * archetype.baseDamageMultiplier * parryBonus
                val finalCrit = isCrit || (Random.nextFloat() < archetype.baseCritBonus)
                hitbox.damage = finalDmg
                hitbox.isCritical = finalCrit
                hitbox.knockbackX = hitConfig.knockbackX * if (archetype == CharacterArchetype.HEAVY) 1.35f else 1f
                hitbox.knockbackY = hitConfig.knockbackY
                hitbox.reset()
                velocity.x *= 0.3f
                if (archetype == CharacterArchetype.HEAVY || comboManager.currentStep == ComboStep.HIT_3) {
                    AudioManager.playSlashHeavy()
                } else {
                    AudioManager.playSlashLight()
                }
            } else if (attackPhase == AttackPhase.RECOVERY || (attackPhase == AttackPhase.ACTIVE && attackTimer > 0.06f)) {
                comboManager.hasBufferedInput = true
            }
        }
    }

    private fun updateSpecialActions(delta: Float) {
        // A. Update Dodge
        if (isDodging) {
            dodgeTimer += delta
            val dashDir = if (facingRight) 1f else -1f
            velocity.x = dashDir * DODGE_SPEED
            velocity.y = 0f // Meluncur lurus

            // Simpan jejak afterimage (Zero-allocation pool)
            if (afterimageCount < afterimagePool.size) {
                afterimagePool[afterimageCount].set(position.x, position.y)
                afterimageCount++
            }

            if (dodgeTimer >= DODGE_DURATION) {
                isDodging = false
                velocity.x *= 0.3f
                afterimageCount = 0
            }
            return
        }

        // B. Update Skill 1 (Gale Crescent / Shadow Shuriken / Earth Shockwave)
        if (isSkillStriking) {
            skillTimer += delta
            val strikeDir = if (facingRight) 1f else -1f
            if (archetype == CharacterArchetype.BALANCED) {
                velocity.x = strikeDir * 8f
            } else if (archetype == CharacterArchetype.HEAVY) {
                velocity.x = strikeDir * 4f
            }

            // Aktifkan Hitbox Dash Strike di sepanjang tubuh
            hitbox.set(position.x - 0.2f, position.y, width + 0.8f, height, active = true)

            if (skillTimer >= SKILL_DURATION) {
                isSkillStriking = false
                hitbox.reset()
                velocity.x *= 0.2f
            }
            return
        }

        // B2. Update Skill 2 (Rising Dragon / Venom Flurry / Cyclone Cleave)
        if (isSkill2Active) {
            skill2Timer += delta
            val dur = when (archetype) {
                CharacterArchetype.BALANCED -> 0.32f
                CharacterArchetype.AGILE -> 0.30f
                CharacterArchetype.HEAVY -> 0.38f
            }

            when (archetype) {
                CharacterArchetype.BALANCED -> {
                    hitbox.set(position.x - 0.2f, position.y, width + 0.7f, height + 0.6f, active = true)
                }
                CharacterArchetype.AGILE -> {
                    val hbX = if (facingRight) position.x + width * 0.4f else position.x - 1.2f + width * 0.4f
                    hitbox.set(hbX, position.y + 0.1f, 1.4f, 1.2f, active = true)
                }
                CharacterArchetype.HEAVY -> {
                    hitbox.set(position.x - 0.5f, position.y, width + 1.0f, height + 0.4f, active = true)
                }
            }

            if (skill2Timer >= dur) {
                isSkill2Active = false
                hitbox.reset()
                velocity.x *= 0.2f
            }
            return
        }

        // B3. Update Skill 3 (Dash Strike / Phantom Blink / Titan Roar)
        if (isSkill3Active) {
            skill3Timer += delta
            val dur = when (archetype) {
                CharacterArchetype.BALANCED -> 0.22f
                CharacterArchetype.AGILE -> 0.15f
                CharacterArchetype.HEAVY -> 0.32f
            }

            when (archetype) {
                CharacterArchetype.BALANCED -> {
                    val strikeDir = if (facingRight) 1f else -1f
                    velocity.x = strikeDir * SKILL_SPEED
                    velocity.y = 0f
                    hitbox.set(position.x - 0.2f, position.y, width + 0.8f, height, active = true)
                }
                CharacterArchetype.AGILE -> {
                    val hbX = if (facingRight) position.x + width * 0.3f else position.x - 1.2f
                    hitbox.set(hbX, position.y, 1.5f, 1.2f, active = true)
                }
                CharacterArchetype.HEAVY -> {
                    velocity.x = 0f
                    hitbox.set(position.x - 1.2f, position.y, width + 2.4f, height + 1.0f, active = true)
                }
            }

            if (skill3Timer >= dur) {
                isSkill3Active = false
                hitbox.reset()
                velocity.x *= 0.2f
            }
            return
        }

        // C. Update Ultimate (Bladestorm)
        if (isUlting) {
            ultTimer += delta
            velocity.set(0f, 0f) // Mengambang di udara/tanah saat melepaskan badai

            // Hitbox Radial 360 Derajat
            val centerX = position.x + width / 2f
            val centerY = position.y + height / 2f
            hitbox.set(centerX - ultRadius, centerY - ultRadius, ultRadius * 2f, ultRadius * 2f, active = true)

            if (ultTimer >= ULT_DURATION) {
                isUlting = false
                hitbox.reset()
            }
            return
        }

        // D. Update Siklus Serangan Kombo Biasa
        if (attackPhase != AttackPhase.INACTIVE) {
            attackTimer += delta
            val cfg = comboManager.currentConfig

            when {
                attackTimer < cfg.startup -> {
                    attackPhase = AttackPhase.STARTUP
                    hitbox.isActive = false
                }
                attackTimer < cfg.startup + cfg.active -> {
                    attackPhase = AttackPhase.ACTIVE
                    val hbW = if (comboManager.currentStep == ComboStep.HIT_3) 1.6f else 1.3f
                    val hbH = if (comboManager.currentStep == ComboStep.HIT_3) 1.6f else 1.3f
                    val hbX = if (facingRight) position.x + width * 0.6f else position.x - hbW + width * 0.4f
                    val hbY = position.y + 0.35f
                    hitbox.set(hbX, hbY, hbW, hbH, active = true)
                }
                attackTimer < cfg.totalTime -> {
                    attackPhase = AttackPhase.RECOVERY
                    hitbox.isActive = false
                }
                else -> {
                    // Serangan selesai: cek apakah ada buffer combo untuk pukulan berikutnya
                    if (comboManager.hasBufferedInput) {
                        val nextCfg = comboManager.startNextHit()
                        attackPhase = AttackPhase.STARTUP
                        attackTimer = 0f
                        val (baseDmg, isCrit) = stats.calculateDamage(nextCfg.damage)
                        val finalDmg = baseDmg * archetype.baseDamageMultiplier
                        val finalCrit = isCrit || (Random.nextFloat() < archetype.baseCritBonus)
                        hitbox.damage = finalDmg
                        hitbox.isCritical = finalCrit
                        hitbox.knockbackX = nextCfg.knockbackX * if (archetype == CharacterArchetype.HEAVY) 1.35f else 1f
                        hitbox.knockbackY = nextCfg.knockbackY
                        hitbox.reset()
                        if (archetype == CharacterArchetype.HEAVY || comboManager.currentStep == ComboStep.HIT_3) {
                            AudioManager.playSlashHeavy()
                        } else {
                            AudioManager.playSlashLight()
                        }
                    } else {
                        attackPhase = AttackPhase.INACTIVE
                        hitbox.reset()
                    }
                }
            }
        }
    }

    private fun resolveCollisionX(delta: Float, platforms: List<Platform>) {
        position.x += velocity.x * delta
        bounds.setPosition(position.x, position.y)

        for (platform in platforms) {
            // Abaikan tabrakan horizontal pada One-Way Platform
            if (platform.isOneWay) continue

            if (bounds.overlaps(platform.bounds)) {
                if (velocity.x > 0f) {
                    position.x = platform.left - width
                    velocity.x = 0f
                } else if (velocity.x < 0f) {
                    position.x = platform.right
                    velocity.x = 0f
                }
                bounds.setPosition(position.x, position.y)
            }
        }
    }

    private fun resolveCollisionY(delta: Float, platforms: List<Platform>) {
        val wasGrounded = isGrounded
        val previousY = position.y
        isGrounded = false
        position.y += velocity.y * delta
        bounds.setPosition(position.x, position.y)

        for (platform in platforms) {
            if (platform.isOneWay) {
                // Abaikan jika sedang dalam masa drop-through (Down + Jump)
                if (ignoreOneWayTimer > 0f) continue
                // One-Way Platform: Hanya mendarat jika sedang jatuh dari atas platform
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

        if (isGrounded) {
            airJumpsRemaining = maxAirJumps
        }

        if (!wasGrounded && isGrounded) {
            onLand?.invoke(position.x + width / 2f, position.y)
        }
    }

    private fun updateState() {
        state = when {
            isUlting || isSkillStriking || isSkill2Active || isSkill3Active || attackPhase != AttackPhase.INACTIVE -> CharacterState.ATTACK
            health.isFlashing -> CharacterState.HURT
            !isGrounded && velocity.y > 0.5f -> CharacterState.JUMP
            !isGrounded && velocity.y <= 0.5f -> CharacterState.FALL
            isGrounded && abs(velocity.x) > 0.1f -> CharacterState.RUN
            else -> CharacterState.IDLE
        }
    }

    fun takeHit(amount: Float, knockDirX: Float, knockDirY: Float): Boolean {
        // QA & Tooling God Mode
        if (isGodMode) return false

        // Jika sedang dalam Dodge Roll, kebal dari serangan musuh!
        if (isDodging) return false

        val effectiveDef = stats.defense + archetype.baseDefenseBonus
        val mitigatedDmg = kotlin.math.max(1f, (amount - effectiveDef) * damageReductionMultiplier)

        // Cek Undying Will saat damage mematikan (Fase 13 Berserker)
        if (health.currentHp <= mitigatedDmg && hasUndyingWill && !undyingWillUsed) {
            undyingWillUsed = true
            health.takeDamage(health.currentHp - 1f)
            HapticManager.vibrateHeavy()
            return true
        }

        if (health.takeDamage(mitigatedDmg)) {
            if (!hasSuperArmor) {
                velocity.x = knockDirX
                velocity.y = knockDirY
            }
            HapticManager.vibrateHeavy()
            return true
        }
        return false
    }

    /**
     * Dipanggil saat pemain naik level:
     * Menyesuaikan Max HP dengan stat baru dan memulihkan HP secara penuh.
     */
    fun onLevelUp(levelsGained: Int) {
        health.maxHp = stats.maxHp
        health.reset()
    }

    /**
     * Mereset status HP dan energi sesuai statistik tersimpan.
     */
    fun resetToStats() {
        health.maxHp = stats.maxHp
        health.reset()
        ultimate.reset()
    }

    /**
     * Mereset status karakter secara lengkap saat respawn di checkpoint.
     * Mengatur ulang HP, energi, bounds, hurtbox, dan membersihkan seluruh status tempur aktif.
     */
    fun respawn(spawnX: Float, spawnY: Float) {
        position.set(spawnX, spawnY)
        velocity.set(0f, 0f)
        bounds.setPosition(spawnX, spawnY)
        hurtbox.set(spawnX, spawnY, width, height)
        hitbox.reset()

        isGrounded = false
        coyoteTimer = 0f
        jumpBufferTimer = 0f
        airJumpsRemaining = maxAirJumps

        isDodging = false
        dodgeTimer = 0f
        dodgeCooldown = 0f
        afterimageCount = 0

        isSkillStriking = false
        skillTimer = 0f

        isUlting = false
        ultTimer = 0f

        attackPhase = AttackPhase.INACTIVE
        attackTimer = 0f
        comboManager.resetToHit1()

        hasParryBuff = false
        parryBuffTimer = 0f
        undyingWillUsed = false

        health.maxHp = stats.maxHp
        health.reset()
        ultimate.reset()
    }

    fun render(shapeRenderer: ShapeRenderer) {
        val centerX = position.x + width / 2f
        val footY = position.y
        val headRadius = 0.22f
        val headCenterY = position.y + height - headRadius - 0.05f
        val neckY = headCenterY - headRadius
        val pelvisY = position.y + 0.75f
        val shoulderY = neckY - 0.15f
        val lookDir = if (facingRight) 1f else -1f

        // 1. Gambar Afterimages (Jejak Bayangan saat Dodge Roll - Zero Allocation)
        if (isDodging) {
            for (idx in 0 until afterimageCount) {
                val ghost = afterimagePool[idx]
                val alpha = (0.2f * (idx + 1)).coerceIn(0.1f, 0.6f)
                val r = if (isParrying) 1f else 0.3f
                val g = if (isParrying) 0.9f else 0.7f
                val b = if (isParrying) 0.3f else 1f
                shapeRenderer.setColor(r, g, b, alpha)
                shapeRenderer.circle(ghost.x + width / 2f, ghost.y + height - headRadius - 0.05f, headRadius, 10)
                shapeRenderer.rectLine(ghost.x + width / 2f, ghost.y + 0.75f, ghost.x + width / 2f, ghost.y, 0.06f)
            }
        }

        // Aura Emas Berkilau saat Parry Buff Aktif (+25% Damage Balasan)
        if (hasParryBuff && !isDodging && !isUlting) {
            val auraPulse = 0.35f + kotlin.math.sin(animTime * 12f) * 0.15f
            shapeRenderer.setColor(1f, 0.85f, 0.2f, auraPulse)
            shapeRenderer.circle(centerX, pelvisY + 0.15f, 0.68f, 16)
        }

        // 2. Warna Tubuh (Biru saat Dodge, Ungu saat Skill, Emas saat Ult/Parry, Merah saat Hurt, Putih normal)
        val bodyColor = when {
            health.isFlashing -> Color.RED
            isParrying -> COLOR_PARRY_BODY
            isDodging -> COLOR_DODGE_BODY
            isSkillStriking || isSkill2Active || isSkill3Active -> COLOR_SKILL_BODY
            isUlting || hasParryBuff -> Color.GOLD
            else -> Color.WHITE
        }
        shapeRenderer.color = bodyColor

        // Kepala
        shapeRenderer.circle(centerX, headCenterY, headRadius, 16)

        // Mata
        shapeRenderer.color = if (health.isFlashing) Color.YELLOW else Color.DARK_GRAY
        val eyeX = centerX + (headRadius * 0.45f * lookDir)
        val eyeY = headCenterY + 0.04f
        shapeRenderer.circle(eyeX, eyeY, 0.04f, 8)

        // Tulang Belakang
        shapeRenderer.color = bodyColor
        shapeRenderer.rectLine(centerX, neckY, centerX, pelvisY, 0.08f)

        // Kaki & Tangan
        var legSwing = 0f
        var armSwing = 0f

        when {
            isDodging -> {
                legSwing = -0.4f // Kaki menekuk meluncur
                armSwing = -0.5f
            }
            state == CharacterState.RUN -> {
                val cycle = sin(animTime * 14f)
                legSwing = cycle * 0.38f
                armSwing = -cycle * 0.35f
            }
            state == CharacterState.JUMP -> {
                legSwing = -0.15f
                armSwing = 0.3f
            }
            state == CharacterState.FALL -> {
                legSwing = 0.12f
                armSwing = 0.2f
            }
            state == CharacterState.ATTACK -> {
                legSwing = 0.1f
                armSwing = 0.7f
            }
            else -> {
                legSwing = 0.04f
                armSwing = sin(animTime * 3f) * 0.02f
            }
        }

        val legLeftFootX = centerX - 0.12f * lookDir + (legSwing * lookDir)
        val legRightFootX = centerX + 0.12f * lookDir - (legSwing * lookDir)
        shapeRenderer.rectLine(centerX, pelvisY, legLeftFootX, footY, 0.07f)
        shapeRenderer.rectLine(centerX, pelvisY, legRightFootX, footY, 0.07f)

        // Tangan Belakang
        val armBackHandX = centerX - 0.25f * lookDir - (armSwing * lookDir * 0.5f)
        val armBackHandY = shoulderY - 0.35f
        shapeRenderer.rectLine(centerX, shoulderY, armBackHandX, armBackHandY, 0.06f)

        // Belati Tangan Belakang jika AGILE (Dual Daggers)
        if (archetype == CharacterArchetype.AGILE) {
            val daggerBackTipX = armBackHandX - 0.35f * lookDir
            val daggerBackTipY = armBackHandY + 0.30f
            shapeRenderer.color = COLOR_DAGGER
            shapeRenderer.rectLine(armBackHandX, armBackHandY, daggerBackTipX, daggerBackTipY, 0.05f)
        }

        // Tangan Depan (Pegang Senjata Utama)
        val armFrontHandX: Float
        val armFrontHandY: Float
        val swordTipX: Float
        val swordTipY: Float

        if (attackPhase == AttackPhase.STARTUP) {
            armFrontHandX = centerX - 0.15f * lookDir
            armFrontHandY = shoulderY + 0.2f
            swordTipX = armFrontHandX - 0.8f * lookDir
            swordTipY = armFrontHandY + 0.6f
        } else if (attackPhase == AttackPhase.ACTIVE || isSkillStriking || isSkill2Active || isSkill3Active) {
            armFrontHandX = centerX + 0.45f * lookDir
            armFrontHandY = shoulderY - 0.05f
            swordTipX = armFrontHandX + 1.0f * lookDir
            swordTipY = armFrontHandY - 0.15f
        } else {
            armFrontHandX = centerX + 0.25f * lookDir + (armSwing * lookDir)
            armFrontHandY = shoulderY - 0.35f
            swordTipX = armFrontHandX + 0.6f * lookDir
            swordTipY = armFrontHandY - 0.4f
        }

        shapeRenderer.rectLine(centerX, shoulderY, armFrontHandX, armFrontHandY, 0.06f)

        // Rendering Senjata Berdasarkan Arketipe (Bilah Pedang / Dagger / Greatsword)
        if (archetype == CharacterArchetype.AGILE) {
            val daggerFrontTipX = armFrontHandX + (if (attackPhase == AttackPhase.ACTIVE) 0.55f else 0.40f) * lookDir
            val daggerFrontTipY = armFrontHandY + (if (attackPhase == AttackPhase.ACTIVE) -0.1f else -0.25f)
            shapeRenderer.color = COLOR_DAGGER
            shapeRenderer.rectLine(armFrontHandX, armFrontHandY, daggerFrontTipX, daggerFrontTipY, 0.06f)
        } else if (archetype == CharacterArchetype.HEAVY) {
            // Colossal Greatsword: Broad slab with glowing runes and crossguard
            val heavyTipX = armFrontHandX + (swordTipX - armFrontHandX) * 1.35f
            val heavyTipY = armFrontHandY + (swordTipY - armFrontHandY) * 1.35f

            // Blade Core
            shapeRenderer.color = COLOR_GREATSWORD_CORE
            shapeRenderer.rectLine(armFrontHandX, armFrontHandY, heavyTipX, heavyTipY, 0.16f)

            // Glowing Rune Edge
            shapeRenderer.color = when (comboManager.currentStep) {
                ComboStep.HIT_1 -> COLOR_HEAVY_RUNE_HIT1
                ComboStep.HIT_2 -> COLOR_HEAVY_RUNE_HIT2
                ComboStep.HIT_3 -> COLOR_HEAVY_RUNE_HIT3
            }
            shapeRenderer.rectLine(armFrontHandX, armFrontHandY, heavyTipX, heavyTipY, 0.08f)

            // Crossguard
            val guardPerpX = -(heavyTipY - armFrontHandY) * 0.12f
            val guardPerpY = (heavyTipX - armFrontHandX) * 0.12f
            val guardBaseX = armFrontHandX + (heavyTipX - armFrontHandX) * 0.12f
            val guardBaseY = armFrontHandY + (heavyTipY - armFrontHandY) * 0.12f
            shapeRenderer.color = Color.GOLD
            shapeRenderer.rectLine(guardBaseX - guardPerpX, guardBaseY - guardPerpY, guardBaseX + guardPerpX, guardBaseY + guardPerpY, 0.10f)
        } else {
            // BALANCED: Standard Sword
            shapeRenderer.color = when (comboManager.currentStep) {
                ComboStep.HIT_1 -> COLOR_SWORD_HIT1
                ComboStep.HIT_2 -> COLOR_SWORD_HIT2
                ComboStep.HIT_3 -> COLOR_SWORD_HIT3
            }
            shapeRenderer.rectLine(armFrontHandX, armFrontHandY, swordTipX, swordTipY, 0.08f)

            // Crossguard
            val guardPerpX = -(swordTipY - armFrontHandY) * 0.10f
            val guardPerpY = (swordTipX - armFrontHandX) * 0.10f
            val guardBaseX = armFrontHandX + (swordTipX - armFrontHandX) * 0.12f
            val guardBaseY = armFrontHandY + (swordTipY - armFrontHandY) * 0.12f
            shapeRenderer.color = Color.GOLD
            shapeRenderer.rectLine(guardBaseX - guardPerpX, guardBaseY - guardPerpY, guardBaseX + guardPerpX, guardBaseY + guardPerpY, 0.06f)
        }

        // 3. Efek Visual Tebasan Kombo
        if (attackPhase == AttackPhase.ACTIVE) {
            renderComboSlashArc(shapeRenderer, centerX, shoulderY, lookDir)
        }

        // 4. Efek Visual Ultimate Bladestorm 360 Derajat
        if (isUlting) {
            renderBladestorm(shapeRenderer, centerX, shoulderY)
        }

        // 5. Efek Visual Skill 2 & Skill 3
        if (isSkill2Active) {
            renderSkill2Visual(shapeRenderer, centerX, shoulderY, lookDir)
        }
        if (isSkill3Active) {
            renderSkill3Visual(shapeRenderer, centerX, shoulderY, lookDir)
        }
    }

    private fun renderComboSlashArc(shapeRenderer: ShapeRenderer, centerX: Float, centerY: Float, lookDir: Float) {
        val (arcRadiusMult, arcColorOverride) = when (archetype) {
            CharacterArchetype.AGILE -> 0.85f to COLOR_SLASH_AGILE // Cyan rapid slash
            CharacterArchetype.HEAVY -> 1.45f to COLOR_SLASH_HEAVY // Colossal fiery orange slash
            CharacterArchetype.BALANCED -> 1.0f to null
        }
        val (baseRadius, defaultColor) = when (comboManager.currentStep) {
            ComboStep.HIT_1 -> 1.15f to COLOR_SLASH_HIT1      // Hit 1: Kuning Emas
            ComboStep.HIT_2 -> 1.35f to COLOR_SLASH_HIT2       // Hit 2: Oranye Api
            ComboStep.HIT_3 -> 1.70f to COLOR_SLASH_HIT3      // Hit 3: Merah Raksasa (Finisher)
        }
        val arcRadius = baseRadius * arcRadiusMult
        val arcColor = arcColorOverride ?: defaultColor

        shapeRenderer.color = arcColor
        val arcCenterX = centerX + 0.25f * lookDir
        val arcCenterY = centerY - 0.1f

        val segments = 10
        val startAngle = if (lookDir > 0) 70f else 110f
        val sweep = if (lookDir > 0) -130f else 130f

        var prevX = arcCenterX + arcRadius * MathUtils.cosDeg(startAngle)
        var prevY = arcCenterY + arcRadius * MathUtils.sinDeg(startAngle)

        for (i in 1..segments) {
            val angle = startAngle + (sweep * (i.toFloat() / segments))
            val currentRadius = arcRadius + sin(i.toFloat() / segments * MathUtils.PI) * 0.2f
            val curX = arcCenterX + currentRadius * MathUtils.cosDeg(angle)
            val curY = arcCenterY + currentRadius * MathUtils.sinDeg(angle)

            val width = 0.07f + sin(i.toFloat() / segments * MathUtils.PI) * 0.12f
            shapeRenderer.rectLine(prevX, prevY, curX, curY, width)

            prevX = curX
            prevY = curY
        }
    }

    private fun renderBladestorm(shapeRenderer: ShapeRenderer, centerX: Float, centerY: Float) {
        // Lingkaran Radial Badai Pedang
        val expand = (ultTimer / ULT_DURATION) * ultRadius
        shapeRenderer.setColor(1f, 0.85f, 0.2f, 0.5f)
        shapeRenderer.circle(centerX, centerY, expand, 24)

        // Cincin Luar Cahaya Emas
        shapeRenderer.color = Color.WHITE
        shapeRenderer.circle(centerX, centerY, expand * 0.95f, 20)
    }

    private fun renderSkill2Visual(shapeRenderer: ShapeRenderer, centerX: Float, centerY: Float, lookDir: Float) {
        when (archetype) {
            CharacterArchetype.BALANCED -> {
                // Rising Dragon: Dragon claw / ascending aura
                shapeRenderer.color = Color.CYAN
                shapeRenderer.rectLine(centerX - 0.2f * lookDir, centerY - 0.8f, centerX + 0.5f * lookDir, centerY + 1.2f, 0.16f)
                shapeRenderer.color = Color.WHITE
                shapeRenderer.rectLine(centerX, centerY - 0.4f, centerX + 0.3f * lookDir, centerY + 1.0f, 0.08f)
            }
            CharacterArchetype.AGILE -> {
                // Venom Flurry: Triple violet slash arcs
                shapeRenderer.color = Color(0.85f, 0.35f, 1f, 1f)
                shapeRenderer.rectLine(centerX, centerY + 0.3f, centerX + 1.2f * lookDir, centerY + 0.5f, 0.12f)
                shapeRenderer.rectLine(centerX, centerY, centerX + 1.4f * lookDir, centerY - 0.1f, 0.14f)
                shapeRenderer.rectLine(centerX, centerY - 0.3f, centerX + 1.1f * lookDir, centerY - 0.4f, 0.12f)
            }
            CharacterArchetype.HEAVY -> {
                // Cyclone Cleave: Whirling fire ring
                shapeRenderer.color = Color(1f, 0.55f, 0.1f, 0.8f)
                shapeRenderer.circle(centerX, centerY, 1.4f, 16)
                shapeRenderer.color = Color.GOLD
                shapeRenderer.circle(centerX, centerY, 1.1f, 12)
            }
        }
    }

    private fun renderSkill3Visual(shapeRenderer: ShapeRenderer, centerX: Float, centerY: Float, lookDir: Float) {
        when (archetype) {
            CharacterArchetype.BALANCED -> {
                // Dash Strike: Piercing beam thrust
                shapeRenderer.color = Color(0.3f, 0.85f, 1f, 0.9f)
                shapeRenderer.rectLine(centerX - 1.2f * lookDir, centerY, centerX + 1.8f * lookDir, centerY, 0.18f)
                shapeRenderer.color = Color.WHITE
                shapeRenderer.rectLine(centerX - 0.6f * lookDir, centerY, centerX + 1.6f * lookDir, centerY, 0.08f)
            }
            CharacterArchetype.AGILE -> {
                // Phantom Blink: Glitch rift circle
                shapeRenderer.color = Color(0.9f, 0.4f, 1f, 0.9f)
                shapeRenderer.circle(centerX, centerY, 0.9f, 12)
                shapeRenderer.color = Color.WHITE
                shapeRenderer.circle(centerX, centerY, 0.5f, 8)
            }
            CharacterArchetype.HEAVY -> {
                // Titan Roar: Ground shockwave ring
                val progress = (skill3Timer / 0.32f).coerceIn(0f, 1f)
                shapeRenderer.color = Color(1f, 0.7f, 0.2f, 1f - progress)
                shapeRenderer.circle(centerX, position.y + 0.1f, 2.2f * progress, 20)
                shapeRenderer.color = Color.RED
                shapeRenderer.circle(centerX, position.y + 0.1f, 1.4f * progress, 16)
            }
        }
    }

    fun renderProjectiles(shapeRenderer: ShapeRenderer) {
        for (i in 0 until projectiles.size) {
            projectiles[i].render(shapeRenderer)
        }
    }

    fun renderDebug(shapeRenderer: ShapeRenderer) {
        shapeRenderer.color = Color.GREEN
        shapeRenderer.rect(bounds.x, bounds.y, bounds.width, bounds.height)

        hurtbox.renderDebug(shapeRenderer)
        hitbox.renderDebug(shapeRenderer)
    }
}
