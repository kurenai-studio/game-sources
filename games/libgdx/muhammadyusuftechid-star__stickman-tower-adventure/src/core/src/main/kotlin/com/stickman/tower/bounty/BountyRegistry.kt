package com.stickman.tower.bounty

/**
 * Registri resmi daftar kontrak monster buronan elit (The Spire Bounty Board).
 */
object BountyRegistry {

    val BOUNTY_BERSERKER = BountyContract(
        id = "BOUNTY_BERSERKER",
        targetName = "The Sanguine Berserker",
        targetTitle = "Pemabuk Getah Beracun Oakhaven",
        targetFloor = 2,
        affixes = listOf(BountyAffix.THORNS),
        synopsis = "Mantan penjaga hutan yang terasimilasi kristal getah ungu. Tubuhnya tertutup duri obsidian yang membalikkan tebasan senjata.",
        rewardGold = 300,
        rewardExp = 500,
        bonusRewardDesc = "Kristal Getah Oakhaven (+10% Durasi Parry)"
    )

    val BOUNTY_VOID_WEAVER = BountyContract(
        id = "BOUNTY_VOID_WEAVER",
        targetName = "Amethyst Void-Weaver",
        targetTitle = "Penenun Kegelapan Ratu Laba-laba",
        targetFloor = 4,
        affixes = listOf(BountyAffix.VAMPIRIC),
        synopsis = "Arachnid purba penjaga sarang ungu. Menghisap sari kehidupan dari setiap tetes darah yang tercurah di lantai berongga.",
        rewardGold = 500,
        rewardExp = 800,
        bonusRewardDesc = "Sutra Ungu Bayangan (+15% Critical Chance)"
    )

    val BOUNTY_DREADNOUGHT = BountyContract(
        id = "BOUNTY_DREADNOUGHT",
        targetName = "Obsidian Dreadnought",
        targetTitle = "Mesin Penghancur Suaka Vulcanus",
        targetFloor = 7,
        affixes = listOf(BountyAffix.HASTE),
        synopsis = "Golem lapis baja yang digerakkan turbin uap panas berlebih. Menyerang dan bergerak dengan kecepatan kilat yang meremukkan benteng.",
        rewardGold = 800,
        rewardExp = 1200,
        bonusRewardDesc = "Inti Tungku Vulcanus (+20 Flat ATK Power)"
    )

    private val allBounties = listOf(
        BOUNTY_BERSERKER,
        BOUNTY_VOID_WEAVER,
        BOUNTY_DREADNOUGHT
    )

    fun getAll(): List<BountyContract> = allBounties

    fun getById(id: String): BountyContract? {
        return allBounties.find { it.id.equals(id, ignoreCase = true) }
    }

    fun getForFloor(floor: Int): BountyContract? {
        return allBounties.find { it.targetFloor == floor }
    }
}
