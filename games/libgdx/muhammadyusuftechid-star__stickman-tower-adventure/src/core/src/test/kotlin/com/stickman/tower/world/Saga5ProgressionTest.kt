package com.stickman.tower.world

import com.stickman.tower.enemy.BossType
import com.stickman.tower.narrative.DialogueRegistry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif untuk SAGA V: PUNCAK KANVAS KOSMIS & THE GRAND CALLIGRAPHER (Lantai 41 - 50).
 * Memvalidasi skala level marmer putih surga, bos Archon of Pure Geometry (Lt 45), bos The Grand Calligrapher (Lt 50),
 * 10 Prasasti Kuno (Lore Tablets XLI - L), penempatan Altar Prisma & Blood Altar, dan dialog sinematik.
 */
class Saga5ProgressionTest {

    @Test
    fun testFloor41To50ProgressionAndScales() {
        for (f in 41..50) {
            val floor = TowerLevelBuilder.buildFloor(f)
            assertEquals(f, floor.floorNumber, "Nomor lantai harus $f")
            assertEquals("SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH", floor.actTitle)
            assertTrue(
                floor.mapBounds.width in 120.0f..190.0f,
                "Bentang lebar lantai $f harus berskala epik (120m - 190m), actual: ${floor.mapBounds.width}"
            )
            assertTrue(floor.platforms.isNotEmpty(), "Lantai $f harus memiliki platform terkurasi!")
            assertNotNull(floor.exitPortal, "Lantai $f harus memiliki portal keluar!")
            assertNotNull(floor.checkpoint, "Lantai $f harus memiliki checkpoint!")
        }
    }

    @Test
    fun testFloor45ArchonOfPureGeometryBoss() {
        val floor45 = TowerLevelBuilder.buildFloor(45)
        assertTrue(floor45.isBossFloor, "Lantai 45 harus merupakan Boss Floor!")
        val boss = floor45.boss
        assertNotNull(boss, "Lantai 45 harus memiliki BossEnemy!")
        assertEquals("Archon of Pure Geometry", boss.name)
        assertEquals(7500f, boss.health.maxHp, "Archon of Pure Geometry harus memiliki 7500 HP!")
        assertNotNull(floor45.prismAltar, "Lantai 45 harus memiliki PrismAltar untuk pergantian Triad!")
    }

    @Test
    fun testFloor50TheGrandCalligrapherFinalBoss() {
        val floor50 = TowerLevelBuilder.buildFloor(50)
        assertTrue(floor50.isBossFloor, "Lantai 50 harus merupakan Boss Floor!")
        val boss = floor50.boss
        assertNotNull(boss, "Lantai 50 harus memiliki BossEnemy!")
        assertEquals("The Grand Calligrapher", boss.name)
        assertEquals(BossType.GRAND_CALLIGRAPHER, boss.type)
        assertEquals(15000f, boss.health.maxHp, "The Grand Calligrapher harus memiliki 15000 HP!")
        assertNotNull(floor50.prismAltar, "Lantai 50 harus memiliki PrismAltar!")
    }

    @Test
    fun testLoreTablets41To50CanonicalContent() {
        val expectedKeywords = mapOf(
            41 to Pair("TABLET_41", "Tangga Marmer Putih Suci"),
            42 to Pair("TABLET_42", "Pilar-Pilar Spektrum Purba"),
            43 to Pair("TABLET_43", "Geometri Non-Euclidean"),
            44 to Pair("TABLET_44", "Lautan Tinta Penciptaan"),
            45 to Pair("TABLET_45", "Malaikat Geometri Suci"),
            46 to Pair("TABLET_46", "Tangga Fajar Kosmis"),
            47 to Pair("TABLET_47", "Ruang Tunggu Para Arsitek"),
            48 to Pair("TABLET_48", "Ambang Kanvas Primordial"),
            49 to Pair("TABLET_49", "Sumpah Triad of Dawn"),
            50 to Pair("TABLET_50", "Patahnya Pena Takdir Semesta")
        )

        for ((floorNum, expected) in expectedKeywords) {
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            assertTrue(floor.loreTablets.isNotEmpty(), "Lantai $floorNum harus memiliki Lore Tablet!")
            val tablet = floor.loreTablets.first()
            assertEquals(expected.first, tablet.tabletId, "Tablet ID di lantai $floorNum tidak cocok")
            assertTrue(
                tablet.title.contains(expected.second, ignoreCase = true) || tablet.text.contains(expected.second, ignoreCase = true),
                "Tablet di lantai $floorNum harus memuat '${expected.second}'! Actual title: '${tablet.title}', text: '${tablet.text}'"
            )
        }
    }

    @Test
    fun testPrismAltarsAndBloodAltarPlacementInSaga5() {
        // Prism Altar harus terpasang di Lantai 41, 43, 45, 47, 48, 50
        val prismFloors = listOf(41, 43, 45, 47, 48, 50)
        for (f in prismFloors) {
            val floor = TowerLevelBuilder.buildFloor(f)
            assertNotNull(floor.prismAltar, "Lantai $f harus memiliki PrismAltar!")
        }

        // Lantai non-prism tidak boleh memiliki Prism Altar
        val nonPrismFloors = listOf(42, 44, 46, 49)
        for (f in nonPrismFloors) {
            val floor = TowerLevelBuilder.buildFloor(f)
            assertTrue(floor.prismAltar == null, "Lantai $f tidak boleh memiliki PrismAltar!")
        }

        // Blood Altar di Lantai 48
        val floor48 = TowerLevelBuilder.buildFloor(48)
        assertNotNull(floor48.bloodAltar, "Lantai 48 harus memiliki BloodAltar pengorbanan terakhir!")
    }

    @Test
    fun testCinematicDialoguesSaga5() {
        val scene41 = DialogueRegistry.getSceneForFloor(41)
        assertNotNull(scene41)
        assertTrue(scene41.lines.any { it.speaker == "Aria" })
        assertTrue(scene41.lines.any { it.text.contains("marmer putih suci") })

        val scene45 = DialogueRegistry.getSceneForFloor(45)
        assertNotNull(scene45)
        assertTrue(scene45.lines.any { it.speaker == "Archon of Pure Geometry" })
        assertTrue(scene45.lines.any { it.text.contains("KECACATAN SIMETRI") })

        val scene49 = DialogueRegistry.getSceneForFloor(49)
        assertNotNull(scene49)
        assertTrue(scene49.lines.any { it.speaker == "Kaelen" })
        assertTrue(scene49.lines.any { it.text.contains("dewa takdir akan jatuh") })

        val scene50 = DialogueRegistry.getSceneForFloor(50)
        assertNotNull(scene50)
        assertTrue(scene50.lines.any { it.speaker == "The Grand Calligrapher" })
        assertTrue(scene50.lines.any { it.text.contains("kanvas kosong") })
    }
}
