package com.stickman.tower.relic

/**
 * Tipe Relik Pasif Acak Setiap Run Menara (Fase 10 Roguelite Loop):
 * Memberikan modifikasi gameplay unik yang bertahan hingga run menara selesai atau pemain gugur.
 */
enum class RelicType(
    val title: String,
    val iconRune: String,
    val description: String
) {
    VAMPIRIC_FANG(
        title = "Vampiric Fang",
        iconRune = "🩸",
        description = "Pulihkan 5% Max HP setiap kali menumbangkan musuh."
    ),
    THUNDER_CHARM(
        title = "Thunder Charm",
        iconRune = "⚡",
        description = "Menyambar musuh terdekat dengan petir 30 DMG setiap kombo 10x."
    ),
    WINGS_OF_HERMES(
        title = "Wings of Hermes",
        iconRune = "🪶",
        description = "Memberikan kemampuan Triple Jump (lompat 3 kali) di udara."
    ),
    CHRONOS_HOURGLASS(
        title = "Hourglass of Chronos",
        iconRune = "⏳",
        description = "Mengurangi cooldown Skill dan Dash sebesar 25%."
    );

    companion object {
        fun getRandomRelics(count: Int, excluding: Set<RelicType>): List<RelicType> {
            val available = entries.filterNot { excluding.contains(it) }.shuffled()
            return available.take(count)
        }
    }
}
