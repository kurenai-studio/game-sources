package com.darumahq.rainbowclimb.world

import com.darumahq.rainbowclimb.entity.*
import com.darumahq.rainbowclimb.util.Constants
import com.darumahq.rainbowclimb.util.SeededRandom

class World(seed: Long = System.currentTimeMillis()) {
    val currentSeed = seed
    val random = SeededRandom(seed)
    val player = Player()
    val generator = ChunkGenerator(random)

    val platforms = mutableListOf<Platform>()
    val enemies = mutableListOf<Enemy>()
    val collectibles = mutableListOf<Collectible>()
    val rainbows = mutableListOf<Rainbow>()
    val projectiles = mutableListOf<Projectile>()
    val boss = Boss()

    // Staging lists to avoid concurrent modification
    private val pendingProjectiles = mutableListOf<Projectile>()
    private val pendingCollectibles = mutableListOf<Collectible>()

    // Events for renderer (particle effects, sounds)
    data class GameEvent(val type: EventType, val x: Float, val y: Float)
    enum class EventType { COLLECT, ENEMY_DEATH, PLAYER_DEATH, RAINBOW_SHOOT, BOSS_HIT, BOSS_DEATH, ACHIEVEMENT }
    val events = mutableListOf<GameEvent>()

    private var frameDelta = 0f

    var cameraY = 0f
    var scrollSpeed = Constants.BASE_SCROLL_SPEED
    var score = 0
    var gemsCollected = 0
    private var nextLifeAt = 100
    var comboCount = 0
    var comboMultiplier = 1
    private var comboTimer = 0f
    private val comboTimeout = 1.5f // seconds to keep combo alive

    // Screen shake
    var shakeTimer = 0f
    var shakeIntensity = 0f

    var enemiesKilled = 0
    var bossesDefeated = 0
    private var bossEncounters = 0  // counts how many bosses have spawned
    var gameTime = 0f
    var rainbowsShot = 0
    var newAchievement: String? = null  // set when an achievement unlocks this frame

    var maxHeight = 0f
    var currentLevel = 0
    var platformsClimbed = 0

    // Biome management
    private var biomeOrder = Biome.ALL.shuffled(java.util.Random(seed))
    private var biomeIndex = 0
    var currentBiome = biomeOrder[0]
        private set

    // Chunk tracking
    private var highestGeneratedY = 0f

    fun init() {
        // Generate initial platforms — a safe starting area + first chunks
        generateStartingArea()
        generateChunksUpTo(cameraY + Constants.VIRTUAL_HEIGHT * 2)
    }

    private fun generateStartingArea() {
        // Starting platform at center screen — full width, player spawns on it
        val startY = Constants.VIRTUAL_HEIGHT / 2f - 10f  // just below player spawn
        val ground = Platform()
        ground.activate(0f, startY, Constants.VIRTUAL_WIDTH, PlatformType.STATIC)
        platforms.add(ground)

        // Easy platforms above the starting point
        val easyPlatforms = listOf(
            PlatformDef(120f, startY + 120f, 120f, PlatformType.STATIC),
            PlatformDef(300f, startY + 220f, 100f, PlatformType.STATIC),
            PlatformDef(50f, startY + 330f, 110f, PlatformType.STATIC),
            PlatformDef(250f, startY + 430f, 100f, PlatformType.STATIC),
        )
        for (def in easyPlatforms) {
            val p = Platform()
            p.activate(def.x, def.y, def.width, def.type)
            platforms.add(p)
        }
        highestGeneratedY = startY + 530f
    }

