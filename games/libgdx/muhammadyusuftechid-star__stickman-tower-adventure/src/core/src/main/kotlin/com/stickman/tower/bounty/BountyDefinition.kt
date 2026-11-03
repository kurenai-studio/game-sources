package com.stickman.tower.bounty

/**
 * Modifikator afiks mutasi monster elit (Elite Affixes) pada Papan Buronan Menara.
 */
enum class BountyAffix(val title: String, val rune: String, val description: String) {
    THORNS(
        title = "Berduri Obsidian",
        rune = "🦔",
        description = "Memantulkan 15% dari seluruh kerusakan serangan fisik kembali kepada penyerang."
    ),
    VAMPIRIC(
        title = "Haus Darah",
        rune = "🩸",
        description = "Memulihkan 10% HP maksimum monster setiap kali serangannya mengenai pemain."
    ),
    HASTE(
        title = "Gerak Badai",
        rune = "⚡",
        description = "Meningkatkan kecepatan gerak dan frekuensi serangan monster sebesar +35%."
    )
}

/**
 * Status progres kontrak perburuan monster elit.
 */
enum class BountyStatus(val label: String) {
    AVAILABLE("Tersedia"),
    ACCEPTED("Sedang Diburu"),
    SLAIN("Target Tertumbangkan"),
    CLAIMED("Imbalan Terklaim")
}

/**
 * Kontrak buronan elit Menara Kaligrafer (Bounty Contract).
 */
data class BountyContract(
    val id: String,
    val targetName: String,
    val targetTitle: String,
    val targetFloor: Int,
    val affixes: List<BountyAffix>,
    val synopsis: String,
    val rewardGold: Int,
    val rewardExp: Int,
    val bonusRewardDesc: String
)
