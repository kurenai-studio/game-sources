package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class SystemPipelineTest {

    private final List<SystemOrder> executed = new ArrayList<>();
    private final World world = new World(new TestContent(), new Rng(1), new GameEventQueue());

    /**
     * The order of the stages is a game rule. Collision before damage is what lets the defensive
     * priority live in one system; cleanup last is what keeps anything from reading a world that is
     * half destroyed. This test pins that order so changing it is a decision and not an accident.
     */
    @Test
    @DisplayName("the canonical order is the one the architecture decided")
    void canonicalOrder() {
        assertEquals(
            List.of(
                SystemOrder.INPUT,
                SystemOrder.MOTION,
                SystemOrder.WEAPON,
                SystemOrder.BOMB,
                SystemOrder.SPAWN,
                SystemOrder.SPAWNER,
                SystemOrder.ENEMY_WEAPON,
                SystemOrder.BOSS,
                SystemOrder.LIFETIME,
                SystemOrder.COLLISION,
                SystemOrder.DAMAGE,
                SystemOrder.PICKUP,
                SystemOrder.SCORE,
                SystemOrder.CLEANUP),
            List.of(SystemOrder.values()));
    }

    @Test
    @DisplayName("runs the systems in canonical order, whatever order they were registered in")
    void runsInCanonicalOrder() {
        SystemPipeline pipeline = SystemPipeline.of(
            new Recorder(SystemOrder.CLEANUP),
            new Recorder(SystemOrder.MOTION),
            new Recorder(SystemOrder.INPUT),
            new Recorder(SystemOrder.DAMAGE));

        pipeline.run(world, 1f / 60f, InputFrame.IDLE);

        assertEquals(
            List.of(SystemOrder.INPUT, SystemOrder.MOTION, SystemOrder.DAMAGE, SystemOrder.CLEANUP),
            executed);
    }

    @Test
    @DisplayName("runs each system exactly once per tick")
    void runsEachSystemOnce() {
        SystemPipeline pipeline = SystemPipeline.of(
            new Recorder(SystemOrder.INPUT),
            new Recorder(SystemOrder.MOTION));

        pipeline.run(world, 1f / 60f, InputFrame.IDLE);
        pipeline.run(world, 1f / 60f, InputFrame.IDLE);

        assertEquals(4, executed.size());
        assertEquals(2, pipeline.size());
    }

    @Test
    @DisplayName("skips the stages that have no system yet")
    void skipsEmptyStages() {
        SystemPipeline pipeline = SystemPipeline.of();

        pipeline.run(world, 1f / 60f, InputFrame.IDLE);

        assertTrue(executed.isEmpty());
        assertEquals(0, pipeline.size());
    }

    @Test
    @DisplayName("rejects two systems claiming the same stage")
    void rejectsDuplicateStage() {
        assertThrows(IllegalArgumentException.class, () -> SystemPipeline.of(
            new Recorder(SystemOrder.MOTION),
            new Recorder(SystemOrder.MOTION)));
    }

    @Test
    @DisplayName("rejects a null system")
    void rejectsNullSystem() {
        assertThrows(IllegalArgumentException.class,
            () -> SystemPipeline.of(new Recorder(SystemOrder.MOTION), null));
    }

    @Test
    @DisplayName("hands every system the same step and the same input frame")
    void handsOverStepAndInput() {
        List<Float> steps = new ArrayList<>();
        List<InputFrame> inputs = new ArrayList<>();
        InputFrame moving = new InputFrame(1f, 0f, true, false, false);
        GameSystem spy = new GameSystem() {
            @Override
            public SystemOrder order() {
                return SystemOrder.MOTION;
            }

            @Override
            public void update(World world, float step, InputFrame input) {
                steps.add(step);
                inputs.add(input);
            }
        };

        SystemPipeline.of(spy).run(world, 1f / 60f, moving);

        assertEquals(List.of(1f / 60f), steps);
        assertEquals(List.of(moving), inputs);
    }

    private final class Recorder implements GameSystem {

        private final SystemOrder stage;

        private Recorder(SystemOrder stage) {
            this.stage = stage;
        }

        @Override
        public SystemOrder order() {
            return stage;
        }

        @Override
        public void update(World world, float step, InputFrame input) {
            executed.add(stage);
        }
    }
}
