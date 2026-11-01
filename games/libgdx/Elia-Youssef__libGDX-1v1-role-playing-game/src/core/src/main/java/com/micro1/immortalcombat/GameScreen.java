package com.micro1.immortalcombat;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.InputProcessor;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

import java.util.EnumMap;

/** Renders the character, maps user input to actions, and plays attack audio. */
public class GameScreen implements Screen {

    private static final float WORLD_WIDTH = 1280f;
    private static final float WORLD_HEIGHT = 720f;
    private static final float PLAYER_SIZE = 256f;
    private static final float PLAYER_CENTER_X = WORLD_WIDTH / 2f;
    private static final float PLAYER_CENTER_Y = WORLD_HEIGHT / 3f;

    private static final String CONTROLS =
        "A/D Move | S Crouch | W Jump | Space Block | Left click Punch | Right click Kick | Esc Exit";

    private final OrthographicCamera camera = new OrthographicCamera();
    private final Viewport viewport = new FitViewport(WORLD_WIDTH, WORLD_HEIGHT, camera);
    private final SpriteBatch batch = new SpriteBatch();
    private final BitmapFont font = new BitmapFont();
    private final Sound attackSound = Gdx.audio.newSound(Gdx.files.internal("woosh.wav"));
    private final Array<Texture> textures = new Array<Texture>();
    private final EnumMap<PlayerState, Animation<TextureRegion>> animations =
        new EnumMap<PlayerState, Animation<TextureRegion>>(PlayerState.class);
    private final TextureRegion[] jumpFrames;
    private final PlayerController controller;
    private final InputProcessor inputProcessor;

    private PlayerState lastLoggedState;

    public GameScreen() {
        font.setColor(0.12f, 0.12f, 0.12f, 1f);
        controller = new PlayerController(action -> attackSound.play());

        registerAnimation(PlayerState.IDLE, "idle", PlayerController.IDLE_FRAME);
        registerAnimation(PlayerState.FORWARD, "forward", PlayerController.FORWARD_FRAME);
        registerAnimation(PlayerState.BACKWARD, "backward", PlayerController.BACKWARD_FRAME);
        registerAnimation(PlayerState.PUNCH, "punch", PlayerController.PUNCH_FRAME);
        registerAnimation(PlayerState.KICK, "kick", PlayerController.KICK_FRAME);
        registerAnimation(PlayerState.BLOCK, "block", PlayerController.BLOCK_FRAME);
        registerAnimation(PlayerState.CROUCH, "crouch", PlayerController.CROUCH_FRAME);
        jumpFrames = loadFrames("jump");

        inputProcessor = createInputProcessor();
    }

    @Override
    public void show() {
        Gdx.input.setInputProcessor(inputProcessor);
    }

    @Override
    public void render(float delta) {
        updateHeldInputs();
        controller.update(delta);
        logStateChange();
        drawFrame();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void pause() {
        // No persistent simulation runs while the desktop window is paused.
    }

    @Override
    public void resume() {
        // Resources remain valid while this desktop application is paused.
    }

    @Override
    public void hide() {
        if (Gdx.input.getInputProcessor() == inputProcessor) {
            Gdx.input.setInputProcessor(null);
        }
    }

    @Override
    public void dispose() {
        hide();
        attackSound.dispose();
        font.dispose();
        batch.dispose();

        for (Texture texture : textures) {
            texture.dispose();
        }
        textures.clear();
    }

    private InputProcessor createInputProcessor() {
        return new InputAdapter() {
            @Override
            public boolean keyDown(int keycode) {
                if (keycode == Input.Keys.W) {
                    controller.pressJump();
                    return true;
                }
                if (keycode == Input.Keys.ESCAPE) {
                    Gdx.app.exit();
                    return true;
                }
                return false;
            }

            @Override
            public boolean touchDown(int screenX, int screenY, int pointer, int button) {
                if (button == Input.Buttons.LEFT) {
                    controller.pressPunch();
                    return true;
                }
                if (button == Input.Buttons.RIGHT) {
                    controller.pressKick();
                    return true;
                }
                return false;
            }
        };
    }

    private void updateHeldInputs() {
        controller.setForwardHeld(Gdx.input.isKeyPressed(Input.Keys.D));
        controller.setBackwardHeld(Gdx.input.isKeyPressed(Input.Keys.A));
        controller.setCrouchHeld(Gdx.input.isKeyPressed(Input.Keys.S));
        controller.setBlockHeld(Gdx.input.isKeyPressed(Input.Keys.SPACE));
    }

    private void logStateChange() {
        PlayerState currentState = controller.getCurrentState();
        if (currentState != lastLoggedState) {
            Gdx.app.log("Player", "playerCurrentState: " + currentState);
            lastLoggedState = currentState;
        }
    }

    private void drawFrame() {
        ScreenUtils.clear(1f, 1f, 1f, 1f);
        viewport.apply();
        batch.setProjectionMatrix(camera.combined);

        batch.begin();
        batch.draw(
            currentFrame(),
            PLAYER_CENTER_X - PLAYER_SIZE / 2f,
            PLAYER_CENTER_Y - PLAYER_SIZE / 2f,
            PLAYER_SIZE,
            PLAYER_SIZE
        );
        font.draw(batch, "Current action: " + controller.getCurrentState(), 24f, WORLD_HEIGHT - 20f);
        font.draw(batch, CONTROLS, 24f, 30f);
        batch.end();
    }

    private TextureRegion currentFrame() {
        PlayerState currentState = controller.getCurrentState();
        if (currentState == PlayerState.JUMP) {
            return jumpFrames[controller.jumpFrameIndex(controller.getOneShotElapsed())];
        }

        boolean looping = currentState != PlayerState.PUNCH && currentState != PlayerState.KICK;
        return animations.get(currentState).getKeyFrame(controller.getStateTime(), looping);
    }

    private void registerAnimation(PlayerState state, String assetPrefix, float frameDuration) {
        TextureRegion[] frames = loadFrames(assetPrefix);
        animations.put(
            state,
            new Animation<TextureRegion>(frameDuration, new Array<TextureRegion>(frames))
        );
    }

    private TextureRegion[] loadFrames(String assetPrefix) {
        TextureRegion[] frames = new TextureRegion[PlayerController.FRAMES_PER_ACTION];
        for (int index = 0; index < frames.length; index++) {
            Texture texture = new Texture(Gdx.files.internal(assetPrefix + "_" + index + ".png"));
            texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
            textures.add(texture);
            frames[index] = new TextureRegion(texture);
        }
        return frames;
    }
}
