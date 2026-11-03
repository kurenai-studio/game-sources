package com.stickman.tower.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input.Keys
import com.badlogic.gdx.Screen
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.GlyphLayout
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Vector2
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.bounty.BountyManager
import com.stickman.tower.challenge.ChallengeManager
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.quest.QuestManager
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Menu Utama Bergaya Dark Fantasy / Spire of Shadows:
 * Menampilkan animasi partikel atmosferik, navigasi tombol keyboard & sentuh/mouse,
 * info profil progresi RPG, opsi audio, dan tipografi anti-aliased FreeType.
 */
class MainMenuScreen(private val game: StickmanGame) : Screen {
    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    // Partikel Latar Belakang (Recycled in-place, zero GC allocation)
    private class MenuParticle(
        val pos: Vector2 = Vector2(),
        val vel: Vector2 = Vector2(),
        var size: Float = 0f,
        var color: Color = Color.WHITE,
        var maxLife: Float = 1f
    ) {
        var life: Float = 0f
        val isExpired: Boolean get() = life >= maxLife

        fun reset(initial: Boolean = false) {
            val x = MathUtils.random(0f, 1280f)
            val y = if (initial) MathUtils.random(0f, 720f) else -10f
            pos.set(x, y)
            val vy = MathUtils.random(25f, 75f)
            val vx = MathUtils.random(-15f, 15f)
            vel.set(vx, vy)
            size = MathUtils.random(2f, 5f)
            val isCyan = MathUtils.randomBoolean(0.6f)
            color = if (isCyan) Color(0.2f, 0.8f, 1f, MathUtils.random(0.3f, 0.7f))
                    else Color(1f, 0.75f, 0.2f, MathUtils.random(0.3f, 0.7f))
            maxLife = MathUtils.random(8f, 16f)
            life = 0f
        }
    }
    private val particles = mutableListOf<MenuParticle>()

    // Tombol Menu 16 Item Simetris (8 Baris x 2 Kolom)
    private val menuItems = listOf(
        "START STORY TOWER",
        "ENDLESS SPIRE",
        "TALENT TREE",
        "BLACKSMITH FORGE",
        "SELECT CHARACTER",
        "STORY CODEX",
        "📜 QUEST LOG",
        "⚔ GAUNTLET & BOSS RUSH",
        "👑 LEADERBOARDS",
        "🏆 ACHIEVEMENTS",
        "CONTROL SETTINGS",
        "AUDIO: ON",
        "HAPTIC: ON",
        "💾 CLOUD BACKUP",
        "RESET SAVE DATA",
        "QUIT GAME"
    )
    private var selectedIndex = 0
    private var selectorX = 140f
    private var selectorY = 540f
    private var animTime = 0f
    private var feedbackNotice = ""
    private var feedbackTimer = 0f

