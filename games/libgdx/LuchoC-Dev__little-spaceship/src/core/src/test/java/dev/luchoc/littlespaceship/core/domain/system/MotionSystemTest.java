package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Trajectory;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.ArcTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.PathSegment;
import dev.luchoc.littlespaceship.core.port.PathTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class MotionSystemTest {

    private static final float STEP = 1f / 60f;

    private final TestBalance balance = new TestBalance();
    private final TestContent content = new TestContent(balance)
        .withTrajectory(new SimpleTrajectoryDefinition("steady-descent", 0f, -30f))
        .withTrajectory(new ArcTrajectoryDefinition("strike-run", 0f, -110f, 27f))
        .withTrajectory(new PathTrajectoryDefinition("enter-and-turn", List.of(
            new PathSegment(0f, -40f, 2f),
            new PathSegment(-30f, 0f, 3f))));
    private final World world = new World(content, new Rng(1), new GameEventQueue());
    private final MotionSystem system = new MotionSystem();

    @Test
    @DisplayName("keyboard and mouse pushing opposite ways leave the ship still")
    void oppositeDirectionsCancel() {
        int player = spawnPlayer(100f, 100f);

        // The adapter already summed keyboard and mouse before this frame reached the core; a
        // cancelling pair of devices is exactly a moveX/moveY of zero.
        system.update(world, STEP, new InputFrame(0f, 0f, false, false, false));

        Transform transform = world.transforms().get(player);
        assertEquals(100f, transform.x);
        assertEquals(100f, transform.y);
        Motion motion = world.motions().get(player);
        assertEquals(0f, motion.vx);
        assertEquals(0f, motion.vy);
    }

    @Test
    @DisplayName("a diagonal input is not faster than a single axis at the same intensity")
    void diagonalIsNotFasterThanAxis() {
        int player = spawnPlayer(100f, 100f);

        // Both inputs exceed the cap: a naive per-axis clamp would let the diagonal one keep an
        // extra factor of up to sqrt(2), which is exactly what the magnitude clamp forbids.
        system.update(world, STEP, new InputFrame(balance.playerSpeed, balance.playerSpeed, false, false, false));
        float diagonalSpeed = speedOf(player);

        resetPlayer(player, 100f, 100f);
        system.update(world, STEP, new InputFrame(balance.playerSpeed, 0f, false, false, false));
        float axisSpeed = speedOf(player);

        assertEquals(axisSpeed, diagonalSpeed, 0.001f);
        assertEquals(balance.playerSpeed, diagonalSpeed, 0.001f);
    }

    @Test
    @DisplayName("an input below the cap is not scaled up to it")
    void belowCapIsUntouched() {
        int player = spawnPlayer(100f, 100f);

        system.update(world, STEP, new InputFrame(10f, 0f, false, false, false));

        Motion motion = world.motions().get(player);
        assertEquals(10f, motion.vx);
        assertEquals(0f, motion.vy);
    }

    @Test
    @DisplayName("slow movement is the same clamp with a smaller cap, not a separate mode")
    void slowMovementReducesTheCap() {
        int player = spawnPlayer(100f, 100f);

        system.update(world, STEP, new InputFrame(balance.playerSpeed * 10f, 0f, false, true, false));

        Motion motion = world.motions().get(player);
        assertEquals(balance.playerSpeed * balance.playerSlowFactor, motion.vx, 0.001f);
    }

    @Test
    @DisplayName("the player cannot leave the playfield's width")
    void playerIsClampedToThePlayfield() {
        int player = spawnPlayer(2f, 100f);
        Collider collider = world.colliders().get(player);

        system.update(world, STEP, new InputFrame(-balance.playerSpeed, 0f, false, false, false));

        Transform transform = world.transforms().get(player);
        assertEquals(collider.radius, transform.x, 0.001f);
    }

    @Test
    @DisplayName("the player is clamped on the right edge too")
    void playerIsClampedOnTheRightEdge() {
        int player = spawnPlayer(MotionSystem.PLAYFIELD_WIDTH - 2f, 100f);
        Collider collider = world.colliders().get(player);

        system.update(world, STEP, new InputFrame(balance.playerSpeed, 0f, false, false, false));

        Transform transform = world.transforms().get(player);
        assertEquals(MotionSystem.PLAYFIELD_WIDTH - collider.radius, transform.x, 0.001f);
    }

    @Test
    @DisplayName("the player cannot fly off the top edge, even after many ticks of sustained input")
    void playerIsClampedOnTheTopEdge() {
        int player = spawnPlayer(100f, MotionSystem.PLAYFIELD_WIDTH / 2f);
        Collider collider = world.colliders().get(player);
        InputFrame upward = new InputFrame(0f, balance.playerSpeed, false, false, false);

        // A single tick would land well short of the edge; only sustained input over many ticks
        // reproduces the reported bug of the ship flying off-screen indefinitely.
        for (int i = 0; i < 600; i++) {
            system.update(world, STEP, upward);
        }

        Transform transform = world.transforms().get(player);
        assertEquals(SpawnSystem.PLAYFIELD_HEIGHT - collider.radius, transform.y, 0.001f);
    }

    @Test
    @DisplayName("the player cannot fly off the bottom edge, even after many ticks of sustained input")
    void playerIsClampedOnTheBottomEdge() {
        int player = spawnPlayer(100f, MotionSystem.PLAYFIELD_WIDTH / 2f);
        Collider collider = world.colliders().get(player);
        InputFrame downward = new InputFrame(0f, -balance.playerSpeed, false, false, false);

        for (int i = 0; i < 600; i++) {
            system.update(world, STEP, downward);
        }

        Transform transform = world.transforms().get(player);
        assertEquals(collider.radius, transform.y, 0.001f);
    }

    @Test
    @DisplayName("sustained input against the right edge still stops at the collider's radius")
    void playerIsClampedOnTheRightEdgeUnderSustainedInput() {
        int player = spawnPlayer(100f, 100f);
        Collider collider = world.colliders().get(player);
        InputFrame rightward = new InputFrame(balance.playerSpeed, 0f, false, false, false);

        for (int i = 0; i < 600; i++) {
            system.update(world, STEP, rightward);
        }

        Transform transform = world.transforms().get(player);
        assertEquals(MotionSystem.PLAYFIELD_WIDTH - collider.radius, transform.x, 0.001f);
    }

    @Test
    @DisplayName("enemies leave the playfield freely")
    void enemiesAreNotClamped() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(MotionSystem.PLAYFIELD_WIDTH - 1f, 100f));
        world.motions().set(enemy, new Motion(500f, 0f));

        system.update(world, STEP, InputFrame.IDLE);

        Transform transform = world.transforms().get(enemy);
        assertTrue(transform.x > MotionSystem.PLAYFIELD_WIDTH,
            "an enemy must be able to fly past the playfield's edge");
    }

    @Test
    @DisplayName("does nothing when there is no player entity")
    void noPlayerIsHarmless() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(10f, 10f));
        world.motions().set(enemy, new Motion(5f, 0f));

        system.update(world, STEP, new InputFrame(1f, 1f, false, false, false));

        assertEquals(10f + 5f * STEP, world.transforms().get(enemy).x, 0.001f);
    }

    @Test
    @DisplayName("does nothing when the player has no Motion component to drive")
    void playerWithoutMotionIsHarmless() {
        int player = world.createEntity();
        world.transforms().set(player, new Transform(50f, 50f));
        world.players().set(player, new Player(3, 2, 1));

        system.update(world, STEP, new InputFrame(1f, 1f, false, false, false));

        assertEquals(50f, world.transforms().get(player).x);
    }

    @Test
    @DisplayName("a trajectory's elapsed time accumulates from the fixed step, one tick at a time")
    void trajectoryElapsedAccumulatesFromTheFixedStep() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(50f, 200f));
        world.motions().set(enemy, new Motion(0f, -30f));
        Trajectory trajectory = new Trajectory("steady-descent");
        world.trajectories().set(enemy, trajectory);

        system.update(world, STEP, InputFrame.IDLE);
        assertEquals(STEP, trajectory.elapsed, 0.0001f);

        system.update(world, STEP, InputFrame.IDLE);
        assertEquals(STEP * 2f, trajectory.elapsed, 0.0001f);
    }

    @Test
    @DisplayName("a constant shape's re-evaluation each tick leaves its velocity unchanged")
    void constantShapeStaysConstantAcrossTicks() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(50f, 200f));
        world.motions().set(enemy, new Motion(0f, -30f));
        world.trajectories().set(enemy, new Trajectory("steady-descent"));

        for (int i = 0; i < 5; i++) {
            system.update(world, STEP, InputFrame.IDLE);
        }

        assertEquals(-30f, world.motions().get(enemy).vy, 0.0001f);
    }

    @Test
    @DisplayName("an arc shape is actually followed: velocity changes tick by tick and the path curves")
    void arcShapeIsFollowedAndCurves() {
        // strike-run: vx 0, vy -110, ay 27 — catalogue's own numbers, turns at t = 110/27 ~= 4.074s.
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(50f, 274f));
        world.motions().set(enemy, new Motion(0f, -110f));
        Trajectory trajectory = new Trajectory("strike-run");
        world.trajectories().set(enemy, trajectory);

        float previousY = world.transforms().get(enemy).y;
        float previousDelta = Float.NEGATIVE_INFINITY;
        boolean sawSignChange = false;
        int ticks = Math.round(5f / STEP);
        for (int i = 0; i < ticks; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            float y = world.transforms().get(enemy).y;
            float delta = y - previousY;
            // A straight line would keep this delta constant; an arc's delta itself changes every
            // tick, which is the closed form actually being evaluated rather than a stale snapshot.
            if (previousDelta != Float.NEGATIVE_INFINITY) {
                assertTrue(delta > previousDelta, "each tick's step should be less negative than the one before it, since ay > 0 keeps decelerating the descent");
            }
            if (delta > 0f) {
                sawSignChange = true;
            }
            previousDelta = delta;
            previousY = y;
        }

        // Closed form, not accumulation: at t = 5s, past the turn, verticalVelocityAt(5) = -110 + 27*5 = 25.
        assertEquals(-110f + 27f * 5f, world.motions().get(enemy).vy, 0.01f);
        assertTrue(sawSignChange, "the entity should climb back up after bottoming out, proving the path curves");
    }

    @Test
    @DisplayName("a path shape turns: horizontal velocity changes tick by tick, not just vertical")
    void pathShapeTurnsHorizontalVelocity() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(50f, 274f));
        world.motions().set(enemy, new Motion(0f, -40f));
        world.trajectories().set(enemy, new Trajectory("enter-and-turn"));

        // Still inside the first segment (2s at vx=0, vy=-40): horizontal velocity stays zero.
        for (int i = 0; i < Math.round(1f / STEP); i++) {
            system.update(world, STEP, InputFrame.IDLE);
        }
        assertEquals(0f, world.motions().get(enemy).vx, 0.0001f);
        assertEquals(-40f, world.motions().get(enemy).vy, 0.0001f);

        // Past the turn (2s mark): the second segment's horizontal velocity now applies.
        for (int i = 0; i < Math.round(1.5f / STEP); i++) {
            system.update(world, STEP, InputFrame.IDLE);
        }
        assertEquals(-30f, world.motions().get(enemy).vx, 0.0001f);
        assertEquals(0f, world.motions().get(enemy).vy, 0.0001f);
    }

    @Test
    @DisplayName("an entity with no Trajectory is unaffected by the advance")
    void entityWithoutTrajectoryIsHarmless() {
        int enemy = world.createEntity();
        world.transforms().set(enemy, new Transform(10f, 10f));
        world.motions().set(enemy, new Motion(5f, 0f));

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(10f + 5f * STEP, world.transforms().get(enemy).x, 0.001f);
    }

    private float speedOf(int entity) {
        Motion motion = world.motions().get(entity);
        return (float) Math.sqrt(motion.vx * motion.vx + motion.vy * motion.vy);
    }

    private void resetPlayer(int player, float x, float y) {
        Transform transform = world.transforms().get(player);
        transform.x = x;
        transform.y = y;
        Motion motion = world.motions().get(player);
        motion.vx = 0f;
        motion.vy = 0f;
    }

    private int spawnPlayer(float x, float y) {
        int player = world.createEntity();
        world.transforms().set(player, new Transform(x, y));
        world.motions().set(player, new Motion(0f, 0f));
        world.colliders().set(player, new Collider(4f, CollisionLayer.PLAYER));
        world.players().set(player, new Player(3, 2, 1));
        return player;
    }
}
