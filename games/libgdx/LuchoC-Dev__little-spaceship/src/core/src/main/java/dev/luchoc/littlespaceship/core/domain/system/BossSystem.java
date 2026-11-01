package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Health;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.BossDefinition;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;

/**
 * Level 1's climax: a six-part boss with one phase and two alternating, tell-then-fire attack
 * patterns, per the decision recorded in {@code 08-decisions-and-open-items.md} under "Level 1
 * climax and length".
 *
 * <p>Not stateless, the same deliberate exception {@code SpawnSystem} already is: it tracks its own
 * elapsed level time, which part entities it spawned, and the pattern state machine across many
 * ticks. A fresh {@code Simulation} always builds a fresh {@code BossSystem}, so this state is
 * exactly as reproducible as everything else the composition root creates once per run.
 *
 * <p><b>Footprint is an art fact, not content.</b> Six parts, their offsets and their radii are
 * fixed in {@code docs/design/02-sprite-sizes.md}/{@code 06-boss-presentation.md} and hardcoded here
 * as constants — the same treatment {@code Simulation} already gives the player's collider radius —
 * rather than read from {@link BossDefinition}, which carries only what genuinely varies with
 * balancing: hit points, timing and projectile speed.
 *
 * <p><b>The sixth part, {@code core-keel}.</b> The original five colliders left a 25 px gap below the
 * core's own circle — the keel, exactly where a player shooting up into the boss aims first — through
 * which a projectile visibly passed with nothing registering. Found by {@code visual-designer}
 * drawing the parts against {@code 02-sprite-sizes.md}'s map, fixed here per
 * {@code 06-boss-presentation.md}'s proposal: one more entity, radius 13.0 at offset (0, −27), plus
 * moving the arms from offset y −18 to −22. The keel carries its own {@link Health} and {@link
 * ScoreValue} — the core's own numbers, since it reads as part of the core rather than as a
 * fourth kind of part — and no {@link Sprite}: it draws nothing of its own, it only extends where a
 * hit against the core's existing drawn sprite actually registers. It dies with the core exactly like
 * a pod or an arm; its own death, on its own, ends nothing.
 *
 * <p><b>The pattern state machine, and the rear/front split added for issue #329.</b> The pods are the
 * rear weapon and keep exactly what shipped for #325: a cooldown, then a three-beat, 0.75 s tell — the
 * timing fixed in {@code docs/design/06-boss-presentation.md} — then an instantaneous fire, always
 * tied to a standstill. During the tell, the pods' {@link Sprite#frame} steps 1, 2, 3 and drops back to
 * 0 the instant the volley leaves, exactly the class javadoc there describes; that is the whole channel
 * presentation needs to draw the charge, so no separate "which part, how far" contract exists on
 * {@link dev.luchoc.littlespaceship.core.port.BossStatus}. The arms are the front weapon and fire on
 * their own clock — see {@link #updateFrontWeapons} — with no tell of their own: each shot locks the
 * player's position at the instant it fires rather than at the start of a charge, since there is no
 * charge to start one from. At the instant a pod tell begins, {@link #lockAim} freezes the player's
 * current position as that volley's aim point; a front shot computes its own, fresh, aim point the same
 * way, in {@link #computeAimPoint}, at the instant it fires. Every volley, rear or front, fans {@link
 * #FAN_COUNT} projectiles at its own locked point, not at a fixed outward or inward angle: {@link
 * #fireAimedFan} and {@link #FAN_SPREAD_RATIOS} carry the geometry and the reasoning. This is the
 * redesign task 4 of {@code docs/plan/11e-level-one-redesigned/plan.md} asked for, replacing the
 * fixed-angle fan that always missed a player parked at screen centre.
 *
 * <p><b>Defeat.</b> The core is the only part whose death ends the fight: once it is destroyed,
 * whatever keel, pods or arms remain are destroyed with it — a boss does not linger as a headless
 * husk — and {@link World#markBossDefeated()} is called, which is what {@code WorldView.outcome()}
 * requires for {@code LevelOutcome.COMPLETED} on a boss level. The keel, a pod or an arm can die
 * earlier, on its own, without ending anything; a pattern whose charging parts are both already dead
 * simply fires nothing and still completes its cycle, so the fight never stalls waiting on a part
 * that is gone.
 *
 * <p><b>Movement, added for issue #325, now a fixed duration per issue #329.</b> Once settled at
 * {@code combatY} and through every attack cycle after that, the boss travels between the ten vertices
 * of a five-pointed star — {@link #STAR_X}/{@link #STAR_Y} — never more than three perimeter steps per
 * move, per the project owner's design. A move only ever starts at the end of {@link #fireRearVolley},
 * after the rear volley has fully resolved, never mid-tell, so the fan in {@link #fireAimedFan} always
 * aims the rear volley from a standstill exactly as before: see {@link #beginMove} for why the two can
 * never overlap. Every move now takes exactly {@link #MOVE_DURATION}, whatever the distance — inverted
 * from #325's constant speed on the owner's own instruction, because a variable cycle length could not
 * hold the fixed front/rear ratio #329 asks for; see {@link #updateFrontWeapons}. Position is a pure
 * function of elapsed time and the destination draws from the seeded {@link World#rng()}, so a replay
 * reproduces the same sequence of points.
 *
 * <p><b>The front weapons deliberately break the move/attack exclusion, for themselves alone.</b> A
 * rear volley still cannot overlap a move — {@link FightStage#MOVING} is entered from exactly one call
 * site, {@link #fireRearVolley}'s caller, exactly as #325 built it. The front clock is not driven
 * through {@link FightStage} at all: {@link #updateFrontWeapons} runs every tick of {@code FIGHT}
 * regardless of {@link #fightStage}, called once per tick from {@link #updateFight} after the stage
 * switch, so a front shot fires whether the boss is cooling down, telling or travelling. Nothing else
 * reads or writes {@link #fightStage} from that method, so no second door into {@code MOVING} exists.
 *
 * <p><b>Damage and score need nothing new.</b> Every part is an ordinary {@code ENEMY}-layer,
 * non-fragile {@link Collider} carrying {@link Health} and {@link ScoreValue}, so {@code
 * DamageSystem}, {@code BombSystem} and {@code ScoreSystem} already resolve a hit against it, a bomb
 * detonation, and the points it awards with no boss-specific code at all — {@code core-keel} included,
 * even though it draws nothing: nothing downstream of {@code Collider}/{@code Health}/{@code
 * ScoreValue} needs a {@link Sprite} to exist.
 */
