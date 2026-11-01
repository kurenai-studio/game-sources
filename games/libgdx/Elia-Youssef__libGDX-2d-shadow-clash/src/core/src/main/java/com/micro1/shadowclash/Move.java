package com.micro1.shadowclash;

/**
 * Immutable definition of an attack: its animation state, damage, frame timing, how it can be
 * blocked, the reaction it causes, and its active-frame hitbox geometry (in fighter-local space,
 * mirrored by facing at resolve time). The nine canonical moves are static instances; the
 * simulation never allocates a Move at runtime.
 *
 * Damage tiers (rubric): light = 1, heavy = 3, special = 5. Light moves use shorter startup and
 * recovery than heavy moves. Block coverage (rubric): a standing block stops HIGH/MID (jab,
 * standing kick, strong punch, Shadow Blast, Dark Charge); a crouching block stops LOW (crouching
 * jab, sweep). Rising uppercut and Spinning Slash are UNBLOCKABLE (not in either block list).
 */
public final class Move {

    public enum Kind { LIGHT, HEAVY, SPECIAL }
    public enum Height { HIGH, MID, LOW, UNBLOCKABLE }
    public enum Reaction { LIGHT, HEAVY, KNOCKDOWN, LAUNCH }

    public final String name;
    public final FighterState state;
    public final Kind kind;
    public final int damage;
    public final float startup, active, recovery; // seconds
    public final Height height;
    public final Reaction reaction;
    public final float knockback;   // horizontal push applied to the victim (px/s)
    public final float reach;       // hitbox far edge, measured forward from body centre (px)
    public final float hitLo, hitHi; // hitbox vertical band above the feet (px)
    public final float forwardSpeed; // self-advance during active frames (px/s); rushing specials
    public final boolean projectile; // spawns a Projectile instead of a melee hitbox

    private Move(String name, FighterState state, Kind kind, int damage,
                 float startup, float active, float recovery, Height height, Reaction reaction,
                 float knockback, float reach, float hitLo, float hitHi,
                 float forwardSpeed, boolean projectile) {
        this.name = name; this.state = state; this.kind = kind; this.damage = damage;
        this.startup = startup; this.active = active; this.recovery = recovery;
        this.height = height; this.reaction = reaction; this.knockback = knockback;
        this.reach = reach; this.hitLo = hitLo; this.hitHi = hitHi;
        this.forwardSpeed = forwardSpeed; this.projectile = projectile;
    }

    public float total() { return startup + active + recovery; }
    public boolean isSpecial() { return kind == Kind.SPECIAL; }

    /** True if a block of the given stance stops this move. */
    public boolean blockedBy(boolean standing, boolean crouching) {
        if (height == Height.UNBLOCKABLE) return false;
        if (height == Height.LOW) return crouching;
        return standing; // HIGH or MID
    }

    // --- light attacks: 1 damage, fast startup + recovery ---
    public static final Move JAB = new Move("Jab", FighterState.JAB, Kind.LIGHT, 1,
        0.05f, 0.06f, 0.13f, Height.MID, Reaction.LIGHT, 120f, 96f, 96f, 190f, 0f, false);
    public static final Move CROUCHJAB = new Move("Crouching Jab", FighterState.CROUCHJAB, Kind.LIGHT, 1,
        0.05f, 0.06f, 0.13f, Height.LOW, Reaction.LIGHT, 110f, 92f, 20f, 90f, 0f, false);
    public static final Move STANDKICK = new Move("Standing Kick", FighterState.STANDKICK, Kind.LIGHT, 1,
        0.07f, 0.07f, 0.15f, Height.MID, Reaction.LIGHT, 140f, 112f, 80f, 175f, 0f, false);

    // --- heavy attacks: 3 damage, slower startup + recovery ---
    public static final Move STRONGPUNCH = new Move("Strong Punch", FighterState.STRONGPUNCH, Kind.HEAVY, 3,
        0.14f, 0.09f, 0.30f, Height.MID, Reaction.HEAVY, 300f, 116f, 95f, 195f, 0f, false);
    public static final Move SWEEP = new Move("Sweep Kick", FighterState.SWEEP, Kind.HEAVY, 3,
        0.15f, 0.10f, 0.32f, Height.LOW, Reaction.KNOCKDOWN, 220f, 126f, 8f, 78f, 0f, false);
    public static final Move UPPERCUT = new Move("Rising Uppercut", FighterState.UPPERCUT, Kind.HEAVY, 3,
        0.13f, 0.10f, 0.34f, Height.UNBLOCKABLE, Reaction.LAUNCH, 120f, 82f, 60f, 250f, 0f, false);

    // --- special moves: 5 damage, unlocked below 75 health, trigger slow motion ---
    public static final Move SHADOWBLAST = new Move("Shadow Blast", FighterState.SHADOWBLAST, Kind.SPECIAL, 5,
        0.20f, 0.14f, 0.34f, Height.MID, Reaction.HEAVY, 260f, 0f, 0f, 0f, 0f, true);
    public static final Move DARKCHARGE = new Move("Dark Charge", FighterState.DARKCHARGE, Kind.SPECIAL, 5,
        0.18f, 0.16f, 0.34f, Height.MID, Reaction.HEAVY, 320f, 118f, 40f, 200f, 460f, false);
    public static final Move SPINSLASH = new Move("Spinning Slash", FighterState.SPINSLASH, Kind.SPECIAL, 5,
        0.16f, 0.20f, 0.32f, Height.UNBLOCKABLE, Reaction.HEAVY, 240f, 110f, 30f, 210f, 300f, false);

    public static final Move[] ALL = {
        JAB, CROUCHJAB, STANDKICK, STRONGPUNCH, SWEEP, UPPERCUT, SHADOWBLAST, DARKCHARGE, SPINSLASH
    };
}
