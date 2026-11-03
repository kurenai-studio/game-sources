package com.stickman.tower.quest

import com.stickman.tower.relic.RelicType

/**
 * Katalog Kanonikal Seluruh Misi Aethelgard (Quest Registry).
 * Menampung 7 Main Quests kampanye cerita dan 3 Heritage Side Quests warisan kuno.
 */
object QuestRegistry {

    val allQuests: List<QuestDefinition> = listOf(
        // =====================================================================
        // KAMPANYE CERITA UTAMA (MAIN ODYSSEY)
        // =====================================================================

        QuestDefinition(
            id = "MQ_1",
            title = "Bangkitnya Siluet",
            synopsis = "Terbangun di kaki Menara Bayang tanpa ingatan. Pelajari kembali naluri bertarung, baca prasasti peninggalan legiun, dan lintasi jurang duri obsidian.",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 1,
            floorTarget = 2,
            recommendedLevel = 1,
            objectives = listOf(
                QuestObjective("MQ1_OBJ1", ObjectiveType.CLEAR_FLOOR, 2, 0, "Selesaikan navigasi platforming Lantai 1 dan 2", "FLOOR_2"),
                QuestObjective("MQ1_OBJ2", ObjectiveType.READ_TABLET, 2, 0, "Temukan dan baca Tablet I & Tablet II", "TABLET_2"),
                QuestObjective("MQ1_OBJ3", ObjectiveType.PERFECT_PARRY, 1, 0, "Lakukan 1x Perfect Parry terhadap cakar Crimson Grunt", "PARRY")
            ),
            goldReward = 120,
            expReward = 150
        ),

        QuestDefinition(
            id = "MQ_2",
            title = "Ujian Sang Hakim Tanduk Emas",
            synopsis = "Jenderal Oakhaven menjaga gerbang menuju lantai atas. Buktikan ketegaran jiwamu dalam duel kehormatan satu lawan satu.",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 1,
            floorTarget = 3,
            recommendedLevel = 3,
            objectives = listOf(
                QuestObjective("MQ2_OBJ1", ObjectiveType.DEFEAT_BOSS, 1, 0, "Tumbangkan Jenderal Oakhaven di Balairung Gerbang Bawah", "TOWER_GUARDIAN"),
                QuestObjective("MQ2_OBJ2", ObjectiveType.READ_TABLET, 1, 0, "Baca wasiat kehormatan pada Tablet III", "TABLET_3")
            ),
            goldReward = 300,
            expReward = 400
        ),

        QuestDefinition(
            id = "MQ_3",
            title = "Mengurai Benang Racun Amethyst",
            synopsis = "Telusuri perpustakaan kaca kristal yang tenggelam, hindari panah beracun, dan purifikasi kawah alkimia The Amethyst Matron.",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 2,
            floorTarget = 5,
            recommendedLevel = 5,
            objectives = listOf(
                QuestObjective("MQ3_OBJ1", ObjectiveType.CLEAR_FLOOR, 1, 0, "Lintasi koridor The Sunken Archives Lantai 4", "FLOOR_4"),
                QuestObjective("MQ3_OBJ2", ObjectiveType.DEFEAT_BOSS, 1, 0, "Kalahkan Sang Ratu Busur Bayang di kawah Miasma", "AMETHYST_MATRON"),
                QuestObjective("MQ3_OBJ3", ObjectiveType.READ_TABLET, 2, 0, "Baca catatan alkimia pada Tablet IV & V", "TABLET_5")
            ),
            goldReward = 450,
            expReward = 750,
            talentPointsReward = 1
        ),

        QuestDefinition(
            id = "MQ_4",
            title = "Denting Palu Suaka Logam",
            synopsis = "Temukan satu-satunya tempat peristirahatan damai di dalam menara. Tempa senjatamu di hadapan tungku meteorit emas Vulcanus.",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 2,
            floorTarget = 6,
            recommendedLevel = 6,
            objectives = listOf(
                QuestObjective("MQ4_OBJ1", ObjectiveType.CLEAR_FLOOR, 1, 0, "Capai Suaka Vulcanus di Lantai 6", "FLOOR_6"),
                QuestObjective("MQ4_OBJ2", ObjectiveType.UPGRADE_WEAPON, 1, 0, "Perkuat senjatamu di paron tempa minimal ke Level 1", "FORGE_WEAPON"),
                QuestObjective("MQ4_OBJ3", ObjectiveType.READ_TABLET, 1, 0, "Baca Wasiat Sang Penempa pada Tablet VI", "TABLET_6")
            ),
            goldReward = 200,
            expReward = 300
        ),

        QuestDefinition(
            id = "MQ_5",
            title = "Melampaui Bayangan Diri",
            synopsis = "Menara menembus angkasa astral. Hadapi rasa bersalah masa lalu yang mewujud menjadi The Shadow Doppelgänger.",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 3,
            floorTarget = 8,
            recommendedLevel = 8,
            objectives = listOf(
                QuestObjective("MQ5_OBJ1", ObjectiveType.CLEAR_FLOOR, 1, 0, "Kuasai akrobatik Low Gravity di tebing retak Lantai 7", "FLOOR_7"),
                QuestObjective("MQ5_OBJ2", ObjectiveType.DEFEAT_BOSS, 1, 0, "Kalahkan bayangan dirimu sendiri di Balairung Gema", "SHADOW_DOPPELGANGER"),
                QuestObjective("MQ5_OBJ3", ObjectiveType.PERFECT_PARRY, 2, 0, "Tangkis serangan bayangan dengan 2x Perfect Parry", "PARRY")
            ),
            goldReward = 600,
            expReward = 1200,
            relicReward = RelicType.WINGS_OF_HERMES
        ),

        QuestDefinition(
            id = "MQ_6",
            title = "Meredupkan Gerhana Darah",
            synopsis = "Pangeran Valtheor telah meminum tinta darah demi keabadian. Hentikan kutukan lifesteal pangeran di bawah gerhana vampirik.",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 3,
            floorTarget = 9,
            recommendedLevel = 9,
            objectives = listOf(
                QuestObjective("MQ6_OBJ1", ObjectiveType.DEFEAT_BOSS, 1, 0, "Bebaskan jiwa Pangeran Belati Darah di altar kuil", "CRIMSON_SOVEREIGN"),
                QuestObjective("MQ6_OBJ2", ObjectiveType.READ_TABLET, 1, 0, "Baca pengorbanan ksatria pengawal pada Tablet IX", "TABLET_9")
            ),
            goldReward = 900,
            expReward = 1800,
            relicReward = RelicType.VAMPIRIC_FANG
        ),

        QuestDefinition(
            id = "MQ_7",
            title = "Patahnya Pena Semesta",
            synopsis = "Berpijak di atas marmer putih tak terbatas di hadapan The Grand Calligrapher. Hancurkan The Primordial Stylus dan kembalikan warna Aethelgard!",
            category = QuestCategory.MAIN_ODYSSEY,
            actNumber = 4,
            floorTarget = 10,
            recommendedLevel = 10,
            objectives = listOf(
                QuestObjective("MQ7_OBJ1", ObjectiveType.DEFEAT_BOSS, 1, 0, "Tumbangkan The Grand Calligrapher di puncak Kanvas Primordial", "GRAND_CALLIGRAPHER"),
                QuestObjective("MQ7_OBJ2", ObjectiveType.READ_TABLET, 1, 0, "Baca deklarasi masa depan Aria pada Tablet X", "TABLET_10")
            ),
            goldReward = 2500,
            expReward = 5000,
            talentPointsReward = 2
        ),

        // =====================================================================
        // MISI SAMPINGAN WARISAN KUNO (HERITAGE SIDE QUESTS)
        // =====================================================================

        QuestDefinition(
            id = "SQ_ARIA_COLORS",
            title = "Fragmen Spektrum Terakhir",
            synopsis = "Aria kehilangan wujud fisiknya. Temukan 4 kristal pigmen murni (Merah di L2, Biru di L4, Hijau di L7, Emas di L9) untuk memulihkan wujud bidadari spektrumnya.",
            category = QuestCategory.SIDE_HERITAGE,
            actNumber = 1,
            floorTarget = 9,
            recommendedLevel = 4,
            objectives = listOf(
                QuestObjective("SQ1_OBJ1", ObjectiveType.COLLECT_ITEM, 4, 0, "Kumpulkan 4 Tetesan Pigmen Spektrum Murni", "CHROMATIC_PIGMENT")
            ),
            goldReward = 500,
            expReward = 800,
            relicReward = RelicType.THUNDER_CHARM
        ),

        QuestDefinition(
            id = "SQ_VALERIUS_VOW",
            title = "Sumpah Seratus Prajurit Gugur",
            synopsis = "Cari 3 Lencana Perak peninggalan para ajudan Kapten Valerius yang gugur di benteng bawah untuk memberikan penghormatan terakhir.",
            category = QuestCategory.SIDE_HERITAGE,
            actNumber = 1,
            floorTarget = 3,
            recommendedLevel = 2,
            objectives = listOf(
                QuestObjective("SQ2_OBJ1", ObjectiveType.COLLECT_ITEM, 3, 0, "Temukan 3 Lencana Perak Legiun Pertama", "LEGION_SIGNET")
            ),
            goldReward = 250,
            expReward = 400
        ),

        QuestDefinition(
            id = "SQ_VULCANUS_METEOR",
            title = "Api Penempa Bintang Kosmis",
            synopsis = "Kumpulkan 3 bongkahan Batu Meteorit Biru Indigo di tebing angkasa Lantai 7 untuk membuka resep penempaan senjata legendaris Apex Ascension.",
            category = QuestCategory.SIDE_HERITAGE,
            actNumber = 3,
            floorTarget = 7,
            recommendedLevel = 7,
            objectives = listOf(
                QuestObjective("SQ3_OBJ1", ObjectiveType.COLLECT_ITEM, 3, 0, "Kumpulkan 3 Bongkahan Meteorit Kosmis di Lantai 7", "CELESTIAL_ORE")
            ),
            goldReward = 800,
            expReward = 1500,
            talentPointsReward = 1
        )
    )

    fun getQuestById(id: String): QuestDefinition? {
        return allQuests.firstOrNull { it.id == id }
    }

    fun getMainQuests(): List<QuestDefinition> {
        return allQuests.filter { it.category == QuestCategory.MAIN_ODYSSEY }
    }

    fun getSideQuests(): List<QuestDefinition> {
        return allQuests.filter { it.category == QuestCategory.SIDE_HERITAGE }
    }
}
