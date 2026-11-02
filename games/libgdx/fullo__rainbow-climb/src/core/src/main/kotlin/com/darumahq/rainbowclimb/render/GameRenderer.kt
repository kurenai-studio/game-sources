package com.darumahq.rainbowclimb.render

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.g2d.TextureRegion
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.utils.viewport.FitViewport
import com.darumahq.rainbowclimb.entity.EnemyType
import com.darumahq.rainbowclimb.entity.PlayerCharacter
import com.darumahq.rainbowclimb.util.Constants
import com.darumahq.rainbowclimb.world.PlatformType
import com.darumahq.rainbowclimb.world.World
import com.darumahq.rainbowclimb.world.World.EventType

class GameRenderer(private val batch: SpriteBatch, private val sprites: SpriteManager,
                   var selectedCharacter: PlayerCharacter = PlayerCharacter.PINK_MAN) {
    val camera = OrthographicCamera()
    val viewport = FitViewport(Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT, camera)
    private val shapeRenderer = ShapeRenderer()
    private val parallax = ParallaxBackground(sprites)
    private val particles = ParticleSystem()
    private var achievementTimer = 0f
    private var lastAchievementName = ""
    // Cached GlyphLayout to avoid per-frame allocation
    private val glyphLayout = com.badlogic.gdx.graphics.g2d.GlyphLayout()
    var showTutorial = false  // set by GameScreen on first play
    var reducedMotion = false  // disables particles and screen shake
    private val hudCamera = OrthographicCamera()

    // Rainbow colors kept for menu screen
    val rainbowColors = listOf(
        Color.RED, Color.ORANGE, Color.YELLOW,
        Color.GREEN, Color.CYAN, Color.BLUE, Color.VIOLET
    )

    init {
        camera.position.set(Constants.VIRTUAL_WIDTH / 2f, Constants.VIRTUAL_HEIGHT / 2f, 0f)
        hudCamera.setToOrtho(false, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
    }

    fun render(world: World) {
        // Update camera to follow world scroll
        camera.position.x = Constants.VIRTUAL_WIDTH / 2f
        camera.position.y = world.cameraY + Constants.VIRTUAL_HEIGHT / 2f

        // Screen shake (skip if reduced motion)
        if (world.shakeTimer > 0 && !reducedMotion) {
            val shake = world.shakeIntensity * (world.shakeTimer / 0.4f)
            camera.position.x += (Math.random().toFloat() - 0.5f) * shake * 2f
            camera.position.y += (Math.random().toFloat() - 0.5f) * shake * 2f
        }

        camera.update()

        Gdx.gl.glClearColor(0f, 0f, 0f, 1f)
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)

        // Update particles and timers
        val delta = Gdx.graphics.deltaTime.coerceAtMost(0.033f)
        particles.update(delta)
        if (achievementTimer > 0) achievementTimer -= delta
        if (world.newAchievement != null) lastAchievementName = world.newAchievement!!

        // ── Background (uses HUD camera for full-screen fill) ──
        batch.projectionMatrix = hudCamera.combined
        batch.begin()
        parallax.render(batch, world.cameraY, world.currentBiome)
        batch.end()

        // ── Sprite entities (game camera) ──
        batch.projectionMatrix = camera.combined
        batch.begin()
        Gdx.gl.glEnable(GL20.GL_BLEND)

        renderPlatforms(world)
        renderCollectibles(world)
        renderEnemies(world)
        renderBoss(world)
        renderPlayer(world)

        batch.end()

        // ── Projectiles + Particles (ShapeRenderer, game camera) ──
        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)
        shapeRenderer.projectionMatrix = camera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        renderProjectiles(world)
        if (!reducedMotion) {
            processEvents(world)
            particles.render(shapeRenderer)
        }

        shapeRenderer.end()

        // ── HUD (screen-space) ──
        hudCamera.update()
        batch.projectionMatrix = hudCamera.combined
        batch.begin()
        renderHUD(world)
        batch.end()
    }

    // ── Platforms ─────────────────────────────────────────────────

    private fun renderPlatforms(world: World) {
        for (platform in world.platforms) {
            if (!platform.active) continue

            val alpha = if (platform.isCrumbling) {
                1f - (platform.crumbleTimer / platform.crumbleDuration)
            } else 1f

            batch.setColor(1f, 1f, 1f, alpha)

            // Choose texture based on platform type
            val tex = when {
                platform.isCrumbling || platform.type == PlatformType.CRUMBLING ->
                    sprites.platformCrumble
                else -> sprites.platformBrown
            }

            tilePlatform(tex, platform.position.x, platform.position.y, platform.width)
        }

        // Rainbow bridges (use animated sprite instead of ShapeRenderer)
        for (rainbow in world.rainbows) {
            if (!rainbow.active) continue
            val alpha = (rainbow.timer / Constants.RAINBOW_DURATION).coerceIn(0f, 1f)
            batch.setColor(1f, 1f, 1f, alpha)

            val frame = sprites.rainbowBridge.getKeyFrame(
                Constants.RAINBOW_DURATION - rainbow.timer, true)
            tilePlatform(frame, rainbow.bounds.x, rainbow.bounds.y,
                rainbow.bounds.width, rainbow.bounds.height)
        }

        batch.setColor(Color.WHITE)
    }

    private fun tilePlatform(tex: TextureRegion, x: Float, y: Float,
                             width: Float, height: Float = tex.regionHeight.toFloat()) {
        val segW = tex.regionWidth.toFloat()
        var drawX = x
        var drawn = 0f
        while (drawn < width) {
            val w = minOf(segW, width - drawn)
            if (w < segW) {
                val partial = TextureRegion(tex.texture,
                    tex.regionX, tex.regionY, w.toInt(), tex.regionHeight)
                batch.draw(partial, drawX, y, w, height)
            } else {
                batch.draw(tex, drawX, y, segW, height)
            }
            drawX += w
            drawn += w
        }
    }

    // ── Collectibles ─────────────────────────────────────────────

    private fun renderCollectibles(world: World) {
        for (collectible in world.collectibles) {
            if (!collectible.active) continue

            val anim = if (collectible.isPowerUp()) {
                sprites.getRandomFruit(collectible.position.x.toInt())
            } else {
                sprites.getGemAnimForBiome(world.currentBiome.type)
            }
            val frame = anim.getKeyFrame(collectible.animTimer, true)
            val bob = kotlin.math.sin((collectible.animTimer * 4f).toDouble()).toFloat() * 3f
            val size = if (collectible.isPowerUp()) Constants.COLLECTIBLE_SIZE else Constants.GEM_SIZE
            batch.draw(frame, collectible.position.x, collectible.position.y + bob, size, size)
        }
    }

    // ── Enemies ──────────────────────────────────────────────────

    private fun renderEnemies(world: World) {
        for (enemy in world.enemies) {
            if (!enemy.active) continue

            val anim = sprites.getEnemyAnim(enemy.type, enemy.animState())
            val frame = anim.getKeyFrame(enemy.stateTime, true)

            val spriteW = frame.regionWidth.toFloat()
            val spriteH = frame.regionHeight.toFloat()

            // Collision box width for centering
            val collW = if (enemy.type == EnemyType.BOMBER) Constants.BOMBER_WIDTH else Constants.ENEMY_SIZE

            // Align sprite: centered X, bottom-aligned Y (feet on platform)
            val drawX = enemy.position.x + (collW - spriteW) / 2f
            val drawY = enemy.position.y  // bottom-aligned

            if (enemy.facingRight) {
                batch.draw(frame, drawX, drawY, spriteW, spriteH)
            } else {
                // Flip horizontally: draw at x+width with negative width
                batch.draw(frame, drawX + spriteW, drawY, -spriteW, spriteH)
            }
        }
    }

    // ── Boss ─────────────────────────────────────────────────────

    private fun renderBoss(world: World) {
        val boss = world.boss
        if (!boss.active) return

        val anim = sprites.getBossAnim(boss.animState())
        val looping = boss.state != com.darumahq.rainbowclimb.entity.Boss.State.HIT &&
                      boss.state != com.darumahq.rainbowclimb.entity.Boss.State.DEAD
        val frame = anim.getKeyFrame(boss.stateTime, looping)

        // Flash red when hit
        if (boss.state == com.darumahq.rainbowclimb.entity.Boss.State.HIT) {
            val blink = ((boss.stateTime * 10f).toInt() % 2 == 0)
            if (blink) batch.setColor(1f, 0.3f, 0.3f, 1f)
        }

        val w = frame.regionWidth.toFloat()
        val h = frame.regionHeight.toFloat()
        if (boss.facingRight) {
            batch.draw(frame, boss.position.x, boss.position.y, w, h)
        } else {
            batch.draw(frame, boss.position.x + w, boss.position.y, -w, h)
        }

        batch.setColor(Color.WHITE)

        // HP bar above boss
        if (boss.hp > 0 && boss.hp < boss.maxHp) {
            val barW = 50f
            val barH = 4f
            val barX = boss.position.x + (w - barW) / 2f
            val barY = boss.position.y + h + 4f
            // Background (will be drawn in shape renderer pass... use sprite tint trick)
            // For now just show HP text
        }
    }

    // ── Player ───────────────────────────────────────────────────

    private fun renderPlayer(world: World) {
        val player = world.player
        if (!player.isAlive && player.stateTime > 1.5f) return // hide after death anim

        val anim = sprites.getPlayerAnim(selectedCharacter, player.animState())
        val looping = player.animState() == "idle" || player.animState() == "run"
        val frame = anim.getKeyFrame(player.stateTime, looping)

        val spriteW = frame.regionWidth.toFloat()
        val spriteH = frame.regionHeight.toFloat()

        // Align sprite to bottom of collision box (feet on platform)
        val drawX = player.position.x + (Constants.PLAYER_WIDTH - spriteW) / 2f
        val drawY = player.position.y  // bottom-aligned, not centered

        // Death: fade out without changing colors
        if (!player.isAlive) {
            val fadeAlpha = (1f - (player.stateTime / 1.5f)).coerceIn(0f, 1f)
            batch.setColor(1f, 1f, 1f, fadeAlpha)
        } else if (player.isInvincible) {
            // Invincibility blink: 5 blinks in 5 seconds (1Hz sine wave)
            val blinkPhase = kotlin.math.sin((player.invincibleTimer * Math.PI * 2.0 / 1.0)).toFloat()
            val alpha = if (blinkPhase > 0f) 1f else 0.3f
            batch.setColor(1f, 1f, 1f, alpha)
        } else {
            batch.setColor(Color.WHITE) // always original colors
        }

        // Draw player sprite
        if (player.facing >= 0) {
            batch.draw(frame, drawX, drawY, spriteW, spriteH)
        } else {
            batch.draw(frame, drawX + spriteW, drawY, -spriteW, spriteH)
        }

        // Shield: draw a blinking outline effect OVER the sprite (not tinting it)
        if (player.isAlive && player.shieldActive) {
            val blink = ((player.stateTime * 8f).toInt() % 2 == 0)
            if (blink) {
                batch.setColor(0.3f, 0.9f, 1f, 0.5f)
                // Draw slightly larger for glow effect
                if (player.facing >= 0) {
                    batch.draw(frame, drawX - 1f, drawY - 1f, spriteW + 2f, spriteH + 2f)
                } else {
                    batch.draw(frame, drawX + spriteW + 1f, drawY - 1f, -spriteW - 2f, spriteH + 2f)
                }
            }
        }

        batch.setColor(Color.WHITE)
    }

    // ── Rainbows (ShapeRenderer) ─────────────────────────────────

    // Rainbows now rendered as sprites in renderPlatforms()

    // ── Projectiles (ShapeRenderer) ──────────────────────────────

    private fun renderProjectiles(world: World) {
        for (proj in world.projectiles) {
            if (!proj.active) continue
            shapeRenderer.color = Color.ORANGE
            shapeRenderer.rect(proj.position.x, proj.position.y,
                Constants.PROJECTILE_SIZE, Constants.PROJECTILE_SIZE)
        }
    }

    // ── HUD ──────────────────────────────────────────────────────

    private fun renderHUD(world: World) {
        val font = sprites.pixelFont
        font.color = Color.WHITE

        // Score + Gems
        font.draw(batch, "Score:${world.score}", 4f, Constants.VIRTUAL_HEIGHT - 4f)
        font.color = Color.CYAN
        font.draw(batch, "G:${world.gemsCollected}", 4f, Constants.VIRTUAL_HEIGHT - 16f)

        // Lives
        font.color = Color.RED
        val livesText = "L:" + "♥".repeat(world.player.lives.coerceAtLeast(0))
        font.draw(batch, livesText, 4f, Constants.VIRTUAL_HEIGHT - 28f)

        // Level
        font.color = Color.WHITE
        font.draw(batch, "Lv ${world.currentLevel + 1}",
            Constants.VIRTUAL_WIDTH - 50f, Constants.VIRTUAL_HEIGHT - 4f)

        // Rainbow ammo
        val ammoText = "R:" + "o".repeat(world.player.rainbowAmmo) +
            ".".repeat(world.player.maxRainbowAmmo - world.player.rainbowAmmo)
        font.draw(batch, ammoText, Constants.VIRTUAL_WIDTH - 60f, Constants.VIRTUAL_HEIGHT - 16f)

        // Biome name
        font.draw(batch, world.currentBiome.name,
            Constants.VIRTUAL_WIDTH / 2f - 30f, Constants.VIRTUAL_HEIGHT - 4f)

        // Tutorial hints (first game only)
        if (showTutorial) {
            font.color = Color(1f, 1f, 1f, 0.8f)
            val height = world.player.position.y
            when {
                height < 100f -> {
                    drawHUDCentered(font, "< > Arrow keys to move", Constants.VIRTUAL_HEIGHT * 0.35f)
                    drawHUDCentered(font, "Touch left/right side on mobile", Constants.VIRTUAL_HEIGHT * 0.3f)
                }
                height < 250f -> {
                    drawHUDCentered(font, "UP / W to jump!", Constants.VIRTUAL_HEIGHT * 0.35f)
                    drawHUDCentered(font, "Tap with 2nd finger on mobile", Constants.VIRTUAL_HEIGHT * 0.3f)
                }
                height < 500f -> {
                    drawHUDCentered(font, "SPACE = Create rainbow bridge", Constants.VIRTUAL_HEIGHT * 0.35f)
                    drawHUDCentered(font, "Direction follows your facing", Constants.VIRTUAL_HEIGHT * 0.3f)
                }
                height < 800f -> {
                    drawHUDCentered(font, "Stand on rainbow bridges!", Constants.VIRTUAL_HEIGHT * 0.35f)
                    drawHUDCentered(font, "They also defeat enemies", Constants.VIRTUAL_HEIGHT * 0.3f)
                }
                height < 1200f -> {
                    drawHUDCentered(font, "Collect gems for extra lives", Constants.VIRTUAL_HEIGHT * 0.35f)
                    drawHUDCentered(font, "100 gems = +1 life", Constants.VIRTUAL_HEIGHT * 0.3f)
                }
                else -> showTutorial = false // tutorial done
            }
        }

        // Achievement popup
        if (achievementTimer > 0 && lastAchievementName.isNotEmpty()) {
            val alpha = if (achievementTimer < 0.5f) achievementTimer * 2f else 1f
            font.color = Color(0.2f, 1f, 0.2f, alpha)
            val achText = "ACHIEVEMENT: $lastAchievementName"
            glyphLayout.setText(font, achText)
            font.draw(batch, achText,
                (Constants.VIRTUAL_WIDTH - glyphLayout.width) / 2f,
                Constants.VIRTUAL_HEIGHT * 0.7f)
        }

        // Boss timer + HP
        if (world.boss.active && world.boss.state != com.darumahq.rainbowclimb.entity.Boss.State.DEAD) {
            val bossTimeLeft = (world.boss.timeRemaining() * 15).toInt()
            font.color = if (bossTimeLeft <= 5) Color.RED else Color.YELLOW
            drawHUDCentered(font, "BOSS #${world.boss.bossNumber}", Constants.VIRTUAL_HEIGHT - 50f)

            // HP pips
            val hpText = "HP:" + "O".repeat(world.boss.hp) + ".".repeat((world.boss.maxHp - world.boss.hp).coerceAtLeast(0))
            drawHUDCentered(font, hpText, Constants.VIRTUAL_HEIGHT - 68f)

            // Time bar
            font.color = Color.GRAY
            drawHUDCentered(font, "Time: ${bossTimeLeft}s", Constants.VIRTUAL_HEIGHT - 86f)
        }

        // Combo display (center screen, fading)
        if (world.comboMultiplier > 1) {
            val comboAlpha = (world.comboMultiplier.toFloat() / 4f).coerceIn(0.5f, 1f)
            font.color = when (world.comboMultiplier) {
                2 -> Color(1f, 1f, 0f, comboAlpha)    // yellow
                3 -> Color(1f, 0.5f, 0f, comboAlpha)  // orange
                else -> Color(1f, 0f, 0f, comboAlpha)  // red
            }
            val comboText = "x${world.comboMultiplier} COMBO!"
            glyphLayout.setText(font, comboText)
            font.draw(batch, comboText,
                (Constants.VIRTUAL_WIDTH - glyphLayout.width) / 2f,
                Constants.VIRTUAL_HEIGHT / 2f + 120f)
        }
    }

    private fun processEvents(world: World) {
        for (event in world.events) {
            when (event.type) {
                EventType.COLLECT -> particles.sparkle(event.x, event.y)
                EventType.ENEMY_DEATH -> particles.enemyPoof(event.x, event.y)
                EventType.PLAYER_DEATH -> particles.deathExplosion(event.x, event.y)
                EventType.RAINBOW_SHOOT -> particles.rainbowBurst(event.x, event.y, 6)
                EventType.BOSS_HIT -> particles.burst(event.x + 32f, event.y + 24f, 10, Color.ORANGE)
                EventType.BOSS_DEATH -> {
                    particles.deathExplosion(event.x + 32f, event.y + 24f)
                    particles.rainbowBurst(event.x + 32f, event.y + 24f, 20)
                }
                EventType.ACHIEVEMENT -> {
                    particles.rainbowBurst(event.x, event.y, 15)
                    achievementTimer = 3f // show for 3 seconds
                }
            }
        }
    }

    private fun drawHUDCentered(font: com.badlogic.gdx.graphics.g2d.BitmapFont, text: String, y: Float) {
        glyphLayout.setText(font, text)
        font.draw(batch, text, (Constants.VIRTUAL_WIDTH - glyphLayout.width) / 2f, y)
    }

    fun resize(width: Int, height: Int) {
        viewport.update(width, height, true)
        camera.position.set(Constants.VIRTUAL_WIDTH / 2f, Constants.VIRTUAL_HEIGHT / 2f, 0f)
    }

    fun dispose() {
        shapeRenderer.dispose()
    }
}
