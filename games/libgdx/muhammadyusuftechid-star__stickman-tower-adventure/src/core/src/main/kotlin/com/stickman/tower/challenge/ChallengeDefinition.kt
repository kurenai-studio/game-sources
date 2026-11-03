package com.stickman.tower.challenge

import com.stickman.tower.relic.RelicType

/**
 * Tingkat pencapaian medali kehormatan pada Monolit Ujian Para Kaligrafer.
 */
enum class ChallengeMedal(val displayName: String, val symbol: String) {
    NONE("Belum Tercapai", "—"),
    BRONZE("Medali Perunggu", "🥉"),
    SILVER("Medali Perak", "🥈"),
    GOLD("Medali Emas Kaligrafer", "🥇")
}

/**
 * Tipe ujian ketangkasan aksi pada The Scribe's Gauntlets.
 */
enum class ChallengeType {
    TRIAL_DEFLECTION, // Ujian Tangkisan Suci: Tanpa serangan, tangkis beruntun
    TRIAL_PACEWALKER, // Ujian Langkah Bayang: Speedrun platforming tanpa kena duri
    TRIAL_IRON_WILL   // Ujian Kehendak Baja: Dual Phantom Boss dengan HP terkunci 50%
}

/**
 * Kontrak definisi arena tantangan Monolit Ujian.
 */
data class ChallengeDefinition(
    val id: String,
    val type: ChallengeType,
    val title: String,
    val subtitle: String,
    val synopsis: String,
    val handicapDescription: String,
    val targetFloor: Int,
    val bronzeThreshold: Int,
    val silverThreshold: Int,
    val goldThreshold: Int,
    val goldReward: Int,
    val expReward: Int,
    val relicReward: RelicType? = null,
    val talentPointsReward: Int = 0
) {
    /**
     * Mengevaluasi medali yang diraih berdasarkan skor/pencapaian pemain.
     */
    fun evaluateMedal(score: Int): ChallengeMedal {
        return when {
            score >= goldThreshold -> ChallengeMedal.GOLD
            score >= silverThreshold -> ChallengeMedal.SILVER
            score >= bronzeThreshold -> ChallengeMedal.BRONZE
            else -> ChallengeMedal.NONE
        }
    }
}
