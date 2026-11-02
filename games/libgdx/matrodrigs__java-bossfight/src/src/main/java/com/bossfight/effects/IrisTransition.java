package com.bossfight.effects;

public class IrisTransition {
    private static final float CLOSE_DURATION = 0.56f;
    private static final float HOLD_DURATION = 0.10f;
    private static final float OPEN_DURATION = 0.68f;

    public enum Target {
        MENU,
        BATTLE,
        END_VICTORY,
        END_DEFEAT
    }

    private enum Phase {
        NONE,
        CLOSING,
        HOLDING,
        OPENING
    }

    private Phase phase = Phase.NONE;
    private Target target;
    private float timer;
    private boolean targetScreenPending;
    private boolean boostVinyl;

    public boolean start(Target target, boolean boostVinyl) {
        if (isActive()) {
            return false;
        }

        this.target = target;
        this.boostVinyl = boostVinyl;
        targetScreenPending = false;
        phase = Phase.CLOSING;
        timer = 0f;
        return true;
    }

    public void update(float delta) {
        if (!isActive()) {
            return;
        }

        timer += delta;
        switch (phase) {
            case CLOSING -> {
                if (timer >= CLOSE_DURATION) {
                    targetScreenPending = true;
                }
            }
            case HOLDING -> {
                if (timer >= HOLD_DURATION) {
                    phase = Phase.OPENING;
                    timer = 0f;
                }
            }
            case OPENING, NONE -> {
            }
        }
    }

    public void markTargetScreenShown() {
        if (!targetScreenPending) {
            return;
        }

        targetScreenPending = false;
        phase = Phase.HOLDING;
        timer = 0f;
    }

    public void cancel() {
        phase = Phase.NONE;
        target = null;
        timer = 0f;
        targetScreenPending = false;
        boostVinyl = false;
    }

    public boolean isActive() {
        return phase != Phase.NONE;
    }

    public boolean isTargetScreenPending() {
        return targetScreenPending;
    }

    public boolean isOpeningComplete() {
        return phase == Phase.OPENING && timer >= OPEN_DURATION;
    }

    public boolean boostsVinyl() {
        return boostVinyl;
    }

    public Target getTarget() {
        return target;
    }

    public float getApertureProgress() {
        return switch (phase) {
            case NONE -> 1f;
            case CLOSING -> 1f - ease(timer / CLOSE_DURATION);
            case HOLDING -> 0f;
            case OPENING -> ease(timer / OPEN_DURATION);
        };
    }

    private float ease(float progress) {
        float clamped = Math.max(0f, Math.min(1f, progress));
        return clamped * clamped * (3f - 2f * clamped);
    }
}
