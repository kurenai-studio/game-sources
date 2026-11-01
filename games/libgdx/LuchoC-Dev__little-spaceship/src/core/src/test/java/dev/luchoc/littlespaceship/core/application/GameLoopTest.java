package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.port.InputFrame;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class GameLoopTest {

    private final List<Float> steps = new ArrayList<>();
    private final GameLoop loop = new GameLoop((step, input) -> steps.add(step));

    @Test
    @DisplayName("every tick receives exactly the same step")
    void stepIsAlwaysTheSame() {
        loop.advance(0.05f, InputFrame.IDLE);

        assertTrue(steps.size() > 0);
        for (float step : steps) {
            assertEquals(GameLoop.STEP, step);
        }
    }

    @Test
    @DisplayName("one second of frames is one second of simulation, at any frame rate")
    void tickCountDoesNotDependOnFrameRate() {
        assertEquals(60, ticksForOneSecond(60), "at 60 fps");
        assertEquals(60, ticksForOneSecond(30), "at 30 fps");
        assertEquals(60, ticksForOneSecond(120), "at 120 fps");
        assertEquals(60, ticksForOneSecond(144), "at 144 fps");
        assertEquals(60, ticksForOneSecond(5), "at 5 fps, still under the clamp");
    }

    @Test
    @DisplayName("a frame shorter than a step runs nothing and keeps the time for later")
    void shortFramesAccumulate() {
        assertEquals(0, loop.advance(0.008f, InputFrame.IDLE));
        assertEquals(1, loop.advance(0.009f, InputFrame.IDLE));
    }

    @Test
    @DisplayName("leftover time is kept, never lost and never invented")
    void keepsLeftoverTime() {
        loop.advance(0.025f, InputFrame.IDLE);

        assertEquals(0.025f - GameLoop.STEP, loop.pendingTime(), 1e-6f);
    }

    /**
     * Without the clamp, a stall would produce a burst of ticks that takes even longer to simulate,
     * which makes the next frame worse. That is the spiral of death.
     */
    @Test
    @DisplayName("a stalled frame is clamped instead of unleashing a burst of ticks")
    void clampsLongFrames() {
        int ticks = loop.advance(10f, InputFrame.IDLE);

        assertEquals(15, ticks, "a quarter of a second is fifteen steps and not one more");
        assertTrue(ticks * GameLoop.STEP <= GameLoop.MAX_FRAME_TIME + GameLoop.STEP,
            "a stall must not produce " + ticks + " ticks");
    }

    @Test
    @DisplayName("counts every tick it has run")
    void countsTicks() {
        loop.advance(0.2f, InputFrame.IDLE);
        loop.advance(0.2f, InputFrame.IDLE);
        loop.advance(0.2f, InputFrame.IDLE);
        loop.advance(0.2f, InputFrame.IDLE);
        loop.advance(0.2f, InputFrame.IDLE);

        assertEquals(60, loop.totalTicks());
        assertEquals(60, steps.size());
    }

    /**
     * Above the clamp the loop stops honouring real time on purpose. Stating it as a test keeps it
     * from being read as a bug the first time someone measures it.
     */
    @Test
    @DisplayName("time above the clamp is dropped, not accumulated for later")
    void timeAboveTheClampIsDropped() {
        loop.advance(0.5f, InputFrame.IDLE);
        loop.advance(0.5f, InputFrame.IDLE);

        assertEquals(30, loop.totalTicks());
    }

    @Test
    @DisplayName("resetting drops the leftover time and the count")
    void resets() {
        loop.advance(0.025f, InputFrame.IDLE);

        loop.reset();

        assertEquals(0f, loop.pendingTime());
        assertEquals(0, loop.totalTicks());
    }

    @Test
    @DisplayName("every tick of a frame receives the frame that was sampled for it")
    void handsOverTheInputFrame() {
        List<InputFrame> seen = new ArrayList<>();
        GameLoop recording = new GameLoop((step, input) -> seen.add(input));
        InputFrame moving = new InputFrame(1f, 0f, true, false, false);

        recording.advance(0.055f, moving);

        assertEquals(3, seen.size());
        for (InputFrame frame : seen) {
            assertEquals(moving, frame);
        }
    }

    @Test
    @DisplayName("rejects a frame time that makes no sense")
    void rejectsInvalidFrameTime() {
        assertThrows(IllegalArgumentException.class, () -> loop.advance(-0.1f, InputFrame.IDLE));
        assertThrows(IllegalArgumentException.class,
            () -> loop.advance(Float.NaN, InputFrame.IDLE));
        assertThrows(IllegalArgumentException.class,
            () -> loop.advance(Float.POSITIVE_INFINITY, InputFrame.IDLE));
    }

    @Test
    @DisplayName("rejects a missing input frame")
    void rejectsMissingInput() {
        assertThrows(IllegalArgumentException.class, () -> loop.advance(0.016f, null));
    }

    @Test
    @DisplayName("rejects a loop with nothing to tick")
    void rejectsMissingTarget() {
        assertThrows(IllegalArgumentException.class, () -> new GameLoop(null));
    }

    private int ticksForOneSecond(int framesPerSecond) {
        GameLoop rateLoop = new GameLoop((step, input) -> {
        });
        float frameTime = 1f / framesPerSecond;
        for (int frame = 0; frame < framesPerSecond; frame++) {
            rateLoop.advance(frameTime, InputFrame.IDLE);
        }
        return rateLoop.totalTicks();
    }
}
