package com.micro1.shadowclash;

/**
 * Every animation-driven state a fighter can be in. Each value carries the sprite-sheet
 * animation key it renders with (see regions_*.json) and whether that clip loops. The state
 * machine lives in {@link Fighter}; this enum is the bridge between logic and animation so a
 * state change is always an animation change (rubric: animation-driven transitions).
 */
public enum FighterState {
    // movement (looping / arc)
    IDLE("idle", true),
    WALK("walk", true),
    RUN("run", true),
    JUMP("jump", false),
    CROUCH("crouch", true),
    BACKDASH("backdash", false),

    // light attacks (1 dmg)
    JAB("jab", false),
    CROUCHJAB("crouchjab", false),
    STANDKICK("standkick", false),

    // heavy attacks (3 dmg)
    STRONGPUNCH("strongpunch", false),
    SWEEP("sweep", false),
    UPPERCUT("uppercut", false),

    // special moves (5 dmg, unlocked below 75 health)
    SHADOWBLAST("shadowblast", false),
    DARKCHARGE("darkcharge", false),
    SPINSLASH("spinslash", false),

    // defense
    BLOCK_STAND("standblock", false),
    BLOCK_CROUCH("crouchblock", false),

    // hit reactions
    HIT_LIGHT("lighthit", false),
    HIT_HEAVY("heavyhit", false),
    KNOCKDOWN("heavyhit", false),
    LAUNCH("launch", false),

    // outcomes
    VICTORY("victory", false),
    DEFEAT("defeat", false);

    public final String animKey;
    public final boolean loop;

    FighterState(String animKey, boolean loop) {
        this.animKey = animKey;
        this.loop = loop;
    }

    public boolean isAttack() {
        return this == JAB || this == CROUCHJAB || this == STANDKICK
            || this == STRONGPUNCH || this == SWEEP || this == UPPERCUT
            || this == SHADOWBLAST || this == DARKCHARGE || this == SPINSLASH;
    }

    public boolean isHitReaction() {
        return this == HIT_LIGHT || this == HIT_HEAVY || this == KNOCKDOWN || this == LAUNCH;
    }

    public boolean isBlock() {
        return this == BLOCK_STAND || this == BLOCK_CROUCH;
    }

    /** States that can blend into one another without obscuring a combat action. */
    public boolean isMovement() {
        return this == IDLE || this == WALK || this == RUN || this == JUMP
            || this == CROUCH || this == BACKDASH;
    }
}
