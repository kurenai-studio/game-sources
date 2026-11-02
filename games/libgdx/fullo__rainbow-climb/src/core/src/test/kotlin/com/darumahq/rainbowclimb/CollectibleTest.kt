package com.darumahq.rainbowclimb

import com.darumahq.rainbowclimb.entity.Collectible
import com.darumahq.rainbowclimb.entity.CollectibleType
import com.darumahq.rainbowclimb.util.Constants
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class CollectibleTest {

    @Test
    fun `activate sets position and bounds`() {
        val c = Collectible()
        c.activate(50f, 100f, CollectibleType.GEM)

        assertEquals(50f, c.position.x)
        assertEquals(100f, c.position.y)
        assertTrue(c.active)
        assertTrue(c.bounds.width > 0f, "Bounds width must be set")
        assertTrue(c.bounds.height > 0f, "Bounds height must be set")
    }

    @Test
    fun `gem has correct score and size`() {
        val c = Collectible()
        c.activate(0f, 0f, CollectibleType.GEM)

        assertEquals(10, c.scoreValue)
        assertEquals(Constants.GEM_SIZE, c.bounds.width)
        assertFalse(c.isPowerUp())
    }

    @Test
    fun `star has correct score`() {
        val c = Collectible()
        c.activate(0f, 0f, CollectibleType.STAR)
        assertEquals(50, c.scoreValue)
        assertFalse(c.isPowerUp())
    }

    @Test
    fun `power-ups are identified correctly`() {
        for (type in listOf(CollectibleType.RAINBOW_BOOST, CollectibleType.DOUBLE_JUMP,
            CollectibleType.SHIELD, CollectibleType.SLOW_TIME, CollectibleType.MAGNET)) {
            val c = Collectible()
            c.activate(0f, 0f, type)
            assertTrue(c.isPowerUp(), "$type should be a power-up")
            assertEquals(25, c.scoreValue)
            assertEquals(Constants.COLLECTIBLE_SIZE, c.bounds.width)
        }
    }

    @Test
    fun `update increments animTimer`() {
        val c = Collectible()
        c.activate(0f, 0f, CollectibleType.GEM)
        assertEquals(0f, c.animTimer)

        c.update(0.5f)
        assertEquals(0.5f, c.animTimer, 0.001f)
    }

    @Test
    fun `update tracks position in bounds`() {
        val c = Collectible()
        c.activate(50f, 100f, CollectibleType.GEM)

        c.position.set(75f, 125f)
        c.update(0.016f)

        assertEquals(75f, c.bounds.x)
        assertEquals(125f, c.bounds.y)
    }
}
