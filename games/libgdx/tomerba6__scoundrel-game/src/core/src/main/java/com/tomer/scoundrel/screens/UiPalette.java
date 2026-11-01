package com.tomer.scoundrel.screens;

import java.util.Set;

/**
 * Tier two of the palette: every colour drawn in code that is <b>not</b> one of
 * the eighty ramp entries in {@link Ramps}.
 *
 * <p>The eighty ramp colours are not the only ones the UI draws: the chrome,
 * the potion bottle, the cleaved card's cut faces and the HUD tints are on no
 * ramp. <b>None of these were invented.</b> Each was taken off the design, which
 * is why the answer is to write them down rather than to repaint them.
 *
 * <p>{@code UiPaletteTest} is what keeps this honest: it reads both declaration
 * forms out of the source and fails on any colour in neither tier.
 *
 * <p><b>What this cannot govern: blended output.</b> {@code fill(…, 0x000000,
 * 0.5f)} puts a colour on screen that is on no ramp by construction, so those
 * shadow lines break the flat-colour, never-alpha rule. Bringing them onto flat
 * palette steps would change pixels, so it is deliberately out of scope here.
 */
final class UiPalette {

    private static final Set<Integer> COLOURS = Set.of(
            // --- structure and chrome ---------------------------------------
            0x0f1410,   // FRAME — the 2px recess around every widget
            0x161210,   // FACE_PANEL
            0x141110,   // FACE_TABLE, and the even ledger row
            0x12161a,   // the rail's recess, the gold plate's label
            0x1a1410,   // DARK plate
            0x2f2620,   // DARK_LIGHT, its lit bevel
            0x0a0806,   // DARK_DARK, its shadowed bevel; also the value and
                        // wordmark drop shadows, which are hard offsets not blurs
            0x4a3524,   // rules, the potion-ready marker, locked trophy text
            0x191513,   // the odd ledger row, and an earned trophy's row
            0x131110,   // a locked trophy's row
            0x1e1a17,   // an unearned seal's empty well — the locked state itself
            0x241d16,   // the "no trophies" badge
            0x9a8b70,   // header captions, the feed, the depth line, the cork
            0x6b5f4c,   // captions, the badge label, the HP suffix, FILL_LOW
            0x746d63,   // a quiet ledger cell
            0x494336,   // an unselected mode's well digit
            0x3a2e26,   // an unlit tutorial step dot
            0x74838f,   // starting health, and the rail weapon's name
            0x0e050c,   // the title portrait's field
            0x100c09,   // the stage behind everything

            // --- the HUD ----------------------------------------------------
            0x1e2a1c,   // the health bar's empty track
            0x3b4334,   // that track's lip
            0x2d3029,   // the segment lines laid over the fill
            0x20180e,   // a spent depth tick

            // --- the slain stack --------------------------------------------
            0x4e2620,   // a chip's face
            0xa35543,   // a chip's label

            // --- objects drawn in code ---------------------------------------
            0x3a1d18,   // the cleaved card's upper cut face
            0x2c1512,   // and its lower one
            0x5d8a4a,   // the potion bottle's glass
            0x507641,   // that glass in shade
            0x35291f,   // the bottle's edge

            // --- black ------------------------------------------------------
            // Drawn at alpha as the shadow line under the rail well and the card
            // well, and used opaque as RimMask's fully transparent clear.
            0x000000);

    private UiPalette() {
    }

    /**
     * Whether a colour is one of the drawn-in-code colours.
     *
     * @param rgb the colour as {@code 0xRRGGBB}, no alpha
     * @return true if it is in this tier
     */
    static boolean contains(int rgb) {
        return COLOURS.contains(rgb);
    }

    /**
     * Every colour in this tier, for the palette test to check against the ramps.
     *
     * @return an unmodifiable set of {@code 0xRRGGBB} values
     */
    static Set<Integer> all() {
        return COLOURS;
    }

    /**
     * How many colours this tier holds.
     *
     * @return the number of distinct colours in {@link #all()}
     */
    static int size() {
        return COLOURS.size();
    }
}
