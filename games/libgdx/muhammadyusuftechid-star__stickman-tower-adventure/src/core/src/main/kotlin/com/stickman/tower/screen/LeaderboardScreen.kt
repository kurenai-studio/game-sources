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
import com.stickman.tower.leaderboard.LeaderboardEntry
import com.stickman.tower.leaderboard.LeaderboardManager
import com.stickman.tower.ui.FontManager

/**
 * Layar Tampilan Papan Peringkat Ksatria Menara (Leaderboard Screen).
 * Menyajikan tab ganda: Endless Ascent & Speedrun Chrono, dengan nomor peringkat bergradasi,
 * dukungan sentuh mobile dan keyboard PC.
 */
class LeaderboardScreen(
    private val game: StickmanGame?,
    private val returnScreen: Screen? = null
) : Screen {

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    enum class LeaderboardTab {
        ENDLESS,
        SPEEDRUN
    }

    private var activeTab: LeaderboardTab = LeaderboardTab.ENDLESS

    private val btnTabEndless = Rectangle(340f, 600f, 280f, 50f)
    private val btnTabSpeedrun = Rectangle(660f, 600f, 280f, 50f)
    private val btnBack = Rectangle(40f, 40f, 180f, 52f)

    private val titleFont: BitmapFont = FontManager.titleFont
    private val bodyFont: BitmapFont = FontManager.regularFont

    override fun show() {
        LeaderboardManager.loadRecords()
    }

    override fun render(delta: Float) {
        handleInput()

        ScreenUtils.clear(0.08f, 0.09f, 0.12f, 1f)
        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        // 1. Gambar Background & Frame UI
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Panel Utama Tabel
        shapeRenderer.setColor(0.12f, 0.14f, 0.20f, 0.85f)
        shapeRenderer.rect(100f, 110f, 1080f, 470f)

        // Tab Buttons
        val tabEndlessColor = if (activeTab == LeaderboardTab.ENDLESS) Color(0.85f, 0.70f, 0.25f, 0.95f) else Color(0.18f, 0.22f, 0.30f, 0.85f)
        shapeRenderer.color = tabEndlessColor
        shapeRenderer.rect(btnTabEndless.x, btnTabEndless.y, btnTabEndless.width, btnTabEndless.height)

        val tabSpeedrunColor = if (activeTab == LeaderboardTab.SPEEDRUN) Color(0.85f, 0.70f, 0.25f, 0.95f) else Color(0.18f, 0.22f, 0.30f, 0.85f)
        shapeRenderer.color = tabSpeedrunColor
        shapeRenderer.rect(btnTabSpeedrun.x, btnTabSpeedrun.y, btnTabSpeedrun.width, btnTabSpeedrun.height)

        // Tombol Kembali
        shapeRenderer.setColor(0.22f, 0.26f, 0.36f, 0.90f)
        shapeRenderer.rect(btnBack.x, btnBack.y, btnBack.width, btnBack.height)

        // Header Tabel
        shapeRenderer.setColor(0.16f, 0.20f, 0.28f, 0.95f)
        shapeRenderer.rect(100f, 535f, 1080f, 45f)

        shapeRenderer.end()

        // 2. Gambar Garis Bingkai Emas
        shapeRenderer.begin(ShapeRenderer.ShapeType.Line)
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.70f)
        shapeRenderer.rect(100f, 110f, 1080f, 470f)
        shapeRenderer.rect(btnTabEndless.x, btnTabEndless.y, btnTabEndless.width, btnTabEndless.height)
        shapeRenderer.rect(btnTabSpeedrun.x, btnTabSpeedrun.y, btnTabSpeedrun.width, btnTabSpeedrun.height)
        shapeRenderer.rect(btnBack.x, btnBack.y, btnBack.width, btnBack.height)
        shapeRenderer.end()

        // 3. Render Teks & Data Tabel
        batch.begin()

        // Judul Layar
        titleFont.color = Color.GOLD
        titleFont.draw(batch, "PAPAN PERINGKAT KSATRIA MENARA", 0f, 695f, 1280f, Align.center, false)

        // Teks Tab
        bodyFont.color = if (activeTab == LeaderboardTab.ENDLESS) Color.BLACK else Color.WHITE
        bodyFont.draw(batch, "ENDLESS ASCENT", btnTabEndless.x, btnTabEndless.y + 33f, btnTabEndless.width, Align.center, false)

        bodyFont.color = if (activeTab == LeaderboardTab.SPEEDRUN) Color.BLACK else Color.WHITE
        bodyFont.draw(batch, "SPEEDRUN CHRONO", btnTabSpeedrun.x, btnTabSpeedrun.y + 33f, btnTabSpeedrun.width, Align.center, false)

        // Header Kolom Tabel
        bodyFont.color = Color.GOLD
        bodyFont.draw(batch, "RANK", 130f, 565f)
        bodyFont.draw(batch, "NAMA KSATRIA", 240f, 565f)
        bodyFont.draw(batch, "ARKETIPE", 510f, 565f)
        bodyFont.draw(batch, "LANTAI", 710f, 565f)
        bodyFont.draw(batch, if (activeTab == LeaderboardTab.ENDLESS) "SKOR ANIMA" else "WAKTU TEMPUH", 850f, 565f)
        bodyFont.draw(batch, if (activeTab == LeaderboardTab.ENDLESS) "DURASI" else "SKOR TOTAL", 1020f, 565f)

        // Render Baris Data
        val records: List<LeaderboardEntry> = if (activeTab == LeaderboardTab.ENDLESS) {
            LeaderboardManager.getEndlessRecords()
        } else {
            LeaderboardManager.getSpeedrunRecords()
        }

        var startY = 510f
        records.forEachIndexed { index, entry ->
            val rankColor = when (index) {
                0 -> Color.GOLD
                1 -> Color.LIGHT_GRAY
                2 -> Color(0.80f, 0.50f, 0.20f, 1f) // Bronze
                else -> Color.WHITE
            }

            bodyFont.color = rankColor
            bodyFont.draw(batch, "#${index + 1}", 130f, startY)

            bodyFont.color = Color.WHITE
            bodyFont.draw(batch, entry.playerName, 240f, startY)
            bodyFont.draw(batch, entry.characterArchetype, 510f, startY)
            bodyFont.draw(batch, "Lt. ${entry.floorReached}", 710f, startY)

            if (activeTab == LeaderboardTab.ENDLESS) {
                bodyFont.color = Color.CYAN
                bodyFont.draw(batch, "%,d pts".format(entry.score), 850f, startY)
                bodyFont.color = Color.LIGHT_GRAY
                bodyFont.draw(batch, entry.getFormattedTime(), 1020f, startY)
            } else {
                bodyFont.color = Color.CYAN
                bodyFont.draw(batch, entry.getFormattedTime(), 850f, startY)
                bodyFont.color = Color.LIGHT_GRAY
                bodyFont.draw(batch, "%,d pts".format(entry.score), 1020f, startY)
            }

            startY -= 38f
        }

        if (records.isEmpty()) {
            bodyFont.color = Color.GRAY
            bodyFont.draw(batch, "Belum ada catatan rekor. Mendakilah menara untuk mencatatkan namamu!", 100f, 340f, 1080f, Align.center, false)
        }

        // Teks Tombol Kembali
        bodyFont.color = Color.WHITE
        bodyFont.draw(batch, "< KEMBALI", btnBack.x, btnBack.y + 34f, btnBack.width, Align.center, false)

        batch.end()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.B)) {
            goBack()
            return
        }

        if (Gdx.input.isKeyJustPressed(Keys.TAB)) {
            activeTab = if (activeTab == LeaderboardTab.ENDLESS) LeaderboardTab.SPEEDRUN else LeaderboardTab.ENDLESS
            AudioManager.playParry()
            return
        }

        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            if (btnTabEndless.contains(touchVec.x, touchVec.y)) {
                if (activeTab != LeaderboardTab.ENDLESS) {
                    activeTab = LeaderboardTab.ENDLESS
                    AudioManager.playParry()
                    HapticManager.vibrateLight()
                }
            } else if (btnTabSpeedrun.contains(touchVec.x, touchVec.y)) {
                if (activeTab != LeaderboardTab.SPEEDRUN) {
                    activeTab = LeaderboardTab.SPEEDRUN
                    AudioManager.playParry()
                    HapticManager.vibrateLight()
                }
            } else if (btnBack.contains(touchVec.x, touchVec.y)) {
                AudioManager.playSlashLight()
                HapticManager.vibrateMedium()
                goBack()
            }
        }
    }

    private fun goBack() {
        if (returnScreen != null) {
            game?.screen = returnScreen
        } else if (game != null) {
            game.screen = MainMenuScreen(game)
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
