package com.stickman.tower.tools

import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.world.TowerLevelBuilder
import kotlin.math.floor
import kotlin.math.pow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Unit Test Suite FASE 31:
 * 1. Memverifikasi secara matematis bahwa seluruh 50 lantai bebas softlock (Exit & Checkpoint reachable, 0 unreachable chests/tablets).
 * 2. Memverifikasi amplop kinematika karakter terberat Gorgon (gap horizontal <= 4.0m, jump double 3.80m).
 * 3. Memvalidasi kurva leveling EXP hingga level 80 dengan formula EXP(L) = 100 * L^1.35.
 * 4. Memvalidasi penempaan senjata hingga Tier +10 Primordial (MAX_WEAPON_LEVEL = 10) beserta skala biaya emas.
 */
class Campaign50FloorsReachabilityTest {

    @Test
    fun testAll50FloorsReachabilityStandardKinematics() {
        val failedFloors = mutableListOf<String>()

        for (floorNum in 1..50) {
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            val result = LevelReachabilityGraph.analyzeFloor(floor, CharacterKinematics.STANDARD)

            if (!result.isPassed) {
                failedFloors.add("Lantai $floorNum (${floor.floorName}): ${result.summary()}")
            }

            assertTrue(
                result.isExitReachable,
                "Exit portal lantai $floorNum (${floor.floorName}) harus dapat dicapai dari titik spawn!"
            )
            assertTrue(
                result.areCheckpointsReachable,
                "Checkpoint lantai $floorNum (${floor.floorName}) harus dapat dicapai!"
            )
            assertEquals(
                0,
                result.unreachableChestsCount,
                "Peti harta karun di lantai $floorNum (${floor.floorName}) harus 100% terjangkau!"
            )
            assertEquals(
                0,
                result.unreachableLoreTabletsCount,
                "Prasasti kuno di lantai $floorNum (${floor.floorName}) harus 100% terjangkau!"
            )
            assertTrue(
                result.isPassed,
                "Lantai $floorNum (${floor.floorName}) harus lulus audit reachability penuh!"
            )
        }

        assertTrue(failedFloors.isEmpty(), "Semua 50 lantai harus bebas softlock: $failedFloors")
    }

    @Test
    fun testSagasReachabilityGorgonHeavyKinematics() {
        val failedGorgonFloors = mutableListOf<String>()

        // Menguji lantai 21..50 di mana Gorgon telah dibebaskan dan aktif dalam pertempuran menara
        for (floorNum in 21..50) {
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            val result = LevelReachabilityGraph.analyzeFloor(floor, CharacterKinematics.HEAVY_GORGON)

            if (!result.isExitReachable || !result.areCheckpointsReachable) {
                failedGorgonFloors.add("Lantai $floorNum (${floor.floorName}): ${result.summary()}")
            }

            assertTrue(
                result.isExitReachable,
                "Gorgon harus mampu mencapai exit portal di lantai $floorNum (${floor.floorName})!"
            )
            assertTrue(
                result.areCheckpointsReachable,
                "Gorgon harus mampu mencapai checkpoint di lantai $floorNum (${floor.floorName})!"
            )
        }

        assertTrue(failedGorgonFloors.isEmpty(), "Gorgon tidak boleh terjebak softlock di Lantai 21-50: $failedGorgonFloors")
    }

    @Test
    fun testCharacterKinematicsProfiles() {
        val standard = CharacterKinematics.fromArchetype(CharacterArchetype.BALANCED)
        val heavy = CharacterKinematics.fromArchetype(CharacterArchetype.HEAVY)
        val agile = CharacterKinematics.fromArchetype(CharacterArchetype.AGILE)

        assertEquals(CharacterKinematics.STANDARD, standard)
        assertEquals(CharacterKinematics.HEAVY_GORGON, heavy)
        assertEquals(CharacterKinematics.AGILE_ZEPHYR, agile)

        // Verifikasi batas kinematika fisik
        assertTrue(heavy.runSpeed < standard.runSpeed, "Gorgon lebih lambat dari Kaelen")
        assertTrue(standard.runSpeed < agile.runSpeed, "Zephyr lebih cepat dari Kaelen")

        assertTrue(heavy.maxDoubleJumpY < standard.maxDoubleJumpY, "Lompatan Gorgon lebih berat")
        assertTrue(standard.maxDoubleJumpY < agile.maxDoubleJumpY, "Lompatan Zephyr paling tinggi")

        assertEquals(28.0f, heavy.gravity)
        assertEquals(28.0f, standard.gravity)
    }

