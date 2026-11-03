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
import com.badlogic.gdx.math.Vector2
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.bounty.BountyAffix
import com.stickman.tower.bounty.BountyManager
import com.stickman.tower.challenge.ChallengeManager
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.CharacterUnlockManager
import com.stickman.tower.character.Player
import com.stickman.tower.combat.ComboStep
import com.stickman.tower.combat.FloatingText
import com.stickman.tower.combat.HitStopManager
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossType
import com.stickman.tower.enemy.CombatDirector
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.endless.FloorMutator
import com.stickman.tower.input.CompositeInput
import com.stickman.tower.input.GameInput
import com.stickman.tower.input.KeyboardInput
import com.stickman.tower.input.TouchSettingsManager
import com.stickman.tower.input.VirtualController
import com.stickman.tower.leaderboard.LeaderboardEntry
import com.stickman.tower.leaderboard.LeaderboardManager
import com.stickman.tower.quest.ObjectiveType
import com.stickman.tower.quest.QuestCompassWidget
import com.stickman.tower.quest.QuestManager
import com.stickman.tower.relic.RelicManager
import com.stickman.tower.relic.RelicType
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.talent.TalentManager
import com.stickman.tower.ui.FontManager
import com.stickman.tower.vfx.ParticleManager
import com.badlogic.gdx.utils.Align
import com.stickman.tower.world.CameraManager
import com.stickman.tower.tools.DevToolsOverlay
import com.stickman.tower.world.LoreTablet
import com.stickman.tower.world.StoryDialogue
import com.stickman.tower.world.MoraleBuffType
import com.stickman.tower.narrative.TowerWhisperManager
import com.stickman.tower.world.TowerFloor
import com.stickman.tower.bestiary.BestiaryManager
import com.stickman.tower.companion.FamiliarType
import com.stickman.tower.companion.InkFamiliar
import com.stickman.tower.rune.RuneManager
import com.stickman.tower.rune.RuneType
import com.stickman.tower.world.BloodAltar
import com.stickman.tower.world.TemporalPact
import com.stickman.tower.bossrush.BossRushManager
import com.stickman.tower.bossrush.BossRushRank
import com.stickman.tower.character.ZephyrCoopAlly
import com.stickman.tower.character.GorgonCoopAlly
import com.stickman.tower.world.RunicBarrier
import com.stickman.tower.world.RunicKey
import com.stickman.tower.world.ZephyrCocoon
import com.stickman.tower.world.TitanPillar
import kotlin.math.abs
import com.stickman.tower.world.TowerLevelBuilder
import com.stickman.tower.world.ProceduralBackgroundRenderer
import kotlin.math.sin

enum class GameMode {
    STORY,
    ENDLESS,
    BOSS_RUSH
}

/**
 * Screen gameplay utama:
 * Memisahkan World Camera (16x9m physics) dan Screen UI Viewport (1280x720px)
 * untuk menjamin HUD dan Virtual Controller terkunci pixel-perfect di segala resolusi.
 * Mendukung Story Mode (Lantai 1-3) dan Endless Spire Mode (Lantai 4 ke atas).
 */
