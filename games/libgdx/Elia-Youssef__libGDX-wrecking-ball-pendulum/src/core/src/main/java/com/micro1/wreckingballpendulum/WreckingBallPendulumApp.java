package com.micro1.wreckingballpendulum;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

public class WreckingBallPendulumApp extends ApplicationAdapter {

    private static final Color BACKGROUND_COLOR = Color.WHITE;
    private static final Color FLOOR_COLOR = Color.valueOf("B3B3B3");
    private static final Color BOOM_COLOR = Color.valueOf("707070");
    private static final Color BLOCK_COLOR = Color.valueOf("777777");
    private static final Color ROPE_COLOR = Color.BLACK;
    private static final Color BALL_COLOR = Color.BLACK;

    private static final float BOOM_THICKNESS_PX = 5f;

    private WreckingBallWorld world;
    private ShapeRenderer renderer;
    private OrthographicCamera camera;

    @Override
    public void create() {
        world = new WreckingBallWorld();
        renderer = new ShapeRenderer();
        camera = new OrthographicCamera();
        camera.setToOrtho(false, WreckingBallWorld.SCREEN_WIDTH_PX, WreckingBallWorld.SCREEN_HEIGHT_PX);
        camera.update();
    }

    @Override
    public void render() {
        boolean leftHeld = Gdx.input.isKeyPressed(Input.Keys.LEFT);
        boolean rightHeld = Gdx.input.isKeyPressed(Input.Keys.RIGHT);
        boolean releasePressed = Gdx.input.isKeyJustPressed(Input.Keys.SPACE);
        world.update(Gdx.graphics.getDeltaTime(), leftHeld, rightHeld, releasePressed);

        Gdx.gl.glClearColor(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        renderer.setProjectionMatrix(camera.combined);

        renderer.begin(ShapeRenderer.ShapeType.Filled);
        renderer.setColor(FLOOR_COLOR);
        renderer.rect(0f, 0f, WreckingBallWorld.SCREEN_WIDTH_PX, WreckingBallWorld.getFloorHeightPx());

        float blockSize = WreckingBallWorld.getBlockSizePx();
        float blockHalf = blockSize / 2f;
        renderer.setColor(BLOCK_COLOR);
        renderer.rect(
                world.getBlockCenterXPx() - blockHalf, world.getBlockCenterYPx() - blockHalf,
                blockHalf, blockHalf,
                blockSize, blockSize,
                1f, 1f,
                world.getBlockAngleDeg());

        renderer.setColor(BOOM_COLOR);
        renderer.rect(
                world.getBoomXPx() - BOOM_THICKNESS_PX / 2f, world.getBoomBottomYPx(),
                BOOM_THICKNESS_PX, world.getBoomTopYPx() - world.getBoomBottomYPx());

        renderer.setColor(BALL_COLOR);
        renderer.circle(world.getBallCenterXPx(), world.getBallCenterYPx(), WreckingBallWorld.getBallRadiusPx(), 32);

        if (world.isRopeAttached()) {
            renderer.setColor(ROPE_COLOR);
            renderer.rectLine(
                    world.getBoomXPx(), world.getBoomBottomYPx(),
                    world.getBallCenterXPx(), world.getBallTopYPx(),
                    1f);
        }
        renderer.end();
    }

    @Override
    public void dispose() {
        if (renderer != null) {
            renderer.dispose();
        }
        if (world != null) {
            world.dispose();
        }
    }
}
