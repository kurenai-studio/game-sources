package com.stickman.tower.tools

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.Player
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.ui.FontManager
import com.stickman.tower.world.TowerFloor

/**
 * Tab navigasi pada Developer Console & Profiler Overlay.
 */
enum class DevTab {
    CHEATS,
    WARP_SPAWN,
    PROFILER_AUDIT,
    CLI_CONSOLE
}

/**
 * In-Game Developer Console, Profiler & QA Testing Overlay (10/10 Tools Architecture):
 * Menyediakan alat pemantau performa realtime, pengubah state permainan (God Mode, Infinite SP),
 * pengatur kecepatan waktu (Timescale 0.1x - 2.0x, Pause & 1-Frame Step), Hot-Swap Arketipe Karakter,
 * Live Enemy Spawner, Level Reachability Validator, Headless Combat Simulator, dan CLI Command Runner.
 */
class DevToolsOverlay {

    var isVisible: Boolean = false
    var currentTab: DevTab = DevTab.CHEATS

    // QA & Cheat Toggles
    var isGodMode: Boolean = false
    var isInfiniteEnergy: Boolean = false
    var showHitboxes: Boolean = false

    // Kontrol Kecepatan Waktu (Timescale & Frame-Step)
    var timeScale: Float = 1.0f
    var isPaused: Boolean = false
    var pendingStepFrame: Boolean = false

    // Status Audit & Output Log Terakhir
    var lastAuditSummary: String = "Audit belum dijalankan. Pilih tombol audit di bawah."

    // Command Dispatcher CLI
    val dispatcher = DevCommandDispatcher()

    // Callback Aksi yang Dihubungkan ke PlayScreen
    var onWarpFloor: ((Int) -> Unit)? = null
    var onGrantGold: ((Int) -> Unit)? = null
    var onGrantLevel: (() -> Unit)? = null
    var onHealFull: (() -> Unit)? = null
    var onKillAllEnemies: (() -> Unit)? = null
    var onSwitchArchetype: ((CharacterArchetype) -> Unit)? = null
    var onSpawnEnemy: ((EnemyType) -> Unit)? = null

    // Tombol Navigasi Umum
    private val btnClose = Rectangle(1000f, 580f, 40f, 35f)
    private val tabBtnCheats = Rectangle(250f, 445f, 185f, 32f)
    private val tabBtnWarp = Rectangle(445f, 445f, 185f, 32f)
    private val tabBtnAudit = Rectangle(640f, 445f, 195f, 32f)
    private val tabBtnCli = Rectangle(845f, 445f, 185f, 32f)

    // Tombol TAB 1: CHEATS & SPEED
    private val btnGodMode = Rectangle(250f, 390f, 180f, 38f)
    private val btnInfEnergy = Rectangle(450f, 390f, 180f, 38f)
    private val btnHitboxes = Rectangle(650f, 390f, 180f, 38f)
    private val btnHeal = Rectangle(850f, 390f, 180f, 38f)

    private val btnGrantGold = Rectangle(250f, 335f, 180f, 38f)
    private val btnGrantLevel = Rectangle(450f, 335f, 180f, 38f)
    private val btnKillEnemies = Rectangle(650f, 335f, 180f, 38f)
    private val btnCycleHero = Rectangle(850f, 335f, 180f, 38f)

    private val btnSpeed01 = Rectangle(250f, 235f, 115f, 34f)
    private val btnSpeed05 = Rectangle(375f, 235f, 115f, 34f)
    private val btnSpeed10 = Rectangle(500f, 235f, 115f, 34f)
    private val btnSpeed20 = Rectangle(625f, 235f, 115f, 34f)
    private val btnPauseToggle = Rectangle(750f, 235f, 135f, 34f)
    private val btnStepFrame = Rectangle(895f, 235f, 135f, 34f)

    // Tombol TAB 2: WARP 5 SAGA (50 LANTAI) & SPAWN
    private val btnWarpF1 = Rectangle(250f, 390f, 125f, 34f)
    private val btnWarpF10 = Rectangle(385f, 390f, 125f, 34f)
    private val btnWarpF20 = Rectangle(520f, 390f, 125f, 34f)
    private val btnWarpF30 = Rectangle(655f, 390f, 125f, 34f)
    private val btnWarpF40 = Rectangle(790f, 390f, 125f, 34f)
    private val btnWarpF50 = Rectangle(925f, 390f, 125f, 34f)

