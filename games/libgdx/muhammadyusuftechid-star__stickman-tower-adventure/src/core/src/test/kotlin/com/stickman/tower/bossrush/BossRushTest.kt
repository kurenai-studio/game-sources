package com.stickman.tower.bossrush

import com.stickman.tower.enemy.BossType
import com.stickman.tower.rpg.SaveData
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit Test Komprehensif untuk Mode Boss Rush & Hall of Legends (Fase 23).
 */
class BossRushTest {

    private lateinit var saveData: SaveData

    @Before
    fun setUp() {
        saveData = SaveData(
            bossRushBestTimes = hashMapOf(),
            unlockedTitles = arrayListOf("TITEL_NOVICE"),
            activeTitle = "TITEL_NOVICE",
            gold = 100
        )
    }

    @Test
    fun testBossRushStagesSequence() {
        val stages = BossRushManager.BOSS_RUSH_STAGES
        assertEquals(5, stages.size)
        assertEquals(BossType.TOWER_GUARDIAN, stages[0])
        assertEquals(BossType.AMETHYST_MATRON, stages[1])
        assertEquals(BossType.SHADOW_DOPPELGANGER, stages[2])
        assertEquals(BossType.CRIMSON_SOVEREIGN, stages[3])
        assertEquals(BossType.GRAND_CALLIGRAPHER, stages[4])
    }

    @Test
    fun testRankEvaluationFromTime() {
        // <= 180s -> S Rank
        assertEquals(BossRushRank.S_RANK, BossRushRank.fromTime(125.5f))
        assertEquals(BossRushRank.S_RANK, BossRushRank.fromTime(180.0f))

        // 180.1s - 270s -> A Rank
        assertEquals(BossRushRank.A_RANK, BossRushRank.fromTime(180.1f))
        assertEquals(BossRushRank.A_RANK, BossRushRank.fromTime(270.0f))

        // > 270s -> B Rank
        assertEquals(BossRushRank.B_RANK, BossRushRank.fromTime(270.1f))
        assertEquals(BossRushRank.B_RANK, BossRushRank.fromTime(500.0f))

        // Non-positive time
        assertEquals(BossRushRank.NONE, BossRushRank.fromTime(0f))
        assertEquals(BossRushRank.NONE, BossRushRank.fromTime(-10f))
    }

    @Test
    fun testRecordCompletionFirstClearAndRewards() {
        val archetype = "BALANCED"
        val (rank, isNewRecord, newTitle) = BossRushManager.recordCompletion(
            archetypeId = archetype,
            elapsedTimeSeconds = 165.0f, // S-Rank
            saveData = saveData
        )

        assertEquals(BossRushRank.S_RANK, rank)
        assertTrue(isNewRecord)
        assertNotNull(newTitle)
        assertEquals("TITEL_CHRONO_SLAYER", newTitle?.id)
        assertTrue(saveData.unlockedTitles.contains("TITEL_CHRONO_SLAYER"))
        assertEquals(165.0f, BossRushManager.getBestTime(archetype, saveData), 0.001f)
        assertEquals(1100, saveData.gold) // 100 base + 1000 S-rank reward
    }

    @Test
    fun testRecordCompletionSubsequentWorseTimeDoesNotOverwrite() {
        val archetype = "AGILE"
        // First run: 200s (A-Rank)
        BossRushManager.recordCompletion(archetype, 200f, saveData)
        assertEquals(200f, BossRushManager.getBestTime(archetype, saveData), 0.001f)

        // Second run: 250s (A-Rank, slower)
        val (_, isNewRecord, _) = BossRushManager.recordCompletion(archetype, 250f, saveData)
        assertFalse(isNewRecord)
        assertEquals(200f, BossRushManager.getBestTime(archetype, saveData), 0.001f)

        // Third run: 150s (S-Rank, new best!)
        val (rank3, isNewRecord3, _) = BossRushManager.recordCompletion(archetype, 150f, saveData)
        assertTrue(isNewRecord3)
        assertEquals(BossRushRank.S_RANK, rank3)
        assertEquals(150f, BossRushManager.getBestTime(archetype, saveData), 0.001f)
    }

