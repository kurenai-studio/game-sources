package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Disposable;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;

public final class PlayerRenderer implements Disposable {
    private static final float FOOT_OFFSET = 11f;
    private static final float RUN_FRAME_RATE = 10f;
    private static final float DASH_FRAME_RATE = 14f;

    private enum Pose {
        HURT,
        DASH,
        SPECIAL,
        AIR_SHOOT,
        RUN_SHOOT,
        SHOOT,
        JUMP,
        RUN,
        IDLE
    }

    private final Texture spriteSheet;
    private final Texture movementSheet;
    private final TextureRegion shootFrame;
    private final TextureRegion jumpFrame;
    private final TextureRegion[] runFrames;
    private final TextureRegion hurtFrame;
    private final TextureRegion airShootFrame;
    private final TextureRegion[] runShootFrames;
    private final TextureRegion specialFrame;
    private final TextureRegion idleFrame;

    public PlayerRenderer() {
        spriteSheet = TextureLoader.loadLinear("sprites/player/clock_player_sheet.png");
        movementSheet = TextureLoader.loadLinear("sprites/player/clock_player_movement_sheet.png");
        shootFrame = frame(0, 0, 271, 271);
        jumpFrame = frame(271, 0, 234, 265);
        runFrames = new TextureRegion[] {
                movementFrame(0, 0),
                movementFrame(1, 0),
                movementFrame(2, 0),
                movementFrame(3, 0)
        };
        hurtFrame = frame(505, 0, 267, 291);
        airShootFrame = frame(0, 291, 273, 245);
        runShootFrames = new TextureRegion[] {
                movementFrame(0, 1),
                movementFrame(1, 1),
                movementFrame(2, 1),
                movementFrame(3, 1)
        };
        specialFrame = frame(273, 291, 195, 260);
        idleFrame = frame(468, 291, 191, 254);
    }

    public void renderShadow(ShapeRenderer shapeRenderer, Player player) {
        float airHeight = Math.max(0f, player.getY() - Constants.FLOOR_Y);
        float groundCloseness = MathUtils.clamp(1f - airHeight / 280f, 0.34f, 1f);
        float width = 72f * groundCloseness;
        float height = 15f * groundCloseness;
        float alpha = 0.28f * groundCloseness;
        shapeRenderer.setColor(0.04f, 0.025f, 0.018f, alpha);
        shapeRenderer.ellipse(player.getCenterX() - width * 0.5f, Constants.FLOOR_Y - 9f, width, height);
    }

    public void render(SpriteBatch batch, OrthographicCamera camera, Player player) {
        if (!player.shouldRenderSprite()) {
            return;
        }

        Pose pose = selectPose(player);
        TextureRegion frame = frameForPose(player, pose);
        float poseHeight = heightForPose(pose);
        float poseWidth = poseHeight * frame.getRegionWidth() / frame.getRegionHeight();
        float idleBreath = pose == Pose.IDLE ? MathUtils.sin(player.getAnimationTime() * 2.2f) : 0f;
        float squashX = pose == Pose.DASH
                ? 1.06f
                : 1f + idleBreath * 0.004f;
        float squashY = pose == Pose.DASH
                ? 0.96f
                : 1f - idleBreath * 0.003f;
        float rotation = pose == Pose.HURT
                ? -player.getFacingDirection() * 5f
                : 0f;
        float drawX = player.getCenterX() - poseWidth * 0.5f;
        float drawY = player.getY() - FOOT_OFFSET;

        Texture frameTexture = frame.getTexture();

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        if (pose == Pose.HURT) {
            batch.setColor(1f, 0.88f, 0.86f, 1f);
        }
        batch.draw(frameTexture,
                drawX, drawY,
                poseWidth * 0.5f, FOOT_OFFSET,
                poseWidth, poseHeight,
                squashX, squashY,
                rotation,
                frame.getRegionX(), frame.getRegionY(),
                frame.getRegionWidth(), frame.getRegionHeight(),
                shouldFlip(player, pose), false);
        batch.setColor(Color.WHITE);
        batch.end();
    }

    @Override
    public void dispose() {
        spriteSheet.dispose();
        movementSheet.dispose();
    }

    private TextureRegion frame(int x, int y, int width, int height) {
        return new TextureRegion(spriteSheet, x, y, width, height);
    }

    private TextureRegion movementFrame(int column, int row) {
        return new TextureRegion(movementSheet, column * 640, row * 512, 640, 512);
    }

    private Pose selectPose(Player player) {
        if (player.isHurtPoseActive()) {
            return Pose.HURT;
        }
        if (player.isSpecialPoseActive()) {
            return Pose.SPECIAL;
        }
        if (player.isShootPoseActive()) {
            if (player.isAirborne()) {
                return Pose.AIR_SHOOT;
            }
            if (player.isMovingHorizontally()) {
                return Pose.RUN_SHOOT;
            }
            return Pose.SHOOT;
        }
        if (player.isDashing()) {
            return Pose.DASH;
        }
        if (player.isAirborne()) {
            return Pose.JUMP;
        }
        if (player.isMovingHorizontally()) {
            return Pose.RUN;
        }
        return Pose.IDLE;
    }

    private TextureRegion frameForPose(Player player, Pose pose) {
        return switch (pose) {
            case HURT -> hurtFrame;
            case DASH -> animationFrame(runFrames, player.getAnimationTime(), DASH_FRAME_RATE);
            case RUN -> animationFrame(runFrames, player.getAnimationTime(), RUN_FRAME_RATE);
            case SPECIAL -> specialFrame;
            case AIR_SHOOT -> airShootFrame;
            case RUN_SHOOT -> animationFrame(runShootFrames, player.getAnimationTime(), RUN_FRAME_RATE);
            case SHOOT -> shootFrame;
            case JUMP -> jumpFrame;
            case IDLE -> idleFrame;
        };
    }

    private TextureRegion animationFrame(TextureRegion[] frames, float animationTime, float frameRate) {
        int index = (int) (animationTime * frameRate) % frames.length;
        return frames[index];
    }

    private float heightForPose(Pose pose) {
        return switch (pose) {
            case HURT, AIR_SHOOT -> 128f;
            case DASH, RUN, RUN_SHOOT -> 136f;
            case SPECIAL, SHOOT, IDLE -> 126f;
            case JUMP -> 132f;
        };
    }

    private boolean shouldFlip(Player player, Pose pose) {
        return switch (pose) {
            case HURT, SHOOT, AIR_SHOOT, JUMP -> player.getFacingDirection() > 0;
            case DASH, RUN, RUN_SHOOT, SPECIAL, IDLE -> player.getFacingDirection() < 0;
        };
    }

}