public final class BossSystem implements GameSystem {

    // Footprint, from docs/design/02-sprite-sizes.md and 06-boss-presentation.md — synchronisation
    // point, not balance.
    private static final float CORE_RADIUS = 18.0f;
    private static final float POD_RADIUS = 12.0f;
    private static final float ARM_RADIUS = 14.0f;

    /** Closes the keel gap under the core; see the class javadoc. No {@code Sprite} of its own. */
    private static final float CORE_KEEL_RADIUS = 13.0f;

    private static final float POD_OFFSET_X = 34f;
    private static final float POD_OFFSET_Y = 6f;
    private static final float ARM_OFFSET_X = 44f;

    /** Moved from −18 to −22 alongside adding {@code core-keel}; see the class javadoc. */
    private static final float ARM_OFFSET_Y = -22f;

    private static final float CORE_KEEL_OFFSET_X = 0f;
    private static final float CORE_KEEL_OFFSET_Y = -27f;

    private static final SpriteId CORE_SPRITE = new SpriteId("boss-core");
    private static final SpriteId POD_SPRITE = new SpriteId("boss-pod");
    private static final SpriteId ARM_SPRITE = new SpriteId("boss-arm");

    /**
     * Sprite of a boss projectile. Not in {@code 02-sprite-sizes.md} yet: the boss is the first
     * enemy in the game to fire at all, so no enemy projectile art existed before this phase. Flagged
     * for the art lane in this phase's report.
     */
    private static final SpriteId SHOT_SPRITE = new SpriteId("boss-shot");

    /** Same order of magnitude as the player's own shots ({@code WeaponSystem.SHOT_P1_RADIUS}). */
    private static final float PROJECTILE_RADIUS = 2.0f;

    /**
     * The tell's timing, from {@code docs/design/06-boss-presentation.md}: three beats of a quarter
     * second each, 0.75 s total. An art fact fixed by that document, not a balance value.
     */
    private static final float BEAT_DURATION = 0.25f;

    private static final int BEATS = 3;
    private static final float TELL_DURATION = BEATS * BEAT_DURATION;

    /**
     * How many projectiles each charging part fires in one volley, fanned around the aim direction.
     * A design constant rather than a {@link BossDefinition} field: the shape of a volley is footprint,
     * the same reasoning that keeps the part radii and offsets above out of content.
     *
     * <p><b>Redesigned per {@code docs/STATUS.md}'s 25/08 diagnosis</b> — the previous, fixed-angle fan
     * always pointed outward (spread) or inward (sweep), so a player parked at screen centre was never
     * threatened by either pattern: a positioning problem solved once, not a dodge. This fan is now
     * built around a direction aimed at the player, locked once per volley (see {@link #lockAim}), and
     * widened from three rays to five — the suggestion recorded in {@code
     * docs/plan/11e-level-one-redesigned/plan.md}'s task 4 — rather than raising density again, which
     * {@code docs/STATUS.md} already tried (three rays per part) and found barely moved the difficulty.
     */
    private static final int FAN_COUNT = 5;

    /**
     * How far each ray of a volley strays from the straight line to the locked aim point, as a
     * fraction of that line's own length, applied along the perpendicular to it — narrowest (the
     * centre ray, dead on the aim point) to widest. Five values, matching {@link #FAN_COUNT}, kept
     * symmetric so the fan reads as centred on the player rather than biased to one side.
     *
     * <p>Built from vector arithmetic alone — addition, multiplication, {@link Math#sqrt} to
     * renormalise — never {@code Math.sin}/{@code cos}, for the same reason the previous fixed-ratio
     * fan avoided them: a transcendental function is not guaranteed to produce the identical float on
     * the JVM and under TeaVM, which a replay cannot afford. {@code Math.sqrt} is IEEE-754 exact and
     * already used this way elsewhere in {@code core} ({@code MotionSystem}'s velocity cap), so it
     * carries no such risk.
     */
    private static final float[] FAN_SPREAD_RATIOS = {-0.6f, -0.3f, 0f, 0.3f, 0.6f};

