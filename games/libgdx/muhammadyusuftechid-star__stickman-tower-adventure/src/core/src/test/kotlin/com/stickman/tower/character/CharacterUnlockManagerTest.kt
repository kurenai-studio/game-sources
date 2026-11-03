package com.stickman.tower.character

import com.stickman.tower.rpg.SaveData
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit Test untuk Validasi Sistem Hero Unlock Odyssey (Fase 24).
 * Memastikan aturan ludonaratif pembukaan karakter:
 * - Kaelen (Balanced) terbuka secara default.
 * - Zephyr (Agile) terkunci hingga diselamatkan di Lantai 10.
 * - Gorgon (Heavy) terkunci hingga diselamatkan di Lantai 20.
 */
class CharacterUnlockManagerTest {

    @Test
    fun testDefaultSaveOnlyBalancedUnlocked() {
        val defaultSave = SaveData()
        assertTrue("Kaelen (Balanced) harus terbuka sejak awal petualangan",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.BALANCED, defaultSave))
        assertFalse("Zephyr (Agile) harus terkunci pada awal petualangan",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.AGILE, defaultSave))
        assertFalse("Gorgon (Heavy) harus terkunci pada awal petualangan",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.HEAVY, defaultSave))
    }

    @Test
    fun testZephyrUnlockedAfterFloor10Rescue() {
        val save = SaveData()
        save.isZephyrRescued = true
        assertTrue("Zephyr harus terbuka jika isZephyrRescued = true",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.AGILE, save))

        val floor11Save = SaveData()
        floor11Save.highestTowerFloor = 11
        assertTrue("Zephyr harus terbuka jika pemain telah menembus lantai 11+",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.AGILE, floor11Save))

        val legacySave = SaveData()
        legacySave.unlockedCharacters.add("STICKMAN_DAGGER")
        assertTrue("Zephyr harus terbuka jika tag STICKMAN_DAGGER ada di unlockedCharacters",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.AGILE, legacySave))
    }

    @Test
    fun testGorgonUnlockedAfterFloor20Rescue() {
        val save = SaveData()
        save.isGorgonRescued = true
        assertTrue("Gorgon harus terbuka jika isGorgonRescued = true",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.HEAVY, save))

        val floor21Save = SaveData()
        floor21Save.highestTowerFloor = 21
        assertTrue("Gorgon harus terbuka jika pemain telah menembus lantai 21+",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.HEAVY, floor21Save))

        val legacySave = SaveData()
        legacySave.unlockedCharacters.add("STICKMAN_HEAVY")
        assertTrue("Gorgon harus terbuka jika tag STICKMAN_HEAVY ada di unlockedCharacters",
            CharacterUnlockManager.isUnlocked(CharacterArchetype.HEAVY, legacySave))
    }

    @Test
    fun testUnlockMethodsMutateSaveCorrectly() {
        val save = SaveData()
        CharacterUnlockManager.unlockZephyr(save)
        assertTrue(save.isZephyrRescued)
        assertTrue(save.unlockedCharacters.contains("STICKMAN_DAGGER"))
        assertTrue(CharacterUnlockManager.isUnlocked(CharacterArchetype.AGILE, save))

        CharacterUnlockManager.unlockGorgon(save)
        assertTrue(save.isGorgonRescued)
        assertTrue(save.unlockedCharacters.contains("STICKMAN_HEAVY"))
        assertTrue(CharacterUnlockManager.isUnlocked(CharacterArchetype.HEAVY, save))
    }

    @Test
    fun testUnlockRequirementTextIsNonEmptyAndDescriptive() {
        val kaelenText = CharacterUnlockManager.getUnlockRequirementText(CharacterArchetype.BALANCED)
        val zephyrText = CharacterUnlockManager.getUnlockRequirementText(CharacterArchetype.AGILE)
        val gorgonText = CharacterUnlockManager.getUnlockRequirementText(CharacterArchetype.HEAVY)

        assertTrue(kaelenText.isNotEmpty())
        assertTrue(zephyrText.contains("Lantai 10") || zephyrText.contains("Calligrapher"))
        assertTrue(gorgonText.contains("Lantai 20") || gorgonText.contains("Vulcanus"))
    }

    @Test
    fun testMaxStoryFloorsConstantIsFifty() {
        assertEquals(50, SaveData.MAX_STORY_FLOORS)
    }
}
