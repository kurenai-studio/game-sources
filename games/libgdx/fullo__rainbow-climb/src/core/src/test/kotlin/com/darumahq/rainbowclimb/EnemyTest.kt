package com.darumahq.rainbowclimb

import com.darumahq.rainbowclimb.entity.Enemy
import com.darumahq.rainbowclimb.entity.EnemyType
import com.darumahq.rainbowclimb.util.Constants
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EnemyTest {

    @Test
    fun `walker patrol clamps position and reverses direction`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.WALKER, 40f)
        e.patrolMinX = 80f
        e.patrolMaxX = 120f

        // Move right until hitting max
        for (i in 0 until 100) e.update(0.016f)

        // Position should be clamped to patrolMaxX
        assertTrue(e.position.x <= e.patrolMaxX)
        assertTrue(e.position.x >= e.patrolMinX)
    }

    @Test
    fun `hopper jumps when reaching baseY`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.HOPPER, 40f)
        e.patrolMinX = 60f
        e.patrolMaxX = 140f

        // After several frames, velocity should be upward at some point
        var hadPositiveVy = false
        for (i in 0 until 200) {
            e.update(0.016f)
            if (e.velocity.y > 0) hadPositiveVy = true
        }
        assertTrue(hadPositiveVy, "Hopper should jump at least once")
    }

    @Test
    fun `shooter fires periodically`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.SHOOTER, 40f)

        // Initial shootTimer is half cooldown (staggered)
        val initial = e.shootTimer
        assertTrue(initial > 0f)

        // Tick until it fires
        var fired = false
        for (i in 0 until 300) {
            e.update(0.016f)
            if (e.wantsToFire) {
                fired = true
                e.wantsToFire = false
            }
        }
        assertTrue(fired, "Shooter should fire within 5 seconds")
    }

    @Test
    fun `shooter wantsToFire resets timer`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.SHOOTER, 40f)
        e.shootTimer = 0.01f // almost ready

        e.update(0.02f) // trigger fire
        assertTrue(e.wantsToFire)
        assertEquals(Constants.SHOOTER_COOLDOWN, e.shootTimer, 0.1f)
    }

    @Test
    fun `bomber elevates above spawn position`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.BOMBER, 40f)

        assertTrue(e.position.y > 200f + Constants.BOMBER_HEIGHT_OFFSET * 0.5f,
            "Bomber should be elevated above spawn Y")
    }

    @Test
    fun `chaser stays idle when not chasing`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.CHASER, 40f)

        assertFalse(e.isChasing)
        assertEquals(0f, e.velocity.x)
        assertEquals(0f, e.velocity.y)

        e.update(0.016f)
        // Still idle — chasing must be triggered by World
        assertFalse(e.isChasing)
    }

    @Test
    fun `chaser stops after duration`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.CHASER, 40f)
        e.isChasing = true
        e.chaseTimer = 0.1f
        e.chaseTargetX = 200f
        e.chaseTargetY = 200f

        e.update(0.2f) // exceed timer
        assertFalse(e.isChasing)
        assertEquals(0f, e.velocity.x)
    }

    @Test
    fun `animState returns correct values`() {
        val walker = Enemy()
        walker.activate(100f, 200f, EnemyType.WALKER, 40f)
        assertEquals("run", walker.animState()) // moving

        val flyer = Enemy()
        flyer.activate(100f, 200f, EnemyType.FLYER, 40f)
        assertEquals("spin", flyer.animState())

        val shooter = Enemy()
        shooter.activate(100f, 200f, EnemyType.SHOOTER, 40f)
        assertEquals("idle", shooter.animState())
        shooter.attackAnimTimer = 0.2f
        assertEquals("attack", shooter.animState())
    }

    @Test
    fun `reset clears all state`() {
        val e = Enemy()
        e.activate(100f, 200f, EnemyType.SHOOTER, 40f)
        e.wantsToFire = true
        e.isChasing = true

        e.reset()
        assertFalse(e.active)
        assertFalse(e.wantsToFire)
        assertFalse(e.isChasing)
        assertEquals(0f, e.stateTime)
    }
}
