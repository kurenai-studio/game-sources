package com.veilfall.game.screens;

public record BattleOutcome(
        boolean victory,
        String characterName,
        String arenaName,
        int wavesCompleted,
        int enemiesDefeated,
        int bossesDefeated,
        float durationSeconds,
        int arenaId,
        int characterId,
        int weaponId,
        String weaponName,
        int experienceEarned,
        int totalExperience,
        int playerLevel,
        int bestWave) {
}
