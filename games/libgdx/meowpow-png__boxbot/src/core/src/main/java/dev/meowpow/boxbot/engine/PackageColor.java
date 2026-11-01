package dev.meowpow.boxbot.engine;

import com.badlogic.gdx.utils.Array;

/**
 * Represents the package color.
 */
public enum PackageColor {
    RED,
    GREEN,
    BLUE,
    NONE;

    private static final Array<PackageColor> COLORED = buildColored();

    private static Array<PackageColor> buildColored() {
        var colored = new Array<PackageColor>(values().length - 1);
        for (var color : values()) {
            if (color != NONE) {
                colored.add(color);
            }
        }
        return colored;
    }

    /**
     * Returns every color except {@link #NONE}.
     */
    public static Array<PackageColor> colored() {
        return COLORED;
    }
}
