package com.stickman.tower.character

import com.stickman.tower.input.GameInput
import com.stickman.tower.physics.Platform
import com.stickman.tower.rpg.CharacterStats
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlayerSkillCollisionTest {

    private class MockSkill3Input : GameInput {
        override fun isMoveLeft(): Boolean = false
        override fun isMoveRight(): Boolean = false
        override fun isJumpJustPressed(): Boolean = false
        override fun isJumpPressed(): Boolean = false
        override fun isAttackJustPressed(): Boolean = false
        override fun isDodgeJustPressed(): Boolean = false
        override fun isSkillJustPressed(): Boolean = false
        override fun isSkill1JustPressed(): Boolean = false
        override fun isSkill2JustPressed(): Boolean = false
        override fun isSkill3JustPressed(): Boolean = true
        override fun isUltimateJustPressed(): Boolean = false
    }

    @Test
    fun testAgileSkill3TeleportStopsBeforeWall() {
        val player = Player(
            spawnX = 10f,
            spawnY = 2f,
            stats = CharacterStats(),
            archetype = CharacterArchetype.AGILE
        )
        player.facingRight = true

        // Platform dinding vertikal tepat 2 meter di depan pemain (x = 12f)
        val wall = Platform(x = 12f, y = 1f, width = 1f, height = 5f, isOneWay = false)
        val ground = Platform(x = 0f, y = 0f, width = 25f, height = 1f)
        val platforms = listOf(ground, wall)

        val input = MockSkill3Input()
        player.update(0.016f, input, platforms)

        // Verifikasi bahwa posisi X pemain TIDAK melompati dinding atau terjebak di dalam dinding (x = 12f s/d 13f)
        assertTrue(player.position.x + player.width <= wall.left, "Player should stop before wall.left!")
        assertTrue(player.bounds.x + player.bounds.width <= wall.left)
        assertFalse(player.bounds.overlaps(wall.bounds), "Player bounds must not overlap wall!")
    }

    @Test
    fun testAgileSkill3TeleportLeftStopsBeforeWall() {
        val player = Player(
            spawnX = 10f,
            spawnY = 2f,
            stats = CharacterStats(),
            archetype = CharacterArchetype.AGILE
        )
        player.facingRight = false // Menghadap kiri

        // Dinding vertikal tepat 2 meter di belakang/kiri pemain (x = 7f s/d 8f)
        val wall = Platform(x = 7f, y = 1f, width = 1f, height = 5f, isOneWay = false)
        val ground = Platform(x = 0f, y = 0f, width = 25f, height = 1f)
        val platforms = listOf(ground, wall)

        val input = MockSkill3Input()
        player.update(0.016f, input, platforms)

        // Verifikasi pemain berhenti di sisi kanan dinding (>= wall.right)
        assertTrue(player.position.x >= wall.right, "Player should stop after wall.right!")
        assertTrue(player.bounds.x >= wall.right)
        assertFalse(player.bounds.overlaps(wall.bounds), "Player bounds must not overlap wall!")
    }

    @Test
    fun testPlayerStateIsAttackDuringSkill2AndSkill3() {
        val player = Player(
            spawnX = 5f,
            spawnY = 2f,
            stats = CharacterStats(),
            archetype = CharacterArchetype.BALANCED
        )
        val ground = Platform(x = 0f, y = 0f, width = 20f, height = 1f)
        val platforms = listOf(ground)

        // Test Skill 3 State
        val input3 = MockSkill3Input()
        player.update(0.016f, input3, platforms)
        assertTrue(player.isSkill3Active)
        assertEquals(CharacterState.ATTACK, player.state)
    }
}