    private fun generateChunksUpTo(targetY: Float) {
        while (highestGeneratedY < targetY) {
            val chunk = generator.generate(highestGeneratedY)
            for (def in chunk.platforms) {
                val p = Platform()
                p.activate(def.x, def.y, def.width, def.type)
                if (def.type == PlatformType.MOVING) {
                    p.moveMinX = 0f
                    p.moveMaxX = Constants.VIRTUAL_WIDTH
                }
                platforms.add(p)
            }
            for (def in chunk.enemies) {
                val e = Enemy()
                val speed = 40f * Math.pow(1.0 + Constants.DIFFICULTY_INCREASE, currentLevel.toDouble()).toFloat()
                e.activate(def.x, def.y, def.type, speed)
                val patrolRange = if (def.type == EnemyType.BOMBER) 80f else 40f
                e.patrolMinX = (def.x - patrolRange).coerceAtLeast(0f)
                e.patrolMaxX = (def.x + patrolRange).coerceAtMost(Constants.VIRTUAL_WIDTH)
                enemies.add(e)
            }
            for (def in chunk.collectibles) {
                val c = Collectible()
                c.activate(def.x, def.y, def.type)
                collectibles.add(c)
            }
            highestGeneratedY += Constants.CHUNK_HEIGHT_PX
        }
    }

    fun update(delta: Float) {
        if (!player.isAlive) return
        frameDelta = delta
        events.clear()
        newAchievement = null
        gameTime += delta

        // Combo timer decay
        if (comboTimer > 0) {
            comboTimer -= delta
            if (comboTimer <= 0) {
                comboCount = 0
                comboMultiplier = 1
            }
        }

        // Screen shake decay
        if (shakeTimer > 0) shakeTimer -= delta

        // Update scroll speed based on level
        val speedMult = if (player.slowTimeTimer > 0) 0.5f else 1f
        scrollSpeed = Constants.BASE_SCROLL_SPEED *
            Math.pow(1.0 + Constants.DIFFICULTY_INCREASE, currentLevel.toDouble()).toFloat() *
            speedMult

        // Auto-scroll camera
        cameraY += scrollSpeed * delta

        // Keep camera at least at player height
        if (player.position.y - cameraY > Constants.VIRTUAL_HEIGHT * 0.6f) {
            cameraY = player.position.y - Constants.VIRTUAL_HEIGHT * 0.6f
        }

        // Update max height and level
        if (player.position.y > maxHeight) {
            maxHeight = player.position.y
        }
        val newLevel = (maxHeight / (Constants.PLATFORMS_PER_LEVEL * 40f)).toInt()
        if (newLevel > currentLevel) {
            currentLevel = newLevel
            generator.setLevel(currentLevel)
            updateBiome()
        }

        // Generate more chunks ahead
        generateChunksUpTo(cameraY + Constants.VIRTUAL_HEIGHT * 3)

        // Update entities
        player.update(delta)
        if (boss.active) {
            boss.cameraY = cameraY
            boss.update(delta, player.position.x, player.position.y)
            handleBossCollisions()
        }
        platforms.forEach { it.update(delta) }
        enemies.forEach { it.update(delta) }
        updateEnemyAI()
        projectiles.forEach { it.update(delta) }
        collectibles.forEach { it.update(delta) }
        rainbows.forEach { it.update(delta) }

        // Collision detection
        handlePlatformCollisions()
        handleEnemyCollisions()
        handleCollectiblePickups()
        handleRainbowEnemyCollisions()
        handleProjectileCollisions()

        // Check death: fell below camera
        if (player.position.y < cameraY - Constants.PLAYER_HEIGHT) {
            if (player.isInvincible) {
                // Auto-rescue during invincibility
                respawnPlayer()
            } else {
                killPlayer()
            }
        }

        // Flush staged entities
        if (pendingProjectiles.isNotEmpty()) {
            projectiles.addAll(pendingProjectiles)
            pendingProjectiles.clear()
        }
        if (pendingCollectibles.isNotEmpty()) {
            collectibles.addAll(pendingCollectibles)
            pendingCollectibles.clear()
        }

        // Clean up off-screen entities
        cleanUp()
        checkAchievements()
    }

