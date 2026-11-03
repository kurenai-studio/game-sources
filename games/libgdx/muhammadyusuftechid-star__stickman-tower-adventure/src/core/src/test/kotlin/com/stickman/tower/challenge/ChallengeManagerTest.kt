package com.stickman.tower.challenge

import com.stickman.tower.relic.RelicType
import com.stickman.tower.rpg.SaveData
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ChallengeManagerTest {

    @BeforeTest
    fun setUp() {
        ChallengeManager.resetForTest()
    }

    @Test
    fun testChallengeRegistryIntegrity() {
        val all = ChallengeRegistry.getAll()
        assertEquals(3, all.size, "Must have exactly 3 canonical Scribe's Gauntlets")

        val deflection = ChallengeRegistry.getById("GAUNTLET_DEFLECTION")
        assertNotNull(deflection)
        assertEquals(ChallengeType.TRIAL_DEFLECTION, deflection.type)
        assertEquals(RelicType.CHRONOS_HOURGLASS, deflection.relicReward)
        assertTrue(deflection.goldThreshold > deflection.silverThreshold)
        assertTrue(deflection.silverThreshold > deflection.bronzeThreshold)

        val pacewalker = ChallengeRegistry.getById("GAUNTLET_PACEWALKER")
        assertNotNull(pacewalker)
        assertEquals(ChallengeType.TRIAL_PACEWALKER, pacewalker.type)
        assertEquals(RelicType.WINGS_OF_HERMES, pacewalker.relicReward)

        val ironWill = ChallengeRegistry.getById("GAUNTLET_IRON_WILL")
        assertNotNull(ironWill)
        assertEquals(ChallengeType.TRIAL_IRON_WILL, ironWill.type)
        assertEquals(2, ironWill.talentPointsReward)
    }

    @Test
    fun testMedalEvaluation() {
        val def = ChallengeRegistry.GAUNTLET_DEFLECTION

        assertEquals(ChallengeMedal.NONE, def.evaluateMedal(def.bronzeThreshold - 1))
        assertEquals(ChallengeMedal.BRONZE, def.evaluateMedal(def.bronzeThreshold))
        assertEquals(ChallengeMedal.BRONZE, def.evaluateMedal(def.silverThreshold - 1))
        assertEquals(ChallengeMedal.SILVER, def.evaluateMedal(def.silverThreshold))
        assertEquals(ChallengeMedal.SILVER, def.evaluateMedal(def.goldThreshold - 1))
        assertEquals(ChallengeMedal.GOLD, def.evaluateMedal(def.goldThreshold))
        assertEquals(ChallengeMedal.GOLD, def.evaluateMedal(def.goldThreshold + 10))
    }

    @Test
    fun testRecordAttemptAndMonotonicMedalProgression() {
        val challengeId = "GAUNTLET_DEFLECTION"
        assertEquals(ChallengeMedal.NONE, ChallengeManager.getBestMedal(challengeId))

        // Percobaan 1: Raih Medali Perunggu
        val medal1 = ChallengeManager.recordAttempt(challengeId, 5)
        assertEquals(ChallengeMedal.BRONZE, medal1)
        assertEquals(ChallengeMedal.BRONZE, ChallengeManager.getBestMedal(challengeId))
        assertEquals(5, ChallengeManager.getBestScore(challengeId))

        // Percobaan 2: Raih Medali Emas
        val medal2 = ChallengeManager.recordAttempt(challengeId, 20)
        assertEquals(ChallengeMedal.GOLD, medal2)
        assertEquals(ChallengeMedal.GOLD, ChallengeManager.getBestMedal(challengeId))
        assertEquals(20, ChallengeManager.getBestScore(challengeId))

        // Percobaan 3: Percobaan buruk (skor perak) tidak boleh menurunkan rekor emas
        val medal3 = ChallengeManager.recordAttempt(challengeId, 11)
        assertEquals(ChallengeMedal.SILVER, medal3)
        assertEquals(ChallengeMedal.GOLD, ChallengeManager.getBestMedal(challengeId), "Rekor medali tertinggi harus tetap Emas")
        assertEquals(20, ChallengeManager.getBestScore(challengeId), "Rekor skor tertinggi harus tetap 20")
    }

    @Test
    fun testClaimRewardAndTalentPoints() {
        val challengeId = "GAUNTLET_IRON_WILL"
        val saveData = SaveData(gold = 100, currentExp = 200, unspentTalentPoints = 1)

        // Belum ada kelulusan, tidak bisa klaim
        assertFalse(ChallengeManager.canClaim(challengeId))
        assertFalse(ChallengeManager.claimReward(challengeId, saveData))

        // Lulus Ujian Kehendak Baja
        ChallengeManager.recordAttempt(challengeId, 1600)
        assertTrue(ChallengeManager.canClaim(challengeId))

        // Klaim Hadiah
        var rewardGoldClaimed = 0
        var rewardExpClaimed = 0
        var rewardTpClaimed = 0
        val success = ChallengeManager.claimReward(challengeId, saveData) { gold, exp, _, tp ->
            rewardGoldClaimed = gold
            rewardExpClaimed = exp
            rewardTpClaimed = tp
        }

        assertTrue(success)
        assertEquals(500, rewardGoldClaimed)
        assertEquals(1000, rewardExpClaimed)
        assertEquals(2, rewardTpClaimed)

        assertEquals(600, saveData.gold)
        assertEquals(1200, saveData.currentExp)
        assertEquals(3, saveData.unspentTalentPoints, "Talent points harus bertambah +2")
        assertTrue(ChallengeManager.isClaimed(challengeId))

        // Tidak boleh bisa diklaim dua kali
        assertFalse(ChallengeManager.canClaim(challengeId))
        assertFalse(ChallengeManager.claimReward(challengeId, saveData))
    }

    @Test
    fun testSaveDataSyncAndIntegrity() {
        val saveData = SaveData()
        ChallengeManager.recordAttempt("GAUNTLET_DEFLECTION", 15) // GOLD
        ChallengeManager.recordAttempt("GAUNTLET_PACEWALKER", 75)  // SILVER

        ChallengeManager.syncToSaveData(saveData)
        saveData.updateChecksum()
        assertTrue(saveData.isChecksumValid(), "SaveData checksum harus valid setelah sinkronisasi medali")

        // Buat manager baru dan muat dari saveData
        ChallengeManager.resetForTest()
        assertEquals(ChallengeMedal.NONE, ChallengeManager.getBestMedal("GAUNTLET_DEFLECTION"))

        ChallengeManager.loadFromSaveData(saveData)
        assertEquals(ChallengeMedal.GOLD, ChallengeManager.getBestMedal("GAUNTLET_DEFLECTION"))
        assertEquals(ChallengeMedal.SILVER, ChallengeManager.getBestMedal("GAUNTLET_PACEWALKER"))
    }
}