    /**
     * The aim point locked at the instant a pattern's tell begins — see {@link #lockAim} — read by
     * every ray of the volley that tell resolves into. Locking once, at the start of the 0.75 s tell
     * rather than at the fire instant, is what keeps the tell honest under an aimed attack: the player
     * dodges a point fixed before the tell started reacting to them, with the same 0.75 s reaction
     * window the un-aimed fan already gave, rather than a shot that keeps re-aiming at wherever they
     * are the instant it fires.
     */
    private float aimX;
    private float aimY;

    /**
     * The core's spawn height: comfortably above the playfield edge as seen through the lowest part
     * — the keel, now that it sits below the arms — exactly {@code SpawnSystem.lowestOffsetY}'s trick
     * applied to the boss's own six fixed offsets instead of a formation's slots.
     */
    private static final float CORE_SPAWN_Y =
        SpawnSystem.PLAYFIELD_HEIGHT + (CORE_KEEL_RADIUS - CORE_KEEL_OFFSET_Y);

    /**
     * The ten vertices of a five-pointed star the boss patrols between during {@code FIGHT}, per the
     * movement the project owner designed for issue #325. Index {@code i} is the ({@code i} + 1)-th
     * point in the owner's own 1-to-10 numbering; odd-numbered points (1, 3, 5, 7, 9 — indices 0, 2,
     * 4, 6, 8) are the star's five outer points, even-numbered ones (2, 4, 6, 8, 10 — indices 1, 3, 5,
     * 7, 9) are the inner valleys between them, alternating around the perimeter as the owner
     * specified.
     *
     * <p><b>Computed once, offline, never with {@code sin}/{@code cos} at runtime</b> — the same
     * determinism constraint phase 11j measured and refused curved motion against, and the plan for
     * this task repeats explicitly. The derivation: a circle of outer radius 32 and inner radius
     * {@code 32 * sin(18°) / sin(54°) ≈ 12.223} (the classic pentagram ratio, the inner-to-outer
     * radius a five-pointed star traces when both kinds of vertex sit 36° apart on the perimeter),
     * ten vertices 36° apart starting from the top (90°) and proceeding clockwise, centred at (104,
     * 200) in logical units — the playfield's own horizontal centre ({@code
     * MotionSystem.PLAYFIELD_WIDTH / 2}) and a height chosen, together with the radius, so the boss's
     * whole six-collider extent clears both edges of the 208×270 playfield with margin, not merely
     * its centre:
     *
     * <ul>
     *   <li>horizontally, the widest part is an arm ({@code ARM_OFFSET_X + ARM_RADIUS} = 58 either
     *       side of {@code coreX}); the ten points span core-x from 73.566 to 134.434, so the arms'
     *       extent spans 15.566 to 192.434 — inside [0, 208] with about 15.6 units clear on each
     *       side;
     *   <li>vertically, the lowest part is {@code core-keel} ({@code CORE_KEEL_OFFSET_Y −
     *       CORE_KEEL_RADIUS} = 40 below {@code coreY}) and the highest is the core or a pod (18
     *       above); the ten points span core-y from 174.111 to 232.0, so the keel's lowest reach is
     *       134.111 — comfortably clear of the bottom of the screen, which is the owner's one hard
     *       constraint — and the core/pod's highest reach is 250.0, inside the 270-tall playfield.
     * </ul>
     */
    static final float[] STAR_X = {
        104.0f, 111.184f, 134.434f, 115.625f, 122.809f, 104.0f, 85.191f, 92.375f, 73.566f, 96.816f
    };

    static final float[] STAR_Y = {
        232.0f, 209.889f, 209.889f, 196.223f, 174.111f, 187.777f, 174.111f, 196.223f, 209.889f,
        209.889f
    };

    static final int STAR_POINT_COUNT = 10;

    /**
     * {@code true} while the boss is travelling between star points. Package-visible for exactly the
     * reason {@link #STAR_X} is: so {@code BossSystemTest} can check it by name at the instant a front
     * shot fires, rather than inferring it from position deltas. No accessor was added to any port.
     */
    boolean isMoving() {
        return fightStage == FightStage.MOVING;
    }

    /**
     * The legal offsets from the boss's current star index to its next one: within three perimeter
     * steps in either direction, per the owner's rule — never the fourth or fifth step, which would
     * let the boss cross the screen from one side to the other in a single move. Six offsets, six
     * legal destinations from any point, exactly as the plan states.
     */
    private static final int[] STAR_STEP_OFFSETS = {-3, -2, -1, 1, 2, 3};

