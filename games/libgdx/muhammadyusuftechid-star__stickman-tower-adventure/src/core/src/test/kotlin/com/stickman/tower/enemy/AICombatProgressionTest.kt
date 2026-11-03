package com.stickman.tower.enemy

import com.stickman.tower.character.Player
import com.stickman.tower.physics.Platform
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AICombatProgressionTest {

    @BeforeTest
    fun setup() {
        CombatDirector.reset()
    }

    @Test
    fun testCombatDirectorTokenAllocationAndLimits() {
        val enemy1 = Enemy(spawnX = 0f, spawnY = 0f, type = EnemyType.MELEE)
        val enemy2 = Enemy(spawnX = 2f, spawnY = 0f, type = EnemyType.MELEE)
        val enemy3 = Enemy(spawnX = 4f, spawnY = 0f, type = EnemyType.MELEE)
        val archer1 = Enemy(spawnX = 8f, spawnY = 0f, type = EnemyType.RANGED)
        val archer2 = Enemy(spawnX = 10f, spawnY = 0f, type = EnemyType.RANGED)

        // 1. Melee tokens limit: max 2
        assertTrue(CombatDirector.requestMeleeToken(enemy1), "Enemy 1 should receive first melee attack token")
        assertTrue(CombatDirector.requestMeleeToken(enemy2), "Enemy 2 should receive second melee attack token")
        assertFalse(CombatDirector.requestMeleeToken(enemy3), "Enemy 3 must be denied melee token when quota (2) is full")

        assertEquals(2, CombatDirector.activeMeleeTokensCount)

        // 2. Ranged tokens limit: max 1
        assertTrue(CombatDirector.requestRangedToken(archer1), "Archer 1 should receive ranged attack token")
        assertFalse(CombatDirector.requestRangedToken(archer2), "Archer 2 must be denied ranged token when quota (1) is full")

        assertEquals(1, CombatDirector.activeRangedTokensCount)

        // 3. Release token allows queued enemy to obtain it
        CombatDirector.releaseToken(enemy1)
        assertEquals(1, CombatDirector.activeMeleeTokensCount)
        assertTrue(CombatDirector.requestMeleeToken(enemy3), "Enemy 3 should now obtain freed melee token")

        // 4. Token Timeout Safety
        CombatDirector.update(CombatDirector.TOKEN_TIMEOUT + 0.1f)
        assertEquals(0, CombatDirector.totalActiveTokens, "All tokens must be cleanly released after watchdog timeout")
    }

    @Test
    fun testShieldedEnemyFrontalDefenseAndCrossUpBackstab() {
        val shieldEnemy = Enemy(spawnX = 10f, spawnY = 0f, type = EnemyType.SHIELDED)

        // Enemy is facing right by default
        assertTrue(shieldEnemy.facingRight)
        assertTrue(shieldEnemy.isShieldGuarding(), "Shield should be active by default")

        // Player attacks from the front (x = 12f, to the right of enemy facing right)
        assertTrue(shieldEnemy.canBlockHitFrom(attackerX = 12f), "Frontal attack must be blocked by shield")

        // Player attacks from behind (x = 8f, cross-up backstab behind enemy)
        assertFalse(shieldEnemy.canBlockHitFrom(attackerX = 8f), "Attack from behind (cross-up) must bypass shield")

        // Guard Break test
        shieldEnemy.breakGuard(1.5f)
        assertTrue(shieldEnemy.isGuardBroken, "Guard should be marked as broken")
        assertEquals(EnemyState.STUNNED, shieldEnemy.state, "Enemy must be stunned on guard break")
        assertFalse(shieldEnemy.isShieldGuarding(), "Shield must not guard while guard-broken/stunned")
        assertFalse(shieldEnemy.canBlockHitFrom(attackerX = 12f), "Broken shield cannot block frontal attacks")
    }

    @Test
    fun testFlyingEnemyHoveringAndSwoopAttack() {
        val ground = listOf(Platform(x = -10f, y = -1f, width = 40f, height = 1f))
        val flying = Enemy(spawnX = 10f, spawnY = 4f, type = EnemyType.FLYING)
        val player = Player(spawnX = 12f, spawnY = 0f)

        // 1. Initial State: PATROL hovering in air without falling down from gravity
        flying.update(delta = 0.05f, player = player, platforms = ground)
        assertEquals(EnemyState.CHASE, flying.state)
        assertTrue(flying.position.y > 1.5f, "Flying enemy must maintain aerial elevation and not collapse to ground")

        // 2. Flying enemy requests token and initiates swoop attack
        for (i in 0 until 5) {
            flying.update(delta = 0.05f, player = player, platforms = ground)
        }

        if (flying.state == EnemyState.ATTACK) {
            // During dive active phase (0.25s - 0.65s)
            for (i in 0 until 6) {
                flying.update(delta = 0.05f, player = player, platforms = ground)
            }
            assertTrue(flying.hitbox.isActive, "Hitbox must be active during divebomb swoop")
            assertTrue(flying.velocity.y < 0f, "Vertical velocity must be downwards during swoop dive")
        }
    }

    @Test
    fun testEnemyGapLeapNavigation() {
        // Two platforms separated by a 2.5m gap (plat1: x=0..6, plat2: x=8.5..15)
        val platforms = listOf(
            Platform(x = 0f, y = 0f, width = 6f, height = 1f),
            Platform(x = 8.5f, y = 0f, width = 7f, height = 1f)
        )
        val enemy = Enemy(spawnX = 5.2f, spawnY = 1.0f, type = EnemyType.MELEE)
        val player = Player(spawnX = 10.0f, spawnY = 1.0f)

        // Frame 1: Grounded in CHASE approaching edge
        enemy.update(delta = 0.05f, player = player, platforms = platforms)
        assertEquals(EnemyState.CHASE, enemy.state)

        // Frame 2: Gap detected, enemy executes gap leap
        enemy.update(delta = 0.05f, player = player, platforms = platforms)
        assertTrue(enemy.velocity.y > 5.0f || enemy.position.x > 5.0f, "Enemy should leap across the gap toward player")
    }

    @Test
    fun testBossDistinctPersonalities() {
        val ground = listOf(Platform(x = -10f, y = 0f, width = 40f, height = 1f))
        val player = Player(spawnX = 10f, spawnY = 1f)

        // 1. Matron: Evasive Leap when player closes into melee (< 3.2m)
        val matron = BossEnemy(spawnX = 12f, spawnY = 1f, type = BossType.AMETHYST_MATRON)
        matron.attackCooldown = 0f
        matron.state = BossState.CHASE
        matron.update(delta = 0.05f, player = player, platforms = ground)
        assertEquals(BossState.EVASIVE_LEAP, matron.state, "Amethyst Matron must evasively backflip away from close melee range")
        assertTrue(matron.velocity.x > 0f, "Matron must leap away (rightwards) from player on left")

        // 2. Sovereign: Blood Blink when in mid/long range
        val sovereign = BossEnemy(spawnX = 18f, spawnY = 1f, type = BossType.CRIMSON_SOVEREIGN)
        sovereign.attackCooldown = 0f
        sovereign.state = BossState.CHASE
        // Update sovereign in range
        sovereign.update(delta = 0.05f, player = player, platforms = ground)
        assertTrue(sovereign.state == BossState.BLOOD_BLINK || sovereign.state == BossState.WIND_SLASH || sovereign.state == BossState.CLEAVE, "Sovereign must use signature blood moves")

        // 3. Calligrapher: Ink Rune Summoning
        val calligrapher = BossEnemy(spawnX = 20f, spawnY = 1f, type = BossType.GRAND_CALLIGRAPHER)
        calligrapher.state = BossState.SUMMON_RUNES
        calligrapher.update(delta = 0.60f, player = player, platforms = ground)
        assertTrue(calligrapher.projectiles.isNotEmpty(), "Calligrapher should erupt an ink geyser projectile from ink rune")
    }
}