class PlayScreen(
    private val game: StickmanGame? = null,
    val initialFloor: Int = 1,
    var gameMode: GameMode = GameMode.STORY
) : Screen {
    companion object {
        val COLOR_MIASMA = Color(0.7f, 0.2f, 0.9f, 1f)
        val COLOR_SKILL_DMG = Color(0.9f, 0.4f, 1f, 1f)
        val COLOR_ENEMY_DMG = Color(1f, 0.25f, 0.25f, 1f)
        val COLOR_CRIT_DMG = Color(1f, 0.35f, 0.35f, 1f)
        val COLOR_PURPLE_SPARK = Color(0.85f, 0.35f, 1f, 1f)
        val COLOR_PURPLE_DMG = Color(0.9f, 0.3f, 1f, 1f)
    }

    private val cameraManager = CameraManager()
    private val backgroundRenderer = ProceduralBackgroundRenderer()
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()

    // Dedicated UI Viewport Pass (Pixel-Perfect 1280x720 Screen Space)
    private val uiCamera = OrthographicCamera()
    private val uiViewport = FitViewport(1280f, 720f, uiCamera)
    private val uiTouchVec = Vector3()
    private val glyphLayout = GlyphLayout()

    // Dual Input Layer: Keyboard Desktop + Virtual Controller Mobile Touch
    private val keyboardInput = KeyboardInput()
    val virtualController = VirtualController()
    private val input = CompositeInput(keyboardInput, virtualController)
    private val noInput = object : GameInput {
        override fun isMoveLeft(): Boolean = false
        override fun isMoveRight(): Boolean = false
        override fun isJumpJustPressed(): Boolean = false
        override fun isJumpPressed(): Boolean = false
        override fun isAttackJustPressed(): Boolean = false
        override fun isDodgeJustPressed(): Boolean = false
        override fun isSkillJustPressed(): Boolean = false
        override fun isUltimateJustPressed(): Boolean = false
    }

    // Data Progresi RPG & Karakter Pemain (Sesuai Arketipe Tersimpan)
    private val saveData = SaveManager.load()
    private val stats = CharacterStats().apply { loadFromSaveData(saveData) }
    private val archetype = CharacterArchetype.fromString(saveData.selectedArchetype)
    private val player = Player(spawnX = -1f, spawnY = 1.5f, stats = stats, archetype = archetype)

    // Manajer Partikel VFX
    val particleManager = ParticleManager()

    // Sistem Pendamping Roh Tinta (Fase 21)
    val inkFamiliar = InkFamiliar(FamiliarType.fromString(saveData.selectedFamiliar))

    // Manajer Relik Pasif (Fase 10) & Talent Tree (Fase 13)
    val relicManager = RelicManager()
    val talentManager = TalentManager().apply { loadFromSave(saveData) }
    var isChoosingRelic: Boolean = false
    var relicOffer: List<RelicType> = emptyList()
    var relicSelectedIndex: Int = 0

    // Parameter Endless Spire & Mutator (Fase 13)
    var activeMutator: FloorMutator = FloorMutator.NONE
    private var miasmaTimer = 0f
    var endlessSurvivalTime = 0f
    var endlessEnemiesKilled = 0

    // Sistem Pause Menu & Developer QA Tools
    var isPaused: Boolean = false
    private var pauseSelectedIndex: Int = 0
    private val pauseMenuItems = listOf("RESUME", "RESTART FLOOR", "BLACKSMITH FORGE", "TALENT TREE", "BESTIARIUM", "ROH PENDAMPING", "CONTROL SETTINGS", "AUDIO: ON", "HAPTIC: ON", "DEVELOPER TOOLS", "MAIN MENU")
    val devTools = DevToolsOverlay()
    private var wasThreeFingerTouched: Boolean = false

    // Sistem Bestiarium Lapangan (Fase 19)
    var isViewingBestiary: Boolean = false
    var bestiarySelectedIndex: Int = 0

    // Post-Processing VFX & Audio Master (Fase 20 & Engine 10/10)
    var floorTransitionAlpha: Float = 1.0f
    var parryFlashTimer: Float = 0f
    private var dangerPulseTimer: Float = 0f
    private var screenFlashTimer: Float = 0f
    private var screenFlashDuration: Float = 0f
    private var screenFlashR: Float = 1f
    private var screenFlashG: Float = 1f
    private var screenFlashB: Float = 1f
    private var screenFlashMaxAlpha: Float = 0.45f

    fun triggerScreenFlash(r: Float, g: Float, b: Float, duration: Float = 0.22f, maxAlpha: Float = 0.45f) {
        screenFlashR = r
        screenFlashG = g
        screenFlashB = b
        screenFlashDuration = duration
        screenFlashTimer = duration
        screenFlashMaxAlpha = maxAlpha
    }

    // Sistem Altar Pengorbanan Darah & Pakta Temporal (Fase 22)
    var isInteractingWithAltar: Boolean = false
    var altarSelectedIndex: Int = 0
    var activeTemporalPact: TemporalPact = TemporalPact.NONE

    // Mode Boss Rush (Gauntlet of Sovereigns) (Fase 23)
    var bossRushStage: Int = 1
    var bossRushTimer: Float = 0f
    var bossRushTransitionTimer: Float = 0f

    // Tag-Team Co-op Ally System (Fase 25 & 26)
    var zephyrCoopAlly: ZephyrCoopAlly? = null
    var gorgonCoopAlly: GorgonCoopAlly? = null

    // Data Lantai Menara Aktif
    var currentFloorNumber: Int = 1
        private set
    private lateinit var currentFloor: TowerFloor

    private val floatingTexts = mutableListOf<FloatingText>()
    private val hitStopManager = HitStopManager()
    private val activeCheckpointPos = Vector2(-1f, 1.5f)

    // Status Game Loop & Notifikasi Save
    var gameStatus: GameStatus = GameStatus.PLAYING
        private set

    private var saveNotificationTimer = 0f
    private var saveNotificationText = ""
    private var hasSavedStageClear = false
    private var showDebugBounds = false

    // Ghost Health Bar (Lag Bar untuk visual impact saat terkena damage)
    private var playerGhostHp: Float = player.health.currentHp
    private var playerGhostDelay: Float = 0f
    private var bossGhostHp: Float = 0f
    private var bossGhostDelay: Float = 0f

    // Micro-animasi HUD Juice
    private var prevComboStep: ComboStep = ComboStep.HIT_1
    private var comboPopTimer: Float = 0f
    private var hudAnimTime: Float = 0f

    // Boss Presentation & Sinematik (Fase 11)
    var isBossIntroActive: Boolean = false
    var bossIntroTimer: Float = 0f
    var bossHpBarAnimated: Float = 0f
    var hasPlayedBossIntro: Boolean = false
    var lastBossIntroFloor: Int = -1

    // Slow Motion Super Finish & Shockwave (Fase 11)
    var bossSlowMoTimer: Float = 0f
    var isBossShockwaveActive: Boolean = false
    var shockwaveRadius: Float = 0f
    var shockwaveCenterX: Float = 0f
    var shockwaveCenterY: Float = 0f
    private var bossSlowMoTriggered: Boolean = false
    private var isFirstShow = true
    private var inputCooldown = 0.25f

    // Story Odyssey Presentation & Dialogues (Fase 14)
    var actBannerTimer: Float = 0f
    var activeLoreTablet: LoreTablet? = null
    var activeStoryDialogue: StoryDialogue? = null
    var nearbyTabletPrompt: LoreTablet? = null
    var nearbyDialoguePrompt: StoryDialogue? = null
    var nearbyAltarPrompt: Boolean = false
    var nearbyPrismPrompt: Boolean = false

    // Engine Dialog Dinamis & Naskah Sinematik (Fase 18)
    var activeMoraleBuff: MoraleBuffType = MoraleBuffType.NONE
    val towerWhisperManager = TowerWhisperManager()

    // Sistem Pencapaian & Trofi (Fase 15)
    private var activeAchievementBanner: com.stickman.tower.achievement.Achievement? = null
    private var achievementBannerTimer: Float = 0f

    // Sistem Quest & The Heritage Saga (Fase 16)
    private val questCompass = QuestCompassWidget()

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        AudioManager.init()
        HapticManager.init()
        FontManager.init()
        inputCooldown = 0.25f
        val freshSave = SaveManager.load()
        stats.loadFromSaveData(freshSave)
        com.stickman.tower.achievement.AchievementManager.loadFromSave(freshSave)
        QuestManager.initFromSave(freshSave)
        if (Gdx.graphics != null && Gdx.graphics.width > 0 && Gdx.graphics.height > 0) {
            uiViewport.update(Gdx.graphics.width, Gdx.graphics.height, true)
        }
        virtualController.applySettings(TouchSettingsManager.load(), 1280, 720)

        // Hubungkan Callback Partikel VFX Pemain
        player.onLand = { x, y -> particleManager.spawnDust(x, y, count = 6) }
        player.onJump = { x, y -> particleManager.spawnDust(x, y, count = 5) }
        player.onDodge = { x, y -> particleManager.spawnDust(x, y, count = 8) }

        // Hubungkan Callback DevTools QA & Profiler
        devTools.onWarpFloor = { targetFloor ->
            gameMode = if (targetFloor >= 11) GameMode.ENDLESS else GameMode.STORY
            loadFloor(targetFloor)
            floatingTexts.add(
                FloatingText("WARPED TO FLOOR $targetFloor", player.position.x, player.position.y + 2.5f, Color.CYAN)
            )
        }
        devTools.onGrantGold = { amount ->
            player.stats.addGold(amount)
            floatingTexts.add(
                FloatingText("+$amount GOLD [DEV CHEAT]", player.position.x, player.position.y + 2.5f, Color.GOLD)
            )
        }
        devTools.onGrantLevel = {
            grantRewards(player.stats.requiredExp - player.stats.currentExp, 0, player.position.x, player.position.y + 1f)
        }
        devTools.onHealFull = {
            player.health.heal(player.health.maxHp)
            floatingTexts.add(
                FloatingText("FULL HEAL [DEV]", player.position.x, player.position.y + 2.5f, Color.GREEN)
            )
        }
        devTools.onKillAllEnemies = {
            for (enemy in currentFloor.allEnemies) {
                if (!enemy.health.isDead) {
                    enemy.health.takeDamage(enemy.health.currentHp)
                }
            }
            val b = currentFloor.boss
            if (b != null && !b.health.isDead) {
                b.health.takeDamage(b.health.currentHp)
            }
            floatingTexts.add(
                FloatingText("ALL MOBS ELIMINATED [DEV]", player.position.x, player.position.y + 2.5f, Color.RED)
            )
        }
        devTools.onSwitchArchetype = { arch ->
            player.switchArchetype(arch)
            floatingTexts.add(
                FloatingText("HERO SWAPPED: ${arch.name} [DEV]", player.position.x, player.position.y + 2.5f, Color.MAGENTA)
            )
        }
        devTools.onSpawnEnemy = { enemyType ->
            val spawnX = player.position.x + if (player.facingRight) 3.5f else -3.5f
            val spawnY = player.position.y
            val newEnemy = com.stickman.tower.enemy.Enemy(spawnX, spawnY, enemyType)
            currentFloor.dynamicEnemies.add(newEnemy)
            particleManager.spawnHitSparks(spawnX, spawnY + 1f, count = 15, color = Color.PURPLE)
            floatingTexts.add(
                FloatingText("+ SPAWNED ${enemyType.name} [DEV]", spawnX, spawnY + 2.0f, Color.ORANGE)
            )
        }
        devTools.dispatcher.getCurrentFloor = { currentFloor }
        devTools.dispatcher.onWarpBossRushStage = { stage ->
            gameMode = GameMode.BOSS_RUSH
            bossRushStage = stage
            bossRushTimer = 0f
            bossRushTransitionTimer = 0f
            val targetFloor = when (stage) {
                1 -> 3
                2 -> 5
                3 -> 8
                4 -> 9
                else -> 10
            }
            loadFloor(targetFloor)
            player.respawn(currentFloor.spawnX, currentFloor.spawnY)
            gameStatus = GameStatus.PLAYING
            floatingTexts.add(FloatingText("DEV WARP: GAUNTLET TAHAP $stage", player.position.x, player.position.y + 2.5f, Color.GOLD))
        }
        devTools.dispatcher.onSetBossRushTimer = { timeSec ->
            bossRushTimer = timeSec
            floatingTexts.add(FloatingText("DEV: BOSS RUSH TIMER = ${timeSec}s", player.position.x, player.position.y + 2.5f, Color.CYAN))
        }
        devTools.dispatcher.onUnlockAllTitles = {
            for (title in com.stickman.tower.bossrush.BossRushManager.ALL_TITLES) {
                if (!saveData.unlockedTitles.contains(title.id)) {
                    saveData.unlockedTitles.add(title.id)
                }
            }
            com.stickman.tower.rpg.SaveManager.saveAsync(saveData)
            floatingTexts.add(FloatingText("DEV: ALL TITLES UNLOCKED", player.position.x, player.position.y + 2.5f, Color.GOLD))
        }
        devTools.dispatcher.onUnlockAllContent = {
            saveData.highestTowerFloor = 50
            saveData.highestEndlessFloor = 50
            saveData.playerLevel = 80
            saveData.gold = 999999
            saveData.isZephyrRescued = true
            saveData.isGorgonRescued = true
            if (!saveData.unlockedCharacters.contains("STICKMAN_DAGGER")) saveData.unlockedCharacters.add("STICKMAN_DAGGER")
            if (!saveData.unlockedCharacters.contains("STICKMAN_AXE")) saveData.unlockedCharacters.add("STICKMAN_AXE")
            for (i in 1..50) {
                val tabId = "TABLET_$i"
                if (!saveData.unlockedLoreTablets.contains(tabId)) saveData.unlockedLoreTablets.add(tabId)
            }
            saveData.sanitize()
            saveData.updateChecksum()
            com.stickman.tower.rpg.SaveManager.saveAsync(saveData)
            floatingTexts.add(FloatingText("DEV: ALL CONTENT UNLOCKED (50F & HEROES)", player.position.x, player.position.y + 2.5f, Color.GOLD))
        }
        devTools.dispatcher.onResetSave = {
            saveData.resetToDefaults()
            saveData.updateChecksum()
            com.stickman.tower.rpg.SaveManager.saveAsync(saveData)
            floatingTexts.add(FloatingText("DEV: SAVE DATA RESET TO DEFAULT", player.position.x, player.position.y + 2.5f, Color.RED))
        }

        if (isFirstShow) {
            isFirstShow = false
            loadFloor(initialFloor)
        }
    }

    /**
     * Memuat layout lantai menara tertentu (Story 1-3 atau Endless 4+).
     */
    fun loadFloor(floorNumber: Int) {
        CombatDirector.reset()
        currentFloorNumber = if (gameMode == GameMode.ENDLESS) floorNumber.coerceAtLeast(11) else floorNumber.coerceIn(1, SaveData.MAX_STORY_FLOORS)
        activeMutator = if (gameMode == GameMode.ENDLESS) FloorMutator.getRandomMutator(currentFloorNumber) else FloorMutator.NONE
        currentFloor = if (gameMode == GameMode.ENDLESS) TowerLevelBuilder.buildEndlessFloor(currentFloorNumber, activeMutator) else TowerLevelBuilder.buildFloor(currentFloorNumber)

        cameraManager.setBounds(
            left = currentFloor.mapBounds.x,
            bottom = currentFloor.mapBounds.y,
            right = currentFloor.mapBounds.x + currentFloor.mapBounds.width,
            top = currentFloor.mapBounds.height
        )

        player.position.set(currentFloor.spawnX, currentFloor.spawnY)
        player.velocity.set(0f, 0f)
        player.maxAirJumps = relicManager.getMaxAirJumps()
        player.airJumpsRemaining = player.maxAirJumps
        player.stats.runeAtkBonus = RuneManager.calculateBonusAtk(saveData)
        player.stats.runeCritBonus = RuneManager.calculateCritRateBonus(saveData)
        activeTemporalPact = TemporalPact.NONE
        isInteractingWithAltar = false
        refreshPlayerModifiers()
        player.hasSuperArmor = talentManager.hasSuperArmor()
        player.hasUndyingWill = talentManager.hasUndyingWill()
        player.undyingWillUsed = false
        activeCheckpointPos.set(currentFloor.spawnX, currentFloor.spawnY)
        inkFamiliar.resetPosition(player.position.x, player.position.y)

        hasSavedStageClear = false
        gameStatus = GameStatus.PLAYING

        playerGhostHp = player.health.currentHp
        playerGhostDelay = 0f
        miasmaTimer = 0f
        bossGhostHp = currentFloor.boss?.health?.currentHp ?: 0f

        for (tablet in currentFloor.loreTablets) {
            if (saveData.unlockedLoreTablets.contains(tablet.tabletId)) {
                tablet.isRead = true
            }
        }
        bossGhostDelay = 0f
        prevComboStep = ComboStep.HIT_1
        comboPopTimer = 0f

        floatingTexts.clear()
        particleManager.clear()

        bossSlowMoTriggered = false
        bossSlowMoTimer = 0f
        isBossShockwaveActive = false
        shockwaveRadius = 0f

        actBannerTimer = 3.5f
        activeLoreTablet = null
        activeStoryDialogue = null
        nearbyTabletPrompt = null
        nearbyDialoguePrompt = null
        towerWhisperManager.reset()
        zephyrCoopAlly = null
        gorgonCoopAlly = null

        if (currentFloorNumber == 1) {
            activeMoraleBuff = MoraleBuffType.NONE
        } else if (currentFloorNumber == 7 && activeMoraleBuff == MoraleBuffType.SPIRITUAL_WARD) {
            val bonusHp = player.health.maxHp * 0.15f
            player.health.maxHp += bonusHp
            player.health.heal(bonusHp)
        }

        if (currentFloor.isBossFloor && lastBossIntroFloor != currentFloorNumber) {
            isBossIntroActive = true
            bossIntroTimer = if (gameMode == GameMode.BOSS_RUSH) 1.2f else 2.8f
            bossHpBarAnimated = 0f
            hasPlayedBossIntro = true
            lastBossIntroFloor = currentFloorNumber
            AudioManager.playBossRoar()
            HapticManager.vibrateHeavy()
            cameraManager.shake(0.8f, 0.6f)
        } else {
            isBossIntroActive = false
            bossIntroTimer = 0f
            bossHpBarAnimated = 1f
        }

        floatingTexts.add(
            FloatingText("=== ${currentFloor.floorName} ===", player.position.x, player.position.y + 2.5f, Color.GOLD, duration = 2.8f)
        )
        AudioManager.playFloorBgm(currentFloorNumber, currentFloor.isBossFloor)
        floorTransitionAlpha = 1.0f
    }

    private fun triggerSave(reason: String, highestFloor: Int = currentFloorNumber) {
        if (gameMode == GameMode.STORY) {
            val saveFloor = kotlin.math.max(saveData.highestTowerFloor, highestFloor)
            saveData.highestTowerFloor = saveFloor
        } else if (gameMode == GameMode.ENDLESS) {
            saveData.highestEndlessFloor = kotlin.math.max(saveData.highestEndlessFloor, highestFloor)
        }
        saveData.totalEnemiesDefeated += endlessEnemiesKilled
        saveData.selectedArchetype = archetype.name
        QuestManager.saveTo(saveData)
        val updatedSave = player.stats.applyToSaveData(saveData)
        SaveManager.save(updatedSave)
        saveNotificationText = "Progress Tersimpan ($reason)"
        saveNotificationTimer = 2.5f
    }

    fun refreshPlayerModifiers() {
        val runeCdr = RuneManager.calculateCooldownReduction(saveData)
        val runeDmgRed = RuneManager.calculateDamageReduction(saveData)
        val pactCdr = if (activeTemporalPact == TemporalPact.SWIFTNESS) 0.35f else 0f
        val effectiveCdr = (runeCdr + pactCdr).coerceIn(0f, 0.75f)
        player.cooldownMultiplier = relicManager.getCooldownMultiplier() * talentManager.getCooldownMultiplier() * (1f - effectiveCdr)
        player.gravityScale = currentFloor.gravityScale * activeMutator.gravityMultiplier
        val pactDmgMultiplier = if (activeTemporalPact == TemporalPact.CARNAGE) 1.15f else 1.0f
        player.damageReductionMultiplier = talentManager.getDamageReductionMultiplier() * (1f - runeDmgRed) * pactDmgMultiplier
    }

    private fun grantRewards(exp: Int, gold: Int, x: Float, y: Float) {
        var goldMultiplier = 1.0f
        if (inkFamiliar.type == FamiliarType.ARIA_WISP) goldMultiplier += 0.20f
        if (activeTemporalPact == TemporalPact.GREED) goldMultiplier += 0.60f
        val finalGold = (gold * goldMultiplier).toInt()
        player.stats.addGold(finalGold)
        floatingTexts.add(FloatingText("+$finalGold G", x + 0.35f, y, Color.YELLOW, duration = 1.2f))
        if (inkFamiliar.type == FamiliarType.ARIA_WISP && goldMultiplier > 1.0f) {
            val bonusGold = (gold * 0.20f).toInt()
            floatingTexts.add(FloatingText("✨ LENTERA ARIA (+$bonusGold G) ✨", x, y + 0.65f, Color.CYAN, duration = 1.3f))
        }
        if (activeTemporalPact == TemporalPact.GREED) {
            val greedBonus = (gold * 0.60f).toInt()
            floatingTexts.add(FloatingText("🩸 PAKTA GREED (+$greedBonus G) 🩸", x, y + 0.95f, Color.GOLD, duration = 1.4f))
        }

        val levelsGained = player.stats.addExp(exp)
        floatingTexts.add(FloatingText("+$exp EXP", x - 0.35f, y + 0.45f, Color.CYAN, duration = 1.2f))

        if (levelsGained > 0) {
            player.onLevelUp(levelsGained)
            if (saveData.unspentTalentPoints >= 0) {
                val oldPts = (player.stats.level - levelsGained) / 2
                val newPts = player.stats.level / 2
                val ptsToAdd = newPts - oldPts
                if (ptsToAdd > 0) {
                    saveData.unspentTalentPoints += ptsToAdd
                    floatingTexts.add(
                        FloatingText("✦ +$ptsToAdd TALENT POINT ✦", player.position.x, player.position.y + 3.2f, Color.GOLD, duration = 2.4f)
                    )
                }
            }
            AudioManager.playLevelUp()
            particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height, count = 25, color = Color.CYAN)
            floatingTexts.add(
                FloatingText("★ LEVEL UP! Lv.${player.stats.level} ★", player.position.x, player.position.y + 2.5f, Color.ORANGE, duration = 2.4f)
            )
            triggerSave("Level Up Lv.${player.stats.level}")
        }
    }

    override fun render(delta: Float) {
        val isThreeFingerPressed = Gdx.input.isTouched(2)
        val justThreeFingerTapped = isThreeFingerPressed && !wasThreeFingerTouched
        wasThreeFingerTouched = isThreeFingerPressed

        // Hotkey DevTools Console & Profiler (F1/F3/~ dan 3-Finger Tap Mobile) dan Bounding Boxes (TAB)
        if (Gdx.input.isKeyJustPressed(Keys.F1) || Gdx.input.isKeyJustPressed(Keys.F3) || Gdx.input.isKeyJustPressed(Keys.GRAVE) || justThreeFingerTapped) {
            devTools.toggle()
            if (devTools.isVisible) AudioManager.playSlashLight()
        }
        if (Gdx.input.isKeyJustPressed(Keys.TAB)) {
            showDebugBounds = !showDebugBounds
        }

        // Sinkronisasi status QA Cheats ke Player
        player.isGodMode = devTools.isGodMode
        if (devTools.isInfiniteEnergy) {
            player.skill1.reset()
            player.ultimate.addEnergy(player.ultimate.maxEnergy)
        }

        // 1. Polling input controller di awal frame (hanya saat gameplay aktif, cegah kebocoran sentuhan ke modal)
        if (!devTools.isVisible && !isPaused && !isViewingBestiary) {
            input.update(uiViewport)
        }

        val baseDelta = delta.coerceAtMost(1f / 30f)
        val safeDelta = if (devTools.isPaused) {
            if (devTools.consumeStep()) 1f / 60f else 0f
        } else {
            (baseDelta * devTools.timeScale).coerceAtMost(0.2f)
        }
        if (inputCooldown > 0f) {
            inputCooldown = (inputCooldown - (if (safeDelta > 0f) safeDelta else baseDelta)).coerceAtLeast(0f)
        }

        // Toggle Pause dengan ESC, P, Tombol Android BACK, atau Gamepad START
        val isBackTriggered = Gdx.input.isKeyJustPressed(Keys.ESCAPE) ||
                              Gdx.input.isKeyJustPressed(Keys.P) ||
                              Gdx.input.isKeyJustPressed(Keys.BACK) ||
                              input.isPauseJustPressed()

        // Shortcut Langsung Bestiarium Lapangan (Fase 19)
        if (inputCooldown <= 0f && Gdx.input.isKeyJustPressed(Keys.B)) {
            isViewingBestiary = !isViewingBestiary
            bestiarySelectedIndex = 0
            AudioManager.playSlashLight()
            inputCooldown = 0.20f
        }

        if (inputCooldown <= 0f) {
            if (isBackTriggered) {
                if (gameStatus == GameStatus.PLAYING && !isPaused) {
                    isPaused = true
                    pauseSelectedIndex = 0
                    AudioManager.playDodge()
                    AudioManager.pauseBgm()
                    inputCooldown = 0.20f
                } else if (isPaused) {
                    isPaused = false
                    AudioManager.resumeBgm()
                    AudioManager.playSlashLight()
                    inputCooldown = 0.20f
                } else if (gameStatus == GameStatus.GAME_OVER || gameStatus == GameStatus.STAGE_CLEAR) {
                    AudioManager.playDodge()
                    if (game != null) {
                        (game as? StickmanGame)?.releasePreservedScreen(this)
                        game.setScreen(MainMenuScreen(game))
                    }
                    return
                }
            }

            // Cek klik tombol Pause di pojok kanan atas HUD (Toleransi area sentuh luas & aman dari notch layar HP)
            if (Gdx.input.justTouched() && (gameStatus == GameStatus.PLAYING || isPaused)) {
                uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                uiViewport.unproject(uiTouchVec)
                if (uiTouchVec.x in (1280f - 180f)..1280f && uiTouchVec.y in (720f - 75f)..720f) {
                    isPaused = !isPaused
                    pauseSelectedIndex = 0
                    if (isPaused) {
                        AudioManager.playDodge()
                        AudioManager.pauseBgm()
                    } else {
                        AudioManager.playSlashLight()
                        AudioManager.resumeBgm()
                    }
                    inputCooldown = 0.20f
                } else if (gameStatus == GameStatus.PLAYING && !isPaused && gameMode == GameMode.STORY && questCompass.contains(uiTouchVec.x, uiTouchVec.y)) {
                    AudioManager.playSlashLight()
                    (game as? StickmanGame)?.preserveScreen(this)
                    game?.setScreen(QuestLogScreen(game, player.stats, this))
                    return
                }
            }

            // Pintasan Keyboard [J] untuk membuka Quest Log
            if (Gdx.input.isKeyJustPressed(Keys.J) && gameStatus == GameStatus.PLAYING && !isPaused) {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game?.setScreen(QuestLogScreen(game, player.stats, this))
                return
            }

            // Pintasan Keyboard [G] untuk membuka Monolit Ujian & Papan Buronan
            if (Gdx.input.isKeyJustPressed(Keys.G) && gameStatus == GameStatus.PLAYING && !isPaused) {
                AudioManager.playSlashLight()
                (game as? StickmanGame)?.preserveScreen(this)
                game?.setScreen(GauntletScreen(game, player.stats, this))
                return
            }
        }

        if (devTools.isVisible) {
            handleDevToolsInput()
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderHUD()
            devTools.render(shapeRenderer, batch, uiCamera, player, currentFloor, particleManager.activeParticleCount)
            return
        }

        if (isViewingBestiary) {
            handleBestiaryInput()
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderBestiaryOverlay()
            return
        }

        if (isPaused) {
            handlePauseInput()
            if (game != null && game.screen !== this) return
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderHUD()
            renderPauseOverlay()
            return
        }

        if (isChoosingRelic) {
            handleRelicChoiceInput()
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderHUD()
            renderRelicChoiceOverlay()
            return
        }

        if (activeLoreTablet != null) {
            handleLoreTabletInput()
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderHUD()
            renderLoreTabletOverlay()
            return
        }

        if (activeStoryDialogue != null) {
            val revealedNewChar = activeStoryDialogue?.updateTypewriter(delta) ?: false
            if (revealedNewChar) {
                activeStoryDialogue?.currentLine?.let { AudioManager.playVoiceChirp(it.speaker) }
            }
            handleStoryDialogueInput()
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderHUD()
            renderStoryDialogueOverlay()
            return
        }

        if (isInteractingWithAltar) {
            handleBloodAltarInput()
            renderWorld(0f)
            uiViewport.apply()
            shapeRenderer.projectionMatrix = uiCamera.combined
            batch.projectionMatrix = uiCamera.combined
            renderHUD()
            renderBloodAltarOverlay()
            return
        }

        // Pembaruan Sinematik Boss Intro (Fase 11)
        if (isBossIntroActive) {
            if (Gdx.input.isKeyJustPressed(Keys.SPACE) || Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.justTouched()) {
                isBossIntroActive = false
                bossIntroTimer = 0f
                bossHpBarAnimated = 1f
            } else {
                bossIntroTimer = (bossIntroTimer - safeDelta).coerceAtLeast(0f)
                bossHpBarAnimated = (1f - (bossIntroTimer / 2.8f)).coerceIn(0f, 1f)
                if (bossIntroTimer <= 0f) {
                    isBossIntroActive = false
                    bossHpBarAnimated = 1f
                }
            }
        }

        // Pembaruan Radial Shockwave & Time Dilation Super Finish (Fase 11)
        if (isBossShockwaveActive) {
            shockwaveRadius += 16f * safeDelta
            if (shockwaveRadius >= 22f) {
                isBossShockwaveActive = false
            }
        }

        val updateDelta = if (bossSlowMoTimer > 0f) {
            bossSlowMoTimer = (bossSlowMoTimer - safeDelta).coerceAtLeast(0f)
            safeDelta * 0.25f
        } else {
            safeDelta
        }

        handleStatusInput()

        hudAnimTime += safeDelta
        if (actBannerTimer > 0f) {
            actBannerTimer = (actBannerTimer - safeDelta).coerceAtLeast(0f)
        }

        // Pembaruan Ghost HP Bar Pemain (Smooth Decay Lag)
        if (playerGhostDelay > 0f) {
            playerGhostDelay = (playerGhostDelay - safeDelta).coerceAtLeast(0f)
        } else if (playerGhostHp > player.health.currentHp) {
            val decaySpeed = ((playerGhostHp - player.health.currentHp) * 4.5f + 25f) * safeDelta
            playerGhostHp = (playerGhostHp - decaySpeed).coerceAtLeast(player.health.currentHp)
        } else {
            playerGhostHp = player.health.currentHp
        }

        // Pembaruan Ghost HP Bar Boss
        val activeBoss = currentFloor.boss
        if (activeBoss != null) {
            if (bossGhostHp == 0f || bossGhostHp < activeBoss.health.currentHp) {
                bossGhostHp = activeBoss.health.currentHp
            }
            if (bossGhostDelay > 0f) {
                bossGhostDelay = (bossGhostDelay - safeDelta).coerceAtLeast(0f)
            } else if (bossGhostHp > activeBoss.health.currentHp) {
                val decaySpeed = ((bossGhostHp - activeBoss.health.currentHp) * 4f + 35f) * safeDelta
                bossGhostHp = (bossGhostHp - decaySpeed).coerceAtLeast(activeBoss.health.currentHp)
            } else {
                bossGhostHp = activeBoss.health.currentHp
            }
        }

        // Pembaruan Animasi Combo Pop
        if (player.comboManager.currentStep != prevComboStep) {
            prevComboStep = player.comboManager.currentStep
            comboPopTimer = 0.28f
        }
        if (comboPopTimer > 0f) {
            comboPopTimer = (comboPopTimer - safeDelta).coerceAtLeast(0f)
        }

        if (saveNotificationTimer > 0f) {
            saveNotificationTimer = (saveNotificationTimer - safeDelta).coerceAtLeast(0f)
        }

        // Pembaruan Antrean Notifikasi Banner Achievement (Fase 15)
        if (activeAchievementBanner == null) {
            val nextAchv = com.stickman.tower.achievement.AchievementManager.pollNotification()
            if (nextAchv != null) {
                activeAchievementBanner = nextAchv
                achievementBannerTimer = 3.8f
                if (nextAchv.goldReward > 0) {
                    player.stats.addGold(nextAchv.goldReward)
                    player.stats.applyToSaveData(saveData)
                    floatingTexts.add(
                        FloatingText("+${nextAchv.goldReward} GOLD [PRESTASI]", player.position.x, player.position.y + 2.5f, Color.GOLD, duration = 3.0f)
                    )
                }
                AudioManager.playChest()
                HapticManager.vibrateMedium()
            }
        } else {
            achievementBannerTimer -= safeDelta
            if (achievementBannerTimer <= 0f) {
                activeAchievementBanner = null
            }
        }

        // 1. Hit Stop Micro-Freeze Update
        val isFrozen = hitStopManager.update(safeDelta)

        if (!isFrozen && gameStatus == GameStatus.PLAYING) {
            // Pembaruan Pemain (abaikan input kendali jika sedang intro sinematik)
            val activeInput = if (isBossIntroActive) noInput else input
            player.update(updateDelta, activeInput, currentFloor.platforms)
            particleManager.update(updateDelta)

            // Tower Whispers Ambient Monologue (Fase 18)
            val isPlayerIdle = abs(player.velocity.x) < 0.1f && abs(player.velocity.y) < 0.1f &&
                    !player.isDodging && !player.isSkillStriking &&
                    !player.isSkill2Active && !player.isSkill3Active && !player.isUlting &&
                    !player.hitbox.isActive && !input.isMoveLeft() && !input.isMoveRight() &&
                    !input.isAttackJustPressed()
            val actNum = when (currentFloorNumber) {
                in 1..3 -> 1
                in 4..6 -> 2
                else -> 3
            }
            towerWhisperManager.update(updateDelta, isPlayerIdle, actNum)

            // Morale Surge: Spiritual Ward Regen di Lantai 7 (Fase 18)
            if (currentFloorNumber == 7 && activeMoraleBuff == MoraleBuffType.SPIRITUAL_WARD && !player.health.isDead) {
                player.health.heal(1.0f * updateDelta)
            }

            // Cek Batas Jurang / Out of Bounds (Mencegah karakter jatuh ke jurang hampa tanpa batas)
            if (player.position.y < currentFloor.mapBounds.y - 3.5f && !player.health.isDead) {
                if (devTools.isGodMode) {
                    player.position.set(currentFloor.spawnX, currentFloor.spawnY)
                    player.velocity.set(0f, 0f)
                } else {
                    player.health.takeDamage(9999f)
                }
            }

            // Cek Rintangan Duri Lantai (Spikes)
            for (spike in currentFloor.spikes) {
                if (spike.checkCollision(player.bounds) && !player.health.isInvulnerable && !player.isDodging) {
                    if (player.takeHit(spike.damage, 0f, 8.0f)) {
                        playerGhostDelay = 0.35f
                        hitStopManager.trigger(0.06f)
                        AudioManager.playHit()
                        particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 8, color = Color.RED)
                        floatingTexts.add(
                            FloatingText("-${spike.damage.toInt()}", player.position.x + player.width / 2f, player.position.y + player.height + 0.3f, Color.RED)
                        )
                    }
                }
            }

            // Cek Tabrakan Runic Barriers (Fase 25)
            for (barrier in currentFloor.runicBarriers) {
                if (!barrier.isUnlocked && player.bounds.overlaps(barrier.bounds)) {
                    if (player.bounds.x + player.bounds.width / 2f < barrier.bounds.x + barrier.bounds.width / 2f) {
                        player.position.x = barrier.bounds.x - player.width
                    } else {
                        player.position.x = barrier.bounds.x + barrier.bounds.width
                    }
                    player.velocity.x = 0f
                    particleManager.spawnHitSparks(barrier.x + barrier.width / 2f, player.position.y + player.height / 2f, count = 2, color = Color.RED)
                }
            }

            // Cek Tabrakan Titan Basalt Walls (Fase 27)
            for (wall in currentFloor.basaltWalls) {
                if (!wall.isBroken && player.bounds.overlaps(wall.bounds)) {
                    if (player.bounds.x + player.bounds.width / 2f < wall.bounds.x + wall.bounds.width / 2f) {
                        player.position.x = wall.bounds.x - player.width
                    } else {
                        player.position.x = wall.bounds.x + wall.bounds.width
                    }
                    player.velocity.x = 0f
                }
            }

            // Cek Pengambilan Runic Keys (Fase 25)
            for (key in currentFloor.runicKeys) {
                if (!key.isCollected) {
                    key.update(updateDelta)
                    val isBodyTouch = player.bounds.overlaps(key.bounds)
                    val isSwordHit = player.hitbox.isActive && player.hitbox.bounds.overlaps(key.bounds)
                    if (isBodyTouch || isSwordHit) {
                        key.isCollected = true
                        for (barrier in currentFloor.runicBarriers) {
                            if (barrier.barrierId == key.targetBarrierId) {
                                barrier.unlock()
                            }
                        }
                        AudioManager.playLevelUp()
                        particleManager.spawnHitSparks(key.x + 0.4f, key.y + 0.4f, count = 25, color = Color.GOLD)
                        floatingTexts.add(
                            FloatingText("✦ KUNCI RUNIK DITEMUKAN! SEGEL TERBUKA! ✦", key.x - 1.5f, key.y + 2.0f, Color.GOLD, duration = 3.0f)
                        )
                    }
                }
            }

            // Pembaruan Kepompong Zephyr (Fase 25) & Pilar Titan Gorgon (Fase 26)
            currentFloor.zephyrCocoon?.update(updateDelta)
            currentFloor.titanPillar?.update(updateDelta)

            // Pembaruan Zephyr Co-op Tag-Team Ally (Fase 25)
            val activeAlly = zephyrCoopAlly
            if (activeAlly != null && activeAlly.isActive) {
                if (activeAlly.onBossHit == null) {
                    activeAlly.onBossHit = { dmg, _ ->
                        val activeBoss = currentFloor.boss
                        if (activeBoss != null) {
                            particleManager.spawnHitSparks(activeBoss.position.x + activeBoss.width / 2f, activeBoss.position.y + activeBoss.height / 2f, count = 10, color = Color.CYAN)
                            floatingTexts.add(
                                FloatingText("ZEPHYR -${dmg.toInt()}", activeBoss.position.x + activeBoss.width / 2f, activeBoss.position.y + activeBoss.height + 0.3f, Color.CYAN)
                            )
                            AudioManager.playHit()
                        }
                    }
                }
                activeAlly.update(updateDelta, currentFloor.boss, player.position)
            }

            // Pembaruan Gorgon Co-op Tag-Team Ally (Fase 26)
            val activeGorgon = gorgonCoopAlly
            if (activeGorgon != null && activeGorgon.isActive) {
                if (activeGorgon.onBossHit == null) {
                    activeGorgon.onBossHit = { dmg, isSlam ->
                        val activeBoss = currentFloor.boss
                        if (activeBoss != null) {
                            particleManager.spawnHitSparks(activeBoss.position.x + activeBoss.width / 2f, activeBoss.position.y + activeBoss.height / 2f, count = if (isSlam) 24 else 12, color = Color.GOLD)
                            floatingTexts.add(
                                FloatingText(if (isSlam) "💥 GORGON SLAM -${dmg.toInt()} 💥" else "GORGON -${dmg.toInt()}", activeBoss.position.x + activeBoss.width / 2f, activeBoss.position.y + activeBoss.height + 0.3f, Color.GOLD)
                            )
                            AudioManager.playHit()
                            if (isSlam) {
                                cameraManager.shake(0.45f, 0.3f)
                            }
                        }
                    }
                }
                activeGorgon.update(updateDelta, currentFloor.boss, player.position)
            }

            // Cek Interaksi Peti Harta (Chests)
            for (chest in currentFloor.chests) {
                if (!chest.isOpened) {
                    val isSwordHit = player.hitbox.isActive && player.hitbox.bounds.overlaps(chest.bounds)
                    val isBodyTouch = player.bounds.overlaps(chest.bounds)
                    if (isSwordHit || isBodyTouch) {
                        if (chest.open()) {
                            player.stats.addGold(chest.goldReward)
                            if (activeTemporalPact == TemporalPact.SWIFTNESS) {
                                floatingTexts.add(FloatingText("⛔ HEAL TERBLOKIR PAKTA", chest.x + 0.2f, chest.y + 1.7f, Color.CYAN, duration = 1.4f))
                            } else {
                                player.health.heal(chest.healReward)
                                floatingTexts.add(FloatingText("+${chest.healReward.toInt()} HP", chest.x + 0.2f, chest.y + 1.7f, Color.GREEN, duration = 1.4f))
                            }
                            AudioManager.playChest()
                            particleManager.spawnHitSparks(chest.x + chest.width / 2f, chest.y + chest.height / 2f, count = 22, color = Color.GOLD)
                            floatingTexts.add(FloatingText("+${chest.goldReward} G", chest.x + 0.2f, chest.y + 1.2f, Color.YELLOW, duration = 1.4f))
                            if (currentFloorNumber == 2 && chest.x > 20f && relicManager.activeRelics.size < 2) {
                                triggerRelicChoice()
                            }
                            triggerSave("Peti Terbuka")
                        }
                    }
                }
            }

            // Cek Trigger Checkpoint
            if (currentFloor.checkpoint != null && currentFloor.checkpoint!!.checkTrigger(player.bounds)) {
                activeCheckpointPos.set(currentFloor.checkpoint!!.x, currentFloor.checkpoint!!.y + 0.2f)
                floatingTexts.add(
                    FloatingText("CHECKPOINT!", currentFloor.checkpoint!!.x, currentFloor.checkpoint!!.y + 2.2f, Color.CYAN, duration = 1.5f)
                )
                triggerSave("Checkpoint Lantai $currentFloorNumber")
            }

            // Pembaruan Prasasti Batu Hitam Kuno (The Lore Tablets)
            nearbyTabletPrompt = null
            for (tablet in currentFloor.loreTablets) {
                tablet.update(updateDelta)
                val dist = player.position.dst(tablet.x + tablet.width / 2f, tablet.y + tablet.height / 2f)
                if (dist < 2.0f || player.bounds.overlaps(tablet.bounds)) {
                    nearbyTabletPrompt = tablet
                    if (Gdx.input.isKeyJustPressed(Keys.E)) {
                        activeLoreTablet = tablet
                        tablet.isRead = true
                        QuestManager.notifyEvent(ObjectiveType.READ_TABLET, tablet.tabletId)
                        if (!saveData.unlockedLoreTablets.contains(tablet.tabletId)) {
                            saveData.unlockedLoreTablets.add(tablet.tabletId)
                            SaveManager.saveAsync(saveData)
                        }
                        AudioManager.playChest()
                        break
                    }
                }
            }

            // Pembaruan Interaksi Altar Pengorbanan Anima (Fase 22)
            nearbyAltarPrompt = false
            val altar = currentFloor.bloodAltar
            if (altar != null && !altar.isActivated) {
                if (altar.isPlayerNear(player.position.x, player.position.y, player.width, player.height)) {
                    nearbyAltarPrompt = true
                    if (Gdx.input.isKeyJustPressed(Keys.E) || (Gdx.input.isKeyJustPressed(Keys.ENTER) && !isPaused) || input.isAttackJustPressed()) {
                        isInteractingWithAltar = true
                        altarSelectedIndex = 0
                        AudioManager.playChest()
                    }
                }
            }

            // Pembaruan Interaksi Altar Prisma Triad Tag-Team (Fase 28)
            nearbyPrismPrompt = false
            val prismAltar = currentFloor.prismAltar
            if (prismAltar != null) {
                prismAltar.update(updateDelta)
                if (player.bounds.overlaps(prismAltar.interactionBounds)) {
                    nearbyPrismPrompt = true
                    val isTriggerPressed = Gdx.input.isKeyJustPressed(Keys.T) || (Gdx.input.isKeyJustPressed(Keys.E) && !nearbyAltarPrompt) || (player.hitbox.isActive && player.hitbox.bounds.overlaps(prismAltar.bounds))
                    if (isTriggerPressed && prismAltar.interactionCooldown <= 0f) {
                        prismAltar.interactionCooldown = 0.8f
                        val nextArchetype = prismAltar.getNextAvailableArchetype(player.archetype, saveData.unlockedCharacters)
                        if (nextArchetype != player.archetype) {
                            player.switchArchetype(nextArchetype)
                            saveData.selectedArchetype = nextArchetype.name
                            SaveManager.saveAsync(saveData)
                            AudioManager.playLevelUp()
                            particleManager.spawnHitSparks(prismAltar.x + prismAltar.width / 2f, prismAltar.y + prismAltar.height / 2f, count = 25, color = Color.GOLD)
                            cameraManager.shake(0.3f, 0.2f)
                            val heroTitle = when (nextArchetype) {
                                CharacterArchetype.BALANCED -> "KAELEN (PEWARIS BARA EMAS)"
                                CharacterArchetype.AGILE -> "ZEPHYR (THE PHANTOM STRIDER)"
                                CharacterArchetype.HEAVY -> "GORGON (THE IRONBREAKER)"
                            }
                            floatingTexts.add(
                                FloatingText("✦ TRIAD SWAP: $heroTitle ✦", prismAltar.x - 1.5f, prismAltar.y + prismAltar.height + 0.8f, Color.GOLD, duration = 3.0f)
                            )
                        } else {
                            floatingTexts.add(
                                FloatingText("✦ Ksatria Lain Masih Terkunci! Selesaikan Menara! ✦", prismAltar.x - 1.5f, prismAltar.y + prismAltar.height + 0.8f, Color.WHITE, duration = 2.0f)
                            )
                        }
                    }
                }
            }

            // Pembaruan Dialog Naratif Karakter (NPC & Cutscenes)
            nearbyDialoguePrompt = null
            for (dialogue in currentFloor.storyDialogues) {
                val dist = player.position.dst(dialogue.triggerX, dialogue.triggerY)
                if (dist <= dialogue.triggerRadius) {
                    if (!dialogue.isTriggered) {
                        nearbyDialoguePrompt = dialogue
                        if (activeStoryDialogue == null && activeLoreTablet == null) {
                            activeStoryDialogue = dialogue
                            AudioManager.playLevelUp()
                            break
                        }
                    }
                }
            }

            // Pembaruan Sistem AI Combat Director & Musuh Biasa
            CombatDirector.update(updateDelta)
            val enemyDelta = if (activeTemporalPact == TemporalPact.GREED) updateDelta * 1.20f else updateDelta
            for (enemy in currentFloor.allEnemies) {
                enemy.update(enemyDelta, player, currentFloor.platforms)
                if (enemy.health.isDead && !enemy.rewardClaimed) {
                    enemy.rewardClaimed = true
                    endlessEnemiesKilled++
                    AudioManager.playDeath()
                    particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height / 2f, count = 16, color = Color.RED)
                    grantRewards(enemy.expReward, enemy.goldReward, enemy.position.x + enemy.width / 2f, enemy.position.y + 1f)
                    relicManager.onEnemyDefeated(player, floatingTexts, particleManager)
                    com.stickman.tower.achievement.AchievementManager.onEnemyKilled(false, currentFloorNumber, saveData = saveData)

                    // Pencatatan Eliminasi Bestiarium Lapangan (Fase 19)
                    val bestiaryId = when {
                        enemy.type == EnemyType.RANGED -> "AMETHYST_SNIPER"
                        currentFloorNumber in listOf(4, 7) -> "OBSIDIAN_KNIGHT"
                        currentFloorNumber in 7..9 -> "SHADOW_PHANTOM"
                        else -> "CRIMSON_GRUNT"
                    }
                    BestiaryManager.recordKill(bestiaryId, saveData)
                }
            }

            // Pembaruan Boss (Jika Ada)
            val boss = currentFloor.boss
            if (boss != null) {
                val wasPhase2 = boss.isPhase2
                val bossDelta = if (activeTemporalPact == TemporalPact.GREED) updateDelta * 1.20f else updateDelta
                boss.update(bossDelta, player, currentFloor.platforms)
                if (!wasPhase2 && boss.isPhase2) {
                    cameraManager.shake(0.35f, 0.25f)
                    AudioManager.playBossRoar()
                    HapticManager.vibrateHeavy()
                    floatingTexts.add(
                        FloatingText("❖ ${boss.name}: \"${boss.enrageQuote}\"", boss.position.x + boss.width / 2f, boss.position.y + boss.height + 1.2f, Color.SCARLET, duration = 4.0f)
                    )
                }
                if (boss.health.isDead && !boss.rewardClaimed) {
                    boss.rewardClaimed = true
                    endlessEnemiesKilled++
                    AudioManager.playDeath()
                    particleManager.spawnHitSparks(boss.position.x + boss.width / 2f, boss.position.y + boss.height / 2f, count = 35, color = Color.GOLD)
                    grantRewards(boss.expReward, boss.goldReward, boss.position.x + boss.width / 2f, boss.position.y + 1.5f)
                    com.stickman.tower.achievement.AchievementManager.onEnemyKilled(true, currentFloorNumber, boss.name, saveData = saveData)
                    QuestManager.notifyEvent(ObjectiveType.DEFEAT_BOSS, boss.type.name)

                    // Drop Rune Kuno Transmutasi Alkimia (Fase 22)
                    val droppedRune = when (boss.type) {
                        BossType.TOWER_GUARDIAN -> RuneType.RUNE_LUNAR
                        BossType.AMETHYST_MATRON -> RuneType.RUNE_TEMPEST
                        BossType.GRAND_CALLIGRAPHER -> RuneType.RUNE_ABYSS
                        else -> null
                    }
                    if (droppedRune != null && RuneManager.unlockRune(droppedRune, saveData)) {
                        floatingTexts.add(
                            FloatingText("💎 RUNE PURBA TERBUKA: ${droppedRune.displayName}!", boss.position.x, boss.position.y + 4.2f, droppedRune.primaryColor, duration = 4.0f)
                        )
                        AudioManager.playLevelUp()
                        SaveManager.saveAsync(saveData)
                    }

                    // Pencatatan Eliminasi Bos Bestiarium Lapangan (Fase 19)
                    val bossBestiaryId = when (boss.type) {
                        BossType.TOWER_GUARDIAN -> "BOSS_OAKHAVEN"
                        BossType.AMETHYST_MATRON -> "BOSS_MATRON"
                        BossType.GRAND_CALLIGRAPHER -> "BOSS_CALLIGRAPHER"
                        else -> "BOSS_OAKHAVEN"
                    }
                    BestiaryManager.recordKill(bossBestiaryId, saveData)
                    floatingTexts.add(
                        FloatingText("★ BOSS DEFEATED! ★", boss.position.x, boss.position.y + 3.2f, Color.GOLD, duration = 3.5f)
                    )
                    floatingTexts.add(
                        FloatingText("\"${boss.deathQuote}\"", boss.position.x + boss.width / 2f, boss.position.y + 2.2f, Color.LIGHT_GRAY, duration = 4.5f)
                    )

                    // Integrasi Mode Boss Rush (Gauntlet of Sovereigns) (Fase 23)
                    if (gameMode == GameMode.BOSS_RUSH) {
                        if (bossRushStage < 5) {
                            val healAmount = player.health.maxHp * 0.35f
                            player.health.heal(healAmount)
                            particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.health.maxHp * 0.05f, count = 20, color = Color.GREEN)
                            floatingTexts.add(
                                FloatingText("+35% ANIMA PULIH! 🩸", player.position.x + player.width / 2f, player.position.y + player.height + 0.8f, Color.GREEN, duration = 3.0f)
                            )
                            bossRushTransitionTimer = 2.5f
                            floatingTexts.add(
                                FloatingText("⚔ TAHAP $bossRushStage/5 TUNTAS! BOS BERIKUTNYA DALAM 2.5s...", boss.position.x, boss.position.y + 4.5f, Color.CYAN, duration = 2.8f)
                            )
                        } else {
                            val (rank, isNewRecord, unlockedTitle) = BossRushManager.recordCompletion(archetype.name, bossRushTimer, saveData)
                            if (rank.goldReward > 0) {
                                player.stats.addGold(rank.goldReward)
                            }
                            player.stats.applyToSaveData(saveData)
                            SaveManager.saveAsync(saveData)
                            gameStatus = GameStatus.STAGE_CLEAR
                            AudioManager.playLevelUp()
                            floatingTexts.add(
                                FloatingText("★ GAUNTLET DITAKLUKKAN! [${rank.badgeSymbol}] ★", boss.position.x, boss.position.y + 4.5f, rank.primaryColor, duration = 5.0f)
                            )
                            if (unlockedTitle != null) {
                                floatingTexts.add(
                                    FloatingText("✦ GELAR TERBUKA: \"${unlockedTitle.titleName}\"! ✦", player.position.x, player.position.y + 2.5f, Color.GOLD, duration = 4.5f)
                                )
                            }
                        }
                    }
                }
            }

            // Pembaruan Roh Pendamping Tinta (Fase 21)
            inkFamiliar.update(updateDelta, player, currentFloor.allEnemies, currentFloor.boss, particleManager, floatingTexts)

            // 2. Deteksi Pertarungan Dua Arah (Pemain <-> Musuh / Boss)
            handleTwoWayCombat()

            // Toxic Miasma Mutator Tick (Fase 13)
            if (activeMutator == FloorMutator.TOXIC_MIASMA && !player.health.isDead) {
                miasmaTimer += updateDelta
                if (miasmaTimer >= 4.5f) {
                    miasmaTimer = 0f
                    player.takeHit(4f, 0f, 0f)
                    cameraManager.shake(0.2f, 0.15f)
                    particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 8, color = Color.PURPLE)
                    floatingTexts.add(
                        FloatingText("-4 MIASMA", player.position.x + player.width / 2f, player.position.y + player.height + 0.4f, COLOR_MIASMA)
                    )
                }
            }

            // Endless Survival Time Tracking
            if (gameMode == GameMode.ENDLESS && !player.health.isDead) {
                endlessSurvivalTime += updateDelta
            }

            // Boss Rush Timer & Stage Transition Tracking (Fase 23)
            if (gameMode == GameMode.BOSS_RUSH && !player.health.isDead && !isBossIntroActive) {
                bossRushTimer += updateDelta
                if (bossRushTransitionTimer > 0f) {
                    bossRushTransitionTimer = (bossRushTransitionTimer - updateDelta).coerceAtLeast(0f)
                    if (bossRushTransitionTimer <= 0f && bossRushStage < 5) {
                        bossRushStage++
                        val nextFloor = when (bossRushStage) {
                            2 -> 5
                            3 -> 8
                            4 -> 9
                            else -> 10
                        }
                        loadFloor(nextFloor)
                        floatingTexts.add(
                            FloatingText("⚔ GAUNTLET: TAHAP $bossRushStage / 5!", player.position.x, player.position.y + 2.0f, Color.GOLD, duration = 2.5f)
                        )
                    }
                }
            }

            // 3. Evaluasi Kondisi Menang & Kalah
            evaluateGameConditions()
        }

        // 4. Perbarui Teks Floating Damage (Zero-Allocation Reverse Indexed Loop)
        for (i in floatingTexts.indices.reversed()) {
            val ft = floatingTexts[i]
            ft.update(updateDelta)
            if (ft.isExpired) {
                floatingTexts.removeAt(i)
            }
        }

        // 5. Render Objek Dunia 2D & Partikel (World Space: Meters)
        renderWorld(safeDelta)

        // 6. UI Viewport Pass (Pixel-Perfect 1280x720 Screen Space)
        uiViewport.apply()
        shapeRenderer.projectionMatrix = uiCamera.combined
        batch.projectionMatrix = uiCamera.combined

        // 7. Pass UI Geometri (Consolidated ShapeRenderer Pass: Virtual Controller + HUD)
        virtualController.renderShapes(
            shapeRenderer,
            player.skill1,
            player.skill2,
            player.skill3,
            player.ultimate
        )
        renderHUDShapes()
        if (isBossIntroActive) {
            renderBossIntroShapes()
        }

        // 8. Pass UI Teks & Ikon (Consolidated Single Continuous SpriteBatch Pass)
        batch.begin()
        virtualController.renderText(
            batch,
            FontManager.smallFont,
            player.skill1,
            player.skill2,
            player.skill3,
            player.ultimate
        )
        renderHUDText()
        if (isBossIntroActive) {
            renderBossIntroText()
        }
        batch.end()

        // 8.5 Post-Processing VFX (Critical Anima Vignette, Parry Flare & Ink Screen Dissolve - Fase 20)
        renderPostProcessingVFX(safeDelta)

    }

    private fun renderWorld(delta: Float) {
        val lookaheadTarget = if (abs(player.velocity.x) > 0.6f) (if (player.facingRight) 1.5f else -1.5f) else 0f
        val targetCamX = if (isBossIntroActive && currentFloor.boss != null) currentFloor.boss!!.position.x + currentFloor.boss!!.width / 2f else player.position.x + player.width / 2f + lookaheadTarget
        val targetCamY = if (isBossIntroActive && currentFloor.boss != null) currentFloor.boss!!.position.y + 1.2f else player.position.y + player.height / 2f + 0.5f
        cameraManager.update(targetCamX, targetCamY, delta)

        // Zero-Allocation Clear Color Selection
        val clearR: Float
        val clearG: Float
        val clearB: Float
        when {
            currentFloor.isSafeZone -> { clearR = 0.14f; clearG = 0.08f; clearB = 0.04f }
            currentFloor.floorNumber == 9 -> { clearR = 0.16f; clearG = 0.03f; clearB = 0.05f }
            currentFloor.floorNumber in 4..5 -> { clearR = 0.10f; clearG = 0.05f; clearB = 0.15f }
            currentFloor.floorNumber in 7..8 -> { clearR = 0.04f; clearG = 0.05f; clearB = 0.12f }
            currentFloor.floorNumber == 10 -> { clearR = 0.02f; clearG = 0.02f; clearB = 0.05f }
            currentFloor.isBossFloor -> { clearR = 0.12f; clearG = 0.08f; clearB = 0.12f }
            else -> { clearR = 0.08f; clearG = 0.09f; clearB = 0.13f }
        }
        ScreenUtils.clear(clearR, clearG, clearB, 1f)

        cameraManager.viewport.apply()
        shapeRenderer.projectionMatrix = cameraManager.camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // 1. Render Atmospheric Parallax Background (Zero-Allocation Layered Depth)
        backgroundRenderer.render(
            shapeRenderer,
            cameraManager.camera,
            currentFloor.floorNumber,
            hudAnimTime,
            currentFloor.mapBounds.width
        )

        // Zero Pop-In Frustum Bounding Box Culling dengan Buffer Lebar Adaptif
        // Kamera Viewport Width = 16m (half = 8m).
        // Buffer aman: 24m di luar tepi kiri layar, 32m di luar tepi kanan layar (total span 72m).
        // Menjamin tidak ada platform yang hilang saat mundur/lompat, dan musuh/halangan/proyektil sudah ter-render sempurna sebelum masuk layar.
        val halfViewportW = cameraManager.viewport.worldWidth / 2f
        val camX = cameraManager.camera.position.x
        val minCullX = camX - halfViewportW - 24.0f
        val maxCullX = camX + halfViewportW + 32.0f

        for (platform in currentFloor.platforms) {
            if (platform.bounds.x + platform.bounds.width >= minCullX && platform.bounds.x <= maxCullX) {
                platform.render(shapeRenderer)
            }
        }

        // 1.5 Render Environmental Storytelling Props (Fase 19)
        for (prop in currentFloor.environmentalProps) {
            prop.update(delta)
            if (prop.x + prop.width >= minCullX && prop.x <= maxCullX) {
                prop.render(shapeRenderer)
            }
        }

        for (spike in currentFloor.spikes) {
            if (spike.bounds.x + spike.bounds.width >= minCullX && spike.bounds.x <= maxCullX) {
                spike.render(shapeRenderer)
            }
        }
        for (chest in currentFloor.chests) {
            if (chest.bounds.x + chest.bounds.width >= minCullX && chest.bounds.x <= maxCullX) {
                chest.render(shapeRenderer)
            }
        }
        for (tablet in currentFloor.loreTablets) {
            if (tablet.bounds.x + tablet.bounds.width >= minCullX && tablet.bounds.x <= maxCullX) {
                tablet.render(shapeRenderer)
            }
        }
        currentFloor.bloodAltar?.update(delta, particleManager)
        currentFloor.bloodAltar?.let {
            if (it.bounds.x + it.bounds.width >= minCullX && it.bounds.x <= maxCullX) it.render(shapeRenderer)
        }
        currentFloor.checkpoint?.let {
            if (it.bounds.x + it.bounds.width >= minCullX && it.bounds.x <= maxCullX) it.render(shapeRenderer)
        }
        if (currentFloor.exitPortal.bounds.x + currentFloor.exitPortal.bounds.width >= minCullX && currentFloor.exitPortal.bounds.x <= maxCullX) {
            currentFloor.exitPortal.render(shapeRenderer)
        }

        // Render Runic Barriers, Keys, Cocoon, Titan Pillar, Basalt Walls & Co-op Allies (Fase 25, 26, & 27)
        for (barrier in currentFloor.runicBarriers) {
            if (barrier.bounds.x + barrier.bounds.width >= minCullX && barrier.bounds.x <= maxCullX) barrier.render(shapeRenderer)
        }
        for (key in currentFloor.runicKeys) {
            if (key.bounds.x + key.bounds.width >= minCullX && key.bounds.x <= maxCullX) key.render(shapeRenderer)
        }
        for (wall in currentFloor.basaltWalls) {
            if (wall.bounds.x + wall.bounds.width >= minCullX && wall.bounds.x <= maxCullX) wall.render(shapeRenderer)
        }
        currentFloor.zephyrCocoon?.render(shapeRenderer)
        currentFloor.titanPillar?.render(shapeRenderer)
        currentFloor.prismAltar?.render(shapeRenderer)
        zephyrCoopAlly?.render(shapeRenderer)
        gorgonCoopAlly?.render(shapeRenderer)

        // Render Tokoh Cerita (NPC)
        if (currentFloor.floorNumber == 6 || currentFloor.floorNumber == 13) {
            renderVulcanusNPC(shapeRenderer)
        } else if (currentFloor.floorNumber == 1) {
            renderAriaNPC(shapeRenderer)
        }

        for (enemy in currentFloor.allEnemies) {
            // Render musuh jika berada dalam buffer luas atau memiliki proyektil panah aktif yang sedang meluncur
            val hasActiveProjectiles = enemy.projectiles.isNotEmpty()
            if (hasActiveProjectiles || (enemy.position.x + enemy.width >= minCullX && enemy.position.x <= maxCullX)) {
                enemy.render(shapeRenderer)
            }
        }
        currentFloor.boss?.render(shapeRenderer)
        player.render(shapeRenderer)
        inkFamiliar.render(shapeRenderer)
        player.renderProjectiles(shapeRenderer)

        // Render Efek Partikel VFX dengan Buffer Luas Anti Pop-In
        particleManager.render(shapeRenderer, minCullX, maxCullX)

        // Render Radial Shockwave Super Finish Boss (Fase 11 & Engine 10/10 Chromatic Ripple)
        if (isBossShockwaveActive && shockwaveRadius > 0f) {
            val shockAlpha = (1f - shockwaveRadius / 22f).coerceIn(0f, 1f)
            // Cincin Luar (Cyan Chromatic Wave)
            shapeRenderer.setColor(0.2f, 0.9f, 1.0f, shockAlpha * 0.65f)
            shapeRenderer.circle(shockwaveCenterX, shockwaveCenterY, shockwaveRadius + 0.35f, 40)
            // Cincin Tengah (Golden Pure Wave)
            shapeRenderer.setColor(1.0f, 0.85f, 0.2f, shockAlpha * 0.95f)
            shapeRenderer.circle(shockwaveCenterX, shockwaveCenterY, shockwaveRadius, 44)
            // Cincin Dalam (Red Chromatic Wave)
            shapeRenderer.setColor(1.0f, 0.25f, 0.25f, shockAlpha * 0.70f)
            val innerR = (shockwaveRadius - 0.35f).coerceAtLeast(0f)
            shapeRenderer.circle(shockwaveCenterX, shockwaveCenterY, innerR, 40)
        }
        shapeRenderer.end()

        // Debug Bounding Boxes
        if (showDebugBounds || devTools.showHitboxes) {
            shapeRenderer.begin(ShapeRenderer.ShapeType.Line)
            player.renderDebug(shapeRenderer)
            for (enemy in currentFloor.allEnemies) enemy.renderDebug(shapeRenderer)
            currentFloor.boss?.renderDebug(shapeRenderer)
            for (platform in currentFloor.platforms) {
                shapeRenderer.color = if (platform.isOneWay) Color.CYAN else Color.YELLOW
                shapeRenderer.rect(platform.bounds.x, platform.bounds.y, platform.bounds.width, platform.bounds.height)
            }
            shapeRenderer.end()
        }

        if (floatingTexts.isNotEmpty()) {
            uiViewport.apply()
            batch.projectionMatrix = uiCamera.combined
            batch.begin()
            val dmgFont = FontManager.regularFont
            for (ft in floatingTexts) {
                ft.render(batch, dmgFont, cameraManager.camera)
            }
            batch.end()
        }
    }

    private fun handleTwoWayCombat() {
        val boss = currentFloor.boss

        // A. Serangan Pemain Mengenai Musuh Biasa
        if (player.hitbox.isActive) {
            for (enemy in currentFloor.allEnemies) {
                if (!enemy.health.isDead && !player.hitbox.hitEntities.contains(enemy)) {
                    if (player.hitbox.bounds.overlaps(enemy.hurtbox.bounds)) {
                        player.hitbox.hitEntities.add(enemy)

                        val isHeavyAttack = player.comboManager.currentStep == ComboStep.HIT_3 ||
                                player.isSkillStriking || player.isSkill2Active || player.isSkill3Active || player.isUlting

                        if (enemy.canBlockHitFrom(player.position.x)) {
                            if (isHeavyAttack) {
                                enemy.breakGuard(1.8f)
                                AudioManager.playParry()
                                hitStopManager.trigger(0.08f)
                                particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height * 0.6f, count = 18, color = Color.GOLD)
                                floatingTexts.add(
                                    FloatingText("★ GUARD BREAK! ★", enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height + 0.45f, Color.GOLD, isCritical = true)
                                )
                            } else {
                                AudioManager.playParry()
                                hitStopManager.trigger(0.04f)
                                particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height * 0.6f, count = 10, color = Color.CYAN)
                                floatingTexts.add(
                                    FloatingText("BLOCKED!", enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height + 0.35f, Color.CYAN)
                                )
                                enemy.velocity.x += if (player.facingRight) 2.0f else -2.0f
                                continue
                            }
                        }

                        val knockX = if (player.facingRight) player.hitbox.knockbackX else -player.hitbox.knockbackX
                        val knockY = player.hitbox.knockbackY
                        var actualDmg = if (currentFloorNumber == 7 && activeMoraleBuff == MoraleBuffType.KINETIC_SURGE) player.hitbox.damage * 1.08f else player.hitbox.damage
                        if (player.hitbox.isCritical && activeTemporalPact == TemporalPact.CARNAGE) {
                            actualDmg *= 1.40f
                        }

                        if (enemy.takeHit(actualDmg, knockX, knockY)) {
                            val combo = player.comboManager.registerHit()
                            hitStopManager.trigger(0.06f)
                            AudioManager.playHit()
                            particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height / 2f, count = 10, color = if (player.hitbox.isCritical) Color.GOLD else Color.WHITE)
                            relicManager.onComboHit(combo, player, currentFloor.allEnemies, currentFloor.boss, floatingTexts, particleManager)
                            com.stickman.tower.achievement.AchievementManager.onComboHit(combo, saveData)

                            // Lifesteal Mutator, Talents & Runes (Fase 13 & 22)
                            val lifesteal = activeMutator.lifestealPercent + RuneManager.calculateLifestealBonus(saveData)
                            if (lifesteal > 0f) {
                                if (activeTemporalPact == TemporalPact.SWIFTNESS) {
                                    // Pemulihan Anima dicegah oleh Pakta Kecepatan Jiwa
                                } else {
                                    val heal = player.hitbox.damage * lifesteal
                                    if (heal >= 0.5f) {
                                        player.health.heal(heal)
                                        floatingTexts.add(
                                            FloatingText("+${heal.toInt()} HP", player.position.x + player.width / 2f, player.position.y + player.height + 0.3f, Color.GREEN)
                                        )
                                    }
                                }
                            }

                            // Toxic Blade Sub-class Talent (Fase 13)
                            if (talentManager.hasToxicBlade()) {
                                enemy.applyPoison(3.5f, player.baseAttackPower * 0.35f)
                                particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height / 2f, count = 5, color = Color.GREEN)
                            }

                            // Efek Proc Roh Pendamping Tinta (Fase 21)
                            inkFamiliar.onAttackHitProc(enemy, particleManager, floatingTexts)

                            // Thorns Mutator dari Kontrak Buronan Elit (Fase 17)
                            val bountyAffixes = BountyManager.getActiveAffixesForFloor(currentFloorNumber)
                            if (bountyAffixes.contains(BountyAffix.THORNS)) {
                                val reflect = player.hitbox.damage * 0.15f
                                if (reflect >= 1f) {
                                    player.takeHit(reflect, -knockX * 0.2f, 0.5f)
                                    floatingTexts.add(
                                        FloatingText("-${reflect.toInt()} 🦔", player.position.x + player.width / 2f, player.position.y + player.height + 0.3f, Color.PURPLE)
                                    )
                                }
                            }

                            val energyGain = when {
                                player.isUlting -> 0f
                                player.comboManager.currentStep == ComboStep.HIT_3 -> 15f
                                player.isSkillStriking || player.isSkill2Active || player.isSkill3Active -> 12f
                                else -> 8f
                            }
                            player.ultimate.addEnergy(energyGain)

                            val critPrefix = if (player.hitbox.isCritical) "CRIT " else "-"
                            val textColor = when {
                                player.hitbox.isCritical -> Color.GOLD
                                player.isUlting -> Color.GOLD
                                player.isSkillStriking || player.isSkill2Active || player.isSkill3Active -> COLOR_SKILL_DMG
                                player.comboManager.currentStep == ComboStep.HIT_3 -> Color.ORANGE
                                else -> COLOR_ENEMY_DMG
                            }

                            floatingTexts.add(
                                FloatingText(
                                    "$critPrefix${actualDmg.toInt()}",
                                    enemy.position.x + enemy.width / 2f,
                                    enemy.position.y + enemy.height + 0.35f,
                                    textColor,
                                    isCritical = player.hitbox.isCritical
                                )
                            )
                        }
                    }
                }
            }

            // Serangan Pemain Mengenai Boss
            if (boss != null && !boss.health.isDead && !player.hitbox.hitEntities.contains(boss)) {
                if (player.hitbox.bounds.overlaps(boss.hurtbox.bounds)) {
                    player.hitbox.hitEntities.add(boss)

                    val knockX = if (player.facingRight) player.hitbox.knockbackX else -player.hitbox.knockbackX
                    val knockY = player.hitbox.knockbackY
                    var actualDmg = if (currentFloorNumber == 7 && activeMoraleBuff == MoraleBuffType.KINETIC_SURGE) player.hitbox.damage * 1.08f else player.hitbox.damage
                    if (player.hitbox.isCritical && activeTemporalPact == TemporalPact.CARNAGE) {
                        actualDmg *= 1.40f
                    }

                    if (boss.takeHit(actualDmg, knockX, knockY)) {
                        val combo = player.comboManager.registerHit()
                        bossGhostDelay = 0.35f
                        hitStopManager.trigger(0.06f)
                        AudioManager.playHit()
                        particleManager.spawnHitSparks(boss.position.x + boss.width / 2f, boss.position.y + boss.height / 2f, count = 14, color = Color.ORANGE)
                        relicManager.onComboHit(combo, player, currentFloor.allEnemies, currentFloor.boss, floatingTexts, particleManager)
                        com.stickman.tower.achievement.AchievementManager.onComboHit(combo, saveData)

                        // Lifesteal Mutator, Talents & Runes (Fase 13 & 22)
                        val lifesteal = activeMutator.lifestealPercent + RuneManager.calculateLifestealBonus(saveData)
                        if (lifesteal > 0f) {
                            if (activeTemporalPact == TemporalPact.SWIFTNESS) {
                                // Pemulihan Anima dicegah oleh Pakta Kecepatan Jiwa
                            } else {
                                val heal = player.hitbox.damage * lifesteal
                                if (heal >= 0.5f) {
                                    player.health.heal(heal)
                                    floatingTexts.add(
                                        FloatingText("+${heal.toInt()} HP", player.position.x + player.width / 2f, player.position.y + player.height + 0.3f, Color.GREEN)
                                    )
                                }
                            }
                        }

                        // Toxic Blade Sub-class Talent (Fase 13)
                        if (talentManager.hasToxicBlade()) {
                            boss.applyPoison(3.5f, player.baseAttackPower * 0.35f)
                            particleManager.spawnHitSparks(boss.position.x + boss.width / 2f, boss.position.y + boss.height / 2f, count = 6, color = Color.GREEN)
                        }

                        // Efek Proc Roh Pendamping Tinta (Fase 21)
                        inkFamiliar.onAttackHitBossProc(boss, particleManager, floatingTexts)

                        // Thorns Mutator dari Kontrak Buronan Elit (Fase 17)
                        val bountyAffixes = BountyManager.getActiveAffixesForFloor(currentFloorNumber)
                        if (bountyAffixes.contains(BountyAffix.THORNS)) {
                            val reflect = player.hitbox.damage * 0.15f
                            if (reflect >= 1f) {
                                player.takeHit(reflect, -knockX * 0.2f, 0.5f)
                                floatingTexts.add(
                                    FloatingText("-${reflect.toInt()} 🦔", player.position.x + player.width / 2f, player.position.y + player.height + 0.3f, Color.PURPLE)
                                )
                            }
                        }

                        // Super Finish Slow-Motion & Radial Shockwave jika Boss Mati (Fase 11 & Engine 10/10)
                        if (boss.health.isDead && !bossSlowMoTriggered) {
                            bossSlowMoTriggered = true
                            bossSlowMoTimer = 0.55f
                            isBossShockwaveActive = true
                            shockwaveRadius = 0.5f
                            shockwaveCenterX = boss.position.x + boss.width / 2f
                            shockwaveCenterY = boss.position.y + boss.height / 2f
                            cameraManager.shake(1.2f, 0.7f)
                            HapticManager.vibrateHeavy()
                            triggerScreenFlash(1.0f, 0.88f, 0.35f, duration = 0.45f, maxAlpha = 0.55f)
                        }

                        val energyGain = when {
                            player.isUlting -> 0f
                            player.comboManager.currentStep == ComboStep.HIT_3 -> 18f
                            player.isSkillStriking || player.isSkill2Active || player.isSkill3Active -> 15f
                            else -> 10f
                        }
                        player.ultimate.addEnergy(energyGain)

                        val critPrefix = if (player.hitbox.isCritical) "CRIT " else "-"
                        val textColor = if (player.hitbox.isCritical) Color.GOLD else Color.RED
                        floatingTexts.add(
                            FloatingText(
                                "$critPrefix${actualDmg.toInt()}",
                                boss.position.x + boss.width / 2f,
                                boss.position.y + boss.height + 0.45f,
                                textColor,
                                isCritical = player.hitbox.isCritical
                            )
                        )
                    }
                }
            }

            // Cek Hitbox Serangan Pemain terhadap Kepompong Zephyr (Fase 25)
            val cocoon = currentFloor.zephyrCocoon
            if (cocoon != null && !cocoon.isBroken && !player.hitbox.hitEntities.contains(cocoon)) {
                if (player.hitbox.bounds.overlaps(cocoon.bounds)) {
                    player.hitbox.hitEntities.add(cocoon)
                    if (cocoon.takeHit()) {
                        hitStopManager.trigger(0.08f)
                        AudioManager.playHit()
                        particleManager.spawnHitSparks(cocoon.x + cocoon.width / 2f, cocoon.y + cocoon.height / 2f, count = 18, color = Color.PURPLE)
                        if (cocoon.isBroken) {
                            AudioManager.playLevelUp()
                            particleManager.spawnHitSparks(cocoon.x + cocoon.width / 2f, cocoon.y + cocoon.height / 2f, count = 35, color = Color.CYAN)
                            floatingTexts.add(FloatingText("⚔ KEPOMPONG HANCUR! ZEPHYR BEBAS! ⚔", cocoon.x - 1.5f, cocoon.y + 3.2f, Color.CYAN, duration = 3.5f))
                            zephyrCoopAlly = ZephyrCoopAlly(spawnX = cocoon.x, spawnY = cocoon.y)
                            if (!saveData.unlockedCharacters.contains("ZEPHYR")) {
                                saveData.unlockedCharacters.add("ZEPHYR")
                                SaveManager.saveAsync(saveData)
                            }
                        } else {
                            floatingTexts.add(FloatingText("KEPOMPONG RETAK! (${3 - cocoon.hitsTaken}/3)", cocoon.x + 0.2f, cocoon.y + 2.5f, Color.PURPLE, duration = 1.2f))
                        }
                    }
                }
            }

            // Cek Hitbox Serangan Pemain terhadap Tuas Hidrolik Pilar Titan Gorgon (Fase 26)
            val pillar = currentFloor.titanPillar
            if (pillar != null && !pillar.isLeverCut && !player.hitbox.hitEntities.contains(pillar)) {
                if (player.hitbox.bounds.overlaps(pillar.leverBounds)) {
                    player.hitbox.hitEntities.add(pillar)
                    if (pillar.takeHit()) {
                        hitStopManager.trigger(0.08f)
                        AudioManager.playHit()
                        particleManager.spawnHitSparks(pillar.leverBounds.x + pillar.leverBounds.width / 2f, pillar.leverBounds.y + pillar.leverBounds.height / 2f, count = 18, color = Color.CORAL)
                        if (pillar.isLeverCut) {
                            AudioManager.playLevelUp()
                            particleManager.spawnHitSparks(pillar.leverBounds.x + pillar.leverBounds.width / 2f, pillar.leverBounds.y + pillar.leverBounds.height / 2f, count = 40, color = Color.GOLD)
                            floatingTexts.add(FloatingText("🛡 RANTAI LAHAR PUTUS! GORGON BEBAS! 🛡", pillar.x - 1.5f, pillar.y + 3.5f, Color.GOLD, duration = 3.5f))
                            gorgonCoopAlly = GorgonCoopAlly(spawnX = pillar.x + pillar.width + 0.5f, spawnY = pillar.y)
                            CharacterUnlockManager.unlockGorgon(saveData)
                            if (!saveData.unlockedCharacters.contains("STICKMAN_HEAVY")) {
                                saveData.unlockedCharacters.add("STICKMAN_HEAVY")
                            }
                            if (!saveData.unlockedCharacters.contains("GORGON")) {
                                saveData.unlockedCharacters.add("GORGON")
                            }
                            SaveManager.saveAsync(saveData)
                        } else {
                            floatingTexts.add(FloatingText("KATUP RETAK! (${3 - pillar.hitsTaken}/3)", pillar.leverBounds.x + 0.2f, pillar.leverBounds.y + 2.5f, Color.CORAL, duration = 1.2f))
                        }
                    }
                }
            }

            // Cek Hitbox Serangan Pemain terhadap Dinding Basalt Titan (Fase 27)
            for (wall in currentFloor.basaltWalls) {
                if (!wall.isBroken && !player.hitbox.hitEntities.contains(wall)) {
                    if (player.hitbox.bounds.overlaps(wall.bounds)) {
                        player.hitbox.hitEntities.add(wall)
                        if (wall.takeHit()) {
                            hitStopManager.trigger(0.08f)
                            AudioManager.playHit()
                            particleManager.spawnHitSparks(wall.x + wall.width / 2f, wall.y + wall.height / 2f, count = 15, color = Color.ORANGE)
                            if (wall.isBroken) {
                                cameraManager.shake(0.5f, 0.25f)
                                AudioManager.playLevelUp()
                                particleManager.spawnHitSparks(wall.x + wall.width / 2f, wall.y + wall.height / 2f, count = 35, color = Color.GOLD)
                                floatingTexts.add(FloatingText("💥 DINDING BASALT HANCUR! 💥", wall.x - 0.5f, wall.y + wall.height + 0.5f, Color.GOLD, duration = 2.0f))
                            } else {
                                floatingTexts.add(FloatingText("DINDING RETAK! (${wall.maxHits - wall.hitsTaken}/3)", wall.x + 0.2f, wall.y + wall.height + 0.3f, Color.ORANGE, duration = 1.0f))
                            }
                        }
                    }
                }
            }
        }

        // A2. Proyektil Pemain (Skill 1: Gale Crescent / Shuriken / Shockwave) mengenai Musuh & Boss
        for (i in 0 until player.projectiles.size) {
            val proj = player.projectiles[i]
            if (proj.isDestroyed) continue

            for (enemy in currentFloor.allEnemies) {
                if (!enemy.health.isDead && proj.bounds.overlaps(enemy.hurtbox.bounds)) {
                    if (enemy.canBlockHitFrom(proj.position.x)) {
                        AudioManager.playParry()
                        particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height * 0.6f, count = 10, color = Color.CYAN)
                        floatingTexts.add(
                            FloatingText("BLOCKED!", enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height + 0.35f, Color.CYAN)
                        )
                        proj.isDestroyed = true
                        break
                    }
                    val knockX = if (proj.velocityX > 0) 6f else -6f
                    if (enemy.takeHit(proj.damage, knockX, 2f)) {
                        particleManager.spawnHitSparks(enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height / 2f, count = 8, color = proj.color)
                        floatingTexts.add(
                            FloatingText(
                                "-${proj.damage.toInt()}",
                                enemy.position.x + enemy.width / 2f,
                                enemy.position.y + enemy.height + 0.35f,
                                proj.color
                            )
                        )
                        player.comboManager.registerHit()
                        player.ultimate.addEnergy(8f)
                    }
                    proj.isDestroyed = true
                    break
                }
            }

            if (!proj.isDestroyed && boss != null && !boss.health.isDead && proj.bounds.overlaps(boss.hurtbox.bounds)) {
                val knockX = if (proj.velocityX > 0) 4f else -4f
                if (boss.takeHit(proj.damage, knockX, 1.5f)) {
                    particleManager.spawnHitSparks(boss.position.x + boss.width / 2f, boss.position.y + boss.height / 2f, count = 10, color = proj.color)
                    floatingTexts.add(
                        FloatingText(
                            "-${proj.damage.toInt()}",
                            boss.position.x + boss.width / 2f,
                            boss.position.y + boss.height + 0.5f,
                            proj.color
                        )
                    )
                    player.comboManager.registerHit()
                    player.ultimate.addEnergy(10f)
                }
                proj.isDestroyed = true
            }
        }

        // B. Serangan Musuh Biasa Mengenai Pemain (Dapat di-Parry / Guard Break)
        for (enemy in currentFloor.allEnemies) {
            if (enemy.hitbox.isActive && !enemy.hitbox.hitEntities.contains(player) && !player.health.isDead) {
                if (enemy.hitbox.bounds.overlaps(player.hurtbox.bounds)) {
                    enemy.hitbox.hitEntities.add(player)

                    if (player.isParrying) {
                        // Sistem Perfect Parry Fase 11: Stun musuh 1.5s, netralkan damage, beri buff ATK + energy
                        enemy.stun(1.5f)
                        player.triggerParry()
                        val parryCombo = player.comboManager.registerHit()
                        relicManager.onComboHit(parryCombo, player, currentFloor.allEnemies, currentFloor.boss, floatingTexts, particleManager)
                        if (talentManager.hasParryHeal()) {
                            if (activeTemporalPact == TemporalPact.SWIFTNESS) {
                                floatingTexts.add(
                                    FloatingText("⛔ HEAL TERBLOKIR PAKTA", player.position.x + player.width / 2f, player.position.y + player.height + 0.35f, Color.CYAN)
                                )
                            } else {
                                val parryHeal = player.health.maxHp * 0.15f
                                player.health.heal(parryHeal)
                                floatingTexts.add(
                                    FloatingText("+${parryHeal.toInt()} HP", player.position.x + player.width / 2f, player.position.y + player.height + 0.35f, Color.GREEN)
                                )
                            }
                        }
                        hitStopManager.trigger(0.08f)
                        AudioManager.playParry()
                        parryFlashTimer = 0.18f
                        triggerScreenFlash(1.0f, 1.0f, 1.0f, duration = 0.14f, maxAlpha = 0.35f)
                        com.stickman.tower.achievement.AchievementManager.onPerfectParry(saveData)
                        QuestManager.notifyEvent(ObjectiveType.PERFECT_PARRY, "PARRY")
                        if (currentFloorNumber == 2) {
                            ChallengeManager.recordAttempt("GAUNTLET_DEFLECTION", player.comboManager.comboCount)
                            ChallengeManager.syncToSaveData(saveData)
                        }
                        inkFamiliar.onParryProc(player.position.x + player.width / 2f, player.position.y + player.height / 2f, currentFloor.allEnemies, currentFloor.boss, particleManager, floatingTexts)
                        HapticManager.vibrateHeavy()
                        input.gamepad.vibrate(200, 1.0f)
                        cameraManager.shake(0.5f, 0.25f)
                        particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 22, color = Color.GOLD)
                        floatingTexts.add(
                            FloatingText(
                                "✨ DENTANG PENOLAKAN TAKDIR! (PARRY) ✨",
                                player.position.x + player.width / 2f,
                                player.position.y + player.height + 0.5f,
                                Color.GOLD,
                                duration = 1.4f,
                                isCritical = true
                            )
                        )
                    } else {
                        val knockX = if (enemy.facingRight) enemy.hitbox.knockbackX else -enemy.hitbox.knockbackX
                        val knockY = enemy.hitbox.knockbackY

                        if (player.takeHit(enemy.hitbox.damage, knockX, knockY)) {
                            playerGhostDelay = 0.35f
                            hitStopManager.trigger(0.08f)
                            AudioManager.playHit()
                            HapticManager.vibrateMedium()
                            input.gamepad.vibrate(150, 0.6f)
                            particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 10, color = Color.RED)
                            floatingTexts.add(
                                FloatingText(
                                    "-${enemy.hitbox.damage.toInt()}",
                                    player.position.x + player.width / 2f,
                                    player.position.y + player.height + 0.35f,
                                    COLOR_CRIT_DMG
                                )
                            )

                            // Vampiric Mutator dari Kontrak Buronan Elit (Fase 17)
                            val bAffixes = BountyManager.getActiveAffixesForFloor(currentFloorNumber)
                            if (bAffixes.contains(BountyAffix.VAMPIRIC)) {
                                val heal = enemy.health.maxHp * 0.10f
                                enemy.health.heal(heal)
                                floatingTexts.add(
                                    FloatingText("+${heal.toInt()} 🩸", enemy.position.x + enemy.width / 2f, enemy.position.y + enemy.height + 0.3f, Color.GREEN)
                                )
                            }
                        }
                    }
                }
            }
        }

        // C. Serangan Melee Boss Mengenai Pemain (Dapat di-Parry / Guard Break)
        if (boss != null && boss.hitbox.isActive && !boss.hitbox.hitEntities.contains(player) && !player.health.isDead) {
            if (boss.hitbox.bounds.overlaps(player.hurtbox.bounds)) {
                boss.hitbox.hitEntities.add(player)

                if (player.isParrying) {
                    // Sistem Perfect Parry Fase 11: Stun Boss 1.5s (Guard Break!), netralkan damage
                    boss.stun(1.5f)
                    player.triggerParry()
                    val parryCombo = player.comboManager.registerHit()
                    relicManager.onComboHit(parryCombo, player, currentFloor.allEnemies, currentFloor.boss, floatingTexts, particleManager)
                    if (talentManager.hasParryHeal()) {
                        if (activeTemporalPact == TemporalPact.SWIFTNESS) {
                            floatingTexts.add(
                                FloatingText("⛔ HEAL TERBLOKIR PAKTA", player.position.x + player.width / 2f, player.position.y + player.height + 0.35f, Color.CYAN)
                            )
                        } else {
                            val parryHeal = player.health.maxHp * 0.15f
                            player.health.heal(parryHeal)
                            floatingTexts.add(
                                FloatingText("+${parryHeal.toInt()} HP", player.position.x + player.width / 2f, player.position.y + player.height + 0.35f, Color.GREEN)
                            )
                        }
                    }
                    hitStopManager.trigger(0.08f)
                    AudioManager.playParry()
                    parryFlashTimer = 0.18f
                    triggerScreenFlash(1.0f, 1.0f, 1.0f, duration = 0.14f, maxAlpha = 0.35f)
                    com.stickman.tower.achievement.AchievementManager.onPerfectParry(saveData)
                    QuestManager.notifyEvent(ObjectiveType.PERFECT_PARRY, "PARRY")
                    inkFamiliar.onParryProc(player.position.x + player.width / 2f, player.position.y + player.height / 2f, currentFloor.allEnemies, currentFloor.boss, particleManager, floatingTexts)
                    HapticManager.vibrateHeavy()
                    input.gamepad.vibrate(250, 1.0f)
                    cameraManager.shake(0.8f, 0.35f)
                    particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 28, color = Color.GOLD)
                    floatingTexts.add(
                        FloatingText(
                            "✨ DENTANG PENOLAKAN TAKDIR! (PARRY) ✨",
                            player.position.x + player.width / 2f,
                            player.position.y + player.height + 0.5f,
                            Color.GOLD,
                            duration = 1.4f,
                            isCritical = true
                        )
                    )
                } else {
                    val knockX = if (boss.facingRight) boss.hitbox.knockbackX else -boss.hitbox.knockbackX
                    val knockY = boss.hitbox.knockbackY

                    if (player.takeHit(boss.hitbox.damage, knockX, knockY)) {
                        playerGhostDelay = 0.35f
                        hitStopManager.trigger(0.09f)
                        AudioManager.playHit()
                        particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 12, color = Color.RED)
                        floatingTexts.add(
                            FloatingText(
                                "-${boss.hitbox.damage.toInt()}",
                                player.position.x + player.width / 2f,
                                player.position.y + player.height + 0.35f,
                                COLOR_ENEMY_DMG
                            )
                        )

                        // Vampiric Mutator dari Kontrak Buronan Elit (Fase 17)
                        val bAffixes = BountyManager.getActiveAffixesForFloor(currentFloorNumber)
                        if (bAffixes.contains(BountyAffix.VAMPIRIC)) {
                            val heal = boss.health.maxHp * 0.10f
                            boss.health.heal(heal)
                            floatingTexts.add(
                                FloatingText("+${heal.toInt()} 🩸", boss.position.x + boss.width / 2f, boss.position.y + boss.height + 0.3f, Color.GREEN)
                            )
                        }
                    }
                }
            }
        }

        // D. Proyektil Wind Slash Boss Mengenai Pemain (Dapat di-Deflect)
        if (boss != null) {
            for (proj in boss.projectiles) {
                if (!proj.isDestroyed && proj.bounds.overlaps(player.hurtbox.bounds) && !player.health.isDead) {
                    proj.isDestroyed = true

                    if (player.isParrying) {
                        player.triggerParry()
                        if (talentManager.hasParryHeal()) {
                            val parryHeal = player.health.maxHp * 0.15f
                            player.health.heal(parryHeal)
                            floatingTexts.add(
                                FloatingText("+${parryHeal.toInt()} HP", player.position.x + player.width / 2f, player.position.y + player.height + 0.35f, Color.GREEN)
                            )
                        }
                        hitStopManager.trigger(0.08f)
                        AudioManager.playParry()
                        HapticManager.vibrateHeavy()
                        input.gamepad.vibrate(200, 1.0f)
                        cameraManager.shake(0.6f, 0.3f)
                        particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 20, color = Color.GOLD)
                        floatingTexts.add(
                            FloatingText(
                                "✨ DEFLECTED! ✨",
                                player.position.x + player.width / 2f,
                                player.position.y + player.height + 0.5f,
                                Color.GOLD,
                                duration = 1.4f,
                                isCritical = true
                            )
                        )
                    } else {
                        val knockX = if (proj.velocityX > 0f) 6.5f else -6.5f
                        if (player.takeHit(proj.damage, knockX, 3.5f)) {
                            playerGhostDelay = 0.35f
                            hitStopManager.trigger(0.06f)
                            AudioManager.playHit()
                            HapticManager.vibrateMedium()
                            input.gamepad.vibrate(150, 0.6f)
                            particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 10, color = Color.RED)
                            floatingTexts.add(
                                FloatingText(
                                    "-${proj.damage.toInt()}",
                                    player.position.x + player.width / 2f,
                                    player.position.y + player.height + 0.35f,
                                    Color.RED
                                )
                            )
                        }
                    }
                }
            }
        }

        // E. Proyektil Ranged Enemy Mengenai Pemain (Dapat di-Deflect)
        for (enemy in currentFloor.allEnemies) {
            if (enemy.projectiles.isNotEmpty()) {
                for (proj in enemy.projectiles) {
                    if (!proj.isDestroyed && proj.bounds.overlaps(player.hurtbox.bounds) && !player.health.isDead) {
                        proj.isDestroyed = true

                        if (player.isParrying) {
                            player.triggerParry()
                            if (talentManager.hasParryHeal()) {
                                val parryHeal = player.health.maxHp * 0.15f
                                player.health.heal(parryHeal)
                                floatingTexts.add(
                                    FloatingText("+${parryHeal.toInt()} HP", player.position.x + player.width / 2f, player.position.y + player.height + 0.35f, Color.GREEN)
                                )
                            }
                            hitStopManager.trigger(0.08f)
                            AudioManager.playParry()
                            HapticManager.vibrateHeavy()
                            input.gamepad.vibrate(200, 1.0f)
                            cameraManager.shake(0.5f, 0.25f)
                            particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 18, color = Color.GOLD)
                            floatingTexts.add(
                                FloatingText(
                                    "✨ DEFLECTED! ✨",
                                    player.position.x + player.width / 2f,
                                    player.position.y + player.height + 0.5f,
                                    Color.GOLD,
                                    duration = 1.4f,
                                    isCritical = true
                                )
                            )
                        } else {
                            val knockX = if (proj.velocityX > 0f) 5.0f else -5.0f
                            if (player.takeHit(proj.damage, knockX, 2.5f)) {
                                playerGhostDelay = 0.35f
                                hitStopManager.trigger(0.05f)
                                AudioManager.playHit()
                                particleManager.spawnHitSparks(player.position.x + player.width / 2f, player.position.y + player.height / 2f, count = 8, color = COLOR_PURPLE_SPARK)
                                floatingTexts.add(
                                    FloatingText(
                                        "-${proj.damage.toInt()}",
                                        player.position.x + player.width / 2f,
                                        player.position.y + player.height + 0.35f,
                                        COLOR_PURPLE_DMG
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private fun evaluateGameConditions() {
        if (player.health.isDead && gameStatus == GameStatus.PLAYING) {
            gameStatus = GameStatus.GAME_OVER
            AudioManager.stopBgm()
            floatingTexts.add(
                FloatingText("DEFEATED!", player.position.x, player.position.y + 2.2f, Color.RED, duration = 2.0f)
            )
            if (gameMode == GameMode.ENDLESS) {
                LeaderboardManager.addEndlessRecord(
                    LeaderboardEntry(
                        playerName = "Hero",
                        characterArchetype = archetype.name,
                        floorReached = currentFloorNumber,
                        score = (player.stats.currentExp * 10L + player.stats.gold * 5L),
                        clearTimeSeconds = hudAnimTime.toLong()
                    )
                )
            }
        }

        val isFloorCleared = if (currentFloor.isSafeZone) {
            true
        } else if (currentFloor.isBossFloor) {
            currentFloor.boss?.health?.isDead == true
        } else {
            currentFloor.allEnemies.all { it.health.isDead }
        }

        if (gameMode == GameMode.BOSS_RUSH) {
            // Pada Boss Rush, transisi panggung ditangani secara otomatis oleh bossRushTransitionTimer
            // dan kemenangan akhir dicapai saat bos ke-5 tumbang.
            return
        }

        if (isFloorCleared && currentFloor.exitPortal.bounds.overlaps(player.bounds) && gameStatus == GameStatus.PLAYING) {
            gameStatus = GameStatus.STAGE_CLEAR
            floatingTexts.add(
                FloatingText("VICTORY!", currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 3.2f, Color.GOLD, duration = 2.5f)
            )
            if (!hasSavedStageClear) {
                hasSavedStageClear = true
                if (gameMode == GameMode.STORY) {
                    val nextFloorNum = (currentFloorNumber + 1).coerceAtMost(SaveData.MAX_STORY_FLOORS)
                    val expReward = if (currentFloor.isBossFloor) (currentFloor.boss?.expReward ?: 250) else (100 + currentFloorNumber * 20)
                    val goldReward = if (currentFloor.isBossFloor) (currentFloor.boss?.goldReward ?: 150) else (60 + currentFloorNumber * 10)
                    grantRewards(expReward, goldReward, currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 1.5f)

                    QuestManager.notifyEvent(ObjectiveType.CLEAR_FLOOR, "FLOOR_$currentFloorNumber")

                    // Kontrak Buronan Elit & Ujian Kaligrafer (Fase 17)
                    val clearedBounty = BountyManager.onFloorCleared(currentFloorNumber)
                    if (clearedBounty != null) {
                        BountyManager.syncToSaveData(saveData)
                        SaveManager.save(saveData)
                        floatingTexts.add(
                            FloatingText("BURONAN TERTUMBANGKAN! ☠", currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 4.0f, Color.RED, duration = 3.5f)
                        )
                    }

                    if (currentFloorNumber == 4) {
                        val pacewalkerScore = (100 - hudAnimTime.toInt()).coerceAtLeast(0)
                        ChallengeManager.recordAttempt("GAUNTLET_PACEWALKER", pacewalkerScore)
                        ChallengeManager.syncToSaveData(saveData)
                    } else if (currentFloorNumber == 6) {
                        val ironWillScore = (player.health.currentHp * 15f).toInt()
                        ChallengeManager.recordAttempt("GAUNTLET_IRON_WILL", ironWillScore)
                        ChallengeManager.syncToSaveData(saveData)
                    }

                    // Pembukaan Roh Pendamping Tinta (Fase 21)
                    if (currentFloorNumber >= 6 && !saveData.unlockedFamiliars.contains("VULCAN_SPARK")) {
                        saveData.unlockedFamiliars.add("VULCAN_SPARK")
                        SaveManager.save(saveData)
                        floatingTexts.add(
                            FloatingText("✦ PENDAMPING DIBUKA: BARA SUCI VULCANUS! ✦", currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 4.2f, Color.ORANGE, duration = 3.5f)
                        )
                    }
                    if (currentFloorNumber >= 8 && !saveData.unlockedFamiliars.contains("PHANTOM_SHADOW")) {
                        saveData.unlockedFamiliars.add("PHANTOM_SHADOW")
                        SaveManager.save(saveData)
                        floatingTexts.add(
                            FloatingText("✦ PENDAMPING DIBUKA: BAYANGAN HANTU ASTRAL! ✦", currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 4.8f, Color.MAGENTA, duration = 3.5f)
                        )
                    }

                    // Pembebasan Hero Ludonaratif (Fase 24: Hero Unlock Odyssey)
                    if (currentFloorNumber == 10 && !saveData.isZephyrRescued) {
                        CharacterUnlockManager.unlockZephyr(saveData)
                        saveData.highestEndlessFloor = kotlin.math.max(saveData.highestEndlessFloor, 11)
                        floatingTexts.add(
                            FloatingText("⚔ HERO DIBEBASKAN: ZEPHYR SANG BAYANGAN! ⚔", currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 4.5f, Color.CYAN, duration = 4.0f)
                        )
                    } else if (currentFloorNumber == 20 && !saveData.isGorgonRescued) {
                        CharacterUnlockManager.unlockGorgon(saveData)
                        floatingTexts.add(
                            FloatingText("🛡 HERO DIBEBASKAN: GORGON BENTENG BESI! 🛡", currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 4.5f, Color.GOLD, duration = 4.0f)
                        )
                    }

                    if (currentFloorNumber >= SaveData.MAX_STORY_FLOORS) {
                        triggerSave("Puncak Menara 50 Lantai Ditaklukkan! (Story Selesai)", highestFloor = SaveData.MAX_STORY_FLOORS + 1)
                        saveData.highestEndlessFloor = kotlin.math.max(saveData.highestEndlessFloor, SaveData.MAX_STORY_FLOORS + 1)
                        LeaderboardManager.addSpeedrunRecord(
                            LeaderboardEntry(
                                playerName = "Hero",
                                characterArchetype = archetype.name,
                                floorReached = SaveData.MAX_STORY_FLOORS,
                                score = (player.stats.currentExp * 15L + player.stats.gold * 10L),
                                clearTimeSeconds = hudAnimTime.toLong()
                            )
                        )
                    } else {
                        triggerSave("Lantai $currentFloorNumber Selesai", highestFloor = nextFloorNum)
                    }

                    if (currentFloorNumber == 1 && relicManager.activeRelics.isEmpty()) {
                        triggerRelicChoice()
                    } else if (currentFloorNumber in listOf(3, 5, 8) && relicManager.activeRelics.size < 4) {
                        triggerRelicChoice()
                    }
                } else {
                    // Endless Mode Stage Clear
                    val expReward = 120 + (currentFloorNumber * 25)
                    val goldReward = 75 + (currentFloorNumber * 15)
                    grantRewards(expReward, goldReward, currentFloor.exitPortal.x + 0.8f, currentFloor.exitPortal.y + 1.5f)

                    // Milestone Talent Point: +1 Poin setiap 2 lantai endless
                    if (currentFloorNumber % 2 == 0) {
                        talentManager.addTalentPoints(1)
                        talentManager.syncToSave(saveData)
                        SaveManager.save(saveData)
                        floatingTexts.add(
                            FloatingText("+1 TALENT POINT! ✦", player.position.x + player.width / 2f, player.position.y + player.height + 0.9f, Color.YELLOW, duration = 2.2f)
                        )
                    }
                    com.stickman.tower.achievement.AchievementManager.onEndlessFloorReached(currentFloorNumber, saveData)
                    LeaderboardManager.addEndlessRecord(
                        LeaderboardEntry(
                            playerName = "Hero",
                            characterArchetype = archetype.name,
                            floorReached = currentFloorNumber,
                            score = (player.stats.currentExp * 10L + player.stats.gold * 5L),
                            clearTimeSeconds = hudAnimTime.toLong()
                        )
                    )
                    triggerSave("Endless Lantai $currentFloorNumber Selesai", highestFloor = currentFloorNumber + 1)
                }
            }
        }
    }

    private fun handleStatusInput() {
        val w = 1280f
        val h = 720f

        if (gameStatus == GameStatus.GAME_OVER) {
            val keyRespawn = Gdx.input.isKeyJustPressed(Keys.R) ||
                             Gdx.input.isKeyJustPressed(Keys.SPACE) ||
                             Gdx.input.isKeyJustPressed(Keys.ENTER) ||
                             input.isJumpJustPressed() ||
                             input.isAttackJustPressed()
            val keyMenu = Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.ESCAPE)
            var touchRespawn = false
            var touchMenu = false

            if (Gdx.input.justTouched()) {
                uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                uiViewport.unproject(uiTouchVec)
                val tx = uiTouchVec.x
                val ty = uiTouchVec.y

                // Tombol Menu Utama di Layar Game Over: [w/2 + 20 .. w/2 + 260, h/2 - 85 .. h/2 - 15]
                // Tombol Respawn di Layar Game Over: [w/2 - 260 .. w/2 - 10, h/2 - 85 .. h/2 - 15]
                if (tx in (w / 2f + 15f)..(w / 2f + 265f) && ty in (h / 2f - 85f)..(h / 2f - 15f)) {
                    touchMenu = true
                } else if (tx in (w / 2f - 265f)..(w / 2f - 15f) && ty in (h / 2f - 85f)..(h / 2f - 15f)) {
                    touchRespawn = true
                }
            }

            if (touchMenu || keyMenu) {
                AudioManager.playDodge()
                if (game != null) {
                    (game as? StickmanGame)?.releasePreservedScreen(this)
                    game.setScreen(MainMenuScreen(game))
                }
                return
            }

            if (keyRespawn || touchRespawn) {
                if (gameMode == GameMode.BOSS_RUSH) {
                    bossRushStage = 1
                    bossRushTimer = 0f
                    bossRushTransitionTimer = 0f
                    loadFloor(3)
                    player.respawn(currentFloor.spawnX, currentFloor.spawnY)
                    gameStatus = GameStatus.PLAYING
                } else {
                    player.respawn(activeCheckpointPos.x, activeCheckpointPos.y)
                    currentFloor.boss?.let { b ->
                        if (!b.health.isDead) {
                            b.projectiles.clear()
                        }
                    }
                    gameStatus = GameStatus.PLAYING
                }
                AudioManager.playSlashLight()
            }
        } else if (gameStatus == GameStatus.STAGE_CLEAR) {
            val keyProceed = Gdx.input.isKeyJustPressed(Keys.SPACE) ||
                             Gdx.input.isKeyJustPressed(Keys.ENTER) ||
                             input.isJumpJustPressed() ||
                             input.isAttackJustPressed()
            val keyRestart = Gdx.input.isKeyJustPressed(Keys.R)
            val keyMenu = Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.ESCAPE)
            var touchProceed = false
            var touchRetry = false
            var touchMenu = false

            if (Gdx.input.justTouched()) {
                uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                uiViewport.unproject(uiTouchVec)
                val tx = uiTouchVec.x
                val ty = uiTouchVec.y

                val btnYMin = h / 2f - 45f
                val btnYMax = h / 2f + 15f
                val menu3YMin = h / 2f - 115f
                val menu3YMax = h / 2f - 60f

                if (tx in (w / 2f - 295f)..(w / 2f - 15f) && ty in btnYMin..btnYMax) {
                    touchProceed = true
                } else if (tx in (w / 2f + 15f)..(w / 2f + 295f) && ty in btnYMin..btnYMax) {
                    touchRetry = true
                } else if (tx in (w / 2f - 165f)..(w / 2f + 165f) && ty in menu3YMin..menu3YMax) {
                    touchMenu = true
                }
            }

            if (touchMenu || keyMenu) {
                AudioManager.playDodge()
                if (game != null) {
                    (game as? StickmanGame)?.releasePreservedScreen(this)
                    game.setScreen(MainMenuScreen(game))
                }
                return
            }

            val proceedTriggered = keyProceed || touchProceed
            val retryTriggered = keyRestart || touchRetry

            if (gameMode == GameMode.STORY) {
                if (currentFloorNumber < SaveData.MAX_STORY_FLOORS) {
                    if (proceedTriggered) {
                        loadFloor(currentFloorNumber + 1)
                    } else if (retryTriggered) {
                        loadFloor(currentFloorNumber)
                    }
                } else {
                    // Lantai 50 Selesai (Puncak Menara Ditaklukkan) -> Buka Akses Menara Tak Berujung (Endless)!
                    if (proceedTriggered) {
                        gameMode = GameMode.ENDLESS
                        loadFloor(SaveData.MAX_STORY_FLOORS + 1)
                    } else if (retryTriggered) {
                        loadFloor(1)
                    }
                }
            } else if (gameMode == GameMode.BOSS_RUSH) {
                if (proceedTriggered) {
                    if (game != null) {
                        (game as? StickmanGame)?.releasePreservedScreen(this)
                        game.setScreen(BossRushScreen(game, MainMenuScreen(game)))
                    }
                } else if (retryTriggered) {
                    bossRushStage = 1
                    bossRushTimer = 0f
                    bossRushTransitionTimer = 0f
                    loadFloor(3)
                    player.respawn(currentFloor.spawnX, currentFloor.spawnY)
                    gameStatus = GameStatus.PLAYING
                }
            } else {
                // Endless Mode: Lanjut ke Lantai Berikutnya
                if (proceedTriggered) {
                    loadFloor(currentFloorNumber + 1)
                } else if (retryTriggered) {
                    loadFloor(currentFloorNumber)
                }
            }
        }
    }

    private fun renderHUD() {
        renderHUDShapes()
        batch.projectionMatrix = uiCamera.combined
        batch.begin()
        renderHUDText()
        batch.end()
    }

    private fun renderHUDShapes() {
        val w = 1280f
        val h = 720f

        val hpPercent = (player.health.currentHp / player.health.maxHp).coerceIn(0f, 1f)
        val ghostHpPercent = (playerGhostHp / player.health.maxHp).coerceIn(0f, 1f)
        val isLowHp = hpPercent <= 0.25f
        val dangerThrob = if (isLowHp) ((Math.sin(hudAnimTime.toDouble() * 9.0).toFloat() + 1f) * 0.5f) else 0f

        // 1. Render Elemen Latar Bar & Kartu Karakter (ShapeRenderer pada Screen Space 1280x720)
        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Panel Latar Player Status Card (Kiri Atas - Obsidian Glassmorphism)
        shapeRenderer.setColor(0.06f + 0.08f * dangerThrob, 0.09f * (1f - dangerThrob), 0.15f * (1f - dangerThrob), 0.94f)
        shapeRenderer.rect(12f, h - 90f, 290f, 78f)

        // Panel Latar Sub-Stats Pod (Gold, ATK, Relics, Familiar)
        shapeRenderer.setColor(0.04f, 0.06f, 0.10f, 0.88f)
        shapeRenderer.rect(12f, h - 146f, 320f, 52f)
        shapeRenderer.setColor(0.20f, 0.30f, 0.45f, 0.50f)
        shapeRenderer.rectLine(12f, h - 94f, 332f, h - 94f, 1f)

        // Top Accent Line (Red danger pulse or Sleek Blue/Gold)
        if (isLowHp) {
            shapeRenderer.setColor(1f, 0.2f, 0.2f, 0.7f + 0.3f * dangerThrob)
        } else {
            shapeRenderer.setColor(0.22f, 0.38f, 0.60f, 0.75f)
        }
        shapeRenderer.rectLine(12f, h - 12f, 302f, h - 12f, 2f)

        // Level Badge Box
        shapeRenderer.setColor(0.10f, 0.15f, 0.24f, 1f)
        shapeRenderer.rect(18f, h - 84f, 55f, 66f)
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.85f)
        shapeRenderer.rectLine(18f, h - 84f, 73f, h - 84f, 2f)

        // HP Bar Trough (Dark Obsidian)
        shapeRenderer.setColor(0.05f, 0.06f, 0.09f, 1f)
        shapeRenderer.rect(80f, h - 35f, 210f, 16f)

        // HP Amber Ghost Catch-Up Bar
        if (ghostHpPercent > hpPercent) {
            shapeRenderer.setColor(0.95f, 0.62f, 0.15f, 0.90f)
            shapeRenderer.rect(80f, h - 35f, 210f * ghostHpPercent, 16f)
        }

        // HP Main Bar Fill (Emerald -> Gold -> Pulsing Crimson Danger)
        if (hpPercent > 0.5f) {
            shapeRenderer.setColor(0.18f, 0.85f, 0.38f, 1f)
        } else if (hpPercent > 0.25f) {
            shapeRenderer.setColor(0.95f, 0.75f, 0.15f, 1f)
        } else {
            val throb = (Math.sin(hudAnimTime.toDouble() * 10.0).toFloat() + 1f) * 0.5f
            shapeRenderer.setColor(0.88f + 0.12f * throb, 0.15f * (1f - throb), 0.15f * (1f - throb), 1f)
        }
        shapeRenderer.rect(80f, h - 35f, 210f * hpPercent, 16f)

        // HP Bar Highlight Rim
        shapeRenderer.setColor(1f, 1f, 1f, 0.22f)
        shapeRenderer.rectLine(80f, h - 20f, 290f, h - 20f, 1f)

        // EXP Bar Background & Fill
        shapeRenderer.setColor(0.05f, 0.06f, 0.09f, 1f)
        shapeRenderer.rect(80f, h - 53f, 210f, 12f)

        val expPercent = (player.stats.currentExp.toFloat() / player.stats.requiredExp.toFloat()).coerceIn(0f, 1f)
        shapeRenderer.setColor(0.15f, 0.75f, 0.95f, 1f)
        shapeRenderer.rect(80f, h - 53f, 210f * expPercent, 12f)
        shapeRenderer.setColor(1f, 1f, 1f, 0.20f)
        shapeRenderer.rectLine(80f, h - 42f, 290f, h - 42f, 1f)

        // Ultimate Energy Bar Background & Fill
        shapeRenderer.setColor(0.05f, 0.06f, 0.09f, 1f)
        shapeRenderer.rect(80f, h - 69f, 210f, 10f)

        if (player.ultimate.isReady) {
            val ultPulse = (Math.sin(hudAnimTime.toDouble() * 7.0).toFloat() + 1f) * 0.5f
            shapeRenderer.setColor(1f, 0.85f + 0.15f * ultPulse, 0.2f, 1f)
        } else {
            shapeRenderer.setColor(0.85f, 0.65f, 0.15f, 0.85f)
        }
        shapeRenderer.rect(80f, h - 69f, 210f * player.ultimate.energyPercent, 10f)

        // Save Notification Pill (Jika Aktif)
        if (saveNotificationTimer > 0f) {
            shapeRenderer.setColor(0.12f, 0.55f, 0.28f, 0.90f)
            shapeRenderer.rect(w / 2f - 110f, h - 38f, 220f, 26f)
        }

        // Tombol Pause (Pojok Kanan Atas)
        shapeRenderer.setColor(0.12f, 0.16f, 0.25f, 0.85f)
        shapeRenderer.rect(w - 110f, h - 45f, 98f, 32f)
        shapeRenderer.setColor(0.9f, 0.75f, 0.25f, 0.85f)
        shapeRenderer.rectLine(w - 110f, h - 45f, w - 12f, h - 45f, 2f)

        // Bar HP Boss Raksasa dengan Amber Ghost Bar & Phase 2 Threshold Marker
        val boss = currentFloor.boss
        if (boss != null && !boss.health.isDead) {
            val bossBarW = 440f
            val bossBarH = 22f
            val bossBarX = w / 2f - bossBarW / 2f
            val bossBarY = h - 36f

            // Frame Gelap Ornate
            shapeRenderer.setColor(0.05f, 0.06f, 0.09f, 0.96f)
            shapeRenderer.rect(bossBarX - 5f, bossBarY - 5f, bossBarW + 10f, bossBarH + 10f)

            // Outer border line
            if (boss.isPhase2) {
                shapeRenderer.setColor(0.95f, 0.35f, 0.15f, 0.9f)
            } else {
                shapeRenderer.setColor(0.80f, 0.68f, 0.30f, 0.85f)
            }
            shapeRenderer.rectLine(bossBarX - 5f, bossBarY + bossBarH + 5f, bossBarX + bossBarW + 5f, bossBarY + bossBarH + 5f, 2f)
            shapeRenderer.rectLine(bossBarX - 5f, bossBarY - 5f, bossBarX + bossBarW + 5f, bossBarY - 5f, 1.5f)

            // Trough
            shapeRenderer.setColor(0.08f, 0.08f, 0.12f, 1f)
            shapeRenderer.rect(bossBarX, bossBarY, bossBarW, bossBarH)

            // Boss Ghost Catch-Up Bar (Amber)
            val currentBossHpPct = (boss.health.currentHp / boss.health.maxHp).coerceIn(0f, 1f)
            val bossHpPct = if (isBossIntroActive) bossHpBarAnimated else currentBossHpPct
            val bossGhostPct = (bossGhostHp / boss.health.maxHp).coerceIn(0f, 1f)
            if (!isBossIntroActive && bossGhostPct > bossHpPct) {
                shapeRenderer.setColor(0.95f, 0.62f, 0.15f, 0.90f)
                shapeRenderer.rect(bossBarX, bossBarY, bossBarW * bossGhostPct, bossBarH)
            }

            // Boss Main Fill Bar (Crimson ke Api Fasa 2)
            if (boss.isPhase2) {
                val flame = (Math.sin(hudAnimTime.toDouble() * 9.0).toFloat() + 1f) * 0.5f
                shapeRenderer.setColor(1f, 0.22f + 0.18f * flame, 0.1f, 1f)
            } else {
                shapeRenderer.setColor(0.85f, 0.15f, 0.24f, 1f)
            }
            shapeRenderer.rect(bossBarX, bossBarY, bossBarW * bossHpPct, bossBarH)

            // Top subtle highlight line
            shapeRenderer.setColor(1f, 1f, 1f, 0.25f)
            shapeRenderer.rectLine(bossBarX, bossBarY + bossBarH - 2f, bossBarX + bossBarW * bossHpPct, bossBarY + bossBarH - 2f, 1.5f)

            // Phase 2 Threshold Marker (50% HP Indicator Divider)
            val markerX = bossBarX + bossBarW * 0.5f
            shapeRenderer.setColor(1f, 0.88f, 0.35f, 0.95f)
            shapeRenderer.rectLine(markerX, bossBarY - 4f, markerX, bossBarY + bossBarH + 4f, 2.5f)
            shapeRenderer.triangle(
                markerX - 4f, bossBarY + bossBarH + 5f,
                markerX + 4f, bossBarY + bossBarH + 5f,
                markerX, bossBarY + bossBarH + 10f
            )
        }

        // Mutator Badge Background
        if (gameMode == GameMode.ENDLESS && activeMutator != FloorMutator.NONE) {
            shapeRenderer.setColor(0.12f, 0.08f, 0.18f, 0.85f)
            shapeRenderer.rect(w / 2f - 240f, h - 110f, 480f, 38f)
            shapeRenderer.setColor(0.85f, 0.45f, 0.95f, 0.9f)
            shapeRenderer.rectLine(w / 2f - 240f, h - 72f, w / 2f + 240f, h - 72f, 2f)
        }

        // Gauntlet of Sovereigns Badge Background (Fase 23)
        if (gameMode == GameMode.BOSS_RUSH) {
            shapeRenderer.setColor(0.08f, 0.10f, 0.16f, 0.88f)
            shapeRenderer.rect(w / 2f - 240f, h - 110f, 480f, 38f)
            shapeRenderer.setColor(0.95f, 0.75f, 0.25f, 0.9f)
            shapeRenderer.rectLine(w / 2f - 240f, h - 72f, w / 2f + 240f, h - 72f, 2f)
        }

        // Overlays Game Over / Stage Clear Buttons (ShapeRenderer)
        if (gameStatus == GameStatus.GAME_OVER) {
            shapeRenderer.setColor(0f, 0f, 0f, 0.75f)
            shapeRenderer.rect(0f, 0f, w, h)

            val cardW = 560f
            val cardH = 220f
            val cardX = w / 2f - cardW / 2f
            val cardY = h / 2f - cardH / 2f
            shapeRenderer.setColor(0.08f, 0.10f, 0.16f, 0.95f)
            shapeRenderer.rect(cardX, cardY, cardW, cardH)
            shapeRenderer.setColor(0.9f, 0.2f, 0.25f, 0.92f)
            shapeRenderer.rectLine(cardX, cardY + cardH, cardX + cardW, cardY + cardH, 3f)

            // Tombol 1: Respawn (Emerald)
            shapeRenderer.setColor(0.14f, 0.38f, 0.22f, 0.95f)
            shapeRenderer.rect(w / 2f - 250f, h / 2f - 75f, 230f, 50f)
            shapeRenderer.setColor(0.25f, 0.9f, 0.45f, 0.95f)
            shapeRenderer.rectLine(w / 2f - 250f, h / 2f - 25f, w / 2f - 20f, h / 2f - 25f, 2.5f)

            // Tombol 2: Menu Utama (Dark Slate)
            shapeRenderer.setColor(0.14f, 0.18f, 0.26f, 0.95f)
            shapeRenderer.rect(w / 2f + 20f, h / 2f - 75f, 230f, 50f)
            shapeRenderer.setColor(0.7f, 0.78f, 0.9f, 0.9f)
            shapeRenderer.rectLine(w / 2f + 20f, h / 2f - 25f, w / 2f + 250f, h / 2f - 25f, 2.5f)
        }

        if (gameStatus == GameStatus.STAGE_CLEAR) {
            shapeRenderer.setColor(0f, 0f, 0f, 0.75f)
            shapeRenderer.rect(0f, 0f, w, h)

            val cardW = 720f
            val cardH = 340f
            val cardX = w / 2f - cardW / 2f
            val cardY = h / 2f - cardH / 2f

            // Card Body (Dark Obsidian Slate)
            shapeRenderer.setColor(0.07f, 0.09f, 0.14f, 0.96f)
            shapeRenderer.rect(cardX, cardY, cardW, cardH)

            // Outer Slate Border & Top Gold Line
            shapeRenderer.setColor(0.20f, 0.28f, 0.40f, 0.85f)
            shapeRenderer.rectLine(cardX, cardY, cardX + cardW, cardY, 1.5f)
            shapeRenderer.rectLine(cardX, cardY + cardH, cardX + cardW, cardY + cardH, 2f)
            shapeRenderer.rectLine(cardX, cardY, cardX, cardY + cardH, 1.5f)
            shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW, cardY + cardH, 1.5f)

            shapeRenderer.setColor(0.92f, 0.76f, 0.25f, 0.95f)
            shapeRenderer.rectLine(cardX + 20f, cardY + cardH - 2f, cardX + cardW - 20f, cardY + cardH - 2f, 3f)

            // Calligraphic Corner Notches
            val notch = 12f
            shapeRenderer.setColor(0.95f, 0.80f, 0.30f, 0.95f)
            shapeRenderer.rectLine(cardX, cardY + cardH, cardX + notch, cardY + cardH, 2.5f)
            shapeRenderer.rectLine(cardX, cardY + cardH, cardX, cardY + cardH - notch, 2.5f)
            shapeRenderer.rectLine(cardX + cardW, cardY + cardH, cardX + cardW - notch, cardY + cardH, 2.5f)
            shapeRenderer.rectLine(cardX + cardW, cardY + cardH, cardX + cardW, cardY + cardH - notch, 2.5f)
            shapeRenderer.rectLine(cardX, cardY, cardX + notch, cardY, 2.5f)
            shapeRenderer.rectLine(cardX, cardY, cardX, cardY + notch, 2.5f)
            shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW - notch, cardY, 2.5f)
            shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW, cardY + notch, 2.5f)

            // Eyebrow Header Capsule Pill di Atas
            val pillW = 280f
            val pillH = 24f
            val pillX = w / 2f - pillW / 2f
            val pillY = h / 2f + 112f
            shapeRenderer.setColor(0.18f, 0.14f, 0.05f, 0.85f)
            shapeRenderer.rect(pillX, pillY, pillW, pillH)
            shapeRenderer.setColor(0.90f, 0.75f, 0.25f, 0.90f)
            shapeRenderer.rectLine(pillX, pillY, pillX + pillW, pillY, 1f)
            shapeRenderer.rectLine(pillX, pillY + pillH, pillX + pillW, pillY + pillH, 1f)
            shapeRenderer.rectLine(pillX, pillY, pillX, pillY + pillH, 1f)
            shapeRenderer.rectLine(pillX + pillW, pillY, pillX + pillW, pillY + pillH, 1f)

            // Tombol 1: Lanjut Menara (Glowing Emerald)
            shapeRenderer.setColor(0.12f, 0.30f, 0.18f, 0.95f)
            shapeRenderer.rect(w / 2f - 290f, h / 2f - 40f, 270f, 50f)
            shapeRenderer.setColor(0.30f, 0.95f, 0.45f, 0.95f)
            shapeRenderer.rectLine(w / 2f - 290f, h / 2f + 10f, w / 2f - 20f, h / 2f + 10f, 2.5f)

            // Tombol 2: Main Ulang (Cyan Slate)
            shapeRenderer.setColor(0.12f, 0.20f, 0.32f, 0.95f)
            shapeRenderer.rect(w / 2f + 20f, h / 2f - 40f, 270f, 50f)
            shapeRenderer.setColor(0.35f, 0.85f, 1f, 0.90f)
            shapeRenderer.rectLine(w / 2f + 20f, h / 2f + 10f, w / 2f + 290f, h / 2f + 10f, 2.5f)

            // Tombol 3: Menu Utama (Dark Slate with Gold line)
            shapeRenderer.setColor(0.14f, 0.12f, 0.18f, 0.95f)
            shapeRenderer.rect(w / 2f - 160f, h / 2f - 110f, 320f, 45f)
            shapeRenderer.setColor(0.90f, 0.75f, 0.25f, 0.90f)
            shapeRenderer.rectLine(w / 2f - 160f, h / 2f - 65f, w / 2f + 160f, h / 2f - 65f, 2.5f)
        }

        // Kotak Prompt Prasasti (Dipindahkan ke Shape Pass agar tidak menginterupsi Batch Pass)
        if (gameStatus == GameStatus.PLAYING && nearbyTabletPrompt != null) {
            val pw = 360f
            val ph = 36f
            val px = (w - pw) / 2f
            val py = 135f
            shapeRenderer.setColor(0.08f, 0.12f, 0.18f, 0.90f)
            shapeRenderer.rect(px, py, pw, ph)
            shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.90f)
            shapeRenderer.rectLine(px, py + ph, px + pw, py + ph, 2f)
        }

        // Kotak Prompt Altar Pengorbanan Darah (Fase 22)
        if (gameStatus == GameStatus.PLAYING && nearbyAltarPrompt && currentFloor.bloodAltar != null && !currentFloor.bloodAltar!!.isActivated) {
            val pw = 420f
            val ph = 38f
            val px = (w - pw) / 2f
            val py = if (nearbyTabletPrompt != null) 180f else 135f
            shapeRenderer.setColor(0.12f, 0.05f, 0.08f, 0.92f)
            shapeRenderer.rect(px, py, pw, ph)
            shapeRenderer.setColor(0.95f, 0.15f, 0.20f, 0.90f)
            shapeRenderer.rectLine(px, py + ph, px + pw, py + ph, 2f)
            shapeRenderer.rectLine(px, py, px + pw, py, 1.5f)
        }

        // Kotak Prompt Altar Prisma Triad Tag-Team (Fase 28)
        if (gameStatus == GameStatus.PLAYING && nearbyPrismPrompt && currentFloor.prismAltar != null) {
            val pw = 440f
            val ph = 38f
            val px = (w - pw) / 2f
            val py = if (nearbyAltarPrompt || nearbyTabletPrompt != null) 180f else 135f
            shapeRenderer.setColor(0.10f, 0.12f, 0.18f, 0.92f)
            shapeRenderer.rect(px, py, pw, ph)
            shapeRenderer.setColor(0.35f, 0.75f, 1.0f, 0.90f)
            shapeRenderer.rectLine(px, py + ph, px + pw, py + ph, 2f)
            shapeRenderer.rectLine(px, py, px + pw, py, 1.5f)
        }

        renderActBannerShapes()
        renderAchievementBannerShapes()

        if (gameStatus == GameStatus.PLAYING && gameMode == GameMode.STORY && !isPaused) {
            questCompass.renderShapes(shapeRenderer, hudAnimTime)
        }

        shapeRenderer.end()
    }

    private fun renderHUDText() {
        val w = 1280f
        val h = 720f
        val expPercent = (player.stats.currentExp.toFloat() / player.stats.requiredExp.toFloat()).coerceIn(0f, 1f)
        val boss = currentFloor.boss

        // Level Badge Text
        val smallF = FontManager.smallFont
        val regF = FontManager.regularFont
        val headF = FontManager.headerFont

        smallF.setColor(0.7f, 0.85f, 1f, 1f)
        smallF.draw(batch, "LVL", 32f, h - 28f)
        headF.color = Color.WHITE
        headF.draw(batch, "${player.stats.level}", 34f, h - 50f)

        // HP (Integritas Anima) Overlay Text
        smallF.color = Color.WHITE
        smallF.draw(batch, "ANIMA: ${player.health.currentHp.toInt()} / ${player.health.maxHp.toInt()}", 86f, h - 22f)

        // EXP (Rekoleksi Memori) Overlay Text
        smallF.setColor(0.85f, 0.95f, 1f, 1f)
        val expPctText = (expPercent * 100).toInt()
        smallF.draw(batch, "MEMORI: ${player.stats.currentExp}/${player.stats.requiredExp} ($expPctText%)", 86f, h - 42f)

        // Ultimate (Resonansi Tinta) Text
        if (player.ultimate.isReady) smallF.color = Color.GOLD else smallF.color = Color.WHITE
        val ultStatus = if (player.ultimate.isReady) "READY [O]" else "${(player.ultimate.energyPercent * 100).toInt()}%"
        smallF.draw(batch, "RESONANSI: $ultStatus", 86f, h - 58f)

        // Stats Bar & Coins (Pecahan Aethel)
        regF.color = Color.GOLD
        regF.draw(batch, "❖ ${player.stats.gold} Pecahan Aethel", 15f, h - 100f)
        regF.setColor(0.8f, 0.85f, 0.9f, 1f)
        val atkBonusStr = if (player.stats.weaponAtkBonus > 0f) " (+${player.stats.weaponAtkBonus.toInt()})" else ""
        regF.draw(batch, "ATK: ${player.stats.attackPower.toInt()}$atkBonusStr | DEF: ${player.stats.defense.toInt()} | CRIT: ${(player.stats.critRate * 100).toInt()}%", 210f, h - 100f)

        // Active Relics Display
        if (relicManager.activeRelics.isNotEmpty()) {
            val relicStr = relicManager.activeRelics.joinToString("  ") { "${it.iconRune} ${it.title}" }
            smallF.setColor(0.3f, 0.85f, 1f, 1f)
            smallF.draw(batch, "RELICS: $relicStr", 15f, h - 122f)
        }

        // Status Roh Pendamping Tinta (Fase 21)
        if (inkFamiliar.type != FamiliarType.NONE) {
            smallF.setColor(inkFamiliar.type.primaryColor)
            smallF.draw(batch, "ROH: ✦ ${inkFamiliar.type.displayName} (${inkFamiliar.type.subtitle})", 15f, h - 138f)
        }

        // Morale Surge Buff Indicator (Fase 18)
        if (currentFloorNumber == 7 && activeMoraleBuff != MoraleBuffType.NONE) {
            val buffColor = if (activeMoraleBuff == MoraleBuffType.KINETIC_SURGE) Color(1.0f, 0.65f, 0.25f, 1f) else Color(0.35f, 0.85f, 1.0f, 1f)
            smallF.setColor(buffColor)
            smallF.draw(batch, "✦ MORALE SURGE: ${activeMoraleBuff.displayName} (${activeMoraleBuff.effectDescription})", 15f, h - 140f)
        }

        // Tower Whispers Ambient Monologue (Fase 18) - Center-wrapped to avoid Quest Tracker collision
        if (towerWhisperManager.isWhisperActive && towerWhisperManager.whisperAlpha > 0.01f) {
            val whisper = towerWhisperManager.currentWhisper ?: ""
            val alpha = towerWhisperManager.whisperAlpha
            regF.setColor(0.85f, 0.92f, 1.0f, alpha * 0.90f)
            val maxWhisperWidth = 500f
            val wx = (w - maxWhisperWidth) / 2f
            val wy = 620f
            regF.draw(batch, whisper, wx, wy, maxWhisperWidth, com.badlogic.gdx.utils.Align.center, true)
        }

        // Floor Name Banner
        headF.color = Color.CYAN
        headF.draw(batch, currentFloor.floorName, 320f, h - 70f)

        if (saveData.activeTitle.isNotEmpty() && gameMode != GameMode.BOSS_RUSH) {
            val knightTitle = com.stickman.tower.bossrush.BossRushManager.getTitleById(saveData.activeTitle)
            smallF.setColor(knightTitle.color.r, knightTitle.color.g, knightTitle.color.b, 0.9f)
            smallF.draw(batch, "✦ Gelar: \"${knightTitle.titleName}\"", 320f, h - 86f)
        }

        // Combo Step Indicator dengan Pop Bounce
        val comboText = when (player.comboManager.currentStep) {
            ComboStep.HIT_1 -> "COMBO: [HIT 1]"
            ComboStep.HIT_2 -> "COMBO: [HIT 2]"
            ComboStep.HIT_3 -> "COMBO: [HIT 3 FINISHER!]"
        }
        when (player.comboManager.currentStep) {
            ComboStep.HIT_1 -> regF.setColor(1f, 0.92f, 0.2f, 1f)
            ComboStep.HIT_2 -> regF.setColor(1f, 0.62f, 0.12f, 1f)
            ComboStep.HIT_3 -> regF.setColor(1f, 0.25f, 0.25f, 1f)
        }
        if (comboPopTimer > 0f) {
            val bounce = 1.0f + (comboPopTimer / 0.28f) * 0.25f
            regF.data.setScale(bounce)
        }
        regF.draw(batch, comboText, 320f, h - 20f)
        if (comboPopTimer > 0f) {
            regF.data.setScale(1.0f)
        }

        // Skill & Dodge Status
        if (player.skill1.isReady) regF.setColor(0.85f, 0.45f, 1f, 1f) else regF.color = Color.GRAY
        val skillStatus = if (player.skill1.isReady) "READY" else {
            val t = (player.skill1.remainingCooldown * 10).toInt().coerceAtLeast(0)
            "${t / 10}.${t % 10}s"
        }
        regF.draw(batch, "Skill [U]: $skillStatus", 320f, h - 45f)

        if (player.dodgeCooldown <= 0f) regF.setColor(0.3f, 0.8f, 1f, 1f) else regF.color = Color.GRAY
        val dodgeStatus = if (player.dodgeCooldown <= 0f) "READY" else {
            val t = (player.dodgeCooldown * 10).toInt().coerceAtLeast(0)
            "${t / 10}.${t % 10}s"
        }
        regF.draw(batch, "Dodge [L/Shift]: $dodgeStatus", 490f, h - 45f)

        // Teks Tombol Pause
        regF.color = Color.WHITE
        regF.draw(batch, "PAUSE", w - 88f, h - 23f)

        if (gameStatus == GameStatus.PLAYING && gameMode == GameMode.STORY && !isPaused) {
            questCompass.renderText(batch, headF, regF, smallF)
        }

        // Teks Bar Boss
        if (boss != null && !boss.health.isDead) {
            if (boss.isPhase2) regF.setColor(1f, 0.65f, 0.35f, 1f) else regF.color = Color.WHITE
            val enrageTag = if (boss.isPhase2) " ❖ ENRAGED FASE 2 ❖" else ""
            val hpDisplay = if (isBossIntroActive) (bossHpBarAnimated * boss.health.maxHp).toInt() else boss.health.currentHp.toInt()
            regF.draw(batch, "☠ ${boss.name} [$hpDisplay/${boss.health.maxHp.toInt()}]$enrageTag", w / 2f - 180f, h - 14f)
        }

        // Notifikasi Auto-Save
        if (saveNotificationTimer > 0f) {
            smallF.color = Color.WHITE
            smallF.draw(batch, "✓ $saveNotificationText", w / 2f - 90f, h - 20f)
        }

        // Mutator Badge Text
        if (gameMode == GameMode.ENDLESS && activeMutator != FloorMutator.NONE) {
            val mutatorBadge = "${activeMutator.iconRune} MUTATOR: ${activeMutator.displayName}"
            regF.color = Color.ORANGE
            regF.draw(batch, mutatorBadge, w / 2f - 130f, h - 76f)
            smallF.setColor(0.9f, 0.9f, 0.9f, 0.85f)
            smallF.draw(batch, activeMutator.description, w / 2f - 230f, h - 94f)
        }

        // Gauntlet of Sovereigns Badge Text (Fase 23)
        if (gameMode == GameMode.BOSS_RUSH) {
            val stageName = when (bossRushStage) {
                1 -> "Penjaga Gerbang Purba (F3)"
                2 -> "Matron Amethyst (F5)"
                3 -> "Bayangan Doppelgänger (F8)"
                4 -> "Crimson Sovereign (F9)"
                5 -> "Sang Kaligrafer Agung (F10)"
                else -> "Boss Rush"
            }
            val gauntletText = "⚔ GAUNTLET: TAHAP $bossRushStage / 5   ⏱ ${String.format("%.1f", bossRushTimer)}s"
            regF.color = Color.GOLD
            glyphLayout.setText(regF, gauntletText)
            regF.draw(batch, gauntletText, (w - glyphLayout.width) / 2f, h - 76f)

            val activeTitleHero = if (saveData.activeTitle.isNotEmpty()) BossRushManager.getTitleById(saveData.activeTitle).titleName else ""
            val titleText = if (activeTitleHero.isNotEmpty()) "\"$activeTitleHero\" | $stageName" else stageName
            smallF.setColor(0.85f, 0.92f, 1f, 0.9f)
            glyphLayout.setText(smallF, titleText)
            smallF.draw(batch, titleText, (w - glyphLayout.width) / 2f, h - 94f)
        }

        // Overlays Game Over / Victory
        if (gameStatus == GameStatus.GAME_OVER) {
            headF.setColor(1f, 0.25f, 0.25f, 1f)
            headF.draw(batch, "=== PELARUTAN JIWA (DEFEAT) ===", w / 2f - 165f, h / 2f + 65f)
            regF.setColor(0.9f, 0.9f, 0.95f, 1f)
            regF.draw(batch, "Anima ksatria terlarut ke dalam tinta hitam! Sentuh tombol di bawah atau ketuk layar:", w / 2f - 290f, h / 2f + 20f)

            // Tombol Teks
            headF.color = Color.WHITE
            val respawnLabel = if (gameMode == GameMode.BOSS_RUSH) "ULANGI GAUNTLET (R)" else "BANGKIT KEMBALI (R)"
            headF.draw(batch, respawnLabel, w / 2f - 200f, h / 2f - 42f)
            headF.setColor(0.9f, 0.95f, 1f, 1f)
            headF.draw(batch, "MENU UTAMA", w / 2f + 70f, h / 2f - 42f)
        }

        if (gameStatus == GameStatus.STAGE_CLEAR) {
            val isStory = gameMode == GameMode.STORY
            val isBossRush = gameMode == GameMode.BOSS_RUSH

            // 1. Eyebrow Tag Pill Text (Kapsul Header di Atas)
            val eyebrowTag = when {
                isBossRush -> "✦ GAUNTLET DITAKLUKKAN ✦"
                isStory -> if (currentFloorNumber < 10) "✦ LANTAI $currentFloorNumber SELESAI ✦" else "✦ TOWER CONQUERED ✦"
                else -> "✦ ENDLESS TOWER CLEARED ✦"
            }
            smallF.setColor(1f, 0.85f, 0.30f, 1f)
            smallF.draw(batch, eyebrowTag, w / 2f - 140f, h / 2f + 129f, 280f, Align.center, false)

            // 2. Main Title (Nama Tahap / Lantai Mewah)
            headF.color = Color.GOLD
            val mainTitle = when {
                isBossRush -> {
                    val rank = BossRushRank.fromTime(bossRushTimer)
                    "BALAIRUNG LEGENDA: RANK [${rank.badgeSymbol}]"
                }
                isStory -> {
                    if (currentFloorNumber < 10) currentFloor.floorName.uppercase()
                    else "KANVAS SEMESTA TERBEBASKAN!"
                }
                else -> "ENDLESS FLOOR $currentFloorNumber"
            }
            headF.draw(batch, mainTitle, w / 2f - 330f, h / 2f + 92f, 660f, Align.center, false)

            // 3. Subtitle / Deskripsi Hasil Pertarungan
            regF.setColor(0.88f, 0.92f, 0.98f, 1f)
            val subText = when {
                isBossRush -> {
                    val rank = BossRushRank.fromTime(bossRushTimer)
                    val titleName = if (rank.titleRewardId != null) BossRushManager.getTitleById(rank.titleRewardId).titleName else "Pejuang Menara"
                    val rankReward = if (rank.goldReward > 0) " | +${rank.goldReward} GOLD" else ""
                    "Waktu: ${String.format("%.2f", bossRushTimer)}s • Gelar: \"$titleName\"$rankReward"
                }
                isStory -> {
                    if (currentFloorNumber < 10) "Musuh telah dibersihkan! Bersiap untuk pendakian lantai berikutnya."
                    else "Sang Penulis Takdir tumbang! Pecahnya pena membuka dimensi Endless Spire."
                }
                else -> {
                    val talentPtText = if (currentFloorNumber % 2 == 0) " | +1 TALENT POINT!" else ""
                    "Kills: $endlessEnemiesKilled • Waktu: ${endlessSurvivalTime.toInt()}s$talentPtText"
                }
            }
            regF.draw(batch, subText, w / 2f - 330f, h / 2f + 48f, 660f, Align.center, false)

            val nextFloorNumber = if (isStory && currentFloorNumber >= 10) 11 else currentFloorNumber + 1
            val nextFloorLabel = when {
                isBossRush -> "ARENA GAUNTLET"
                isStory && currentFloorNumber >= 10 -> "ENDLESS SPIRE (F11)"
                else -> "LANTAI $nextFloorNumber"
            }

            // 4. Tombol Baris 1: Lanjut Menara
            headF.color = Color.WHITE
            headF.draw(batch, "LANJUT ($nextFloorLabel)", w / 2f - 290f, h / 2f - 8f, 270f, Align.center, false)

            // 5. Tombol Baris 1: Main Ulang
            headF.setColor(0.85f, 0.95f, 1f, 1f)
            headF.draw(batch, "MAIN ULANG (R)", w / 2f + 20f, h / 2f - 8f, 270f, Align.center, false)

            // 6. Tombol Baris 2: Menu Utama
            headF.setColor(0.95f, 0.80f, 0.30f, 1f)
            headF.draw(batch, "MENU UTAMA (ESC)", w / 2f - 160f, h / 2f - 80f, 320f, Align.center, false)
        }

        if (gameStatus == GameStatus.PLAYING) {
            nearbyTabletPrompt?.let { tablet ->
                val promptText = if (tablet.isRead) "[E] / [TAP] BACA ULANG PRASASTI" else "✦ [E] / [TAP] BACA PRASASTI KUNO ✦"
                glyphLayout.setText(regF, promptText)
                val pw = glyphLayout.width + 30f
                val ph = 36f
                val px = (w - pw) / 2f
                val py = 135f

                regF.color = Color.GOLD
                regF.draw(batch, promptText, px + (pw - glyphLayout.width) / 2f, py + 25f)

                if (Gdx.input.justTouched()) {
                    uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                    uiViewport.unproject(uiTouchVec)
                    if (uiTouchVec.x in px..(px + pw) && uiTouchVec.y in py..(py + ph)) {
                        activeLoreTablet = tablet
                        tablet.isRead = true
                        QuestManager.notifyEvent(ObjectiveType.READ_TABLET, tablet.tabletId)
                        if (!saveData.unlockedLoreTablets.contains(tablet.tabletId)) {
                            saveData.unlockedLoreTablets.add(tablet.tabletId)
                            SaveManager.saveAsync(saveData)
                        }
                        AudioManager.playChest()
                    }
                }
            }

            if (nearbyAltarPrompt && currentFloor.bloodAltar != null && !currentFloor.bloodAltar!!.isActivated) {
                val promptText = "🩸 [E] / [TAP] KORBANKAN ANIMA PADA ALTAR 🩸"
                glyphLayout.setText(regF, promptText)
                val pw = 420f
                val ph = 38f
                val px = (w - pw) / 2f
                val py = if (nearbyTabletPrompt != null) 180f else 135f

                regF.color = Color(1.0f, 0.35f, 0.35f, 1f)
                regF.draw(batch, promptText, px + (pw - glyphLayout.width) / 2f, py + 26f)

                if (Gdx.input.justTouched()) {
                    uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                    uiViewport.unproject(uiTouchVec)
                    if (uiTouchVec.x in px..(px + pw) && uiTouchVec.y in py..(py + ph)) {
                        isInteractingWithAltar = true
                        altarSelectedIndex = 0
                        AudioManager.playChest()
                    }
                }
            }

            // Prompt Teks Altar Prisma Triad Tag-Team (Fase 28)
            if (nearbyPrismPrompt && currentFloor.prismAltar != null) {
                val promptText = "✦ [T] / [E] / [TAP] GANTI HERO (TRIAD TAG-TEAM) ✦"
                glyphLayout.setText(regF, promptText)
                val pw = 440f
                val ph = 38f
                val px = (w - pw) / 2f
                val py = if (nearbyAltarPrompt || nearbyTabletPrompt != null) 180f else 135f

                regF.color = Color(0.40f, 0.85f, 1.0f, 1f)
                regF.draw(batch, promptText, px + (pw - glyphLayout.width) / 2f, py + 26f)

                if (Gdx.input.justTouched()) {
                    uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                    uiViewport.unproject(uiTouchVec)
                    if (uiTouchVec.x in px..(px + pw) && uiTouchVec.y in py..(py + ph)) {
                        val pAltar = currentFloor.prismAltar!!
                        if (pAltar.interactionCooldown <= 0f) {
                            pAltar.interactionCooldown = 0.8f
                            val nextArchetype = pAltar.getNextAvailableArchetype(player.archetype, saveData.unlockedCharacters)
                            if (nextArchetype != player.archetype) {
                                player.switchArchetype(nextArchetype)
                                saveData.selectedArchetype = nextArchetype.name
                                SaveManager.saveAsync(saveData)
                                AudioManager.playLevelUp()
                                particleManager.spawnHitSparks(pAltar.x + pAltar.width / 2f, pAltar.y + pAltar.height / 2f, count = 25, color = Color.GOLD)
                                cameraManager.shake(0.3f, 0.2f)
                                val heroTitle = when (nextArchetype) {
                                    CharacterArchetype.BALANCED -> "KAELEN (PEWARIS BARA EMAS)"
                                    CharacterArchetype.AGILE -> "ZEPHYR (THE PHANTOM STRIDER)"
                                    CharacterArchetype.HEAVY -> "GORGON (THE IRONBREAKER)"
                                }
                                floatingTexts.add(
                                    FloatingText("✦ TRIAD SWAP: $heroTitle ✦", pAltar.x - 1.5f, pAltar.y + pAltar.height + 0.8f, Color.GOLD, duration = 3.0f)
                                )
                            }
                        }
                    }
                }
            }

            // Tampilkan Lencana Pakta Temporal Aktif di HUD
            if (activeTemporalPact != TemporalPact.NONE) {
                smallF.setColor(activeTemporalPact.primaryColor)
                smallF.draw(batch, "🩸 PAKTA: ${activeTemporalPact.displayName.uppercase()}", 130f, h - 85f)
            }
        }

        renderAchievementBannerText()
        renderActBannerText()
    }

    private fun handleDevToolsInput() {
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) ||
            Gdx.input.isKeyJustPressed(Keys.F1) ||
            Gdx.input.isKeyJustPressed(Keys.F3) ||
            Gdx.input.isKeyJustPressed(Keys.GRAVE) ||
            Gdx.input.isKeyJustPressed(Keys.BACK) ||
            input.gamepad.isPauseJustPressed()
        ) {
            devTools.isVisible = false
            AudioManager.playSlashLight()
            inputCooldown = 0.20f
            return
        }

        if (Gdx.input.justTouched()) {
            val handled = devTools.handleTouchDown(Gdx.input.x, Gdx.input.y, uiViewport, currentFloor, player)
            if (handled) {
                inputCooldown = 0.15f
            }
        }
    }

    private fun handlePauseInput() {
        if (inputCooldown > 0f) return

        if (Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.ESCAPE) || input.isPauseJustPressed()) {
            isPaused = false
            AudioManager.resumeBgm()
            AudioManager.playSlashLight()
            inputCooldown = 0.20f
            return
        }

        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W) || input.gamepad.isUpJustPressed()) {
            pauseSelectedIndex = (pauseSelectedIndex - 1 + pauseMenuItems.size) % pauseMenuItems.size
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S) || input.gamepad.isDownJustPressed()) {
            pauseSelectedIndex = (pauseSelectedIndex + 1) % pauseMenuItems.size
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE) || input.isJumpJustPressed() || input.isAttackJustPressed()) {
            executePauseSelection()
        }

        if (Gdx.input.justTouched()) {
            uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            uiViewport.unproject(uiTouchVec)
            val touchX = uiTouchVec.x
            val touchY = uiTouchVec.y
            val w = 1280f
            val h = 720f
            val cardW = 390f
            val cardH = 540f
            val cardX = (w - cardW) / 2f
            val cardY = (h - cardH) / 2f
            val startY = cardY + cardH - 75f
            val itemH = 32f
            val itemSpacing = 37f
            val itemW = cardW - 50f
            val btnX = cardX + 25f

            for (i in pauseMenuItems.indices) {
                val btnY = startY - (i * itemSpacing)
                if (touchX in (btnX - 10f)..(btnX + itemW + 10f) && touchY in (btnY - 3f)..(btnY + itemH + 3f)) {
                    pauseSelectedIndex = i
                    executePauseSelection()
                    break
                }
            }
        }
    }

    private fun executePauseSelection() {
        when (pauseSelectedIndex) {
            0 -> { // Resume
                isPaused = false
                AudioManager.resumeBgm()
                AudioManager.playSlashLight()
            }
            1 -> { // Restart Floor
                isPaused = false
                loadFloor(currentFloorNumber)
                AudioManager.playSlashLight()
            }
            2 -> { // Blacksmith Forge
                AudioManager.playSlashLight()
                if (game != null) {
                    (game as? StickmanGame)?.preserveScreen(this)
                    game.setScreen(BlacksmithScreen(game, this))
                }
            }
            3 -> { // Talent Tree (Fase 13)
                AudioManager.playSlashLight()
                if (game != null) {
                    (game as? StickmanGame)?.preserveScreen(this)
                    game.setScreen(TalentTreeScreen(game, this))
                }
            }
            4 -> { // Bestiarium Menara (Fase 19)
                AudioManager.playSlashLight()
                isViewingBestiary = true
                bestiarySelectedIndex = 0
            }
            5 -> { // Ganti Roh Pendamping Tinta (Fase 21)
                val available = FamiliarType.values().filter { saveData.unlockedFamiliars.contains(it.id) || it == FamiliarType.NONE }
                val currIdx = available.indexOf(inkFamiliar.type)
                val nextType = available[(if (currIdx >= 0) currIdx + 1 else 0) % available.size]
                inkFamiliar.type = nextType
                saveData.selectedFamiliar = nextType.id
                SaveManager.save(saveData)
                AudioManager.playLevelUp()
                floatingTexts.add(
                    FloatingText("ROH: ${nextType.displayName}", player.position.x + player.width / 2f, player.position.y + player.height + 0.8f, nextType.primaryColor, duration = 2.0f)
                )
            }
            6 -> { // Control Settings (Fase 12)
                AudioManager.playSlashLight()
                if (game != null) {
                    (game as? StickmanGame)?.preserveScreen(this)
                    game.setScreen(ControlSettingsScreen(game, this))
                }
            }
            7 -> { // Toggle Audio
                AudioManager.toggleMute()
                if (!AudioManager.isMuted) AudioManager.playChest()
            }
            8 -> { // Toggle Haptic
                HapticManager.toggle()
                AudioManager.playSlashLight()
            }
            9 -> { // Developer Tools & Profiler (Tools Architecture)
                isPaused = false
                devTools.isVisible = true
                AudioManager.playSlashLight()
            }
            10 -> { // Main Menu
                isPaused = false
                AudioManager.stopBgm()
                AudioManager.playDodge()
                if (game != null) {
                    (game as? StickmanGame)?.releasePreservedScreen(this)
                    game.setScreen(MainMenuScreen(game))
                }
            }
        }
    }

    private fun renderPauseOverlay() {
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // Dimmer background
        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)
        shapeRenderer.setColor(0f, 0f, 0f, 0.75f)
        shapeRenderer.rect(0f, 0f, w, h)

        // Pause Menu Card (Dark Obsidian with Gold Calligraphic Accents)
        val cardW = 390f
        val cardH = 540f
        val cardX = (w - cardW) / 2f
        val cardY = (h - cardH) / 2f

        // Card Main Body
        shapeRenderer.setColor(0.07f, 0.09f, 0.14f, 0.96f)
        shapeRenderer.rect(cardX, cardY, cardW, cardH)

        // Card Outer Border (Subtle Slate Blue)
        shapeRenderer.setColor(0.20f, 0.28f, 0.40f, 0.85f)
        shapeRenderer.rectLine(cardX, cardY, cardX + cardW, cardY, 1.5f)
        shapeRenderer.rectLine(cardX, cardY + cardH, cardX + cardW, cardY + cardH, 2f)
        shapeRenderer.rectLine(cardX, cardY, cardX, cardY + cardH, 1.5f)
        shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW, cardY + cardH, 1.5f)

        // Gilded Top Header Line
        shapeRenderer.setColor(0.92f, 0.76f, 0.25f, 0.95f)
        shapeRenderer.rectLine(cardX + 20f, cardY + cardH - 3f, cardX + cardW - 20f, cardY + cardH - 3f, 3f)

        // Calligraphic Corner Notches (Artisanal Gold Accents)
        val notch = 12f
        shapeRenderer.setColor(0.95f, 0.80f, 0.30f, 0.95f)
        // Top-Left
        shapeRenderer.rectLine(cardX, cardY + cardH, cardX + notch, cardY + cardH, 2.5f)
        shapeRenderer.rectLine(cardX, cardY + cardH, cardX, cardY + cardH - notch, 2.5f)
        // Top-Right
        shapeRenderer.rectLine(cardX + cardW, cardY + cardH, cardX + cardW - notch, cardY + cardH, 2.5f)
        shapeRenderer.rectLine(cardX + cardW, cardY + cardH, cardX + cardW, cardY + cardH - notch, 2.5f)
        // Bottom-Left
        shapeRenderer.rectLine(cardX, cardY, cardX + notch, cardY, 2.5f)
        shapeRenderer.rectLine(cardX, cardY, cardX, cardY + notch, 2.5f)
        // Bottom-Right
        shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW - notch, cardY, 2.5f)
        shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW, cardY + notch, 2.5f)

        // Button Pills Layout
        val startY = cardY + cardH - 75f
        val itemH = 32f
        val itemSpacing = 37f
        val itemW = cardW - 50f
        val btnX = cardX + 25f

        // Render Button Containers
        for (i in pauseMenuItems.indices) {
            val btnY = startY - (i * itemSpacing)
            if (i == pauseSelectedIndex) {
                // Active Selected Button: Sapphire Glow + Gilded Side Brackets
                shapeRenderer.setColor(0.15f, 0.36f, 0.65f, 0.90f)
                shapeRenderer.rect(btnX, btnY, itemW, itemH)

                // Gold Accent Line on top & bottom of selected pill
                shapeRenderer.setColor(0.95f, 0.80f, 0.30f, 0.95f)
                shapeRenderer.rectLine(btnX, btnY, btnX + 5f, btnY + itemH, 3f)
                shapeRenderer.rectLine(btnX + itemW - 5f, btnY + itemH, btnX + itemW, btnY, 3f)
            } else {
                // Inactive Button: Subtle Dark Slate Capsule
                shapeRenderer.setColor(0.04f, 0.06f, 0.10f, 0.65f)
                shapeRenderer.rect(btnX, btnY, itemW, itemH)
                shapeRenderer.setColor(0.15f, 0.22f, 0.32f, 0.45f)
                shapeRenderer.rectLine(btnX, btnY, btnX + itemW, btnY, 1f)
            }
        }

        // Footer Hint Capsule Pill
        shapeRenderer.setColor(0.04f, 0.06f, 0.10f, 0.85f)
        shapeRenderer.rect(cardX + 20f, cardY + 12f, cardW - 40f, 26f)
        shapeRenderer.setColor(0.18f, 0.25f, 0.38f, 0.65f)
        shapeRenderer.rectLine(cardX + 20f, cardY + 12f, cardX + cardW - 20f, cardY + 12f, 1f)
        shapeRenderer.rectLine(cardX + 20f, cardY + 38f, cardX + cardW - 20f, cardY + 38f, 1f)

        shapeRenderer.end()

        batch.projectionMatrix = uiCamera.combined
        batch.begin()
        val regF = FontManager.regularFont
        val headF = FontManager.headerFont
        val smallF = FontManager.smallFont

        // Header Title
        headF.color = Color.GOLD
        headF.draw(batch, "JEDA PERMAINAN", cardX, cardY + cardH - 18f, cardW, Align.center, false)

        for (i in pauseMenuItems.indices) {
            val itemText = when (i) {
                5 -> "ROH: ${inkFamiliar.type.displayName.take(14)}"
                7 -> if (AudioManager.isMuted) "AUDIO: MUTED" else "AUDIO: ON"
                8 -> if (HapticManager.isEnabled) "HAPTIC: ON" else "HAPTIC: OFF"
                else -> pauseMenuItems[i]
            }
            val btnY = startY - (i * itemSpacing)
            val textY = btnY + itemH / 2f + 6f
            if (i == pauseSelectedIndex) {
                regF.color = Color.YELLOW
                regF.draw(batch, "• $itemText •", btnX, textY, itemW, Align.center, false)
            } else {
                regF.setColor(0.82f, 0.87f, 0.94f, 1f)
                regF.draw(batch, itemText, btnX, textY, itemW, Align.center, false)
            }
        }

        // Petunjuk kontrol di footer card
        smallF.setColor(0.65f, 0.75f, 0.90f, 0.85f)
        smallF.draw(batch, "[W/S / TAP] Pilih • [ENTER / SPACE] Konfirmasi", cardX, cardY + 29f, cardW, Align.center, false)

        batch.end()
    }

    private fun handleBestiaryInput() {
        val entries = BestiaryManager.ENTRIES
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) ||
            Gdx.input.isKeyJustPressed(Keys.B) ||
            Gdx.input.isKeyJustPressed(Keys.BACKSPACE) ||
            Gdx.input.isKeyJustPressed(Keys.BACK)
        ) {
            isViewingBestiary = false
            AudioManager.playSlashLight()
            return
        }

        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W)) {
            bestiarySelectedIndex = (bestiarySelectedIndex - 1 + entries.size) % entries.size
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S)) {
            bestiarySelectedIndex = (bestiarySelectedIndex + 1) % entries.size
            AudioManager.playJump()
        }

        if (Gdx.input.justTouched()) {
            val touchPoint = Vector3()
            uiViewport.unproject(touchPoint.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f))

            // Klik item list di panel kiri (x: 50..390)
            if (touchPoint.x in 50f..390f) {
                for (i in entries.indices) {
                    val bY = 560f - (i * 72f)
                    if (touchPoint.y in (bY - 10f)..(bY + 54f)) {
                        bestiarySelectedIndex = i
                        AudioManager.playJump()
                        break
                    }
                }
            }

            // Klik tombol tutup / kembali di kanan atas atau kiri bawah
            if (touchPoint.x in 1100f..1230f && touchPoint.y in 640f..700f) {
                isViewingBestiary = false
                AudioManager.playSlashLight()
            }
        }
    }

    private fun renderBestiaryOverlay() {
        val w = 1280f
        val h = 720f
        val entries = BestiaryManager.ENTRIES
        if (entries.isEmpty()) return

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Dim background (Tinggi untuk isolasi visual penuh dari gameplay)
        shapeRenderer.setColor(0.04f, 0.05f, 0.08f, 0.98f)
        shapeRenderer.rect(0f, 0f, w, h)

        // Top Header Banner
        shapeRenderer.setColor(0.10f, 0.09f, 0.18f, 0.95f)
        shapeRenderer.rect(50f, 635f, 1180f, 65f)
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 1f)
        shapeRenderer.rect(50f, 633f, 1180f, 2f)

        // Tombol Close [X] di Header (Aksen Emas Bertema)
        shapeRenderer.setColor(0.48f, 0.12f, 0.16f, 0.92f)
        shapeRenderer.rect(1140f, 645f, 80f, 45f)
        shapeRenderer.setColor(0.95f, 0.75f, 0.25f, 0.85f)
        shapeRenderer.rectLine(1140f, 645f, 1220f, 645f, 1.5f)
        shapeRenderer.rectLine(1140f, 690f, 1220f, 690f, 1.5f)
        shapeRenderer.rectLine(1140f, 645f, 1140f, 690f, 1.5f)
        shapeRenderer.rectLine(1220f, 645f, 1220f, 690f, 1.5f)

        // Left Panel (Daftar Entitas Monster)
        shapeRenderer.setColor(0.07f, 0.07f, 0.13f, 0.90f)
        shapeRenderer.rect(50f, 50f, 340f, 570f)
        shapeRenderer.setColor(0.20f, 0.20f, 0.35f, 0.80f)
        shapeRenderer.rect(388f, 50f, 2f, 570f)

        // Right Panel (Detail Bestiarium, Lore Aurelius & Taktik Valerius)
        shapeRenderer.setColor(0.07f, 0.07f, 0.13f, 0.90f)
        shapeRenderer.rect(410f, 50f, 820f, 570f)

        // Highlight dan tombol pada Left Panel
        for (i in entries.indices) {
            val entry = entries[i]
            val bY = 560f - (i * 72f)
            val isSelected = (i == bestiarySelectedIndex)

            if (isSelected) {
                shapeRenderer.setColor(0.22f, 0.20f, 0.38f, 1f)
            } else {
                shapeRenderer.setColor(0.11f, 0.11f, 0.18f, 0.85f)
            }
            shapeRenderer.rect(60f, bY, 320f, 62f)

            // Accent bar kiri sesuai warna entitas jika terpilih
            if (isSelected) {
                shapeRenderer.setColor(Color.valueOf(entry.colorHex))
                shapeRenderer.rect(60f, bY, 6f, 62f)
            }
        }

        // Header Card di Right Panel untuk Monster yang Dipilih
        val selected = entries[bestiarySelectedIndex]
        shapeRenderer.setColor(0.12f, 0.12f, 0.22f, 0.95f)
        shapeRenderer.rect(430f, 495f, 780f, 110f)
        shapeRenderer.setColor(Color.valueOf(selected.colorHex))
        shapeRenderer.rect(430f, 495f, 8f, 110f)

        // Preview Siluet Mini Entitas (Vektor Silhouette Preview)
        val previewX = 1145f
        val previewY = 550f
        val entColor = Color.valueOf(selected.colorHex)
        shapeRenderer.setColor(0.05f, 0.06f, 0.10f, 0.95f)
        shapeRenderer.circle(previewX, previewY, 38f)
        shapeRenderer.setColor(entColor.r, entColor.g, entColor.b, 0.85f)
        shapeRenderer.circle(previewX, previewY, 38f)
        shapeRenderer.setColor(0.05f, 0.06f, 0.10f, 0.95f)
        shapeRenderer.circle(previewX, previewY, 35f)

        // Ornamen siluet ksatria/monster di dalam lingkaran
        shapeRenderer.setColor(entColor)
        shapeRenderer.circle(previewX, previewY + 12f, 7f)
        shapeRenderer.rectLine(previewX, previewY + 5f, previewX, previewY - 12f, 3f)
        shapeRenderer.rectLine(previewX, previewY - 12f, previewX - 9f, previewY - 24f, 2.5f)
        shapeRenderer.rectLine(previewX, previewY - 12f, previewX + 9f, previewY - 24f, 2.5f)
        shapeRenderer.rectLine(previewX, previewY - 2f, previewX - 14f, previewY + 8f, 2f)
        shapeRenderer.rectLine(previewX, previewY - 2f, previewX + 13f, previewY + 3f, 2f)

        // Card Lore Aurelius
        shapeRenderer.setColor(0.09f, 0.09f, 0.16f, 0.90f)
        shapeRenderer.rect(430f, 315f, 780f, 165f)
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.6f)
        shapeRenderer.rect(430f, 478f, 780f, 2f)

        // Card Taktik Valerius
        shapeRenderer.setColor(0.11f, 0.08f, 0.12f, 0.90f)
        shapeRenderer.rect(430f, 115f, 780f, 185f)
        shapeRenderer.setColor(0.95f, 0.35f, 0.35f, 0.6f)
        shapeRenderer.rect(430f, 298f, 780f, 2f)

        shapeRenderer.end()

        batch.projectionMatrix = uiCamera.combined
        batch.begin()

        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Header Title
        titleF.color = Color.GOLD
        titleF.draw(batch, "BESTIARIUM MENARA AETHEL", 70f, 680f)
        smallF.color = Color.LIGHT_GRAY
        smallF.draw(batch, "Katalog Entitas Gubahan Tinta & Panduan Taktis Perang Valerius  |  [B / ESC] Tutup", 70f, 652f)

        headF.color = Color.WHITE
        headF.draw(batch, "TUTUP", 1155f, 674f)

        // Left Panel Item Labels
        for (i in entries.indices) {
            val entry = entries[i]
            val bY = 560f - (i * 72f)
            val isSelected = (i == bestiarySelectedIndex)
            val kills = BestiaryManager.getKills(saveData, entry.id)

            regF.color = if (isSelected) Color.valueOf(entry.colorHex) else Color.WHITE
            regF.draw(batch, entry.name, 75f, bY + 48f)

            smallF.color = if (isSelected) Color.GOLD else Color.GRAY
            smallF.draw(batch, "${entry.title}  |  Ditumpas: $kills", 75f, bY + 24f)
        }

        // Right Panel Selected Info
        val kills = BestiaryManager.getKills(saveData, selected.id)
        headF.color = Color.valueOf(selected.colorHex)
        headF.draw(batch, selected.name.uppercase(), 455f, 585f)

        regF.color = Color.GOLD
        regF.draw(batch, "${selected.title}   *   Wilayah: ${selected.threatZone}", 455f, 555f)

        smallF.color = Color.CYAN
        smallF.draw(batch, "KELEMAHAN TAKTIS: ${selected.weakness.uppercase()}   |   REKOR PENUMPASAN: $kills JIWA", 455f, 525f)

        // Lore Aurelius Section
        headF.color = Color.GOLD
        headF.draw(batch, "CATATAN HISTORIS AURELIUS:", 445f, 465f)
        regF.color = Color(0.92f, 0.92f, 0.96f, 1f)
        regF.draw(batch, selected.lore, 445f, 435f, 750f, Align.left, true)

        // Tactics Valerius Section
        headF.color = Color(1.0f, 0.45f, 0.45f, 1f)
        headF.draw(batch, "DOKTRIN TEMPUR & TAKTIK VALERIUS:", 445f, 285f)
        regF.color = Color(1.0f, 0.90f, 0.75f, 1f)
        regF.draw(batch, selected.tactics, 445f, 255f, 750f, Align.left, true)

        // Footer Guidance
        smallF.color = Color.YELLOW
        smallF.draw(batch, "[W / S / ATAS / BAWAH] Pilih Entitas   |   [KLIK DAFTAR] Pilih Monster   |   [B / ESC] Kembali ke Medan Pertempuran", 430f, 85f)

        batch.end()
    }

    fun triggerRelicChoice() {
        val available = RelicType.getRandomRelics(3, relicManager.activeRelics)
        if (available.isNotEmpty()) {
            relicOffer = available
            relicSelectedIndex = 0
            isChoosingRelic = true
            AudioManager.playChest()
            HapticManager.vibrateMedium()
        }
    }

    private fun handleRelicChoiceInput() {
        if (relicOffer.isEmpty()) {
            isChoosingRelic = false
            return
        }

        if (Gdx.input.isKeyJustPressed(Keys.LEFT) || Gdx.input.isKeyJustPressed(Keys.A)) {
            relicSelectedIndex = (relicSelectedIndex - 1 + relicOffer.size) % relicOffer.size
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.RIGHT) || Gdx.input.isKeyJustPressed(Keys.D)) {
            relicSelectedIndex = (relicSelectedIndex + 1) % relicOffer.size
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.NUM_1) && relicOffer.size >= 1) {
            relicSelectedIndex = 0
            confirmRelicChoice()
        }
        if (Gdx.input.isKeyJustPressed(Keys.NUM_2) && relicOffer.size >= 2) {
            relicSelectedIndex = 1
            confirmRelicChoice()
        }
        if (Gdx.input.isKeyJustPressed(Keys.NUM_3) && relicOffer.size >= 3) {
            relicSelectedIndex = 2
            confirmRelicChoice()
        }
        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE)) {
            confirmRelicChoice()
        }

        if (Gdx.input.justTouched()) {
            uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            uiViewport.unproject(uiTouchVec)

            val total = relicOffer.size
            val cardW = 320f
            val cardH = 340f
            val gap = 40f
            val startX = (1280f - (total * cardW + (total - 1) * gap)) / 2f
            val cardY = (720f - cardH) / 2f - 20f

            for (i in relicOffer.indices) {
                val cx = startX + i * (cardW + gap)
                if (uiTouchVec.x in cx..(cx + cardW) && uiTouchVec.y in cardY..(cardY + cardH)) {
                    relicSelectedIndex = i
                    confirmRelicChoice()
                    break
                }
            }
        }
    }

    private fun confirmRelicChoice() {
        if (relicSelectedIndex in relicOffer.indices) {
            val chosen = relicOffer[relicSelectedIndex]
            relicManager.add(chosen)
            player.maxAirJumps = relicManager.getMaxAirJumps()
            player.airJumpsRemaining = player.maxAirJumps
            player.cooldownMultiplier = relicManager.getCooldownMultiplier()
            floatingTexts.add(
                FloatingText(
                    text = "RELIC ACQUIRED: ${chosen.title}!",
                    worldX = player.position.x,
                    worldY = player.position.y + player.height + 1.2f,
                    color = Color.GOLD,
                    duration = 2.5f
                )
            )
            isChoosingRelic = false
        }
    }

    private fun renderRelicChoiceOverlay() {
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Dimmer background
        shapeRenderer.setColor(0f, 0f, 0f, 0.85f)
        shapeRenderer.rect(0f, 0f, w, h)

        // Sanctum Header Box
        shapeRenderer.setColor(0.08f, 0.11f, 0.18f, 0.95f)
        shapeRenderer.rect(140f, 570f, 1000f, 90f)
        shapeRenderer.setColor(0.3f, 0.85f, 1f, 0.85f)
        shapeRenderer.rectLine(140f, 570f, 1140f, 570f, 2.5f)

        val total = relicOffer.size
        val cardW = 320f
        val cardH = 340f
        val gap = 40f
        val startX = (w - (total * cardW + (total - 1) * gap)) / 2f
        val cardY = (h - cardH) / 2f - 30f

        for (i in relicOffer.indices) {
            val cx = startX + i * (cardW + gap)
            val isSelected = i == relicSelectedIndex

            // Card body
            if (isSelected) {
                shapeRenderer.setColor(0.12f, 0.18f, 0.28f, 0.95f)
            } else {
                shapeRenderer.setColor(0.07f, 0.09f, 0.14f, 0.90f)
            }
            shapeRenderer.rect(cx, cardY, cardW, cardH)

            // Glowing border
            val pulse = if (isSelected) (sin(hudAnimTime * 6f) + 1f) * 0.15f else 0f
            if (isSelected) {
                shapeRenderer.setColor(0.2f, 0.85f, 1f, 0.85f + pulse)
            } else {
                shapeRenderer.setColor(0.3f, 0.35f, 0.45f, 0.6f)
            }
            val borderThick = if (isSelected) 3f else 1.5f
            shapeRenderer.rectLine(cx, cardY, cx + cardW, cardY, borderThick)
            shapeRenderer.rectLine(cx, cardY + cardH, cx + cardW, cardY + cardH, borderThick)
            shapeRenderer.rectLine(cx, cardY, cx, cardY + cardH, borderThick)
            shapeRenderer.rectLine(cx + cardW, cardY, cx + cardW, cardY + cardH, borderThick)

            // Select button at card bottom
            val btnW = 200f
            val btnH = 42f
            val btnX = cx + (cardW - btnW) / 2f
            val btnY = cardY + 25f
            if (isSelected) {
                shapeRenderer.setColor(0.15f, 0.6f, 0.85f, 0.95f)
            } else {
                shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.8f)
            }
            shapeRenderer.rect(btnX, btnY, btnW, btnH)
            if (isSelected) {
                shapeRenderer.color = Color.CYAN
            } else {
                shapeRenderer.setColor(0.35f, 0.4f, 0.5f, 0.6f)
            }
            shapeRenderer.rectLine(btnX, btnY, btnX + btnW, btnY, 1.5f)
            shapeRenderer.rectLine(btnX, btnY + btnH, btnX + btnW, btnY + btnH, 1.5f)
        }

        shapeRenderer.end()

        batch.projectionMatrix = uiCamera.combined
        batch.begin()
        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont

        titleF.color = Color.CYAN
        titleF.draw(batch, "ANCIENT RELIC SANCTUARY", 180f, 638f)
        regF.setColor(0.85f, 0.9f, 1f, 0.9f)
        regF.draw(batch, "Commune with the Spire: Select one passive relic to augment your ascension", 180f, 600f)

        for (i in relicOffer.indices) {
            val relic = relicOffer[i]
            val cx = startX + i * (cardW + gap)
            val isSelected = i == relicSelectedIndex

            headF.color = if (isSelected) Color.GOLD else Color.WHITE
            val runeTitle = "${relic.iconRune} ${relic.title}"
            glyphLayout.setText(headF, runeTitle)
            headF.draw(batch, runeTitle, cx + (cardW - glyphLayout.width) / 2f, cardY + cardH - 35f)

            regF.setColor(0.80f, 0.85f, 0.95f, 0.9f)
            glyphLayout.setText(regF, relic.description)
            regF.draw(batch, relic.description, cx + 25f, cardY + cardH - 95f, cardW - 50f, 1, true)

            // Tombol pilih
            val btnW = 200f
            val btnY = cardY + 25f
            val btnText = if (isSelected) "⚔  SELECT  ⚔" else "SELECT"
            headF.color = if (isSelected) Color.WHITE else Color.LIGHT_GRAY
            glyphLayout.setText(headF, btnText)
            headF.draw(batch, btnText, cx + (cardW - glyphLayout.width) / 2f, btnY + 28f)
        }

        regF.setColor(0.6f, 0.65f, 0.75f, 0.8f)
        glyphLayout.setText(regF, "[A / D / LEFT / RIGHT / TOUCH] Browse  |  [1 / 2 / 3 / SPACE / ENTER] Claim Relic")
        regF.draw(batch, "[A / D / LEFT / RIGHT / TOUCH] Browse  |  [1 / 2 / 3 / SPACE / ENTER] Claim Relic", (w - glyphLayout.width) / 2f, cardY - 20f)

        batch.end()
    }

    private fun renderBossIntroOverlay() {
        renderBossIntroShapes()
        batch.projectionMatrix = uiCamera.combined
        batch.begin()
        renderBossIntroText()
        batch.end()
    }

    private fun renderBossIntroShapes() {
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Letterbox Bars (Top & Bottom Sinematik)
        val barHeight = 85f
        shapeRenderer.setColor(0f, 0f, 0f, 0.95f)
        shapeRenderer.rect(0f, h - barHeight, w, barHeight)
        shapeRenderer.rect(0f, 0f, w, barHeight)

        // Gold Accent Lines on Letterbox Edge
        shapeRenderer.setColor(0.92f, 0.78f, 0.28f, 0.75f)
        shapeRenderer.rectLine(0f, h - barHeight, w, h - barHeight, 2f)
        shapeRenderer.rectLine(0f, barHeight, w, barHeight, 2f)

        // Title Card Plaque (Center-Lower Obsidian Glassmorphism)
        val cardW = 620f
        val cardH = 100f
        val cardX = (w - cardW) / 2f
        val cardY = 190f
        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.94f)
        shapeRenderer.rect(cardX, cardY, cardW, cardH)

        // Card Border Lines
        shapeRenderer.setColor(0.92f, 0.78f, 0.28f, 0.9f)
        shapeRenderer.rectLine(cardX, cardY, cardX + cardW, cardY, 2.5f)
        shapeRenderer.rectLine(cardX, cardY + cardH, cardX + cardW, cardY + cardH, 2.5f)
        shapeRenderer.rectLine(cardX, cardY, cardX, cardY + cardH, 2f)
        shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW, cardY + cardH, 2f)

        shapeRenderer.end()
    }

    private fun renderBossIntroText() {
        val w = 1280f
        val barHeight = 85f
        val cardH = 100f
        val cardY = 190f

        val titleF = FontManager.titleFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Boss Title in Gold
        val currentBoss = currentFloor.boss
        titleF.setColor(1f, 0.85f, 0.25f, 1f)
        val bossTitle = "⚔ ${currentBoss?.name ?: "BOSS"} ⚔"
        glyphLayout.setText(titleF, bossTitle)
        titleF.draw(batch, bossTitle, (w - glyphLayout.width) / 2f, cardY + cardH - 24f)

        // Boss Subtitle / Lore
        regF.setColor(0.85f, 0.90f, 1f, 0.95f)
        val bossSub = "${currentBoss?.subtitle ?: "Tower Boss"}  •  Lantai $currentFloorNumber"
        glyphLayout.setText(regF, bossSub)
        regF.draw(batch, bossSub, (w - glyphLayout.width) / 2f, cardY + 38f)

        // Skip prompt inside bottom letterbox
        val skipPulse = (sin(hudAnimTime * 6f) + 1f) * 0.5f
        smallF.setColor(0.85f + 0.15f * skipPulse, 0.85f + 0.15f * skipPulse, 0.85f, 0.85f)
        val skipText = "[TOUCH / SPACE / ENTER] Skip Intro"
        glyphLayout.setText(smallF, skipText)
        smallF.draw(batch, skipText, (w - glyphLayout.width) / 2f, barHeight / 2f + 6f)
    }

    private fun handleLoreTabletInput() {
        val tablet = activeLoreTablet ?: return
        if (Gdx.input.isKeyJustPressed(Keys.E) ||
            Gdx.input.isKeyJustPressed(Keys.SPACE) ||
            Gdx.input.isKeyJustPressed(Keys.ENTER) ||
            Gdx.input.isKeyJustPressed(Keys.ESCAPE) ||
            Gdx.input.isKeyJustPressed(Keys.BACK) ||
            input.isAttackJustPressed() ||
            input.isJumpJustPressed() ||
            Gdx.input.justTouched()) {
            tablet.isRead = true
            activeLoreTablet = null
            AudioManager.playSlashLight()
            inputCooldown = 0.2f
        }
    }

    private fun handleStoryDialogueInput() {
        val dialogue = activeStoryDialogue ?: return

        // 1. Pilihan Percabangan Moril Interaktif (Fase 18)
        if (dialogue.isWaitingForChoice) {
            val line = dialogue.currentLine
            if (line != null && line.branchOptions.isNotEmpty()) {
                val boxX = 100f
                val boxY = 40f
                val card1X = boxX + 30f
                val card1Y = boxY + 12f
                val card1W = 500f
                val card1H = 46f

                val card2X = boxX + 550f
                val card2Y = boxY + 12f
                val card2W = 500f
                val card2H = 46f

                var choiceSelected = -1

                if (Gdx.input.isKeyJustPressed(Keys.NUM_1) || Gdx.input.isKeyJustPressed(Keys.NUMPAD_1)) {
                    choiceSelected = 0
                } else if (Gdx.input.isKeyJustPressed(Keys.NUM_2) || Gdx.input.isKeyJustPressed(Keys.NUMPAD_2)) {
                    choiceSelected = 1
                } else if (Gdx.input.justTouched()) {
                    uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
                    uiViewport.unproject(uiTouchVec)
                    if (uiTouchVec.x in card1X..(card1X + card1W) && uiTouchVec.y in card1Y..(card1Y + card1H)) {
                        choiceSelected = 0
                    } else if (uiTouchVec.x in card2X..(card2X + card2W) && uiTouchVec.y in card2Y..(card2Y + card2H)) {
                        choiceSelected = 1
                    }
                }

                if (choiceSelected in line.branchOptions.indices) {
                    dialogue.selectBranch(choiceSelected) { buff ->
                        activeMoraleBuff = buff
                    }
                    AudioManager.playSlashLight()
                    inputCooldown = 0.2f
                }
            }
            return
        }

        // 2. Navigasi Baris Naratif (Typewriter instant reveal atau advance)
        if (Gdx.input.isKeyJustPressed(Keys.E) ||
            Gdx.input.isKeyJustPressed(Keys.SPACE) ||
            Gdx.input.isKeyJustPressed(Keys.ENTER) ||
            input.isAttackJustPressed() ||
            input.isJumpJustPressed() ||
            Gdx.input.justTouched()) {

            if (!dialogue.isCurrentLineCompleted()) {
                dialogue.instantReveal()
            } else {
                val hasNext = dialogue.advance()
                if (!hasNext) {
                    dialogue.isTriggered = true
                    activeStoryDialogue = null
                }
            }
            AudioManager.playSlashLight()
            inputCooldown = 0.2f
        }
    }

    private fun renderLoreTabletOverlay() {
        val tablet = activeLoreTablet ?: return
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Dark dim background
        shapeRenderer.setColor(0f, 0f, 0f, 0.82f)
        shapeRenderer.rect(0f, 0f, w, h)

        // Ancient Obsidian Tablet Plaque
        val boxW = 860f
        val boxH = 460f
        val boxX = (w - boxW) / 2f
        val boxY = (h - boxH) / 2f

        shapeRenderer.setColor(0.08f, 0.10f, 0.16f, 0.96f)
        shapeRenderer.rect(boxX, boxY, boxW, boxH)

        // Ancient Gold Border with pulse
        val pulse = (sin(hudAnimTime * 4f) + 1f) * 0.15f
        shapeRenderer.setColor(0.85f + pulse, 0.70f + pulse, 0.25f, 0.9f)
        val borderThick = 2.5f
        shapeRenderer.rectLine(boxX, boxY, boxX + boxW, boxY, borderThick)
        shapeRenderer.rectLine(boxX, boxY + boxH, boxX + boxW, boxY + boxH, borderThick)
        shapeRenderer.rectLine(boxX, boxY, boxX, boxY + boxH, borderThick)
        shapeRenderer.rectLine(boxX + boxW, boxY, boxX + boxW, boxY + boxH, borderThick)

        // Top Rune Symbol Center Circle
        shapeRenderer.setColor(0.3f, 0.75f, 1f, 0.85f)
        shapeRenderer.circle(w / 2f, boxY + boxH - 45f, 22f, 16)
        shapeRenderer.color = Color.WHITE
        shapeRenderer.circle(w / 2f, boxY + boxH - 45f, 10f, 10)

        // Close Button Bar at bottom
        val btnW = 320f
        val btnH = 42f
        val btnX = (w - btnW) / 2f
        val btnY = boxY + 28f
        shapeRenderer.setColor(0.14f, 0.20f, 0.30f, 0.95f)
        shapeRenderer.rect(btnX, btnY, btnW, btnH)
        shapeRenderer.setColor(0.3f, 0.8f, 1f, 0.85f)
        shapeRenderer.rectLine(btnX, btnY, btnX + btnW, btnY, 1.5f)
        shapeRenderer.rectLine(btnX, btnY + btnH, btnX + btnW, btnY + btnH, 1.5f)

        shapeRenderer.end()

        batch.projectionMatrix = uiCamera.combined
        batch.begin()
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont

        // Header Title
        headF.setColor(1f, 0.85f, 0.3f, 1f)
        glyphLayout.setText(headF, tablet.title)
        headF.draw(batch, tablet.title, (w - glyphLayout.width) / 2f, boxY + boxH - 85f)

        // Tablet Lore Body Text
        regF.setColor(0.90f, 0.92f, 0.98f, 0.96f)
        regF.draw(batch, tablet.text, boxX + 60f, boxY + boxH - 145f, boxW - 120f, Align.left, true)

        // Button Label
        headF.setColor(0.4f, 0.9f, 1f, 1f)
        val closeLabel = "[SPACE / TAP] TUTUP PRASASTI"
        glyphLayout.setText(headF, closeLabel)
        headF.draw(batch, closeLabel, (w - glyphLayout.width) / 2f, btnY + 28f)

        batch.end()
    }

    private fun renderStoryDialogueOverlay() {
        val dialogue = activeStoryDialogue ?: return
        val line = dialogue.currentLine ?: return
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Dialogue Box at screen bottom
        val boxX = 100f
        val boxY = 40f
        val boxW = 1080f
        val boxH = 175f

        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.95f)
        shapeRenderer.rect(boxX, boxY, boxW, boxH)

        // Border colored with speaker color
        shapeRenderer.setColor(line.speakerColor.r, line.speakerColor.g, line.speakerColor.b, 0.9f)
        shapeRenderer.rectLine(boxX, boxY + boxH, boxX + boxW, boxY + boxH, 2.5f)
        shapeRenderer.rectLine(boxX, boxY, boxX + boxW, boxY, 2f)
        shapeRenderer.rectLine(boxX, boxY, boxX, boxY + boxH, 2f)
        shapeRenderer.rectLine(boxX + boxW, boxY, boxX + boxW, boxY + boxH, 2f)

        // Speaker Tag Box (Dynamic sizing based on title length for zero text clipping)
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont
        val speakerTag = "${line.speaker.uppercase()}  •  ${line.title}"
        glyphLayout.setText(headF, speakerTag)
        val tagW = kotlin.math.max(320f, glyphLayout.width + 36f)
        val tagH = 38f
        val tagX = boxX + 25f
        val tagY = boxY + boxH - 6f
        shapeRenderer.setColor(0.12f, 0.16f, 0.24f, 0.98f)
        shapeRenderer.rect(tagX, tagY, tagW, tagH)
        shapeRenderer.setColor(line.speakerColor)
        shapeRenderer.rectLine(tagX, tagY + tagH, tagX + tagW, tagY + tagH, 2.5f)
        shapeRenderer.rectLine(tagX, tagY, tagX, tagY + tagH, 1.5f)
        shapeRenderer.rectLine(tagX + tagW, tagY, tagX + tagW, tagY + tagH, 1.5f)

        // Jika sedang menunggu pilihan percabangan
        if (dialogue.isWaitingForChoice && line.branchOptions.isNotEmpty()) {
            val card1X = boxX + 30f
            val card1Y = boxY + 12f
            val card1W = 500f
            val card1H = 46f

            val card2X = boxX + 550f
            val card2Y = boxY + 12f
            val card2W = 500f
            val card2H = 46f

            // Opsi 1 (Oranye Bara / Vengeance)
            shapeRenderer.setColor(0.12f, 0.14f, 0.22f, 0.95f)
            shapeRenderer.rect(card1X, card1Y, card1W, card1H)
            shapeRenderer.setColor(1.0f, 0.65f, 0.25f, 0.9f)
            shapeRenderer.rectLine(card1X, card1Y + card1H, card1X + card1W, card1Y + card1H, 2f)
            shapeRenderer.rectLine(card1X, card1Y, card1X + card1W, card1Y, 1f)
            shapeRenderer.rectLine(card1X, card1Y, card1X, card1Y + card1H, 1f)
            shapeRenderer.rectLine(card1X + card1W, card1Y, card1X + card1W, card1Y + card1H, 1f)

            // Opsi 2 (Biru Spiritual / Restoration)
            shapeRenderer.setColor(0.12f, 0.14f, 0.22f, 0.95f)
            shapeRenderer.rect(card2X, card2Y, card2W, card2H)
            shapeRenderer.setColor(0.35f, 0.85f, 1.0f, 0.9f)
            shapeRenderer.rectLine(card2X, card2Y + card2H, card2X + card2W, card2Y + card2H, 2f)
            shapeRenderer.rectLine(card2X, card2Y, card2X + card2W, card2Y, 1f)
            shapeRenderer.rectLine(card2X, card2Y, card2X, card2Y + card2H, 1f)
            shapeRenderer.rectLine(card2X + card2W, card2Y, card2X + card2W, card2Y + card2H, 1f)
        }

        shapeRenderer.end()

        batch.projectionMatrix = uiCamera.combined
        batch.begin()

        // Speaker Name
        headF.setColor(line.speakerColor)
        headF.draw(batch, speakerTag, tagX + 18f, tagY + tagH - 12f)

        // Typewriter Revealed Text
        val displayedText = dialogue.getDisplayText()
        regF.setColor(0.95f, 0.96f, 1f, 1f)
        regF.draw(batch, displayedText, boxX + 40f, boxY + boxH - 35f, boxW - 80f, Align.left, true)

        if (dialogue.isWaitingForChoice && line.branchOptions.isNotEmpty()) {
            val card1X = boxX + 30f
            val card1Y = boxY + 12f
            val card2X = boxX + 550f
            val card2Y = boxY + 12f

            smallF.setColor(1.0f, 0.75f, 0.35f, 1f)
            smallF.draw(batch, line.branchOptions[0].promptText, card1X + 16f, card1Y + 30f)

            if (line.branchOptions.size > 1) {
                smallF.setColor(0.45f, 0.90f, 1.0f, 1f)
                smallF.draw(batch, line.branchOptions[1].promptText, card2X + 16f, card2Y + 30f)
            }
        } else {
            // Advance Prompt (Right-aligned with pulsing glow)
            val blink = (sin(hudAnimTime * 6f) + 1f) * 0.5f
            regF.setColor(1f, 0.85f, 0.3f, 0.65f + 0.35f * blink)
            val promptText = if (dialogue.isCurrentLineCompleted()) "LANJUT [TAP / SPACE] ▶" else "LEWATI [TAP / SPACE] ⏩"
            glyphLayout.setText(regF, promptText)
            regF.draw(batch, promptText, boxX + boxW - glyphLayout.width - 32f, boxY + 28f)
        }

        batch.end()
    }

    private fun renderActBannerShapes() {
        if (actBannerTimer <= 0f) return
        val w = 1280f

        val alpha = if (actBannerTimer > 2.8f) {
            (3.5f - actBannerTimer) / 0.7f
        } else if (actBannerTimer < 0.7f) {
            actBannerTimer / 0.7f
        } else {
            1.0f
        }.coerceIn(0f, 1f)

        if (alpha <= 0.01f) return

        // Background banner strip
        val bannerY = 590f
        val bannerH = 85f
        shapeRenderer.setColor(0.04f, 0.06f, 0.10f, 0.80f * alpha)
        shapeRenderer.rect(0f, bannerY, w, bannerH)

        // Golden glow accent lines
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.85f * alpha)
        shapeRenderer.rectLine(0f, bannerY, w, bannerY, 1.5f)
        shapeRenderer.rectLine(0f, bannerY + bannerH, w, bannerY + bannerH, 1.5f)
    }

    private fun renderActBannerText() {
        if (actBannerTimer <= 0f) return
        val w = 1280f

        val alpha = if (actBannerTimer > 2.8f) {
            (3.5f - actBannerTimer) / 0.7f
        } else if (actBannerTimer < 0.7f) {
            actBannerTimer / 0.7f
        } else {
            1.0f
        }.coerceIn(0f, 1f)

        if (alpha <= 0.01f) return

        val bannerY = 590f
        val bannerH = 85f
        val titleF = FontManager.titleFont
        val regF = FontManager.regularFont

        titleF.setColor(1f, 0.85f, 0.3f, alpha)
        val actTitle = currentFloor.actTitle
        glyphLayout.setText(titleF, actTitle)
        titleF.draw(batch, actTitle, (w - glyphLayout.width) / 2f, bannerY + bannerH - 18f)

        regF.setColor(0.75f, 0.85f, 1f, alpha)
        val actSub = currentFloor.actSubtitle
        glyphLayout.setText(regF, actSub)
        regF.draw(batch, actSub, (w - glyphLayout.width) / 2f, bannerY + 28f)
    }

    private fun renderVulcanusNPC(shapeRenderer: ShapeRenderer) {
        val anvilX = 10.5f
        val anvilY = 2.0f
        val vulcanusX = 9.8f
        val vulcanusY = 2.0f

        // Forge Anvil Iron Block
        shapeRenderer.setColor(0.20f, 0.22f, 0.26f, 1f)
        shapeRenderer.rect(anvilX - 0.4f, anvilY, 0.8f, 0.7f)
        shapeRenderer.rect(anvilX - 0.6f, anvilY + 0.5f, 1.2f, 0.25f)

        // Ember Glow on Anvil
        val emberPulse = (sin(hudAnimTime * 4f) + 1f) * 0.5f
        shapeRenderer.setColor(1f, 0.45f + 0.2f * emberPulse, 0.1f, 0.75f)
        shapeRenderer.circle(anvilX, anvilY + 0.76f, 0.14f, 10)

        // Vulcanus Legs
        shapeRenderer.setColor(0.12f, 0.08f, 0.06f, 1f)
        shapeRenderer.rect(vulcanusX - 0.22f, vulcanusY, 0.16f, 0.9f)
        shapeRenderer.rect(vulcanusX + 0.06f, vulcanusY, 0.16f, 0.9f)

        // Torso & Leather Apron
        shapeRenderer.setColor(0.38f, 0.20f, 0.10f, 1f)
        shapeRenderer.rect(vulcanusX - 0.35f, vulcanusY + 0.9f, 0.7f, 1.1f)

        // Head & Headband
        shapeRenderer.setColor(0.15f, 0.12f, 0.10f, 1f)
        shapeRenderer.circle(vulcanusX, vulcanusY + 2.25f, 0.26f, 14)
        shapeRenderer.setColor(1.0f, 0.55f, 0.15f, 1f)
        shapeRenderer.rect(vulcanusX - 0.28f, vulcanusY + 2.22f, 0.56f, 0.08f)

        // Massive Sledgehammer resting on anvil
        shapeRenderer.setColor(0.45f, 0.30f, 0.15f, 1f)
        shapeRenderer.rectLine(vulcanusX + 0.2f, vulcanusY + 1.4f, anvilX, anvilY + 0.8f, 0.08f)
        shapeRenderer.setColor(0.5f, 0.52f, 0.58f, 1f)
        shapeRenderer.rect(anvilX - 0.15f, anvilY + 0.75f, 0.35f, 0.22f)
    }

    private fun renderAriaNPC(shapeRenderer: ShapeRenderer) {
        val ariaX = 2.0f
        val hoverY = 1.6f + sin(hudAnimTime * 3f) * 0.12f
        val pulse = (sin(hudAnimTime * 5f) + 1f) * 0.5f

        // Golden Anima Spirit Aura
        shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.35f + 0.25f * pulse)
        shapeRenderer.circle(ariaX, hoverY, 0.42f, 16)

        // Inner glowing soul sphere
        shapeRenderer.setColor(1f, 0.92f, 0.55f, 0.85f)
        shapeRenderer.circle(ariaX, hoverY, 0.22f, 14)

        // Center white core
        shapeRenderer.color = Color.WHITE
        shapeRenderer.circle(ariaX, hoverY, 0.10f, 10)
    }

    private fun renderAchievementBannerShapes() {
        val banner = activeAchievementBanner ?: return
        val w = 1280f
        val bw = 460f
        val bh = 56f
        val bx = (w - bw) / 2f
        val by = 645f

        // Pill Latar Belakang Glassmorphism
        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.95f)
        shapeRenderer.rect(bx, by, bw, bh)

        // Border Emas Menyala dengan Efek Denyut
        val pulse = kotlin.math.sin(hudAnimTime.toDouble() * 6.0).toFloat() * 0.1f
        shapeRenderer.setColor(0.95f, 0.82f, 0.25f, 0.88f + pulse)
        shapeRenderer.rectLine(bx, by, bx + bw, by, 2f)
        shapeRenderer.rectLine(bx, by + bh, bx + bw, by + bh, 2f)
        shapeRenderer.rectLine(bx, by, bx, by + bh, 3f)
        shapeRenderer.rectLine(bx + bw, by, bx + bw, by + bh, 3f)

        // Badge Kotak Trofi
        shapeRenderer.setColor(0.85f, 0.65f, 0.15f, 0.35f)
        shapeRenderer.rect(bx + 8f, by + 8f, 40f, 40f)
    }

    private fun renderAchievementBannerText() {
        val banner = activeAchievementBanner ?: return
        val w = 1280f
        val bw = 460f
        val bx = (w - bw) / 2f
        val by = 645f

        val headF = FontManager.headerFont
        val regF = FontManager.regularFont

        headF.setColor(1f, 0.88f, 0.25f, 1f)
        headF.draw(batch, "★", bx + 19f, by + 36f)

        headF.setColor(1f, 0.85f, 0.3f, 1f)
        headF.draw(batch, "PRESTASI TERBUKA!", bx + 60f, by + 44f)

        regF.setColor(0.9f, 0.95f, 1f, 1f)
        val textDesc = "${banner.title} (+${banner.goldReward} Gold)"
        regF.draw(batch, textDesc, bx + 60f, by + 22f)
    }

    private fun renderPostProcessingVFX(delta: Float) {
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // 1. Living Canvas Edge Vignette (Bingkai Tinta Naskah Sinematik di 4 Sisi Layar - Engine 10/10)
        val edgeW = 48f
        shapeRenderer.setColor(0.02f, 0.02f, 0.05f, 0.35f)
        shapeRenderer.rect(0f, 0f, w, edgeW) // Bawah
        shapeRenderer.rect(0f, h - edgeW, w, edgeW) // Atas
        shapeRenderer.rect(0f, 0f, edgeW, h) // Kiri
        shapeRenderer.rect(w - edgeW, 0f, edgeW, h) // Kanan

        // Lapisan gradien halus bagian dalam
        shapeRenderer.setColor(0.01f, 0.01f, 0.03f, 0.18f)
        shapeRenderer.rect(edgeW, edgeW, w - edgeW * 2f, 22f)
        shapeRenderer.rect(edgeW, h - edgeW - 22f, w - edgeW * 2f, 22f)
        shapeRenderer.rect(edgeW, edgeW, 22f, h - edgeW * 2f)
        shapeRenderer.rect(w - edgeW - 22f, edgeW, 22f, h - edgeW * 2f)

        // 2. Critical Anima Vignette (Detak Darah Saat HP Kritis <= 25%)
        if (!player.health.isDead && player.health.currentHp <= player.health.maxHp * 0.25f && gameStatus == GameStatus.PLAYING) {
            dangerPulseTimer += delta
            val hpRatio = (player.health.currentHp / (player.health.maxHp * 0.25f)).coerceIn(0f, 1f)
            val urgency = 1f - hpRatio
            val pulse = 0.5f + 0.5f * kotlin.math.sin(dangerPulseTimer * (5f + urgency * 5f))
            val vigAlpha = (0.16f + urgency * 0.26f) * pulse

            shapeRenderer.setColor(0.75f, 0.05f, 0.05f, vigAlpha)
            val edgeThickness = 55f
            shapeRenderer.rect(0f, 0f, w, edgeThickness) // Bottom
            shapeRenderer.rect(0f, h - edgeThickness, w, edgeThickness) // Top
            shapeRenderer.rect(0f, edgeThickness, edgeThickness, h - edgeThickness * 2f) // Left
            shapeRenderer.rect(w - edgeThickness, edgeThickness, edgeThickness, h - edgeThickness * 2f) // Right

            // Inner softer gradient strip
            shapeRenderer.setColor(0.55f, 0.02f, 0.02f, vigAlpha * 0.45f)
            shapeRenderer.rect(edgeThickness, edgeThickness, w - edgeThickness * 2f, 25f)
            shapeRenderer.rect(edgeThickness, h - edgeThickness - 25f, w - edgeThickness * 2f, 25f)
        }

        // 3. Perfect Parry Horizontal Flare (Dentang Penolakan Takdir)
        if (parryFlashTimer > 0f) {
            parryFlashTimer = (parryFlashTimer - delta).coerceAtLeast(0f)
            val flareRatio = (parryFlashTimer / 0.18f).coerceIn(0f, 1f)
            val flareHeight = 6f + 24f * flareRatio
            val flareY = h / 2f - flareHeight / 2f

            shapeRenderer.setColor(1f, 0.95f, 0.65f, flareRatio * 0.85f)
            shapeRenderer.rect(0f, flareY, w, flareHeight)
            shapeRenderer.setColor(1f, 1f, 1f, flareRatio * 0.95f)
            shapeRenderer.rect(0f, h / 2f - 2f, w, 4f)
        }

        // 4. Screen Impact Flash (Whiteout / Gold Super Burst - Engine 10/10)
        if (screenFlashTimer > 0f && screenFlashDuration > 0f) {
            screenFlashTimer = (screenFlashTimer - delta).coerceAtLeast(0f)
            val progress = (screenFlashTimer / screenFlashDuration).coerceIn(0f, 1f)
            val currentAlpha = progress * screenFlashMaxAlpha
            shapeRenderer.setColor(screenFlashR, screenFlashG, screenFlashB, currentAlpha)
            shapeRenderer.rect(0f, 0f, w, h)
        }

        // 5. Ink Screen Dissolve Transition (Transisi Pindah Lantai & Respawn)
        if (floorTransitionAlpha > 0f) {
            floorTransitionAlpha = (floorTransitionAlpha - delta * 2.2f).coerceAtLeast(0f)
            shapeRenderer.setColor(0.04f, 0.04f, 0.06f, floorTransitionAlpha)
            shapeRenderer.rect(0f, 0f, w, h)
        }

        shapeRenderer.end()
    }

    private fun handleBloodAltarInput() {
        // Navigasi Keyboard / Gamepad
        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W)) {
            altarSelectedIndex = (altarSelectedIndex - 1 + 4) % 4
            AudioManager.playParry()
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S)) {
            altarSelectedIndex = (altarSelectedIndex + 1) % 4
            AudioManager.playParry()
        }

        // Batal dengan ESC / BACK
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK)) {
            isInteractingWithAltar = false
            AudioManager.playSlashLight()
            return
        }

        val confirm = Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE) ||
                Gdx.input.isKeyJustPressed(Keys.E) || input.isAttackJustPressed()

        if (confirm) {
            applyAltarSelection(altarSelectedIndex)
            return
        }

        // Navigasi Touch / Mouse Click
        if (Gdx.input.justTouched()) {
            uiTouchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            uiViewport.unproject(uiTouchVec)

            val modalW = 880f
            val modalH = 580f
            val modalX = (1280f - modalW) / 2f
            val modalY = (720f - modalH) / 2f
            val cardW = 820f
            val cardX = modalX + (modalW - cardW) / 2f
            val startY = modalY + modalH - 170f
            val cardH = 86f
            val spacing = 14f

            for (i in 0 until 3) {
                val cardY = startY - i * (cardH + spacing)
                if (uiTouchVec.x in cardX..(cardX + cardW) && uiTouchVec.y in cardY..(cardY + cardH)) {
                    applyAltarSelection(i)
                    return
                }
            }

            // Tombol Batal
            val cancelY = startY - 3 * (cardH + spacing) + 10f
            val cancelH = 50f
            if (uiTouchVec.x in cardX..(cardX + cardW) && uiTouchVec.y in cancelY..(cancelY + cancelH)) {
                applyAltarSelection(3)
                return
            }
        }
    }

    private fun applyAltarSelection(index: Int) {
        if (index == 3) {
            isInteractingWithAltar = false
            AudioManager.playSlashLight()
            return
        }

        val chosenPact = when (index) {
            0 -> TemporalPact.CARNAGE
            1 -> TemporalPact.GREED
            2 -> TemporalPact.SWIFTNESS
            else -> TemporalPact.NONE
        }

        if (chosenPact != TemporalPact.NONE) {
            val sacrificeHp = (player.health.currentHp * 0.25f).coerceAtLeast(1f)
            player.health.consumeHp(sacrificeHp)
            activeTemporalPact = chosenPact
            currentFloor.bloodAltar?.isActivated = true
            currentFloor.bloodAltar?.activePact = chosenPact
            refreshPlayerModifiers()
            isInteractingWithAltar = false

            AudioManager.playLevelUp()
            HapticManager.vibrateHeavy()
            input.gamepad.vibrate(250, 0.9f)
            particleManager.spawnHitSparks(
                player.position.x + player.width / 2f,
                player.position.y + player.height / 2f,
                count = 32,
                color = chosenPact.primaryColor
            )
            floatingTexts.add(
                FloatingText(
                    "🩸 TERIKAT: ${chosenPact.displayName}! (-${sacrificeHp.toInt()} ANIMA)",
                    player.position.x + player.width / 2f,
                    player.position.y + player.height + 0.6f,
                    chosenPact.primaryColor,
                    duration = 3.5f,
                    isCritical = true
                )
            )
        }
    }

    private fun renderBloodAltarOverlay() {
        val w = 1280f
        val h = 720f

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        shapeRenderer.projectionMatrix = uiCamera.combined
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // 1. Fullscreen Dark Crimson Vignette Overlay
        shapeRenderer.setColor(0.04f, 0.02f, 0.04f, 0.88f)
        shapeRenderer.rect(0f, 0f, w, h)

        // 2. Central Modal Box
        val modalW = 880f
        val modalH = 580f
        val modalX = (w - modalW) / 2f
        val modalY = (h - modalH) / 2f

        shapeRenderer.setColor(0.06f, 0.04f, 0.07f, 0.98f)
        shapeRenderer.rect(modalX, modalY, modalW, modalH)

        // Border Crimson Berdenyut Mistis
        val pulse = (sin(hudAnimTime * 3.5f) + 1f) * 0.5f
        shapeRenderer.setColor(0.90f, 0.15f, 0.20f, 0.80f + 0.20f * pulse)
        shapeRenderer.rectLine(modalX, modalY + modalH, modalX + modalW, modalY + modalH, 3f)
        shapeRenderer.rectLine(modalX, modalY, modalX + modalW, modalY, 2f)
        shapeRenderer.rectLine(modalX, modalY, modalX, modalY + modalH, 2f)
        shapeRenderer.rectLine(modalX + modalW, modalY, modalX + modalW, modalY + modalH, 2f)

        // 3. Render 3 Pact Cards + 1 Cancel Button
        val cardW = 820f
        val cardX = modalX + (modalW - cardW) / 2f
        val startY = modalY + modalH - 170f
        val cardH = 86f
        val spacing = 14f

        val pacts = listOf(
            TemporalPact.CARNAGE,
            TemporalPact.GREED,
            TemporalPact.SWIFTNESS
        )

        for (i in 0 until 3) {
            val pact = pacts[i]
            val cardY = startY - i * (cardH + spacing)
            val isSelected = (altarSelectedIndex == i)

            // Card Background
            if (isSelected) {
                shapeRenderer.setColor(0.18f, 0.08f, 0.12f, 0.98f)
            } else {
                shapeRenderer.setColor(0.10f, 0.06f, 0.10f, 0.90f)
            }
            shapeRenderer.rect(cardX, cardY, cardW, cardH)

            // Card Border
            val borderColor = if (isSelected) pact.primaryColor else Color(0.35f, 0.25f, 0.35f, 0.7f)
            val borderThick = if (isSelected) 2.5f else 1.2f
            shapeRenderer.rectLine(cardX, cardY + cardH, cardX + cardW, cardY + cardH, borderThick)
            shapeRenderer.rectLine(cardX, cardY, cardX + cardW, cardY, borderThick)
            shapeRenderer.rectLine(cardX, cardY, cardX, cardY + cardH, borderThick)
            shapeRenderer.rectLine(cardX + cardW, cardY, cardX + cardW, cardY + cardH, borderThick)

            // Left Glow Indicator Strip
            if (isSelected) {
                shapeRenderer.setColor(pact.primaryColor)
                shapeRenderer.rect(cardX, cardY, 8f, cardH)
            }
        }

        // Cancel Button (Index 3)
        val cancelY = startY - 3 * (cardH + spacing) + 10f
        val cancelH = 50f
        val isCancelSelected = (altarSelectedIndex == 3)
        shapeRenderer.setColor(if (isCancelSelected) Color(0.22f, 0.12f, 0.16f, 0.95f) else Color(0.12f, 0.08f, 0.12f, 0.85f))
        shapeRenderer.rect(cardX, cancelY, cardW, cancelH)
        shapeRenderer.setColor(if (isCancelSelected) Color.WHITE else Color.GRAY)
        shapeRenderer.rectLine(cardX, cancelY + cancelH, cardX + cardW, cancelY + cancelH, if (isCancelSelected) 2f else 1f)
        shapeRenderer.rectLine(cardX, cancelY, cardX + cardW, cancelY, if (isCancelSelected) 2f else 1f)
        shapeRenderer.rectLine(cardX, cancelY, cardX, cancelY + cardH, if (isCancelSelected) 2f else 1f)
        shapeRenderer.rectLine(cardX + cardW, cancelY, cardX + cardW, cancelY + cardH, if (isCancelSelected) 2f else 1f)

        shapeRenderer.end()

        // 4. Batch Text Pass
        batch.projectionMatrix = uiCamera.combined
        batch.begin()

        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Header Title
        headF.setColor(1.0f, 0.25f, 0.30f, 1f)
        val title = "✦ ALTAR PENGORBANAN ANIMA ✦"
        glyphLayout.setText(headF, title)
        headF.draw(batch, title, (w - glyphLayout.width) / 2f, modalY + modalH - 24f)

        // Subtitle Lore & Cost
        val sacrificeHp = (player.health.currentHp * 0.25f).coerceAtLeast(1f).toInt()
        regF.setColor(0.9f, 0.85f, 0.85f, 0.9f)
        val sub = "Persembahkan $sacrificeHp Anima (25% Jiwa) untuk mengikat satu Pakta Temporal di lantai ini."
        glyphLayout.setText(regF, sub)
        regF.draw(batch, sub, (w - glyphLayout.width) / 2f, modalY + modalH - 58f)

        // Draw Pact Texts
        for (i in 0 until 3) {
            val pact = pacts[i]
            val cardY = startY - i * (cardH + spacing)
            val isSelected = (altarSelectedIndex == i)

            // Title & Subtitle
            headF.setColor(if (isSelected) pact.primaryColor else Color.LIGHT_GRAY)
            headF.draw(batch, "${pact.displayName.uppercase()}  •  ${pact.subtitle}", cardX + 22f, cardY + cardH - 16f)

            // Description
            regF.setColor(0.92f, 0.92f, 0.95f, 1f)
            regF.draw(batch, pact.description, cardX + 22f, cardY + cardH - 46f, cardW - 44f, Align.left, true)
        }

        // Cancel Button Text
        headF.setColor(if (isCancelSelected) Color.WHITE else Color.GRAY)
        val cancelText = "BATALKAN RITUAL (TETAPKAN JIWA MURNI)"
        glyphLayout.setText(headF, cancelText)
        headF.draw(batch, cancelText, (w - glyphLayout.width) / 2f, cancelY + 34f)

        // Footer Controls Guide
        smallF.setColor(0.75f, 0.70f, 0.75f, 0.8f)
        val guide = "[↑/↓ / W/S] PILIH PAKTA   •   [ENTER / E / TAP] KORBANKAN ANIMA   •   [ESC] BATAL"
        glyphLayout.setText(smallF, guide)
        smallF.draw(batch, guide, (w - glyphLayout.width) / 2f, modalY + 28f)

        batch.end()
    }

    override fun resize(width: Int, height: Int) {
        cameraManager.resize(width, height)
        uiViewport.update(width, height, true)
        virtualController.resize(1280, 720)
    }

    override fun pause() {
        AudioManager.pauseBgm()
    }

    override fun resume() {
        if (!isPaused && gameStatus == GameStatus.PLAYING) {
            AudioManager.resumeBgm()
        }
    }

    override fun hide() {
        AudioManager.pauseBgm()
    }

    override fun dispose() {
        AudioManager.stopBgm()
        particleManager.clear()
        shapeRenderer.dispose()
        batch.dispose()
    }
}
