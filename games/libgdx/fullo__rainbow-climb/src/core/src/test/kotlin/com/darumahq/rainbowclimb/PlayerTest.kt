package com.darumahq.rainbowclimb

import com.darumahq.rainbowclimb.entity.Player
import com.darumahq.rainbowclimb.util.Constants
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PlayerTest {

    private lateinit var player: Player

    @BeforeEach
    fun setup() {
        player = Player()
        player.isAlive = true
        player.isOnGround = true
    }

    @Test
    fun `initial state is correct`() {
        val p = Player()
        assertTrue(p.isAlive)
        assertEquals(2, p.lives)
        assertEquals(Constants.RAINBOW_MAX_AMMO, p.rainbowAmmo)
        assertEquals(1, p.facing)
        assertEquals(0f, p.invincibleTimer)
    }

    @Test
    fun `jump sets velocity and clears ground`() {
        player.jump()
        assertEquals(Constants.JUMP_VELOCITY, player.velocity.y)
        assertFalse(player.isOnGround)
    }

    @Test
    fun `cannot jump when not on ground without double jump`() {
        player.isOnGround = false
        player.hasDoubleJump = false
        player.velocity.y = 100f
        player.jump()
        assertEquals(100f, player.velocity.y) // unchanged
    }

    @Test
    fun `double jump works once in air`() {
        player.hasDoubleJump = true
        player.jump() // first jump (from ground)
        player.isOnGround = false
        player.velocity.y = 0f

        player.jump() // double jump (in air)
        assertEquals(Constants.JUMP_VELOCITY, player.velocity.y)
        assertTrue(player.doubleJumpUsed)

        player.velocity.y = 0f
        player.jump() // third jump should fail
        assertEquals(0f, player.velocity.y)
    }

    @Test
    fun `moveLeft sets facing and velocity`() {
        player.moveLeft()
        assertEquals(-1, player.facing)
        assertEquals(-Constants.MOVE_SPEED, player.velocity.x)
    }

    @Test
    fun `moveRight sets facing and velocity`() {
        player.moveRight()
        assertEquals(1, player.facing)
        assertEquals(Constants.MOVE_SPEED, player.velocity.x)
    }

    @Test
    fun `stopMoving zeroes velocity`() {
        player.moveRight()
        player.stopMoving()
        assertEquals(0f, player.velocity.x)
    }

    @Test
    fun `shootRainbow decrements ammo`() {
        val before = player.rainbowAmmo
        assertTrue(player.shootRainbow())
        assertEquals(before - 1, player.rainbowAmmo)
    }

    @Test
    fun `shootRainbow fails when out of ammo`() {
        player.rainbowAmmo = 0
        assertFalse(player.shootRainbow())
    }

    @Test
    fun `shootRainbow fails when dead`() {
        player.isAlive = false
        assertFalse(player.shootRainbow())
    }

    @Test
    fun `animState returns correct states`() {
        assertEquals("idle", player.animState())

        player.moveRight()
        assertEquals("run", player.animState())

        player.isOnGround = false
        player.velocity.y = 100f
        assertEquals("jump", player.animState())

        player.velocity.y = -100f
        assertEquals("fall", player.animState())

        player.isAlive = false
        assertEquals("hit", player.animState())
    }

    @Test
    fun `invincibility timer decrements`() {
        player.invincibleTimer = 5f
        assertTrue(player.isInvincible)

        // Simulate update
        player.update(1f)
        assertEquals(4f, player.invincibleTimer, 0.01f)

        player.invincibleTimer = 0f
        assertFalse(player.isInvincible)
    }

    @Test
    fun `reset restores all defaults`() {
        player.lives = 0
        player.isAlive = false
        player.rainbowAmmo = 0
        player.shieldActive = true
        player.invincibleTimer = 3f

        player.reset()

        assertTrue(player.isAlive)
        assertEquals(2, player.lives)
        assertEquals(Constants.RAINBOW_MAX_AMMO, player.rainbowAmmo)
        assertFalse(player.shieldActive)
        assertEquals(0f, player.invincibleTimer)
    }
}
