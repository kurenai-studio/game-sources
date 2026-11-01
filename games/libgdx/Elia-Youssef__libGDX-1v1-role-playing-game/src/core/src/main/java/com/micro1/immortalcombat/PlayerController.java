package com.micro1.immortalcombat;

/**
 * Tracks the player's current action independently from libGDX rendering and input APIs.
 * One-shot actions finish before held actions are evaluated again.
 */
public class PlayerController {

    public static final float IDLE_FRAME = 0.1f;
    public static final float FORWARD_FRAME = 0.1f;
    public static final float BACKWARD_FRAME = 0.1f;
    public static final float KICK_FRAME = 0.08f;
    public static final float PUNCH_FRAME = 0.08f;
    public static final float BLOCK_FRAME = 0.08f;
    public static final float CROUCH_FRAME = 0.08f;

    public static final float JUMP_LAUNCH_FRAME = 0.1f;
    public static final float JUMP_MIDAIR_FRAME = 0.4f;
    public static final float JUMP_LAND_FRAME = 0.1f;

    public static final int FRAMES_PER_ACTION = 3;

    private final AttackListener attackListener;

    private PlayerState currentState = PlayerState.IDLE;
    private float stateTime;

    private boolean oneShotActive;
    private float oneShotElapsed;
    private float oneShotDuration;

    private boolean forwardHeld;
    private boolean backwardHeld;
    private boolean crouchHeld;
    private boolean blockHeld;

    @FunctionalInterface
    public interface AttackListener {
        void onAttackStarted(PlayerState action);
    }

    public PlayerController() {
        this(null);
    }

    public PlayerController(AttackListener attackListener) {
        this.attackListener = attackListener;
    }

    public void pressJump() {
        startOneShot(PlayerState.JUMP, jumpDuration());
    }

    public void pressPunch() {
        startOneShot(PlayerState.PUNCH, FRAMES_PER_ACTION * PUNCH_FRAME);
    }

    public void pressKick() {
        startOneShot(PlayerState.KICK, FRAMES_PER_ACTION * KICK_FRAME);
    }

    public void setForwardHeld(boolean held) {
        forwardHeld = held;
    }

    public void setBackwardHeld(boolean held) {
        backwardHeld = held;
    }

    public void setCrouchHeld(boolean held) {
        crouchHeld = held;
    }

    public void setBlockHeld(boolean held) {
        blockHeld = held;
    }

    /** Advances the state machine by the supplied number of seconds. */
    public void update(float deltaSeconds) {
        if (deltaSeconds < 0f) {
            throw new IllegalArgumentException("deltaSeconds must not be negative");
        }

        if (!oneShotActive) {
            resolveHeldState();
            stateTime += deltaSeconds;
            return;
        }

        float remaining = oneShotDuration - oneShotElapsed;
        float consumed = Math.min(deltaSeconds, remaining);
        oneShotElapsed += consumed;
        stateTime += consumed;

        if (oneShotElapsed < oneShotDuration) {
            return;
        }

        oneShotActive = false;
        resolveHeldState();
        stateTime += deltaSeconds - consumed;
    }

    public PlayerState getCurrentState() {
        return currentState;
    }

    public float getStateTime() {
        return stateTime;
    }

    public boolean isOneShotActive() {
        return oneShotActive;
    }

    public float getOneShotElapsed() {
        return oneShotElapsed;
    }

    /** Returns the frame for the three jump phases: launch, airborne, and landing. */
    public int jumpFrameIndex(float elapsedSeconds) {
        if (elapsedSeconds < JUMP_LAUNCH_FRAME) {
            return 0;
        }
        if (elapsedSeconds < JUMP_LAUNCH_FRAME + JUMP_MIDAIR_FRAME) {
            return 1;
        }
        return 2;
    }

    private void startOneShot(PlayerState action, float duration) {
        if (oneShotActive) {
            return;
        }

        oneShotActive = true;
        oneShotElapsed = 0f;
        oneShotDuration = duration;
        changeState(action);

        if (isAttack(action) && attackListener != null) {
            attackListener.onAttackStarted(action);
        }
    }

    private void resolveHeldState() {
        if (blockHeld) {
            changeState(PlayerState.BLOCK);
        } else if (crouchHeld) {
            changeState(PlayerState.CROUCH);
        } else if (forwardHeld) {
            changeState(PlayerState.FORWARD);
        } else if (backwardHeld) {
            changeState(PlayerState.BACKWARD);
        } else {
            changeState(PlayerState.IDLE);
        }
    }

    private void changeState(PlayerState nextState) {
        if (nextState != currentState) {
            currentState = nextState;
            stateTime = 0f;
        }
    }

    private static boolean isAttack(PlayerState action) {
        return action == PlayerState.PUNCH || action == PlayerState.KICK;
    }

    private static float jumpDuration() {
        return JUMP_LAUNCH_FRAME + JUMP_MIDAIR_FRAME + JUMP_LAND_FRAME;
    }
}
