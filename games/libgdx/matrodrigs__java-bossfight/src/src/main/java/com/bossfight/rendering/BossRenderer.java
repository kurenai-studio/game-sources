package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Disposable;
import com.bossfight.boss.Boss;
import com.bossfight.boss.BossVisualState;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;

public final class BossRenderer implements Disposable {
    private static final int SHEET_COLUMNS = 4;
    private static final int SHEET_ROWS = 2;
    private static final int INTRO_FRAME_INDEX = 0;
    private static final int IDLE_SIDE_FRAME_INDEX = 1;
    private static final int IDLE_FORWARD_FRAME_INDEX = 2;
    private static final int MAGIC_FRAME_INDEX = 3;
    private static final int VINE_FRAME_INDEX = 4;
    private static final int POLLEN_BREATH_FRAME_INDEX = 5;
    private static final int POLLEN_RAIN_FRAME_INDEX = 6;
    private static final int DEFEATED_FRAME_INDEX = 7;
    private static final int FORWARD_RIGHT_TRIM = 24;
    private static final int MAGIC_LEFT_EXTENSION = 20;
    private static final float FRAME_ASPECT_RATIO = 3f / 4f;
    private static final float IDLE_BREATH_FREQUENCY = 2.5f;
    private static final float ATTACK_PULSE_FREQUENCY = 7.2f;
    private static final float MAGIC_SWAY_FREQUENCY = 5.4f;
    private static final float POLLEN_RAIN_SWAY_FREQUENCY = 6.2f;
    private static final float CONTINUOUS_MOTION_SCALE = 0.5f;
    private static final float ATTACK_IMPULSE_SCALE = 0.55f;
    private static final float POLLEN_RAIN_VERTICAL_SWAY = 4f;
    private static final float POLLEN_RAIN_ATTACK_LIFT = 3.5f;
    private static final float ENRAGE_VERTICAL_SWAY = 4f;
    private static final float BASIC_RECOIL_X = 8f;
    private static final float BASIC_SQUASH_X = 0.014f;
    private static final float BASIC_STRETCH_Y = 0.020f;
    private static final float BASIC_REACTION_ROTATION = 1.5f;
    private static final float SPECIAL_RECOIL_X = 28f;
    private static final float SPECIAL_SQUASH_Y = 16f;
    private static final float SPECIAL_REACTION_ROTATION = 5.5f;
    private static final float DEFEATED_INITIAL_FRAME_DURATION = 0.18f;
    private static final float DEFEATED_ANIMATION_FPS = 2f;
    private static final AnimationSpec MAGIC_ANIMATION = new AnimationSpec(MAGIC_FRAME_INDEX, 11f);
    private static final AnimationSpec VINE_ANIMATION = new AnimationSpec(VINE_FRAME_INDEX, 14f);
    private static final AnimationSpec POLLEN_BREATH_ANIMATION =
            new AnimationSpec(POLLEN_BREATH_FRAME_INDEX, 13f);
    private static final AnimationSpec POLLEN_RAIN_ANIMATION = new AnimationSpec(POLLEN_RAIN_FRAME_INDEX, 12f);
    private static final PhaseTint PHASE_TWO_TINT = new PhaseTint(0.78f, 0.68f);
    private static final PhaseTint FINAL_RAGE_TINT = new PhaseTint(0.56f, 0.44f);

    private final Texture spriteSheet;
    private final TextureRegion[] frames;
    private final Texture inbetweenSheet;
    private final TextureRegion[] inbetweenFrames;

    private record AnimationSpec(int frameIndex, float framesPerSecond) {
    }

    private record PhaseTint(float green, float blue) {
    }

    private record AnimationSignals(
            BossVisualState state,
            boolean defeated,
            float stateTime,
            float breath,
            float windup,
            float actionKick,
            float actionFollowThrough,
            float hitKick,
            float specialKick,
            float attackPulse
    ) {
        private boolean is(BossVisualState expectedState) {
            return state == expectedState;
        }
    }

    private record BossPose(
            TextureRegion frame,
            float x,
            float y,
            float width,
            float height,
            float scaleX,
            float scaleY,
            float rotation,
            float hitKick,
            float specialKick,
            boolean flipX
    ) {
    }