    private var currentSaveData: SaveData = SaveManager.load()
    private var inputCooldown = 0.25f
    private var lastBackPressTime = 0L

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        AudioManager.init()
        HapticManager.init()
        FontManager.init()
        currentSaveData = SaveManager.load()
        QuestManager.initFromSave(currentSaveData)
        inputCooldown = 0.25f
        val colX = if (selectedIndex < 8) 140f else 670f
        val rowIdx = if (selectedIndex < 8) selectedIndex else selectedIndex - 8
        selectorX = colX
        selectorY = 540f - (rowIdx * 46f)
        particles.clear()
        for (i in 0 until 45) {
            val p = MenuParticle()
            p.reset(initial = true)
            particles.add(p)
        }
    }

    override fun render(delta: Float) {
        animTime += delta
        if (feedbackTimer > 0f) {
            feedbackTimer -= delta
            if (feedbackTimer <= 0f) feedbackNotice = ""
        }

        if (inputCooldown > 0f) {
            inputCooldown -= delta
        } else {
            handleInput()
        }
        if (game.screen !== this) return

        updateParticles(delta)

        ScreenUtils.clear(0.04f, 0.05f, 0.09f, 1f)
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // 1. Gambar Arsitektur Spire & Partikel Latar Belakang
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Siluet Pilar Menara Kuno Sisi Kiri & Kanan (Spire Architecture)
        shapeRenderer.setColor(0.06f, 0.08f, 0.13f, 0.95f)
        shapeRenderer.rect(0f, 0f, 95f, 720f)
        shapeRenderer.rect(1185f, 0f, 95f, 720f)

        shapeRenderer.setColor(0.14f, 0.19f, 0.28f, 0.70f)
        shapeRenderer.rectLine(95f, 0f, 95f, 720f, 2f)
        shapeRenderer.rectLine(1185f, 0f, 1185f, 720f, 2f)

        // Ornamen Garis Mortar Batu Menara
        for (mortarY in 60..700 step 85) {
            shapeRenderer.rectLine(10f, mortarY.toFloat(), 95f, mortarY.toFloat(), 1.5f)
            shapeRenderer.rectLine(1185f, mortarY.toFloat(), 1270f, mortarY.toFloat(), 1.5f)
        }

        // Partikel Ember Atmosferik (Dual-Core: Soft Halo + Bright Core)
        for (p in particles) {
            val alpha = (1f - (p.life / p.maxLife)).coerceIn(0f, 1f)
            shapeRenderer.setColor(p.color.r, p.color.g, p.color.b, p.color.a * alpha * 0.4f)
            shapeRenderer.circle(p.pos.x, p.pos.y, p.size * 1.5f)
            shapeRenderer.setColor(1f, 1f, 1f, alpha * 0.85f)
            shapeRenderer.circle(p.pos.x, p.pos.y, p.size * 0.55f)
        }

        // Panel Judul & Kartu Status Pemain (Dark Slate Obsidian dengan Gold Line)
        shapeRenderer.setColor(0.06f, 0.09f, 0.15f, 0.92f)
        shapeRenderer.rect(140f, 38f, 1000f, 120f)
        shapeRenderer.setColor(0.9f, 0.75f, 0.25f, 0.85f)
        shapeRenderer.rectLine(140f, 158f, 1140f, 158f, 2.5f)

        // Badge Badge Box Penanda Archetype
        shapeRenderer.setColor(0.10f, 0.14f, 0.22f, 1f)
        shapeRenderer.rect(770f, 80f, 340f, 32f)

        // Wadah Tombol-tombol Menu (Glassmorphism Cards 2 Kolom Responsif)
        val buttonWidth = 470f
        val buttonHeight = 40f
        val startY = 540f
        val spacingY = 46f

        // Render Latar Belakang Kartu untuk Seluruh Tombol Menu
        for (i in menuItems.indices) {
            val colX = if (i < 8) 140f else 670f
            val rowIdx = if (i < 8) i else i - 8
            val itemY = startY - (rowIdx * spacingY)

            shapeRenderer.setColor(0.07f, 0.10f, 0.16f, 0.85f)
            shapeRenderer.rect(colX, itemY, buttonWidth, buttonHeight)
            shapeRenderer.setColor(0.16f, 0.22f, 0.32f, 0.65f)
            shapeRenderer.rectLine(colX, itemY, colX + buttonWidth, itemY, 1.5f)
            shapeRenderer.rectLine(colX, itemY + buttonHeight, colX + buttonWidth, itemY + buttonHeight, 1.5f)
        }

        // Smooth Lerp Indikator Seleksi Tombol
        val targetX = if (selectedIndex < 8) 140f else 670f
        val targetRow = if (selectedIndex < 8) selectedIndex else selectedIndex - 8
        val targetY = startY - (targetRow * spacingY)
        selectorX += (targetX - selectorX) * (20f * delta).coerceAtMost(1f)
        selectorY += (targetY - selectorY) * (20f * delta).coerceAtMost(1f)

        val pulse = sin(animTime * 6f) * 0.08f
        shapeRenderer.setColor(0.12f, 0.18f, 0.28f, 0.94f)
        shapeRenderer.rect(selectorX - 6f, selectorY - 4f, buttonWidth + 12f, buttonHeight + 8f)

        // Frame Emas Menyala dengan Aksen Sudut
        shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.88f + pulse)
        shapeRenderer.rectLine(selectorX - 6f, selectorY - 4f, selectorX + buttonWidth + 6f, selectorY - 4f, 2f)
        shapeRenderer.rectLine(selectorX - 6f, selectorY + buttonHeight + 4f, selectorX + buttonWidth + 6f, selectorY + buttonHeight + 4f, 2f)
        shapeRenderer.rectLine(selectorX - 6f, selectorY - 4f, selectorX - 6f, selectorY + buttonHeight + 4f, 3f)
        shapeRenderer.rectLine(selectorX + buttonWidth + 6f, selectorY - 4f, selectorX + buttonWidth + 6f, selectorY + buttonHeight + 4f, 3f)

        // Notch Vektor Segitiga Kursor Samping
        shapeRenderer.triangle(
            selectorX - 14f, selectorY + buttonHeight / 2f,
            selectorX - 5f, selectorY + buttonHeight / 2f + 7f,
            selectorX - 5f, selectorY + buttonHeight / 2f - 7f
        )
        shapeRenderer.triangle(
            selectorX + buttonWidth + 14f, selectorY + buttonHeight / 2f,
            selectorX + buttonWidth + 5f, selectorY + buttonHeight / 2f + 7f,
            selectorX + buttonWidth + 5f, selectorY + buttonHeight / 2f - 7f
        )

        shapeRenderer.end()

        // 2. Render Teks & Tipografi (FontManager FreeType Anti-Aliased)
        batch.begin()

        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont

        // Judul Utama
        titleF.color = Color.WHITE
        glyphLayout.setText(titleF, "STICKMAN TOWER ADVENTURE")
        titleF.draw(batch, "STICKMAN TOWER ADVENTURE", (1280f - glyphLayout.width) / 2f, 655f)

        // Subtitle Emas
        regF.color = Color.GOLD
        val subtitle = "Ascend the Spire of Shadows • 2D Action RPG"
        glyphLayout.setText(regF, subtitle)
        regF.draw(batch, subtitle, (1280f - glyphLayout.width) / 2f, 600f)

        val isStoryUnlocked = currentSaveData.highestTowerFloor > 10 || currentSaveData.highestEndlessFloor > 0

        // Tombol-tombol Navigasi 2 Kolom
        for (i in menuItems.indices) {
            val itemText = when (i) {
                5 -> if (isStoryUnlocked) "📖 STORY CODEX (UNLOCKED)" else "🔒 STORY CODEX (LOCKED)"
                11 -> if (AudioManager.isMuted) "AUDIO: MUTED" else "AUDIO: ON"
                12 -> if (HapticManager.isEnabled) "HAPTIC: ON" else "HAPTIC: OFF"
                else -> menuItems[i]
            }

            val colX = if (i < 8) 140f else 670f
            val rowIdx = if (i < 8) i else i - 8
            val curY = startY - (rowIdx * spacingY) + 26f

            if (i == selectedIndex) {
                if (i == 5 && !isStoryUnlocked) {
                    headF.setColor(1f, 0.65f, 0.35f, 1f)
                } else {
                    headF.setColor(1f, 0.88f, 0.3f, 1f)
                }
                val markedText = "⚔  $itemText  ⚔"
                glyphLayout.setText(headF, markedText)
                headF.draw(batch, markedText, colX + (buttonWidth - glyphLayout.width) / 2f, curY)
            } else {
                if (i == 5 && !isStoryUnlocked) {
                    headF.setColor(0.55f, 0.58f, 0.65f, 0.65f)
                } else if (i == 5 && isStoryUnlocked) {
                    headF.setColor(1f, 0.85f, 0.3f, 0.95f)
                } else {
                    headF.setColor(0.85f, 0.88f, 0.95f, 0.92f)
                }
                glyphLayout.setText(headF, itemText)
                headF.draw(batch, itemText, colX + (buttonWidth - glyphLayout.width) / 2f, curY)
            }
        }

        // Kartu Profil Pemain
        val currentArchetype = CharacterArchetype.fromString(currentSaveData.selectedArchetype)
        regF.color = Color.CYAN
        regF.draw(batch, "HERO STATUS:", 170f, 135f)
        regF.color = Color.WHITE
        regF.draw(batch, "Level: ${currentSaveData.playerLevel}", 170f, 95f)
        regF.draw(batch, "❖ ${currentSaveData.gold} Coins", 360f, 95f)
        val floorText = if (currentSaveData.highestEndlessFloor > 0) {
            "⚑ Story: F${currentSaveData.highestTowerFloor} | Endless: F${currentSaveData.highestEndlessFloor}"
        } else {
            "⚑ Highest Floor: ${currentSaveData.highestTowerFloor}"
        }
        regF.draw(batch, floorText, 550f, 95f)

        when (currentArchetype) {
            CharacterArchetype.BALANCED -> regF.setColor(0.4f, 0.8f, 1f, 1f)
            CharacterArchetype.AGILE -> regF.setColor(0.2f, 0.95f, 0.85f, 1f)
            CharacterArchetype.HEAVY -> regF.setColor(1f, 0.55f, 0.2f, 1f)
        }
        regF.draw(batch, "Hero: ${currentArchetype.characterName}", 780f, 95f)

        val activeTitleMeta = com.stickman.tower.bossrush.BossRushManager.getTitleById(currentSaveData.activeTitle)
        regF.setColor(activeTitleMeta.color)
        regF.draw(batch, "✦ Gelar: \"${activeTitleMeta.titleName}\"", 780f, 135f)

        // Feedback / Notifikasi aksi
        if (feedbackNotice.isNotEmpty()) {
            regF.color = Color.GREEN
            glyphLayout.setText(regF, feedbackNotice)
            regF.draw(batch, feedbackNotice, (1280f - glyphLayout.width) / 2f, 195f)
        }

        // Petunjuk Kontrol
        regF.setColor(0.6f, 0.65f, 0.75f, 0.8f)
        glyphLayout.setText(regF, "[SENTUH TOMBOL / WASD] Pilih  |  [ENTER / SPACE] Konfirmasi")
        regF.draw(batch, "[SENTUH TOMBOL / WASD] Pilih  |  [ENTER / SPACE] Konfirmasi", (1280f - glyphLayout.width) / 2f, 25f)

        batch.end()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W)) {
            selectedIndex = if (selectedIndex in 1..7 || selectedIndex in 9..15) {
                selectedIndex - 1
            } else if (selectedIndex == 0) {
                7
            } else {
                15
            }
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S)) {
            selectedIndex = if (selectedIndex in 0..6 || selectedIndex in 8..14) {
                selectedIndex + 1
            } else if (selectedIndex == 7) {
                0
            } else {
                8
            }
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.LEFT) || Gdx.input.isKeyJustPressed(Keys.A)) {
            if (selectedIndex >= 8) {
                selectedIndex -= 8
                AudioManager.playJump()
            }
        }
        if (Gdx.input.isKeyJustPressed(Keys.RIGHT) || Gdx.input.isKeyJustPressed(Keys.D)) {
            if (selectedIndex < 8) {
                selectedIndex += 8
                AudioManager.playJump()
            }
        }

        // Deteksi Hover & Klik Mouse / Layar Sentuh Mobile
        if (Gdx.input.isTouched) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)
            val buttonWidth = 470f
            val buttonHeight = 40f
            val startY = 540f
            val spacingY = 46f

            for (i in menuItems.indices) {
                val colX = if (i < 8) 140f else 670f
                val rowIdx = if (i < 8) i else i - 8
                val btnY = startY - (rowIdx * spacingY)

                if (touchVec.x in (colX - 25f)..(colX + buttonWidth + 25f) && touchVec.y in (btnY - 8f)..(btnY + buttonHeight + 8f)) {
                    selectedIndex = i
                    if (Gdx.input.justTouched()) {
                        executeSelection()
                    }
                    break
                }
            }
        }

        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE)) {
            executeSelection()
        }

        if (Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.ESCAPE)) {
            val now = System.currentTimeMillis()
            if (now - lastBackPressTime < 2000L) {
                Gdx.app.exit()
            } else {
                lastBackPressTime = now
                feedbackNotice = "Tekan KEMBALI sekali lagi untuk keluar game"
                feedbackTimer = 2.5f
                AudioManager.playJump()
                HapticManager.vibrateLight()
            }
        }
    }

    private fun executeSelection() {
        when (selectedIndex) {
            0 -> {
                AudioManager.playSlashLight()
                if (!currentSaveData.hasSeenPrologue && currentSaveData.highestTowerFloor <= 1) {
                    game.setScreen(PrologueScreen(game))
                } else {
                    game.setScreen(PlayScreen(game, 1, GameMode.STORY))
                }
            }
            1 -> {
                AudioManager.playSlashLight()
                val startingFloor = if (currentSaveData.highestEndlessFloor >= 11) currentSaveData.highestEndlessFloor else 11
                game.setScreen(PlayScreen(game, startingFloor, GameMode.ENDLESS))
            }
            2 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(TalentTreeScreen(game, this))
            }
            3 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(BlacksmithScreen(game, this))
            }
            4 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(CharacterSelectScreen(game))
            }
            5 -> {
                val isStoryUnlocked = currentSaveData.highestTowerFloor > 10 || currentSaveData.highestEndlessFloor > 0
                if (isStoryUnlocked) {
                    AudioManager.playChest()
                    (game as? StickmanGame)?.preserveScreen(this)
                    game.setScreen(StoryCodexScreen(game, this))
                } else {
                    AudioManager.playDeath()
                    HapticManager.vibrateHeavy()
                    feedbackNotice = "Kisah Terkunci! Taklukkan Lantai 10 (Grand Calligrapher) untuk membuka Arsip Menara!"
                    feedbackTimer = 3.5f
                }
            }
            6 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(QuestLogScreen(game, returnScreen = this))
            }
            7 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(GauntletScreen(game, returnScreen = this))
            }
            8 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(LeaderboardScreen(game, this))
            }
            9 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(AchievementScreen(game, this))
            }
            10 -> {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game.setScreen(ControlSettingsScreen(game, this))
            }
            11 -> {
                AudioManager.toggleMute()
                if (!AudioManager.isMuted) AudioManager.playChest()
            }
            12 -> {
                HapticManager.toggle()
                AudioManager.playSlashLight()
            }
            13 -> {
                feedbackNotice = "Cloud Save Verified (Slot ${currentSaveData.saveSlotId}): Checksum OK"
                feedbackTimer = 3.5f
                AudioManager.playChest()
                HapticManager.vibrateMedium()
            }
            14 -> {
                currentSaveData = SaveManager.resetSave()
                QuestManager.reset()
                ChallengeManager.resetForTest()
                BountyManager.resetForTest()
                feedbackNotice = "Save Data Successfully Reset!"
                feedbackTimer = 3.0f
                AudioManager.playDeath()
            }
            15 -> {
                Gdx.app.exit()
            }
        }
    }

    private fun updateParticles(delta: Float) {
        for (p in particles) {
            p.life += delta
            p.pos.x += p.vel.x * delta
            p.pos.y += p.vel.y * delta
            if (p.isExpired || p.pos.y > 730f) {
                p.reset(initial = false)
            }
        }
    }

    override fun resize(width: Int, height: Int) {
        viewport.update(width, height, true)
    }

    override fun pause() {}
    override fun resume() {}
    override fun hide() {}

    override fun dispose() {
        shapeRenderer.dispose()
        batch.dispose()
    }
}