    @Test
    fun testLevel80ExpCurveAndProgression() {
        val stats = CharacterStats(level = 1, currentExp = 0)

        // Level 1: 100 * 1^1.35 = 100 EXP
        assertEquals(100, stats.requiredExp)

        // Level 10: floor(100 * 10^1.35) = 2238 EXP
        stats.level = 10
        val expLv10 = floor(100.0 * 10.0.pow(1.35)).toInt()
        assertEquals(expLv10, stats.requiredExp)

        // Level 50: floor(100 * 50^1.35) = 19679 EXP
        stats.level = 50
        val expLv50 = floor(100.0 * 50.0.pow(1.35)).toInt()
        assertEquals(expLv50, stats.requiredExp)

        // Level 80: floor(100 * 80^1.35) = 37015 EXP
        stats.level = 80
        val expLv80 = floor(100.0 * 80.0.pow(1.35)).toInt()
        assertEquals(expLv80, stats.requiredExp)

        // Simulasi progresi leveling dari level 1 menuju level 80
        stats.level = 1
        stats.currentExp = 0

        var totalExpRequiredTo80 = 0
        for (lvl in 1 until 80) {
            totalExpRequiredTo80 += floor(100.0 * lvl.toDouble().pow(1.35)).toInt()
        }

        // Berikan total EXP yang dibutuhkan
        val levelsGained = stats.addExp(totalExpRequiredTo80)
        assertEquals(79, levelsGained)
        assertEquals(80, stats.level, "Karakter harus mencapai Level 80 tepat pada akumulasi EXP yang sesuai")
    }

    @Test
    fun testWeaponForgingTier10Balancing() {
        assertEquals(10, CharacterStats.MAX_WEAPON_LEVEL, "Maksimum tier senjata harus 10 Primordial")

        val stats = CharacterStats(gold = 100_000)

        // Verifikasi skala biaya: 120 * (currentLevel + 1)
        for (tier in 0 until 10) {
            val expectedCost = 120 * (tier + 1)
            assertEquals(expectedCost, CharacterStats.getUpgradeCost(tier))
        }

        // Total biaya upgrade 1 kategori dari 0 ke 10: 120 * sum(1..10) = 120 * 55 = 6600 Gold
        val initialGold = stats.gold
        for (i in 0 until 10) {
            assertTrue(stats.canUpgradeAtk(), "Harus bisa upgrade ATK tier ${i + 1}")
            val success = stats.upgradeAtk()
            assertTrue(success)
        }

        assertEquals(10, stats.weaponAtkLevel)
        assertFalse(stats.canUpgradeAtk(), "Tidak boleh upgrade melebihi MAX_WEAPON_LEVEL 10")
        assertEquals(6600, initialGold - stats.gold, "Total biaya upgrade tier 10 harus tepat 6600 Gold")
        assertEquals(40.0f, stats.weaponAtkBonus, "Tier 10 memberikan +40 ATK")

        // Upgrade CRIT ke tier 10
        for (i in 0 until 10) {
            assertTrue(stats.upgradeCrit())
        }
        assertEquals(10, stats.weaponCritLevel)
        assertEquals(0.25f, stats.weaponCritBonus, "Tier 10 memberikan +25% CRIT")

        // Upgrade SPD ke tier 10
        for (i in 0 until 10) {
            assertTrue(stats.upgradeSpd())
        }
        assertEquals(10, stats.weaponSpdLevel)
        assertEquals(0.35f, stats.weaponSpdBonus, "Tier 10 memberikan +35% SPD")

        // Total biaya 3 kategori (ATK, CRIT, SPD) ke Tier 10: 3 * 6600 = 19,800 Gold
        assertEquals(19_800, initialGold - stats.gold, "Total upgrade 3 kategori ke tier 10 harus 19800 Gold")
    }
}
