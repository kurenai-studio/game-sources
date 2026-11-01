package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.port.InputFrame;

/**
 * One rule of the game, applied to the whole world once per tick.
 *
 * <p>Systems hold no state of their own beyond the strictly necessary and consult no singletons:
 * everything they need arrives as an argument or hangs from the world. That is what allows any of
 * them to be instantiated in a test with fake dependencies and no framework at all.
 *
 * <p>The step is always the same value and the input frame is immutable. Neither of them is
 * negotiable: a system that read the clock, or that kept a reference to a mutable input, would
 * break replays without breaking any test.
 */
public interface GameSystem {

    /**
     * Says where in the fixed order this system runs. Two systems cannot share a stage.
     *
     * @return the stage this system belongs to
     */
    SystemOrder order();

    /**
     * Applies the rule to the world.
     *
     * @param world the simulation state, mutable from here
     * @param step seconds elapsed, always the same fixed value
     * @param input what the player asked for this tick, immutable
     */
    void update(World world, float step, InputFrame input);
}