    /**
     * How long a move takes, whatever the distance — issue #329's inversion of #325's constant speed.
     * A footprint/movement constant hardcoded here, the same treatment {@link #FAN_COUNT} and the part
     * radii above already get: not a number {@link BossDefinition} varies with balancing.
     *
     * <p>Chosen to keep #325's own feel: at the old constant speed of 45 units/second, the longest
     * <i>legal</i> (three-step) hop of the ten star points — about 37.6 units — took about 0.84 s,
     * the slowest a player had actually seen a hop take. This value reproduces that number exactly,
     * so a short hop now visibly crawls and a long one visibly accelerates (the point of the
     * inversion) without changing how long the slowest hop used to feel.
     *
     * <p>One line to change, per the plan's own instruction — the project owner tunes this by playing.
     */
    static final float MOVE_DURATION = 0.84f;

    /**
     * How many times the front weapon (the arms, the sweep pattern) fires within one full rear cycle —
     * {@link #rearCycleDuration}, one move plus cooldown plus tell, <b>in that order in steady
     * state</b> — including the shot it fires together with the rear volley at the cycle's own
     * boundary. Issue #329's synchronisation rule: "they fire together, then the front fires more
     * often, then they coincide again," which is arithmetic once the cycle is a constant (see {@link
     * #MOVE_DURATION}'s javadoc) — the front period is simply {@code rearCycleDuration /
     * FRONT_SHOTS_PER_CYCLE}, so the Nth front shot always lands exactly on the next rear volley, and
     * {@code FRONT_SHOTS_PER_CYCLE − 1} front shots fall strictly between two rear volleys.
     *
     * <p><b>The cycle runs {@code MOVING} first, not last, in every cycle but the very first one.</b>
     * {@link #updateTelling} resets {@link #frontElapsed}/{@link #frontShotsThisCycle} to zero and
     * calls {@link #beginMove} back to back, in the same tick a rear volley fires — so the instant a
     * cycle's own clock starts at zero, the boss is already entering {@code MOVING}. Only the very
     * first cycle, from the entrance settling to the first rear volley, is different: it has no move
     * to lead with, since none has happened yet, and runs {@code COOLDOWN} then {@code TELLING} alone.
     * Every cycle after that runs {@code MOVING} ({@link #MOVE_DURATION}), then {@code COOLDOWN}
     * ({@code patternCooldown}), then {@code TELLING} ({@code TELL_DURATION}), then the next fire.
     *
     * <p><b>2, not 3 — lowered for issue #333, from the project owner's second play session.</b> #329
     * chose 3 over 2 specifically so that an independent front shot could be proven to land inside
     * {@code MOVING} — at {@code N = 2}, the single independent shot sits at exactly half the cycle,
     * which at this boss's real content ({@code patternCooldown} 0.7 s, cycle 2.29 s) falls inside
     * {@code COOLDOWN} (36.7%–63.3% of the cycle), never inside the first 36.7% that {@code MOVING}
     * occupies. The owner played {@code N = 3} and found the fight too hard; their instruction was to
     * lower the cadence, which only {@code N = 2} does at this {@link #MOVE_DURATION}. <b>A front shot
     * coinciding with a move is given up on purpose, and it does not undo the point of the front
     * weapon</b>: {@link #updateFrontWeapons} is still called unconditionally every tick of
     * {@code FIGHT}, still reads and writes nothing of {@link #fightStage}, and still fires whether the
     * boss is cooling down, telling or travelling — the front clock was never gated by movement, only
     * one particular ratio of it once happened to land a shot inside a move. What #329 proved
     * (independence from {@code fightStage}) survives; what it also proved (a shot demonstrably falls
     * inside {@code MOVING}) does not, and is no longer a requirement — the owner's own tuning outranks
     * the coordinator's hardening of the original request. The front period is now
     * {@code rearCycleDuration / 2} ≈ 1.145 s against real content, close to the owner's original 1.2 s
     * suggestion from #329 — closer, in fact, than {@code N = 3}'s 0.763 s ever was.
     *
     * <p><b>The lever not taken: fewer rays per front volley.</b> Lowering {@link #FAN_COUNT} for the
     * front weapon alone (fewer than five rays) would cut front damage while keeping {@code N = 3}'s
     * faster rhythm and keeping a shot provably inside {@code MOVING}. The coordinator raised both
     * levers with the owner; the owner chose the cadence. Left here as a one-line option for the next
     * tuning pass, not attempted: {@code FAN_COUNT} is currently shared by both weapons, so splitting it
     * would need its own constant, not a value change.
     */
    static final int FRONT_SHOTS_PER_CYCLE = 2;

    private enum Phase { AWAITING, ENTRANCE, FIGHT, DEFEATED }

    private enum FightStage { COOLDOWN, TELLING, MOVING }

    private final String levelId;

    private BossDefinition definition;
    private float levelTime;
    private Phase phase = Phase.AWAITING;

    private int core = EntityId.NONE;
    private int coreKeel = EntityId.NONE;
    private int podLeft = EntityId.NONE;
    private int podRight = EntityId.NONE;
    private int armLeft = EntityId.NONE;
    private int armRight = EntityId.NONE;

    private float coreX;
    private float coreY;

    private FightStage fightStage = FightStage.COOLDOWN;
    private float stageTimer;

    /**
     * The rear cycle's own length — {@code patternCooldown + TELL_DURATION + MOVE_DURATION} — cached
     * once {@link #definition} is known, since {@link BossDefinition#patternCooldown()} is fixed for a
     * level and never changes mid-run. What {@link #frontPeriod} divides.
     */
    private float rearCycleDuration;

