package com.stickman.tower.rune

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.combat.Health
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.world.BloodAltar
import com.stickman.tower.world.TemporalPact
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit Test Komprehensif untuk Sistem Transmutasi Rune & Altar Pengorbanan Anima (Fase 22).
 */
class RuneAndAltarTest {

    private lateinit var saveData: SaveData

    @Before
    fun setUp() {
        saveData = SaveData(
            equippedRunes = arrayListOf(RuneType.NONE.id, RuneType.NONE.id),
            unlockedRunes = arrayListOf(RuneType.RUNE_SOLAR.id)
        )
    }

    @Test
    fun testRuneTypePropertiesAndLookup() {
        assertEquals("☼", RuneType.RUNE_SOLAR.runeSymbol)
        assertEquals(8f, RuneType.RUNE_SOLAR.bonusAtk, 0.001f)
        assertEquals(0.10f, RuneType.RUNE_LUNAR.damageReductionPct, 0.001f)
        assertEquals(0.15f, RuneType.RUNE_TEMPEST.cooldownReductionPct, 0.001f)
        assertEquals(0.08f, RuneType.RUNE_ABYSS.critRatePct, 0.001f)
        assertEquals(0.04f, RuneType.RUNE_ABYSS.lifestealPct, 0.001f)

        // Lookup from String ID
        assertEquals(RuneType.RUNE_SOLAR, RuneType.fromString("RUNE_SOLAR"))
        assertEquals(RuneType.RUNE_LUNAR, RuneType.fromString("RUNE_LUNAR"))
        assertEquals(RuneType.RUNE_TEMPEST, RuneType.fromString("RUNE_TEMPEST"))
        assertEquals(RuneType.RUNE_ABYSS, RuneType.fromString("RUNE_ABYSS"))
        assertEquals(RuneType.NONE, RuneType.fromString("UNKNOWN_RUNE"))
        assertEquals(RuneType.NONE, RuneType.fromString(null))
    }

    @Test
    fun testRuneManagerEquipAndUnequip() {
        // Equip Solar Rune on Slot 0
        assertTrue(RuneManager.equipRune(0, RuneType.RUNE_SOLAR, saveData))
        assertEquals(RuneType.RUNE_SOLAR.id, saveData.equippedRunes[0])

        // Equip Lunar Rune on Slot 1
        assertTrue(RuneManager.equipRune(1, RuneType.RUNE_LUNAR, saveData))
        assertEquals(RuneType.RUNE_LUNAR.id, saveData.equippedRunes[1])

        // Invalid Slot
        assertFalse(RuneManager.equipRune(-1, RuneType.RUNE_TEMPEST, saveData))
        assertFalse(RuneManager.equipRune(2, RuneType.RUNE_TEMPEST, saveData))

        // Get equipped runes
        val equipped = RuneManager.getEquippedRunes(saveData)
        assertEquals(2, equipped.size)
        assertEquals(RuneType.RUNE_SOLAR, equipped[0])
        assertEquals(RuneType.RUNE_LUNAR, equipped[1])

        // Unequip Slot 0
        assertTrue(RuneManager.unequipRune(0, saveData))
        assertEquals(RuneType.NONE, RuneManager.getEquippedRunes(saveData)[0])
    }

    @Test
    fun testRuneManagerStatCalculations() {
        // Empty slots produce 0 bonus
        assertEquals(0f, RuneManager.calculateBonusAtk(saveData), 0.001f)
        assertEquals(0f, RuneManager.calculateDamageReduction(saveData), 0.001f)
        assertEquals(0f, RuneManager.calculateCooldownReduction(saveData), 0.001f)
        assertEquals(0f, RuneManager.calculateCritRateBonus(saveData), 0.001f)
        assertEquals(0f, RuneManager.calculateLifestealBonus(saveData), 0.001f)

        // Equip Solar (Slot 0: +8 ATK) & Abyss (Slot 1: +8% Crit, +5% Lifesteal)
        RuneManager.equipRune(0, RuneType.RUNE_SOLAR, saveData)
        RuneManager.equipRune(1, RuneType.RUNE_ABYSS, saveData)

        assertEquals(8f, RuneManager.calculateBonusAtk(saveData), 0.001f)
        assertEquals(0.08f, RuneManager.calculateCritRateBonus(saveData), 0.001f)
        assertEquals(0.04f, RuneManager.calculateLifestealBonus(saveData), 0.001f)

        // Equip Tempest (+15% CDR) & Lunar (+10% Dmg Reduction)
        RuneManager.equipRune(0, RuneType.RUNE_TEMPEST, saveData)
        RuneManager.equipRune(1, RuneType.RUNE_LUNAR, saveData)

        assertEquals(0.15f, RuneManager.calculateCooldownReduction(saveData), 0.001f)
        assertEquals(0.10f, RuneManager.calculateDamageReduction(saveData), 0.001f)
    }

