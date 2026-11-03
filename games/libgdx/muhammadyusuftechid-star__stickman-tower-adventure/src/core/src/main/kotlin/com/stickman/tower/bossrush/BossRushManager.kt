package com.stickman.tower.bossrush

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.enemy.BossType
import com.stickman.tower.rpg.SaveData

/**
 * Metadata Gelar Kehormatan Ksatria Siluet (Hall of Legends).
 */
data class KnightTitle(
    val id: String,
    val titleName: String,
    val description: String,
    val color: Color
)

/**
 * Manajer Mode Boss Rush (Gauntlet of Sovereigns) & Hall of Legends.
 */
object BossRushManager {

    /**
     * Rangkaian urutan 5 bos legendaris yang dihadapi secara beruntun.
     */
    val BOSS_RUSH_STAGES = listOf(
        BossType.TOWER_GUARDIAN,
        BossType.AMETHYST_MATRON,
        BossType.SHADOW_DOPPELGANGER,
        BossType.CRIMSON_SOVEREIGN,
        BossType.GRAND_CALLIGRAPHER
    )

    val TOTAL_STAGES = BOSS_RUSH_STAGES.size

    val ALL_TITLES = listOf(
        KnightTitle(
            id = "TITEL_NOVICE",
            titleName = "Pendaki Pemula",
            description = "Gelar dasar bagi setiap ksatria siluet yang melangkah ke Menara Aethelgard.",
            color = Color.LIGHT_GRAY
        ),
        KnightTitle(
            id = "TITEL_SOVEREIGN_BANE",
            titleName = "Bencana Para Raja",
            description = "Diberikan kepada penantang yang menyelesaikan Gauntlet of Sovereigns dengan Peringkat A (< 4.5 menit).",
            color = Color(0.35f, 0.85f, 1.0f, 1f)
        ),
        KnightTitle(
            id = "TITEL_CHRONO_SLAYER",
            titleName = "Penebas Sang Waktu",
            description = "Dianugerahkan kepada ksatria agung yang melibas kelima bos dengan Peringkat S (< 3 menit).",
            color = Color(1.0f, 0.85f, 0.25f, 1f)
        ),
        KnightTitle(
            id = "TITEL_SPIRE_CONQUEROR",
            titleName = "Penakluk Puncak Menara",
            description = "Diberikan kepada petarung gigih yang menembus lantai 20+ di mode Endless Spire.",
            color = Color(0.85f, 0.35f, 0.95f, 1f)
        )
    )

    fun getTitleById(id: String): KnightTitle {
        return ALL_TITLES.find { it.id == id } ?: ALL_TITLES[0]
    }

    fun getBestTime(archetypeId: String, saveData: SaveData): Float {
        return saveData.bossRushBestTimes[archetypeId] ?: 0f
    }

    fun getBestRank(archetypeId: String, saveData: SaveData): BossRushRank {
        val time = getBestTime(archetypeId, saveData)
        return BossRushRank.fromTime(time)
    }

    /**
     * Mencatat hasil penyelesaian Boss Rush.
     * Mengembalikan Triple (Rank dicapai, IsNewRecord, Gelar baru yang terbuka).
     */
    fun recordCompletion(
        archetypeId: String,
        elapsedTimeSeconds: Float,
        saveData: SaveData
    ): Triple<BossRushRank, Boolean, KnightTitle?> {
        val rank = BossRushRank.fromTime(elapsedTimeSeconds)
        val currentBest = getBestTime(archetypeId, saveData)
        val isNewRecord = (currentBest <= 0f || elapsedTimeSeconds < currentBest)

        if (isNewRecord) {
            saveData.bossRushBestTimes[archetypeId] = elapsedTimeSeconds
        }

        var unlockedNewTitle: KnightTitle? = null
        val titleId = rank.titleRewardId
        if (titleId != null && !saveData.unlockedTitles.contains(titleId)) {
            saveData.unlockedTitles.add(titleId)
            unlockedNewTitle = getTitleById(titleId)
        }

        if (rank.goldReward > 0) {
            saveData.gold += rank.goldReward
        }

        return Triple(rank, isNewRecord, unlockedNewTitle)
    }

    fun setActiveTitle(titleId: String, saveData: SaveData): Boolean {
        if (saveData.unlockedTitles.contains(titleId)) {
            saveData.activeTitle = titleId
            return true
        }
        return false
    }
}
