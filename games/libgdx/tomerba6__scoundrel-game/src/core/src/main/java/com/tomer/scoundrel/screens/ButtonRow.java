package com.tomer.scoundrel.screens;

import java.util.ArrayList;
import java.util.List;
import java.util.function.ToIntFunction;

/**
 * A row of buttons sized by their labels and laid out centred with a fixed gap
 * — the run-end panel's four, each as wide as its own label rather than one
 * shared width.
 *
 * <p>How wide a label is needs a font, so it is passed in and the placing stays
 * arithmetic. Same seam as {@link TextWrap}, and the same reason: a row that
 * drifts off centre by a few pixels is invisible in a screenshot and obvious in
 * an assertion.
 */
final class ButtonRow {

    /**
     * Where one button goes.
     *
     * @param label the text on the button
     * @param x     the button's left edge, in design pixels
     * @param width the button's width, padding included, in design pixels
     */
    record Slot(String label, int x, int width) {
    }

    private ButtonRow() {
    }

    /**
     * Lays the labels out left to right, the whole row centred in its region.
     *
     * @param labels the buttons' text, in order
     * @param left   the left edge of the region to centre within — the panel's,
     *               not the stage's; the run-end panel spans 338..938, so its row
     *               centres on 638 rather than the stage's 640
     * @param across the width of that region
     * @param gap    the space between neighbours
     * @param measure label to button width, padding included
     * @return one slot per label, in order; empty for no labels
     */
    static List<Slot> lay(List<String> labels, int left, int across, int gap,
                          ToIntFunction<String> measure) {
        if (labels.isEmpty()) {
            return List.of();
        }
        int[] widths = new int[labels.size()];
        int total = gap * (labels.size() - 1);
        for (int i = 0; i < labels.size(); i++) {
            widths[i] = measure.applyAsInt(labels.get(i));
            total += widths[i];
        }
        // The whole run is centred, gaps included — centring each button on its
        // own share of the width would leave the row lopsided whenever the
        // labels differ in length, which is exactly when it is noticeable.
        int x = left + (across - total) / 2;
        List<Slot> slots = new ArrayList<>(labels.size());
        for (int i = 0; i < labels.size(); i++) {
            slots.add(new Slot(labels.get(i), x, widths[i]));
            x += widths[i] + gap;
        }
        return List.copyOf(slots);
    }

    /**
     * Which button a point is on, or {@link PressGesture#NONE}. The row is one
     * band: every button shares {@code bottom} and {@code height}, so only the x
     * distinguishes them — and the gaps between them are not targets, which is
     * why this is a scan rather than arithmetic on a pitch.
     *
     * <p>World y points up, so {@code bottom} is the low edge and the band runs
     * upward from it.
     *
     * @param slots  the row, as {@link #lay} returned it
     * @param bottom the row's lower edge in world space
     * @param height how tall each button is
     * @param pointX the point's x, in world space
     * @param pointY the point's y, in world space, pointing up
     * @return the index of the slot under the point, or {@link PressGesture#NONE}
     */
    static int indexAt(List<Slot> slots, float bottom, int height, float pointX, float pointY) {
        if (pointY < bottom || pointY >= bottom + height) {
            return PressGesture.NONE;
        }
        for (int i = 0; i < slots.size(); i++) {
            Slot slot = slots.get(i);
            if (pointX >= slot.x() && pointX < slot.x() + slot.width()) {
                return i;
            }
        }
        return PressGesture.NONE;
    }
}
