package com.darumahq.rainbowclimb

import com.darumahq.rainbowclimb.entity.Achievement
import com.darumahq.rainbowclimb.entity.PlayerCharacter
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AchievementTest {

    @Test
    fun `all achievements have unique names`() {
        val names = Achievement.entries.map { it.displayName }
        assertEquals(names.size, names.toSet().size, "Achievement names must be unique")
    }

    @Test
    fun `achievement count matches enum`() {
        assertEquals(14, Achievement.totalCount())
    }
}

class PlayerCharacterTest {

    @Test
    fun `pink man is always unlocked`() {
        assertTrue(PlayerCharacter.PINK_MAN.isUnlocked(0))
    }

    @Test
    fun `characters unlock at correct thresholds`() {
        assertFalse(PlayerCharacter.NINJA_FROG.isUnlocked(999))
        assertTrue(PlayerCharacter.NINJA_FROG.isUnlocked(1000))

        assertFalse(PlayerCharacter.MASK_DUDE.isUnlocked(2499))
        assertTrue(PlayerCharacter.MASK_DUDE.isUnlocked(2500))

        assertFalse(PlayerCharacter.VIRTUAL_GUY.isUnlocked(4999))
        assertTrue(PlayerCharacter.VIRTUAL_GUY.isUnlocked(5000))
    }

    @Test
    fun `unlockedCharacters returns correct list`() {
        assertEquals(1, PlayerCharacter.unlockedCharacters(0).size)
        assertEquals(2, PlayerCharacter.unlockedCharacters(1000).size)
        assertEquals(3, PlayerCharacter.unlockedCharacters(2500).size)
        assertEquals(4, PlayerCharacter.unlockedCharacters(5000).size)
    }
}
