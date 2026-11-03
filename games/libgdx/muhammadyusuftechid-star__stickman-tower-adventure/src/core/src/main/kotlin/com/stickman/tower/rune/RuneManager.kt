package com.stickman.tower.rune

import com.stickman.tower.rpg.SaveData

/**
 * Manajer Perhitungan & Pengaturan Soket Rune Senjata Ksatria.
 */
object RuneManager {
    const val MAX_SOCKETS = 2

    fun getEquippedRunes(saveData: SaveData): List<RuneType> {
        val runes = mutableListOf<RuneType>()
        for (i in 0 until MAX_SOCKETS) {
            val runeId = saveData.equippedRunes.getOrNull(i)
            runes.add(RuneType.fromString(runeId))
        }
        return runes
    }

    fun calculateBonusAtk(saveData: SaveData): Float {
        return getEquippedRunes(saveData).sumOf { it.bonusAtk.toDouble() }.toFloat()
    }

    fun calculateDamageReduction(saveData: SaveData): Float {
        return getEquippedRunes(saveData).sumOf { it.damageReductionPct.toDouble() }.toFloat().coerceIn(0f, 0.40f)
    }

    fun calculateCooldownReduction(saveData: SaveData): Float {
        return getEquippedRunes(saveData).sumOf { it.cooldownReductionPct.toDouble() }.toFloat().coerceIn(0f, 0.45f)
    }

    fun calculateCritRateBonus(saveData: SaveData): Float {
        return getEquippedRunes(saveData).sumOf { it.critRatePct.toDouble() }.toFloat()
    }

    fun calculateLifestealBonus(saveData: SaveData): Float {
        return getEquippedRunes(saveData).sumOf { it.lifestealPct.toDouble() }.toFloat()
    }

    fun equipRune(slotIndex: Int, rune: RuneType, saveData: SaveData): Boolean {
        if (slotIndex !in 0 until MAX_SOCKETS) return false
        while (saveData.equippedRunes.size < MAX_SOCKETS) {
            saveData.equippedRunes.add(RuneType.NONE.id)
        }
        saveData.equippedRunes[slotIndex] = rune.id
        return true
    }

    fun unequipRune(slotIndex: Int, saveData: SaveData): Boolean {
        return equipRune(slotIndex, RuneType.NONE, saveData)
    }

    fun unlockRune(rune: RuneType, saveData: SaveData): Boolean {
        if (rune == RuneType.NONE) return false
        if (!saveData.unlockedRunes.contains(rune.id)) {
            saveData.unlockedRunes.add(rune.id)
            return true
        }
        return false
    }
}
