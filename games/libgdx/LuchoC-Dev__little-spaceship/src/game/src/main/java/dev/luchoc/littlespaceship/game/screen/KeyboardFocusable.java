package dev.luchoc.littlespaceship.game.screen;

/**
 * One entry a {@link MenuNavigator} can move keyboard focus to.
 *
 * <p>{@link #setFocused} must change how the entry reads at 480x270 through more than colour alone
 * — {@code docs/design/05-legibility-rules.md} R4, the same rule gameplay sprites already follow.
 * {@link #activate} is what Enter/Space does to the entry; {@link #adjust} is what Left/Right does,
 * for an entry with a value rather than an action, such as a slider.
 */
interface KeyboardFocusable {

    void setFocused(boolean focused);

    default void activate() {
    }

    default void adjust(int direction) {
    }
}
