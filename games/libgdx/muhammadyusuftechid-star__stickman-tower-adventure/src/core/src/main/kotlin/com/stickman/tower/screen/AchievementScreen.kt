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
import com.stickman.tower.achievement.AchievementCatalog
import com.stickman.tower.achievement.AchievementManager
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Screen Interaktif Galeri Prestasi & Trofi (The Hall of Trophies).
 * Menampilkan daftar 12 pencapaian heroik Aethelgard, progress bar persentase penyelesaian,
 * total perolehan emas, serta visual kartu glassmorphism bertema piala emas.
 */
class AchievementScreen(
    private val game: StickmanGame,
    private val returnScreen: Screen? = null
) : Screen {

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private var animTime = 0f
    private var inputCooldown = 0.25f
    private var selectedIndex = 0

    private var currentSaveData: SaveData = SaveManager.load()

    // Partikel Emas Atmosferik
    private class TrophyParticle(
        val pos: Vector2 = Vector2(),
        val vel: Vector2 = Vector2(),
        var size: Float = 0f,
        var color: Color = Color.WHITE,
        var maxLife: Float = 1f
    ) {
        var life: Float = 0f
        val isExpired: Boolean get() = life >= maxLife

        fun reset(initial: Boolean = false) {
            pos.set(MathUtils.random(0f, 1280f), if (initial) MathUtils.random(0f, 720f) else -10f)
            vel.set(MathUtils.random(-10f, 10f), MathUtils.random(25f, 65f))
            size = MathUtils.random(2f, 4f)
            color = Color(1f, 0.85f, 0.25f, MathUtils.random(0.35f, 0.75f))
            maxLife = MathUtils.random(7f, 14f)
            life = 0f
        }
    }
    private val particles = mutableListOf<TrophyParticle>()

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        FontManager.init()
        currentSaveData = SaveManager.load()
        AchievementManager.loadFromSave(currentSaveData)
        inputCooldown = 0.25f
        selectedIndex = 0

        particles.clear()
        for (i in 0 until 35) {
            val p = TrophyParticle()
            p.reset(initial = true)
            particles.add(p)
        }
    }

    override fun render(delta: Float) {
        animTime += delta
        if (inputCooldown > 0f) {
            inputCooldown -= delta
        } else {
            handleInput()
        }
        if (game.screen !== this) return

        updateParticles(delta)

        ScreenUtils.clear(0.04f, 0.05f, 0.085f, 1f)
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // =========================================================================
        // 1. RENDER LATAR BELAKANG & KARTU PRESTASI (SHAPE RENDERER)
        // =========================================================================
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Partikel Emas Melayang
        for (p in particles) {
            val alpha = (1f - (p.life / p.maxLife)).coerceIn(0f, 1f)
            shapeRenderer.setColor(p.color.r, p.color.g, p.color.b, p.color.a * alpha * 0.5f)
            shapeRenderer.circle(p.pos.x, p.pos.y, p.size * 1.5f)
            shapeRenderer.setColor(1f, 1f, 1f, alpha * 0.9f)
            shapeRenderer.circle(p.pos.x, p.pos.y, p.size * 0.55f)
        }

        // Header Panel Atas
        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.95f)
        shapeRenderer.rect(50f, 625f, 1180f, 75f)
        shapeRenderer.setColor(0.95f, 0.80f, 0.25f, 0.85f)
        shapeRenderer.rectLine(50f, 625f, 1230f, 625f, 2.5f)

        // Progress Bar Penyelesaian Prestasi
        val unlockedCount = AchievementManager.getUnlockedCount()
        val totalCount = AchievementCatalog.ACHIEVEMENTS.size
        val progressRatio = (unlockedCount.toFloat() / totalCount.toFloat()).coerceIn(0f, 1f)

        shapeRenderer.setColor(0.12f, 0.16f, 0.24f, 0.9f)
        shapeRenderer.rect(750f, 642f, 450f, 14f)
        shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 1f)
        shapeRenderer.rect(750f, 642f, 450f * progressRatio, 14f)
        shapeRenderer.setColor(1f, 0.95f, 0.6f, 0.8f)
        shapeRenderer.rectLine(750f, 656f, 750f + 450f * progressRatio, 656f, 1.5f)

        // Susunan 12 Kartu Trofi (2 Kolom x 6 Baris)
        val colWidth = 575f
        val cardHeight = 72f
        val startY = 535f
        val spacingY = 82f

        val achievements = AchievementCatalog.ACHIEVEMENTS
        for (i in achievements.indices) {
            val achv = achievements[i]
            val isUnlocked = AchievementManager.isUnlocked(achv.id)

            val colX = if (i < 6) 50f else 655f
            val rowIdx = if (i < 6) i else i - 6
            val cardY = startY - (rowIdx * spacingY)

            // Latar Belakang Kartu
            if (isUnlocked) {
                shapeRenderer.setColor(0.08f, 0.13f, 0.18f, 0.92f)
            } else {
                shapeRenderer.setColor(0.05f, 0.07f, 0.11f, 0.85f)
            }
            shapeRenderer.rect(colX, cardY, colWidth, cardHeight)

            // Border & Indikator Seleksi
            if (i == selectedIndex) {
                val pulse = sin(animTime * 6f) * 0.1f
                shapeRenderer.setColor(0.95f, 0.85f, 0.3f, 0.85f + pulse)
                shapeRenderer.rectLine(colX, cardY, colX + colWidth, cardY, 2f)
                shapeRenderer.rectLine(colX, cardY + cardHeight, colX + colWidth, cardY + cardHeight, 2f)
                shapeRenderer.rectLine(colX, cardY, colX, cardY + cardHeight, 3.5f)
                shapeRenderer.rectLine(colX + colWidth, cardY, colX + colWidth, cardY + cardHeight, 3.5f)
            } else {
                if (isUnlocked) {
                    shapeRenderer.setColor(0.25f, 0.55f, 0.40f, 0.65f)
                } else {
                    shapeRenderer.setColor(0.15f, 0.20f, 0.28f, 0.5f)
                }
                shapeRenderer.rectLine(colX, cardY, colX + colWidth, cardY, 1.5f)
                shapeRenderer.rectLine(colX, cardY + cardHeight, colX + colWidth, cardY + cardHeight, 1.5f)
            }

            // Badge Kotak Ikon Vektor Prosedural (Zero-Font Dependency)
            val boxX = colX + 12f
            val boxY = cardY + 11f
            val boxSize = 50f
            val cx = boxX + boxSize / 2f
            val cy = boxY + boxSize / 2f

            if (isUnlocked) {
                // Background & Border Emas
                shapeRenderer.setColor(0.85f, 0.65f, 0.15f, 0.35f)
                shapeRenderer.rect(boxX, boxY, boxSize, boxSize)
                shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.90f)
                shapeRenderer.rectLine(boxX, boxY, boxX + boxSize, boxY, 1.5f)
                shapeRenderer.rectLine(boxX, boxY + boxSize, boxX + boxSize, boxY + boxSize, 1.5f)
                shapeRenderer.rectLine(boxX, boxY, boxX, boxY + boxSize, 1.5f)
                shapeRenderer.rectLine(boxX + boxSize, boxY, boxX + boxSize, boxY + boxSize, 1.5f)

                // Vektor Piala Emas Bersinar (Trophy Chalice)
                shapeRenderer.setColor(1f, 0.88f, 0.25f, 1f)
                // Kaki & Batang Piala
                shapeRenderer.rect(cx - 10f, cy - 14f, 20f, 4f)
                shapeRenderer.rect(cx - 3f, cy - 10f, 6f, 7f)
                // Cawan Piala
                shapeRenderer.triangle(cx - 13f, cy + 12f, cx + 13f, cy + 12f, cx, cy - 3f)
                // Permata Bintang Inti
                shapeRenderer.setColor(1f, 1f, 0.65f, 1f)
                shapeRenderer.circle(cx, cy + 5f, 3.5f)
            } else {
                // Background & Border Besi Gembok
                shapeRenderer.setColor(0.10f, 0.14f, 0.20f, 0.75f)
                shapeRenderer.rect(boxX, boxY, boxSize, boxSize)
                shapeRenderer.setColor(0.30f, 0.38f, 0.50f, 0.70f)
                shapeRenderer.rectLine(boxX, boxY, boxX + boxSize, boxY, 1.5f)
                shapeRenderer.rectLine(boxX, boxY + boxSize, boxX + boxSize, boxY + boxSize, 1.5f)
                shapeRenderer.rectLine(boxX, boxY, boxX, boxY + boxSize, 1.5f)
                shapeRenderer.rectLine(boxX + boxSize, boxY, boxX + boxSize, boxY + boxSize, 1.5f)

                // Vektor Gembok Baja (Padlock)
                // Lengkungan Pengait (Shackle)
                shapeRenderer.setColor(0.70f, 0.75f, 0.85f, 0.9f)
                shapeRenderer.rectLine(cx - 7f, cy + 2f, cx - 7f, cy + 11f, 2.5f)
                shapeRenderer.rectLine(cx - 7f, cy + 11f, cx + 7f, cy + 11f, 2.5f)
                shapeRenderer.rectLine(cx + 7f, cy + 11f, cx + 7f, cy + 2f, 2.5f)
                // Badan Gembok
                shapeRenderer.setColor(0.42f, 0.48f, 0.60f, 0.95f)
                shapeRenderer.rect(cx - 10f, cy - 12f, 20f, 14f)
                // Lubang Kunci (Keyhole)
                shapeRenderer.setColor(0.06f, 0.08f, 0.12f, 1f)
                shapeRenderer.circle(cx, cy - 3f, 2.5f)
                shapeRenderer.rect(cx - 1f, cy - 8f, 2f, 5f)
            }
        }

        // Tombol Kembali Ke Menu
        shapeRenderer.setColor(0.18f, 0.08f, 0.10f, 0.95f)
        shapeRenderer.rect(980f, 32f, 250f, 46f)
        shapeRenderer.setColor(0.95f, 0.35f, 0.35f, 0.85f)
        shapeRenderer.rectLine(980f, 32f, 1230f, 32f, 2f)
        shapeRenderer.rectLine(980f, 78f, 1230f, 78f, 2f)
        shapeRenderer.rectLine(980f, 32f, 980f, 78f, 2f)
        shapeRenderer.rectLine(1230f, 32f, 1230f, 78f, 2f)

        shapeRenderer.end()

        // =========================================================================
        // 2. RENDER TEKS & IKON TIPOGRAFI (SPRITE BATCH)
        // =========================================================================
        batch.begin()

        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont

        // Judul Utama
        titleF.color = Color.WHITE
        titleF.draw(batch, "PRESTASI KSATRIA AETHELGARD", 70f, 680f)

        regF.setColor(1f, 0.85f, 0.3f, 1f)
        regF.draw(batch, "Piala Terkumpul: $unlockedCount / $totalCount (${(progressRatio * 100).toInt()}%)", 750f, 680f)

        // Kartu Prestasi
        for (i in achievements.indices) {
            val achv = achievements[i]
            val isUnlocked = AchievementManager.isUnlocked(achv.id)

            val colX = if (i < 6) 50f else 655f
            val rowIdx = if (i < 6) i else i - 6
            val cardY = startY - (rowIdx * spacingY)

            // Judul Prestasi
            if (isUnlocked) {
                headF.setColor(1f, 0.90f, 0.35f, 1f)
            } else {
                headF.setColor(0.60f, 0.65f, 0.75f, 0.85f)
            }
            headF.draw(batch, achv.title, colX + 75f, cardY + 54f)

            // Deskripsi Prestasi (Auto-Wrap Anti-Overflow ke Kolom Sebelah)
            if (isUnlocked) {
                regF.setColor(0.85f, 0.90f, 0.95f, 0.95f)
            } else {
                regF.setColor(0.45f, 0.50f, 0.60f, 0.70f)
            }
            val maxDescW = colWidth - 95f
            regF.draw(batch, achv.description, colX + 75f, cardY + 34f, maxDescW, com.badlogic.gdx.utils.Align.left, true)

            // Label Reward
            if (isUnlocked) {
                regF.setColor(0.35f, 0.95f, 0.55f, 1f)
                val claimText = "✓ TERBUKA (+${achv.goldReward}G)"
                glyphLayout.setText(regF, claimText)
                regF.draw(batch, claimText, colX + colWidth - glyphLayout.width - 15f, cardY + 54f)
            } else {
                regF.setColor(0.85f, 0.65f, 0.3f, 0.8f)
                val lockText = "HADIAH: +${achv.goldReward}G"
                glyphLayout.setText(regF, lockText)
                regF.draw(batch, lockText, colX + colWidth - glyphLayout.width - 15f, cardY + 54f)
            }
        }

        // Tombol Kembali
        headF.setColor(1f, 0.45f, 0.45f, 1f)
        glyphLayout.setText(headF, "KEMBALI KE MENU")
        headF.draw(batch, "KEMBALI KE MENU", 980f + (250f - glyphLayout.width) / 2f, 62f)

        // Petunjuk Kontrol
        regF.setColor(0.55f, 0.60f, 0.70f, 0.8f)
        regF.draw(batch, "[WASD / SENTUH] Telusuri Trofi  |  [ESC / BACK] Kembali", 70f, 58f)

        batch.end()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W)) {
            selectedIndex = if (selectedIndex in 1..5 || selectedIndex in 7..11) {
                selectedIndex - 1
            } else if (selectedIndex == 0) {
                5
            } else {
                11
            }
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S)) {
            selectedIndex = if (selectedIndex in 0..4 || selectedIndex in 6..10) {
                selectedIndex + 1
            } else if (selectedIndex == 5) {
                0
            } else {
                6
            }
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.LEFT) || Gdx.input.isKeyJustPressed(Keys.A)) {
            if (selectedIndex >= 6) {
                selectedIndex -= 6
                AudioManager.playJump()
            }
        }
        if (Gdx.input.isKeyJustPressed(Keys.RIGHT) || Gdx.input.isKeyJustPressed(Keys.D)) {
            if (selectedIndex < 6) {
                selectedIndex += 6
                AudioManager.playJump()
            }
        }

        // Deteksi Sentuh / Mouse
        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            val colWidth = 575f
            val cardHeight = 72f
            val startY = 535f
            val spacingY = 82f

            for (i in 0 until 12) {
                val colX = if (i < 6) 50f else 655f
                val rowIdx = if (i < 6) i else i - 6
                val cardY = startY - (rowIdx * spacingY)

                if (touchVec.x in colX..(colX + colWidth) && touchVec.y in cardY..(cardY + cardHeight)) {
                    selectedIndex = i
                    AudioManager.playSlashLight()
                    HapticManager.vibrateLight()
                    break
                }
            }

            // Klik Tombol Kembali (980f..1230f, 32f..78f)
            if (touchVec.x in 980f..1230f && touchVec.y in 32f..78f) {
                returnToPreviousScreen()
            }
        }

        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK)) {
            returnToPreviousScreen()
        }
    }

    private fun returnToPreviousScreen() {
        AudioManager.playSlashLight()
        (game as? StickmanGame)?.releasePreservedScreen(returnScreen ?: this)
        game.setScreen(returnScreen ?: MainMenuScreen(game))
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
