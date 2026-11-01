package dev.luchoc.littlespaceship.core.port;

/**
 * Read-only window onto the simulation, for whoever has to draw it.
 *
 * <p>The presentation layer never touches the ECS: it does not know entities, components or stores
 * exist. It asks this view, and what comes back is either a primitive or another contract. That is
 * what allows the internals to change without the renderer noticing.
 *
 * <p>The view grows with the simulation. The boss status arrives with phase 07, which is what
 * creates a boss to report on; adding it now would mean inventing what it reports.
 */
public interface WorldView {

    /**
     * Walks every entity that has to be drawn.
     *
     * @param visitor receives each entity; never null
     */
    void forEachSprite(SpriteVisitor visitor);

    /**
     * Reads the player's current state, for the HUD.
     *
     * @return a snapshot of the player's status, or {@link PlayerStatus#NONE} if no entity holds
     *     {@code Player} — never the case once a run has started, since the player's ship exists
     *     from the first tick
     */
    PlayerStatus player();

    /**
     * Reads whether the current run is still going, and how it ended if it is not.
     *
     * @return the run's outcome so far
     */
    LevelOutcome outcome();

    /**
     * Reads the end-of-level bonus the player would earn from lives and bombs currently held.
     *
     * @return the completion bonus, split into its lives and bombs components
     */
    CompletionBonus completionBonus();

    /**
     * Reads the boss's aggregate health, for the health bar {@code docs/design/04-hud-layout.md}
     * shows only during the fight.
     *
     * @return the boss's status, or {@link BossStatus#NONE} before it spawns, after it is defeated,
     *     or on a level with no boss
     */
    BossStatus bossStatus();
}
