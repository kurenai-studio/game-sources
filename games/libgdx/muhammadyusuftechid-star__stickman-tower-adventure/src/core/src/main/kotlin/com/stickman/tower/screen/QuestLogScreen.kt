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
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.quest.QuestCategory
import com.stickman.tower.quest.QuestDefinition
import com.stickman.tower.quest.QuestManager
import com.stickman.tower.quest.QuestRegistry
import com.stickman.tower.quest.QuestStatus
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Screen Interaktif Jurnal Misi Menara (Quest Log Screen):
 * Memungkinkan pemain melihat progres kampanye Odyssey, menyelesaikan misi warisan kuno,
 * memeriksa persyaratan objektif, serta mengklaim reward (Gold, EXP, Relic, Talent Point).
 */
class QuestLogScreen(
    private val game: StickmanGame?,
    private val stats: CharacterStats? = null,
    private val returnScreen: Screen? = null
) : Screen {

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    enum class LogTab(val title: String) {
        MAIN("Cerita Utama"),
        SIDE("Warisan Kuno"),
        COMPLETED("Misi Selesai")
    }

    private var activeTab = LogTab.MAIN
    private var selectedIndex = 0
    private var pulseTimer = 0f

    // UI Regions
    private val btnTabMain = Rectangle(100f, 600f, 220f, 48f)
    private val btnTabSide = Rectangle(335f, 600f, 220f, 48f)
    private val btnTabCompleted = Rectangle(570f, 600f, 220f, 48f)
    private val btnTabGauntlet = Rectangle(805f, 600f, 260f, 48f)

    private val btnBack = Rectangle(40f, 35f, 180f, 50f)
    private val btnClaim = Rectangle(840f, 50f, 340f, 55f)

    private val titleFont: BitmapFont = FontManager.titleFont
    private val headerFont: BitmapFont = FontManager.headerFont
    private val regularFont: BitmapFont = FontManager.regularFont
    private val smallFont: BitmapFont = FontManager.smallFont

    override fun show() {
        QuestManager.syncRegistryObjectiveCounts()
        selectedIndex = 0
    }

    private fun getCurrentList(): List<QuestDefinition> {
        return when (activeTab) {
            LogTab.MAIN -> QuestRegistry.getMainQuests().filter {
                !QuestManager.completedQuestIds.contains(it.id)
            }
            LogTab.SIDE -> QuestRegistry.getSideQuests().filter {
                !QuestManager.completedQuestIds.contains(it.id)
            }
            LogTab.COMPLETED -> QuestRegistry.allQuests.filter {
                QuestManager.completedQuestIds.contains(it.id)
            }
        }
    }

    override fun render(delta: Float) {
        pulseTimer += delta
        handleInput()

        ScreenUtils.clear(0.06f, 0.07f, 0.10f, 1f)
        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        val list = getCurrentList()
        if (selectedIndex >= list.size) {
            selectedIndex = (list.size - 1).coerceAtLeast(0)
        }
        val selectedQuest = if (list.isNotEmpty() && selectedIndex in list.indices) list[selectedIndex] else null

        // 1. Render Pass Shapes
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Panel Kiri (Daftar Misi)
        shapeRenderer.setColor(0.10f, 0.12f, 0.17f, 0.85f)
        shapeRenderer.rect(100f, 100f, 440f, 480f)

        // Panel Kanan (Detail Misi Terpilih)
        shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.90f)
        shapeRenderer.rect(560f, 100f, 620f, 480f)

        // Tab Buttons
        drawTabButton(btnTabMain, LogTab.MAIN)
        drawTabButton(btnTabSide, LogTab.SIDE)
        drawTabButton(btnTabCompleted, LogTab.COMPLETED)

        // Tab Pintasan Gauntlet / Bounty
        shapeRenderer.setColor(0.18f, 0.22f, 0.32f, 0.85f)
        shapeRenderer.rect(btnTabGauntlet.x, btnTabGauntlet.y, btnTabGauntlet.width, btnTabGauntlet.height)
        shapeRenderer.setColor(0.95f, 0.80f, 0.30f, 0.9f)
        shapeRenderer.rect(btnTabGauntlet.x, btnTabGauntlet.y, btnTabGauntlet.width, 2f)

        // Tombol Kembali
        shapeRenderer.setColor(0.20f, 0.25f, 0.35f, 0.9f)
        shapeRenderer.rect(btnBack.x, btnBack.y, btnBack.width, btnBack.height)

        // Highlight Misi Terpilih pada Panel Kiri
        for (i in list.indices) {
            val itemY = 520f - (i * 68f)
            if (itemY < 110f) break

            val isSelected = (i == selectedIndex)
            val q = list[i]
            val status = QuestManager.getQuestStatus(q.id)

            if (isSelected) {
                shapeRenderer.setColor(0.25f, 0.32f, 0.48f, 0.85f)
                shapeRenderer.rect(108f, itemY, 424f, 60f)
                shapeRenderer.setColor(0.95f, 0.80f, 0.30f, 1f)
                shapeRenderer.rect(108f, itemY, 4f, 60f)
            } else {
                shapeRenderer.setColor(0.14f, 0.17f, 0.24f, 0.60f)
                shapeRenderer.rect(108f, itemY, 424f, 60f)
            }
        }

        // Tombol Klaim Reward (jika memenuhi syarat)
        if (selectedQuest != null && QuestManager.canClaimReward(selectedQuest.id)) {
            val pulse = (sin(pulseTimer * 6f) + 1f) * 0.5f
            shapeRenderer.setColor(0.2f + 0.1f * pulse, 0.75f + 0.15f * pulse, 0.3f, 0.95f)
            shapeRenderer.rect(btnClaim.x, btnClaim.y, btnClaim.width, btnClaim.height)
        }

        shapeRenderer.end()

        // 2. Render Pass Text
        batch.begin()

        // Header Judul Layar
        titleFont.setColor(0.95f, 0.85f, 0.40f, 1f)
        titleFont.draw(batch, "📜 JURNAL MISI AETHELGARD", 100f, 690f)

        // Teks Tab
        drawTabText(btnTabMain, "◈ Cerita Utama", activeTab == LogTab.MAIN)
        drawTabText(btnTabSide, "◇ Warisan Kuno", activeTab == LogTab.SIDE)
        drawTabText(btnTabCompleted, "✓ Selesai (${QuestManager.completedQuestIds.size})", activeTab == LogTab.COMPLETED)

        regularFont.setColor(0.95f, 0.85f, 0.40f, 1f)
        regularFont.draw(batch, "⚔ Ujian & Buronan ▶", btnTabGauntlet.x + 20f, btnTabGauntlet.y + 32f)

        // Teks Tombol Kembali
        regularFont.color = Color.WHITE
        regularFont.draw(batch, "◀ KEMBALI [B]", btnBack.x + 25f, btnBack.y + 32f)

        // Teks Daftar Misi pada Panel Kiri
        for (i in list.indices) {
            val itemY = 520f - (i * 68f)
            if (itemY < 110f) break

            val q = list[i]
            val status = QuestManager.getQuestStatus(q.id)

            val titleCol = when (status) {
                QuestStatus.COMPLETED -> Color.GRAY
                QuestStatus.OBJECTIVES_MET -> Color.GREEN
                QuestStatus.ACTIVE -> Color.WHITE
                else -> Color.LIGHT_GRAY
            }

            regularFont.color = titleCol
            regularFont.draw(batch, "${q.category.symbol} ${q.title}", 125f, itemY + 45f)

            // Status Badge
            val badgeText = when (status) {
                QuestStatus.COMPLETED -> "✓ Selesai"
                QuestStatus.OBJECTIVES_MET -> "★ SIAP KLAIM"
                QuestStatus.ACTIVE -> "• Sedang Berjalan (Lantai ${q.floorTarget})"
                QuestStatus.LOCKED -> "🔒 Terkunci"
                QuestStatus.AVAILABLE -> "◇ Tersedia"
                else -> ""
            }
            smallFont.setColor(if (status == QuestStatus.OBJECTIVES_MET) 0.3f else 0.7f, 0.85f, 0.5f, 0.9f)
            smallFont.draw(batch, badgeText, 125f, itemY + 22f)
        }

        if (list.isEmpty()) {
            regularFont.setColor(0.6f, 0.65f, 0.75f, 0.8f)
            regularFont.draw(batch, "Tidak ada misi dalam kategori ini.", 160f, 350f)
        }

        // Render Detail Misi Terpilih pada Panel Kanan
        if (selectedQuest != null) {
            renderQuestDetails(selectedQuest)
        }

        batch.end()
    }

    private fun renderQuestDetails(q: QuestDefinition) {
        val startX = 585f
        var curY = 555f

        // Kategori & Act Badge
        smallFont.setColor(0.9f, 0.75f, 0.3f, 1f)
        smallFont.draw(batch, "${q.category.displayName.uppercase()}  |  BAB ${q.actNumber}  |  LANTAI ${q.floorTarget}", startX, curY)
        curY -= 25f

        // Judul Misi
        headerFont.color = Color.WHITE
        headerFont.draw(batch, q.title, startX, curY)
        curY -= 35f

        // Sinopsis Lore
        smallFont.setColor(0.80f, 0.85f, 0.90f, 1f)
        glyphLayout.setText(smallFont, q.synopsis, Color.WHITE, 570f, 0, true)
        smallFont.draw(batch, q.synopsis, startX, curY, 570f, 0, true)
        curY -= glyphLayout.height + 25f

        // Garis Pembatas Objektif
        regularFont.setColor(0.95f, 0.82f, 0.35f, 1f)
        regularFont.draw(batch, "━━ TARGET & OBJEKTIF ━━", startX, curY)
        curY -= 25f

        // Daftar Objektif
        for (obj in q.objectives) {
            val current = QuestManager.getObjectiveCount(obj.id)
            val isDone = current >= obj.targetCount
            val icon = if (isDone) "✓" else "•"

            if (isDone) {
                smallFont.setColor(0.35f, 0.95f, 0.45f, 1f)
            } else {
                smallFont.setColor(0.85f, 0.90f, 0.95f, 1f)
            }

            val objText = "$icon ${obj.description}  [$current / ${obj.targetCount}]"
            smallFont.draw(batch, objText, startX + 10f, curY)
            curY -= 22f
        }

        curY -= 15f

        // Garis Hadiah
        regularFont.setColor(0.95f, 0.82f, 0.35f, 1f)
        regularFont.draw(batch, "━━ HADIAH PENYELESAIAN ━━", startX, curY)
        curY -= 25f

        val rewardItems = mutableListOf<String>()
        rewardItems.add("❖ +${q.goldReward} Gold")
        rewardItems.add("★ +${q.expReward} EXP")
        if (q.talentPointsReward > 0) {
            rewardItems.add("⚡ +${q.talentPointsReward} Talent Point")
        }
        if (q.relicReward != null) {
            rewardItems.add("⚔ Relik: ${q.relicReward.title}")
        }

        smallFont.setColor(1f, 0.85f, 0.4f, 1f)
        smallFont.draw(batch, rewardItems.joinToString("    |    "), startX + 10f, curY)

        // Teks Tombol Klaim
        if (QuestManager.canClaimReward(q.id)) {
            regularFont.setColor(0.05f, 0.15f, 0.05f, 1f)
            regularFont.draw(batch, "★ KLAIM HADIAH MISI ★", btnClaim.x + 55f, btnClaim.y + 35f)
        }
    }

    private fun drawTabButton(rect: Rectangle, tab: LogTab) {
        val isSelected = (activeTab == tab)
        if (isSelected) {
            shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.95f)
        } else {
            shapeRenderer.setColor(0.16f, 0.20f, 0.28f, 0.85f)
        }
        shapeRenderer.rect(rect.x, rect.y, rect.width, rect.height)
    }

    private fun drawTabText(rect: Rectangle, text: String, isSelected: Boolean) {
        regularFont.color = if (isSelected) Color.BLACK else Color.WHITE
        regularFont.draw(batch, text, rect.x + 20f, rect.y + 31f)
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.B)) {
            goBack()
            return
        }

        if (Gdx.input.isKeyJustPressed(Keys.TAB)) {
            activeTab = when (activeTab) {
                LogTab.MAIN -> LogTab.SIDE
                LogTab.SIDE -> LogTab.COMPLETED
                LogTab.COMPLETED -> LogTab.MAIN
            }
            selectedIndex = 0
            AudioManager.playSlashLight()
            return
        }

        val list = getCurrentList()
        if (Gdx.input.isKeyJustPressed(Keys.UP)) {
            if (selectedIndex > 0) {
                selectedIndex--
                AudioManager.playSlashLight()
            }
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN)) {
            if (selectedIndex < list.size - 1) {
                selectedIndex++
                AudioManager.playSlashLight()
            }
        }

        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE)) {
            if (list.isNotEmpty() && selectedIndex in list.indices) {
                val q = list[selectedIndex]
                if (QuestManager.canClaimReward(q.id)) {
                    claimSelected(q)
                }
            }
        }

        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            if (btnTabMain.contains(touchVec.x, touchVec.y)) {
                if (activeTab != LogTab.MAIN) {
                    activeTab = LogTab.MAIN
                    selectedIndex = 0
                    AudioManager.playSlashLight()
                    HapticManager.vibrateLight()
                }
            } else if (btnTabSide.contains(touchVec.x, touchVec.y)) {
                if (activeTab != LogTab.SIDE) {
                    activeTab = LogTab.SIDE
                    selectedIndex = 0
                    AudioManager.playSlashLight()
                    HapticManager.vibrateLight()
                }
            } else if (btnTabCompleted.contains(touchVec.x, touchVec.y)) {
                if (activeTab != LogTab.COMPLETED) {
                    activeTab = LogTab.COMPLETED
                    selectedIndex = 0
                    AudioManager.playSlashLight()
                    HapticManager.vibrateLight()
                }
            } else if (btnTabGauntlet.contains(touchVec.x, touchVec.y)) {
                AudioManager.playSlashLight()
                HapticManager.vibrateLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game?.setScreen(GauntletScreen(game, stats, this))
                return
            } else if (btnBack.contains(touchVec.x, touchVec.y)) {
                AudioManager.playSlashLight()
                HapticManager.vibrateMedium()
                goBack()
            } else if (btnClaim.contains(touchVec.x, touchVec.y)) {
                if (list.isNotEmpty() && selectedIndex in list.indices) {
                    val q = list[selectedIndex]
                    if (QuestManager.canClaimReward(q.id)) {
                        claimSelected(q)
                    }
                }
            } else if (touchVec.x in 100f..540f && touchVec.y in 100f..580f) {
                // Sentuhan pada daftar item misi
                for (i in list.indices) {
                    val itemY = 520f - (i * 68f)
                    if (touchVec.y in itemY..(itemY + 60f)) {
                        selectedIndex = i
                        AudioManager.playSlashLight()
                        HapticManager.vibrateLight()
                        break
                    }
                }
            }
        }
    }

    private fun claimSelected(quest: QuestDefinition) {
        val success = QuestManager.claimReward(quest.id, stats)
        if (success) {
            HapticManager.vibrateMedium()
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
