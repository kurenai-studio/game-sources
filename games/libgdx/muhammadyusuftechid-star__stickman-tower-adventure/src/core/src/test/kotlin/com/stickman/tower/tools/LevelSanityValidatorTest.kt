package com.stickman.tower.tools

import com.badlogic.gdx.math.Rectangle
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.Player
import com.stickman.tower.physics.Platform
import com.stickman.tower.world.SpikeHazard
import com.stickman.tower.world.StageExit
import com.stickman.tower.world.TowerFloor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LevelSanityValidatorTest {

    @Test
    fun testStoryFloorsSanity() {
        val reports = LevelSanityValidator.auditAllStoryFloors()
        assertEquals(10, reports.size)

        for (report in reports) {
            assertTrue(report.isValid, "Lantai ${report.floorNumber} harus valid tanpa error softlock: ${report.errors}")
            assertTrue(report.platformCount > 0, "Lantai ${report.floorNumber} harus memiliki platform")
            assertTrue(report.summary().contains("[PASSED]"), "Summary harus berstatus PASSED")
        }

        // Lantai bos Saga I: 5 (Oakhaven), 10 (Lady Vespera)
        val bossFloors = setOf(5, 10)
        for (report in reports) {
            if (report.floorNumber in bossFloors) {
                assertTrue(report.hasBoss, "Lantai ${report.floorNumber} harus memiliki boss")
            } else {
                assertFalse(report.hasBoss, "Lantai ${report.floorNumber} bukan boss floor")
            }
        }
    }

    @Test
    fun testEndlessFloorsSanity() {
        val reports = LevelSanityValidator.auditEndlessFloors(count = 10)
        assertEquals(10, reports.size)

        for (report in reports) {
            assertTrue(report.isValid, "Endless Floor ${report.floorNumber} gagal validasi: ${report.errors}")
            assertTrue(report.platformCount >= 3, "Endless Floor harus memiliki platform yang cukup")
        }

        // Lantai 15 dan 20 adalah boss milestone
        val floor15 = reports.firstOrNull { it.floorNumber == 15 }
        assertTrue(floor15 != null && floor15.hasBoss, "Lantai 15 harus memiliki boss")
    }

    @Test
    fun testDetectSpikeOnSpawnSoftlock() {
        // Buat mock floor yang cacat (duri berada tepat di titik spawn)
        val corruptedFloor = TowerFloor(
            floorNumber = 99,
            floorName = "Corrupted Floor",
            mapBounds = Rectangle(0f, 0f, 20f, 15f),
            spawnX = 2.0f,
            spawnY = 1.0f,
            platforms = listOf(Platform(0f, 0f, 20f, 1f)),
            spikes = listOf(SpikeHazard(1.5f, 0.5f, 2f, 1.5f)), // Menutupi spawn (2, 1)
            chests = emptyList(),
            enemies = emptyList(),
            boss = null,
            checkpoint = null,
            exitPortal = StageExit(18f, 1.5f),
            isBossFloor = false
        )

        val report = LevelSanityValidator.validateFloor(corruptedFloor)
        assertFalse(report.isValid, "Floor dengan duri di titik spawn harus gagal validasi!")
        assertTrue(report.errors.any { it.contains("Titik spawn pemain") && it.contains("SpikeHazard") })
    }

    @Test
    fun testDevToolsOverlayTogglesAndCallbacks() {
        val devTools = DevToolsOverlay()
        assertFalse(devTools.isVisible)
        assertFalse(devTools.isGodMode)
        assertFalse(devTools.isInfiniteEnergy)
        assertFalse(devTools.showHitboxes)

        devTools.toggle()
        assertTrue(devTools.isVisible)

        var grantedGold = 0
        var warpTarget = 0
        var healCalled = false
        var levelCalled = false
        var killCalled = false

        devTools.onGrantGold = { grantedGold += it }
        devTools.onWarpFloor = { warpTarget = it }
        devTools.onHealFull = { healCalled = true }
        devTools.onGrantLevel = { levelCalled = true }
        devTools.onKillAllEnemies = { killCalled = true }

        devTools.onGrantGold?.invoke(1000)
        devTools.onWarpFloor?.invoke(5)
        devTools.onHealFull?.invoke()
        devTools.onGrantLevel?.invoke()
        devTools.onKillAllEnemies?.invoke()

        assertEquals(1000, grantedGold)
        assertEquals(5, warpTarget)
        assertTrue(healCalled)
        assertTrue(levelCalled)
        assertTrue(killCalled)
    }

    @Test
    fun testPlayerGodModeImmunity() {
        val player = Player(archetype = CharacterArchetype.BALANCED)
        val initialHp = player.health.currentHp

        // Aktifkan God Mode
        player.isGodMode = true
        val hitResult = player.takeHit(100f, 5f, 5f)
        assertFalse(hitResult, "Serangan harus ditolak saat God Mode aktif")
        assertEquals(initialHp, player.health.currentHp, "HP tidak boleh berkurang saat God Mode aktif")

        // Nonaktifkan God Mode
        player.isGodMode = false
        val normalHit = player.takeHit(20f, 0f, 0f)
        assertTrue(normalHit, "Serangan normal harus diterima saat God Mode nonaktif")
        assertTrue(player.health.currentHp < initialHp, "HP harus berkurang saat menerima serangan normal")
    }
}
