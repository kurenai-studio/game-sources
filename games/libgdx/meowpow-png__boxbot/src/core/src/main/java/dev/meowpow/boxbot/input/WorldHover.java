package dev.meowpow.boxbot.input;

/**
 * The player's pointer position, in screen coordinates.
 * <p>
 * <strong>API Note:</strong>
 * Reused by the dispatcher across events; listeners must
 * read the coordinates synchronously and must not retain the instance.
 */
public final class WorldHover {

    private int screenX;
    private int screenY;

    /**
     * Updates the pointer position.
     *
     * @param screenX the pointer's x position, in screen pixels
     * @param screenY the pointer's y position, in screen pixels
     */
    public void set(int screenX, int screenY) {
        this.screenX = screenX;
        this.screenY = screenY;
    }

    /**
     * Returns the pointer's x position, in screen pixels.
     */
    public int screenX() {
        return screenX;
    }

    /**
     * Returns the pointer's y position, in screen pixels.
     */
    public int screenY() {
        return screenY;
    }
}
