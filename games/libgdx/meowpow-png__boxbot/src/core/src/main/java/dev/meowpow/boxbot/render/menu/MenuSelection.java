package dev.meowpow.boxbot.render.menu;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Tracks which menu item is currently selected.
 */
public final class MenuSelection {

    private final MenuLabel[] items;

    private @Nullable MenuLabel selected;

    /**
     * Creates a selection with nothing selected.
     *
     * @param items the menu's items, top to bottom
     *
     * @throws NullPointerException if {@code items} is null
     */
    public MenuSelection(MenuLabel[] items) {
        this.items = Objects.requireNonNull(items, "items must not be null");
    }

    /**
     * Returns the currently selected
     * item, or null if none is selected.
     */
    public @Nullable MenuLabel selected() {
        return selected;
    }

    /**
     * Selects the given item, or clears
     * the selection when it isn't selectable.
     *
     * @param label the hovered item, or null when hovering nothing
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void hover(@Nullable MenuLabel label, MenuRenderer renderer) {
        selected = (label != null && renderer.isEnabled(label)) ? label : null;
    }

    /**
     * Moves the selection to the next
     * selectable item in the given direction.
     * <p>
     * Selects the first selectable item
     * when nothing is currently selected.
     *
     * @param direction -1 for the previous item, 1 for the next item
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void move(int direction, MenuRenderer renderer) {
        if (selected == null) {
            selectFirstEnabled(renderer);
            return;
        }
        int selectedIndex = indexOf(selected);
        for (int offset = 1; offset < items.length; offset++) {
            int index = Math.floorMod(selectedIndex + direction * offset, items.length);
            var candidate = items[index];
            if (renderer.isEnabled(candidate)) {
                selected = candidate;
                return;
            }
        }
    }

    private void selectFirstEnabled(MenuRenderer renderer) {
        for (MenuLabel candidate : items) {
            if (renderer.isEnabled(candidate)) {
                selected = candidate;
                return;
            }
        }
    }

    private int indexOf(MenuLabel label) {
        for (int i = 0; i < items.length; i++) {
            if (items[i] == label) {
                return i;
            }
        }
        var message = "selected item not found among items: " + label;
        throw new IllegalStateException(message);
    }
}
