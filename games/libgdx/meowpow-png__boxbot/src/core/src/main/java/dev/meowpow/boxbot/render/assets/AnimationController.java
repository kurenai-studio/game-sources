package dev.meowpow.boxbot.render.assets;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import com.badlogic.gdx.utils.ObjectMap;

import java.util.Objects;

/**
 * Controls an entity's animation.
 */
@HotPath
public class AnimationController<A extends Enum<A>> {

    private final AnimationClip[] clips;

    private A action;

    /**
     * Creates a a new animation controller.
     *
     * @param actionType the action enum's class
     * @param initialAction the action active before the first {@link #setAction}
     * @param clips one clip per {@code actionType} constant
     *
     * @throws NullPointerException if any argument is null,
     * or {@code clipsByAction} is missing an entry for any action
     */
    public AnimationController(Class<A> actionType, A initialAction, ObjectMap<A, AnimationClip> clips) {
        Objects.requireNonNull(initialAction, "initialAction must not be null");
        var actions = actionType.getEnumConstants();
        this.clips = new AnimationClip[actions.length];
        for (var action : actions) {
            var clip = Objects.requireNonNull(clips.get(action), "missing clip for " + action);
            this.clips[action.ordinal()] = clip;
        }
        this.action = initialAction;
    }

    /**
     * Switches the active action,
     * restarting its clip from the first frame.
     * <p>
     * No-op if {@code action} is already active.
     *
     * @param action the entity's new current action
     *
     * @throws NullPointerException if {@code action} is null
     */
    public void setAction(A action) {
        Objects.requireNonNull(action, "action must not be null");
        if (action != this.action) {
            GameLog.debugf(LogTag.RENDER, "animation action %s -> %s", this.action, action);
            this.action = action;
            clips[action.ordinal()].restart();
        }
    }

    /**
     * Advances the active action's clip by {@code delta} seconds.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    public void update(float delta) {
        clips[action.ordinal()].advance(delta);
    }

    /**
     * Returns the active action's current frame.
     */
    public EntitySprite frame() {
        return clips[action.ordinal()].frame();
    }
}