    public BossRenderer() {
        spriteSheet = TextureLoader.loadLinear("sprites/boss/flower_boss_sheet.png");
        frames = splitFrames(spriteSheet);
        inbetweenSheet = TextureLoader.loadLinear("sprites/boss/flower_boss_inbetweens.png");
        inbetweenFrames = splitFrames(inbetweenSheet);
    }

    public void renderShadow(ShapeRenderer shapeRenderer, Boss boss) {
        float width = 330f;
        shapeRenderer.setColor(0.04f, 0.02f, 0.02f, 0.38f);
        shapeRenderer.ellipse(boss.getCenterX() - width * 0.5f - 16f, Constants.FLOOR_Y - 16f, width, 42f);
    }

    public void renderTelegraphGlow(ShapeRenderer shapeRenderer, Boss boss) {
        if (!boss.isTelegraphing() || boss.isDefeated()) {
            return;
        }

        float alpha = boss.getTelegraphAlpha();
        boolean enraging = boss.getVisualState() == BossVisualState.ENRAGING;
        float pulse = 0.5f + MathUtils.sin(boss.getVisualStateTime() * 16f) * 0.5f;
        float radius = (enraging ? 155f : 118f) + (1f - alpha) * (enraging ? 105f : 55f);
        float centerX = boss.getCenterX() - 30f;
        float centerY = Constants.FLOOR_Y + 360f;
        if (enraging) {
            shapeRenderer.setColor(0.72f, 0.025f, 0.01f, (0.20f + pulse * 0.08f) * alpha);
            shapeRenderer.circle(centerX, centerY, radius);
            shapeRenderer.setColor(1f, 0.16f, 0.025f, (0.20f + pulse * 0.07f) * alpha);
            shapeRenderer.circle(centerX, centerY, radius * 0.67f);
            shapeRenderer.setColor(1f, 0.70f, 0.16f, 0.14f * alpha);
            shapeRenderer.circle(centerX, centerY, radius * 0.34f);
        } else {
            Color color = boss.getTelegraphColor();
            shapeRenderer.setColor(color.r * 0.72f, color.g * 0.72f, color.b * 0.72f, 0.18f * alpha);
            shapeRenderer.circle(centerX, centerY, radius);
            shapeRenderer.setColor(color.r, color.g, color.b, 0.20f * alpha);
            shapeRenderer.circle(centerX, centerY, radius * 0.58f);
        }
    }

    public void render(SpriteBatch batch, OrthographicCamera camera, Boss boss, Player player,
                       boolean fightStarted, float elapsed) {
        BossPose pose = createPose(boss, player, fightStarted, elapsed);
        drawPose(batch, camera, boss, pose);
    }

    private BossPose createPose(Boss boss, Player player, boolean fightStarted, float elapsed) {
        BossVisualState state = boss.getVisualState();
        TextureRegion frame = selectFrame(boss, fightStarted, elapsed, state);
        AnimationSignals signals = createAnimationSignals(boss, state, elapsed);
        float height = visualHeight(boss, signals);
        float width = height * frame.getRegionWidth() / frame.getRegionHeight();

        return new BossPose(
                frame,
                horizontalPosition(boss, frame, width, height, signals),
                verticalPosition(signals),
                width,
                height,
                horizontalScale(signals),
                verticalScale(signals),
                rotation(signals),
                signals.hitKick(),
                signals.specialKick(),
                state == BossVisualState.POLLEN_BREATH && player.getCenterX() < boss.getCenterX()
        );
    }

    private AnimationSignals createAnimationSignals(Boss boss, BossVisualState state, float elapsed) {
        boolean defeated = boss.isDefeated();
        float stateTime = boss.getVisualStateTime();
        float actionImpulse = boss.getActionImpulse();
        float hitReaction = boss.getHitReaction();
        float actionProgress = smoothStep(1f - actionImpulse);
        float hitTime = 1f - hitReaction;
        float attackPulse = !defeated && isAttackState(state)
                ? MathUtils.sin(stateTime * ATTACK_PULSE_FREQUENCY)
                : 0f;

        return new AnimationSignals(
                state,
                defeated,
                stateTime,
                defeated ? 0f : MathUtils.sin(elapsed * IDLE_BREATH_FREQUENCY),
                boss.isTelegraphing() ? smoothStep(1f - boss.getTelegraphAlpha()) : 0f,
                actionImpulse > 0f
                        ? MathUtils.sin(actionProgress * MathUtils.PI) * ATTACK_IMPULSE_SCALE : 0f,
                actionImpulse > 0f
                        ? MathUtils.sin(actionProgress * MathUtils.PI2) * (1f - actionProgress)
                        * ATTACK_IMPULSE_SCALE : 0f,
                hitReaction > 0f ? MathUtils.sin(hitTime * MathUtils.PI) : 0f,
                boss.getSpecialHitReaction(),
                attackPulse
        );
    }

