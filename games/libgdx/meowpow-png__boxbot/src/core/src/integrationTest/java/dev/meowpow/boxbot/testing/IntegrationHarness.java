package dev.meowpow.boxbot.testing;

import dev.meowpow.boxbot.BoxbotGame;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.input.GameActionDispatcher;
import dev.meowpow.boxbot.input.WorldClickDispatcher;
import dev.meowpow.boxbot.input.WorldHoverDispatcher;

/**
 * A running {@link BoxbotGame} under a headless backend.
 *
 * @param game the running game
 * @param clock the game's simulation clock
 * @param actionDispatcher dispatcher for player-triggered actions
 * @param clickDispatcher dispatcher for clicks in the world
 * @param hoverDispatcher dispatcher for pointer movement in the world
 */
public record IntegrationHarness(
        BoxbotGame game,
        SimulationClock clock,
        GameActionDispatcher actionDispatcher,
        WorldClickDispatcher clickDispatcher,
        WorldHoverDispatcher hoverDispatcher
) {}