    private fun checkAchievements() {
        fun tryUnlock(a: Achievement) {
            if (Achievement.unlock(a)) {
                newAchievement = a.displayName
                events.add(GameEvent(EventType.ACHIEVEMENT, player.position.x, player.position.y + 40f))
            }
        }
        if (rainbowsShot >= 1) tryUnlock(Achievement.FIRST_RAINBOW)
        if (score >= 1000) tryUnlock(Achievement.SCORE_1000)
        if (score >= 5000) tryUnlock(Achievement.SCORE_5000)
        if (score >= 10000) tryUnlock(Achievement.SCORE_10000)
        if (enemiesKilled >= 10) tryUnlock(Achievement.KILL_10)
        if (enemiesKilled >= 50) tryUnlock(Achievement.KILL_50)
        if (comboMultiplier >= 3) tryUnlock(Achievement.COMBO_X3)
        if (comboMultiplier >= 4) tryUnlock(Achievement.COMBO_X4)
        if (bossesDefeated >= 1) tryUnlock(Achievement.BOSS_DEFEAT)
        if (gameTime >= 180f) tryUnlock(Achievement.SURVIVE_3MIN)
        if (gemsCollected >= 100) tryUnlock(Achievement.COLLECT_100_GEMS)
        if (currentLevel >= 10) tryUnlock(Achievement.LEVEL_10)
        if (currentLevel >= 25) tryUnlock(Achievement.LEVEL_25)
    }

    private fun handlePlatformCollisions() {
        player.isOnGround = false

        // Check regular platforms
        for (platform in platforms) {
            if (!platform.active) continue
            if (checkPlatformLanding(platform)) break
        }

        // Check rainbow platforms (same robust check as normal platforms)
        for (rainbow in rainbows) {
            if (!rainbow.active) continue
            if (player.velocity.y > 0) continue // moving up, skip

            val playerBottom = player.position.y
            val rainbowTop = rainbow.position.y + rainbow.bounds.height

            // Horizontal overlap check
            if (player.bounds.x + player.bounds.width > rainbow.bounds.x &&
                player.bounds.x < rainbow.bounds.x + rainbow.bounds.width &&
                playerBottom >= rainbow.position.y - 4f &&
                playerBottom <= rainbowTop + 8f
            ) {
                player.position.y = rainbowTop
                player.velocity.y = 0f
                player.isOnGround = true
                break
            }
        }
    }

    private fun checkPlatformLanding(platform: Platform): Boolean {
        if (player.velocity.y > 0) return false // moving up, skip

        val playerBottom = player.position.y
        val platformTop = platform.position.y + 8f

        if (player.bounds.x + player.bounds.width > platform.bounds.x &&
            player.bounds.x < platform.bounds.x + platform.bounds.width &&
            playerBottom >= platform.position.y - 2f &&
            playerBottom <= platformTop + 4f &&
            player.velocity.y <= 0
        ) {
            player.position.y = platformTop
            player.velocity.y = 0f
            player.isOnGround = true
            platform.startCrumble()
            return true
        }
        return false
    }

    private fun handleEnemyCollisions() {
        if (!player.isAlive) return
        for (enemy in enemies) {
            if (!enemy.active) continue
            if (player.bounds.overlaps(enemy.bounds)) {
                if (player.isInvincible) {
                    // Invincible: destroy enemy on contact
                    enemy.active = false
                    enemiesKilled++
                    score += 25
                    events.add(GameEvent(EventType.ENEMY_DEATH, enemy.position.x, enemy.position.y))
                    spawnEnemyDrop(enemy.position.x, enemy.position.y)
                } else if (player.shieldActive) {
                    player.shieldActive = false
                    enemy.active = false
                    score += 25
                    spawnEnemyDrop(enemy.position.x, enemy.position.y)
                } else {
                    killPlayer()
                }
                return
            }
        }
    }

