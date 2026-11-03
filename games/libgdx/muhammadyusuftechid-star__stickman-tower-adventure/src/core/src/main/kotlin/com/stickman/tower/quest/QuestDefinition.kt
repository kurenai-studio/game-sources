package com.stickman.tower.quest

import com.stickman.tower.relic.RelicType

/**
 * Kategori misi kanonikal di menara Aethelgard.
 */
enum class QuestCategory(val displayName: String, val symbol: String) {
    MAIN_ODYSSEY("Kampanye Cerita Utama", "◈"),
    SIDE_HERITAGE("Warisan Kuno", "◇"),
    SCRIBE_TRIAL("Ujian Para Kaligrafer", "⚔"),
    BOUNTY_HUNT("Kontrak Buronan Elit", "☠")
}

/**
 * Siklus hidup status misi (Finite State Machine).
 */
enum class QuestStatus {
    LOCKED,
    AVAILABLE,
    ACTIVE,
    OBJECTIVES_MET,
    COMPLETED,
    FAILED
}

/**
 * Tipe objektif misi yang dipantau oleh engine tempur dan platforming.
 */
enum class ObjectiveType {
    CLEAR_FLOOR,
    DEFEAT_BOSS,
    PERFECT_PARRY,
    COLLECT_ITEM,
    READ_TABLET,
    UPGRADE_WEAPON,
    SPECIAL_ACTION
}

/**
 * Satu target capaian dalam misi.
 */
data class QuestObjective(
    val id: String,
    val type: ObjectiveType,
    val targetCount: Int,
    var currentCount: Int = 0,
    val description: String,
    val targetIdentifier: String = "" // Contoh: "TABLET_1", "TOWER_GUARDIAN", "CHROMATIC_PIGMENT"
) {
    val isComplete: Boolean get() = currentCount >= targetCount

    fun reset() {
        currentCount = 0
    }
}

/**
 * Definisi kontrak misi lengkap di Stickman Tower Adventure.
 */
data class QuestDefinition(
    val id: String,
    val title: String,
    val synopsis: String,
    val category: QuestCategory,
    val actNumber: Int,
    val floorTarget: Int,
    val recommendedLevel: Int,
    val objectives: List<QuestObjective>,
    val goldReward: Int,
    val expReward: Int,
    val relicReward: RelicType? = null,
    val talentPointsReward: Int = 0
) {
    val isAllObjectivesMet: Boolean
        get() = objectives.all { it.isComplete }
}
