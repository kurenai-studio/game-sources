package com.micro1.cookiesort;

/** The four corner plates, each with a stable index (0..3) and a lowercase-hyphen log label. */
public enum Corner {
    TOP_LEFT("top-left"),
    TOP_RIGHT("top-right"),
    BOTTOM_LEFT("bottom-left"),
    BOTTOM_RIGHT("bottom-right");

    public final String label;

    Corner(String label) {
        this.label = label;
    }
}
