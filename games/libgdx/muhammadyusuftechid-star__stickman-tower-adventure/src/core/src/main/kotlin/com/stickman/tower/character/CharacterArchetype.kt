package com.stickman.tower.character

/**
 * Arketipe Karakter Stickman sesuai GDD v0.1:
 * - BALANCED: Gaya seimbang (pedang tunggal).
 * - AGILE: Gaya bertempo cepat (pisau ganda, lari kencang, crit tinggi).
 * - HEAVY: Gaya bertempo berat (pedang raksasa masif, defense tinggi, knockback kuat).
 */
enum class CharacterArchetype(
    val displayName: String,
    val title: String,
    val characterName: String,
    val canonTitle: String,
    val weaponName: String,
    val description: String,
    val moveSpeed: Float,
    val jumpVelocity: Float,
    val baseDamageMultiplier: Float,
    val baseDefenseBonus: Float,
    val baseCritBonus: Float,
    val skill1Name: String,
    val skill1Cooldown: Float,
    val skill1Desc: String,
    val skill2Name: String,
    val skill2Cooldown: Float,
    val skill2Desc: String,
    val skill3Name: String,
    val skill3Cooldown: Float,
    val skill3Desc: String,
    val ultName: String,
    val ultDesc: String,
    val ultEnergyCost: Float = 100f
) {
    BALANCED(
        displayName = "Balanced Blade",
        title = "The Wandering Swordsman",
        characterName = "Kaelen The Bladeweaver",
        canonTitle = "Pendekar Pedang Badai (Aliran Zephyr)",
        weaponName = "Runed Broadsword",
        description = "Gaya seimbang dengan mobilitas stabil dan kombo pedang 3-hit yang luwes.",
        moveSpeed = 7.5f,
        jumpVelocity = 11.5f,
        baseDamageMultiplier = 1.0f,
        baseDefenseBonus = 0f,
        baseCritBonus = 0f,
        skill1Name = "Gale Crescent",
        skill1Cooldown = 3.5f,
        skill1Desc = "Menebaskan sabit angin jarak menengah (6m)",
        skill2Name = "Rising Dragon",
        skill2Cooldown = 4.8f,
        skill2Desc = "Tebasan melompat ke atas mengangkat musuh ke udara",
        skill3Name = "Dash Strike",
        skill3Cooldown = 4.2f,
        skill3Desc = "Menerjang cepat menembus pertahanan musuh",
        ultName = "Bladestorm 360°",
        ultDesc = "Badai pusaran 1000 tebasan pedang melumat semua musuh sekitar",
        ultEnergyCost = 100f
    ),
    AGILE(
        displayName = "Shadow Daggers",
        title = "The Silent Assassin",
        characterName = "Zephyr The Shadowstalker",
        canonTitle = "Pembunuh Bayangan (Eclipse Creed)",
        weaponName = "Dual Amethyst Daggers",
        description = "Kecepatan luar biasa dengan serangan cepat bertubi-tubi dan peluang critical tinggi.",
        moveSpeed = 9.5f,
        jumpVelocity = 12.2f,
        baseDamageMultiplier = 0.85f,
        baseDefenseBonus = -1.0f,
        baseCritBonus = 0.15f,
        skill1Name = "Shadow Shuriken",
        skill1Cooldown = 2.8f,
        skill1Desc = "Melemparkan 3 pisau bayangan menusuk berkecepatan tinggi",
        skill2Name = "Venom Flurry",
        skill2Cooldown = 3.8f,
        skill2Desc = "Rentetan tusukan kilat beracun poison DoT",
        skill3Name = "Phantom Blink",
        skill3Cooldown = 4.5f,
        skill3Desc = "Teleportasi instan ke belakang musuh disertai tebasan kritis",
        ultName = "Phantom Flurry",
        ultDesc = "Mencabik-cabik seluruh musuh di layar dengan bayangan gelap",
        ultEnergyCost = 80f
    ),
    HEAVY(
        displayName = "Titan Greatsword",
        title = "The Tower Juggernaut",
        characterName = "Gorgon The Ironbreaker",
        canonTitle = "Sang Penghancur Benteng (Paladin Batu)",
        weaponName = "Colossal Obsidian Greatsword",
        description = "Kekuatan brutal dengan pertahanan tebal dan hantaman pedang raksasa berdaya hancur tinggi.",
        moveSpeed = 5.8f,
        jumpVelocity = 10.8f,
        baseDamageMultiplier = 1.55f,
        baseDefenseBonus = 3.5f,
        baseCritBonus = -0.02f,
        skill1Name = "Earth Shockwave",
        skill1Cooldown = 4.0f,
        skill1Desc = "Menghantam tanah memunculkan pilar batu tajam (5m)",
        skill2Name = "Cyclone Cleave",
        skill2Cooldown = 5.2f,
        skill2Desc = "Mengayunkan pedang raksasa 360° dengan Super Armor",
        skill3Name = "Titan Roar",
        skill3Cooldown = 6.5f,
        skill3Desc = "Raungan radial pentalan musuh, pulihkan 15% HP & buff DEF",
        ultName = "Meteor Cleave",
        ultDesc = "Melompat tinggi lalu menghunjam bumi bagai komet pemecah arena",
        ultEnergyCost = 120f
    );

    val skillName: String get() = skill1Name

    companion object {
        fun fromString(name: String): CharacterArchetype {
            return entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: BALANCED
        }
    }
}
