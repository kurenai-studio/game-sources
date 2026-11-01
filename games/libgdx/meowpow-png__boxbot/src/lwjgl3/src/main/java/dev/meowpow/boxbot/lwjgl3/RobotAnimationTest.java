package dev.meowpow.boxbot.lwjgl3;

import dev.meowpow.boxbot.engine.robot.RobotAction;
import dev.meowpow.boxbot.engine.robot.RobotAnimationController;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.Slf4jGameLogger;

import org.jspecify.annotations.NullUnmarked;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;

/**
 * Standalone window that plays the robot's animation
 * clips in isolation, alternating actions, for visually
 * verifying clip playback without running the full simulation.
 */
@NullUnmarked
public final class RobotAnimationTest extends ApplicationAdapter {

    private static final int WINDOW_SIZE = 256;
    private static final float ACTION_SWITCH_SECONDS = 2f;

    private TextureAtlas atlas;
    private SpriteBatch batch;
    private OrthographicCamera camera;
    private RobotAnimationController animation;

    private float actionTimer;
    private boolean moving = true;

    public static void main(String[] args) {
        GameLog.init(new Slf4jGameLogger(), new SimulationClock()::currentTick);
        var config = new Lwjgl3ApplicationConfiguration();

        config.setTitle("Robot Animation Test");
        config.setWindowedMode(WINDOW_SIZE, WINDOW_SIZE);
        config.setResizable(false);

        new Lwjgl3Application(new RobotAnimationTest(), config);
    }

    @Override
    public void create() {
        atlas = new TextureAtlas(Gdx.files.internal("atlas/sprites.atlas"));
        batch = new SpriteBatch();
        camera = new OrthographicCamera(WINDOW_SIZE, WINDOW_SIZE);
        camera.position.set(WINDOW_SIZE / 2f, WINDOW_SIZE / 2f, 0);
        camera.update();

        animation = new RobotAnimationController(atlas);
        animation.setAction(RobotAction.MOVING);
    }

    @Override
    public void render() {
        float delta = Gdx.graphics.getDeltaTime();

        actionTimer += delta;
        if (actionTimer >= ACTION_SWITCH_SECONDS) {
            actionTimer = 0f;
            moving = !moving;
            animation.setAction(moving ? RobotAction.MOVING : RobotAction.IDLE);
        }
        animation.update(delta);

        Gdx.gl.glClearColor(0.15f, 0.15f, 0.15f, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        var sprite = animation.frame();

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        batch.draw(sprite.region(), 0, 0, WINDOW_SIZE, WINDOW_SIZE);
        batch.end();
    }

    @Override
    public void dispose() {
        batch.dispose();
        atlas.dispose();
    }
}
