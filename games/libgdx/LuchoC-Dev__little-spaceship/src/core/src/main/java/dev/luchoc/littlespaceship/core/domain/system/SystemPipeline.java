package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.port.InputFrame;

/**
 * The systems of a run, executed in the order declared by {@link SystemOrder}.
 *
 * <p>Registration order is irrelevant by design. Systems are placed in a slot per stage and run by
 * stage, so nobody can change the behaviour of the game by moving a line in the composition root.
 * Registering two systems in the same stage is rejected instead of silently keeping one of them.
 */
public final class SystemPipeline {

    private final GameSystem[] byStage;
    private final int registered;

    private SystemPipeline(GameSystem[] byStage, int registered) {
        this.byStage = byStage;
        this.registered = registered;
    }

    /**
     * Builds a pipeline out of the given systems, whatever order they come in.
     *
     * @param systems the systems of this run; none may be null
     * @return a pipeline that runs them in the canonical order
     * @throws IllegalArgumentException if two systems claim the same stage
     */
    public static SystemPipeline of(GameSystem... systems) {
        GameSystem[] byStage = new GameSystem[SystemOrder.values().length];
        int count = 0;
        for (GameSystem system : systems) {
            if (system == null) {
                throw new IllegalArgumentException("a system cannot be null");
            }
            int stage = system.order().ordinal();
            if (byStage[stage] != null) {
                throw new IllegalArgumentException(
                    "two systems claim the stage " + system.order() + ": "
                        + byStage[stage].getClass().getSimpleName() + " and "
                        + system.getClass().getSimpleName());
            }
            byStage[stage] = system;
            count++;
        }
        return new SystemPipeline(byStage, count);
    }

    /**
     * Runs every registered system, in the canonical order, exactly once.
     *
     * @param world the simulation state
     * @param step seconds elapsed, always the same fixed value
     * @param input what the player asked for this tick
     */
    public void run(World world, float step, InputFrame input) {
        for (GameSystem system : byStage) {
            if (system != null) {
                system.update(world, step, input);
            }
        }
    }

    /**
     * Returns how many systems are registered, which is at most one per stage.
     *
     * @return the number of registered systems
     */
    public int size() {
        return registered;
    }
}
