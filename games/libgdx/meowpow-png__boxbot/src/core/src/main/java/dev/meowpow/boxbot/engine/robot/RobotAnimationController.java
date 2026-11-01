package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.assets.AnimationClip;
import dev.meowpow.boxbot.render.assets.AnimationController;
import dev.meowpow.boxbot.render.assets.EntitySprite;

import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.utils.ObjectMap;

/**
 * Picks the robot's current animation frame.
 */
@HotPath
public final class RobotAnimationController extends AnimationController<RobotAction> {

    private static final float SIZE_RATIO = 0.4f;
    private static final float MOVE_SECONDS_PER_FRAME = 0.10f;

    /**
     * Create a new robot animation controller.
     *
     * @param atlas the atlas to load the clips from
     *
     * @throws IllegalStateException if the atlas has no {@code robot-move} region
     */
    public RobotAnimationController(TextureAtlas atlas) {
        super(RobotAction.class, RobotAction.IDLE, createClips(atlas));
    }

    private static ObjectMap<RobotAction, AnimationClip> createClips(TextureAtlas atlas) {
        var moveRegions = atlas.findRegions("robot-move");
        if (moveRegions.isEmpty()) {
            throw new IllegalStateException("no atlas regions: robot-move");
        }
        var moveFrames = new EntitySprite[moveRegions.size];
        for (int i = 0; i < moveRegions.size; i++) {
            moveFrames[i] = new EntitySprite(moveRegions.get(i), SIZE_RATIO);
        }
        var moveClip = new AnimationClip(moveFrames, MOVE_SECONDS_PER_FRAME);
        var restClip = new AnimationClip(new EntitySprite[]{moveFrames[0]}, 1f);
        var clips = new ObjectMap<RobotAction, AnimationClip>();

        clips.put(RobotAction.MOVING, moveClip);
        clips.put(RobotAction.IDLE, restClip);
        clips.put(RobotAction.PICKING_UP, restClip);
        clips.put(RobotAction.DROPPING_OFF, restClip);
        clips.put(RobotAction.CHARGING, restClip);

        return clips;
    }
}
