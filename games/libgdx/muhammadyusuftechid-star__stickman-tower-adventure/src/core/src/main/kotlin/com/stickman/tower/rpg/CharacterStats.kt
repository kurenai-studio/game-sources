package com.stickman.tower.rpg

import kotlin.math.floor
import kotlin.math.max
import kotlin.math.pow
import kotlin.random.Random

/**
 * Manages player RPG statistics, leveling curve, weapon forging upgrades, and EXP/Gold accumulation.
 */
class CharacterStats(
    var level: Int = 1,
    val baseMaxHp: Float = 100f,
    val baseAttack: Float = 15f,
    var defense: Float = 2f,
    var baseCritRate: Float = 0.08f,
    var critMultiplier: Float = 1.6f,
    var currentExp: Int = 0,
    var gold: Int = 0,
    var weaponAtkLevel: Int = 0,
    var weaponCritLevel: Int = 0,
    var weaponSpdLevel: Int = 0
) {
    companion object {
        const val MAX_WEAPON_LEVEL = 10

        fun getUpgradeCost(currentLevel: Int): Int {
            return 120 * (currentLevel + 1)
        }
    }

    val maxHp: Float
        get() = baseMaxHp * (1f + 0.10f * (level - 1))

    val weaponAtkBonus: Float
        get() = weaponAtkLevel * 4.0f

    val weaponCritBonus: Float
        get() = weaponCritLevel * 0.025f

    val weaponSpdBonus: Float
        get() = weaponSpdLevel * 0.035f

    var runeAtkBonus: Float = 0f
    var runeCritBonus: Float = 0f

    val attackPower: Float
        get() = (baseAttack * (1f + 0.08f * (level - 1))) + weaponAtkBonus + runeAtkBonus

    val critRate: Float
        get() = (baseCritRate + weaponCritBonus + runeCritBonus).coerceIn(0f, 0.85f)

    val requiredExp: Int
        get() = max(50, floor(100.0 * (level.toDouble()).pow(1.35)).toInt())

    /**
     * Adds EXP and returns the number of levels gained (0 if no level up occurred).
     */
    fun addExp(amount: Int): Int {
        var levelsGained = 0
        currentExp += amount
        while (currentExp >= requiredExp) {
            currentExp -= requiredExp
            level++
            levelsGained++
        }
        return levelsGained
    }

    /**
     * Adds gold coins collected.
     */
    fun addGold(amount: Int) {
        gold += amount
    }

    fun canUpgradeAtk(): Boolean = weaponAtkLevel < MAX_WEAPON_LEVEL && gold >= getUpgradeCost(weaponAtkLevel)
    fun upgradeAtk(): Boolean {
        if (!canUpgradeAtk()) return false
        gold -= getUpgradeCost(weaponAtkLevel)
        weaponAtkLevel++
        return true
    }

    fun canUpgradeCrit(): Boolean = weaponCritLevel < MAX_WEAPON_LEVEL && gold >= getUpgradeCost(weaponCritLevel)
    fun upgradeCrit(): Boolean {
        if (!canUpgradeCrit()) return false
        gold -= getUpgradeCost(weaponCritLevel)
        weaponCritLevel++
        return true
    }

    fun canUpgradeSpd(): Boolean = weaponSpdLevel < MAX_WEAPON_LEVEL && gold >= getUpgradeCost(weaponSpdLevel)
    fun upgradeSpd(): Boolean {
        if (!canUpgradeSpd()) return false
        gold -= getUpgradeCost(weaponSpdLevel)
        weaponSpdLevel++
        return true
    }

    /**
     * Calculates final damage based on skill base damage, attack scaling, target defense, and critical chance.
     * Returns a Pair of (finalDamage: Float, isCritical: Boolean).
     */
    fun calculateDamage(skillBaseDamage: Float, targetDefense: Float = 0f): Pair<Float, Boolean> {
        val rawDamage = skillBaseDamage * (attackPower / baseAttack)
        val isCrit = Random.nextFloat() < critRate
        val multiplier = if (isCrit) critMultiplier else 1.0f
        val finalDmg = max(1f, (rawDamage - targetDefense) * multiplier)
        return Pair(finalDmg, isCrit)
    }

    fun toSaveData(
        highestFloor: Int = 1,
        selectedArchetype: String = "BALANCED",
        selectedSubClass: String = "BERSERKER",
        unlockedCharacters: List<String> = listOf("STICKMAN_SWORD")
    ): SaveData {
        return SaveData(
            playerLevel = level,
            currentExp = currentExp,
            gold = gold,
            highestTowerFloor = highestFloor,
            selectedArchetype = selectedArchetype,
            selectedSubClass = selectedSubClass,
            unlockedCharacters = ArrayList(unlockedCharacters),
            weaponAtkLevel = weaponAtkLevel,
            weaponCritLevel = weaponCritLevel,
            weaponSpdLevel = weaponSpdLevel
        )
    }

    /**
     * Memperbarui data RPG pada objek SaveData yang sudah ada tanpa menimpa data sub-class atau karakter terbuka.
     */
    fun applyToSaveData(existing: SaveData): SaveData {
        return existing.apply {
            playerLevel = level
            currentExp = this@CharacterStats.currentExp
            gold = this@CharacterStats.gold
            weaponAtkLevel = this@CharacterStats.weaponAtkLevel
            weaponCritLevel = this@CharacterStats.weaponCritLevel
            weaponSpdLevel = this@CharacterStats.weaponSpdLevel
        }
    }

    fun loadFromSaveData(data: SaveData) {
        this.level = max(1, data.playerLevel)
        this.currentExp = max(0, data.currentExp)
        this.gold = max(0, data.gold)
        this.weaponAtkLevel = data.weaponAtkLevel.coerceIn(0, MAX_WEAPON_LEVEL)
        this.weaponCritLevel = data.weaponCritLevel.coerceIn(0, MAX_WEAPON_LEVEL)
        this.weaponSpdLevel = data.weaponSpdLevel.coerceIn(0, MAX_WEAPON_LEVEL)
        this.runeAtkBonus = com.stickman.tower.rune.RuneManager.calculateBonusAtk(data)
        this.runeCritBonus = com.stickman.tower.rune.RuneManager.calculateCritRateBonus(data)
    }
}
