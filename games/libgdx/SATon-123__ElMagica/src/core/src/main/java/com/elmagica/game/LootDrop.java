package com.elmagica.game;

import com.badlogic.gdx.math.Vector2;

public class LootDrop {
    public enum Type { BOOK, POTION, COIN }
    public final Type type;
    public float x, y;
    private float age;
    private float flightTime;
    public float getScale() { return 1 + Math.min(0.35f, flightTime * 1.2f); }
    public void flyTo(Player player, float delta) {
        if (!player.isAlive() || delta <= 0) return;
        flightTime += delta;
        float dx = player.x + 30 - x, dy = player.y + 30 - y;
        float distance = Vector2.len(dx, dy);
        if (distance == 0) return;
        // Лут летит напрямую, укрытия ему не мешают.
        float step = Math.min(distance, (800 + Math.min(1000, flightTime * 1400)) * delta);
        x += dx / distance * step; y += dy / distance * step;
    }
    public final int amount;
    public LootDrop(Type type, float x, float y) { this(type, x, y, 1); }
    public LootDrop(Type type, float x, float y, int amount) { this.type = type; this.x = x; this.y = y; this.amount = amount; }
    public void update(float delta) { age += delta; }
    public float getAge() { return age; }
    public boolean canPickUp(Player player) {
        return player.isAlive() && age >= 0.15f && Vector2.dst(x, y, player.x + 30, player.y + 30) <= 44;
    }
}
