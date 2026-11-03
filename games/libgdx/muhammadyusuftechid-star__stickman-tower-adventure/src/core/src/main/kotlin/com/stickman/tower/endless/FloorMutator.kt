package com.stickman.tower.endless

import com.badlogic.gdx.graphics.Color
import kotlin.random.Random

/**
 * Mutator Lingkungan & Pertarungan Prosedural untuk Mode Endless Spire (Fase 13).
 * Setiap lantai menara tanpa batas menghadirkan kondisi pertarungan unik yang menuntut adaptasi taktik.
 */
enum class FloorMutator(
    val title: String,
    val description: String,
    val badgeColor: Color,
    val iconSymbol: String,
    val gravityMultiplier: Float = 1.0f,
    val playerDamageMultiplier: Float = 1.0f,
    val enemyDamageMultiplier: Float = 1.0f,
    val enemySpeedMultiplier: Float = 1.0f,
    val lifestealPercent: Float = 0f,
    val miasmaInterval: Float = 0f
) {
    NONE(
        title = "Standard Domain",
        description = "Kondisi lantai normal tanpa mutasi anomali.",
        badgeColor = Color(0.7f, 0.7f, 0.7f, 0.9f),
        iconSymbol = "⚔️"
    ),

    TOXIC_MIASMA(
        title = "Toxic Miasma",
        description = "Kabut beracun merayap di lantai; pemain menerima poison tick 4 damage setiap 4.5 detik.",
        badgeColor = Color(0.25f, 0.85f, 0.35f, 0.95f),
        iconSymbol = "☣️",
        miasmaInterval = 4.5f
    ),

    BERSERK_SURGE(
        title = "Berserk Surge",
        description = "Adrenalin memuncak: Musuh +25% SPD & ATK, namun serangan pemain +30% ATK dan 10% Lifesteal.",
        badgeColor = Color(1.0f, 0.28f, 0.15f, 0.95f),
        iconSymbol = "⚡",
        playerDamageMultiplier = 1.30f,
        enemyDamageMultiplier = 1.25f,
        enemySpeedMultiplier = 1.25f,
        lifestealPercent = 0.10f
    ),

    LOW_GRAVITY(
        title = "Low Gravity",
        description = "Gravitasi anomali berkurang 35%; lompatan jauh lebih melayang untuk pertempuran udara.",
        badgeColor = Color(0.35f, 0.75f, 1.0f, 0.95f),
        iconSymbol = "🌌",
        gravityMultiplier = 0.65f
    ),

    SPIKE_FRENZY(
        title = "Spike Frenzy",
        description = "Duri lingkungan berlipat ganda dan lebih mematikan; mobilitas presisi mutlak dibutuhkan.",
        badgeColor = Color(0.95f, 0.65f, 0.15f, 0.95f),
        iconSymbol = "⚠️",
        enemyDamageMultiplier = 1.15f
    ),

    VAMPIRIC_ECLIPSE(
        title = "Vampiric Eclipse",
        description = "Bulan darah merah pekat; setiap serangan pemain menyerap 15% HP, namun musuh juga menyerap 8% HP.",
        badgeColor = Color(0.95f, 0.15f, 0.45f, 0.95f),
        iconSymbol = "🩸",
        playerDamageMultiplier = 1.10f,
        lifestealPercent = 0.15f
    );

    val displayName: String get() = title
    val iconRune: String get() = iconSymbol
    val playerAttackMultiplier: Float get() = playerDamageMultiplier
    val enemyAttackMultiplier: Float get() = enemyDamageMultiplier
    val isToxicMiasma: Boolean get() = this == TOXIC_MIASMA

    companion object {
        /**
         * Memilih mutator acak secara prosedural untuk lantai endless tertentu.
         */
        fun getRandomMutator(floorNumber: Int = 4, seed: Long = System.currentTimeMillis()): FloorMutator {
            val candidates = values().filter { it != NONE }
            if (candidates.isEmpty()) return NONE
            val rng = Random(seed + floorNumber * 31L)
            return candidates[rng.nextInt(candidates.size)]
        }
    }
}
