package com.veilfall.game.data;

public final class SkillData {
    private final int id;
    private final int characterId;
    private final String name;
    private final String keyBinding;
    private final int damage;
    private final double cooldown;

    public SkillData(int id, int characterId, String name, String keyBinding, int damage, double cooldown) {
        this.id = id;
        this.characterId = characterId;
        this.name = name;
        this.keyBinding = keyBinding;
        this.damage = damage;
        this.cooldown = cooldown;
    }

    public int getId() { return id; }
    public int getCharacterId() { return characterId; }
    public String getName() { return name; }
    public String getKeyBinding() { return keyBinding; }
    public int getDamage() { return damage; }
    public double getCooldown() { return cooldown; }
}
