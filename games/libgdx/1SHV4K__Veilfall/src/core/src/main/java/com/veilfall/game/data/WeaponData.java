package com.veilfall.game.data;

public final class WeaponData {
    private final int id;
    private final String name;
    private final int characterId;
    private final int damage;
    private final double attackSpeed;
    private final double range;

    public WeaponData(int id, String name, int characterId, int damage, double attackSpeed, double range) {
        this.id = id;
        this.name = name;
        this.characterId = characterId;
        this.damage = damage;
        this.attackSpeed = attackSpeed;
        this.range = range;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public int getCharacterId() { return characterId; }
    public int getDamage() { return damage; }
    public double getAttackSpeed() { return attackSpeed; }
    public double getRange() { return range; }
}
