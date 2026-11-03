package com.stickman.tower.character

import com.stickman.tower.rpg.SaveData

/**
 * CharacterUnlockManager:
 * Mengelola aturan ludonaratif pembukaan karakter (Hero Odyssey):
 * - BALANCED (Kaelen): Terbuka sejak awal petualangan / Prolog Padang Abu.
 * - AGILE (Zephyr): Terbuka setelah diselamatkan di Lantai 10 (Sarang Lady Vespera).
 * - HEAVY (Gorgon): Terbuka setelah dibebaskan di Lantai 20 (Ambang Kawah Titan).
 */
object CharacterUnlockManager {
    const val FLOOR_UNLOCK_ZEPHYR = 10
    const val FLOOR_UNLOCK_GORGON = 20

    const val ID_KAELEN = "STICKMAN_SWORD"
    const val ID_ZEPHYR = "STICKMAN_DAGGER"
    const val ID_GORGON = "STICKMAN_HEAVY"

    fun getCharacterId(archetype: CharacterArchetype): String {
        return when (archetype) {
            CharacterArchetype.BALANCED -> ID_KAELEN
            CharacterArchetype.AGILE -> ID_ZEPHYR
            CharacterArchetype.HEAVY -> ID_GORGON
        }
    }

    /**
     * Memeriksa apakah karakter dapat dimainkan berdasarkan progres save data.
     */
    fun isUnlocked(archetype: CharacterArchetype, save: SaveData): Boolean = isCharacterUnlocked(archetype, save)

    fun isCharacterUnlocked(archetype: CharacterArchetype, save: SaveData): Boolean {
        return when (archetype) {
            CharacterArchetype.BALANCED -> true
            CharacterArchetype.AGILE -> {
                save.isZephyrRescued ||
                save.highestTowerFloor > FLOOR_UNLOCK_ZEPHYR ||
                save.unlockedCharacters.contains(ID_ZEPHYR)
            }
            CharacterArchetype.HEAVY -> {
                save.isGorgonRescued ||
                save.highestTowerFloor > FLOOR_UNLOCK_GORGON ||
                save.unlockedCharacters.contains(ID_GORGON)
            }
        }
    }

    /**
     * Membuka Zephyr setelah event penyelamatan di Lantai 10.
     */
    fun unlockZephyr(save: SaveData): Boolean {
        var changed = false
        if (!save.isZephyrRescued) {
            save.isZephyrRescued = true
            changed = true
        }
        if (!save.unlockedCharacters.contains(ID_ZEPHYR)) {
            save.unlockedCharacters.add(ID_ZEPHYR)
            changed = true
        }
        return changed
    }

    /**
     * Membuka Gorgon setelah event pembebasan di Lantai 20.
     */
    fun unlockGorgon(save: SaveData): Boolean {
        var changed = false
        if (!save.isGorgonRescued) {
            save.isGorgonRescued = true
            changed = true
        }
        if (!save.unlockedCharacters.contains(ID_GORGON)) {
            save.unlockedCharacters.add(ID_GORGON)
            changed = true
        }
        return changed
    }

    /**
     * Memberikan deskripsi persyaratan pembukaan karakter.
     */
    fun getUnlockRequirementText(archetype: CharacterArchetype): String {
        return when (archetype) {
            CharacterArchetype.BALANCED -> "Tersedia Sejak Awal (Pewaris Bara Emas)"
            CharacterArchetype.AGILE -> "Terkunci: Capai & Selesaikan Lantai 10 untuk menyelamatkan Zephyr"
            CharacterArchetype.HEAVY -> "Terkunci: Capai & Selesaikan Lantai 20 untuk membebaskan Gorgon"
        }
    }

    /**
     * Memberikan teks lencana singkat untuk kartu UI.
     */
    fun getUnlockShortBadge(archetype: CharacterArchetype, isUnlocked: Boolean): String {
        if (isUnlocked) return "TERBUKA"
        return when (archetype) {
            CharacterArchetype.BALANCED -> "TERBUKA"
            CharacterArchetype.AGILE -> "KUNCI LT 10"
            CharacterArchetype.HEAVY -> "KUNCI LT 20"
        }
    }
}
