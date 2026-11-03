package com.stickman.tower.world

import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.CharacterUnlockManager
import com.stickman.tower.enemy.BossType
import com.stickman.tower.narrative.DialogueRegistry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Saga4ProgressionTest:
 * Pengujian komprehensif untuk Fase 28:
 * - Bentang luas level design Saga IV (Lantai 31 - 40)
 * - Prasasti kuno kanonikal XXXI s/d XL (Lore Tablets 31-40)
 * - Fitur interaktif Altar Prisma Triad Tag-Team (PrismAltar) di Lantai 31, 33, 36, 38
 * - Fitur interaktif Altar Pengorbanan Darah (BloodAltar) di Lantai 38
 * - Bos Lantai 35 (The Void Chimera) & Bos Lantai 40 (Malakor The Crimson Sovereign)
 * - Anomali gravitasi rendah Astral (Lantai 31-35: 0.50G - 0.65G) dan stabilisasi katedral (Lantai 36-40: 1.0G)
 * - Dialog sinematik SCENE_13 s/d SCENE_16
 */
class Saga4ProgressionTest {

    @Test
    fun testSaga4FloorsScaleAndStructure() {
        for (fNum in 31..40) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(fNum, floor.floorNumber)
            assertTrue(floor.mapBounds.width >= 110f, "Lantai $fNum harus memiliki bentang luas minimal 110m!")
            assertTrue(floor.platforms.isNotEmpty(), "Lantai $fNum harus memiliki platform!")
            assertNotNull(floor.checkpoint, "Lantai $fNum harus memiliki checkpoint!")
            assertNotNull(floor.exitPortal, "Lantai $fNum harus memiliki stage exit portal!")
            assertEquals("SAGA IV: ASTRAL RIFT & CRIMSON ECLIPSE", floor.actTitle, "Act Title Lantai $fNum harus Saga IV!")
        }
    }

    @Test
    fun testLoreTabletsXXXIToXLContentAndPlacement() {
        for (fNum in 31..40) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(1, floor.loreTablets.size, "Lantai $fNum harus memiliki tepat 1 prasasti kuno!")
            val tablet = floor.loreTablets.first()
            assertEquals("TABLET_$fNum", tablet.tabletId)
            assertTrue(tablet.title.isNotEmpty())
            assertTrue(tablet.text.isNotEmpty())
        }

        // Verifikasi kutipan kanonikal Lore Tablets 31 - 40
        val t31 = TowerLevelBuilder.buildFloor(31).loreTablets.first()
        assertTrue(t31.text.contains("Dinding menara lenyap total di sini"))
        assertTrue(t31.text.contains("jembatan cahaya"))

        val t32 = TowerLevelBuilder.buildFloor(32).loreTablets.first()
        assertTrue(t32.text.contains("Pulau-pulau batu obsidian melayang bebas"))

        val t33 = TowerLevelBuilder.buildFloor(33).loreTablets.first()
        assertTrue(t33.text.contains("Ruang melengkung pada sudut 90 derajat"))
        assertTrue(t33.text.contains("Perfect Parry"))

        val t34 = TowerLevelBuilder.buildFloor(34).loreTablets.first()
        assertTrue(t34.text.contains("Angin kosmis membawa bisikan jutaan jiwa"))

        val t35 = TowerLevelBuilder.buildFloor(35).loreTablets.first()
        assertTrue(t35.title.contains("Chimera Kehampaan"))
        assertTrue(t35.text.contains("bertentakel bintang"))

        val t36 = TowerLevelBuilder.buildFloor(36).loreTablets.first()
        assertTrue(t36.title.contains("Ambang Katedral Gotik"))
        assertTrue(t36.text.contains("gerhana bulan merah darah"))

        val t37 = TowerLevelBuilder.buildFloor(37).loreTablets.first()
        assertTrue(t37.text.contains("Tirai beludru katedral basah oleh tetesan darah"))

        val t38 = TowerLevelBuilder.buildFloor(38).loreTablets.first()
        assertTrue(t38.title.contains("Altar Pengorbanan Anima"))
        assertTrue(t38.text.contains("para bangsawan menjual rakyat jelata"))

        val t39 = TowerLevelBuilder.buildFloor(39).loreTablets.first()
        assertTrue(t39.text.contains("Peti-peti marmer berlumur darah terbuka"))
        assertTrue(t39.text.contains("Pasukan algojo bertaring"))

        val t40 = TowerLevelBuilder.buildFloor(40).loreTablets.first()
        assertTrue(t40.text.contains("Malakor tersungkur di depan takhtanya"))
        assertTrue(t40.text.contains("tinta merah"))
    }

    @Test
    fun testFloor35VoidChimeraBossArena() {
        val floor35 = TowerLevelBuilder.buildFloor(35)
        assertTrue(floor35.isBossFloor, "Lantai 35 harus merupakan Boss Floor!")
        val boss = floor35.boss
        assertNotNull(boss, "Lantai 35 harus memiliki boss The Void Chimera!")
        assertEquals("THE VOID CHIMERA", boss.name)
        assertEquals(1800f, boss.health.maxHp)
        assertEquals(BossType.AMETHYST_MATRON, boss.type)
        assertTrue(boss.health.currentHp > 0f)
    }

    @Test
    fun testFloor40MalakorCrimsonSovereignBossArena() {
        val floor40 = TowerLevelBuilder.buildFloor(40)
        assertTrue(floor40.isBossFloor, "Lantai 40 harus merupakan Boss Floor!")
        val boss = floor40.boss
        assertNotNull(boss, "Lantai 40 harus memiliki boss Malakor The Crimson Sovereign!")
        assertEquals("MALAKOR THE CRIMSON SOVEREIGN", boss.name)
        assertEquals(2200f, boss.health.maxHp)
        assertEquals(BossType.CRIMSON_SOVEREIGN, boss.type)
        assertTrue(boss.health.currentHp > 0f)
    }

    @Test
    fun testAstralRiftLowGravityAnomalies() {
        // Lantai 31 - 35 anomali gravitasi rendah astral
        val floor31 = TowerLevelBuilder.buildFloor(31)
        assertEquals(0.55f, floor31.gravityScale, "Lantai 31 harus bergravitasi 0.55f!")

        val floor32 = TowerLevelBuilder.buildFloor(32)
        assertEquals(0.50f, floor32.gravityScale, "Lantai 32 harus bergravitasi 0.50f!")

        val floor33 = TowerLevelBuilder.buildFloor(33)
        assertEquals(0.50f, floor33.gravityScale, "Lantai 33 harus bergravitasi 0.50f!")

        val floor34 = TowerLevelBuilder.buildFloor(34)
        assertEquals(0.55f, floor34.gravityScale, "Lantai 34 harus bergravitasi 0.55f!")

        val floor35 = TowerLevelBuilder.buildFloor(35)
        assertEquals(0.65f, floor35.gravityScale, "Lantai 35 arena sarang harus bergravitasi 0.65f!")

        // Lantai 36 - 40 stabilisasi gravitasi normal di katedral gotik
        for (fNum in 36..40) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(1.0f, floor.gravityScale, "Lantai $fNum harus bergravitasi normal 1.0f!")
        }
    }

    @Test
    fun testPrismAltarTriadSwapMechanics() {
        val altar = PrismAltar(x = 22.0f, y = 1.2f)
        assertEquals(0f, altar.interactionCooldown)

        // Update timer
        altar.update(0.16f)
        assertTrue(altar.pulseTimer > 0f)

        // 1. Kasus hanya Kaelen yang terbuka
        val onlyKaelen = listOf(CharacterUnlockManager.ID_KAELEN)
        val swap1 = altar.getNextAvailableArchetype(CharacterArchetype.BALANCED, onlyKaelen)
        assertEquals(CharacterArchetype.BALANCED, swap1)

        // 2. Kasus Kaelen dan Zephyr terbuka
        val kaelenAndZephyr = listOf(CharacterUnlockManager.ID_KAELEN, CharacterUnlockManager.ID_ZEPHYR)
        val swapToZephyr = altar.getNextAvailableArchetype(CharacterArchetype.BALANCED, kaelenAndZephyr)
        assertEquals(CharacterArchetype.AGILE, swapToZephyr)

        val swapBackToKaelen = altar.getNextAvailableArchetype(CharacterArchetype.AGILE, kaelenAndZephyr)
        assertEquals(CharacterArchetype.BALANCED, swapBackToKaelen)

        // 3. Kasus Ketiga Ksatria (Triad) terbuka
        val triadUnlocked = listOf(
            CharacterUnlockManager.ID_KAELEN,
            CharacterUnlockManager.ID_ZEPHYR,
            CharacterUnlockManager.ID_GORGON
        )
        val t1 = altar.getNextAvailableArchetype(CharacterArchetype.BALANCED, triadUnlocked)
        assertEquals(CharacterArchetype.AGILE, t1)

        val t2 = altar.getNextAvailableArchetype(CharacterArchetype.AGILE, triadUnlocked)
        assertEquals(CharacterArchetype.HEAVY, t2)

        val t3 = altar.getNextAvailableArchetype(CharacterArchetype.HEAVY, triadUnlocked)
        assertEquals(CharacterArchetype.BALANCED, t3)
    }

    @Test
    fun testPrismAltarPlacementInSaga4() {
        val f31 = TowerLevelBuilder.buildFloor(31)
        assertNotNull(f31.prismAltar, "Lantai 31 harus memiliki Altar Prisma pembuka jalan!")

        val f33 = TowerLevelBuilder.buildFloor(33)
        assertNotNull(f33.prismAltar, "Lantai 33 harus memiliki Altar Prisma di labirin singularitas!")

        val f36 = TowerLevelBuilder.buildFloor(36)
        assertNotNull(f36.prismAltar, "Lantai 36 harus memiliki Altar Prisma di ambang katedral gotik!")

        val f38 = TowerLevelBuilder.buildFloor(38)
        assertNotNull(f38.prismAltar, "Lantai 38 harus memiliki Altar Prisma di altar pengorbanan!")
    }

    @Test
    fun testBloodAltarPlacementOnFloor38() {
        val f38 = TowerLevelBuilder.buildFloor(38)
        assertNotNull(f38.bloodAltar, "Lantai 38 harus memiliki Altar Pengorbanan Darah (BloodAltar)!")
    }

    @Test
    fun testSaga4CinematicDialogueRegistry() {
        // Lantai 31: Scene 13 Astral Isles
        val d31 = DialogueRegistry.getSceneForFloor(31)
        assertNotNull(d31)
        assertTrue(d31.lines.any { it.speaker == "Zephyr" })
        assertTrue(d31.lines.any { it.speaker == "Gorgon" })

        // Lantai 35: Scene 14 Void Chimera
        val d35 = DialogueRegistry.getSceneForFloor(35)
        assertNotNull(d35)
        assertTrue(d35.lines.any { it.speaker == "The Void Chimera" })

        // Lantai 36: Scene 15 Blood Cathedral
        val d36 = DialogueRegistry.getSceneForFloor(36)
        assertNotNull(d36)
        assertTrue(d36.lines.any { it.speaker == "Aria" })

        // Lantai 40: Scene 16 Malakor Showdown
        val d40 = DialogueRegistry.getSceneForFloor(40)
        assertNotNull(d40)
        assertTrue(d40.lines.any { it.speaker == "Malakor The Crimson Sovereign" })
        assertTrue(d40.lines.any { it.speaker == "Kaelen" })
    }
}
