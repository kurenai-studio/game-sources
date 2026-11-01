package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEvent;
import dev.luchoc.littlespaceship.core.domain.system.GameSystem;
import dev.luchoc.littlespaceship.core.domain.system.SystemOrder;
import dev.luchoc.littlespaceship.core.domain.system.SystemPipeline;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * The determinism of a whole run, which is the invariant every replay rests on. The systems used
 * here belong to the test: what is being verified is the machinery, not the game rules, which do
 * not exist yet.
 */
class SimulationTest {

    private static final int TICKS = 600;

    @Test
    @DisplayName("the same seed and the same inputs produce the same final state")
    void isDeterministic() {
        List<InputFrame> script = script(TICKS);

        String first = fingerprintOf(run(42, script));
        String second = fingerprintOf(run(42, script));

        assertEquals(first, second);
    }

    @Test
    @DisplayName("a different seed produces a different final state")
    void seedChangesTheOutcome() {
        List<InputFrame> script = script(TICKS);

        assertNotEquals(fingerprintOf(run(42, script)), fingerprintOf(run(43, script)));
    }

    @Test
    @DisplayName("different inputs produce a different final state")
    void inputChangesTheOutcome() {
        List<InputFrame> script = script(TICKS);
        List<InputFrame> other = new ArrayList<>(script);
        other.set(100, new InputFrame(-1f, 1f, false, true, true));

        assertNotEquals(fingerprintOf(run(42, script)), fingerprintOf(run(42, other)));
    }

    @Test
    @DisplayName("the same run replayed through the loop matches the one ticked by hand")
    void loopAndDirectTicksAgree() {
        List<InputFrame> script = script(120);

        Simulation direct = simulation(42);
        for (InputFrame frame : script) {
            direct.tick(GameLoop.STEP, frame);
        }

        Simulation looped = simulation(42);
        GameLoop loop = new GameLoop(looped);
        for (InputFrame frame : script) {
            loop.advance(GameLoop.STEP, frame);
        }

        assertEquals(120, looped.tickCount());
        assertEquals(fingerprintOf(direct), fingerprintOf(looped));
    }

    @Test
    @DisplayName("events reach the sink once the tick is over, in order")
    void drainsEventsAfterTheTick() {
        List<GameEvent> received = new ArrayList<>();
        Simulation simulation = new Simulation(new TestContent(), received::add, 1,
            SystemPipeline.of(new Chatty()));

        simulation.tick(GameLoop.STEP, InputFrame.IDLE);
        simulation.tick(GameLoop.STEP, InputFrame.IDLE);

        assertEquals(2, received.size());
        assertEquals(new Chatty.Tick(1), received.get(0));
        assertEquals(new Chatty.Tick(2), received.get(1));
    }

    @Test
    @DisplayName("counts the ticks it has simulated")
    void countsTicks() {
        Simulation simulation = simulation(1);

        simulation.tick(GameLoop.STEP, InputFrame.IDLE);
        simulation.tick(GameLoop.STEP, InputFrame.IDLE);

        assertEquals(2, simulation.tickCount());
    }

    @Test
    @DisplayName("what it hands out can only be read")
    void exposesOnlyTheView() {
        Simulation simulation = run(7, script(60));

        List<String> drawn = new ArrayList<>();
        simulation.view().forEachSprite(
            (sprite, x, y, frame, rotation) -> drawn.add(sprite.value()));

        assertTrue(drawn.size() > 0, "the test systems should have spawned something");
    }

    @Test
    @DisplayName("rejects being assembled without its collaborators")
    void rejectsMissingCollaborators() {
        assertThrows(IllegalArgumentException.class,
            () -> new Simulation(null, event -> {
            }, 1));
        assertThrows(IllegalArgumentException.class,
            () -> new Simulation(new TestContent(), null, 1));
    }

