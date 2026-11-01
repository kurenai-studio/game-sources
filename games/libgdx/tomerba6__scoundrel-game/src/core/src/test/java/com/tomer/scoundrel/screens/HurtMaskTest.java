package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The struck-creature frame: every colour moved two steps up its own ramp and
 * the cream outline laid over it.
 *
 * <p>Moving along the ramp rather than blending toward white is the whole
 * point — it is what keeps the flash inside the eighty colours the art is drawn
 * on. The palette test below is that guarantee, checked over every sprite the
 * game can show rather than over a hand-picked example.
 */
class HurtMaskTest {

    private static final int CREAM = 0xfff7f0dc;

    private static Path referenceDir() {
        return Path.of("..", "art-reference", "sprites");
    }

    /**
     * Whether the reference sprites are present; the tests that compare against
     * them run only then.
     *
     * @return true when {@code art-reference/sprites/anim} exists
     */
    static boolean hasReferenceArt() {
        return Files.isDirectory(referenceDir().resolve("anim"));
    }

    private static int[] pixels(BufferedImage image) {
        int[] out = new int[image.getWidth() * image.getHeight()];
        image.getRGB(0, 0, image.getWidth(), image.getHeight(), out, 0, image.getWidth());
        return out;
    }

    /** The ramp table holds the eighty colours, BONE 0 and ACCENT 7 among them. */
    @Test
    void theRampTableIsCompleteAndUnambiguous() {
        assertEquals(80, Ramps.size(), "the palette is eighty colours");
        assertTrue(Ramps.contains(0x12101c), "BONE 0");
        assertTrue(Ramps.contains(0xf7f0dc), "ACCENT 7");
    }

    /** Lightening moves a colour two steps up its own ramp. */
    @Test
    void aColourMovesUpItsOwnRamp() {
        assertEquals(0x383341, Ramps.lighten(0x12101c, 2));   // BONE 0 -> 2
        assertEquals(0xa85338, Ramps.lighten(0x6b2b23, 2));   // FLESH 4 -> 6
        assertEquals(0x58964a, Ramps.lighten(0x325a31, 2));   // ROT 3 -> 5
    }

    /** Lightening stops at the top of the ramp. */
    @Test
    void theLightestStepIsAsFarAsItGoes() {
        assertEquals(0xe6dcc0, Ramps.lighten(0xb3a683, 2));   // BONE 6 -> clamped 7
        assertEquals(0xe6dcc0, Ramps.lighten(0xe6dcc0, 2));   // already 7
    }

    /**
     * Six creatures are not fully on the ramps, so a colour outside the system
     * is snapped to its nearest ramp entry and then brightened. Leaving it
     * alone would make being struck invisible on 92% of the Ace.
     */
    @Test
    void aColourOutsideTheSystemIsSnappedToTheNearestRamp() {
        int lightened = Ramps.lighten(0x584636, 2);
        assertTrue(Ramps.contains(lightened),
                "expected an on-palette result, got #" + Integer.toHexString(lightened));
        assertNotEquals(0x584636, lightened, "an off-ramp colour should still brighten");
    }

    /** An on-ramp colour lightens along its own ramp, not a neighbour's. */
    @Test
    void aColourAlreadyOnTheRampIsNotDisturbedByTheFallback() {
        // The nearest match to an exact entry is itself, so on-ramp colours
        // keep taking their own ramp rather than drifting to a neighbour's.
        assertEquals(0x383341, Ramps.lighten(0x12101c, 2));
    }

    /** Clear pixels stay clear. */
    @Test
    void transparentPixelsStayTransparent() {
        int[] src = new int[4];
        for (int argb : HurtMask.generate(src, 2, 2)) {
            assertEquals(0, argb >>> 24, "a clear pixel gained alpha");
        }
    }

    /** An edge pixel ends up cream. */
    @Test
    void theOutlineIsLaidOverTheBrightenedSprite() {
        // A single opaque pixel is entirely its own edge, so it ends up cream.
        int[] src = {0xff12101c};
        assertEquals(CREAM, HurtMask.generate(src, 1, 1)[0]);
    }

    /** An interior pixel brightens two steps while an edge pixel turns cream. */
    @Test
    void theInteriorIsBrightenedRatherThanOutlined() {
        // 3x3 of BONE 0: the centre is interior, so it brightens to BONE 2.
        int[] src = new int[9];
        java.util.Arrays.fill(src, 0xff12101c);
        int[] hurt = HurtMask.generate(src, 3, 3);
        assertEquals(0xff383341, hurt[4], "centre should be BONE 2");
        assertEquals(CREAM, hurt[0], "corner is on the edge, so cream");
    }

    /** A hurt frame's interior is lighter than its source. */
    @Test
    void aHurtFrameIsBrighterThanItsSource() {
        int[] src = new int[25];
        java.util.Arrays.fill(src, 0xff12101c);
        int[] hurt = HurtMask.generate(src, 5, 5);
        assertNotEquals(src[12], hurt[12], "the middle should have changed");
        assertTrue(luminance(hurt[12]) > luminance(src[12]), "and it should be lighter");
    }

    /**
     * Over every sprite rather than an example: the hurt frame must be brighter
     * but still on-palette — no white, no invented colours. Brightening along the
     * ramp is what guarantees it; blending toward white would not.
     */
    @Test
    @EnabledIf("hasReferenceArt")
    void noSpriteEverProducesAColourOutsideThePalette() throws IOException {
        File[] sprites = referenceDir().toFile()
                .listFiles((dir, name) -> name.endsWith(".png") && name.startsWith("creature_"));
        assertTrue(sprites != null && sprites.length > 0, "no reference sprites found");

        Set<String> strays = new LinkedHashSet<>();
        int checked = 0;
        for (File file : sprites) {
            BufferedImage image = ImageIO.read(file);
            int[] hurt = HurtMask.generate(pixels(image), image.getWidth(), image.getHeight());
            for (int argb : hurt) {
                if ((argb >>> 24) == 0) {
                    continue;
                }
                int rgb = argb & 0xffffff;
                if (!Ramps.contains(rgb)) {
                    strays.add(file.getName() + ": #" + Integer.toHexString(rgb));
                }
                assertNotEquals(0xffffff, rgb, "washed to pure white in " + file.getName());
            }
            checked++;
        }
        assertEquals(26, checked, "expected the 26 creature cards");
        assertTrue(strays.isEmpty(), "off-palette colours generated: " + strays);
    }

    private static int luminance(int argb) {
        return ((argb >> 16) & 0xff) * 30 + ((argb >> 8) & 0xff) * 59 + (argb & 0xff) * 11;
    }
}
