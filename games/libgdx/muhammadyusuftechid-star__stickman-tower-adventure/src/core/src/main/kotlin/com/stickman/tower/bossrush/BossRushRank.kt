package com.stickman.tower.bossrush

import com.badlogic.gdx.graphics.Color

/**
 * Peringkat Medali Evaluasi Waktu Mode Boss Rush (Gauntlet of Sovereigns).
 */
enum class BossRushRank(
    val id: String,
    val timeThresholdSeconds: Float,
    val badgeSymbol: String,
    val displayName: String,
    val primaryColor: Color,
    val titleRewardId: String?,
    val goldReward: Int
) {
    S_RANK(
        id = "S_RANK",
        timeThresholdSeconds = 180f, // Di bawah 3 menit
        badgeSymbol = "★ S ★",
        displayName = "Grandmaster Kinetik",
        primaryColor = Color(1.0f, 0.85f, 0.25f, 1f),
        titleRewardId = "TITEL_CHRONO_SLAYER",
        goldReward = 1000
    ),

    A_RANK(
        id = "A_RANK",
        timeThresholdSeconds = 270f, // Di bawah 4.5 menit
        badgeSymbol = "◆ A ◆",
        displayName = "Veteran Penantang Menara",
        primaryColor = Color(0.35f, 0.85f, 1.0f, 1f),
        titleRewardId = "TITEL_SOVEREIGN_BANE",
        goldReward = 500
    ),

    B_RANK(
        id = "B_RANK",
        timeThresholdSeconds = Float.MAX_VALUE, // Menamatkan tantangan
        badgeSymbol = "▲ B ▲",
        displayName = "Ksatria Penyintas",
        primaryColor = Color(0.45f, 0.90f, 0.45f, 1f),
        titleRewardId = null,
        goldReward = 250
    ),

    NONE(
        id = "NONE",
        timeThresholdSeconds = Float.MAX_VALUE,
        badgeSymbol = "-",
        displayName = "Belum Ditaklukkan",
        primaryColor = Color.GRAY,
        titleRewardId = null,
        goldReward = 0
    );

    companion object {
        fun fromTime(timeSeconds: Float): BossRushRank {
            if (timeSeconds <= 0f) return NONE
            return when {
                timeSeconds <= S_RANK.timeThresholdSeconds -> S_RANK
                timeSeconds <= A_RANK.timeThresholdSeconds -> A_RANK
                else -> B_RANK
            }
        }
    }
}
