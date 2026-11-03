package com.stickman.tower.tools

import com.badlogic.gdx.math.Rectangle
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.Player
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.physics.Platform
import com.stickman.tower.world.StageExit
import com.stickman.tower.world.TowerFloor
import com.stickman.tower.world.TowerLevelBuilder
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ToolsProgrammerTestSuite {

    @Test
    fun testDevCommandDispatcherAllCommands() {
        val dispatcher = DevCommandDispatcher()

        var godModeState: Boolean? = null
        var energyState: Boolean? = null
        var timeScaleVal = 1.0f
        var stepCalled = false
        var warpFloorTarget = 0
        var goldGranted = 0
        var levelUpCalled = false
        var healCalled = false
        var killAllCalled = false
        var switchedArchetype: CharacterArchetype? = null
        var spawnedEnemy: EnemyType? = null
        var hitboxToggle: Boolean? = null

        dispatcher.onSetGodMode = { godModeState = it }
        dispatcher.onSetInfiniteEnergy = { energyState = it }
        dispatcher.onSetTimeScale = { timeScaleVal = it }
        dispatcher.onStepFrame = { stepCalled = true }
        dispatcher.onWarpFloor = { warpFloorTarget = it }
        dispatcher.onGrantGold = { goldGranted += it }
        dispatcher.onGrantLevel = { levelUpCalled = true }
        dispatcher.onHealFull = { healCalled = true }
        dispatcher.onKillAllEnemies = { killAllCalled = true }
        dispatcher.onSwitchArchetype = { switchedArchetype = it }
        dispatcher.onSpawnEnemy = { spawnedEnemy = it }
        dispatcher.onToggleHitboxes = { hitboxToggle = it }
        dispatcher.getCurrentFloor = { TowerLevelBuilder.buildFloor(1) }

        // 1. Help
        val helpRes = dispatcher.dispatch("help")
        assertTrue(helpRes.success)
        assertTrue(helpRes.message.contains("god"))

        // 2. God mode
        assertTrue(dispatcher.dispatch("god on").success)
        assertEquals(true, godModeState)
        assertTrue(dispatcher.dispatch("god off").success)
        assertEquals(false, godModeState)

        // 3. Energy
        assertTrue(dispatcher.dispatch("energy on").success)
        assertEquals(true, energyState)

        // 4. Timescale
        assertTrue(dispatcher.dispatch("timescale 0.5").success)
        assertEquals(0.5f, timeScaleVal)

        // 5. Pause & Resume & Step
        assertTrue(dispatcher.dispatch("pause").success)
        assertEquals(0.0f, timeScaleVal)
        assertTrue(dispatcher.dispatch("resume").success)
        assertEquals(1.0f, timeScaleVal)
        assertTrue(dispatcher.dispatch("step").success)
        assertTrue(stepCalled)

        // 6. Gold & Level
        assertTrue(dispatcher.dispatch("gold 2500").success)
        assertEquals(2500, goldGranted)
        assertTrue(dispatcher.dispatch("level").success)
        assertTrue(levelUpCalled)

        // 7. Heal & Kill
        assertTrue(dispatcher.dispatch("heal").success)
        assertTrue(healCalled)
        assertTrue(dispatcher.dispatch("kill").success)
        assertTrue(killAllCalled)

        // 8. Warp
        assertTrue(dispatcher.dispatch("warp 5").success)
        assertEquals(5, warpFloorTarget)

        // 9. Archetype hot-swap
        assertTrue(dispatcher.dispatch("archetype AGILE").success)
        assertEquals(CharacterArchetype.AGILE, switchedArchetype)
        assertTrue(dispatcher.dispatch("archetype HEAVY").success)
        assertEquals(CharacterArchetype.HEAVY, switchedArchetype)

        // 10. Spawn enemy
        assertTrue(dispatcher.dispatch("spawn FLYING").success)
        assertEquals(EnemyType.FLYING, spawnedEnemy)

        // 11. Hitbox
        assertTrue(dispatcher.dispatch("hitbox on").success)
        assertEquals(true, hitboxToggle)

        // 12. Audit & Reachability
        assertTrue(dispatcher.dispatch("audit 1").success)
        assertTrue(dispatcher.dispatch("reachability 1").success)

        // 13. Simulate Balance
        val simRes = dispatcher.dispatch("simulate 10")
        assertTrue(simRes.success)
        assertTrue(simRes.message.contains("COMBAT & ECONOMY BALANCE"))

        // 14. Asset Validation
        val assetRes = dispatcher.dispatch("validate_assets")
        assertTrue(assetRes.success)

        // 15. Enterprise QA Commands (unlock_all, reset_save, metrics)
        var unlockAllInvoked = false
        var resetSaveInvoked = false
        dispatcher.onUnlockAllContent = { unlockAllInvoked = true }
        dispatcher.onResetSave = { resetSaveInvoked = true }

        val unlockRes = dispatcher.dispatch("unlock_all")
        assertTrue(unlockRes.success)
        assertTrue(unlockAllInvoked)

        val resetRes = dispatcher.dispatch("reset_save")
        assertTrue(resetRes.success)
        assertTrue(resetSaveInvoked)

        val metricsRes = dispatcher.dispatch("metrics")
        assertTrue(metricsRes.success)
        assertTrue(metricsRes.message.contains("Heap"))

        // 16. Invalid command handling
        val invalidRes = dispatcher.dispatch("unknown_command_xyz")
        assertFalse(invalidRes.success)
    }

    @Test
    fun testSaveDataResetAndCopyInPlace() {
        val original = com.stickman.tower.rpg.SaveData(
            playerLevel = 50,
            gold = 99999,
            highestTowerFloor = 50,
            isZephyrRescued = true,
            isGorgonRescued = true
        ).sanitize()
        original.unlockedLoreTablets.add("TABLET_1")

        val target = com.stickman.tower.rpg.SaveData().sanitize()
        assertEquals(1, target.playerLevel)
        assertEquals(1, target.highestTowerFloor)

        target.copyFrom(original)
        assertEquals(50, target.playerLevel)
        assertEquals(99999, target.gold)
        assertEquals(50, target.highestTowerFloor)
        assertTrue(target.isZephyrRescued)
        assertTrue(target.unlockedLoreTablets.contains("TABLET_1"))

        target.resetToDefaults()
        assertEquals(1, target.playerLevel)
        assertEquals(0, target.gold)
        assertEquals(1, target.highestTowerFloor)
        assertFalse(target.isZephyrRescued)
        assertFalse(target.isGorgonRescued)
    }

    @Test
    fun testLevelReachabilityOnStoryFloors() {
        for (floorNum in 1..10) {
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            val result = LevelReachabilityGraph.analyzeFloor(floor)

            assertTrue(result.isExitReachable, "Exit portal lantai $floorNum harus dapat dicapai dari titik spawn!")
            assertTrue(result.areCheckpointsReachable, "Checkpoint lantai $floorNum harus dapat dicapai!")
            assertEquals(0, result.unreachableChestsCount, "Semua peti di lantai $floorNum harus dapat dicapai!")
            assertTrue(result.reachablePlatformsCount > 0, "Harus ada platform yang terjangkau!")
            assertTrue(result.isPassed, "Lantai $floorNum harus lolos audit reachability")
            assertTrue(result.summary().contains("[REACHABILITY PASS]"))
        }
    }

    @Test
    fun testDetectUnreachableExitSoftlock() {
        // Mock floor dengan platform exit melayang di ketinggian 30 meter tanpa rute penghubung
        val softlockFloor = TowerFloor(
            floorNumber = 99,
            floorName = "Softlocked Void Floor",
            mapBounds = Rectangle(0f, 0f, 40f, 40f),
            spawnX = 2f,
            spawnY = 1.5f,
            platforms = listOf(
                Platform(0f, 0f, 10f, 1f),
                Platform(25f, 30f, 10f, 1f) // Melayang di Y=30m, mustahil dicapai
            ),
            spikes = emptyList(),
            chests = emptyList(),
            enemies = emptyList(),
            boss = null,
            checkpoint = null,
            exitPortal = StageExit(x = 28f, y = 31.5f),
            isBossFloor = false
        )

        val result = LevelReachabilityGraph.analyzeFloor(softlockFloor)
        assertFalse(result.isExitReachable, "Exit portal di Y=30m tanpa platform lompatan harus terdeteksi unreachable!")
        assertFalse(result.isPassed, "Lantai dengan exit mustahil harus gagal uji reachability!")
    }

    @Test
    fun testCombatBalanceSimulatorFullAudit() {
        val report = CombatBalanceSimulator.runFullAudit(roundsPerArchetype = 25)

        assertTrue(report.totalBattles > 0, "Total simulasi pertempuran harus > 0")
        assertTrue(report.archetypeResults.isNotEmpty(), "Harus ada hasil untuk setiap arketipe")
        assertTrue(report.globalWinRate in 0.35f..1.0f, "Global winrate harus dalam rentang wajar (aktual: ${report.globalWinRate})")

        val summary = report.summary()
        assertNotNull(summary)
        assertTrue(summary.contains("COMBAT & ECONOMY BALANCE SIMULATION REPORT"))
        assertTrue(summary.contains("WARRIOR") || summary.contains("BALANCED"))
    }

    @Test
    fun testAssetPipelineValidatorDataIntegrity() {
        val report = AssetPipelineValidator.validateAll()

        assertTrue(report.totalChecked >= 15, "Total aset dan data yang diperiksa harus komprehensif (>= 15 item)")
        assertEquals(0, report.failed, "Tidak boleh ada kegagalan aset: ${report.errors}")
        assertTrue(report.isClean, "Asset report harus bersih tanpa error")
        assertTrue(report.summary().contains("[ASSET VALIDATION PASSED]"))
    }

    @Test
    fun testDevToolsOverlayTabNavigationAndFrameStep() {
        val devTools = DevToolsOverlay()
        assertEquals(DevTab.CHEATS, devTools.currentTab)

        // Uji Pergantian Tab
        devTools.currentTab = DevTab.WARP_SPAWN
        assertEquals(DevTab.WARP_SPAWN, devTools.currentTab)

        devTools.currentTab = DevTab.PROFILER_AUDIT
        assertEquals(DevTab.PROFILER_AUDIT, devTools.currentTab)

        devTools.currentTab = DevTab.CLI_CONSOLE
        assertEquals(DevTab.CLI_CONSOLE, devTools.currentTab)

        // Uji Timescale & Step 1 Frame
        assertEquals(1.0f, devTools.timeScale)
        assertFalse(devTools.isPaused)

        devTools.isPaused = true
        devTools.step()
        assertTrue(devTools.pendingStepFrame)
        assertTrue(devTools.consumeStep(), "Step pertama harus mengembalikan true")
        assertFalse(devTools.consumeStep(), "Step kedua tanpa pemicu baru harus mengembalikan false")
    }

    @Test
    fun testPlayerArchetypeLiveHotSwapping() {
        val player = Player(archetype = CharacterArchetype.BALANCED)
        assertEquals(CharacterArchetype.BALANCED, player.archetype)
        assertEquals("Gale Crescent", player.skill1.name)

        // Switch ke AGILE
        player.switchArchetype(CharacterArchetype.AGILE)
        assertEquals(CharacterArchetype.AGILE, player.archetype)
        assertEquals("Shadow Shuriken", player.skill1.name)
        assertEquals(80f, player.ultimate.maxEnergy)

        // Switch ke HEAVY
        player.switchArchetype(CharacterArchetype.HEAVY)
        assertEquals(CharacterArchetype.HEAVY, player.archetype)
        assertEquals("Earth Shockwave", player.skill1.name)
        assertEquals(120f, player.ultimate.maxEnergy)
    }
}
