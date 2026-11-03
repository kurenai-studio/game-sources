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
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.Align
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.bossrush.BossRushManager
import com.stickman.tower.bossrush.BossRushRank
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Layar Arena Gauntlet of Sovereigns (Mode Boss Rush & Hall of Legends) (Fase 23).
 * Menampilkan urutan 5 bos legendaris, target evaluasi waktu per medali (S/A/B),
 * personal best per hero archetype, dan kustomisasi gelar ksatria siluet.
 */
class BossRushScreen(
    private val game: StickmanGame,
    private val returnScreen: Screen? = null
) : Screen {
    companion object {
        private val RANKS = listOf(BossRushRank.S_RANK, BossRushRank.A_RANK, BossRushRank.B_RANK)
        private val BOSS_STAGE_DESCRIPTIONS = listOf(
            "Tahap 1: General Oakhaven" to "Penjaga Menara • Gempa Seismik & Perisai Kayu Purba",
            "Tahap 2: The Amethyst Matron" to "Ratu Busur Bayang • Tembakan Kipas Panah Kristal",
            "Tahap 3: Shadow Doppelganger" to "Cermin Gelap • Refleksi Serangan & Tebasan Sabit",
            "Tahap 4: The Crimson Sovereign" to "Pangeran Darah • Teleportasi Kilat & Serangan Berserk",
            "Tahap 5: The Grand Calligrapher" to "Sang Penulis Takdir • Badai Goresan Tinta Kosmis"
        )
    }

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private var saveData: SaveData = SaveManager.load()
    private var animTime = 0f
    private var inputCooldown = 0.25f
    private var feedbackNotice = ""
    private var feedbackTimer = 0f

    // Tombol Aksi Bawah
    private val btnStart = Rectangle(840f, 40f, 340f, 55f)
    private val btnCycleTitle = Rectangle(480f, 40f, 320f, 55f)
    private val btnBack = Rectangle(100f, 40f, 220f, 55f)

    private val currentArchetype: CharacterArchetype
        get() = CharacterArchetype.fromString(saveData.selectedArchetype)

    override fun show() {
        saveData = SaveManager.load()
        inputCooldown = 0.25f
        feedbackNotice = ""
        feedbackTimer = 0f
        AudioManager.playFloorBgm(10, isBossFloor = true)
    }

    override fun render(delta: Float) {
        animTime += delta
        if (feedbackTimer > 0f) {
            feedbackTimer -= delta
            if (feedbackTimer <= 0f) feedbackNotice = ""
        }
        if (inputCooldown > 0f) {
            inputCooldown = (inputCooldown - delta).coerceAtLeast(0f)
        } else {
            handleInput()
        }

        ScreenUtils.clear(0.04f, 0.05f, 0.08f, 1f)
        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        // 1. SHAPE RENDERER PASS
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Panel Kiri: 5 Bos Gauntlet Stages
        shapeRenderer.setColor(0.08f, 0.10f, 0.15f, 0.92f)
        shapeRenderer.rect(100f, 115f, 540f, 465f)

        // Panel Kanan: Hall of Legends & Target Waktu Medali
        shapeRenderer.setColor(0.10f, 0.12f, 0.18f, 0.94f)
        shapeRenderer.rect(660f, 115f, 520f, 465f)

        // Border Panel Emas Halus
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.45f)
        shapeRenderer.rectLine(100f, 580f, 640f, 580f, 2f)
        shapeRenderer.rectLine(660f, 580f, 1180f, 580f, 2f)

        // 5 Kartu Bos di Panel Kiri
        val stageH = 76f
        val stageSpacing = 12f
        val stageStartY = 580f - 16f - stageH
        for (i in 0 until 5) {
            val sy = stageStartY - i * (stageH + stageSpacing)
            shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.88f)
            shapeRenderer.rect(115f, sy, 510f, stageH)

            // Garis Tepi Tahap
            shapeRenderer.setColor(0.35f, 0.45f, 0.60f, 0.5f)
            shapeRenderer.rectLine(115f, sy, 625f, sy, 1f)
            shapeRenderer.rectLine(115f, sy + stageH, 625f, sy + stageH, 1f)
            shapeRenderer.rectLine(115f, sy, 115f, sy + stageH, 1f)
            shapeRenderer.rectLine(625f, sy, 625f, sy + stageH, 1f)

            // Badge Nomor Tahap
            shapeRenderer.setColor(0.18f, 0.24f, 0.36f, 0.95f)
            shapeRenderer.rect(125f, sy + 10f, 56f, 56f)
        }

        // Kartu Rekor Personal Best di Panel Kanan Atas
        shapeRenderer.setColor(0.14f, 0.18f, 0.26f, 0.90f)
        shapeRenderer.rect(680f, 385f, 480f, 180f)
        val pulse = (sin(animTime * 5f) + 1f) * 0.15f
        shapeRenderer.setColor(1.0f, 0.85f, 0.3f, 0.75f + pulse)
        shapeRenderer.rectLine(680f, 565f, 1160f, 565f, 2f)

        // 3 Kartu Target Medali (S, A, B) di Panel Kanan Bawah
        val medalCardH = 68f
        val medalSpacing = 10f
        val medalStartY = 385f - 16f - medalCardH
        for (i in 0 until 3) {
            val r = RANKS[i]
            val my = medalStartY - i * (medalCardH + medalSpacing)
            shapeRenderer.setColor(0.12f, 0.14f, 0.20f, 0.85f)
            shapeRenderer.rect(680f, my, 480f, medalCardH)

            shapeRenderer.setColor(r.primaryColor.r, r.primaryColor.g, r.primaryColor.b, 0.7f)
            shapeRenderer.rect(680f, my, 8f, medalCardH)
        }

        // Tombol-Tombol Aksi Bawah
        // Tombol Start (Emas / Oranye Menyala)
        shapeRenderer.setColor(0.85f, 0.50f, 0.12f, 0.95f)
        shapeRenderer.rect(btnStart.x, btnStart.y, btnStart.width, btnStart.height)
        shapeRenderer.setColor(1f, 0.85f, 0.35f, 0.95f)
        shapeRenderer.rectLine(btnStart.x, btnStart.y + btnStart.height, btnStart.x + btnStart.width, btnStart.y + btnStart.height, 2.5f)

        // Tombol Ganti Gelar (Biru Indigo)
        shapeRenderer.setColor(0.18f, 0.25f, 0.42f, 0.95f)
        shapeRenderer.rect(btnCycleTitle.x, btnCycleTitle.y, btnCycleTitle.width, btnCycleTitle.height)
        shapeRenderer.setColor(0.45f, 0.85f, 1f, 0.85f)
        shapeRenderer.rectLine(btnCycleTitle.x, btnCycleTitle.y + btnCycleTitle.height, btnCycleTitle.x + btnCycleTitle.width, btnCycleTitle.y + btnCycleTitle.height, 2f)

        // Tombol Kembali (Dark Slate)
        shapeRenderer.setColor(0.16f, 0.20f, 0.28f, 0.92f)
        shapeRenderer.rect(btnBack.x, btnBack.y, btnBack.width, btnBack.height)
        shapeRenderer.setColor(0.6f, 0.7f, 0.85f, 0.75f)
        shapeRenderer.rectLine(btnBack.x, btnBack.y + btnBack.height, btnBack.x + btnBack.width, btnBack.y + btnBack.height, 1.5f)

        shapeRenderer.end()

        // 2. SPRITE BATCH TEXT PASS
        batch.begin()

        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Header Title
        titleF.setColor(1.0f, 0.85f, 0.30f, 1f)
        val mainTitle = "✦ GAUNTLET OF SOVEREIGNS (BOSS RUSH) ✦"
        glyphLayout.setText(titleF, mainTitle)
        titleF.draw(batch, mainTitle, (1280f - glyphLayout.width) / 2f, 690f)

        // Subtitle
        regF.setColor(0.85f, 0.90f, 0.95f, 0.90f)
        val subTitle = "Uji ketangkasan ksatria siluet melibas ke-5 Bos Legendaris Aethelgard secara beruntun!"
        glyphLayout.setText(regF, subTitle)
        regF.draw(batch, subTitle, (1280f - glyphLayout.width) / 2f, 638f)

        // Text Panel Kiri: 5 Bos Stages
        headF.setColor(0.95f, 0.75f, 0.25f, 1f)
        headF.draw(batch, "TAHAP PERTARUNGAN BERUNTUN", 125f, 565f)

        for (i in 0 until 5) {
            val sy = stageStartY - i * (stageH + stageSpacing)
            headF.setColor(1.0f, 0.85f, 0.3f, 1f)
            headF.draw(batch, "${i + 1}", 145f, sy + 46f)

            headF.setColor(Color.WHITE)
            headF.draw(batch, BOSS_STAGE_DESCRIPTIONS[i].first, 195f, sy + 58f)

            smallF.setColor(0.75f, 0.82f, 0.90f, 0.9f)
            smallF.draw(batch, BOSS_STAGE_DESCRIPTIONS[i].second, 195f, sy + 28f)
        }

        // Text Panel Kanan Atas: Hall of Legends Rekor Personal Best
        headF.setColor(0.95f, 0.75f, 0.25f, 1f)
        headF.draw(batch, "HALL OF LEGENDS: REKOR WAKTU", 700f, 550f)

        val archetypes = listOf(
            CharacterArchetype.BALANCED,
            CharacterArchetype.AGILE,
            CharacterArchetype.HEAVY
        )

        var recordY = 516f
        for (arch in archetypes) {
            val bTime = BossRushManager.getBestTime(arch.name, saveData)
            val bRank = BossRushManager.getBestRank(arch.name, saveData)
            val isCurrent = (arch == currentArchetype)
            val marker = if (isCurrent) " [AKTIF]" else ""
            val tStr = if (bTime > 0f) "${String.format("%.2f", bTime)}s (${bRank.badgeSymbol})" else "Belum Ditaklukkan (-)"

            regF.setColor(if (isCurrent) Color(1.0f, 0.88f, 0.35f, 1f) else Color(0.85f, 0.88f, 0.95f, 0.85f))
            regF.draw(batch, "• ${arch.characterName}$marker:", 700f, recordY)
            regF.setColor(bRank.primaryColor)
            regF.draw(batch, tStr, 1020f, recordY)
            recordY -= 24f
        }

        // Gelar Kehormatan Aktif
        val activeTitleMeta = BossRushManager.getTitleById(saveData.activeTitle)
        headF.setColor(activeTitleMeta.color)
        headF.draw(batch, "Gelar Ksatria: \"${activeTitleMeta.titleName}\"", 700f, 432f)
        smallF.setColor(0.85f, 0.88f, 0.95f, 0.90f)
        smallF.draw(batch, activeTitleMeta.description, 700f, 408f, 460f, Align.left, true)

        // Text Panel Kanan Bawah: Peringkat Medali Target
        for (i in 0 until 3) {
            val r = RANKS[i]
            val my = medalStartY - i * (medalCardH + medalSpacing)

            headF.setColor(r.primaryColor)
            val thresholdStr = if (r == BossRushRank.S_RANK) "< 180s (3m)" else if (r == BossRushRank.A_RANK) "< 270s (4.5m)" else "Selesaikan Boss Rush"
            headF.draw(batch, "${r.badgeSymbol}  ${r.displayName}  [$thresholdStr]", 705f, my + 52f)

            smallF.setColor(Color.WHITE)
            val rewardDesc = if (r.titleRewardId != null) {
                val t = BossRushManager.getTitleById(r.titleRewardId)
                "Hadiah: +${r.goldReward} Gold • Gelar \"${t.titleName}\""
            } else {
                "Hadiah: +${r.goldReward} Gold"
            }
            smallF.draw(batch, rewardDesc, 705f, my + 25f)
        }

        // Feedback Notice (Jika ada)
        if (feedbackNotice.isNotEmpty()) {
            regF.setColor(1.0f, 0.85f, 0.25f, 1f)
            glyphLayout.setText(regF, feedbackNotice)
            regF.draw(batch, feedbackNotice, (1280f - glyphLayout.width) / 2f, 108f)
        }

        // Teks Tombol Aksi Bawah
        headF.setColor(1f, 1f, 1f, 1f)
        glyphLayout.setText(headF, "MULAI GAUNTLET [ENTER]")
        headF.draw(batch, "MULAI GAUNTLET [ENTER]", btnStart.x + (btnStart.width - glyphLayout.width) / 2f, btnStart.y + 36f)

        glyphLayout.setText(headF, "GELAR AKTIF [T]")
        headF.draw(batch, "GELAR AKTIF [T]", btnCycleTitle.x + (btnCycleTitle.width - glyphLayout.width) / 2f, btnCycleTitle.y + 36f)

        glyphLayout.setText(headF, "KEMBALI [ESC]")
        headF.draw(batch, "KEMBALI [ESC]", btnBack.x + (btnBack.width - glyphLayout.width) / 2f, btnBack.y + 36f)

        batch.end()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK)) {
            AudioManager.playSlashLight()
            game.setScreen(returnScreen ?: MainMenuScreen(game))
            return
        }

        // Toggle / Siklus Gelar
        if (Gdx.input.isKeyJustPressed(Keys.T) || Gdx.input.isKeyJustPressed(Keys.TAB)) {
            cycleTitle()
        }

        // Mulai Tantangan Boss Rush
        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE)) {
            startBossRush()
            return
        }

        // Touch Input
        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            if (btnStart.contains(touchVec.x, touchVec.y)) {
                startBossRush()
                return
            }
            if (btnCycleTitle.contains(touchVec.x, touchVec.y)) {
                cycleTitle()
                return
            }
            if (btnBack.contains(touchVec.x, touchVec.y)) {
                AudioManager.playSlashLight()
                game.setScreen(returnScreen ?: MainMenuScreen(game))
                return
            }
        }
    }

    private fun cycleTitle() {
        val unlocked = saveData.unlockedTitles
        if (unlocked.size <= 1) {
            feedbackNotice = "Selesaikan Gauntlet (Rank S/A) atau Spire F20+ untuk membuka gelar baru!"
            feedbackTimer = 3.0f
            AudioManager.playHit()
            HapticManager.vibrateLight()
            return
        }

        val currentIndex = unlocked.indexOf(saveData.activeTitle)
        val nextIndex = if (currentIndex < 0) 0 else (currentIndex + 1) % unlocked.size
        BossRushManager.setActiveTitle(unlocked[nextIndex], saveData)
        SaveManager.saveAsync(saveData)
        AudioManager.playLevelUp()
        HapticManager.vibrateLight()
    }

    private fun startBossRush() {
        AudioManager.playBossRoar()
        HapticManager.vibrateHeavy()
        game.setScreen(PlayScreen(game, initialFloor = 3, gameMode = GameMode.BOSS_RUSH))
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
