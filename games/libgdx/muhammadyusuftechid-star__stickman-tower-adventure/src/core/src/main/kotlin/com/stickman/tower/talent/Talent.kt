package com.stickman.tower.talent

/**
 * Node Talent Pasif dalam Pohon Keahlian (Talent Tree).
 */
data class Talent(
    val id: String,
    val subClass: SubClass,
    val tier: Int,
    val name: String,
    val description: String,
    val cost: Int = 1,
    val iconSymbol: String = "✦"
)

object TalentCatalog {
    val allTalents: List<Talent> = listOf(
        // === BERSERKER ===
        Talent(
            id = "BS_BLOOD_RAGE",
            subClass = SubClass.BERSERKER,
            tier = 1,
            name = "Blood Rage",
            description = "Memberikan bonus +35% Attack saat HP berada di bawah 50%.",
            cost = 1,
            iconSymbol = "🩸"
        ),
        Talent(
            id = "BS_FRENZY_STRIKES",
            subClass = SubClass.BERSERKER,
            tier = 2,
            name = "Frenzy Strikes",
            description = "Meningkatkan kecepatan ayunan senjata +20% dan memberi 25% peluang double strike.",
            cost = 1,
            iconSymbol = "⚡"
        ),
        Talent(
            id = "BS_UNDYING_WILL",
            subClass = SubClass.BERSERKER,
            tier = 3,
            name = "Undying Will",
            description = "Mencegah kematian dari serangan mematikan sekali per lantai (HP tertahan di 1 + 2.5s invulnerability).",
            cost = 2,
            iconSymbol = "🔥"
        ),

        // === GUARDIAN ===
        Talent(
            id = "GD_IRON_BULWARK",
            subClass = SubClass.GUARDIAN,
            tier = 1,
            name = "Iron Bulwark",
            description = "Meningkatkan Max HP sebesar +25% dan mengurangi semua damage yang diterima sebesar 20%.",
            cost = 1,
            iconSymbol = "🛡️"
        ),
        Talent(
            id = "GD_COUNTER_FORTITUDE",
            subClass = SubClass.GUARDIAN,
            tier = 2,
            name = "Counter Fortitude",
            description = "Melakukan Perfect Parry memulihkan 15% Max HP dan menyegarkan cooldown Dodge.",
            cost = 1,
            iconSymbol = "✨"
        ),
        Talent(
            id = "GD_AEGIS_STANCE",
            subClass = SubClass.GUARDIAN,
            tier = 3,
            name = "Aegis Stance",
            description = "Super Armor Permanen: Kebal terhadap efek knockback atau stagger dari musuh reguler.",
            cost = 2,
            iconSymbol = "👑"
        ),

        // === SHADOW STALKER ===
        Talent(
            id = "SS_LETHAL_PRECISION",
            subClass = SubClass.SHADOW_STALKER,
            tier = 1,
            name = "Lethal Precision",
            description = "Peluang Critical Rate +15% dan Critical Damage meningkat menjadi 220%.",
            cost = 1,
            iconSymbol = "🎯"
        ),
        Talent(
            id = "SS_SHADOW_STEP",
            subClass = SubClass.SHADOW_STALKER,
            tier = 2,
            name = "Shadow Step",
            description = "Jarak Dodge Roll bertambah +35% dan meninggalkan bayangan pengecoh musuh.",
            cost = 1,
            iconSymbol = "💨"
        ),
        Talent(
            id = "SS_ASSASSINATE",
            subClass = SubClass.SHADOW_STALKER,
            tier = 3,
            name = "Assassinate",
            description = "Menyerang musuh dari arah punggung memiliki 100% Guaranteed Critical Strike.",
            cost = 2,
            iconSymbol = "🗡️"
        ),

        // === VENOMANCER ===
        Talent(
            id = "VM_TOXIC_BLADE",
            subClass = SubClass.VENOMANCER,
            tier = 1,
            name = "Toxic Blade",
            description = "Setiap tebasan memberi efek Poison DoT (5 damage/detik selama 4 detik).",
            cost = 1,
            iconSymbol = "🧪"
        ),
        Talent(
            id = "VM_NEUROTOXIN",
            subClass = SubClass.VENOMANCER,
            tier = 2,
            name = "Neurotoxin",
            description = "Musuh yang terkena racun mengalami pengurangan kecepatan gerak sebesar 30%.",
            cost = 1,
            iconSymbol = "🕸️"
        ),
        Talent(
            id = "VM_PLAGUE_BURST",
            subClass = SubClass.VENOMANCER,
            tier = 3,
            name = "Plague Burst",
            description = "Musuh beracun yang mati akan meledak, menyebarkan racun ke musuh sekitar dalam radius 3.5m.",
            cost = 2,
            iconSymbol = "☣️"
        ),

        // === ARCHMAGE ===
        Talent(
            id = "AM_ARCANE_CONDUIT",
            subClass = SubClass.ARCHMAGE,
            tier = 1,
            name = "Arcane Conduit",
            description = "Cooldown semua Skill berkurang 30% dan pengisian energi Ultimate meningkat +40%.",
            cost = 1,
            iconSymbol = "⌛"
        ),
        Talent(
            id = "AM_OVERLOAD_WAVE",
            subClass = SubClass.ARCHMAGE,
            tier = 2,
            name = "Overload Wave",
            description = "Radius ledakan Ultimate bertambah +50% dan membekukan semua musuh selama 1.8 detik.",
            cost = 1,
            iconSymbol = "🌊"
        ),
        Talent(
            id = "AM_MANA_SHIELD",
            subClass = SubClass.ARCHMAGE,
            tier = 3,
            name = "Mana Shield",
            description = "Menyerap 35% damage yang diterima dengan mengonsumsi energi Ultimate sebagai pengganti HP.",
            cost = 2,
            iconSymbol = "🔮"
        ),

        // === SPELLBLADE ===
        Talent(
            id = "SB_ELEMENTAL_INFUSION",
            subClass = SubClass.SPELLBLADE,
            tier = 1,
            name = "Elemental Infusion",
            description = "Setiap serangan melee memicu ledakan percikan energi petir ekstra (bonus +25% Magic Damage).",
            cost = 1,
            iconSymbol = "⚡"
        ),
        Talent(
            id = "SB_FLAME_CLEAVE",
            subClass = SubClass.SPELLBLADE,
            tier = 2,
            name = "Flame Cleave",
            description = "Serangan ke-3 kombo membakar area depan dan menghasilkan gelombang api sejauh 4 meter.",
            cost = 1,
            iconSymbol = "🔥"
        ),
        Talent(
            id = "SB_ARCANE_EXECUTE",
            subClass = SubClass.SPELLBLADE,
            tier = 3,
            name = "Arcane Execute",
            description = "Musuh non-bos yang memiliki HP di bawah 20% langsung dieksekusi instan saat terkena tebasan.",
            cost = 2,
            iconSymbol = "⚔️"
        )
    )

    fun getTalentsFor(subClass: SubClass): List<Talent> {
        return allTalents.filter { it.subClass == subClass }
    }

    fun getTalentsForSubClass(subClass: SubClass): List<Talent> = getTalentsFor(subClass)

    fun findById(id: String): Talent? {
        return allTalents.firstOrNull { it.id == id }
    }
}
