package com.micro1.monstercafe;

/**
 * The three monster customers. Each maps to its supplied asset path (used exactly as provided, never
 * renamed). {@code values()} drives the uniform random monster selection; the same monster may recur.
 */
public enum MonsterType {
    GREEN("characters/monster_green.png"),
    BLUE("characters/monster_blue.png"),
    RED("characters/monster_red.png");

    public final String assetPath;

    MonsterType(String assetPath) {
        this.assetPath = assetPath;
    }
}
