package com.stickman.tower.world

import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossState
import com.stickman.tower.enemy.BossType
import com.stickman.tower.endless.FloorMutator
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif Kampanye Cerita Utama (The 10-Floor Story Odyssey)
 * Menguji integritas struktural ke-10 lantai, 5 tipe Bos Menara, Prasasti Kuno (Lore Tablets),
 * Dialog Tokoh Cerita (Aria & Vulcanus), Zona Aman, serta Anomali Gravitasi Rendah.
 */
class StoryCampaignTest {

    @Test
    fun testAllTenFloorsBuildProperly() {
        for (floorNum in 1..10) {
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            assertEquals(floorNum, floor.floorNumber)
            assertTrue(floor.floorName.isNotEmpty())
            assertTrue(floor.platforms.isNotEmpty(), "Lantai $floorNum harus memiliki platform!")
            assertNotNull(floor.exitPortal, "Lantai $floorNum harus memiliki portal keluar!")
            assertTrue(floor.actTitle.isNotEmpty(), "Lantai $floorNum harus memiliki judul Act!")
            assertTrue(floor.actSubtitle.isNotEmpty(), "Lantai $floorNum harus memiliki subjudul Act!")
        }
    }

    @Test
    fun testActHierarchyAndThematicContinuity() {
        // Act I: Lantai 1 s/d 3
        val floor1 = TowerLevelBuilder.buildFloor(1)
        val floor2 = TowerLevelBuilder.buildFloor(2)
        val floor3 = TowerLevelBuilder.buildFloor(3)
        assertEquals("ACT I: THE INITIATION", floor1.actTitle)
        assertEquals("ACT I: THE INITIATION", floor2.actTitle)
        assertEquals("ACT I: THE INITIATION", floor3.actTitle)
        assertEquals("LOWER BASTION", floor1.actSubtitle)
        assertEquals("SPIRE OF HAZARDS", floor2.actSubtitle)
        assertEquals("THE SEALED ARMORY", floor3.actSubtitle)

        // Lantai 4: Act II
        val floor4 = TowerLevelBuilder.buildFloor(4)
        assertEquals("ACT II: SECRETS OF THE INK", floor4.actTitle)
        assertEquals("THE SUNKEN ARCHIVES", floor4.actSubtitle)

        // Saga I (Lantai 5 s/d 10)
        val floor5 = TowerLevelBuilder.buildFloor(5)
        val floor6 = TowerLevelBuilder.buildFloor(6)
        val floor7 = TowerLevelBuilder.buildFloor(7)
        val floor8 = TowerLevelBuilder.buildFloor(8)
        val floor9 = TowerLevelBuilder.buildFloor(9)
        val floor10 = TowerLevelBuilder.buildFloor(10)

        assertEquals("SAGA I: THE ASHEN DEPTHS", floor5.actTitle)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor6.actTitle)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor7.actTitle)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor8.actTitle)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor9.actTitle)
        assertEquals("SAGA I: THE ASHEN DEPTHS", floor10.actTitle)

        assertEquals("THE OBSIDIAN COLOSSEUM", floor5.actSubtitle)
        assertEquals("THE IRON FOUNDRY", floor6.actSubtitle)
        assertEquals("THE FRACTURED PRECIPICE", floor7.actSubtitle)
        assertEquals("THE HALL OF ECHOES", floor8.actSubtitle)
        assertEquals("THE WEAVERS' PASSAGE", floor9.actSubtitle)
        assertEquals("THE VIOLET SANCTUM", floor10.actSubtitle)
    }

    @Test
    fun testFiveLegendaryBossesInitializationAndAttributes() {
        // Boss Lantai 5: The Tower Guardian (General Oakhaven)
        val floor5 = TowerLevelBuilder.buildFloor(5)
        assertTrue(floor5.isBossFloor)
        val boss5 = floor5.boss
        assertNotNull(boss5)
        assertEquals(BossType.TOWER_GUARDIAN, boss5.type)
        assertEquals("TOWER GUARDIAN", boss5.name)
        assertEquals("General Oakhaven", boss5.subtitle)
        assertEquals(350f, boss5.health.maxHp)

        // Boss Lantai 10: The Amethyst Matron (Lady Vespera)
        val floor10 = TowerLevelBuilder.buildFloor(10)
        assertTrue(floor10.isBossFloor)
        val boss10 = floor10.boss
        assertNotNull(boss10)
        assertEquals(BossType.AMETHYST_MATRON, boss10.type)
        assertEquals("THE AMETHYST MATRON", boss10.name)
        assertEquals("Queen of the Shadow Bow", boss10.subtitle)
        assertEquals(480f, boss10.health.maxHp)
        assertNotNull(floor10.zephyrCocoon, "Lantai 10 harus memiliki kepompong Zephyr!")

        // Boss Archetypes untuk Endless Spire & Saga Mendatang
        val bossDoppel = BossEnemy(type = BossType.SHADOW_DOPPELGANGER)
        assertEquals("SHADOW DOPPELGANGER", bossDoppel.name)
        assertEquals(620f, bossDoppel.health.maxHp)

        val bossCrimson = BossEnemy(type = BossType.CRIMSON_SOVEREIGN)
        assertEquals("CRIMSON SOVEREIGN", bossCrimson.name)
        assertEquals(780f, bossCrimson.health.maxHp)

        val bossCalligrapher = BossEnemy(type = BossType.GRAND_CALLIGRAPHER)
        assertEquals("THE GRAND CALLIGRAPHER", bossCalligrapher.name)
        assertEquals(1100f, bossCalligrapher.health.maxHp)
        assertTrue(bossCalligrapher.health.maxHp > bossCrimson.health.maxHp)
    }

    @Test
    fun testLoreTabletsPlacementAndContent() {
        // Pastikan setiap lantai 1 s/d 10 memiliki tepat 1 prasasti kuno
        for (fNum in 1..10) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(1, floor.loreTablets.size, "Lantai $fNum harus memiliki 1 prasasti kuno!")
            val tablet = floor.loreTablets.first()
            assertEquals("TABLET_$fNum", tablet.tabletId)
            assertTrue(tablet.title.isNotEmpty())
            assertTrue(tablet.text.isNotEmpty())
        }

        // Verifikasi konten spesifik kanon lore
        val f1 = TowerLevelBuilder.buildFloor(1).loreTablets.first()
        assertTrue(f1.text.contains("Hari ke-47"))

        val f2 = TowerLevelBuilder.buildFloor(2).loreTablets.first()
        assertTrue(f2.text.contains("Kutukan gravitasi"))

        val f3 = TowerLevelBuilder.buildFloor(3).loreTablets.first()
        assertTrue(f3.text.contains("Segel Runik Bawah"))

        val f4 = TowerLevelBuilder.buildFloor(4).loreTablets.first()
        assertTrue(f4.text.contains("panah amethyst"))

        val f5 = TowerLevelBuilder.buildFloor(5).loreTablets.first()
        assertTrue(f5.text.contains("Oakhaven"))

        val f6 = TowerLevelBuilder.buildFloor(6).loreTablets.first()
        assertTrue(f6.text.contains("Besi meteorit"))

        val f7 = TowerLevelBuilder.buildFloor(7).loreTablets.first()
        assertTrue(f7.text.contains("Tinta Primordial"))

        val f8 = TowerLevelBuilder.buildFloor(8).loreTablets.first()
        assertTrue(f8.text.contains("Segel Runik Gema"))

        val f9 = TowerLevelBuilder.buildFloor(9).loreTablets.first()
        assertTrue(f9.text.contains("Lady Vespera"))

        val f10 = TowerLevelBuilder.buildFloor(10).loreTablets.first()
        assertTrue(f10.text.contains("Zephyr"))
    }

    @Test
    fun testStoryDialoguesAcrossKeyStoryFloors() {
        // Lantai-lantai bernarasi tinggi: Lantai 1, 4, 5, 6, 7, 9, 10
        val keyFloors = listOf(1, 4, 5, 6, 7, 9, 10)
        for (fNum in keyFloors) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertTrue(floor.storyDialogues.isNotEmpty(), "Lantai $fNum harus memiliki storyDialogues naratif!")
            val firstDialogue = floor.storyDialogues.first()
            assertTrue(firstDialogue.lines.isNotEmpty(), "StoryDialogue lantai $fNum harus memiliki baris dialog!")
            assertTrue(firstDialogue.lines.first().speaker.isNotEmpty())
            assertTrue(firstDialogue.lines.first().text.isNotEmpty())
        }

        // Cek dialog khusus tokoh-tokoh utama:
        val floor1 = TowerLevelBuilder.buildFloor(1)
        assertEquals("Aria", floor1.storyDialogues.first().lines.first().speaker)

        val floor5 = TowerLevelBuilder.buildFloor(5)
        assertEquals("Jenderal Oakhaven", floor5.storyDialogues.first().lines.first().speaker)

        val floor6 = TowerLevelBuilder.buildFloor(6)
        assertEquals("Vulcanus", floor6.storyDialogues.first().lines.first().speaker)

        val floor10 = TowerLevelBuilder.buildFloor(10)
        assertEquals("Lady Vespera", floor10.storyDialogues.first().lines.first().speaker)
    }

    @Test
    fun testBossEnrageAndDeathQuotesLore() {
        val bossTypes = listOf(
            BossType.TOWER_GUARDIAN,
            BossType.AMETHYST_MATRON,
            BossType.SHADOW_DOPPELGANGER,
            BossType.CRIMSON_SOVEREIGN,
            BossType.GRAND_CALLIGRAPHER
        )
        for (type in bossTypes) {
            val boss = BossEnemy(type = type)
            assertTrue(boss.enrageQuote.isNotEmpty(), "Boss $type harus memiliki enrageQuote!")
            assertTrue(boss.deathQuote.isNotEmpty(), "Boss $type harus memiliki deathQuote!")
        }
    }

    @Test
    fun testFloor6SafeZoneSanctuary() {
        val floor6 = TowerLevelBuilder.buildFloor(6)
        assertTrue(floor6.isSafeZone, "Lantai 6 harus merupakan Safe Zone!")
        assertFalse(floor6.isBossFloor, "Lantai 6 bukan boss floor!")
        assertNull(floor6.boss, "Lantai 6 tidak boleh memiliki boss musuh!")
        assertTrue(floor6.enemies.isEmpty(), "Lantai 6 harus bebas dari monster musuh!")
        assertTrue(floor6.spikes.isEmpty(), "Lantai 6 tidak boleh memiliki duri maut!")
        assertTrue(floor6.chests.isNotEmpty(), "Lantai 6 harus memiliki peti relik tempaan!")
    }

    @Test
    fun testFloor7LowGravityAnomaly() {
        val floor7 = TowerLevelBuilder.buildFloor(7)
        assertEquals(0.65f, floor7.gravityScale, "Lantai 7 harus memiliki skala gravitasi rendah 0.65f!")
    }

    @Test
    fun testEndlessFloorTransitionAndScaling() {
        // Lantai 51 (Endless Rank 1 setelah Saga V Puncak Menara)
        val endless51 = TowerLevelBuilder.buildFloor(51, FloorMutator.NONE)
        assertEquals(51, endless51.floorNumber)
        assertEquals("EPILOGUE: THE ENDLESS PARADOX", endless51.actTitle)
        assertEquals("FLOOR 51", endless51.actSubtitle)

        // Lantai 55 (Endless Boss)
        val endless55 = TowerLevelBuilder.buildFloor(55, FloorMutator.BERSERK_SURGE)
        assertTrue(endless55.isBossFloor)
        val boss55 = endless55.boss
        assertNotNull(boss55)
        assertTrue(boss55.health.maxHp > 350f, "Boss Endless harus diskalakan HP-nya!")
    }

    @Test
    fun testBossWindSlashProjectilePatterns() {
        val player = com.stickman.tower.character.Player(spawnX = 4f, spawnY = 2f)
        val bossTypes = listOf(
            BossType.TOWER_GUARDIAN,
            BossType.AMETHYST_MATRON,
            BossType.SHADOW_DOPPELGANGER,
            BossType.CRIMSON_SOVEREIGN,
            BossType.GRAND_CALLIGRAPHER
        )

        for (type in bossTypes) {
            val boss = BossEnemy(spawnX = 10f, spawnY = 2f, type = type)
            boss.state = BossState.WIND_SLASH
            val prevProjCount = boss.projectiles.size
            boss.update(delta = 0.30f, player = player, platforms = emptyList())
            assertTrue(boss.projectiles.size > prevProjCount, "Boss $type harus menghasilkan proyektil pada WIND_SLASH!")
        }
    }
}
