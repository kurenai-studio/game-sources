package com.stickman.tower.combat

import com.stickman.tower.character.Player
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossState
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.enemy.EnemyState
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.input.GameInput
import com.stickman.tower.physics.Platform
import com.stickman.tower.rpg.CharacterStats
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ParryTest {

    private class DummyInput(
        private val moveLeft: Boolean = false,
        private val moveRight: Boolean = false,
        private val jumpJustPressed: Boolean = false,
        private val jumpPressed: Boolean = false,
        private val attackJustPressed: Boolean = false,
        private val skillJustPressed: Boolean = false,
        private val ultJustPressed: Boolean = false,
        private val dodgeJustPressed: Boolean = false
    ) : GameInput {
        override fun isMoveLeft(): Boolean = moveLeft
        override fun isMoveRight(): Boolean = moveRight
        override fun isJumpJustPressed(): Boolean = jumpJustPressed
        override fun isJumpPressed(): Boolean = jumpPressed
        override fun isAttackJustPressed(): Boolean = attackJustPressed
        override fun isDodgeJustPressed(): Boolean = dodgeJustPressed
        override fun isSkillJustPressed(): Boolean = skillJustPressed
        override fun isUltimateJustPressed(): Boolean = ultJustPressed
    }

    private val testPlatform = listOf(Platform(x = -20f, y = -1f, width = 60f, height = 1f))

    @Test
    fun testParryWindowDuringDodge() {
        val player = Player(spawnX = 0f, spawnY = 0f)

        assertFalse(player.isDodging)
        assertFalse(player.isParrying)

        // Trigger dodge roll
        val dodgeInput = DummyInput(dodgeJustPressed = true)
        player.update(0.01f, dodgeInput, testPlatform)

        assertTrue(player.isDodging, "Player should be dodging")
        assertTrue(player.isParrying, "Player should be in parry window during first 0.12s of dodge")

        // Advance 0.05s (total 0.06s < 0.12s)
        val idleInput = DummyInput()
        player.update(0.05f, idleInput, testPlatform)
        assertTrue(player.isDodging)
        assertTrue(player.isParrying, "Player should still be in parry window at 0.06s")

        // Advance past 0.12s (total 0.16s)
        player.update(0.10f, idleInput, testPlatform)
        assertTrue(player.isDodging, "Player should still be invulnerable during rest of dodge")
        assertFalse(player.isParrying, "Parry window should expire after 0.12s")
    }

    @Test
    fun testParryTriggerBuffAndEnergy() {
        val stats = CharacterStats(baseCritRate = 0f)
        val player = Player(spawnX = 0f, spawnY = 0f, stats = stats)
        assertEquals(0f, player.ultimate.currentEnergy)
        assertFalse(player.hasParryBuff)

        // Trigger parry
        var parryCallbackFired = false
        player.onParry = { _, _ -> parryCallbackFired = true }
        player.triggerParry()

        assertTrue(parryCallbackFired)
        assertEquals(35f, player.ultimate.currentEnergy, "Parry should award +35% ultimate energy")
        assertTrue(player.hasParryBuff, "Parry should activate +25% attack damage buff")

        // Perform attack with parry buff active (Hit 1 base damage is 12f)
        val attackInput = DummyInput(attackJustPressed = true)
        player.update(0.01f, attackInput, testPlatform)

        // Buff should be consumed immediately on attack initiation
        assertFalse(player.hasParryBuff, "Parry buff should be consumed upon initiating attack")
        val expectedBuffedDmg = 12f * 1.25f // 15.0f
        assertEquals(expectedBuffedDmg, player.hitbox.damage, 0.01f, "Attack should deal +25% damage from parry buff")

        // Advance past startup (0.08s) into active frames
        player.update(0.08f, DummyInput(), testPlatform)
        assertTrue(player.hitbox.isActive, "Hitbox should be active during attack active window")
    }

    @Test
    fun testEnemyStunGuardBreak() {
        val enemy = Enemy(spawnX = 5f, spawnY = 0f, type = EnemyType.MELEE)
        val player = Player(spawnX = 4f, spawnY = 0f)

        // Enemy starts in PATROL
        assertEquals(EnemyState.PATROL, enemy.state)

        // Trigger Stun Guard Break (1.5s)
        enemy.stun(1.5f)
        assertEquals(EnemyState.STUNNED, enemy.state)
        assertFalse(enemy.hitbox.isActive, "Hitbox must be deactivated when stunned")
        assertEquals(0f, enemy.velocity.x, "Velocity X must stop when stunned")

        // Update 0.8s: still stunned
        enemy.update(0.8f, player, testPlatform)
        assertEquals(EnemyState.STUNNED, enemy.state)

        // Update remaining 0.8s: stun expires and enemy recovers
        enemy.update(0.8f, player, testPlatform)
        assertTrue(enemy.state != EnemyState.STUNNED, "Enemy should recover after stun duration expires")
    }

    @Test
    fun testBossStunGuardBreak() {
        val boss = BossEnemy(spawnX = 10f, spawnY = 0f)
        val player = Player(spawnX = 8f, spawnY = 0f)

        assertEquals(BossState.IDLE, boss.state)

        // Trigger Stun Guard Break (1.5s)
        boss.stun(1.5f)
        assertEquals(BossState.STUNNED, boss.state)
        assertFalse(boss.hitbox.isActive, "Boss hitbox must be deactivated when stunned")
        assertEquals(0f, boss.velocity.x, "Boss velocity X must stop when stunned")

        // Update 0.8s: still stunned
        boss.update(0.8f, player, testPlatform)
        assertEquals(BossState.STUNNED, boss.state)

        // Update remaining 0.8s: stun expires and boss recovers
        boss.update(0.8f, player, testPlatform)
        assertTrue(boss.state != BossState.STUNNED, "Boss should recover after stun duration expires")
    }
}
