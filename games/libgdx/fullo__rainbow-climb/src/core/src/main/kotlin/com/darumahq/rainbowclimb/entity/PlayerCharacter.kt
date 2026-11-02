package com.darumahq.rainbowclimb.entity

/**
 * Unlockable player characters.
 * Each character requires a total gem count across all games.
 */
enum class PlayerCharacter(
    val displayName: String,
    val spritePath: String,
    val gemsRequired: Int
) {
    PINK_MAN("Pink Man", "sprites/player", 0),
    NINJA_FROG("Ninja Frog", "sprites/player_alt/ninja_frog", 1000),
    MASK_DUDE("Mask Dude", "sprites/player_alt/mask_dude", 2500),
    VIRTUAL_GUY("Virtual Guy", "sprites/player_alt/virtual_guy", 5000);

    fun isUnlocked(totalGems: Int): Boolean = totalGems >= gemsRequired

    companion object {
        fun unlockedCharacters(totalGems: Int): List<PlayerCharacter> =
            entries.filter { it.isUnlocked(totalGems) }
    }
}
