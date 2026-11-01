package com.tomer.scoundrel.screens;

/**
 * The sizes Silkscreen is rendered at, and the only ones anything should ask
 * for.
 *
 * <p>All even, deliberately. The viewport snaps to half-steps, so at 1920×1080
 * everything is drawn at ×1.5 and an odd size lands on a half pixel — which is
 * precisely the blur a pixel face exists to avoid, and which nothing in a code
 * review would catch. So there is no 11 or 13; text that would be set at one is
 * set at 12 or 14.
 */
final class PixelType {

    /** Captions and the smallest labels. */
    static final int SMALL = 8;
    /** Section headings and badges. */
    static final int LABEL = 12;
    /** Descriptions and body copy. */
    static final int BODY = 14;
    /** Screen names and headlines. */
    static final int TITLE = 26;
    /** Card values and the wordmark. */
    static final int DISPLAY = 38;

    /** Every legal size, ascending — checked to be even and viewport-safe. */
    static final int[] SIZES = {SMALL, LABEL, BODY, TITLE, DISPLAY};

    private PixelType() {
    }
}
