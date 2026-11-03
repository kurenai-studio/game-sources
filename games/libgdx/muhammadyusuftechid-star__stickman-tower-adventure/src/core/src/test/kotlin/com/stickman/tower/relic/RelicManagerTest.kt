package com.stickman.tower.relic

import com.stickman.tower.character.Player
import com.stickman.tower.combat.FloatingText
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.vfx.ParticleManager
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RelicManagerTest {

    @Test
    fun testRelicAdditionAndQuery() {
        val manager = RelicManager()
        assertFalse(manager.has(RelicType.VAMPIRIC_FANG))

        manager.add(RelicType.VAMPIRIC_FANG)
        assertTrue(manager.has(RelicType.VAMPIRIC_FANG))
        assertEquals(1, manager.activeRelics.size)

        manager.add(RelicType.WINGS_OF_HERMES)
        assertEquals(2, manager.getMaxAirJumps()) // Triple jump enabled
    }

    @Test
    fun testVampiricFangHealOnKill() {
        val manager = RelicManager()
        val player = Player(spawnX = 0f, spawnY = 0f)
        val floatingTexts = mutableListOf<FloatingText>()
        val particles = ParticleManager()

        // Kurangi HP player
        player.health.takeDamage(30f)
        val hpBefore = player.health.currentHp

        // Tanpa relic Vampiric Fang -> tidak ada heal
        manager.onEnemyDefeated(player, floatingTexts, particles)
        assertEquals(hpBefore, player.health.currentHp)

        // Dengan relic Vampiric Fang -> heal 5% max HP (5 HP)
        manager.add(RelicType.VAMPIRIC_FANG)
        manager.onEnemyDefeated(player, floatingTexts, particles)
        assertEquals(hpBefore + 5f, player.health.currentHp)
        assertEquals(1, floatingTexts.size)
        assertEquals("+5 HP", floatingTexts.first().text)
    }

    @Test
    fun testThunderCharmComboTrigger() {
        val manager = RelicManager()
        manager.add(RelicType.THUNDER_CHARM)

        val player = Player(spawnX = 0f, spawnY = 0f)
        val enemy = Enemy(spawnX = 3f, spawnY = 0f)
        val floatingTexts = mutableListOf<FloatingText>()
        val particles = ParticleManager()

        val enemyHpBefore = enemy.health.currentHp

        // Combo 9 -> Belum memicu petir
        manager.onComboHit(9, player, listOf(enemy), null, floatingTexts, particles)
        assertEquals(enemyHpBefore, enemy.health.currentHp)

        // Combo 10 -> Petir menyambar 30 DMG
        manager.onComboHit(10, player, listOf(enemy), null, floatingTexts, particles)
        assertEquals(enemyHpBefore - 30f, enemy.health.currentHp)
        assertTrue(floatingTexts.any { it.text.contains("THUNDER") })
    }

    @Test
    fun testChronosHourglassCooldownReduction() {
        val manager = RelicManager()
        assertEquals(1.0f, manager.getCooldownMultiplier())

        manager.add(RelicType.CHRONOS_HOURGLASS)
        assertEquals(0.75f, manager.getCooldownMultiplier())
    }

    @Test
    fun testWeaponForgingStatsAndGoldCost() {
        val stats = CharacterStats(gold = 500)
        assertEquals(0, stats.weaponAtkLevel)
        assertEquals(15f, stats.attackPower) // Base attack lv 1

        // Cost tier 0 -> tier 1 adalah 120 * 1 = 120 G
        assertTrue(stats.canUpgradeAtk())
        val upgraded = stats.upgradeAtk()
        assertTrue(upgraded)
        assertEquals(1, stats.weaponAtkLevel)
        assertEquals(380, stats.gold) // 500 - 120
        assertEquals(19f, stats.attackPower) // 15 + 4 flat ATK

        // Upgrade Crit: Cost 120 G
        assertTrue(stats.upgradeCrit())
        assertEquals(1, stats.weaponCritLevel)
        assertEquals(260, stats.gold) // 380 - 120
        assertEquals(0.105f, stats.critRate) // 0.08 + 0.025

        // Upgrade Spd: Cost 120 G
        assertTrue(stats.upgradeSpd())
        assertEquals(1, stats.weaponSpdLevel)
        assertEquals(140, stats.gold) // 260 - 120
        assertEquals(0.035f, stats.weaponSpdBonus)

        // Upgrade Atk Tier 2: Cost 120 * 2 = 240 G (Gold sisa 140, tidak cukup)
        assertFalse(stats.canUpgradeAtk())
        assertFalse(stats.upgradeAtk())
        assertEquals(1, stats.weaponAtkLevel)
        assertEquals(140, stats.gold)
    }
}
