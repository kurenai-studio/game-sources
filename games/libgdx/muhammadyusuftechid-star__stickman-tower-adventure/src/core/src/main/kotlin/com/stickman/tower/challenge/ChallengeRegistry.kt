package com.stickman.tower.challenge

import com.stickman.tower.relic.RelicType

/**
 * Registri resmi tantangan Monolit Ujian Para Kaligrafer (The Scribe's Gauntlets).
 */
object ChallengeRegistry {

    val GAUNTLET_DEFLECTION = ChallengeDefinition(
        id = "GAUNTLET_DEFLECTION",
        type = ChallengeType.TRIAL_DEFLECTION,
        title = "Ujian Tangkisan Suci",
        subtitle = "Kaligrafi Ketepatan Tanpa Kekerasan",
        synopsis = "Di hadapan Monolit Suci, pedangmu disegel dari melukai. Bertahanlah dan tangkis serangan beruntun ilusi musuh hingga batas sempurna!",
        handicapDescription = "Serangan fisik dinonaktifkan (ATK = 0). Raih medali melalui jumlah Perfect Parry berturut-turut.",
        targetFloor = 2,
        bronzeThreshold = 5,
        silverThreshold = 10,
        goldThreshold = 15,
        goldReward = 250,
        expReward = 400,
        relicReward = RelicType.CHRONOS_HOURGLASS,
        talentPointsReward = 0
    )

    val GAUNTLET_PACEWALKER = ChallengeDefinition(
        id = "GAUNTLET_PACEWALKER",
        type = ChallengeType.TRIAL_PACEWALKER,
        title = "Ujian Langkah Bayang",
        subtitle = "Ketangkasan Menembus Ruang Berbahaya",
        synopsis = "Lintasi labirin duri obsidian dan lantai runtuh sepanjang 45 meter dalam batas waktu sempit dengan refleks kilat.",
        handicapDescription = "Rintangan duri memberikan damage fatal. Tuntaskan rute sebelum pasir waktu habis.",
        targetFloor = 4,
        bronzeThreshold = 40,
        silverThreshold = 70,
        goldThreshold = 95,
        goldReward = 350,
        expReward = 600,
        relicReward = RelicType.WINGS_OF_HERMES,
        talentPointsReward = 0
    )

    val GAUNTLET_IRON_WILL = ChallengeDefinition(
        id = "GAUNTLET_IRON_WILL",
        type = ChallengeType.TRIAL_IRON_WILL,
        title = "Ujian Kehendak Baja",
        subtitle = "Menghadapi Bayangan Kembar Sang Penjaga",
        synopsis = "Dua bayangan ilusi Penjaga Oakhaven dan Sang Ratu bangkit bersamaan dengan kutukan yang mereduksi separuh daya hidupmu.",
        handicapDescription = "Max HP pemain dikunci pada 50%. Kalahkan kedua bos ilusi tanpa terlelap.",
        targetFloor = 6,
        bronzeThreshold = 500,
        silverThreshold = 1000,
        goldThreshold = 1500,
        goldReward = 500,
        expReward = 1000,
        relicReward = null,
        talentPointsReward = 2
    )

    private val allChallenges = listOf(
        GAUNTLET_DEFLECTION,
        GAUNTLET_PACEWALKER,
        GAUNTLET_IRON_WILL
    )

    fun getAll(): List<ChallengeDefinition> = allChallenges

    fun getById(id: String): ChallengeDefinition? {
        return allChallenges.find { it.id.equals(id, ignoreCase = true) }
    }
}
