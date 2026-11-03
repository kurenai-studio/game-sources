package com.stickman.tower.world

import com.badlogic.gdx.math.Vector2
import com.stickman.tower.character.Player
import com.stickman.tower.character.ZephyrCoopAlly
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif Fase 25:
 * Saga I (Lantai 1-10) — The Ashen Depths, Ekspansi Level Design Bentang Luas,
 * Mekanisme Pintu Segel Runik (Runic Barrier & Key),
 * dan Pertarungan Co-op Tag-Team Penyelamatan Zephyr melawan Lady Vespera.
 */
class Saga1ProgressionTest {

    @Test
    fun testAllSaga1FloorsHaveExpansiveScale() {
        for (floorNum in 1..10) {
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            val mapWidth = floor.mapBounds.width
            assertTrue(
                mapWidth >= 80f,
                "Lantai $floorNum harus memiliki bentang luas minimal 80 meter (aktual: ${mapWidth}m)!"
            )
            assertTrue(floor.platforms.size >= 5, "Lantai $floorNum harus memiliki variasi platform navigasi!")
            assertNotNull(floor.checkpoint, "Lantai $floorNum harus memiliki checkpoint!")
            assertNotNull(floor.exitPortal, "Lantai $floorNum harus memiliki portal keluar!")
        }
    }

    @Test
    fun testRunicBarrierAndKeyOnFloor3() {
        val floor3 = TowerLevelBuilder.buildFloor(3)
        assertFalse(floor3.isBossFloor, "Lantai 3 adalah koridor penjelajahan runik, bukan boss floor!")
        assertEquals(1, floor3.runicBarriers.size, "Lantai 3 harus memiliki 1 Runic Barrier!")
        assertEquals(1, floor3.runicKeys.size, "Lantai 3 harus memiliki 1 Runic Key!")

        val barrier = floor3.runicBarriers.first()
        val key = floor3.runicKeys.first()

        assertEquals("BARRIER_FLOOR_3", barrier.barrierId)
        assertEquals(barrier.barrierId, key.targetBarrierId, "Target ID Kunci harus cocok dengan ID Barrier!")
        assertFalse(barrier.isUnlocked, "Barrier harus terkunci pada awal lantai!")
        assertFalse(key.isCollected, "Kunci belum boleh terambil pada awal lantai!")

        // Lokasi Barrier dan Kunci (Key ditempatkan sebelum Barrier)
        assertTrue(key.x < barrier.x, "Kunci harus ditempatkan sebelum pintu segel barier!")

        // Simulasi pembukaan segel
        barrier.unlock()
        assertTrue(barrier.isUnlocked, "Barrier harus terbuka setelah dibuka!")
    }

    @Test
    fun testRunicBarrierAndKeyOnFloor8() {
        val floor8 = TowerLevelBuilder.buildFloor(8)
        assertFalse(floor8.isBossFloor, "Lantai 8 adalah koridor teka-teki gema runik, bukan boss floor!")
        assertEquals(1, floor8.runicBarriers.size, "Lantai 8 harus memiliki 1 Runic Barrier!")
        assertEquals(1, floor8.runicKeys.size, "Lantai 8 harus memiliki 1 Runic Key!")

        val barrier = floor8.runicBarriers.first()
        val key = floor8.runicKeys.first()

        assertEquals("BARRIER_FLOOR_8", barrier.barrierId)
        assertEquals(barrier.barrierId, key.targetBarrierId)
        assertFalse(barrier.isUnlocked)
        assertFalse(key.isCollected)
        assertTrue(key.x < barrier.x)
    }

    @Test
    fun testFloor5ObsidianColosseumGeneralOakhaven() {
        val floor5 = TowerLevelBuilder.buildFloor(5)
        assertTrue(floor5.isBossFloor, "Lantai 5 harus merupakan Boss Floor!")
        assertEquals("Lantai 5: The Obsidian Colosseum", floor5.floorName)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor5.actTitle)
        assertEquals("THE OBSIDIAN COLOSSEUM", floor5.actSubtitle)

        val boss = floor5.boss
        assertNotNull(boss, "Lantai 5 harus memiliki bos!")
        assertEquals(BossType.TOWER_GUARDIAN, boss.type, "Bos Lantai 5 harus General Oakhaven!")
        assertEquals("TOWER GUARDIAN", boss.name)
        assertEquals(350f, boss.health.maxHp)

