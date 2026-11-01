package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Trajectory;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.TrajectoryDefinition;

/**
 * Applies velocities to every entity, and turns the player's raw input vector into one.
 *
 * <p>The player's {@link Motion} is overwritten from {@link InputFrame} before the generic
 * integration runs, so both share one pass over the world. {@link InputFrame#moveX()} and {@link
 * InputFrame#moveY()} already carry the sum of every enabled device — that is the adapter's job, not
 * this system's — so what is left here is exactly the game rule the spec assigns to the simulation:
 * clamping the result to the ship's top speed.
 *
 * <p>The clamp is on the vector's magnitude, not per axis. Clamping each axis independently would
 * let a diagonal input, whose magnitude is larger by a factor of up to √2, end up faster than a
 * single axis at the same nominal intensity. A magnitude clamp forbids that by construction: whatever
 * direction the input points in, the result can never exceed the configured top speed.
 *
 * <p>Slow movement is the same clamp with a smaller cap — a multiplier, not a separate mode, per the
 * confirmed rule in {@code 02-mvp-functional-spec.md}.
 *
 * <p>This is also where an entity's {@link Trajectory} advances: {@link Trajectory#elapsed} is
 * incremented by the fixed step, once per tick, before velocities are integrated — never read from
 * the system clock, so a replay reproduces it exactly. The same pass then re-evaluates {@link
 * Trajectory#trajectoryId}'s velocity at that updated elapsed time and writes both components into
 * the entity's own {@link Motion}, so a shape whose velocity is a function of time — {@code arc} and,
 * since phase 11i, {@code path} — is actually followed tick after tick, not only snapshotted once at
 * spawn. The evaluation is each definition's own closed form — {@link
 * TrajectoryDefinition#horizontalVelocityAt(float)} and {@link
 * TrajectoryDefinition#verticalVelocityAt(float)} — computed from {@code elapsed} directly, never an
 * accumulation of per-tick deltas, which is what keeps it exact rather than drifting. A {@code
 * constant} or {@code arc} shape's {@code horizontalVelocityAt} ignores elapsed time and returns the
 * same value every tick — per {@code docs/plan/11c-movement-shapes/shape-catalogue.md}, horizontal
 * velocity never varies with time in either — so this re-evaluation is a no-op for both and changes
 * nothing about the shapes that shipped before {@code path} existed.
 */
public final class MotionSystem implements GameSystem {

    /**
     * Width of the playfield, in logical units. {@code CLAUDE.md} states it flatly as one of the
     * project's invariants; {@code 10-mvp-initial-values.md} calls the same number, together with
     * the 480×270 logical resolution it lives inside, a "proposed starting point" whose "definitive
     * value is set during the technical prototype" — which {@code 11-technical-prototype-results.md}
     * records as done, confirming 208 as the starting point. It is a fixed dimension of the logical
     * resolution, not a balance value that changes with difficulty, so it lives here rather than in
     * {@code BalanceValues}.
     */
    public static final float PLAYFIELD_WIDTH = 208f;

    @Override
    public SystemOrder order() {
        return SystemOrder.MOTION;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        applyPlayerInput(world, input);
        advanceTrajectories(world, step);
        integrate(world, step);
        clampPlayerToPlayfield(world);
    }