    /** {@link #rearCycleDuration} divided by {@link #FRONT_SHOTS_PER_CYCLE}. See {@link #updateFrontWeapons}. */
    private float frontPeriod;

    /** Time since the front weapon last fired — either independently or together with a rear volley. */
    private float frontElapsed;

    /**
     * How many front shots have already fired within the current rear cycle, capped at {@link
     * #FRONT_SHOTS_PER_CYCLE} − 1 by {@link #updateFrontWeapons} itself: the last shot of every cycle
     * is always the one fired together with the rear volley, from {@link #fireRearVolley}, never from
     * the independent clock — see {@link #updateFrontWeapons}.
     */
    private int frontShotsThisCycle;

    /**
     * The star index the boss currently stands on, or {@code -1} while it has not yet made its first
     * move — meaning it is still exactly where the entrance left it, at {@code (PLAYFIELD_WIDTH / 2,
     * combatY)}, a position the star does not otherwise claim. See {@link #beginMove}.
     */
    private int currentStarIndex = -1;

    private int targetStarIndex;
    private float moveFromX;
    private float moveFromY;
    private float moveDuration;
    private float moveElapsed;

    /**
     * @param levelId the content id of the level this system fights the boss for
     */
    public BossSystem(String levelId) {
        if (levelId == null || levelId.isEmpty()) {
            throw new IllegalArgumentException("a boss system needs a level id");
        }
        this.levelId = levelId;
    }

    @Override
    public SystemOrder order() {
        return SystemOrder.BOSS;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        levelTime += step;
        if (definition == null) {
            if (!world.content().hasBoss(levelId)) {
                // This level has no boss. Checked every tick instead of once, the same trade
                // SpawnSystem's own exhaustion flag makes: cheaper than a one-shot guard and just as
                // correct, since a level's content never changes mid-run.
                return;
            }
            definition = world.content().boss(levelId);
            rearCycleDuration = definition.patternCooldown() + TELL_DURATION + MOVE_DURATION;
            frontPeriod = rearCycleDuration / FRONT_SHOTS_PER_CYCLE;
        }
        world.markBossLevel();

        switch (phase) {
            case AWAITING -> updateAwaiting(world, definition);
            case ENTRANCE, FIGHT -> updateSpawned(world, definition, step);
            case DEFEATED -> { }
        }
    }

    /**
     * Shared by {@code ENTRANCE} and {@code FIGHT}: both are "the boss exists" states, and the core
     * can in principle die in either — a bomb detonating during the entrance is unlikely to line up,
     * but not impossible, and the fight must end correctly either way, not only once the state
     * machine has formally reached {@code FIGHT}.
     */
    private void updateSpawned(World world, BossDefinition def, float step) {
        if (!world.isAlive(core)) {
            handleCoreDeath(world);
            return;
        }
        if (phase == Phase.ENTRANCE) {
            updateEntrance(world, def, step);
        } else {
            updateFight(world, def, step);
        }
    }

    private void updateAwaiting(World world, BossDefinition def) {
        if (levelTime < def.entersAt()) {
            return;
        }
        spawnParts(world, def);
        phase = Phase.ENTRANCE;
        reportStatus(world, def);
    }

    private void spawnParts(World world, BossDefinition def) {
        coreX = MotionSystem.PLAYFIELD_WIDTH / 2f;
        coreY = CORE_SPAWN_Y;

        core = createPart(world, coreX, coreY, CORE_SPRITE, CORE_RADIUS, def.coreHealth(), def.corePoints());
        coreKeel = createPart(world, coreX + CORE_KEEL_OFFSET_X, coreY + CORE_KEEL_OFFSET_Y, null,
            CORE_KEEL_RADIUS, def.coreHealth(), def.corePoints());
        podLeft = createPart(world, coreX - POD_OFFSET_X, coreY + POD_OFFSET_Y, POD_SPRITE, POD_RADIUS,
            def.podHealth(), def.podPoints());
        podRight = createPart(world, coreX + POD_OFFSET_X, coreY + POD_OFFSET_Y, POD_SPRITE, POD_RADIUS,
            def.podHealth(), def.podPoints());
        armLeft = createPart(world, coreX - ARM_OFFSET_X, coreY + ARM_OFFSET_Y, ARM_SPRITE, ARM_RADIUS,
            def.armHealth(), def.armPoints());
        armRight = createPart(world, coreX + ARM_OFFSET_X, coreY + ARM_OFFSET_Y, ARM_SPRITE, ARM_RADIUS,
            def.armHealth(), def.armPoints());
    }

    /**
     * @param sprite what to draw, or {@code null} for a part with no drawn sprite of its own —
     *     {@code core-keel}, which only exists to extend where a hit against the core's own drawn
     *     sprite registers
     */
    private static int createPart(
        World world, float x, float y, SpriteId sprite, float radius, int health, int points) {
        int entity = world.createEntity();
        world.transforms().set(entity, new Transform(x, y));
        world.colliders().set(entity, new Collider(radius, CollisionLayer.ENEMY, false));
        if (sprite != null) {
            world.sprites().set(entity, new Sprite(sprite));
        }
        world.healths().set(entity, new Health(health));
        world.scoreValues().set(entity, new ScoreValue(points));
        return entity;
    }