        // Skala Colosseum megah
        assertTrue(floor5.mapBounds.width >= 90f, "Colosseum harus berbentang minimal 90m!")
    }

    @Test
    fun testFloor6IronFoundrySafeZone() {
        val floor6 = TowerLevelBuilder.buildFloor(6)
        assertTrue(floor6.isSafeZone, "Lantai 6 harus safe zone!")
        assertFalse(floor6.isBossFloor)
        assertTrue(floor6.enemies.isEmpty())
        assertTrue(floor6.spikes.isEmpty())
        assertTrue(floor6.chests.size >= 3, "Lantai 6 harus memiliki banyak peti persediaan!")
    }

    @Test
    fun testFloor7FracturedPrecipiceLowGravity() {
        val floor7 = TowerLevelBuilder.buildFloor(7)
        assertEquals(0.65f, floor7.gravityScale, "Lantai 7 harus memiliki skala gravitasi rendah 0.65f!")
        assertNotNull(floor7.bloodAltar, "Lantai 7 harus memiliki altar darah!")
        assertTrue(floor7.mapBounds.width >= 120f, "Lantai 7 harus berbentang luas minimal 120m!")
    }

    @Test
    fun testFloor10VioletSanctumAndZephyrRescue() {
        val floor10 = TowerLevelBuilder.buildFloor(10)
        assertTrue(floor10.isBossFloor, "Lantai 10 harus Boss Floor!")
        assertEquals("Lantai 10: The Violet Sanctum", floor10.floorName)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor10.actTitle)
        assertEquals("THE VIOLET SANCTUM", floor10.actSubtitle)

        // Verifikasi Lady Vespera
        val boss = floor10.boss
        assertNotNull(boss)
        assertEquals(BossType.AMETHYST_MATRON, boss.type)
        assertEquals("THE AMETHYST MATRON", boss.name)

        // Verifikasi Kepompong Zephyr
        val cocoon = floor10.zephyrCocoon
        assertNotNull(cocoon, "Lantai 10 harus memiliki kepompong kristal Zephyr!")
        assertFalse(cocoon.isBroken, "Kepompong harus utuh pada awal pertempuran!")
        assertEquals(3, cocoon.hitPoints, "Kepompong butuh 3 tebasan pedang!")

        // Simulasi tebasan pedang Kaelen ke kepompong
        assertFalse(cocoon.takeHit(), "Hit 1 tidak boleh langsung memecahkan kepompong!")
        assertEquals(2, cocoon.hitsRemaining)
        assertEquals(1, cocoon.hitsTaken)

        assertFalse(cocoon.takeHit(), "Hit 2 tidak boleh memecahkan kepompong!")
        assertEquals(1, cocoon.hitsRemaining)
        assertEquals(2, cocoon.hitsTaken)

        assertTrue(cocoon.takeHit(), "Hit 3 harus memecahkan kepompong sutra kristal!")
        assertTrue(cocoon.isBroken, "Kepompong harus berstatus isBroken!")
        assertEquals(0, cocoon.hitsRemaining)
        assertEquals(3, cocoon.hitsTaken)
    }

    @Test
    fun testZephyrCoopAllyTacticalBehavior() {
        val ally = ZephyrCoopAlly(spawnX = 10f, spawnY = 2f)
        assertTrue(ally.isActive, "Zephyr Co-op Ally harus aktif!")

        val player = Player(spawnX = 5f, spawnY = 2f)
        val boss = BossEnemy(spawnX = 25f, spawnY = 2f, type = BossType.AMETHYST_MATRON)

        var hitRegistered = false
        var damageDealt = 0f
        ally.onBossHit = { dmg, _ ->
            hitRegistered = true
            damageDealt = dmg
        }

        // 1. Shadow Dash mendekat saat bos jauh (>3m)
        val initialX = ally.position.x
        ally.update(delta = 0.5f, boss = boss, playerPos = player.position)
        assertTrue(ally.position.x > initialX, "Zephyr harus bergerak mendekati bos!")

        // 2. Simulasi berada dalam jangkauan tempur jarak dekat (delta 1.0f untuk menghabiskan cooldown serangan 0.8s)
        ally.position.set(boss.position.x - 1.0f, boss.position.y)
        ally.update(delta = 1.0f, boss = boss, playerPos = player.position)

        // Belati mengenai bos
        assertTrue(hitRegistered, "Serangan belati Zephyr harus memicu callback onBossHit!")
        assertTrue(damageDealt > 0f, "Damage belati Zephyr harus lebih dari 0!")

        // 3. Mengikuti pemain saat bos sudah gugur
        boss.health.update(0.5f) // Habiskan i-frames dari hit sebelumnya
        boss.health.takeDamage(9999f)
        assertTrue(boss.health.isDead)
        player.position.set(0f, 2f)
        val prevX = ally.position.x
        ally.update(delta = 0.5f, boss = boss, playerPos = player.position)
        assertTrue(ally.position.x < prevX, "Zephyr harus mengikuti arah pemain saat bos gugur!")
    }
}
