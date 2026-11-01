package com.veilfall.game.data;

public final class ArenaData {
    private final int id;
    private final String name;
    private final String description;
    private final int difficulty;
    private final String environment;
    private final int bossMobId;

    public ArenaData(int id, String name, String description, int difficulty, String environment, int bossMobId) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.difficulty = difficulty;
        this.environment = environment;
        this.bossMobId = bossMobId;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public int getDifficulty() { return difficulty; }
    public String getEnvironment() { return environment; }
    public int getBossMobId() { return bossMobId; }
}