    private boolean isAttackState(BossVisualState state) {
        return state == BossVisualState.VINE_STRIKE
                || state == BossVisualState.MAGIC_HANDS
                || state == BossVisualState.POLLEN_RAIN
                || state == BossVisualState.POLLEN_BREATH
                || state == BossVisualState.ENRAGING;
    }

    private float visualHeight(Boss boss, AnimationSignals signals) {
        float height = 506f + signals.breath() * 2f + (boss.isPhaseTwo() ? 18f : 0f);
        height += signals.is(BossVisualState.VINE_STRIKE) ? signals.windup() * 18f : 0f;
        height += signals.is(BossVisualState.ENRAGING)
                ? signals.windup() * 24f + signals.actionKick() * 12f
                : 0f;
        height -= signals.specialKick() * SPECIAL_SQUASH_Y;
        height -= signals.defeated()
                ? smoothStep(MathUtils.clamp(signals.stateTime() / 0.42f, 0f, 1f)) * 24f
                : 0f;
        return height;
    }

    private float horizontalPosition(Boss boss, TextureRegion frame, float width, float height,
                                     AnimationSignals signals) {
        float x = boss.getCenterX() - width * 0.5f - 18f;
        if (isForwardIdleFrame(frame)) {
            float uncroppedWidth = height * FRAME_ASPECT_RATIO;
            x -= (uncroppedWidth - width) * 0.5f;
        }
        if (signals.is(BossVisualState.VINE_STRIKE)) {
            x += signals.attackPulse() * 5f * CONTINUOUS_MOTION_SCALE - 18f - signals.windup() * 18f
                    - signals.actionKick() * 26f + signals.actionFollowThrough() * 11f;
        }
        if (signals.is(BossVisualState.MAGIC_HANDS)) {
            x += MathUtils.sin(signals.stateTime() * MAGIC_SWAY_FREQUENCY) * 5f * CONTINUOUS_MOTION_SCALE
                    - signals.windup() * 10f
                    - signals.actionKick() * 8f + signals.actionFollowThrough() * 5f;
        }
        if (signals.is(BossVisualState.POLLEN_BREATH)) {
            x += -signals.windup() * 18f + signals.attackPulse() * 4f * CONTINUOUS_MOTION_SCALE
                    - signals.actionKick() * 18f + signals.actionFollowThrough() * 8f;
        }
        return x + signals.hitKick() * BASIC_RECOIL_X + signals.specialKick() * SPECIAL_RECOIL_X;
    }

    private boolean isForwardIdleFrame(TextureRegion frame) {
        return frame == frames[IDLE_FORWARD_FRAME_INDEX]
                || frame == inbetweenFrames[IDLE_FORWARD_FRAME_INDEX];
    }

    private float verticalPosition(AnimationSignals signals) {
        float y = Constants.FLOOR_Y - 30f + signals.breath();
        if (signals.is(BossVisualState.POLLEN_RAIN)) {
            y += MathUtils.sin(signals.stateTime() * POLLEN_RAIN_SWAY_FREQUENCY)
                    * POLLEN_RAIN_VERTICAL_SWAY * CONTINUOUS_MOTION_SCALE
                    + signals.actionKick() * POLLEN_RAIN_ATTACK_LIFT;
        }
        if (signals.is(BossVisualState.ENRAGING)) {
            y += signals.attackPulse() * ENRAGE_VERTICAL_SWAY * CONTINUOUS_MOTION_SCALE;
        }
        if (signals.defeated()) {
            y -= smoothStep(MathUtils.clamp(signals.stateTime() / 0.42f, 0f, 1f)) * 16f;
        }
        return y - signals.specialKick() * 4f;
    }

    private float horizontalScale(AnimationSignals signals) {
        return 1f + signals.breath() * 0.005f
                + (signals.is(BossVisualState.MAGIC_HANDS)
                ? signals.attackPulse() * 0.02f * CONTINUOUS_MOTION_SCALE : 0f)
                + signals.actionKick() * (signals.is(BossVisualState.VINE_STRIKE)
                || signals.is(BossVisualState.POLLEN_BREATH) ? 0.035f : 0.018f)
                + signals.actionFollowThrough() * 0.012f
                - signals.hitKick() * BASIC_SQUASH_X
                + signals.specialKick() * 0.07f;
    }

