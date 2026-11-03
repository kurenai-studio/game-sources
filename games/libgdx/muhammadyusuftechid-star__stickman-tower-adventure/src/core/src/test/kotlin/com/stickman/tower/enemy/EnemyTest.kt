package com.stickman.tower.enemy

import com.stickman.tower.character.Player
import com.stickman.tower.physics.Platform
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EnemyTest {

    @Test
    fun testEnemyTypeStats() {
        val melee = Enemy(spawnX = 0f, spawnY = 0f, type = EnemyType.MELEE)
        val ranged = Enemy(spawnX = 0f, spawnY = 0f, type = EnemyType.RANGED)

        // Verifikasi HP
        assertEquals(50f, melee.health.maxHp)
        assertEquals(40f, ranged.health.maxHp)

        // Verifikasi Hitbox Melee vs Ranged
        assertEquals(12f, melee.hitbox.damage)
        assertEquals(8f, ranged.hitbox.damage)

        // Verifikasi Reward RPG
        assertEquals(25, melee.expReward)
        assertEquals(10, melee.goldReward)

        assertEquals(35, ranged.expReward)
        assertEquals(15, ranged.goldReward)
    }

    @Test
    fun testRangedEnemyKitingBehavior() {
        val ground = listOf(Platform(x = -10f, y = -1f, width = 40f, height = 1f))
        val ranged = Enemy(spawnX = 10f, spawnY = 0f, type = EnemyType.RANGED)
        val player = Player(spawnX = 12f, spawnY = 0f) // Jarak 2m (terlalu dekat: < 3.2m)

        // Frame 1: Dari PATROL mendeteksi player -> beralih ke CHASE
        ranged.update(delta = 0.05f, player = player, platforms = ground)
        assertEquals(EnemyState.CHASE, ranged.state)

        // Frame 2: Dalam CHASE, karena terlalu dekat (< 3.2m), musuh panah harus mundur (kiting retreat ke kiri)
        ranged.update(delta = 0.05f, player = player, platforms = ground)
        assertTrue(ranged.velocity.x < 0f, "Ranged enemy should retreat when player is too close (< 3.2m)")
    }

    @Test
    fun testRangedEnemyAttackAndProjectile() {
        val ground = listOf(Platform(x = -10f, y = -1f, width = 40f, height = 1f))
        val ranged = Enemy(spawnX = 10f, spawnY = 0f, type = EnemyType.RANGED)
        val player = Player(spawnX = 14.5f, spawnY = 0f) // Jarak 4.5m (sweet spot: 3.2m - 7.2m)

        // Frame 1: Dari PATROL mendeteksi player -> beralih ke CHASE
        ranged.update(delta = 0.05f, player = player, platforms = ground)
        assertEquals(EnemyState.CHASE, ranged.state)

        // Frame 2: Dalam CHASE pada sweet spot -> beralih ke ATTACK
        ranged.update(delta = 0.05f, player = player, platforms = ground)
        assertEquals(EnemyState.ATTACK, ranged.state)

        // Update frame hingga melewati windup (0.40s) untuk menembakkan proyektil panah sihir
        for (i in 0 until 9) {
            ranged.update(delta = 0.05f, player = player, platforms = ground)
        }

        assertTrue(ranged.projectiles.isNotEmpty(), "Ranged enemy should fire a projectile during sweet-spot attack")

        val proj = ranged.projectiles.first()
        assertEquals(14f, proj.damage)
        assertTrue(proj.velocityX > 0f, "Projectile should fly right towards the player")
        assertFalse(proj.isDestroyed)
    }

    @Test
    fun testEnemyStunPersistenceDuringHits() {
        val ground = listOf(Platform(x = -10f, y = -1f, width = 40f, height = 1f))
        val enemy = Enemy(spawnX = 10f, spawnY = 0f, type = EnemyType.MELEE)
        val player = Player(spawnX = 8f, spawnY = 0f)

        // Perfect Parry Guard Break
        enemy.stun(1.5f)
        assertEquals(EnemyState.STUNNED, enemy.state)
        assertTrue(enemy.stunTimer > 0f)

        // Player hits enemy while stunned (e.g. combo hit 1)
        val hitRegistered = enemy.takeHit(damage = 15f, knockX = 1f, knockY = 0f)
        assertTrue(hitRegistered)
        assertEquals(EnemyState.STUNNED, enemy.state, "Enemy must REMAIN stunned when taking hits during Guard Break window")

        // Update 0.5s: still stunned
        enemy.update(0.5f, player, ground)
        assertEquals(EnemyState.STUNNED, enemy.state)

        // Player hits enemy again (combo hit 2)
        enemy.takeHit(damage = 20f, knockX = 1f, knockY = 0f)
        assertEquals(EnemyState.STUNNED, enemy.state, "Enemy must continue to stay stunned during subsequent hits")

        // Update 1.1s: stun timer expires (total 1.6s > 1.5s)
        enemy.update(1.1f, player, ground)
        assertEquals(EnemyState.CHASE, enemy.state, "Enemy should smoothly transition to CHASE once stun timer elapses")
    }

    @Test
    fun testMeleeEnemyCliffAvoidanceDuringChase() {
        // Platform terisolasi kecil (x = 5f .. 9f, width = 4f)
        val isolatedPlatform = listOf(Platform(x = 5f, y = 0f, width = 4f, height = 1f))
        val enemy = Enemy(spawnX = 8.5f, spawnY = 1.0f, type = EnemyType.MELEE) // Berdiri dekat tepi kanan (x=9)
        val player = Player(spawnX = 14f, spawnY = 1.0f) // Pemain berada jauh di seberang jurang (x=14)

        // Set enemy grounded on platform
        enemy.update(delta = 0.05f, player = player, platforms = isolatedPlatform)
        assertEquals(EnemyState.CHASE, enemy.state)

        // Musuh mendeteksi tidak ada platform di depan (x > 9): kecepatan X harus melambat/berhenti mendekati 0
        enemy.update(delta = 0.05f, player = player, platforms = isolatedPlatform)
        assertTrue(enemy.position.x <= 9.0f, "Enemy must not walk off the cliff/platform edge during chase")
    }

    @Test
    fun testRangedEnemyLineOfSightDetection() {
        val openPlatforms = listOf(
            Platform(x = 0f, y = 0f, width = 30f, height = 1f)
        )
        val ranged = Enemy(spawnX = 5f, spawnY = 1f, type = EnemyType.RANGED)
        val player = Player(spawnX = 12f, spawnY = 1f)

        // 1. Tanpa halangan: Line of Sight harus TRUE
        assertTrue(ranged.hasLineOfSight(player, openPlatforms), "Line of sight should be clear across open platform")

        // 2. Ada pilar solid di antara musuh (x=5) dan pemain (x=12): pilar pada x=8 .. 9, height=4
        val obstructedPlatforms = listOf(
            Platform(x = 0f, y = 0f, width = 30f, height = 1f),
            Platform(x = 8f, y = 1f, width = 1f, height = 4f, isOneWay = false)
        )
        assertFalse(ranged.hasLineOfSight(player, obstructedPlatforms), "Line of sight must be blocked by solid vertical pillar")

        // 3. Platform One-Way (bisa ditembus panah): Line of Sight harus tetap TRUE
        val oneWayPlatforms = listOf(
            Platform(x = 0f, y = 0f, width = 30f, height = 1f),
            Platform(x = 8f, y = 1f, width = 1f, height = 4f, isOneWay = true)
        )
        assertTrue(ranged.hasLineOfSight(player, oneWayPlatforms), "Line of sight should pass through one-way platforms")
    }

    @Test
    fun testBossGroundSlamShockwaveAndRecovery() {
        val ground = listOf(Platform(x = -10f, y = 0f, width = 40f, height = 1f))
        val boss = BossEnemy(spawnX = 10f, spawnY = 5f)
        val player = Player(spawnX = 8f, spawnY = 1f)

        // Set state ke GROUND_SLAM_DOWN saat menukik ke bawah
        boss.state = BossState.GROUND_SLAM_DOWN
        boss.velocity.y = -22f

        // Frame 1: Menukik dan menabrak platform lantai (collision detection menandai isGrounded)
        boss.position.y = 1.05f
        boss.update(0.05f, player, ground)

        // Frame 2: Dampak hantaman tanah memicu shockwave luas
        boss.update(0.02f, player, ground)
        assertEquals(BossState.GROUND_SLAM_DOWN, boss.state)
        assertTrue(boss.hitbox.isActive, "Shockwave hitbox must be active on ground impact")

        // Update 0.20s: shockwave mereda dan hitbox dinonaktifkan (pemain aman dari lingering damage)
        boss.update(0.20f, player, ground)
        assertEquals(BossState.GROUND_SLAM_DOWN, boss.state)
        assertFalse(boss.hitbox.isActive, "Shockwave hitbox must be deactivated during boss recovery")

        // Update remaining recovery (0.50s > 0.65s total): boss pulih dan kembali ke IDLE
        boss.update(0.50f, player, ground)
        assertEquals(BossState.IDLE, boss.state, "Boss should recover from ground slam and return to IDLE")
    }
}