    private fun handleCollectiblePickups() {
        val magnetRange = if (player.magnetTimer > 0) Constants.TILE_SIZE * 3f else 0f

        for (collectible in collectibles) {
            if (!collectible.active) continue

            // Magnet attraction
            if (magnetRange > 0 && !collectible.isPowerUp()) {
                val dx = player.position.x - collectible.position.x
                val dy = player.position.y - collectible.position.y
                val dist = Math.sqrt((dx * dx + dy * dy).toDouble()).toFloat()
                if (dist < magnetRange && dist > 0) {
                    collectible.position.x += dx / dist * 200f * frameDelta
                    collectible.position.y += dy / dist * 200f * frameDelta
                }
            }

            if (player.bounds.overlaps(collectible.bounds)) {
                collectible.active = false
                // Combo system
                comboCount++
                comboTimer = comboTimeout
                comboMultiplier = when {
                    comboCount >= 20 -> 4
                    comboCount >= 10 -> 3
                    comboCount >= 5 -> 2
                    else -> 1
                }
                score += collectible.scoreValue * comboMultiplier
                events.add(GameEvent(EventType.COLLECT, collectible.position.x, collectible.position.y))
                applyCollectible(collectible.type)
            }
        }
    }

    private fun applyCollectible(type: CollectibleType) {
        when (type) {
            CollectibleType.RAINBOW_BOOST -> {
                player.maxRainbowAmmo = 6
                player.rainbowAmmo = 6
                player.rainbowBoostTimer = 15f
            }
            CollectibleType.DOUBLE_JUMP -> {
                player.hasDoubleJump = true
                player.doubleJumpTimer = 20f
            }
            CollectibleType.SHIELD -> {
                player.shieldActive = true
            }
            CollectibleType.SLOW_TIME -> {
                player.slowTimeTimer = 10f
            }
            CollectibleType.MAGNET -> {
                player.magnetTimer = 15f
            }
            else -> {
                // Gems and stars: track gem count for extra lives
                if (type == CollectibleType.GEM) {
                    gemsCollected++
                    if (gemsCollected >= nextLifeAt) {
                        player.lives++
                        nextLifeAt += 100
                        events.add(GameEvent(EventType.COLLECT, player.position.x, player.position.y + 20f))
                    }
                }
            }
        }
    }

    private fun killPlayer() {
        events.add(GameEvent(EventType.PLAYER_DEATH, player.position.x, player.position.y))
        shakeTimer = 0.4f
        shakeIntensity = 6f
        player.lives--
        if (player.lives > 0) {
            // Respawn: place player on the nearest visible platform
            respawnPlayer()
        } else {
            player.isAlive = false
        }
    }

    private fun respawnPlayer() {
        // Create a rescue platform at mid-screen
        val rescueY = cameraY + Constants.VIRTUAL_HEIGHT / 2f
        val rescuePlatform = Platform()
        rescuePlatform.activate(
            Constants.VIRTUAL_WIDTH / 2f - Constants.VIRTUAL_WIDTH / 4f,
            rescueY,
            Constants.VIRTUAL_WIDTH / 2f,  // half screen width
            PlatformType.STATIC
        )
        platforms.add(rescuePlatform)

        // Place player on the rescue platform
        player.position.set(Constants.VIRTUAL_WIDTH / 2f - Constants.PLAYER_WIDTH / 2f,
            rescueY + 10f)
        player.velocity.set(0f, 0f)
        player.isOnGround = true

        // 5 seconds of invincibility (blinks 5 times = 1 blink per second)
        player.invincibleTimer = 5f
        player.shieldActive = false  // no shield, use invincibility instead
    }

    private fun handleRainbowEnemyCollisions() {
        for (rainbow in rainbows) {
            if (!rainbow.active) continue
            for (enemy in enemies) {
                if (!enemy.active) continue
                if (rainbow.bounds.overlaps(enemy.bounds)) {
                    events.add(GameEvent(EventType.ENEMY_DEATH, enemy.position.x, enemy.position.y))
                    enemy.active = false
                    enemiesKilled++
                    score += 25
                    spawnEnemyDrop(enemy.position.x, enemy.position.y)
                }
            }
            // Rainbows also destroy enemy projectiles
            for (proj in projectiles) {
                if (!proj.active) continue
                if (rainbow.bounds.overlaps(proj.bounds)) {
                    proj.active = false
                }
            }
        }
    }

