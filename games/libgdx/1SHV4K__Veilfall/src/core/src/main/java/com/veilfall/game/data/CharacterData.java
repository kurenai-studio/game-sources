package com.veilfall.game.data;

public final class CharacterData {
    private final int id;
    private final String name;
    private final int hp;
    private final int attack;
    private final double speed;
    private final int defense;
    private final double range;

    public CharacterData(int id, String name, int hp, int attack, double speed, int defense, double range) {
        this.id = id;
        this.name = name;
        this.hp = hp;
        this.attack = attack;
        this.speed = speed;
        this.defense = defense;
        this.range = range;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public int getHp() { return hp; }
    public int getAttack() { return attack; }
    public double getSpeed() { return speed; }
    public int getDefense() { return defense; }
    public double getRange() { return range; }
}
