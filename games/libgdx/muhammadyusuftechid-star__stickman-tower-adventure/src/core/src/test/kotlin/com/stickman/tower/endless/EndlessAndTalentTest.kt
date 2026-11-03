package com.stickman.tower.endless

import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.Player
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.talent.SubClass
import com.stickman.tower.talent.TalentCatalog
import com.stickman.tower.talent.TalentManager
import com.stickman.tower.world.TowerLevelBuilder
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class EndlessAndTalentTest {

    @Test
    fun testFloorMutatorsProperties() {
        val none = FloorMutator.NONE
        assertEquals(1.0f, none.playerAttackMultiplier)
        assertEquals(1.0f, none.gravityMultiplier)
        assertFalse(none.isToxicMiasma)

        val berserk = FloorMutator.BERSERK_SURGE
        assertTrue(berserk.playerAttackMultiplier > 1.0f)
        assertTrue(berserk.enemyAttackMultiplier > 1.0f)

        val lowGrav = FloorMutator.LOW_GRAVITY
        assertEquals(0.65f, lowGrav.gravityMultiplier)

        val miasma = FloorMutator.TOXIC_MIASMA
        assertTrue(miasma.isToxicMiasma)

        val vamp = FloorMutator.VAMPIRIC_ECLIPSE
        assertEquals(0.15f, vamp.lifestealPercent)

        // Random Mutator
        val randomMut = FloorMutator.getRandomMutator()
        assertNotNull(randomMut)
    }

    @Test
    fun testTalentCatalogIntegrity() {
        // Harus ada 18 talent (3 tier x 6 subclass)
        assertEquals(18, TalentCatalog.allTalents.size)

        for (subClass in SubClass.values().filter { it != SubClass.NONE }) {
            val talents = TalentCatalog.getTalentsForSubClass(subClass)
            assertEquals(3, talents.size, "SubClass $subClass harus memiliki 3 talent!")
            assertEquals(1, talents[0].tier)
            assertEquals(2, talents[1].tier)
            assertEquals(3, talents[2].tier)
        }
    }

    @Test
    fun testTalentManagerProgressionAndPrerequisites() {
        val manager = TalentManager(CharacterArchetype.BALANCED)
        assertEquals(SubClass.BERSERKER, manager.selectedSubClass)
        assertEquals(3, manager.talentPoints) // 3 poin awal

        // Gagal buka Tier 2 langsung (prasyarat Tier 1 belum dipenuhi)
        assertFalse(manager.unlockTalent("BS_FRENZY_STRIKES"))

        // Buka Tier 1 sukses (cost 1)
        assertTrue(manager.unlockTalent("BS_BLOOD_RAGE"))
        assertEquals(2, manager.talentPoints)
        assertTrue(manager.isTalentUnlocked("BS_BLOOD_RAGE"))

        // Buka Tier 2 sukses setelah Tier 1 (cost 1)
        assertTrue(manager.unlockTalent("BS_FRENZY_STRIKES"))
        assertEquals(1, manager.talentPoints)
        assertTrue(manager.isTalentUnlocked("BS_FRENZY_STRIKES"))

        // Gagal buka Tier 3 karena butuh 2 poin (sisa cuma 1)
        assertFalse(manager.unlockTalent("BS_UNDYING_WILL"))

        // Tambah 1 poin lagi -> total 2 poin
        manager.addTalentPoints(1)
        assertEquals(2, manager.talentPoints)

        // Buka Tier 3 sukses (cost 2)
        assertTrue(manager.unlockTalent("BS_UNDYING_WILL"))
        assertEquals(0, manager.talentPoints)
        assertTrue(manager.isTalentUnlocked("BS_UNDYING_WILL"))
        assertTrue(manager.hasUndyingWill())
    }

    @Test
    fun testTalentManagerCombatMultipliers() {
        val manager = TalentManager(CharacterArchetype.BALANCED)
        manager.addTalentPoints(10)
        manager.unlockTalent("BS_BLOOD_RAGE")

        // Blood Rage: +35% ATK saat HP <= 50%
        val atkFullHp = manager.getAttackMultiplier(100f, 100f)
        assertEquals(1.0f, atkFullHp)

        val atkLowHp = manager.getAttackMultiplier(40f, 100f)
        assertEquals(1.35f, atkLowHp)

        // Guardian Iron Bulwark: -20% Damage Received
        manager.selectSubClass(SubClass.GUARDIAN)
        manager.unlockTalent("GD_IRON_BULWARK")
        assertEquals(0.80f, manager.getDamageReductionMultiplier())

        manager.unlockTalent("GD_COUNTER_FORTITUDE")
        assertTrue(manager.hasParryHeal())

        manager.unlockTalent("GD_AEGIS_STANCE")
        assertTrue(manager.hasSuperArmor())
    }

    @Test
    fun testTalentManagerRespec() {
        val manager = TalentManager(CharacterArchetype.AGILE)
        manager.selectSubClass(SubClass.VENOMANCER)
        manager.addTalentPoints(5) // 3 awal + 5 = 8 poin

        assertTrue(manager.unlockTalent("VM_TOXIC_BLADE")) // cost 1
        assertTrue(manager.hasToxicBlade())
        assertEquals(7, manager.talentPoints)

        manager.respec()
        assertFalse(manager.hasToxicBlade())
        assertEquals(8, manager.talentPoints)
        assertTrue(manager.unlockedTalentIds.isEmpty())
    }

    @Test
    fun testTalentManagerSaveSync() {
        val manager = TalentManager(CharacterArchetype.HEAVY)
        manager.selectSubClass(SubClass.ARCHMAGE)
        manager.addTalentPoints(4)
        manager.unlockTalent("AM_ARCANE_CONDUIT")

        val saveData = SaveData()
        manager.syncToSave(saveData)

        assertEquals("ARCHMAGE", saveData.selectedSubClass)
        assertTrue(saveData.unlockedCharacters.contains("TALENT_AM_ARCANE_CONDUIT"))

        // Manager baru memuat dari SaveData
        val restoredManager = TalentManager(CharacterArchetype.HEAVY)
        restoredManager.syncFromSave(saveData)

        assertEquals(SubClass.ARCHMAGE, restoredManager.selectedSubClass)
        assertTrue(restoredManager.isTalentUnlocked("AM_ARCANE_CONDUIT"))
        assertEquals(0.70f, restoredManager.getCooldownMultiplier())
    }

    @Test
    fun testTowerLevelBuilderEndlessFloors() {
        // Lantai Biasa (Lantai 4)
        val floor4 = TowerLevelBuilder.buildEndlessFloor(4, FloorMutator.BERSERK_SURGE)
        assertNotNull(floor4)
        assertFalse(floor4.isBossFloor)
        assertTrue(floor4.enemies.isNotEmpty())
        assertTrue(floor4.platforms.isNotEmpty())
        assertNotNull(floor4.exitPortal)

        // Musuh di lantai 4 harus memiliki HP lebih besar dari base 50f
        val firstEnemy = floor4.enemies.first()
        assertTrue(firstEnemy.health.maxHp > 50f)

        // Lantai Boss (Lantai 5: Kelipatan 5)
        val floor5 = TowerLevelBuilder.buildEndlessFloor(5, FloorMutator.NONE)
        assertNotNull(floor5)
        assertTrue(floor5.isBossFloor)
        assertNotNull(floor5.boss)
        assertTrue(floor5.boss!!.health.maxHp > 350f)
    }

    @Test
    fun testPlayerUndyingWillMechanic() {
        val player = Player(spawnX = 0f, spawnY = 0f)
        player.hasUndyingWill = true
        player.undyingWillUsed = false

        // Berikan damage mematikan (200 damage pada 100 HP)
        val tookHit = player.takeHit(200f, 0f, 0f)
        assertTrue(tookHit)
        // Pemain tidak boleh mati seketika, diselamatkan dengan 1 HP
        assertFalse(player.health.isDead)
        assertEquals(1f, player.health.currentHp)
        assertTrue(player.undyingWillUsed)

        // Reset invulnerability dari trigger undying will agar serangan mematikan berikutnya masuk
        player.health.update(3.0f)

        // Serangan kedua setelah used -> mati
        player.takeHit(10f, 0f, 0f)
        assertTrue(player.health.isDead)
    }
}
