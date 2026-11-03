package com.stickman.tower.talent

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.character.CharacterArchetype

/**
 * Spesialisasi Sub-Class untuk setiap Arketipe Karakter (Fase 13).
 */
enum class SubClass(
    val idName: String,
    val displayName: String,
    val archetype: CharacterArchetype,
    val title: String,
    val description: String,
    val themeColor: Color,
    val iconSymbol: String
) {
    NONE(
        idName = "NONE",
        displayName = "Novice Adventurer",
        archetype = CharacterArchetype.BALANCED,
        title = "Tanpa Spesialisasi",
        description = "Pilih salah satu sub-class untuk membuka potensi kekuatan tempur sejati.",
        themeColor = Color(0.7f, 0.7f, 0.7f, 1f),
        iconSymbol = "🗡️"
    ),

    // --- Arketipe BALANCED (Swordsman / Warrior) ---
    BERSERKER(
        idName = "BERSERKER",
        displayName = "Berserker",
        archetype = CharacterArchetype.BALANCED,
        title = "Blood & Fury",
        description = "Makin terluka, makin mematikan. Lonjakan damage luar biasa saat HP kritis dan attack speed tinggi.",
        themeColor = Color(0.95f, 0.22f, 0.22f, 1f),
        iconSymbol = "🩸"
    ),
    GUARDIAN(
        idName = "GUARDIAN",
        displayName = "Guardian",
        archetype = CharacterArchetype.BALANCED,
        title = "Iron Bulwark",
        description = "Benteng tak tertembus. Ketahanan fisik tebal, mitigasi damage masif, dan pemulihan HP saat Parry.",
        themeColor = Color(0.25f, 0.65f, 0.95f, 1f),
        iconSymbol = "🛡️"
    ),

    // --- Arketipe AGILE (Assassin / Rogue) ---
    SHADOW_STALKER(
        idName = "SHADOW_STALKER",
        displayName = "Shadow Stalker",
        archetype = CharacterArchetype.AGILE,
        title = "Phantom Assassin",
        description = "Kematian dari kegelapan. Tingkat critical ekstrim, teleport bayangan, dan damage mematikan dari belakang.",
        themeColor = Color(0.85f, 0.35f, 0.95f, 1f),
        iconSymbol = "👁️"
    ),
    VENOMANCER(
        idName = "VENOMANCER",
        displayName = "Venomancer",
        archetype = CharacterArchetype.AGILE,
        title = "Viper Alchemist",
        description = "Racun korosif mematikan. Setiap tebasan melumuri musuh dengan poison DoT dan efek perlambatan gerak.",
        themeColor = Color(0.25f, 0.90f, 0.40f, 1f),
        iconSymbol = "🧪"
    ),

    // --- Arketipe HEAVY (Titan / Mage / Juggernaut) ---
    ARCHMAGE(
        idName = "ARCHMAGE",
        displayName = "Archmage",
        archetype = CharacterArchetype.HEAVY,
        title = "Arcane Overlord",
        description = "Penguasa sihir kehancuran. Reduksi cooldown skill drastis, ledakan AoE masif, dan perisai mana.",
        themeColor = Color(0.40f, 0.50f, 1.0f, 1f),
        iconSymbol = "🔮"
    ),
    SPELLBLADE(
        idName = "SPELLBLADE",
        displayName = "Spellblade",
        archetype = CharacterArchetype.HEAVY,
        title = "Elemental Striker",
        description = "Perpaduan pedang raksasa dan energi elemental. Tebasan melee meledakkan elemen api dan petir.",
        themeColor = Color(1.0f, 0.60f, 0.20f, 1f),
        iconSymbol = "⚡"
    );

    companion object {
        fun getSubClassesFor(archetype: CharacterArchetype): List<SubClass> {
            return entries.filter { it.archetype == archetype && it != NONE }
        }

        fun fromString(id: String): SubClass {
            return entries.firstOrNull { it.name.equals(id, ignoreCase = true) || it.idName.equals(id, ignoreCase = true) } ?: NONE
        }
    }
}