    private float verticalScale(AnimationSignals signals) {
        return 1f - signals.breath() * 0.004f
                + (signals.is(BossVisualState.VINE_STRIKE)
                ? signals.attackPulse() * 0.028f * CONTINUOUS_MOTION_SCALE : 0f)
                - signals.actionKick() * (signals.is(BossVisualState.VINE_STRIKE)
                || signals.is(BossVisualState.POLLEN_BREATH) ? 0.045f : 0.018f)
                - signals.actionFollowThrough() * 0.01f
                + signals.hitKick() * BASIC_STRETCH_Y
                - signals.specialKick() * 0.09f;
    }

    private float rotation(AnimationSignals signals) {
        return MathUtils.sin(signals.stateTime() * 2.1f) * 0.25f
                + signals.attackPulse() * (signals.is(BossVisualState.POLLEN_RAIN)
                || signals.is(BossVisualState.ENRAGING) ? 1.4f : 0.45f) * CONTINUOUS_MOTION_SCALE
                + signals.actionKick() * (signals.is(BossVisualState.VINE_STRIKE) ? -2.4f : 1.2f)
                + signals.actionFollowThrough() * (signals.is(BossVisualState.VINE_STRIKE) ? 2.2f : -1.4f)
                + signals.hitKick() * BASIC_REACTION_ROTATION
                + signals.specialKick() * SPECIAL_REACTION_ROTATION;
    }

    private void drawPose(SpriteBatch batch, OrthographicCamera camera, Boss boss, BossPose pose) {
        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        if (pose.specialKick() > 0.05f) {
            float flash = 0.5f + MathUtils.sin(boss.getVisualStateTime() * 30f) * 0.5f;
            batch.setColor(1f, 0.65f + flash * 0.3f, 0.32f + flash * 0.4f, 1f);
        } else if (pose.hitKick() > 0.05f) {
            batch.setColor(1f, 0.66f + pose.hitKick() * 0.26f, 0.66f + pose.hitKick() * 0.26f, 1f);
        } else if (boss.getVisualState() == BossVisualState.ENRAGING) {
            float progress = 1f - boss.getTelegraphAlpha();
            float pulse = 0.5f + MathUtils.sin(boss.getVisualStateTime() * 18f) * 0.5f;
            float intensity = MathUtils.clamp(0.38f + progress * 0.48f + pulse * 0.14f, 0f, 1f);
            batch.setColor(
                    1f,
                    MathUtils.lerp(1f, 0.48f, intensity),
                    MathUtils.lerp(1f, 0.38f, intensity),
                    1f);
        } else if (boss.isPhaseTwo()) {
            if (boss.isFinalRage()) {
                float pulse = 0.5f + MathUtils.sin(boss.getVisualStateTime() * 6f) * 0.5f;
                batch.setColor(
                        1f,
                        MathUtils.lerp(PHASE_TWO_TINT.green(), FINAL_RAGE_TINT.green(), 0.72f + pulse * 0.28f),
                        MathUtils.lerp(PHASE_TWO_TINT.blue(), FINAL_RAGE_TINT.blue(), 0.72f + pulse * 0.28f),
                        1f);
            } else {
                batch.setColor(1f, PHASE_TWO_TINT.green(), PHASE_TWO_TINT.blue(), 1f);
            }
        }
        if (pose.flipX()) {
            pose.frame().flip(true, false);
        }
        batch.draw(
                pose.frame(),
                pose.x(), pose.y(),
                pose.width() * 0.48f, 44f,
                pose.width(), pose.height(),
                pose.scaleX(), pose.scaleY(),
                pose.rotation()
        );
        if (pose.flipX()) {
            pose.frame().flip(true, false);
        }
        batch.setColor(Color.WHITE);
        batch.end();
    }

    @Override
    public void dispose() {
        spriteSheet.dispose();
        inbetweenSheet.dispose();
    }