    private val btnWarpF5 = Rectangle(250f, 340f, 125f, 34f)
    private val btnWarpF15 = Rectangle(385f, 340f, 125f, 34f)
    private val btnWarpF25 = Rectangle(520f, 340f, 125f, 34f)
    private val btnWarpF35 = Rectangle(655f, 340f, 125f, 34f)
    private val btnWarpF45 = Rectangle(790f, 340f, 125f, 34f)
    private val btnWarpEndless50 = Rectangle(925f, 340f, 125f, 34f)

    private val btnSpawnMelee = Rectangle(250f, 235f, 180f, 36f)
    private val btnSpawnRanged = Rectangle(445f, 235f, 180f, 36f)
    private val btnSpawnFlying = Rectangle(640f, 235f, 180f, 36f)
    private val btnSpawnShield = Rectangle(835f, 235f, 195f, 36f)

    // Tombol TAB 3: PROFILER & AUDIT
    private val btnRunSanity = Rectangle(250f, 390f, 180f, 36f)
    private val btnRunReachability = Rectangle(445f, 390f, 195f, 36f)
    private val btnRunBalance = Rectangle(655f, 390f, 185f, 36f)
    private val btnRunAssets = Rectangle(855f, 390f, 175f, 36f)

    // Tombol TAB 4: CONSOLE CLI QUICK ACTIONS
    private val btnCliHelp = Rectangle(250f, 390f, 120f, 34f)
    private val btnCliGod = Rectangle(380f, 390f, 120f, 34f)
    private val btnCliHeal = Rectangle(510f, 390f, 120f, 34f)
    private val btnCliGold = Rectangle(640f, 390f, 130f, 34f)
    private val btnCliSim = Rectangle(780f, 390f, 125f, 34f)
    private val btnCliReach = Rectangle(915f, 390f, 115f, 34f)
    private val btnCliUnlockAll = Rectangle(250f, 340f, 380f, 34f)
    private val btnCliReset = Rectangle(640f, 340f, 390f, 34f)

    private val touchPoint = Vector3()

    init {
        // Hubungkan callback default ke dispatcher internal
        dispatcher.onSetGodMode = { isGodMode = it }
        dispatcher.onSetInfiniteEnergy = { isInfiniteEnergy = it }
        dispatcher.onSetTimeScale = { timeScale = it; isPaused = it <= 0f }
        dispatcher.onStepFrame = { step() }
        dispatcher.onWarpFloor = { onWarpFloor?.invoke(it) }
        dispatcher.onHealFull = { onHealFull?.invoke() }
        dispatcher.onGrantGold = { onGrantGold?.invoke(it) }
        dispatcher.onGrantLevel = { onGrantLevel?.invoke() }
        dispatcher.onKillAllEnemies = { onKillAllEnemies?.invoke() }
        dispatcher.onSwitchArchetype = { onSwitchArchetype?.invoke(it) }
        dispatcher.onSpawnEnemy = { onSpawnEnemy?.invoke(it) }
        dispatcher.onToggleHitboxes = { if (it != null) showHitboxes = it else showHitboxes = !showHitboxes }
    }

    fun toggle() {
        isVisible = !isVisible
    }

    fun step() {
        pendingStepFrame = true
    }

    fun consumeStep(): Boolean {
        if (pendingStepFrame) {
            pendingStepFrame = false
            return true
        }
        return false
    }

    /**
     * Helper extension untuk mengecek apakah titik (px, py) berada di dalam rectangle
     * dengan toleransi margin sentuh tambahan untuk kenyamanan tombol mobile/mouse.
     */
    private fun Rectangle.containsPoint(px: Float, py: Float, margin: Float = 6f): Boolean {
        return px in (x - margin)..(x + width + margin) && py in (y - margin)..(y + height + margin)
    }

