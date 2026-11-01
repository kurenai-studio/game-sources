package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Drop;
import dev.luchoc.littlespaceship.core.domain.component.Trajectory;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.WaveOrigin;
import dev.luchoc.littlespaceship.core.domain.content.ComponentFactoryRegistry;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.EnemyDefinition;
import dev.luchoc.littlespaceship.core.port.FormationDefinition;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.PlacedPickup;
import dev.luchoc.littlespaceship.core.port.SpawnEvent;
import dev.luchoc.littlespaceship.core.port.WaveDefinition;
import dev.luchoc.littlespaceship.core.port.WaveEndCondition;
import dev.luchoc.littlespaceship.core.port.WavePlacement;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * Advances a level's ordered {@link WavePlacement} sequence and spawns what is due — the intensity
 * curve turned into entities.
 *
 * <p>Unlike most other systems, this one is not stateless: it holds the level id it was built for,
 * how much level time has elapsed, and every {@link ActiveWave} currently spawning or waiting on its
 * end condition. That is a deliberate exception to the pattern the other systems keep, not an
 * oversight — a fresh {@code Simulation} always builds a fresh {@code SpawnSystem}, so the state is
 * exactly as reproducible as everything else the composition root creates once per run.
 *
 * <p><b>How a level's placements resolve into running waves.</b> {@link WavePlacement#offsetSeconds()}
 * is relative to the end of the placement before it, so the next placement can only be scheduled once
 * the current one's end time is known — and the two end conditions know that at very different
 * moments. For a {@link WaveEndCondition.FixedDuration} wave the end time is deterministic —
 * {@code startTime + seconds} — the instant the wave itself starts, so {@link #scheduleNext} resolves
 * the placement after it <em>predictively</em>, right then, chaining through as many further
 * {@code FixedDuration} placements as follow consecutively. That is what lets a negative offset
 * genuinely overlap two waves: both are in {@link #activeWaves} at once, rather than the second only
 * appearing on the tick the first is removed. For a {@link WaveEndCondition.Cleared} wave the end
 * time cannot be known until it actually happens: {@code CLEANUP}, the stage that removes a spawned
 * entity, runs after {@code SPAWN} in the very same tick, so a wave clearing on this tick is only
 * visible to this system on the <em>next</em> one — {@code SPAWN} stays fifth in {@link SystemOrder},
 * and a {@code cleared} wave resolves one tick late as a direct, deterministic consequence of that
 * order, not a bug. Only this reactive case clamps its start forward to {@code levelTime}: it is the
 * one whose "end of the placement before it" is discovered after the fact, so a negative offset must
 * not retroactively spawn anything in the past. The predictive {@code FixedDuration} case carries no
 * such clamp — a negative offset there is free to place the next wave's start before the current
 * {@code levelTime}, which is exactly the overlap it is for.
 *
 * <p>Several waves can be active at once — that is what a negative offset is for — so every tick
 * first lets every active wave spawn whatever of its own {@link WaveDefinition#spawns()} is now due,
 * then checks every active wave's end condition and schedules the placement after any that just
 * ended. Because scheduling a new wave can itself make it immediately due this same tick (a
 * clamped-to-now start with a spawn at its own time zero), that two-phase step repeats until nothing
 * changes, bounded by the level's own placement count.
 *
 * <p>Each entity of a spawned wave is built the same way: an entity is created, every {@link
 * ComponentSpec} of the {@link EnemyDefinition} is handed to the {@link ComponentFactoryRegistry},
 * and only then is its {@code Transform} set from the wave's anchor plus the {@link FormationSlot}'s
 * offset — position is spawn-event data, never archetype data, so it is not something a component
 * factory could know. When {@link SpawnEvent#hasTrajectoryOverride()} is true, the movement shape the
 * archetype's own {@code "motion"} spec just attached is immediately replaced by
 * {@link ComponentFactoryRegistry#attachTrajectory}, resolved against the event's own {@link
 * SpawnEvent#trajectoryId()} — the binding {@code docs/plan/11c-movement-shapes/plan.md} decided:
 * "the shape is chosen in the spawn event, with the archetype supplying the default." Every
 * archetype in {@code assets/data/enemies.json} carries a {@code "motion"} spec today, so this never
 * attaches a {@link dev.luchoc.littlespaceship.core.domain.component.Trajectory} to an entity whose
 * archetype opted out of movement altogether; nothing currently does. Every entity of a wave enters
 * fully off-screen, regardless of its own size and
 * of the formation's shape: the anchor is pushed up by the formation's lowest {@code offsetY}
 * ({@link #lowestOffsetY}), so the slot closest to being visible is the one measured against the
 * playfield edge, and every other slot ends up further above it. A single-slot formation is the
 * special case of this where the lowest offset is its own, usually zero.
 *
 * <p>Every entity a wave spawns also carries a {@link WaveOrigin}, tagged with the {@link
 * WaveDefinition#id()} of the wave that spawned it — the string content id, not a synthetic per-call
 * counter, which is what lets {@link WaveEndCondition.Cleared} ask "does any entity still carry this
 * wave's id" and get a real answer even when the same wave id is placed twice in a level.
 * {@code SpawnerSystem} copies this tag onto the children a carrier spawns, per the carrier-children
 * rule in {@code docs/planning/08-decisions-and-open-items.md}.
 */
public final class SpawnSystem implements GameSystem {

    /**
     * Height of the playfield, in logical units. {@code docs/design/04-hud-layout.md} fixes the
     * playfield at 208x270 inside the 480x270 logical resolution — this is that second figure, the
     * counterpart to {@link MotionSystem#PLAYFIELD_WIDTH}. A fixed dimension of the logical
     * resolution, not a balance value, for the same reason that constant is not one either.
     */
    public static final float PLAYFIELD_HEIGHT = 270f;

    private static final ComponentFactoryRegistry FACTORIES = ComponentFactoryRegistry.withDefaults();

    private final String levelId;

    private final List<ActiveWave> activeWaves = new ArrayList<>();
    private List<WavePlacement> placements;
    private int nextPlacementIndex;
    private float levelTime;
    private boolean started;

    /**
     * @param levelId the content id of the level this system advances
     */
    public SpawnSystem(String levelId) {
        if (levelId == null || levelId.isEmpty()) {
            throw new IllegalArgumentException("a spawn system needs a level id");
        }
        this.levelId = levelId;
    }

    @Override
    public SystemOrder order() {
        return SystemOrder.SPAWN;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        if (!started) {
            // Scheduled at levelTime 0, before this tick's own step is added — the level's very
            // first placement starts at "the beginning", the same instant the old flat-cursor system
            // began at, not one step late. Scheduling it after the increment below would clamp its
            // start forward to this tick's levelTime and push every one of its spawns back by one
            // step, which is not what "clamp forward on late detection" in scheduleNext is for.
            started = true;
            placements = world.content().placements(levelId);
            activeWaves.addAll(scheduleNext(world, 0f));
        }
        levelTime += step;

        boolean progressed;
        do {
            for (ActiveWave wave : activeWaves) {
                spawnDue(world, wave, step);
            }
            progressed = resolveEnded(world);
        } while (progressed);

        if (nextPlacementIndex >= placements.size() && activeWaves.isEmpty()) {
            // Marks every tick from here on, not only the one where the level's last wave first
            // ended — cheaper than a one-shot guard and just as correct, since World.outcome() only
            // ever reads this as a level, not an edge.
            world.markWaveTimelineExhausted();
        }
    }

    /**
     * Removes every active wave whose end condition is true this tick and, for a {@link
     * WaveEndCondition.Cleared} wave, reactively schedules the placement after it — returning whether
     * at least one wave ended. A {@link WaveEndCondition.FixedDuration} wave's own follower was already
     * scheduled predictively back when this wave itself started (see {@link #scheduleNext}), so ending
     * one here schedules nothing further. Collects reactively scheduled waves separately and adds them
     * only once the removal pass is over, since {@link #activeWaves} cannot be both iterated and
     * appended to at the same time.
     */
    private boolean resolveEnded(World world) {
        List<ActiveWave> scheduled = null;
        boolean anyEnded = false;
        Iterator<ActiveWave> it = activeWaves.iterator();
        while (it.hasNext()) {
            ActiveWave wave = it.next();
            if (!hasEnded(world, wave)) {
                continue;
            }
            it.remove();
            anyEnded = true;
            if (wave.definition.endCondition() instanceof WaveEndCondition.Cleared) {
                List<ActiveWave> next = scheduleNext(world, levelTime);
                if (!next.isEmpty()) {
                    if (scheduled == null) {
                        scheduled = new ArrayList<>();
                    }
                    scheduled.addAll(next);
                }
            }
        }
        if (scheduled != null) {
            activeWaves.addAll(scheduled);
        }
        return anyEnded;
    }

    /**
     * Resolves the next placement of the level, if any remain, into a running {@link ActiveWave}
     * started at {@code previousEndTime + offsetSeconds}. When that new wave is itself a {@link
     * WaveEndCondition.FixedDuration} one, its own end time is already known — {@code start + seconds}
     * — so the placement after <em>it</em> is resolved right away too, recursively, rather than waiting
     * for {@link #resolveEnded} to notice it ended later. The chain only stops at a level's last
     * placement or at a {@link WaveEndCondition.Cleared} wave, whose true end is discoverable only
     * after the fact.
     *
     * <p>{@code previousEndTime} is clamped forward to {@link #levelTime} so a negative offset never
     * schedules a start earlier than "now" for the wave whose end time this call was actually told —
     * the only case that matters for a {@link WaveEndCondition.Cleared} predecessor, since a {@link
     * WaveEndCondition.FixedDuration} predecessor's known end is always already {@code <= levelTime}
     * by construction. This is deliberately the one clamp negative offsets still respect: it protects
     * "no retroactive spawning", not "no overlap".
     *
     * @param previousEndTime the level time the placement before this one ends (known exactly for a
     *     {@code FixedDuration} predecessor, or the current tick's {@code levelTime} when called
     *     reactively for a {@code Cleared} one), or {@code 0f} for the level's very first placement
     * @return every {@link ActiveWave} this call resolved, in order — empty once the level has no more
     *     placements, one or more when a chain of {@code FixedDuration} placements resolves at once
     */
    private List<ActiveWave> scheduleNext(World world, float previousEndTime) {
        List<ActiveWave> created = new ArrayList<>();
        scheduleChain(world, previousEndTime, created);
        return created;
    }

    private void scheduleChain(World world, float previousEndTime, List<ActiveWave> created) {
        if (nextPlacementIndex >= placements.size()) {
            return;
        }
        WavePlacement placement = placements.get(nextPlacementIndex);
        nextPlacementIndex++;
        float start = Math.max(previousEndTime + placement.offsetSeconds(), levelTime);
        WaveDefinition definition = world.content().wave(placement.waveId());
        ActiveWave wave = new ActiveWave(definition, start);
        created.add(wave);
        if (definition.endCondition() instanceof WaveEndCondition.FixedDuration duration) {
            scheduleChain(world, start + duration.seconds(), created);
        }
    }

    private void spawnDue(World world, ActiveWave wave, float step) {
        List<SpawnEvent> events = wave.definition.spawns();
        float localTime = levelTime - wave.startTime;
        while (wave.cursor < events.size() && events.get(wave.cursor).at() <= localTime) {
            spawnWave(world, events.get(wave.cursor), wave.definition.id(), step);
            wave.cursor++;
        }
        List<PlacedPickup> pickups = wave.definition.pickups();
        while (wave.pickupCursor < pickups.size() && pickups.get(wave.pickupCursor).at() <= localTime) {
            spawnPlacedPickup(world, pickups.get(wave.pickupCursor), wave.definition.id());
            wave.pickupCursor++;
        }
    }

    /**
     * Creates the pickup a {@link PlacedPickup} describes, with no enemy involved — issue #255's "a
     * reward the player flies to rather than one that falls out of something they shot." Built the
     * same way {@code CleanupSystem} builds one from a defeated enemy's {@code Drop}, through {@link
     * CleanupSystem#createFallingPickup}: same components, same falling {@code Motion}, the only
     * difference being where the position and the kind come from. {@code atX}/{@code atY} convert
     * from the {@code [0, 1]} fraction {@link PlacedPickup} stores to logical units the same way
     * {@link SpawnEvent#atX()} already does for an enemy's anchor.
     */
    private static void spawnPlacedPickup(World world, PlacedPickup placed, String waveId) {
        requireRecognisedPickup(waveId, placed);
        float x = placed.atX() * MotionSystem.PLAYFIELD_WIDTH;
        float y = placed.atY() * PLAYFIELD_HEIGHT;
        CleanupSystem.createFallingPickup(world, x, y, placed.kind());
    }

    /**
     * Fails the moment a wave carrying an unrecognised placed-pickup kind spawns it, instead of only
     * when a player reaches the pickup — the same reasoning {@link #requireRecognisedDrop} applies to
     * an enemy's designed drop, asked of the same single source of truth, {@code PickupSystem}.
     */
    private static void requireRecognisedPickup(String waveId, PlacedPickup placed) {
        if (!PickupSystem.isRecognisedKind(placed.kind())) {
            throw new IllegalArgumentException(
                "wave '" + waveId + "' places a pickup at " + placed.at()
                    + "s with an unrecognised kind '" + placed.kind() + "'");
        }
    }

    /**
     * @return true once {@code wave}'s own end condition is satisfied at the current {@link
     *     #levelTime}
     */
    private boolean hasEnded(World world, ActiveWave wave) {
        WaveEndCondition condition = wave.definition.endCondition();
        if (condition instanceof WaveEndCondition.FixedDuration duration) {
            return levelTime - wave.startTime >= duration.seconds();
        }
        if (condition instanceof WaveEndCondition.Cleared) {
            return wave.cursor >= wave.definition.spawns().size()
                && wave.pickupCursor >= wave.definition.pickups().size()
                && noEntityCarries(world, wave.definition.id());
        }
        // WaveEndCondition is sealed to exactly these two, per its own class javadoc.
        throw new IllegalStateException("unknown wave end condition: " + condition);
    }

    /**
     * @return true when no live entity's {@link WaveOrigin} names {@code waveId} — a wave's own
     *     spawns and, per the carrier-children rule, every child a carrier of theirs produced
     */
    private static boolean noEntityCarries(World world, String waveId) {
        ComponentStore<WaveOrigin> origins = world.waveOrigins();
        for (int i = 0; i < origins.size(); i++) {
            if (origins.valueAt(i).waveId.equals(waveId)) {
                return false;
            }
        }
        return true;
    }

    private static void spawnWave(World world, SpawnEvent event, String waveId, float step) {
        EnemyDefinition enemy = world.content().enemy(event.enemyId());
        FormationDefinition formation = world.content().formation(event.formationId());
        if (event.hasDrop()) {
            requireRecognisedDrop(enemy, event);
            requireSlotInRange(formation, event);
        }
        float anchorX = event.atX() * MotionSystem.PLAYFIELD_WIDTH;
        float lowestOffsetY = lowestOffsetY(formation.slots());

        List<FormationSlot> slots = formation.slots();
        for (int i = 0; i < slots.size(); i++) {
            FormationSlot slot = slots.get(i);
            int entity = world.createEntity();
            attachComponents(world, enemy, entity);
            if (event.hasTrajectoryOverride()) {
                ComponentFactoryRegistry.attachTrajectory(world, entity, event.trajectoryId());
            }
            applySlotDelay(world, entity, slot, step);
            positionSpawned(world, entity, anchorX, lowestOffsetY, slot);
            world.waveOrigins().set(entity, new WaveOrigin(waveId));
            if (event.hasDrop() && i == event.dropSlot()) {
                world.drops().set(entity, new Drop(event.dropId()));
            }
        }
    }

    /**
     * Fails the moment a wave's drop names a slot its own formation does not have, instead of the
     * drop silently landing on no entity at all — the same reasoning as {@link
     * #requireRecognisedDrop}, applied to issue #23's fix: a designed drop is tied to one specific
     * slot, and a typo in which one should not go unnoticed until someone wonders why an encounter
     * gave up nothing.
     */
    private static void requireSlotInRange(FormationDefinition formation, SpawnEvent event) {
        if (event.dropSlot() >= formation.slots().size()) {
            throw new IllegalArgumentException(
                "spawn event at " + event.at() + "s drops into slot " + event.dropSlot()
                    + " of formation '" + formation.id() + "', which only has "
                    + formation.slots().size() + " slot(s)");
        }
    }

    /**
     * Fails the moment a wave carrying an unrecognised drop id spawns, instead of only when a
     * player reaches the pickup that {@code Drop} eventually produces. {@code PickupSystem} is the
     * single place that decides which kinds are real; this only asks it, rather than keeping a
     * second list of the same six strings that could drift from the one {@code PickupSystem}
     * resolves against.
     */
    private static void requireRecognisedDrop(EnemyDefinition enemy, SpawnEvent event) {
        if (!PickupSystem.isRecognisedKind(event.dropId())) {
            throw new IllegalArgumentException(
                "enemy '" + enemy.id() + "' at " + event.at() + "s drops an unrecognised kind '"
                    + event.dropId() + "'");
        }
    }

    /**
     * The offset closest to the playfield — the smallest {@code offsetY}, since {@code Transform.y}
     * grows upwards and a lower value means lower on screen. Measuring the spawn height against this
     * one slot, rather than against each slot's own offset, is what keeps every other slot of the
     * same formation above it and therefore also off-screen.
     */
    private static float lowestOffsetY(List<FormationSlot> slots) {
        float lowest = Float.POSITIVE_INFINITY;
        for (FormationSlot slot : slots) {
            lowest = Math.min(lowest, slot.offsetY());
        }
        return lowest;
    }

    private static void attachComponents(World world, EnemyDefinition enemy, int entity) {
        for (ComponentSpec spec : enemy.components()) {
            try {
                FACTORIES.attach(world, entity, spec);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException(
                    "enemy '" + enemy.id() + "': " + e.getMessage(), e);
            }
        }
    }

    /**
     * Sets a delayed slot's {@link Trajectory#delayTicks} to the number of ticks it should hold still
     * before its {@link Trajectory#elapsed} starts accumulating — issue #330's "single-file column".
     * {@code MotionSystem} holds an entity still and counts this down for as long as it is positive,
     * so this is the whole mechanism: no new component, no scheduler, just the one integer field
     * {@link Trajectory} carries for it. A slot with no delay is untouched — its {@link Trajectory},
     * if it has one, keeps the {@code 0} {@link ComponentFactoryRegistry#attachTrajectory} gave it —
     * which is what keeps every formation that predates this issue byte-for-byte identical.
     *
     * <p><b>Issue #337 correction.</b> This used to backdate {@link Trajectory#elapsed} to {@code
     * -slot.delaySeconds()} and let {@code MotionSystem} hold the entity still while that float stayed
     * at or below zero. That crossing depended on two different float arithmetic paths — this single
     * multiplication versus {@code MotionSystem}'s repeated addition of {@code step} — agreeing
     * bit-for-bit, which they did not for roughly a fifth of all delays. Converting the delay to a
     * whole tick count once, here, with {@link Math#round}, and handing {@code MotionSystem} an
     * integer to count down removes that disagreement entirely: {@code delaySeconds} is already, by
     * the time it reaches a slot, an exact multiple of {@code step} (the loader quantises it on parse,
     * and every {@code core} fixture constructs it as {@code delayTicks * step}), so the rounding here
     * only ever undoes the single rounding step that produced it, never introduces a new one.
     *
     * <p>An entity with no {@link Trajectory} — an archetype whose {@code "motion"} spec was never
     * given, or a formation slot with a delay but a formation nobody attached a trajectory to — has
     * nothing to hold; the delay is simply inert for it, the same way {@code MotionSystem} already
     * leaves a {@code Trajectory} with no {@code Motion} alone.
     */
    private static void applySlotDelay(World world, int entity, FormationSlot slot, float step) {
        if (slot.delaySeconds() <= 0f) {
            return;
        }
        Trajectory trajectory = world.trajectories().get(entity);
        if (trajectory == null) {
            return;
        }
        trajectory.delayTicks = Math.round(slot.delaySeconds() / step);
    }

    private static void positionSpawned(
        World world, int entity, float anchorX, float lowestOffsetY, FormationSlot slot) {
        Collider collider = world.colliders().get(entity);
        float radius = collider == null ? 0f : collider.radius;
        float x = anchorX + slot.offsetX();
        // The slot at lowestOffsetY lands exactly at PLAYFIELD_HEIGHT + radius — its own radius
        // above the edge, tangent to it. Every other slot is further above by however much its
        // offsetY exceeds lowestOffsetY, so the whole formation clears the edge together.
        float y = PLAYFIELD_HEIGHT + radius + (slot.offsetY() - lowestOffsetY);
        world.transforms().set(entity, new Transform(x, y));
    }

    /**
     * One placement's wave, currently running: spawning what is due, or already past its last spawn
     * and only waiting on {@link WaveDefinition#endCondition()} to become true.
     */
    private static final class ActiveWave {

        final WaveDefinition definition;
        final float startTime;
        int cursor;
        int pickupCursor;

        ActiveWave(WaveDefinition definition, float startTime) {
            this.definition = definition;
            this.startTime = startTime;
        }
    }
}
