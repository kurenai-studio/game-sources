package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/**
 * The palette rule.
 *
 * <p>The eighty ramp colours are not the only colours the UI uses. The chrome
 * has hexes on no ramp, and the potion bottle, the cleaved card's cut faces and
 * the HUD tints are sampled colours of their own. Even the sprites only mostly
 * keep to the ramps — six are partly off, which is why {@link Ramps} snaps to
 * the nearest entry before brightening.
 *
 * <p>So: two tiers. {@link Ramps} holds the eighty and governs sprite pixels;
 * {@link UiPalette} holds the colours drawn in code that are not on them, each
 * with its provenance. This fails if a colour appears in neither.
 *
 * <p>It reads source rather than reflecting over fields, so both declaration
 * forms are caught — a {@code 0x} scan alone would never look at {@code Theme},
 * which spells its colours {@code Color.valueOf("d9a441")}. Declarations only:
 * {@code argb[i] & 0xffffff} in the mask generators is a bit mask, not a colour.
 */
class UiPaletteTest {

    /** Relative to the module directory, as {@code RimMaskTest} does it. */
    private static final Path SOURCES =
            Path.of("src", "main", "java", "com", "tomer", "scoundrel", "screens");

    private static final Pattern INT_FORM =
            Pattern.compile("static final int ([A-Z_][A-Z0-9_]*) = 0x([0-9a-fA-F]{6,8})");

    private static final Pattern COLOR_FORM =
            Pattern.compile("Color\\.valueOf\\(\"([0-9a-fA-F]{6})\"\\)");

    private record Declared(String file, int line, String name, int rgb) {
        @Override
        public String toString() {
            return String.format("%s:%d %s = %06x", file, line, name, rgb);
        }
    }

    /** Every colour declared in the screens sources is on a ramp or in UiPalette. */
    @Test
    void everyDeclaredColourIsOnARampOrIsANamedException() throws IOException {
        List<Declared> strays = new ArrayList<>();
        for (Declared declared : scan()) {
            if (!Ramps.contains(declared.rgb()) && !UiPalette.contains(declared.rgb())) {
                strays.add(declared);
            }
        }
        assertTrue(strays.isEmpty(),
                "colours on neither the ramps nor UiPalette — add each to UiPalette with a "
                        + "comment saying what it draws, or move it onto a ramp:\n  "
                        + String.join("\n  ", strays.stream().map(Object::toString).toList()));
    }

    /** No UiPalette colour is also on a ramp. */
    @Test
    void theTwoTiersAreDisjoint() {
        List<String> both = new ArrayList<>();
        for (int rgb : UiPalette.all()) {
            if (Ramps.contains(rgb)) {
                both.add(String.format("%06x", rgb));
            }
        }
        assertTrue(both.isEmpty(),
                "these are on a ramp already and must not also be UiPalette entries: " + both);
    }

    /** A guard on the scanner itself: if it stops finding colours, it stops working. */
    @Test
    void theScannerFindsTheColoursThatAreThere() throws IOException {
        assertTrue(scan().size() > 50,
                "the source scan found suspiciously few colour declarations: " + scan().size());
    }

    private List<Declared> scan() throws IOException {
        List<Declared> found = new ArrayList<>();
        try (Stream<Path> files = Files.list(SOURCES)) {
            for (Path file : files.filter(p -> p.toString().endsWith(".java")).toList()) {
                List<String> lines = Files.readAllLines(file);
                for (int i = 0; i < lines.size(); i++) {
                    collect(found, file.getFileName().toString(), i + 1, lines.get(i));
                }
            }
        }
        return found;
    }

    private void collect(List<Declared> found, String file, int line, String text) {
        Matcher ints = INT_FORM.matcher(text);
        while (ints.find()) {
            // The 8-digit form is ARGB; the colour is its low three bytes. Read
            // as a long first — 0xff______ overflows a signed int.
            int rgb = (int) (Long.parseLong(ints.group(2), 16) & 0xffffffL);
            found.add(new Declared(file, line, ints.group(1), rgb));
        }
        Matcher colors = COLOR_FORM.matcher(text);
        while (colors.find()) {
            found.add(new Declared(file, line, "Color.valueOf",
                    Integer.parseInt(colors.group(1), 16)));
        }
    }
}