    private void updateEntrance(World world, BossDefinition def, float step) {
        coreY -= def.entranceSpeed() * step;
        boolean reached = coreY <= def.combatY();
        if (reached) {
            coreY = def.combatY();
        }
        positionParts(world);
        if (reached) {
            phase = Phase.FIGHT;
            fightStage = FightStage.COOLDOWN;
            stageTimer = def.patternCooldown();
            // The front weapon's own clock starts here too, so it is already running through the very
            // first rear cooldown and tell — it does not wait for the first rear volley to begin.
            frontElapsed = 0f;
            frontShotsThisCycle = 0;
        }
        reportStatus(world, def);
    }

    private void positionParts(World world) {
        setPosition(world, core, coreX, coreY);
        setPosition(world, coreKeel, coreX + CORE_KEEL_OFFSET_X, coreY + CORE_KEEL_OFFSET_Y);
        setPosition(world, podLeft, coreX - POD_OFFSET_X, coreY + POD_OFFSET_Y);
        setPosition(world, podRight, coreX + POD_OFFSET_X, coreY + POD_OFFSET_Y);
        setPosition(world, armLeft, coreX - ARM_OFFSET_X, coreY + ARM_OFFSET_Y);
        setPosition(world, armRight, coreX + ARM_OFFSET_X, coreY + ARM_OFFSET_Y);
    }

    private static void setPosition(World world, int entity, float x, float y) {
        if (entity == EntityId.NONE || !world.isAlive(entity)) {
            return;
        }
        Transform transform = world.transforms().get(entity);
        if (transform != null) {
            transform.x = x;
            transform.y = y;
        }
    }

    private void updateFight(World world, BossDefinition def, float step) {
        switch (fightStage) {
            case COOLDOWN -> updateCooldown(world, def, step);
            case TELLING -> updateTelling(world, def, step);
            case MOVING -> updateMoving(world, def, step);
        }
        // Independent of fightStage on purpose: the front weapon fires whether the boss is cooling
        // down, telling or travelling. See the class javadoc paragraph on the rear/front split.
        updateFrontWeapons(world, def, step);
        reportStatus(world, def);
    }

    private void updateCooldown(World world, BossDefinition def, float step) {
        stageTimer -= step;
        if (stageTimer <= 0f) {
            fightStage = FightStage.TELLING;
            stageTimer = 0f;
            lockAim(world);
        }
    }

    /**
     * Reads the player's current position, through the same fixed step every other system reads the
     * world under, and holds it in {@link #aimX}/{@link #aimY} for the whole tell and the rear volley
     * it resolves into. Called exactly once per rear cycle, at the instant the tell begins — see the
     * class javadoc on {@link #FAN_SPREAD_RATIOS} for why locking here rather than at fire time is
     * what keeps the tell honest. The front weapon does not use this: it has no tell to lock at the
     * start of, so it computes its own aim point fresh, at fire time — see {@link #computeAimPoint}.
     */
    private void lockAim(World world) {
        AimPoint aim = computeAimPoint(world);
        aimX = aim.x();
        aimY = aim.y();
    }

    /**
     * Reads the player's current position, the same way {@link #lockAim} does, but returns it instead
     * of freezing it in a field — what the front weapon needs, since each of its shots aims at the
     * position current at the instant it fires rather than one frozen at the start of a charge it
     * never has.
     *
     * <p>No player entity — the boss level's own test fixtures routinely omit one — falls back to the
     * playfield's horizontal centre at {@code playerStartY}, {@link BalanceValues}' own content value
     * rather than a hardcoded one, so a shot still points somewhere plausible instead of at (0, 0).
     */
    private AimPoint computeAimPoint(World world) {
        int player = world.playerEntity();
        Transform transform = player == EntityId.NONE ? null : world.transforms().get(player);
        if (transform != null) {
            return new AimPoint(transform.x, transform.y);
        }
        return new AimPoint(MotionSystem.PLAYFIELD_WIDTH / 2f, world.content().balance().playerStartY());
    }

    private record AimPoint(float x, float y) { }

    private void updateTelling(World world, BossDefinition def, float step) {
        stageTimer += step;
        int beat = Math.min(BEATS - 1, (int) (stageTimer / BEAT_DURATION));
        applyPodTellFrame(world, beat + 1);
        if (stageTimer < TELL_DURATION) {
            return;
        }
        fireRearVolley(world, def);
        applyPodTellFrame(world, 0);
        // The synchronisation point: the front weapon fires together with every rear volley, whether
        // or not its own independent clock (below) had already reached FRONT_SHOTS_PER_CYCLE - 1 shots
        // this cycle, and the cycle restarts from here regardless.
        fireFrontVolley(world, def);
        frontElapsed = 0f;
        frontShotsThisCycle = 0;
        beginMove(world);
    }