    @Test
    @DisplayName("rejects a tick without an input frame")
    void rejectsMissingInput() {
        Simulation simulation = simulation(1);

        assertThrows(IllegalArgumentException.class, () -> simulation.tick(GameLoop.STEP, null));
    }

    private static Simulation simulation(int seed) {
        return new Simulation(new TestContent(), event -> {
        }, seed, SystemPipeline.of(new Spawner(), new Mover()));
    }

    private static Simulation run(int seed, List<InputFrame> script) {
        Simulation simulation = simulation(seed);
        for (InputFrame frame : script) {
            simulation.tick(GameLoop.STEP, frame);
        }
        return simulation;
    }

    /** A scripted sequence of inputs, built without randomness so it is the same in every run. */
    private static List<InputFrame> script(int ticks) {
        List<InputFrame> frames = new ArrayList<>(ticks);
        for (int tick = 0; tick < ticks; tick++) {
            float moveX = ((tick / 7) % 3) - 1f;
            float moveY = ((tick / 11) % 3) - 1f;
            frames.add(new InputFrame(moveX, moveY, tick % 5 == 0, tick % 13 == 0, tick % 97 == 0));
        }
        return frames;
    }

    /**
     * A textual snapshot of the whole world. Comparing strings and not floats is deliberate: a
     * difference of one bit has to fail, because one bit is all it takes for a replay to diverge.
     */
    private static String fingerprintOf(Simulation simulation) {
        World world = simulation.world();
        List<String> lines = new ArrayList<>();
        for (int i = 0; i < world.transforms().size(); i++) {
            int entity = world.transforms().entityAt(i);
            Transform transform = world.transforms().valueAt(i);
            Motion motion = world.motions().get(entity);
            lines.add(entity
                + " p " + Float.floatToIntBits(transform.x)
                + "," + Float.floatToIntBits(transform.y)
                + " v " + (motion == null ? "none"
                    : Float.floatToIntBits(motion.vx) + "," + Float.floatToIntBits(motion.vy)));
        }
        lines.sort(String::compareTo);
        return world.entityCount() + " entities\n" + String.join("\n", lines);
    }

    /** Creates entities out of the seeded generator, so the seed reaches the world state. */
    private static final class Spawner implements GameSystem {

        private static final SpriteId SPRITE = new SpriteId("test-entity");

        @Override
        public SystemOrder order() {
            return SystemOrder.SPAWN;
        }

        @Override
        public void update(World world, float step, InputFrame input) {
            if (world.rng().nextInt(4) != 0) {
                return;
            }
            int entity = world.createEntity();
            world.transforms().set(entity,
                new Transform(world.rng().nextFloat() * 208f, world.rng().nextFloat() * 270f));
            world.motions().set(entity,
                new Motion(world.rng().nextFloat() * 20f - 10f, world.rng().nextFloat() * -60f));
            world.sprites().set(entity, new Sprite(SPRITE));
        }
    }

    /** Moves what exists, so the input frames reach the world state too. */
    private static final class Mover implements GameSystem {

        @Override
        public SystemOrder order() {
            return SystemOrder.MOTION;
        }

        @Override
        public void update(World world, float step, InputFrame input) {
            for (int i = 0; i < world.motions().size(); i++) {
                int entity = world.motions().entityAt(i);
                Motion motion = world.motions().valueAt(i);
                Transform transform = world.transforms().get(entity);
                transform.x += (motion.vx + input.moveX() * 40f) * step;
                transform.y += (motion.vy + input.moveY() * 40f) * step;
            }
        }
    }

    /** Emits one event per tick, to check when the queue is drained. */
    private static final class Chatty implements GameSystem {

        private record Tick(int number) implements GameEvent {
        }

        private int ticks;

        @Override
        public SystemOrder order() {
            return SystemOrder.SCORE;
        }

        @Override
        public void update(World world, float step, InputFrame input) {
            world.events().emit(new Tick(++ticks));
        }
    }
}
