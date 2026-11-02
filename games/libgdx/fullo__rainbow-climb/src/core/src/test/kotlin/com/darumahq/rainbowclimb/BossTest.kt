package com.darumahq.rainbowclimb

import com.darumahq.rainbowclimb.entity.Boss
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class BossTest {

    @Test
    fun `first boss has 1 HP`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 1)
        assertEquals(1, b.hp)
        assertEquals(1, b.maxHp)
        assertEquals(1, b.bossNumber)
    }

    @Test
    fun `third boss has 3 HP`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 3)
        assertEquals(3, b.hp)
        assertEquals(3, b.maxHp)
    }

    @Test
    fun `takeDamage decrements HP and enters HIT`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 2)
        b.takeDamage()
        assertEquals(1, b.hp)
        assertEquals(Boss.State.HIT, b.state)
    }

    @Test
    fun `first boss dies in one hit`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 1)
        b.takeDamage()
        assertEquals(0, b.hp)
        assertEquals(Boss.State.HIT, b.state)
    }

    @Test
    fun `takeDamage ignored in HIT state`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 3)
        b.takeDamage()
        val hpAfter = b.hp
        b.takeDamage() // should be ignored
        assertEquals(hpAfter, b.hp)
    }

    @Test
    fun `boss flees after 15 seconds`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 1)

        // Simulate 16 seconds
        for (i in 0 until 1000) {
            b.update(0.016f, 200f, 300f)
        }

        // Boss should be fleeing or gone
        assertTrue(b.state == Boss.State.FLEEING || !b.active,
            "Boss should flee after 15 seconds")
    }

    @Test
    fun `timeRemaining returns correct fraction`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 1)
        assertEquals(1f, b.timeRemaining(), 0.01f)

        // After 7.5 seconds
        for (i in 0 until 469) { // 469 * 0.016 ≈ 7.5s
            b.update(0.016f, 200f, 300f)
        }
        assertEquals(0.5f, b.timeRemaining(), 0.1f)
    }

    @Test
    fun `boss stays on screen horizontally`() {
        val b = Boss()
        b.activate(0f, 500f, 0f, 1)

        for (i in 0 until 200) {
            b.update(0.016f, -1000f, 500f)
        }
        assertTrue(b.position.x >= 0f)
    }

    @Test
    fun `animState returns correct values`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 1)
        assertEquals("idle", b.animState())

        b.state = Boss.State.SWOOP
        assertEquals("attack", b.animState())
        b.state = Boss.State.RETREAT
        assertEquals("run", b.animState())
        b.state = Boss.State.HIT
        assertEquals("hit", b.animState())
        b.state = Boss.State.DEAD
        assertEquals("dead", b.animState())
        b.state = Boss.State.FLEEING
        assertEquals("run", b.animState())
    }

    @Test
    fun `reset clears active`() {
        val b = Boss()
        b.activate(100f, 500f, 0f, 2)
        b.reset()
        assertFalse(b.active)
    }
}
