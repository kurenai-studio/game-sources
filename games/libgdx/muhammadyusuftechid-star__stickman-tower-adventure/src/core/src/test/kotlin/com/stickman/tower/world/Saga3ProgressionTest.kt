package com.stickman.tower.world

import com.stickman.tower.enemy.BossType
import com.stickman.tower.narrative.DialogueRegistry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Saga3ProgressionTest:
 * Pengujian komprehensif untuk Fase 27:
 * - Bentang luas level design Saga III (Lantai 21 - 30)
 * - Prasasti kuno kanonikal XXI s/d XXX (Lore Tablets 21-30)
 * - Rintangan dinding batu basalt tebal (TitanBasaltWall) di Lantai 21 dan 24
 * - Bos Lantai 25 (Magma Golem King) & Bos Lantai 30 (The Shadow Doppelgänger)
 * - Anomali gravitasi rendah Kosmis (Lantai 27-29: 0.75G, 0.65G, 0.55G)
 * - Dialog sinematik SCENE_09 s/d SCENE_12
 */
class Saga3ProgressionTest {

    @Test
    fun testSaga3FloorsScaleAndStructure() {
        for (fNum in 21..30) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(fNum, floor.floorNumber)
            assertTrue(floor.mapBounds.width >= 105f, "Lantai $fNum harus memiliki bentang luas minimal 105m!")
            assertTrue(floor.platforms.isNotEmpty(), "Lantai $fNum harus memiliki platform!")
            assertNotNull(floor.checkpoint, "Lantai $fNum harus memiliki checkpoint!")
            assertNotNull(floor.exitPortal, "Lantai $fNum harus memiliki stage exit portal!")

            assertEquals("SAGA III: BASALT CRATER & ASTRAL RIFT", floor.actTitle, "Act Title Lantai $fNum harus sesuai pembagian sub-bab!")
        }
    }

    @Test
    fun testLoreTabletsXXIToXXXContentAndPlacement() {
        for (fNum in 21..30) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(1, floor.loreTablets.size, "Lantai $fNum harus memiliki tepat 1 prasasti kuno!")
            val tablet = floor.loreTablets.first()
            assertEquals("TABLET_$fNum", tablet.tabletId)
            assertTrue(tablet.title.isNotEmpty())
            assertTrue(tablet.text.isNotEmpty())
        }

        // Verifikasi kutipan kanonikal Lore Tablets 21 - 30
        val t21 = TowerLevelBuilder.buildFloor(21).loreTablets.first()
        assertTrue(t21.text.contains("Pedang raksasaku"))
        assertTrue(t21.text.contains("batu basalt"))

        val t22 = TowerLevelBuilder.buildFloor(22).loreTablets.first()
        assertTrue(t22.text.contains("membeku dari lahar purba"))

        val t23 = TowerLevelBuilder.buildFloor(23).loreTablets.first()
        assertTrue(t23.text.contains("padang pasir Aethelgard"))

        val t24 = TowerLevelBuilder.buildFloor(24).loreTablets.first()
        assertTrue(t24.text.contains("paladin Titan Bastion"))

        val t25 = TowerLevelBuilder.buildFloor(25).loreTablets.first()
        assertTrue(t25.text.contains("lahar yang menolak dingin"))

        val t26 = TowerLevelBuilder.buildFloor(26).loreTablets.first()
        assertTrue(t26.text.contains("kosmos hitam berbintang cyan"))

        val t27 = TowerLevelBuilder.buildFloor(27).loreTablets.first()
        assertTrue(t27.text.contains("Angin kosmis melolong"))

        val t28 = TowerLevelBuilder.buildFloor(28).loreTablets.first()
        assertTrue(t28.text.contains("bongkahan meteorit"))

        val t29 = TowerLevelBuilder.buildFloor(29).loreTablets.first()
        assertTrue(t29.text.contains("Lantai menjadi langit"))

        val t30 = TowerLevelBuilder.buildFloor(30).loreTablets.first()
        assertTrue(t30.text.contains("cermin jiwa"))
    }

    @Test
    fun testFloor25MagmaGolemKingBossArena() {
        val floor25 = TowerLevelBuilder.buildFloor(25)
        assertTrue(floor25.isBossFloor, "Lantai 25 harus merupakan Boss Floor!")
        val boss = floor25.boss
        assertNotNull(boss, "Lantai 25 harus memiliki boss Magma Golem King!")
        assertEquals("MAGMA GOLEM KING", boss.name)
        assertEquals(1400f, boss.health.maxHp)
        assertEquals(BossType.TOWER_GUARDIAN, boss.type)
        assertTrue(boss.health.currentHp > 0f)
    }

    @Test
    fun testFloor30TheShadowDoppelgangerBossArena() {
        val floor30 = TowerLevelBuilder.buildFloor(30)
        assertTrue(floor30.isBossFloor, "Lantai 30 harus merupakan Boss Floor!")
        val boss = floor30.boss
        assertNotNull(boss, "Lantai 30 harus memiliki boss The Shadow Doppelgänger!")
        assertEquals("THE SHADOW DOPPELGANGER", boss.name)
        assertEquals(1600f, boss.health.maxHp)
        assertEquals(BossType.SHADOW_DOPPELGANGER, boss.type)
        assertTrue(boss.health.currentHp > 0f)
    }

    @Test
    fun testCosmicRiftLowGravityAnomalies() {
        // Lantai 21 - 26 normal gravity
        for (fNum in 21..26) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(1.0f, floor.gravityScale, "Lantai $fNum harus bergravitasi normal 1.0f!")
        }

        // Lantai 27, 28, 29 anomali gravitasi rendah kosmis
        val floor27 = TowerLevelBuilder.buildFloor(27)
        assertEquals(0.75f, floor27.gravityScale, "Lantai 27 harus bergravitasi 0.75f!")

        val floor28 = TowerLevelBuilder.buildFloor(28)
        assertEquals(0.65f, floor28.gravityScale, "Lantai 28 harus bergravitasi 0.65f!")

        val floor29 = TowerLevelBuilder.buildFloor(29)
        assertEquals(0.55f, floor29.gravityScale, "Lantai 29 harus bergravitasi 0.55f!")

        // Lantai 30 kembali normal untuk kestabilan arena duel cermin
        val floor30 = TowerLevelBuilder.buildFloor(30)
        assertEquals(1.0f, floor30.gravityScale, "Lantai 30 harus bergravitasi normal 1.0f!")
    }

    @Test
    fun testTitanBasaltWallDestructionMechanics() {
        val wall = TitanBasaltWall(x = 55.0f, y = 1.2f)
        assertEquals(0, wall.hitsTaken)
        assertFalse(wall.isBroken)
        assertEquals(3, wall.maxHits)

        // Pukulan 1
        assertTrue(wall.takeHit())
        assertEquals(1, wall.hitsTaken)
        assertFalse(wall.isBroken)

        // Pukulan 2
        assertTrue(wall.takeHit())
        assertEquals(2, wall.hitsTaken)
        assertFalse(wall.isBroken)

        // Pukulan 3 (Dinding runtuh)
        assertTrue(wall.takeHit())
        assertEquals(3, wall.hitsTaken)
        assertTrue(wall.isBroken)

        // Pukulan lanjutan setelah hancur
        assertFalse(wall.takeHit(), "Dinding yang sudah hancur tidak dapat menerima pukulan lagi!")
    }

    @Test
    fun testBasaltWallsPlacementOnFloor21And24() {
        val floor21 = TowerLevelBuilder.buildFloor(21)
        assertTrue(floor21.basaltWalls.isNotEmpty(), "Lantai 21 harus memiliki rintangan dinding basalt!")
        assertEquals(1, floor21.basaltWalls.size)

        val floor24 = TowerLevelBuilder.buildFloor(24)
        assertTrue(floor24.basaltWalls.isNotEmpty(), "Lantai 24 harus memiliki rintangan dinding basalt ganda!")
        assertEquals(2, floor24.basaltWalls.size)
    }

    @Test
    fun testSaga3CinematicDialogueRegistry() {
        // Lantai 21: Scene 09 Basalt Crater
        val d21 = DialogueRegistry.getSceneForFloor(21)
        assertNotNull(d21)
        assertTrue(d21.lines.any { it.speaker == "Gorgon" })

        // Lantai 25: Scene 10 Magma Golem
        val d25 = DialogueRegistry.getSceneForFloor(25)
        assertNotNull(d25)
        assertTrue(d25.lines.any { it.speaker == "Magma Golem King" })

        // Lantai 26: Scene 11 Astral Rift
        val d26 = DialogueRegistry.getSceneForFloor(26)
        assertNotNull(d26)
        assertTrue(d26.lines.any { it.speaker == "Aria" })

        // Lantai 30: Scene 12 Nexus of Reflections
        val d30 = DialogueRegistry.getSceneForFloor(30)
        assertNotNull(d30)
        assertTrue(d30.lines.any { it.speaker == "The Shadow Doppelganger" })
    }
}