    /**
     * Accumulates the fixed step into every entity's {@link Trajectory#elapsed}, then re-evaluates
     * {@link Trajectory#trajectoryId}'s velocity at that updated elapsed time and writes both
     * components into the entity's own {@link Motion} — before {@link #integrate} runs, so this
     * tick's integration already uses this tick's velocity. An entity with a {@link Trajectory} but
     * no {@link Motion} is left alone: nothing to write the evaluated velocity into, and nothing in
     * the catalogue attaches one without the other.
     *
     * <p><b>Issue #330 — a formation slot delayed in time.</b> {@code SpawnSystem} sets a delayed
     * slot's {@link Trajectory#delayTicks} to the number of ticks it should hold still at spawn.
     * While {@code delayTicks} is still positive, the entity is <em>present</em> (it has a {@code
     * Transform}, a {@code Collider}, a {@code WaveOrigin}: it can be hit, it counts against a
     * {@code cleared} wave, the safety box can see it) but holds perfectly still, {@link Motion#vx}
     * and {@link Motion#vy} pinned to zero, and {@code delayTicks} decrements by exactly one — never
     * touching {@link Trajectory#elapsed}, which stays at its starting {@code 0} for as long as the
     * countdown runs. That is the decision this issue asked to be made and pinned: a delayed slot
     * exists from tick zero, it simply does not move yet. The alternative — not existing until the
     * delay elapses — would need a second spawn-scheduling mechanism alongside {@code SpawnSystem}'s
     * own wave timeline, and invariant 6's "no abstraction without a case" refuses exactly that for
     * the one column this issue asks for.
     *
     * <p><b>Issue #337 correction.</b> The original design compared {@link Trajectory#elapsed}
     * against zero to decide the crossing, backdating it to {@code -delaySeconds} and holding the
     * entity still while {@code elapsed <= 0f}. That held-branch predicate was a float comparison
     * between two different arithmetic paths to the same target value — the delay itself, formed by a
     * single multiplication, against {@code elapsed}'s own repeated addition of {@code step} — and
     * those do not generally agree bit-for-bit. Swept over delays of 1..300 ticks, about a fifth of
     * them (the bands 18–40 and 258–300) crossed zero one tick earlier than the delay actually called
     * for, permanently misaligning the traced path. Counting down an integer {@code delayTicks}
     * instead removes the float entirely from the decision: the countdown reaches exactly zero after
     * exactly {@code delayTicks} ticks, with no accumulation and no comparison against a target that
     * could itself carry rounding error.
     *
     * <p>Once {@code delayTicks} reaches zero, {@code elapsed} begins accumulating from {@code 0} the
     * same way an undelayed entity's always has, so a slot delayed by exactly {@code N} ticks
     * reproduces, from tick {@code N} onward, the identical sequence of velocity evaluations — and
     * therefore the identical sequence of Euler integration steps in {@link #integrate} — that the
     * undelayed slot produced from tick zero. A slot with no delay is entirely unaffected: its {@code
     * delayTicks} starts at {@code 0}, so this branch never fires for it and {@code elapsed}
     * accumulates on the very first tick exactly as it always did — which is what keeps every
     * formation that predates this issue byte-for-byte identical.
     */
    private static void advanceTrajectories(World world, float step) {
        ComponentStore<Trajectory> trajectories = world.trajectories();
        ComponentStore<Motion> motions = world.motions();
        ContentSource content = world.content();
        for (int i = 0; i < trajectories.size(); i++) {
            int entity = trajectories.entityAt(i);
            Trajectory trajectory = trajectories.valueAt(i);
            Motion motion = motions.get(entity);
            if (trajectory.delayTicks > 0) {
                trajectory.delayTicks--;
                if (motion != null) {
                    motion.vx = 0f;
                    motion.vy = 0f;
                }
                continue;
            }
            trajectory.elapsed += step;
            if (motion == null) {
                continue;
            }
            TrajectoryDefinition definition = content.trajectory(trajectory.trajectoryId);
            motion.vx = definition.horizontalVelocityAt(trajectory.elapsed);
            motion.vy = definition.verticalVelocityAt(trajectory.elapsed);
        }
    }

    private static void applyPlayerInput(World world, InputFrame input) {
        int player = world.playerEntity();
        if (player == EntityId.NONE) {
            return;
        }
        Motion motion = world.motions().get(player);
        if (motion == null) {
            // The composition root did not attach a Motion to the player: nothing to drive.
            return;
        }
        BalanceValues balance = world.content().balance();
        float cap = balance.playerSpeed() * (input.slow() ? balance.playerSlowFactor() : 1f);
        setClamped(motion, input.moveX(), input.moveY(), cap);
    }

    private static void setClamped(Motion motion, float x, float y, float cap) {
        float lengthSquared = x * x + y * y;
        float capSquared = cap * cap;
        if (lengthSquared > capSquared && lengthSquared > 0f) {
            float scale = cap / (float) Math.sqrt(lengthSquared);
            x *= scale;
            y *= scale;
        }
        motion.vx = x;
        motion.vy = y;
    }

    private static void integrate(World world, float step) {
        ComponentStore<Motion> motions = world.motions();
        ComponentStore<Transform> transforms = world.transforms();
        for (int i = 0; i < motions.size(); i++) {
            int entity = motions.entityAt(i);
            Motion motion = motions.valueAt(i);
            Transform transform = transforms.get(entity);
            if (transform == null) {
                continue;
            }
            transform.x += motion.vx * step;
            transform.y += motion.vy * step;
        }
    }

    /**
     * Keeps the player inside the playfield on both axes, collider edge against the boundary rather
     * than the ship's centre. Enemies leave freely, which is why this only ever touches the player's
     * entity. {@code 01-vision-and-scope.md} describes "free ship movement inside the playable area"
     * with no separate zone for the top edge, so the vertical bound uses the full {@link
     * SpawnSystem#PLAYFIELD_HEIGHT}, symmetric with the x clamp below rather than some narrower band
     * near the bottom where the ship merely starts.
     */
    private static void clampPlayerToPlayfield(World world) {
        int player = world.playerEntity();
        if (player == EntityId.NONE) {
            return;
        }
        Transform transform = world.transforms().get(player);
        if (transform == null) {
            return;
        }
        Collider collider = world.colliders().get(player);
        float margin = collider == null ? 0f : collider.radius;
        transform.x = clamp(transform.x, margin, PLAYFIELD_WIDTH - margin);
        transform.y = clamp(transform.y, margin, SpawnSystem.PLAYFIELD_HEIGHT - margin);
    }

    private static float clamp(float value, float min, float max) {
        if (value < min) {
            return min;
        }
        if (value > max) {
            return max;
        }
        return value;
    }
}