    /**
     * Starts the boss travelling, for exactly {@link #MOVE_DURATION} regardless of distance, from
     * wherever it is to the next star point — called only once the rear volley has fully resolved,
     * never while a tell is charging or a shot is in flight. This is what answers the plan's question
     * of what happens if an attack is still resolving when a move would begin: it cannot happen for the
     * rear weapon, because {@link FightStage#MOVING} is only ever entered from the end of {@link
     * #updateTelling}, after {@link #fireRearVolley} has already run, and {@link #updateCooldown} and
     * {@link #updateTelling} — the only places a tell advances or a rear volley fires — never run while
     * {@link #fightStage} is {@code MOVING}. Firing and moving are strictly serialised by this state
     * machine, not merely by convention. The front weapon is exempt from this exclusion entirely — see
     * {@link #updateFrontWeapons}, which never reads or writes {@link #fightStage}.
     *
     * <p>The destination is drawn from the seeded {@link World#rng()}: uniformly over all ten points
     * for the very first move, since the boss is not yet standing on any of them — it is still at the
     * entrance's own landing spot, {@code (PLAYFIELD_WIDTH / 2, combatY)}, which the star does not
     * claim as one of its own — and otherwise restricted to {@link #STAR_STEP_OFFSETS} from {@link
     * #currentStarIndex}, per the owner's three-step rule.
     */
    private void beginMove(World world) {
        int next = currentStarIndex < 0
            ? world.rng().nextInt(STAR_POINT_COUNT)
            : pickNextStarIndex(world, currentStarIndex);
        moveFromX = coreX;
        moveFromY = coreY;
        targetStarIndex = next;
        moveDuration = MOVE_DURATION;
        moveElapsed = 0f;
        fightStage = FightStage.MOVING;
    }

    private static int pickNextStarIndex(World world, int current) {
        int offset = STAR_STEP_OFFSETS[world.rng().nextInt(STAR_STEP_OFFSETS.length)];
        int next = (current + offset) % STAR_POINT_COUNT;
        return next < 0 ? next + STAR_POINT_COUNT : next;
    }

    /**
     * Advances the boss along the straight line from where the move began to {@link
     * #targetStarIndex}, linearly in time over the fixed {@link #MOVE_DURATION} so a degenerate
     * zero-duration move (never configured, {@code MOVE_DURATION} being a positive literal, but not
     * provably impossible if it were ever changed to zero) still resolves in one tick rather than
     * dividing by zero. No rear attack timer advances while this runs — see {@link #beginMove} — but
     * the front weapon's own clock keeps running, per {@link #updateFrontWeapons}.
     */
    private void updateMoving(World world, BossDefinition def, float step) {
        moveElapsed += step;
        float t = moveDuration <= 0f ? 1f : Math.min(1f, moveElapsed / moveDuration);
        coreX = moveFromX + (STAR_X[targetStarIndex] - moveFromX) * t;
        coreY = moveFromY + (STAR_Y[targetStarIndex] - moveFromY) * t;
        positionParts(world);
        if (t >= 1f) {
            currentStarIndex = targetStarIndex;
            fightStage = FightStage.COOLDOWN;
            stageTimer = def.patternCooldown();
        }
    }

    /**
     * The front weapon's own clock, run every tick of {@code FIGHT} regardless of {@link #fightStage}
     * — the deliberate break of the move/attack exclusion the rear weapon still holds to. Fires at most
     * {@link #FRONT_SHOTS_PER_CYCLE} − 1 shots independently per rear cycle, evenly spaced at {@link
     * #frontPeriod}; the cycle's own last shot always comes from {@link #updateTelling}, fired together
     * with the rear volley, never from here — that split is what turns "coincide every N shots" from a
     * runtime correction into arithmetic: {@link #frontPeriod} is exactly {@link #rearCycleDuration}
     * divided by {@link #FRONT_SHOTS_PER_CYCLE}, so {@code FRONT_SHOTS_PER_CYCLE} shots, evenly spaced,
     * always span exactly one rear cycle.
     */
    private void updateFrontWeapons(World world, BossDefinition def, float step) {
        frontElapsed += step;
        if (frontShotsThisCycle < FRONT_SHOTS_PER_CYCLE - 1
            && frontElapsed >= frontPeriod * (frontShotsThisCycle + 1)) {
            frontShotsThisCycle++;
            fireFrontVolley(world, def);
        }
    }

    /**
     * Sets the pods' {@link Sprite#frame} to the tell's current beat, 1 through 3, or back to 0 once
     * the rear volley leaves — the whole contract presentation needs, per the class javadoc. The arms
     * have no tell and no charge frame of their own: a front shot is instantaneous.
     */
    private void applyPodTellFrame(World world, int frame) {
        setFrame(world, podLeft, frame);
        setFrame(world, podRight, frame);
    }

    private static void setFrame(World world, int entity, int frame) {
        if (entity == EntityId.NONE || !world.isAlive(entity)) {
            return;
        }
        Sprite sprite = world.sprites().get(entity);
        if (sprite != null) {
            sprite.frame = frame;
        }
    }

    private void fireRearVolley(World world, BossDefinition def) {
        fireAimedFan(world, podLeft, def.spreadProjectileSpeed(), aimX, aimY);
        fireAimedFan(world, podRight, def.spreadProjectileSpeed(), aimX, aimY);
    }

