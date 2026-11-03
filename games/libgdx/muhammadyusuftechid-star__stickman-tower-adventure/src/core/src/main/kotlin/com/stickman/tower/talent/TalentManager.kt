package com.stickman.tower.talent

import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager

/**
 * Manajer Pengelolaan Talent Tree, Alokasi Poin, dan Kalkulasi Bonus Tempur Sub-Class (Fase 13).
 */
class TalentManager(initialArchetype: CharacterArchetype = CharacterArchetype.BALANCED) {

    var selectedSubClass: SubClass = when (initialArchetype) {
        CharacterArchetype.BALANCED -> SubClass.BERSERKER
        CharacterArchetype.AGILE -> SubClass.SHADOW_STALKER
        CharacterArchetype.HEAVY -> SubClass.ARCHMAGE
    }
        private set

    var talentPoints: Int = 3
        private set

    val unlockedTalentIds = mutableSetOf<String>()

    fun loadFromSave(saveData: SaveData) {
        val subClassStr = saveData.selectedSubClass
        val fromSave = SubClass.fromString(subClassStr)
        if (fromSave != SubClass.NONE) {
            selectedSubClass = fromSave
        } else {
            val fromList = saveData.unlockedCharacters.firstOrNull { it.startsWith("SUBCLASS_") }?.removePrefix("SUBCLASS_")
            if (fromList != null) {
                selectedSubClass = SubClass.fromString(fromList)
            }
        }
        unlockedTalentIds.clear()
        // Skema V2
        for (id in saveData.unlockedTalents) {
            unlockedTalentIds.add(id)
        }
        // Skema V1 legacy
        for (id in saveData.unlockedCharacters) {
            if (id.startsWith("TALENT_")) {
                unlockedTalentIds.add(id.removePrefix("TALENT_"))
            }
        }
        if (saveData.unspentTalentPoints >= 0) {
            talentPoints = saveData.unspentTalentPoints
        } else {
            // Kompatibilitas mundur save legacy: total poin diperoleh dikurangi poin yang telah dibelanjakan
            val totalEarned = saveData.playerLevel.coerceAtLeast(1) / 2 + 2
            val spentPoints = unlockedTalentIds.sumOf { TalentCatalog.findById(it)?.cost ?: 1 }
            talentPoints = (totalEarned - spentPoints).coerceAtLeast(0)
        }
    }

    fun syncFromSave(saveData: SaveData) = loadFromSave(saveData)

    fun syncToSave(saveData: SaveData) {
        saveData.selectedSubClass = selectedSubClass.name
        saveData.unspentTalentPoints = talentPoints

        saveData.unlockedTalents.clear()
        saveData.unlockedTalents.addAll(unlockedTalentIds)

        saveData.unlockedCharacters.removeAll { it.startsWith("SUBCLASS_") || it.startsWith("TALENT_") }
        saveData.unlockedCharacters.add("SUBCLASS_${selectedSubClass.idName}")
        for (id in unlockedTalentIds) {
            saveData.unlockedCharacters.add("TALENT_$id")
        }
    }

    fun selectSubClass(subClass: SubClass, currentArchetype: CharacterArchetype? = null): Boolean {
        if (currentArchetype == null || subClass == SubClass.NONE || subClass.archetype == currentArchetype) {
            selectedSubClass = subClass
            return true
        }
        return false
    }

    fun isTalentUnlocked(talentId: String): Boolean = unlockedTalentIds.contains(talentId)

    fun canUnlockTalent(talent: Talent): Boolean {
        if (isTalentUnlocked(talent.id)) return false
        if (talentPoints < talent.cost) return false
        if (selectedSubClass != talent.subClass) return false

        // Memeriksa prasyarat tier (Tier 2 butuh Tier 1, Tier 3 butuh Tier 2)
        if (talent.tier == 2) {
            val tier1 = TalentCatalog.getTalentsFor(talent.subClass).firstOrNull { it.tier == 1 }
            if (tier1 != null && !isTalentUnlocked(tier1.id)) return false
        } else if (talent.tier == 3) {
            val tier2 = TalentCatalog.getTalentsFor(talent.subClass).firstOrNull { it.tier == 2 }
            if (tier2 != null && !isTalentUnlocked(tier2.id)) return false
        }
        return true
    }

    fun canUnlockTalent(talentId: String): Boolean {
        val talent = TalentCatalog.findById(talentId) ?: return false
        return canUnlockTalent(talent)
    }

