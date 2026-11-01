package dev.luchoc.littlespaceship.core.domain.system;

/**
 * The order in which the systems run, declared once and in one place.
 *
 * <p>This is a game rule, not an implementation detail. Collision before damage is what makes the
 * defensive priority resolvable in a single place; cleanup last is what lets a system mark an
 * entity for destruction without anything reading a half-destroyed world afterwards. Reordering
 * these constants changes how the game behaves.
 *
 * <p>The pipeline runs the stages in declaration order and every system says which stage it belongs
 * to, so the order cannot be changed by accident when registering one. Stages with no system yet
 * are simply skipped: they arrive with the phase that implements them.
 */
public enum SystemOrder {

    /** Translates the input frame into the player's intent. */
    INPUT,

    /** Applies velocities and trajectories. */
    MOTION,

    /** Resolves rates of fire and creates projectiles. */
    WEAPON,

    /**
     * Detonates the bomb when requested: clears on-screen fragile enemies and enemy projectiles,
     * damages on-screen resistant ones. Runs before {@code SPAWN} so a bomb used the instant a wave
     * would appear never reaches a wave that has not spawned yet, and — this is the part that
     * matters for correctness, not just tidiness — before {@code COLLISION}. {@code BombSystem} only
     * marks entities for destruction; it does not remove their collider. Running before {@code
     * COLLISION} is what lets {@code CollisionSystem}'s own rule (skip anything already marked for
     * destruction this tick, stated on its class) turn that marking into actual protection: an enemy
     * or an enemy projectile the bomb just cleared never produces a {@code CollisionHit} against the
     * player in the same tick, so {@code DamageSystem} never consumes a layer or a life for it. Move
     * {@code BOMB} to run after {@code COLLISION} and this protection is lost regardless of what
     * {@code CollisionSystem} does — the hits would already be in the list.
     */
    BOMB,

    /**
     * Advances the level's ordered wave placements and spawns what is due.
     *
     * <p><b>{@code SPAWN} stays fifth in this enum</b> — rejected as a candidate to move, with
     * reasons, in {@code docs/plan/10c-architecture-review/decision.md}. One consequence of keeping
     * it here, decided alongside that rejection: a {@link
     * dev.luchoc.littlespaceship.core.port.WaveEndCondition.Cleared} wave resolves one tick late,
     * deterministically. {@code CLEANUP} — the stage that actually removes a destroyed or escaped
     * entity — runs after this stage in the very same tick, so an entity that stops existing this
     * tick is still present, as far as {@code SpawnSystem} can see, when this stage runs. A wave
     * whose last entity is destroyed this tick is only detected as cleared on the <em>next</em> tick,
     * once {@code CLEANUP} has actually removed it. This is not a bug to fix by moving either stage —
     * both are exactly where the rest of the pipeline needs them — it is the one-tick lag every
     * fixed-step system already has for anything it can only observe rather than react to instantly,
     * and it is exactly as reproducible as every other tick-quantised decision in this pipeline.
     */
    SPAWN,

    /**
     * Ticks down every entity's {@code Spawner} — the heavy carrier's periodic basic-enemy spawn —
     * and creates a child the instant one is due. Added in phase 07, after {@code SPAWN} and before
     * {@code BOSS}: a carrier spawned by {@code SPAWN} this very tick already exists by the time this
     * stage runs, so a carrier placed at the very start of a level can begin spawning children from
     * its very first eligible tick, the same way a boss spawned this tick is already positioned by
     * the time {@code BOSS} runs right after.
     *
     * <p>A spawn inside a spawn is exactly the kind of nested, same-tick ordering phase 02's own
     * review found a real instance of (finding F4, {@code docs/plan/02-core-mechanics/status.md}: a
     * system reading a buffer from a stage that runs before the stage refilling it resolves stale,
     * previous-tick data instead of the current tick's). This stage avoids the same class of mistake
     * two ways. First, it never mutates the very store it iterates — a spawned child never itself
     * carries a fresh {@code Spawner}, so {@code World#spawners()}'s dense array is never reordered
     * mid-loop, the hazard {@code ComponentStore}'s own documentation warns about. Second, iteration
     * is a plain index walk over that dense array — never a {@code HashMap} or a {@code Set} — so
     * which carrier's child is created first, when several are due the same tick, is exactly the
     * carriers' own creation order and nothing else, which is what keeps a replay reproducible.
     */
    SPAWNER,

    /**
     * Resolves every enemy's {@code EnemyWeapon} cooldown and creates its projectile once it reaches
     * zero. Added to close the gap {@code 08-decisions-and-open-items.md} records: no enemy fired at
     * all before this — {@code enemy-shooter} read as a bigger, slower basic. Placed after {@code
     * SPAWNER} and before {@code BOSS}, both for the same reason those two are already here: an enemy
     * spawned this very tick, whether by {@code SPAWN} or by a carrier's {@code SPAWNER}, already
     * exists by the time this stage runs, and this stage in turn runs before {@code COLLISION} and
     * {@code LIFETIME} so a shot fired this tick is detected by the very same tick's collision pass,
     * exactly like a player projectile created at {@code WEAPON} already is. Distinct from {@code
     * BOSS}, which fires the boss's own projectiles directly and does not go through the generic,
     * data-driven {@code EnemyWeapon} component at all — the boss's pattern is a fixed state machine
     * with no equivalent in {@code enemies.json}, not an archetype component.
     */
    ENEMY_WEAPON,

    /**
     * Advances the boss encounter: entrance, the pattern state machine and its fire. Added in phase
     * 07, after {@code SPAWN} and before {@code LIFETIME} — the boss is a second, independent
     * timeline running alongside the wave one, not a wave itself, so it does not share {@code
     * SPAWN}'s stage. Placed here rather than folded into {@code SPAWN} because a wave's timeline is
     * "spawn and forget" while the boss keeps state — entrance progress, which pattern is charging —
     * across many ticks, closer in shape to {@code WEAPON} than to a one-shot spawn. Running before
     * {@code LIFETIME} and {@code COLLISION} is what lets a boss projectile fired this tick be
     * detected by the very same tick's collision pass the moment it exists, exactly like a player
     * projectile created at {@code WEAPON} already is.
     */
    BOSS,

    /** Expires projectiles and effects. */
    LIFETIME,

    /**
     * Detects impacts between layer pairs. Also the one place that enforces: an entity already
     * marked for destruction this tick — by {@code BombSystem}, by {@code LifetimeSystem}, by
     * anything that runs earlier in the pipeline and calls {@code World.markForDestruction} — never
     * produces a {@code CollisionHit}, regardless of what marked it. Marking alone leaves the
     * collider in place, so without this rule an entity destroyed earlier in the same tick could
     * still register a hit against the player before {@code CleanupSystem} ever runs.
     */
    COLLISION,

    /**
     * Applies the defensive priority against the player — invulnerability, shield, attachment,
     * life — and resolves what a player projectile did to the enemy it reached. Both are damage
     * resolution against a collision hit reported the same tick, which is why one system owns both
     * instead of splitting the second half into a stage of its own.
     */
    DAMAGE,

    /** Resolves power-ups and attachments. */
    PICKUP,

    /** Accumulates score. */
    SCORE,

    /** Destroys what was marked and frees identifiers. */
    CLEANUP
}