    @Test
    fun testTitleManagementAndSelection() {
        assertEquals("TITEL_NOVICE", saveData.activeTitle)

        // Trying to set locked title fails
        assertFalse(BossRushManager.setActiveTitle("TITEL_CHRONO_SLAYER", saveData))
        assertEquals("TITEL_NOVICE", saveData.activeTitle)

        // Unlock title and set it
        saveData.unlockedTitles.add("TITEL_CHRONO_SLAYER")
        assertTrue(BossRushManager.setActiveTitle("TITEL_CHRONO_SLAYER", saveData))
        assertEquals("TITEL_CHRONO_SLAYER", saveData.activeTitle)

        val titleMeta = BossRushManager.getTitleById(saveData.activeTitle)
        assertEquals("Penebas Sang Waktu", titleMeta.titleName)
    }

    @Test
    fun testSaveDataChecksumIntegrityWithBossRushData() {
        saveData.updateChecksum()
        assertTrue(saveData.isChecksumValid())
        val originalChecksum = saveData.checksum

        // Modify best times
        saveData.bossRushBestTimes["BALANCED"] = 145.2f
        assertFalse(saveData.isChecksumValid())

        saveData.updateChecksum()
        assertTrue(saveData.isChecksumValid())
        assertTrue(saveData.checksum != originalChecksum)

        // Modify title
        saveData.activeTitle = "TITEL_CHRONO_SLAYER"
        assertFalse(saveData.isChecksumValid())

        saveData.updateChecksum()
        assertTrue(saveData.isChecksumValid())
    }

    @Test
    fun testAllThreeArchetypesIndependentRecords() {
        // BALANCED: S-Rank (140s)
        val (rankB, newRecB, titleB) = BossRushManager.recordCompletion("BALANCED", 140.0f, saveData)
        assertEquals(BossRushRank.S_RANK, rankB)
        assertTrue(newRecB)
        assertEquals("TITEL_CHRONO_SLAYER", titleB?.id)

        // AGILE: A-Rank (220s)
        val (rankA, newRecA, titleA) = BossRushManager.recordCompletion("AGILE", 220.0f, saveData)
        assertEquals(BossRushRank.A_RANK, rankA)
        assertTrue(newRecA)
        assertEquals("TITEL_SOVEREIGN_BANE", titleA?.id)

        // HEAVY: B-Rank (310s)
        val (rankH, newRecH, titleH) = BossRushManager.recordCompletion("HEAVY", 310.0f, saveData)
        assertEquals(BossRushRank.B_RANK, rankH)
        assertTrue(newRecH)
        org.junit.Assert.assertNull(titleH)

        // Check each best time and rank independently
        assertEquals(140.0f, BossRushManager.getBestTime("BALANCED", saveData), 0.001f)
        assertEquals(BossRushRank.S_RANK, BossRushManager.getBestRank("BALANCED", saveData))

        assertEquals(220.0f, BossRushManager.getBestTime("AGILE", saveData), 0.001f)
        assertEquals(BossRushRank.A_RANK, BossRushManager.getBestRank("AGILE", saveData))

        assertEquals(310.0f, BossRushManager.getBestTime("HEAVY", saveData), 0.001f)
        assertEquals(BossRushRank.B_RANK, BossRushManager.getBestRank("HEAVY", saveData))
    }

    @Test
    fun testGauntletScreenBossRushStagesInfo() {
        val stages = com.stickman.tower.screen.GauntletScreen.BOSS_RUSH_STAGES_INFO
        assertEquals(5, stages.size)
        assertTrue(stages[0].first.contains("General Oakhaven"))
        assertTrue(stages[1].first.contains("Amethyst Matron"))
        assertTrue(stages[2].first.contains("Shadow Doppelgänger"))
        assertTrue(stages[3].first.contains("Crimson Sovereign"))
        assertTrue(stages[4].first.contains("Grand Calligrapher"))
    }
}
