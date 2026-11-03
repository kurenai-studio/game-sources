package com.stickman.tower.challenge

import com.stickman.tower.relic.RelicType
import com.stickman.tower.rpg.SaveData

/**
 * Manajer pengelola arena Monolit Ujian Para Kaligrafer (The Scribe's Gauntlets).
 * Bertanggung jawab melacak skor tertinggi, piala/medali yang diraih, dan klaim hadiah.
 */
object ChallengeManager {

    // Menyimpan rekor medali tertinggi untuk tiap tantangan (challengeId -> ChallengeMedal)
    private val bestMedals = mutableMapOf<String, ChallengeMedal>()

    // Menyimpan rekor skor angka tertinggi (challengeId -> High Score)
    private val bestScores = mutableMapOf<String, Int>()

    // Melacak tantangan yang sudah diklaim hadiah kelulusannya
    private val claimedChallenges = mutableSetOf<String>()

    /**
     * Memuat status rekor dari SaveData pemain.
     */
    fun loadFromSaveData(saveData: SaveData) {
        bestMedals.clear()
        bestScores.clear()
        claimedChallenges.clear()

        // Muat medali
        for ((challengeId, medalName) in saveData.challengeMedals) {
            try {
                bestMedals[challengeId] = ChallengeMedal.valueOf(medalName)
            } catch (_: Exception) {
                bestMedals[challengeId] = ChallengeMedal.NONE
            }
        }

        // Muat status klaim reward dari format penanda khusus jika ada
        for (challengeId in saveData.completedQuests) {
            if (challengeId.startsWith("CHALLENGE_CLAIM_")) {
                claimedChallenges.add(challengeId.removePrefix("CHALLENGE_CLAIM_"))
            }
        }
    }

    /**
     * Menyinkronkan status medali dan klaim kembali ke SaveData.
     */
    fun syncToSaveData(saveData: SaveData) {
        saveData.challengeMedals.clear()
        for ((id, medal) in bestMedals) {
            saveData.challengeMedals[id] = medal.name
        }

        for (claimedId in claimedChallenges) {
            val key = "CHALLENGE_CLAIM_$claimedId"
            if (!saveData.completedQuests.contains(key)) {
                saveData.completedQuests.add(key)
            }
        }
    }

    /**
     * Mengambil medali tertinggi yang pernah diraih untuk tantangan tertentu.
     */
    fun getBestMedal(challengeId: String): ChallengeMedal {
        return bestMedals[challengeId] ?: ChallengeMedal.NONE
    }

    /**
     * Mengambil skor tertinggi yang pernah diraih.
     */
    fun getBestScore(challengeId: String): Int {
        return bestScores[challengeId] ?: 0
    }

    /**
     * Memeriksa apakah hadiah penyelesaian tantangan telah diklaim.
     */
    fun isClaimed(challengeId: String): Boolean {
        return claimedChallenges.contains(challengeId)
    }

    /**
     * Memeriksa apakah pemain memenuhi syarat untuk mengklaim hadiah pertama (lulus minimal Perunggu & belum diklaim).
     */
    fun canClaim(challengeId: String): Boolean {
        val medal = getBestMedal(challengeId)
        return medal != ChallengeMedal.NONE && !isClaimed(challengeId)
    }

    /**
     * Mencatat percobaan tantangan dengan skor yang diperoleh.
     * Mengembalikan medali yang didapatkan pada percobaan ini.
     */
    fun recordAttempt(challengeId: String, score: Int): ChallengeMedal {
        val def = ChallengeRegistry.getById(challengeId) ?: return ChallengeMedal.NONE
        val earnedMedal = def.evaluateMedal(score)

        val currentScore = bestScores[challengeId] ?: 0
        if (score > currentScore) {
            bestScores[challengeId] = score
        }

        val currentMedal = bestMedals[challengeId] ?: ChallengeMedal.NONE
        if (earnedMedal.ordinal > currentMedal.ordinal) {
            bestMedals[challengeId] = earnedMedal
        }

        return earnedMedal
    }

    /**
     * Mengklaim hadiah kelulusan tantangan ke SaveData pemain.
     */
    fun claimReward(
        challengeId: String,
        saveData: SaveData,
        onSuccess: ((gold: Int, exp: Int, relic: RelicType?, talentPoints: Int) -> Unit)? = null
    ): Boolean {
        if (!canClaim(challengeId)) return false

        val def = ChallengeRegistry.getById(challengeId) ?: return false

        // Tambahkan emas dan exp ke save data
        saveData.gold += def.goldReward
        saveData.currentExp += def.expReward

        // Tambahkan talent point jika ada
        if (def.talentPointsReward > 0) {
            if (saveData.unspentTalentPoints < 0) {
                saveData.unspentTalentPoints = def.talentPointsReward
            } else {
                saveData.unspentTalentPoints += def.talentPointsReward
            }
        }

        // Tandai sudah diklaim
        claimedChallenges.add(challengeId)
        syncToSaveData(saveData)

        onSuccess?.invoke(def.goldReward, def.expReward, def.relicReward, def.talentPointsReward)
        return true
    }

    /**
     * Mereset seluruh rekor untuk pengujian unit test.
     */
    fun resetForTest() {
        bestMedals.clear()
        bestScores.clear()
        claimedChallenges.clear()
    }
}
