package dev.meowpow.boxbot.testing;

import dev.meowpow.boxbot.BoxbotGame;
import dev.meowpow.boxbot.render.screen.ScreenPresets;

import com.badlogic.gdx.ApplicationListener;
import com.badlogic.gdx.Gdx;

import java.util.concurrent.CountDownLatch;

/**
 * Delegates every {@link ApplicationListener} callback
 * to the real game. Signals {@code shutdown} once the
 * headless application's main loop has finished disposing it.
 * <p>
 * <strong>Implementation Note:</strong>
 * {@code HeadlessApplication.exit()} only schedules a shutdown; the
 * background loop thread calls {@link ApplicationListener#dispose()} asynchronously.
 * <p>
 * Hooking the latch here, rather than a {@code LifecycleListener},
 * guarantees the next test's {@code beforeEach} cannot start
 * until the game has fully released the Gdx statics.
 */
final class ShutdownSignalingListener implements ApplicationListener {

    private final BoxbotGame delegate;
    private final CountDownLatch shutdown;

    ShutdownSignalingListener(BoxbotGame delegate, CountDownLatch shutdown) {
        this.delegate = delegate;
        this.shutdown = shutdown;
    }

    @Override
    public void create() {
        // HeadlessApplication mocks Gdx.graphics/input/audio but leaves
        // Gdx.gl null; real asset loading needs it to be non-null.
        Gdx.gl = NoOpGL20.create();
        Gdx.gl20 = Gdx.gl;
        // Gdx.graphics.getWidth()/getHeight() are hardcoded to 0 headless;
        // ScreenLayout needs a real window size to match a known preset.
        Gdx.graphics = FixedSizeGraphics.wrap(
                Gdx.graphics,
                ScreenPresets.SMALL.width(),
                ScreenPresets.SMALL.height()
        );
        delegate.create();
    }

    @Override
    public void resize(int width, int height) {
        delegate.resize(width, height);
    }

    @Override
    public void render() {
        delegate.render();
    }

    @Override
    public void pause() {
        delegate.pause();
    }

    @Override
    public void resume() {
        delegate.resume();
    }

    @Override
    public void dispose() {
        delegate.dispose();
        shutdown.countDown();
    }
}
