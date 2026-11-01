package com.tomer.scoundrel.screens;

/**
 * What the health bar and its number say right now, which is not always what
 * the state says.
 *
 * <p>The bar lags the engine deliberately. A drink is resolved the instant you
 * press the card, but nothing may appear at the bar until the bottle has flown
 * there and tipped — a fill with no visible cause reads as the bar glitching.
 * So between the press and the pour the bar {@link Phase#HELD holds} the
 * reading it is about to leave.
 *
 * <p>It is a decision rather than a drawing, so it lives out here where it can
 * be pinned. The held case must not fall through to "at rest", which paints the
 * state's own health: the bar would fill on the press, then rewind and fill
 * again on the pour.
 *
 * @param fill     how wide the filled part is, in pixels
 * @param number   the reading beside the bar, which may be negative
 * @param offsetX  the sideways jolt a hit gives the whole bar
 * @param healing  paint the fill green; the bar is growing
 * @param bleeding paint it dried blood; the bar is draining
 */
record HealthReadout(int fill, int number, int offsetX, boolean healing, boolean bleeding) {

    /**
     * Where the bar is coming from and going to, in widths and in numbers.
     *
     * @param fromWidth  the fill before the move, in pixels
     * @param toWidth    the fill after it, in pixels
     * @param fromHealth the number before the move
     * @param toHealth   the number after it; may be negative on a death
     */
    record Change(int fromWidth, int toWidth, int fromHealth, int toHealth) {
        /** No change in flight: the phase is {@link Phase#REST} and this is never read. */
        static final Change NONE = new Change(0, 0, 0, 0);
    }

    /** What the bar is doing. */
    enum Phase {
        /** Nothing; the bar agrees with the state. */
        REST,
        /** A drink is resolved but the bottle has not poured. The bar waits. */
        HELD,
        /** The bottle has poured: the fill grows green toward the new health. */
        HEALING,
        /** A hit landed: the fill drains, dried blood, and the bar jolts sideways. */
        BLEEDING
    }

    /**
     * What the bar shows this frame.
     *
     * @param phase     what the bar is doing
     * @param health    the state's health, read only at rest
     * @param maxHealth the ruleset's cap, which a full bar stands for
     * @param change    the move in flight; ignored at rest
     * @param elapsed   seconds on the change's pulse clock
     * @return the fill, the number and the jolt to draw
     */
    static HealthReadout of(Phase phase, int health, int maxHealth,
                            Change change, float elapsed) {
        return switch (phase) {
            case REST -> new HealthReadout(
                    HudArt.barFillWidth(health, maxHealth), health, 0, false, false);
            // Everything the bar knows is the pre-drink reading: the width it
            // had and the number it showed. The state's health is deliberately
            // ignored — it has run ahead of the bottle.
            case HELD -> new HealthReadout(
                    change.fromWidth(), change.fromHealth(), 0, false, false);
            case HEALING -> {
                boolean growing = HpPulse.numberHealed(
                        change.fromWidth(), change.toWidth(), elapsed);
                yield new HealthReadout(
                        HpPulse.healWidth(change.fromWidth(), change.toWidth(), elapsed),
                        growing ? change.toHealth() : change.fromHealth(),
                        0, true, false);
            }
            case BLEEDING -> {
                boolean draining = HpPulse.numberBloodied(
                        change.fromWidth(), change.toWidth(), elapsed);
                yield new HealthReadout(
                        HpPulse.damageWidth(change.fromWidth(), change.toWidth(), elapsed),
                        draining ? change.toHealth() : change.fromHealth(),
                        HpPulse.barOffset(change.fromWidth(), change.toWidth(), elapsed),
                        false, true);
            }
        };
    }
}
