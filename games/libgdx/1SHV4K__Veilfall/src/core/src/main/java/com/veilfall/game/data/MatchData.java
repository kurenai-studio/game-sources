package com.veilfall.game.data;

public final class MatchData {
    private final int id;
    private final String result;
    private final int arenaId;
    private final int characterId;
    private final int wavesReached;
    private final int enemiesDefeated;
    private final int bossesDefeated;
    private final double durationSeconds;
    private final String playedAt;
    private final int weaponId;
    private final String arenaName;
    private final String characterName;
    private final String weaponName;

    public MatchData(int id, String result, int arenaId, int characterId, int wavesReached,
                     int enemiesDefeated, int bossesDefeated, double durationSeconds, String playedAt) {
        this.id = id;
        this.result = result;
        this.arenaId = arenaId;
        this.characterId = characterId;
        this.wavesReached = wavesReached;
        this.enemiesDefeated = enemiesDefeated;
        this.bossesDefeated = bossesDefeated;
        this.durationSeconds = durationSeconds;
        this.playedAt = playedAt;
        this.weaponId = 0;
        this.arenaName = "";
        this.characterName = "";
        this.weaponName = "";
    }

    public MatchData(int id, String result, int arenaId, int characterId, int weaponId, int wavesReached,
                     int enemiesDefeated, int bossesDefeated, double durationSeconds, String playedAt,
                     String arenaName, String characterName, String weaponName) {
        this.id = id;
        this.result = result;
        this.arenaId = arenaId;
        this.characterId = characterId;
        this.weaponId = weaponId;
        this.wavesReached = wavesReached;
        this.enemiesDefeated = enemiesDefeated;
        this.bossesDefeated = bossesDefeated;
        this.durationSeconds = durationSeconds;
        this.playedAt = playedAt;
        this.arenaName = arenaName;
        this.characterName = characterName;
        this.weaponName = weaponName;
    }

    public int getId() { return id; }
    public String getResult() { return result; }
    public int getArenaId() { return arenaId; }
    public int getCharacterId() { return characterId; }
    public int getWavesReached() { return wavesReached; }
    public int getEnemiesDefeated() { return enemiesDefeated; }
    public int getBossesDefeated() { return bossesDefeated; }
    public double getDurationSeconds() { return durationSeconds; }
    public String getPlayedAt() { return playedAt; }
    public int getWeaponId() { return weaponId; }
    public String getArenaName() { return arenaName; }
    public String getCharacterName() { return characterName; }
    public String getWeaponName() { return weaponName; }
}
