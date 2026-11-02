package com.darumahq.rainbowclimb.entity

import com.badlogic.gdx.Gdx

/**
 * Achievement system with persistent unlock tracking.
 */
enum class Achievement(
    val displayName: String,
    val description: String
) {
    FIRST_RAINBOW("Rainbow Starter", "Shoot your first rainbow"),
    SCORE_1000("Getting There", "Reach 1000 score"),
    SCORE_5000("Climber", "Reach 5000 score"),
    SCORE_10000("Sky High", "Reach 10000 score"),
    KILL_10("Pest Control", "Defeat 10 enemies"),
    KILL_50("Exterminator", "Defeat 50 enemies"),
    COMBO_X3("Triple Threat", "Reach x3 combo"),
    COMBO_X4("Unstoppable", "Reach x4 combo"),
    BOSS_DEFEAT("King Slayer", "Defeat your first boss"),
    SURVIVE_3MIN("Endurance", "Survive 3 minutes"),
    COLLECT_100_GEMS("Gem Hoarder", "Collect 100 gems in one run"),
    LEVEL_10("Explorer", "Reach level 10"),
    LEVEL_25("Veteran", "Reach level 25"),
    ALL_CHARACTERS("Completionist", "Unlock all characters");

    companion object {
        private const val PREFS_KEY = "achievements"

        fun isUnlocked(achievement: Achievement): Boolean {
            val prefs = Gdx.app.getPreferences("rainbow-climb")
            return prefs.getBoolean("$PREFS_KEY.${achievement.name}", false)
        }

        fun unlock(achievement: Achievement): Boolean {
            if (isUnlocked(achievement)) return false
            val prefs = Gdx.app.getPreferences("rainbow-climb")
            prefs.putBoolean("$PREFS_KEY.${achievement.name}", true)
            prefs.flush()
            return true // newly unlocked
        }

        fun unlockedCount(): Int = entries.count { isUnlocked(it) }
        fun totalCount(): Int = entries.size
    }
}
