package com.stickman.tower.rune

import com.badlogic.gdx.graphics.Color

/**
 * Tipe Rune Kuno Menara Aethelgard (Ancient Rune Types).
 * Batu berukir kekuatan primordial yang dapat dipasang pada soket senjata ksatria.
 */
enum class RuneType(
    val id: String,
    val runeSymbol: String,
    val displayName: String,
    val subtitle: String,
    val lore: String,
    val primaryColor: Color,
    val bonusAtk: Float = 0f,
    val damageReductionPct: Float = 0f,
    val cooldownReductionPct: Float = 0f,
    val critRatePct: Float = 0f,
    val lifestealPct: Float = 0f
) {
    NONE(
        id = "NONE",
        runeSymbol = "◇",
        displayName = "Soket Kosong",
        subtitle = "Belum Terisi",
        lore = "Soket senjata yang masih hampa dan menunggu dipahat dengan kekuatan rune purba.",
        primaryColor = Color.GRAY
    ),

    RUNE_SOLAR(
        id = "RUNE_SOLAR",
        runeSymbol = "☼",
        displayName = "Rune Surya Vulcanus",
        subtitle = "Panas Paron Meteorit",
        lore = "Dipahat langsung dari sisa meteorit penempaan Vulcanus. Mengalirkan kobaran api murni yang memperkuat tebasan senjata (+8 ATK).",
        primaryColor = Color(1.0f, 0.45f, 0.15f, 1f),
        bonusAtk = 8f
    ),

    RUNE_LUNAR(
        id = "RUNE_LUNAR",
        runeSymbol = "☽",
        displayName = "Rune Rembulan Aria",
        subtitle = "Selimut Cahaya Jiwa",
        lore = "Kristalisasi dari air mata suci dan cahaya lentera Aria. Membentuk lapisan perlindungan mistis yang meredam benturan lawan (-10% Damage Taken).",
        primaryColor = Color(0.40f, 0.85f, 1.0f, 1f),
        damageReductionPct = 0.10f
    ),

    RUNE_TEMPEST(
        id = "RUNE_TEMPEST",
        runeSymbol = "⚡",
        displayName = "Rune Badai Kael",
        subtitle = "Kilat Kinetik Menara",
        lore = "Mengandung esensi kilat angin badai yang menderu di puncak menara. Mempercepat pemulihan energi jurus ksatria (+15% Cooldown Reduction).",
        primaryColor = Color(0.95f, 0.90f, 0.25f, 1f),
        cooldownReductionPct = 0.15f
    ),

    RUNE_ABYSS(
        id = "RUNE_ABYSS",
        runeSymbol = "☯",
        displayName = "Rune Palung Obsidian",
        subtitle = "Kekosongan Tanpa Batas",
        lore = "Diukir dari serpihan batu hitam jurang tak berdasar. Mengorbankan ketenangan batin demi serangan mematikan (+8% Crit Chance, +4% Vampiric Lifesteal).",
        primaryColor = Color(0.75f, 0.20f, 0.85f, 1f),
        critRatePct = 0.08f,
        lifestealPct = 0.04f
    );

    companion object {
        fun fromString(id: String?): RuneType {
            if (id.isNullOrBlank()) return NONE
            return try {
                valueOf(id.trim().uppercase())
            } catch (_: Exception) {
                NONE
            }
        }
    }
}
