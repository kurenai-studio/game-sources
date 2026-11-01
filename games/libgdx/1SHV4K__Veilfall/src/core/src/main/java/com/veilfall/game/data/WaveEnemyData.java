package com.veilfall.game.data;

public final class WaveEnemyData {
    private final int waveId;
    private final int mobId;
    private final String mobName;
    private final int quantity;

    public WaveEnemyData(int waveId, int mobId, String mobName, int quantity) {
        this.waveId = waveId;
        this.mobId = mobId;
        this.mobName = mobName;
        this.quantity = quantity;
    }

    public int getWaveId() { return waveId; }
    public int getMobId() { return mobId; }
    public String getMobName() { return mobName; }
    public int getQuantity() { return quantity; }
}