    /**
     * Fires the front weapon: a fresh aim point, computed now rather than read from a field frozen
     * earlier, since the front weapon has no tell to freeze one at the start of. Called both from
     * {@link #updateFrontWeapons}, on its own independent clock, and from {@link #updateTelling}, at
     * the instant a rear volley fires — see the class javadoc on the synchronisation rule.
     */
    private void fireFrontVolley(World world, BossDefinition def) {
        AimPoint aim = computeAimPoint(world);
        fireAimedFan(world, armLeft, def.sweepProjectileSpeed(), aim.x(), aim.y());
        fireAimedFan(world, armRight, def.sweepProjectileSpeed(), aim.x(), aim.y());
    }

    /**
     * Fires {@link #FAN_COUNT} projectiles from {@code part} in the same tick, fanned around the
     * straight line from {@code part}'s own current position to {@code (targetX, targetY)} — not
     * around a fixed outward or inward angle, which is exactly the change this method exists for. Both
     * a rear pod and a front arm call this the same way; they differ only in which parts fire, at what
     * speed and how the target is computed (frozen at tell start for the rear, fresh at fire time for
     * the front — see {@link #lockAim} and {@link #computeAimPoint}), not in how a volley is shaped.
     *
     * <p>Each ray takes the unit aim direction, adds a multiple of its perpendicular — {@link
     * #FAN_SPREAD_RATIOS}, narrowest to widest — and renormalises, so every ray still travels at
     * exactly {@code speed} regardless of how far it strays from dead-on. The centre ratio, {@code 0f},
     * reproduces the un-fanned aim direction exactly.
     */
    private void fireAimedFan(World world, int part, float speed, float targetX, float targetY) {
        if (part == EntityId.NONE || !world.isAlive(part)) {
            // The firing part is dead: that side of the attack simply does not fire. The cycle still
            // completes normally.
            return;
        }
        Transform origin = world.transforms().get(part);
        if (origin == null) {
            return;
        }
        float dx = targetX - origin.x;
        float dy = targetY - origin.y;
        float lengthSquared = dx * dx + dy * dy;
        if (lengthSquared < 1e-6f) {
            // The aim point sits (almost) on top of the firing part — degenerate only, never observed
            // in play at this boss's footprint, but a direction must still be well defined. Straight
            // down, toward where the player always is relative to the boss.
            dx = 0f;
            dy = -1f;
            lengthSquared = 1f;
        }
        float length = (float) Math.sqrt(lengthSquared);
        float ux = dx / length;
        float uy = dy / length;
        float perpX = -uy;
        float perpY = ux;
        for (float ratio : FAN_SPREAD_RATIOS) {
            float rx = ux + ratio * perpX;
            float ry = uy + ratio * perpY;
            float rayLength = (float) Math.sqrt(rx * rx + ry * ry);
            fireFrom(world, origin, speed * rx / rayLength, speed * ry / rayLength);
        }
    }

    private static void fireFrom(World world, Transform origin, float vx, float vy) {
        int projectile = world.createEntity();
        world.transforms().set(projectile, new Transform(origin.x, origin.y));
        world.motions().set(projectile, new Motion(vx, vy));
        world.colliders().set(projectile, new Collider(PROJECTILE_RADIUS, CollisionLayer.ENEMY_PROJECTILE));
        world.sprites().set(projectile, new Sprite(SHOT_SPRITE));
    }

    /**
     * The core is destroyed: whatever pods and arms remain go with it, the fight ends, and {@link
     * World#markBossDefeated()} is what lets {@code WorldView.outcome()} report victory.
     */
    private void handleCoreDeath(World world) {
        markDefeatedPart(world, coreKeel);
        markDefeatedPart(world, podLeft);
        markDefeatedPart(world, podRight);
        markDefeatedPart(world, armLeft);
        markDefeatedPart(world, armRight);
        phase = Phase.DEFEATED;
        world.markBossDefeated();
    }

    private static void markDefeatedPart(World world, int entity) {
        if (entity != EntityId.NONE && world.isAlive(entity)) {
            world.markForDestruction(entity);
        }
    }

    /**
     * Sums current hit points across every surviving part and reports the total, plus the fixed
     * starting total, to {@link World#setBossStatus(int, int)}. A dead part — {@code
     * EntityId.NONE} before it spawns, or destroyed later — simply contributes zero, which is what
     * makes the bar shorten the instant a part dies, not only while it is merely damaged.
     */
    private void reportStatus(World world, BossDefinition def) {
        int hp = healthOf(world, core) + healthOf(world, coreKeel) + healthOf(world, podLeft)
            + healthOf(world, podRight) + healthOf(world, armLeft) + healthOf(world, armRight);
        int hpMax = 2 * def.coreHealth() + 2 * def.podHealth() + 2 * def.armHealth();
        world.setBossStatus(hp, hpMax);
    }

    private static int healthOf(World world, int entity) {
        if (entity == EntityId.NONE || !world.isAlive(entity)) {
            return 0;
        }
        Health health = world.healths().get(entity);
        return health == null ? 0 : health.points;
    }
}
