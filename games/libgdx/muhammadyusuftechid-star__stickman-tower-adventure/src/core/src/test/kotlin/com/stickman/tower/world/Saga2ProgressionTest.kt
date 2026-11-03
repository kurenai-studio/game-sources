package com.stickman.tower.world

import com.badlogic.gdx.math.Vector2
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.CharacterUnlockManager
import com.stickman.tower.character.GorgonCoopAlly
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.BossType
import com.stickman.tower.rpg.SaveData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Saga2ProgressionTest:
 * Pengujian komprehensif untuk Fase 26:
 * - Bentang luas level design Saga II (Lantai 11 - 20)
 * - Prasasti kuno kanonikal XI s/d XX (Lore Tablets 11-20)
 * - Suaka Tempa Vulcanus di Lantai 13 (Safe Hub II)
 * - Bos Lantai 15 (Forge-Master Ignis) & Bos Lantai 20 (The Slag Colossus)
 * - Mekanika pemotongan tuas rantai lahar pada TitanPillar
 * - AI Co-op Tag-Team Ally Gorgon The Ironbreaker
 * - Integrasi unlock karakter STICKMAN_HEAVY
 */
class Saga2ProgressionTest {

    @Test
    fun testSaga2FloorsScaleAndStructure() {
        for (fNum in 11..20) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(fNum, floor.floorNumber)
            assertTrue(floor.mapBounds.width >= 110f, "Lantai $fNum harus memiliki bentang luas minimal 110m!")
            assertTrue(floor.platforms.isNotEmpty(), "Lantai $fNum harus memiliki platform!")
            assertNotNull(floor.checkpoint, "Lantai $fNum harus memiliki checkpoint!")
            assertNotNull(floor.exitPortal, "Lantai $fNum harus memiliki stage exit portal!")
            assertEquals("SAGA II: CLOCKWORK FOUNDRY", floor.actTitle)
        }
    }

    @Test
    fun testLoreTabletsXIToXXContentAndPlacement() {
        for (fNum in 11..20) {
            val floor = TowerLevelBuilder.buildFloor(fNum)
            assertEquals(1, floor.loreTablets.size, "Lantai $fNum harus memiliki tepat 1 prasasti kuno!")
            val tablet = floor.loreTablets.first()
            assertEquals("TABLET_$fNum", tablet.tabletId)
            assertTrue(tablet.title.isNotEmpty())
            assertTrue(tablet.text.isNotEmpty())
        }

        // Verifikasi kutipan kanonikal Lore Tablets 11 - 20
        val t11 = TowerLevelBuilder.buildFloor(11).loreTablets.first()
        assertTrue(t11.text.contains("Catatan Zephyr"))
        assertTrue(t11.text.contains("ventilasi lantai 11"))

        val t12 = TowerLevelBuilder.buildFloor(12).loreTablets.first()
        assertTrue(t12.text.contains("jam kosmis semesta"))
        assertTrue(t12.text.contains("digiling"))

        val t13 = TowerLevelBuilder.buildFloor(13).loreTablets.first()
        assertTrue(t13.text.contains("Hari ke-10,420"))
        assertTrue(t13.text.contains("serpihan meteorit bintang"))

        val t14 = TowerLevelBuilder.buildFloor(14).loreTablets.first()
        assertTrue(t14.text.contains("serpihan batu bintang"))
        assertTrue(t14.text.contains("koin emas"))

        val t15 = TowerLevelBuilder.buildFloor(15).loreTablets.first()
        assertTrue(t15.text.contains("Ignis adalah murid terbaikku"))
        assertTrue(t15.text.contains("terak baja cair"))

        val t16 = TowerLevelBuilder.buildFloor(16).loreTablets.first()
        assertTrue(t16.text.contains("Tekanan uap di lantai 16"))

        val t17 = TowerLevelBuilder.buildFloor(17).loreTablets.first()
        assertTrue(t17.text.contains("bunker"))
        assertTrue(t17.text.contains("Gorgon"))

        val t18 = TowerLevelBuilder.buildFloor(18).loreTablets.first()
        assertTrue(t18.text.contains("Rantai-rantai ini mengikat katup lahar"))

        val t19 = TowerLevelBuilder.buildFloor(19).loreTablets.first()
        assertTrue(t19.text.contains("Pundakku remuk"))

        val t20 = TowerLevelBuilder.buildFloor(20).loreTablets.first()
        assertTrue(t20.text.contains("Gorgon membelah raksasa terak"))
    }

    @Test
    fun testFloor13VulcanusSanctuarySafeHub() {
        val floor13 = TowerLevelBuilder.buildFloor(13)
        assertTrue(floor13.isSafeZone, "Lantai 13 harus berupa Safe Zone peristirahatan!")
        assertFalse(floor13.isBossFloor, "Lantai 13 bukan arena bos!")
        assertTrue(floor13.enemies.isEmpty(), "Lantai 13 bebas monster agresif!")
        assertTrue(floor13.chests.size >= 3, "Lantai 13 harus menyediakan peti perbekalan!")
        assertNotNull(floor13.storyDialogues.firstOrNull(), "Lantai 13 harus memiliki dialog interaktif Vulcanus!")
    }

    @Test
    fun testFloor15ForgeMasterIgnisBossArena() {
        val floor15 = TowerLevelBuilder.buildFloor(15)
        assertTrue(floor15.isBossFloor, "Lantai 15 harus merupakan Boss Floor!")
        val boss = floor15.boss
        assertNotNull(boss, "Lantai 15 harus memiliki boss!")
        assertEquals("FORGE-MASTER IGNIS", boss!!.name)
        assertEquals(900f, boss.health.maxHp)
        assertTrue(boss.health.currentHp > 0f)
    }

    @Test
    fun testFloor20SlagColossusAndTitanPillarSetup() {
        val floor20 = TowerLevelBuilder.buildFloor(20)
        assertTrue(floor20.isBossFloor, "Lantai 20 harus merupakan Boss Floor!")
        val boss = floor20.boss
        assertNotNull(boss, "Lantai 20 harus memiliki boss The Slag Colossus!")
        assertEquals("THE SLAG COLOSSUS", boss!!.name)
        assertEquals(1200f, boss.health.maxHp)

        val pillar = floor20.titanPillar
        assertNotNull(pillar, "Lantai 20 harus memiliki Pilar Titan penyelamatan Gorgon!")
        assertFalse(pillar!!.isLeverCut, "Tuas katup lahar harus terkunci di awal level!")
        assertFalse(pillar.isGorgonFreed, "Gorgon masih tertahan sebelum tuas dipotong!")
    }

    @Test
    fun testTitanPillarLeverHitMechanics() {
        val pillar = TitanPillar(x = 35.0f, y = 1.2f)
        assertEquals(0, pillar.hitsTaken)
        assertFalse(pillar.isLeverCut)
        assertFalse(pillar.isGorgonFreed)

        // Tebasan pertama
        assertTrue(pillar.takeHit())
        assertEquals(1, pillar.hitsTaken)
        assertFalse(pillar.isLeverCut)

        // Tebasan kedua
        assertTrue(pillar.takeHit())
        assertEquals(2, pillar.hitsTaken)
        assertFalse(pillar.isLeverCut)

        // Tebasan ketiga (Rantai putus & pasak terkunci)
        assertTrue(pillar.takeHit())
        assertEquals(3, pillar.hitsTaken)
        assertTrue(pillar.isLeverCut)
        assertTrue(pillar.isGorgonFreed)

        // Tebasan keempat tidak berpengaruh lagi
        assertFalse(pillar.takeHit())
    }

    @Test
    fun testGorgonCoopAllyCombatBehavior() {
        val ally = GorgonCoopAlly(spawnX = 35.0f, spawnY = 1.2f)
        assertTrue(ally.isActive)
        assertTrue(ally.facingRight)

        val boss = BossEnemy(spawnX = 36.5f, spawnY = 1.2f, type = BossType.SHADOW_DOPPELGANGER, customMaxHp = 1000f)
        var hitDamageReceived = 0f
        var isHeavySlamTriggered = false

        ally.onBossHit = { dmg, isSlam ->
            hitDamageReceived = dmg
            isHeavySlamTriggered = isSlam
        }

        // Jalankan beberapa frame update untuk memicu serangan
        val playerPos = Vector2(30.0f, 1.2f)
        for (i in 1..20) {
            ally.update(0.1f, boss, playerPos)
        }

        assertTrue(hitDamageReceived > 0f, "Gorgon harus menyerang boss dalam jangkauan!")
        assertTrue(boss.health.currentHp < 1000f, "HP Bos harus berkurang akibat serangan Greatsword Gorgon!")
    }

    @Test
    fun testGorgonCharacterUnlockFlow() {
        val save = SaveData(
            playerLevel = 15,
            highestTowerFloor = 20,
            isGorgonRescued = false
        )
        assertFalse(CharacterUnlockManager.isCharacterUnlocked(CharacterArchetype.HEAVY, save))

        // Trigger unlock Gorgon
        val unlocked = CharacterUnlockManager.unlockGorgon(save)
        assertTrue(unlocked)
        assertTrue(save.isGorgonRescued)
        assertTrue(save.unlockedCharacters.contains(CharacterUnlockManager.ID_GORGON))
        assertTrue(CharacterUnlockManager.isCharacterUnlocked(CharacterArchetype.HEAVY, save))
    }
}
