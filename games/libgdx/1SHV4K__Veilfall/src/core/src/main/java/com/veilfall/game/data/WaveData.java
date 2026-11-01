package com.veilfall.game.data;

public final class WaveData {
    private final int id;
    private final int arenaId;
    private final int waveNumber;
    private final double healthMultiplier;
    private final double damageMultiplier;
    private final boolean bossWave;

    public WaveData(int id, int arenaId, int waveNumber, double healthMultiplier,
                    double damageMultiplier, boolean bossWave) {
        this.id = id;
        this.arenaId = arenaId;
        this.waveNumber = waveNumber;
        this.healthMultiplier = healthMultiplier;
        this.damageMultiplier = damageMultiplier;
        this.bossWave = bossWave;
    }

    public int getId() { return id; }
    public int getArenaId() { return arenaId; }
    public int getWaveNumber() { return waveNumber; }
    public double getHealthMultiplier() { return healthMultiplier; }
    public double getDamageMultiplier() { return damageMultiplier; }
    public boolean isBossWave() { return bossWave; }
}
