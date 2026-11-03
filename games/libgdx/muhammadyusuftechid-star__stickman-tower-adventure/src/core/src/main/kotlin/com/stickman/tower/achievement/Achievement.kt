package com.stickman.tower.achievement

/**
 * Representasi data satu prestasi / pencapaian (Achievement) di Aethelgard.
 */
data class Achievement(
    val id: String,
    val title: String,
    val description: String,
    val goldReward: Int,
    val iconTag: String = "🏆"
)

/**
 * Katalog lengkap 12 Prestasi Ksatria Menara (The 12 Achievements of Aethelgard).
 */
object AchievementCatalog {
    val ACHIEVEMENTS: List<Achievement> = listOf(
        Achievement(
            id = "FIRST_BLOOD",
            title = "Darah Pertama",
            description = "Kalahkan monster kroco pertama di Menara Bayang.",
            goldReward = 50
        ),
        Achievement(
            id = "TOWER_GUARDIAN_DOWN",
            title = "Hakim Gerbang Tumbang",
            description = "Kalahkan Jenderal Oakhaven (The Tower Guardian) di Lantai 3.",
            goldReward = 200
        ),
        Achievement(
            id = "MATRON_SLAYER",
            title = "Penawar Racun Purba",
            description = "Kalahkan The Amethyst Matron di Lantai 5.",
            goldReward = 350
        ),
        Achievement(
            id = "SHADOW_REFLECTOR",
            title = "Memecahkan Cermin Jiwa",
            description = "Tumbangkan The Shadow Doppelgänger di Lantai 8.",
            goldReward = 500
        ),
        Achievement(
            id = "CRIMSON_CLEANSER",
            title = "Fajar di Atas Gerhana",
            description = "Kalahkan The Crimson Sovereign di Lantai 9.",
            goldReward = 750
        ),
        Achievement(
            id = "DESTINY_REWRITTEN",
            title = "Pena Takdir Terbelah",
            description = "Tumbangkan The Grand Calligrapher di Lantai 10 dan bebaskan warna Aethelgard.",
            goldReward = 1500
        ),
        Achievement(
            id = "PERFECT_PARRY_PRO",
            title = "Refleks Baja Astral",
            description = "Berhasil mengeksekusi 10 kali Perfect Parry.",
            goldReward = 300
        ),
        Achievement(
            id = "COMBO_VIRTUOSO",
            title = "Tarian Bilah Angin",
            description = "Capai rentetan 15-Hit Combo tanpa terputus.",
            goldReward = 250
        ),
        Achievement(
            id = "FORGE_MASTER",
            title = "Murid Vulcanus",
            description = "Tingkatkan senjata hingga Level 5 atau lebih tinggi.",
            goldReward = 300
        ),
        Achievement(
            id = "TALENT_ADEPT",
            title = "Kebangkitan Sub-Class",
            description = "Buka minimal 3 kemampuan khusus di Pohon Talent.",
            goldReward = 250
        ),
        Achievement(
            id = "ENDLESS_SURVIVOR",
            title = "Penjelajah Waktu Abadi",
            description = "Capai Lantai 15 atau lebih tinggi di mode Endless Spire.",
            goldReward = 500
        ),
        Achievement(
            id = "CHRONICLER_OF_AETHELGARD",
            title = "Pembaca Naskah Kuno",
            description = "Buka dan jelajahi seluruh arsip rahasia di Story Codex.",
            goldReward = 400
        )
    )

    fun findById(id: String): Achievement? = ACHIEVEMENTS.firstOrNull { it.id == id }
}