    /**
     * Memproses input klik / sentuhan pada panel Developer Tools.
     */
    fun handleTouchDown(screenX: Int, screenY: Int, viewport: Viewport, currentFloor: TowerFloor, player: Player? = null): Boolean {
        if (!isVisible) return false

        touchPoint.set(screenX.toFloat(), screenY.toFloat(), 0f)
        viewport.unproject(touchPoint)
        val tx = touchPoint.x
        val ty = touchPoint.y

        // Tombol Tutup [ X ] di kanan atas modal
        if (btnClose.containsPoint(tx, ty, 8f)) {
            isVisible = false
            AudioManager.playSlashLight()
            return true
        }

        // Navigasi Tab
        if (tabBtnCheats.containsPoint(tx, ty, 4f)) { currentTab = DevTab.CHEATS; AudioManager.playJump(); return true }
        if (tabBtnWarp.containsPoint(tx, ty, 4f)) { currentTab = DevTab.WARP_SPAWN; AudioManager.playJump(); return true }
        if (tabBtnAudit.containsPoint(tx, ty, 4f)) { currentTab = DevTab.PROFILER_AUDIT; AudioManager.playJump(); return true }
        if (tabBtnCli.containsPoint(tx, ty, 4f)) { currentTab = DevTab.CLI_CONSOLE; AudioManager.playJump(); return true }

        when (currentTab) {
            DevTab.CHEATS -> {
                if (btnGodMode.containsPoint(tx, ty, 4f)) { isGodMode = !isGodMode; AudioManager.playSlashLight(); return true }
                if (btnInfEnergy.containsPoint(tx, ty, 4f)) { isInfiniteEnergy = !isInfiniteEnergy; AudioManager.playSlashLight(); return true }
                if (btnHitboxes.containsPoint(tx, ty, 4f)) { showHitboxes = !showHitboxes; AudioManager.playSlashLight(); return true }
                if (btnHeal.containsPoint(tx, ty, 4f)) { onHealFull?.invoke(); AudioManager.playLevelUp(); return true }
                if (btnGrantGold.containsPoint(tx, ty, 4f)) { onGrantGold?.invoke(1000); AudioManager.playChest(); return true }
                if (btnGrantLevel.containsPoint(tx, ty, 4f)) { onGrantLevel?.invoke(); AudioManager.playLevelUp(); return true }
                if (btnKillEnemies.containsPoint(tx, ty, 4f)) { onKillAllEnemies?.invoke(); AudioManager.playSlashHeavy(); return true }

                if (btnCycleHero.containsPoint(tx, ty, 4f) && player != null) {
                    val current = player.archetype
                    val next = when (current) {
                        CharacterArchetype.BALANCED -> CharacterArchetype.AGILE
                        CharacterArchetype.AGILE -> CharacterArchetype.HEAVY
                        CharacterArchetype.HEAVY -> CharacterArchetype.BALANCED
                    }
                    player.switchArchetype(next)
                    onSwitchArchetype?.invoke(next)
                    AudioManager.playDodge()
                    return true
                }

                // Timescale controls
                if (btnSpeed01.containsPoint(tx, ty, 4f)) { timeScale = 0.1f; isPaused = false; AudioManager.playSlashLight(); return true }
                if (btnSpeed05.containsPoint(tx, ty, 4f)) { timeScale = 0.5f; isPaused = false; AudioManager.playSlashLight(); return true }
                if (btnSpeed10.containsPoint(tx, ty, 4f)) { timeScale = 1.0f; isPaused = false; AudioManager.playSlashLight(); return true }
                if (btnSpeed20.containsPoint(tx, ty, 4f)) { timeScale = 2.0f; isPaused = false; AudioManager.playSlashLight(); return true }
                if (btnPauseToggle.containsPoint(tx, ty, 4f)) { isPaused = !isPaused; AudioManager.playSlashLight(); return true }
                if (btnStepFrame.containsPoint(tx, ty, 4f)) { isPaused = true; step(); AudioManager.playSlashLight(); return true }
            }
            DevTab.WARP_SPAWN -> {
                if (btnWarpF1.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(1); AudioManager.playSlashLight(); return true }
                if (btnWarpF10.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(10); AudioManager.playSlashLight(); return true }
                if (btnWarpF20.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(20); AudioManager.playSlashLight(); return true }
                if (btnWarpF30.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(30); AudioManager.playSlashLight(); return true }
                if (btnWarpF40.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(40); AudioManager.playSlashLight(); return true }
                if (btnWarpF50.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(50); AudioManager.playSlashLight(); return true }

                if (btnWarpF5.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(5); AudioManager.playSlashLight(); return true }
                if (btnWarpF15.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(15); AudioManager.playSlashLight(); return true }
                if (btnWarpF25.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(25); AudioManager.playSlashLight(); return true }
                if (btnWarpF35.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(35); AudioManager.playSlashLight(); return true }
                if (btnWarpF45.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(45); AudioManager.playSlashLight(); return true }
                if (btnWarpEndless50.containsPoint(tx, ty, 4f)) { onWarpFloor?.invoke(50); AudioManager.playSlashLight(); return true }

                if (btnSpawnMelee.containsPoint(tx, ty, 4f)) { onSpawnEnemy?.invoke(EnemyType.MELEE); AudioManager.playDodge(); return true }
                if (btnSpawnRanged.containsPoint(tx, ty, 4f)) { onSpawnEnemy?.invoke(EnemyType.RANGED); AudioManager.playDodge(); return true }
                if (btnSpawnFlying.containsPoint(tx, ty, 4f)) { onSpawnEnemy?.invoke(EnemyType.FLYING); AudioManager.playDodge(); return true }
                if (btnSpawnShield.containsPoint(tx, ty, 4f)) { onSpawnEnemy?.invoke(EnemyType.SHIELDED); AudioManager.playDodge(); return true }
            }
            DevTab.PROFILER_AUDIT -> {
                if (btnRunSanity.containsPoint(tx, ty, 4f)) {
                    val report = LevelSanityValidator.validateFloor(currentFloor)
                    lastAuditSummary = report.summary()
                    AudioManager.playSlashLight()
                    return true
                }
                if (btnRunReachability.containsPoint(tx, ty, 4f)) {
                    val report = LevelReachabilityGraph.analyzeFloor(currentFloor)
                    lastAuditSummary = report.summary()
                    AudioManager.playSlashLight()
                    return true
                }
                if (btnRunBalance.containsPoint(tx, ty, 4f)) {
                    val report = CombatBalanceSimulator.runFullAudit(roundsPerArchetype = 30)
                    lastAuditSummary = "SIMULATION DONE: OverallBalanced=${report.overallBalanced}, WinRate=${"%.1f".format(report.globalWinRate * 100)}%"
                    AudioManager.playSlashLight()
                    return true
                }
                if (btnRunAssets.containsPoint(tx, ty, 4f)) {
                    val report = AssetPipelineValidator.validateAll()
                    lastAuditSummary = report.summary()
                    AudioManager.playSlashLight()
                    return true
                }
            }
            DevTab.CLI_CONSOLE -> {
                if (btnCliHelp.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("help"); AudioManager.playSlashLight(); return true }
                if (btnCliGod.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("god"); AudioManager.playSlashLight(); return true }
                if (btnCliHeal.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("heal"); AudioManager.playLevelUp(); return true }
                if (btnCliGold.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("gold 5000"); AudioManager.playChest(); return true }
                if (btnCliSim.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("simulate 20"); AudioManager.playSlashLight(); return true }
                if (btnCliReach.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("reachability"); AudioManager.playSlashLight(); return true }
                if (btnCliUnlockAll.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("unlock_all"); AudioManager.playLevelUp(); return true }
                if (btnCliReset.containsPoint(tx, ty, 4f)) { dispatcher.dispatch("reset_save"); AudioManager.playHit(); return true }
            }
        }

        // Sentuhan di dalam area panel modal -> konsumsi input (cegah kebocoran input ke game di bawahnya)
        if (tx in 220f..1060f && ty in 90f..630f) {
            return true
        }

        // Sentuhan di luar panel modal (backdrop gelap) -> tutup overlay dengan aman
        isVisible = false
        AudioManager.playSlashLight()
        return true
    }