    private TextureRegion[] splitFrames(Texture sheet) {
        if (sheet.getWidth() % SHEET_COLUMNS != 0 || sheet.getHeight() % SHEET_ROWS != 0) {
            throw new IllegalArgumentException("A spritesheet do chefe deve usar uma grade exata de 4x2");
        }

        int frameWidth = sheet.getWidth() / SHEET_COLUMNS;
        int frameHeight = sheet.getHeight() / SHEET_ROWS;
        TextureRegion[] result = new TextureRegion[SHEET_COLUMNS * SHEET_ROWS];
        int index = 0;

        for (int row = 0; row < SHEET_ROWS; row++) {
            for (int column = 0; column < SHEET_COLUMNS; column++) {
                int frameIndex = row * SHEET_COLUMNS + column;
                int frameX = column * frameWidth;
                int regionWidth = frameWidth;

                if (frameIndex == IDLE_FORWARD_FRAME_INDEX) {
                    regionWidth -= FORWARD_RIGHT_TRIM;
                } else if (frameIndex == MAGIC_FRAME_INDEX) {
                    frameX -= MAGIC_LEFT_EXTENSION;
                    regionWidth += MAGIC_LEFT_EXTENSION;
                }

                result[index++] = createBleedSafeRegion(
                        sheet, frameX, row * frameHeight, regionWidth, frameHeight);
            }
        }
        return result;
    }

    private TextureRegion createBleedSafeRegion(Texture sheet, int x, int y, int width, int height) {
        float halfTexelU = 0.5f / sheet.getWidth();
        float halfTexelV = 0.5f / sheet.getHeight();
        TextureRegion region = new TextureRegion(sheet, x, y, width, height);
        region.setRegion(
                region.getU() + halfTexelU,
                region.getV() + halfTexelV,
                region.getU2() - halfTexelU,
                region.getV2() - halfTexelV);
        return region;
    }

    private TextureRegion selectFrame(Boss boss, boolean fightStarted, float elapsed, BossVisualState state) {
        if (!fightStarted) {
            return ((int) (elapsed * 2.2f) & 1) == 0
                    ? frames[INTRO_FRAME_INDEX]
                    : inbetweenFrames[INTRO_FRAME_INDEX];
        }
        if (boss.isDefeated()) {
            return defeatedAnimationFrame(boss);
        }
        return switch (state) {
            case ENRAGING, MAGIC_HANDS -> attackAnimationFrame(boss, MAGIC_ANIMATION);
            case VINE_STRIKE -> attackAnimationFrame(boss, VINE_ANIMATION);
            case POLLEN_BREATH -> attackAnimationFrame(boss, POLLEN_BREATH_ANIMATION);
            case POLLEN_RAIN -> attackAnimationFrame(boss, POLLEN_RAIN_ANIMATION);
            case DEFEATED -> defeatedAnimationFrame(boss);
            case IDLE -> idleAnimationFrame(boss);
        };
    }

    private TextureRegion defeatedAnimationFrame(Boss boss) {
        float stateTime = boss.getVisualStateTime();
        if (stateTime < DEFEATED_INITIAL_FRAME_DURATION) {
            return frames[DEFEATED_FRAME_INDEX];
        }

        int frame = (int) ((stateTime - DEFEATED_INITIAL_FRAME_DURATION) * DEFEATED_ANIMATION_FPS);
        return (frame & 1) == 0
                ? inbetweenFrames[DEFEATED_FRAME_INDEX]
                : frames[DEFEATED_FRAME_INDEX];
    }

    private TextureRegion idleAnimationFrame(Boss boss) {
        int frame = (int) (boss.getVisualStateTime() * 7.5f) % 4;
        return switch (frame) {
            case 0 -> frames[IDLE_SIDE_FRAME_INDEX];
            case 1 -> inbetweenFrames[IDLE_SIDE_FRAME_INDEX];
            case 2 -> frames[IDLE_FORWARD_FRAME_INDEX];
            default -> inbetweenFrames[IDLE_FORWARD_FRAME_INDEX];
        };
    }

    private TextureRegion attackAnimationFrame(Boss boss, AnimationSpec animation) {
        if (boss.isTelegraphing() && boss.getActionImpulse() <= 0f) {
            return inbetweenFrames[animation.frameIndex()];
        }
        return ((int) (boss.getVisualStateTime() * animation.framesPerSecond()) & 1) == 0
                ? frames[animation.frameIndex()]
                : inbetweenFrames[animation.frameIndex()];
    }

    private float smoothStep(float value) {
        float t = MathUtils.clamp(value, 0f, 1f);
        return t * t * (3f - 2f * t);
    }
}
