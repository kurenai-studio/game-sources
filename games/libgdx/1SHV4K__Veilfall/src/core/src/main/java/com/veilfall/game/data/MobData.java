package com.veilfall.game.data;

public final class MobData {
    private final int id;
    private final String name;
    private final String type;
    private final int hp;
    private final int damage;
    private final double speed;
    private final double range;
    private final boolean boss;

    public MobData(int id, String name, String type, int hp, int damage, double speed, double range, boolean boss) {
        this.id = id;
        this.name = name;
        this.type = type;
        this.hp = hp;
        this.damage = damage;
        this.speed = speed;
        this.range = range;
        this.boss = boss;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public String getType() { return type; }
    public int getHp() { return hp; }
    public int getDamage() { return damage; }
    public double getSpeed() { return speed; }
    public double getRange() { return range; }
    public boolean isBoss() { return boss; }
}