    /**
     * Merender panel profil dan alat pengembang pada viewport UI.
     */
    fun render(
        shapeRenderer: ShapeRenderer,
        batch: SpriteBatch,
        camera: OrthographicCamera,
        player: Player,
        currentFloor: TowerFloor,
        particleCount: Int
    ) {
        if (!isVisible) return

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        val regF = FontManager.regularFont
        val headF = FontManager.headerFont

        // 1. Gambar Panel Latar Belakang Modal (Dark Obsidian)
        shapeRenderer.projectionMatrix = camera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Backdrop Dimmer
        shapeRenderer.setColor(0f, 0f, 0f, 0.75f)
        shapeRenderer.rect(0f, 0f, 1280f, 720f)

        // Panel Utama
        shapeRenderer.setColor(0.05f, 0.07f, 0.11f, 0.96f)
        shapeRenderer.rect(220f, 90f, 840f, 540f)

        // Header Bar Neon Cyan
        shapeRenderer.setColor(0.12f, 0.65f, 0.85f, 1f)
        shapeRenderer.rectLine(220f, 630f, 1060f, 630f, 3f)

        // Tombol Tutup [ X ]
        shapeRenderer.setColor(0.85f, 0.20f, 0.25f, 0.9f)
        shapeRenderer.rect(btnClose.x, btnClose.y, btnClose.width, btnClose.height)

        // Render Baris Tab Navigasi
        renderTabHeader(shapeRenderer, tabBtnCheats, currentTab == DevTab.CHEATS, Color.CYAN)
        renderTabHeader(shapeRenderer, tabBtnWarp, currentTab == DevTab.WARP_SPAWN, Color.CORAL)
        renderTabHeader(shapeRenderer, tabBtnAudit, currentTab == DevTab.PROFILER_AUDIT, Color.CHARTREUSE)
        renderTabHeader(shapeRenderer, tabBtnCli, currentTab == DevTab.CLI_CONSOLE, Color.GOLD)

        // Render Konten Sesuai Tab Aktif
        when (currentTab) {
            DevTab.CHEATS -> {
                renderButtonShape(shapeRenderer, btnGodMode, if (isGodMode) Color.GREEN else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnInfEnergy, if (isInfiniteEnergy) Color.CYAN else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnHitboxes, if (showHitboxes) Color.ORANGE else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnHeal, Color(0.2f, 0.6f, 0.3f, 1f))

                renderButtonShape(shapeRenderer, btnGrantGold, Color(0.7f, 0.55f, 0.1f, 1f))
                renderButtonShape(shapeRenderer, btnGrantLevel, Color(0.3f, 0.4f, 0.8f, 1f))
                renderButtonShape(shapeRenderer, btnKillEnemies, Color(0.7f, 0.2f, 0.2f, 1f))
                renderButtonShape(shapeRenderer, btnCycleHero, Color(0.5f, 0.2f, 0.7f, 1f))

                renderButtonShape(shapeRenderer, btnSpeed01, if (timeScale == 0.1f && !isPaused) Color.MAGENTA else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnSpeed05, if (timeScale == 0.5f && !isPaused) Color.MAGENTA else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnSpeed10, if (timeScale == 1.0f && !isPaused) Color.ROYAL else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnSpeed20, if (timeScale == 2.0f && !isPaused) Color.GOLD else Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnPauseToggle, if (isPaused) Color.RED else Color(0.3f, 0.3f, 0.3f, 1f))
                renderButtonShape(shapeRenderer, btnStepFrame, Color(0.2f, 0.5f, 0.6f, 1f))
            }
            DevTab.WARP_SPAWN -> {
                renderButtonShape(shapeRenderer, btnWarpF1, Color(0.2f, 0.4f, 0.5f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF10, Color(0.6f, 0.2f, 0.2f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF20, Color(0.7f, 0.25f, 0.1f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF30, Color(0.5f, 0.1f, 0.6f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF40, Color(0.2f, 0.5f, 0.7f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF50, Color(0.8f, 0.65f, 0.1f, 1f))

                renderButtonShape(shapeRenderer, btnWarpF5, Color(0.3f, 0.3f, 0.4f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF15, Color(0.4f, 0.2f, 0.3f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF25, Color(0.4f, 0.3f, 0.2f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF35, Color(0.2f, 0.3f, 0.5f, 1f))
                renderButtonShape(shapeRenderer, btnWarpF45, Color(0.3f, 0.4f, 0.5f, 1f))
                renderButtonShape(shapeRenderer, btnWarpEndless50, Color(0.6f, 0.1f, 0.6f, 1f))

                renderButtonShape(shapeRenderer, btnSpawnMelee, Color(0.6f, 0.25f, 0.25f, 1f))
                renderButtonShape(shapeRenderer, btnSpawnRanged, Color(0.3f, 0.25f, 0.6f, 1f))
                renderButtonShape(shapeRenderer, btnSpawnFlying, Color(0.2f, 0.55f, 0.45f, 1f))
                renderButtonShape(shapeRenderer, btnSpawnShield, Color(0.4f, 0.4f, 0.2f, 1f))
            }
            DevTab.PROFILER_AUDIT -> {
                renderButtonShape(shapeRenderer, btnRunSanity, Color.ROYAL)
                renderButtonShape(shapeRenderer, btnRunReachability, Color(0.2f, 0.55f, 0.4f, 1f))
                renderButtonShape(shapeRenderer, btnRunBalance, Color(0.6f, 0.45f, 0.1f, 1f))
                renderButtonShape(shapeRenderer, btnRunAssets, Color(0.5f, 0.25f, 0.55f, 1f))
            }
            DevTab.CLI_CONSOLE -> {
                renderButtonShape(shapeRenderer, btnCliHelp, Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnCliGod, Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnCliHeal, Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnCliGold, Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnCliSim, Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnCliReach, Color.DARK_GRAY)
                renderButtonShape(shapeRenderer, btnCliUnlockAll, Color(0.2f, 0.5f, 0.3f, 1f))
                renderButtonShape(shapeRenderer, btnCliReset, Color(0.55f, 0.15f, 0.15f, 1f))
            }
        }

        shapeRenderer.end()

        // 2. Render Teks & Metrik Profiler
        batch.projectionMatrix = camera.combined
        batch.begin()

        headF.setColor(0.2f, 0.85f, 1.0f, 1f)
        headF.draw(batch, "⚙ DEVELOPER CONSOLE & TOOLS SUITE (10/10)", 250f, 615f)

        regF.setColor(1f, 1f, 1f, 1f)
        regF.draw(batch, "X", btnClose.x + 13f, btnClose.y + 25f)

        // Metrik Realtime & Profiler Engine
        val fps = Gdx.graphics.framesPerSecond
        val deltaMs = (Gdx.graphics.deltaTime * 1000f).toInt()
        val javaHeapMB = (Gdx.app?.javaHeap ?: (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory())) / (1024 * 1024)
        val nativeHeapMB = (Gdx.app?.nativeHeap ?: 0L) / (1024 * 1024)
        val memMaxMB = Runtime.getRuntime().maxMemory() / (1024 * 1024)
        val drawCalls = batch.renderCalls
        val screenRes = if (Gdx.graphics != null) "${Gdx.graphics.width}x${Gdx.graphics.height}" else "1280x720"

        regF.color = if (fps >= 55) Color.GREEN else if (fps >= 30) Color.YELLOW else Color.RED
        regF.draw(batch, "FPS: $fps (${deltaMs}ms) | Disp: $screenRes | Batch Calls: $drawCalls", 250f, 570f)

        regF.color = Color.WHITE
        regF.draw(batch, "Mem: Java ${javaHeapMB}MB / Nat ${nativeHeapMB}MB (Max ${memMaxMB}MB) | Speed: ${timeScale}x ${if (isPaused) "[PAUSED]" else ""}", 250f, 545f)

        val enemyCount = currentFloor.enemies.count { !it.health.isDead }
        val projCount = currentFloor.enemies.sumOf { it.projectiles.size } + (currentFloor.boss?.projectiles?.size ?: 0)
        regF.setColor(0.85f, 0.85f, 0.85f, 1f)
        regF.draw(batch, "World: F${currentFloor.floorNumber} (${currentFloor.floorName}) | Mobs: $enemyCount | Proj: $projCount | Hero: ${player.archetype.name} (Lv.${player.stats.level})", 250f, 520f)

        // Teks Tab Header
        renderButtonText(batch, regF, tabBtnCheats, "[1] CHEATS & SPEED", if (currentTab == DevTab.CHEATS) Color.CYAN else Color.LIGHT_GRAY)
        renderButtonText(batch, regF, tabBtnWarp, "[2] WARP & SPAWN", if (currentTab == DevTab.WARP_SPAWN) Color.CORAL else Color.LIGHT_GRAY)
        renderButtonText(batch, regF, tabBtnAudit, "[3] PROFILER & AUDIT", if (currentTab == DevTab.PROFILER_AUDIT) Color.CHARTREUSE else Color.LIGHT_GRAY)
        renderButtonText(batch, regF, tabBtnCli, "[4] CONSOLE CLI", if (currentTab == DevTab.CLI_CONSOLE) Color.GOLD else Color.LIGHT_GRAY)

        // Teks Sesuai Tab Aktif
        when (currentTab) {
            DevTab.CHEATS -> {
                renderButtonText(batch, regF, btnGodMode, if (isGodMode) "GOD MODE: ON" else "GOD MODE: OFF")
                renderButtonText(batch, regF, btnInfEnergy, if (isInfiniteEnergy) "INF ENERGY: ON" else "INF ENERGY: OFF")
                renderButtonText(batch, regF, btnHitboxes, if (showHitboxes) "HITBOXES: ON" else "HITBOXES: OFF")
                renderButtonText(batch, regF, btnHeal, "+ HEAL FULL HP")

                renderButtonText(batch, regF, btnGrantGold, "+ 1000 GOLD")
                renderButtonText(batch, regF, btnGrantLevel, "+ 1 LEVEL UP")
                renderButtonText(batch, regF, btnKillEnemies, "KILL ALL MOBS")
                renderButtonText(batch, regF, btnCycleHero, "HERO: ${player.archetype.name}")

                regF.setColor(0.3f, 0.8f, 1.0f, 1f)
                regF.draw(batch, "Physics Timescale & Frame-Step Simulator:", 250f, 290f)

                renderButtonText(batch, regF, btnSpeed01, "0.1x SLOW")
                renderButtonText(batch, regF, btnSpeed05, "0.5x HALF")
                renderButtonText(batch, regF, btnSpeed10, "1.0x NORMAL")
                renderButtonText(batch, regF, btnSpeed20, "2.0x FAST")
                renderButtonText(batch, regF, btnPauseToggle, if (isPaused) "▶ RESUME" else "⏸ PAUSE")
                renderButtonText(batch, regF, btnStepFrame, "⏭ STEP 1F")

                regF.setColor(0.6f, 0.6f, 0.6f, 1f)
                regF.draw(batch, "Status: Timescale=${timeScale}x | Paused=$isPaused | Hero: ${player.archetype.characterName}", 250f, 180f)
            }
            DevTab.WARP_SPAWN -> {
                regF.setColor(0.9f, 0.7f, 0.3f, 1f)
                regF.draw(batch, "5 Saga Zenith Floor Warper (50 Floors):", 250f, 435f)

                renderButtonText(batch, regF, btnWarpF1, "F1 INTRO")
                renderButtonText(batch, regF, btnWarpF10, "F10 ZEPHYR")
                renderButtonText(batch, regF, btnWarpF20, "F20 GORGON")
                renderButtonText(batch, regF, btnWarpF30, "F30 MIRROR")
                renderButtonText(batch, regF, btnWarpF40, "F40 TRIAD")
                renderButtonText(batch, regF, btnWarpF50, "F50 ZENITH")

                regF.setColor(0.7f, 0.7f, 0.7f, 1f)
                regF.draw(batch, "Mid-Saga Checkpoints & Endless Spire:", 250f, 375f)

                renderButtonText(batch, regF, btnWarpF5, "F5 MATRON")
                renderButtonText(batch, regF, btnWarpF15, "F15 FOUNDRY")
                renderButtonText(batch, regF, btnWarpF25, "F25 BASALT")
                renderButtonText(batch, regF, btnWarpF35, "F35 ASTRAL")
                renderButtonText(batch, regF, btnWarpF45, "F45 ARCHON")
                renderButtonText(batch, regF, btnWarpEndless50, "ENDLESS 50")

                regF.setColor(0.4f, 0.8f, 1.0f, 1f)
                regF.draw(batch, "Live Enemy Spawner (Spawns at Player Position):", 250f, 290f)

                renderButtonText(batch, regF, btnSpawnMelee, "+ MELEE GRUNT")
                renderButtonText(batch, regF, btnSpawnRanged, "+ RANGED ARCHER")
                renderButtonText(batch, regF, btnSpawnFlying, "+ FLYING GARGOYLE")
                renderButtonText(batch, regF, btnSpawnShield, "+ SHIELD KNIGHT")
            }
            DevTab.PROFILER_AUDIT -> {
                renderButtonText(batch, regF, btnRunSanity, "RUN SANITY")
                renderButtonText(batch, regF, btnRunReachability, "RUN BFS REACH")
                renderButtonText(batch, regF, btnRunBalance, "SIM BALANCE")
                renderButtonText(batch, regF, btnRunAssets, "VALIDATE ASSETS")

                regF.setColor(0.3f, 0.9f, 0.4f, 1f)
                regF.draw(batch, "Audit & Diagnostic Report Output:", 250f, 340f)

                regF.setColor(0.95f, 0.95f, 0.95f, 1f)
                // Split long output to prevent screen overflow
                val lines = lastAuditSummary.split("\n").take(6)
                var lineY = 300f
                for (line in lines) {
                    regF.draw(batch, line.take(90), 250f, lineY)
                    lineY -= 24f
                }
            }
            DevTab.CLI_CONSOLE -> {
                regF.setColor(1.0f, 0.8f, 0.2f, 1f)
                regF.draw(batch, "Quick Action Commands:", 250f, 430f)

                renderButtonText(batch, regF, btnCliHelp, "help")
                renderButtonText(batch, regF, btnCliGod, "god")
                renderButtonText(batch, regF, btnCliHeal, "heal")
                renderButtonText(batch, regF, btnCliGold, "gold 5k")
                renderButtonText(batch, regF, btnCliSim, "sim 20")
                renderButtonText(batch, regF, btnCliReach, "reach")
                renderButtonText(batch, regF, btnCliUnlockAll, "★ UNLOCK ALL 50F & HEROES ★")
                renderButtonText(batch, regF, btnCliReset, "⚠ RESET ONBOARDING ⚠")

                regF.setColor(0.3f, 0.8f, 1.0f, 1f)
                regF.draw(batch, "Recent Console Log:", 250f, 320f)

                regF.setColor(0.85f, 0.85f, 0.85f, 1f)
                val logs = dispatcher.consoleLog.takeLast(6)
                var yPos = 295f
                for (l in logs) {
                    regF.draw(batch, l.take(85), 250f, yPos)
                    yPos -= 22f
                }
            }
        }

        regF.setColor(0.5f, 0.5f, 0.5f, 1f)
        regF.draw(batch, "Tip: Tekan F1/F3/~ pada keyboard untuk buka/tutup console. Sentuh tab untuk navigasi.", 250f, 120f)

        batch.end()
    }

    private fun renderTabHeader(shapeRenderer: ShapeRenderer, tab: Rectangle, isActive: Boolean, activeColor: Color) {
        if (isActive) {
            shapeRenderer.color = activeColor
            shapeRenderer.rect(tab.x, tab.y, tab.width, tab.height)
        } else {
            shapeRenderer.setColor(0.12f, 0.16f, 0.22f, 0.9f)
            shapeRenderer.rect(tab.x, tab.y, tab.width, tab.height)
        }
        shapeRenderer.setColor(0.3f, 0.4f, 0.5f, 0.5f)
        shapeRenderer.rectLine(tab.x, tab.y, tab.x + tab.width, tab.y, 1f)
    }

    private fun renderButtonShape(shapeRenderer: ShapeRenderer, btn: Rectangle, color: Color) {
        shapeRenderer.color = color
        shapeRenderer.rect(btn.x, btn.y, btn.width, btn.height)
        shapeRenderer.setColor(0.9f, 0.9f, 0.9f, 0.5f)
        shapeRenderer.rectLine(btn.x, btn.y, btn.x + btn.width, btn.y, 1f)
    }

    private fun renderButtonText(batch: SpriteBatch, font: BitmapFont, btn: Rectangle, text: String, color: Color = Color.WHITE) {
        font.color = color
        font.draw(batch, text, btn.x + 8f, btn.y + btn.height / 2f + 5f)
    }
}
