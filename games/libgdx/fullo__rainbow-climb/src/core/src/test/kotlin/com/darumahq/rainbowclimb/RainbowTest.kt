package com.darumahq.rainbowclimb

import com.darumahq.rainbowclimb.entity.Rainbow
import com.darumahq.rainbowclimb.util.Constants
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RainbowTest {

    @Test
    fun `activate on ground creates platform above player`() {
        val r = Rainbow()
        r.activate(100f, 200f, 1, onGround = true)

        assertTrue(r.active)
        assertEquals(Constants.RAINBOW_DURATION, r.timer)
        // Platform should be 48px above player position
        assertEquals(200f + 48f, r.position.y)
        // Should extend to the right (dir=1)
        assertEquals(100f + Constants.PLAYER_WIDTH, r.position.x)
    }

    @Test
    fun `activate in air creates platform below player`() {
        val r = Rainbow()
        r.activate(100f, 200f, -1, onGround = false)

        // Platform should be 6px below player position
        assertEquals(200f - 6f, r.position.y)
        // Should extend to the left (dir=-1)
        assertEquals(100f - Constants.RAINBOW_LENGTH, r.position.x)
    }

    @Test
    fun `bounds match position and size`() {
        val r = Rainbow()
        r.activate(100f, 200f, 1, onGround = true)

        assertEquals(r.position.x, r.bounds.x)
        assertEquals(r.position.y, r.bounds.y)
        assertEquals(Constants.RAINBOW_LENGTH, r.bounds.width)
        assertEquals(Constants.RAINBOW_WIDTH, r.bounds.height)
    }

    @Test
    fun `deactivates after duration`() {
        val r = Rainbow()
        r.activate(100f, 200f, 1, onGround = true)

        // Tick most of the duration
        r.update(Constants.RAINBOW_DURATION - 0.1f)
        assertTrue(r.active)

        // Tick past duration
        r.update(0.2f)
        assertFalse(r.active)
    }

    @Test
    fun `direction normalizes to -1 or 1`() {
        val r1 = Rainbow()
        r1.activate(0f, 0f, 5, onGround = true) // positive → 1
        assertEquals(1, r1.direction)

        val r2 = Rainbow()
        r2.activate(0f, 0f, -3, onGround = true) // negative → -1
        assertEquals(-1, r2.direction)

        val r3 = Rainbow()
        r3.activate(0f, 0f, 0, onGround = true) // zero → 1
        assertEquals(1, r3.direction)
    }
}
