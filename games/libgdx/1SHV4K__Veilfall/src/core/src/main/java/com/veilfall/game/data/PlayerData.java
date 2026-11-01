package com.veilfall.game.data;

public final class PlayerData {
    private final int id;
    private final String name;
    private final int level;
    private final int experience;
    private final int wins;
    private final int losses;
    private final int battles;
    private final int enemiesDefeated;
    private final int bossesDefeated;
    private final int bestWave;

    public PlayerData(int id, String name, int level, int experience, int wins, int losses, int battles,
                      int enemiesDefeated, int bossesDefeated, int bestWave) {
        this.id = id;
        this.name = name;
        this.level = level;
        this.experience = experience;
        this.wins = wins;
        this.losses = losses;
        this.battles = battles;
        this.enemiesDefeated = enemiesDefeated;
        this.bossesDefeated = bossesDefeated;
        this.bestWave = bestWave;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public int getLevel() { return level; }
    public int getExperience() { return experience; }
    public int getWins() { return wins; }
    public int getLosses() { return losses; }
    public int getBattles() { return battles; }
    public int getEnemiesDefeated() { return enemiesDefeated; }
    public int getBossesDefeated() { return bossesDefeated; }
    public int getBestWave() { return bestWave; }
}
