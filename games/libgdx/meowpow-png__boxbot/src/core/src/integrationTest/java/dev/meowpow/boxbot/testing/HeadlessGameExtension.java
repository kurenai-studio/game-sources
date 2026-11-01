package dev.meowpow.boxbot.testing;

import dev.meowpow.boxbot.BoxbotGame;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.input.GameActionDispatcher;
import dev.meowpow.boxbot.input.WorldClickDispatcher;
import dev.meowpow.boxbot.input.WorldHoverDispatcher;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.NoOpGameLogger;
import dev.meowpow.boxbot.render.screen.ScreenPresets;

import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.backends.headless.HeadlessApplication;
import com.badlogic.gdx.backends.headless.HeadlessApplicationConfiguration;

import org.junit.jupiter.api.extension.*;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/**
 * Boots a real {@link BoxbotGame} under
 * a headless libGDX backend before each test
 * and tears the application down afterward.
 * <p>
 * <strong>API Note:</strong>
 * libGDX's {@code Gdx} statics are process-wide,
 * so only one headless application can safely run at a time.
 * Tests using this extension must not run in parallel.
 */
public final class HeadlessGameExtension implements
        BeforeEachCallback, AfterEachCallback, ParameterResolver {

    private static final ExtensionContext.Namespace GAME_LOG_NAMESPACE =
            ExtensionContext.Namespace.create(HeadlessGameExtension.class, "gameLog");

    private static final long SHUTDOWN_TIMEOUT_SECONDS = 5;

    @Override
    public void beforeEach(ExtensionContext context) {
        context.getRoot().getStore(GAME_LOG_NAMESPACE).computeIfAbsent(
                GameLogInitializer.class
        );
        var clock = new SimulationClock();
        var actionDispatcher = new GameActionDispatcher();
        var clickDispatcher = new WorldClickDispatcher();
        var hoverDispatcher = new WorldHoverDispatcher();
        var inputProcessor = new InputMultiplexer();

        var game = new BoxbotGame(
                inputProcessor,
                ScreenPresets.SMALL,
                actionDispatcher,
                clickDispatcher,
                hoverDispatcher,
                clock,
                false
        );
        var shutdown = new CountDownLatch(1);
        var app = new HeadlessApplication(
                new ShutdownSignalingListener(game, shutdown),
                new HeadlessApplicationConfiguration()
        );
        var harness = new IntegrationHarness(
                game,
                clock,
                actionDispatcher,
                clickDispatcher,
                hoverDispatcher
        );
        var runningApp = new RunningApplication(app, shutdown, harness);
        RunningApplicationStore.put(context, runningApp);
    }

    /**
     * @throws IllegalStateException if it does not shut down within the timeout
     */
    @Override
    public void afterEach(ExtensionContext context) throws InterruptedException {
        var running = RunningApplicationStore.remove(context);
        if (running == null) {
            return;
        }
        running.app().exit();
        if (!running.shutdown().await(SHUTDOWN_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
            var message = "App did not shut down within " + SHUTDOWN_TIMEOUT_SECONDS + "s";
            throw new IllegalStateException(message);
        }
    }

    @Override
    public boolean supportsParameter(ParameterContext context, ExtensionContext ignored) {
        return context.getParameter().getType() == IntegrationHarness.class;
    }

    @Override
    public Object resolveParameter(ParameterContext ignored, ExtensionContext context) {
        var running = RunningApplicationStore.get(context);
        if (running == null) {
            var message = "No running headless application for this test";
            throw new ParameterResolutionException(message);
        }
        return running.harness();
    }

    /**
     * Initializes {@link GameLog} once for the whole test run.
     * <p>
     * <strong>Implementation Note:</strong>
     * {@code GameLog.init} throws if called more than once,
     * so this is created through {@code computeIfAbsent} on the
     * JUnit root store rather than directly in {@code beforeEach},
     * which would try to initialize it again for every test class.
     */
    private static final class GameLogInitializer {

        private GameLogInitializer() {
            GameLog.init(new NoOpGameLogger(), () -> 0L);
        }
    }
}