    @Test
    fun testRuneManagerUnlock() {
        assertFalse(saveData.unlockedRunes.contains(RuneType.RUNE_TEMPEST.id))

        // Unlock tempest rune
        assertTrue(RuneManager.unlockRune(RuneType.RUNE_TEMPEST, saveData))
        assertTrue(saveData.unlockedRunes.contains(RuneType.RUNE_TEMPEST.id))

        // Duplicate unlock returns false
        assertFalse(RuneManager.unlockRune(RuneType.RUNE_TEMPEST, saveData))

        // Unlock NONE returns false
        assertFalse(RuneManager.unlockRune(RuneType.NONE, saveData))
    }

    @Test
    fun testCharacterStatsIntegrationWithRunes() {
        val stats = CharacterStats(baseAttack = 20f, baseCritRate = 0.05f)
        stats.runeAtkBonus = 8f
        stats.runeCritBonus = 0.08f

        assertEquals(28f, stats.attackPower, 0.001f)
        assertEquals(0.13f, stats.critRate, 0.001f)
    }

    @Test
    fun testTemporalPactEnum() {
        assertEquals("CARNAGE", TemporalPact.CARNAGE.id)
        assertEquals("GREED", TemporalPact.GREED.id)
        assertEquals("SWIFTNESS", TemporalPact.SWIFTNESS.id)
        assertEquals("NONE", TemporalPact.NONE.id)

        assertNotNull(TemporalPact.CARNAGE.displayName)
        assertNotNull(TemporalPact.CARNAGE.description)
        assertNotNull(TemporalPact.CARNAGE.primaryColor)
    }

    @Test
    fun testBloodAltarProximityAndActivation() {
        val altar = BloodAltar(x = 10f, y = 2f)
        assertEquals(10f, altar.x, 0.001f)
        assertEquals(2f, altar.y, 0.001f)
        assertFalse(altar.isActivated)
        assertEquals(TemporalPact.NONE, altar.activePact)

        // Player near altar
        assertTrue(altar.isPlayerNear(playerX = 10.5f, playerY = 2f, playerW = 0.8f, playerH = 1.6f))

        // Player far from altar
        assertFalse(altar.isPlayerNear(playerX = 25f, playerY = 2f, playerW = 0.8f, playerH = 1.6f))

        // Activate altar with Carnage pact
        altar.isActivated = true
        altar.activePact = TemporalPact.CARNAGE
        assertTrue(altar.isActivated)
        assertEquals(TemporalPact.CARNAGE, altar.activePact)
    }

    @Test
    fun testHealthConsumeHpForPactSacrifice() {
        val health = Health(maxHp = 100f)
        health.heal(100f)
        assertEquals(100f, health.currentHp, 0.001f)

        // Consume 25 HP
        val consumed = health.consumeHp(25f)
        assertEquals(25f, consumed, 0.001f)
        assertEquals(75f, health.currentHp, 0.001f)

        // Try to consume more than remaining HP - ensures minimum 1 HP remains
        val excessive = health.consumeHp(100f)
        assertEquals(74f, excessive, 0.001f)
        assertEquals(1f, health.currentHp, 0.001f)
        assertFalse(health.isDead)
    }

    @Test
    fun testSaveDataChecksumIntegrityWithRunes() {
        saveData.updateChecksum()
        val originalChecksum = saveData.checksum
        assertTrue(saveData.isChecksumValid())

        // Modify equipped runes
        saveData.equippedRunes[0] = RuneType.RUNE_SOLAR.id
        // Without updateChecksum, checksum is now invalid
        assertFalse(saveData.isChecksumValid())

        // Updating checksum re-validates and passes
        saveData.updateChecksum()
        assertTrue(saveData.isChecksumValid())
        assertTrue(saveData.checksum != originalChecksum)
    }
}