    fun unlockTalent(talent: Talent): Boolean {
        if (!canUnlockTalent(talent)) return false
        talentPoints -= talent.cost
        unlockedTalentIds.add(talent.id)
        return true
    }

    fun unlockTalent(talentId: String): Boolean {
        val talent = TalentCatalog.findById(talentId) ?: return false
        return unlockTalent(talent)
    }

    /**
     * Mengembalikan seluruh poin talent yang telah dialokasikan (Respec).
     */
    fun respecTalents() {
        for (id in unlockedTalentIds) {
            val talent = TalentCatalog.findById(id)
            if (talent != null) {
                talentPoints += talent.cost
            }
        }
        unlockedTalentIds.clear()
    }

    fun respec() = respecTalents()

    fun addTalentPoints(amount: Int) {
        talentPoints = (talentPoints + amount).coerceAtLeast(0)
    }

    // =========================================================================
    // Modifikator Tempur Real-Time (Combat Stat Multipliers)
    // =========================================================================

    /**
     * Multiplier serangan saat ini (termasuk Blood Rage saat HP < 50%).
     */
    fun getAttackMultiplier(currentHp: Float, maxHp: Float): Float {
        var mult = 1.0f
        if (selectedSubClass == SubClass.BERSERKER && isTalentUnlocked("BS_BLOOD_RAGE")) {
            if (maxHp > 0f && (currentHp / maxHp) <= 0.50f) {
                mult += 0.35f
            }
        }
        if (selectedSubClass == SubClass.SPELLBLADE && isTalentUnlocked("SB_ELEMENTAL_INFUSION")) {
            mult += 0.25f
        }
        return mult
    }

    /**
     * Pengurangan damage yang diterima (Iron Bulwark -20%).
     */
    fun getDamageReductionMultiplier(): Float {
        var red = 1.0f
        if (selectedSubClass == SubClass.GUARDIAN && isTalentUnlocked("GD_IRON_BULWARK")) {
            red *= 0.80f
        }
        return red
    }

    /**
     * Bonus Critical Rate (Lethal Precision +15%).
     */
    fun getCritRateBonus(): Float {
        var bonus = 0f
        if (selectedSubClass == SubClass.SHADOW_STALKER && isTalentUnlocked("SS_LETHAL_PRECISION")) {
            bonus += 0.15f
        }
        return bonus
    }

    /**
     * Bonus Critical Multiplier.
     */
    fun getCritMultiplier(): Float {
        var mult = 1.6f
        if (selectedSubClass == SubClass.SHADOW_STALKER && isTalentUnlocked("SS_LETHAL_PRECISION")) {
            mult = 2.2f
        }
        return mult
    }

    /**
     * Cooldown Multiplier (Archmage Arcane Conduit -30%).
     */
    fun getCooldownMultiplier(): Float {
        var mult = 1.0f
        if (selectedSubClass == SubClass.ARCHMAGE && isTalentUnlocked("AM_ARCANE_CONDUIT")) {
            mult *= 0.70f
        }
        return mult
    }

    /**
     * Menentukan apakah karakter kebal terhadap stagger/knockback (Aegis Stance).
     */
    fun hasSuperArmor(): Boolean {
        return selectedSubClass == SubClass.GUARDIAN && isTalentUnlocked("GD_AEGIS_STANCE")
    }

    /**
     * Efek pemulihan 15% HP saat Perfect Parry (Counter Fortitude).
     */
    fun hasParryHeal(): Boolean {
        return selectedSubClass == SubClass.GUARDIAN && isTalentUnlocked("GD_COUNTER_FORTITUDE")
    }

    /**
     * Efek racun pada setiap tebasan (Toxic Blade).
     */
    fun hasToxicBlade(): Boolean {
        return selectedSubClass == SubClass.VENOMANCER && isTalentUnlocked("VM_TOXIC_BLADE")
    }

    /**
     * Efek menahan kematian sekali per lantai (Undying Will).
     */
    fun hasUndyingWill(): Boolean {
        return selectedSubClass == SubClass.BERSERKER && isTalentUnlocked("BS_UNDYING_WILL")
    }

    /**
     * Efek Mana Shield: menyerap 35% damage dengan energi Ultimate.
     */
    fun hasManaShield(): Boolean {
        return selectedSubClass == SubClass.ARCHMAGE && isTalentUnlocked("AM_MANA_SHIELD")
    }
}
