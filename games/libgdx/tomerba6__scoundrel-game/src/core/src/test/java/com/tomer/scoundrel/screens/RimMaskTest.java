package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The cream outline is generated at load rather than shipped, so the art set
 * stays 174 files instead of 226. That only holds if the generator reproduces
 * what the artist actually drew — the reference copies exist precisely so this
 * can be checked pixel for pixel, and the big test below does exactly that
 * against all 26 of them.
 */
class RimMaskTest {

    private static final int RIM = 0xfff7f0dc;
    private static final int CLEAR = 0x00000000;
    private static final int SOLID = 0xff123456;

    /** Reference art lives beside the module; absent in a source-only checkout. */
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

    // --- the rule, in isolation -------------------------------------------

    /** A lone opaque pixel is all rim. */
    @Test
    void aLoneOpaquePixelIsAllRim() {
        int[] src = {SOLID};
        assertArrayIs(new int[] {RIM}, RimMask.generate(src, 1, 1));
    }

    /** An empty image has no rim. */
    @Test
    void anEmptyImageProducesNothing() {
        int[] src = new int[9];
        assertArrayIs(new int[9], RimMask.generate(src, 3, 3));
    }

    /** In a solid block the centre is not rim and the ring is. */
    @Test
    void anInteriorPixelIsNotRim() {
        // A solid 3x3: only the ring touches transparency, and the centre does
        // not — but the ring also touches the image edge, which counts.
        int[] src = new int[9];
        java.util.Arrays.fill(src, SOLID);
        int[] rim = RimMask.generate(src, 3, 3);
        assertEquals(CLEAR, rim[4], "the centre of a solid block should not be rim");
        for (int i : new int[] {0, 1, 2, 3, 5, 6, 7, 8}) {
            assertEquals(RIM, rim[i], "ring pixel " + i + " should be rim");
        }
    }

    /**
     * Pixels off the edge of the image count as transparent, so a sprite drawn
     * flush to its bounding box is still outlined there. Verified against the
     * reference set: the Ace differs by 38 pixels between the two conventions,
     * and only this one matches.
     */
    @Test
    void theImageEdgeCountsAsTransparent() {
        int[] src = {SOLID, SOLID, SOLID, SOLID};
        int[] rim = RimMask.generate(src, 2, 2);
        for (int i = 0; i < 4; i++) {
            assertEquals(RIM, rim[i], "pixel " + i + " touches the edge and should be rim");
        }
    }

    /** Only the four side neighbours count, so a plus-shape's centre is not rim. */
    @Test
    void diagonalNeighboursDoNotCount() {
        // Four-neighbourhood only. The centre of a plus-shape is enclosed on
        // all four sides, so it stays clear even though its corners are empty.
        int[] src = new int[9];
        src[1] = SOLID; src[3] = SOLID; src[4] = SOLID; src[5] = SOLID; src[7] = SOLID;
        assertEquals(CLEAR, RimMask.generate(src, 3, 3)[4]);
    }

    /** Every pixel of the rim is opaque cream or clear. */
    @Test
    void theRimIsOpaqueCreamAndNothingElse() {
        int[] src = new int[16];
        java.util.Arrays.fill(src, SOLID);
        for (int argb : RimMask.generate(src, 4, 4)) {
            assertTrue(argb == RIM || argb == CLEAR, "unexpected colour " + Integer.toHexString(argb));
        }
    }

    /** A source pixel with any alpha counts as solid. */
    @Test
    void partiallyTransparentSourcePixelsCountAsSolid() {
        // The delivered art is binary alpha, but treating "any alpha" as solid
        // keeps the rule from silently eating a soft edge if that ever changes.
        int[] src = {0x01123456};
        assertArrayIs(new int[] {RIM}, RimMask.generate(src, 1, 1));
    }

    /** Generating a rim leaves the source untouched. */
    @Test
    void theSourceIsNotModified() {
        int[] src = {SOLID, 0, SOLID, 0};
        int[] copy = src.clone();
        RimMask.generate(src, 2, 2);
        assertArrayIs(copy, src);
    }

    // --- against what the artist actually drew -----------------------------

    /**
     * The load-bearing test: generate the rim for all 26 creature cards and
     * compare to the delivered PNGs pixel for pixel. If this passes, the 52
     * generated frames are provably the same art as the ones left out of the
     * atlas.
     */
    @Test
    @EnabledIf("hasReferenceArt")
    void everyGeneratedRimMatchesTheDeliveredOne() throws IOException {
        Path sprites = referenceDir();
        List<String> checked = new ArrayList<>();
        List<String> failures = new ArrayList<>();

        File[] rims = sprites.resolve("anim").toFile()
                .listFiles((dir, name) -> name.endsWith(".rim.png"));
        assertTrue(rims != null && rims.length > 0, "no reference rims found");

        for (File rimFile : rims) {
            String stem = rimFile.getName().replace(".rim.png", "");
            File baseFile = sprites.resolve(stem + ".png").toFile();
            assertTrue(baseFile.isFile(), "no base sprite for " + stem);

            BufferedImage base = ImageIO.read(baseFile);
            BufferedImage expected = ImageIO.read(rimFile);
            int[] generated = RimMask.generate(pixels(base), base.getWidth(), base.getHeight());
            int[] reference = pixels(expected);

            int differing = 0;
            for (int i = 0; i < reference.length; i++) {
                // Compare transparency and colour, normalising fully clear
                // pixels whose RGB may be anything at all.
                int a = (generated[i] >>> 24) == 0 ? 0 : generated[i];
                int b = (reference[i] >>> 24) == 0 ? 0 : reference[i];
                if (a != b) {
                    differing++;
                }
            }
            checked.add(stem);
            if (differing > 0) {
                failures.add(stem + " (" + differing + "px)");
            }
        }
        assertEquals(26, checked.size(), "expected 26 creature rims, checked " + checked);
        assertTrue(failures.isEmpty(), "generated rim differs from the delivered art: " + failures);
    }

    /** A real sprite's rim is neither empty nor the whole sprite. */
    @Test
    @EnabledIf("hasReferenceArt")
    void aGeneratedRimIsNeitherEmptyNorTheWholeSprite() throws IOException {
        Path sprites = referenceDir();
        BufferedImage base = ImageIO.read(sprites.resolve("creature_07_ghoul.clubs.png").toFile());
        int[] rim = RimMask.generate(pixels(base), base.getWidth(), base.getHeight());
        long lit = java.util.Arrays.stream(rim).filter(p -> (p >>> 24) != 0).count();
        long opaque = java.util.Arrays.stream(pixels(base)).filter(p -> (p >>> 24) != 0).count();
        assertTrue(lit > 0, "rim is empty");
        assertFalse(lit >= opaque, "rim covers the whole sprite rather than outlining it");
    }

    private static void assertArrayIs(int[] expected, int[] actual) {
        assertEquals(expected.length, actual.length, "length");
        for (int i = 0; i < expected.length; i++) {
            assertEquals(expected[i], actual[i],
                    "at " + i + ": expected " + Integer.toHexString(expected[i])
                            + " got " + Integer.toHexString(actual[i]));
        }
    }
}