    private fun spawnEnemyDrop(x: Float, y: Float) {
        if (random.nextFloat() < 0.5f) {
            val c = Collectible()
            val dropType = if (random.nextFloat() < 0.15f) {
                // Rare power-up drop
                val powerUps = listOf(CollectibleType.SHIELD, CollectibleType.DOUBLE_JUMP, CollectibleType.SLOW_TIME)
                powerUps[random.nextInt(powerUps.size)]
            } else {
                CollectibleType.GEM
            }
            c.activate(x, y, dropType)
            pendingCollectibles.add(c)
        }
    }

    private fun updateEnemyAI() {
        for (enemy in enemies) {
            if (!enemy.active) continue

            when (enemy.type) {
                EnemyType.SHOOTER -> {
                    if (enemy.wantsToFire) {
                        enemy.wantsToFire = false
                        val dir = if (player.position.x < enemy.position.x) -1 else 1
                        val proj = Projectile()
                        val spawnX = if (dir == 1) enemy.position.x + Constants.ENEMY_SIZE else enemy.position.x - Constants.PROJECTILE_SIZE
                        proj.activate(spawnX, enemy.position.y + Constants.ENEMY_SIZE / 2f, ProjectileType.HORIZONTAL, dir)
                        pendingProjectiles.add(proj)
                    }
                }
                EnemyType.BOMBER -> {
                    if (enemy.wantsToFire) {
                        enemy.wantsToFire = false
                        val dx = kotlin.math.abs(player.position.x - enemy.position.x)
                        if (dx < Constants.BOMBER_DROP_RANGE_X) {
                            val proj = Projectile()
                            proj.activate(
                                enemy.position.x + Constants.BOMBER_WIDTH / 2f - Constants.PROJECTILE_SIZE / 2f,
                                enemy.position.y,
                                ProjectileType.VERTICAL, 0
                            )
                            pendingProjectiles.add(proj)
                        }
                        // If not aligned, shot is forfeited; next drop waits for full cooldown
                    }
                }
                EnemyType.CHASER -> {
                    if (!enemy.isChasing) {
                        val dx = player.position.x - enemy.position.x
                        val dy = player.position.y - enemy.position.y
                        val dist = kotlin.math.sqrt((dx * dx + dy * dy).toDouble()).toFloat()
                        if (dist <= Constants.CHASER_DETECT_RADIUS) {
                            enemy.isChasing = true
                            enemy.chaseTimer = Constants.CHASER_DURATION
                        }
                    }
                    if (enemy.isChasing) {
                        // Update target to live player position each frame
                        enemy.chaseTargetX = player.position.x
                        enemy.chaseTargetY = player.position.y
                    }
                }
                else -> {}
            }
        }
    }

    private fun handleProjectileCollisions() {
        if (!player.isAlive) return
        for (proj in projectiles) {
            if (!proj.active) continue
            if (player.bounds.overlaps(proj.bounds)) {
                if (player.isInvincible) {
                    proj.active = false  // destroy projectile, no damage
                } else if (player.shieldActive) {
                    player.shieldActive = false
                    proj.active = false
                } else {
                    killPlayer()
                    return
                }
            }
        }
    }

    private fun handleBossCollisions() {
        if (!boss.active || boss.state == Boss.State.DEAD) return

        // Boss hits player
        if (player.bounds.overlaps(boss.bounds) && boss.state != Boss.State.HIT) {
            if (player.isInvincible) {
                // No damage during invincibility
            } else if (player.shieldActive) {
                player.shieldActive = false
            } else {
                killPlayer()
            }
        }

        // Rainbows hit boss
        for (rainbow in rainbows) {
            if (!rainbow.active) continue
            if (rainbow.bounds.overlaps(boss.bounds)) {
                val wasAlive = boss.hp > 0
                boss.takeDamage()
                if (!wasAlive) break  // already dead, skip
                rainbow.active = false
                shakeTimer = 0.2f
                shakeIntensity = 4f
                score += 50
                events.add(GameEvent(EventType.BOSS_HIT, boss.position.x, boss.position.y))

                if (boss.hp <= 0) {
                    bossesDefeated++
                    score += 500
                    events.add(GameEvent(EventType.BOSS_DEATH, boss.position.x, boss.position.y))
                    // Drop 50 gems
                    for (i in 0 until 50) {
                        val c = Collectible()
                        c.activate(
                            boss.position.x + random.nextFloat(-60f, 60f),
                            boss.position.y + random.nextFloat(-20f, 60f),
                            CollectibleType.GEM
                        )
                        pendingCollectibles.add(c)
                    }
                }
                break
            }
        }
    }

    fun shootRainbow(direction: Int) {
        if (!player.shootRainbow()) return
        val rainbow = Rainbow()
        rainbow.activate(player.position.x, player.position.y, direction, player.isOnGround)
        rainbows.add(rainbow)
        rainbowsShot++
        events.add(GameEvent(EventType.RAINBOW_SHOOT, player.position.x, player.position.y))
    }

    private fun updateBiome() {
        biomeIndex = (biomeIndex + 1) % biomeOrder.size
        if (biomeIndex == 0) {
            biomeOrder = Biome.ALL.shuffled(java.util.Random(random.seed + currentLevel))
        }
        currentBiome = biomeOrder[biomeIndex]

        // Spawn boss every 5 levels (if no boss active)
        if (currentLevel > 0 && currentLevel % 5 == 0 && !boss.active) {
            bossEncounters++
            boss.activate(
                Constants.VIRTUAL_WIDTH / 2f - Boss.WIDTH / 2f,
                cameraY + Constants.VIRTUAL_HEIGHT * 0.75f,
                cameraY,
                bossEncounters  // 1st boss = 1 HP, 2nd = 2 HP, etc.
            )
        }
    }

    private fun cleanUp() {
        val bottomThreshold = cameraY - Constants.CHUNK_HEIGHT_PX
        platforms.removeAll { !it.active || it.position.y < bottomThreshold }
        enemies.removeAll { !it.active || it.position.y < bottomThreshold }
        collectibles.removeAll { !it.active || it.position.y < bottomThreshold }
        rainbows.removeAll { !it.active }
        projectiles.removeAll {
            !it.active ||
            it.position.y < bottomThreshold ||
            it.position.x < -Constants.PROJECTILE_SIZE ||
            it.position.x > Constants.VIRTUAL_WIDTH + Constants.PROJECTILE_SIZE
        }
    }

    fun reset(newSeed: Long = System.currentTimeMillis()) {
        platforms.clear()
        enemies.clear()
        collectibles.clear()
        rainbows.clear()
        projectiles.clear()
        events.clear()
        pendingProjectiles.clear()
        pendingCollectibles.clear()
        boss.reset()
        player.reset()
        cameraY = 0f
        scrollSpeed = Constants.BASE_SCROLL_SPEED
        score = 0
        gemsCollected = 0
        nextLifeAt = 100
        comboCount = 0
        comboMultiplier = 1
        comboTimer = 0f
        shakeTimer = 0f
        shakeIntensity = 0f
        enemiesKilled = 0
        bossesDefeated = 0
        bossEncounters = 0
        gameTime = 0f
        rainbowsShot = 0
        newAchievement = null
        maxHeight = 0f
        currentLevel = 0
        highestGeneratedY = 0f
        biomeIndex = 0
        biomeOrder = Biome.ALL.shuffled(java.util.Random(newSeed))
        currentBiome = biomeOrder[0]
        generator.setLevel(0)
        init()
    }
}
