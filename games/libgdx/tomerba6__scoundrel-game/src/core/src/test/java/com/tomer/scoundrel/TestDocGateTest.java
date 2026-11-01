package com.tomer.scoundrel;

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
 * Every test says, in a doc comment, what it checks.
 *
 * <p>The Javadoc gate in {@code build.gradle} covers the main sources only, and
 * it cannot simply be pointed at the tests too: doclint files the default
 * constructor of every test class under the same {@code missing} group as an
 * undocumented method, so the one cannot be turned on without the other, and
 * silencing it would mean writing a constructor into each class. So the rule
 * for tests is checked here instead, by reading the source: every test and
 * parameterised test method needs a doc comment — a block opening with
 * {@code /**} — directly above it, other annotations aside.
 *
 * <p>The annotations are deliberately not spelled out in this comment: the
 * project counts its tests by grepping the sources for them.
 */
class TestDocGateTest {

    /** Relative to the module directory, as {@code CoverageGateTest} reads its sources. */
    private static final Path SOURCES = Path.of("src", "test", "java");

    private static final Pattern TEST = Pattern.compile("^\\s*@(Test|ParameterizedTest)\\b");
    private static final Pattern ANNOTATION = Pattern.compile("^\\s*@\\w");
    private static final Pattern METHOD = Pattern.compile("\\bvoid\\s+(\\w+)\\s*\\(");

    /** Every test and parameterised test in the test sources has a doc comment above it. */
    @Test
    void everyTestHasADocComment() throws IOException {
        List<String> bare = new ArrayList<>();
        for (Found test : scan()) {
            if (!test.documented()) {
                bare.add(test.toString());
            }
        }
        assertTrue(bare.isEmpty(),
                "these tests have no doc comment — add a /** */ line above each saying the "
                        + "behaviour it checks and the outcome it expects:\n  "
                        + String.join("\n  ", bare));
    }

    /** A guard on the scanner itself: if it stops finding tests, it stops working. */
    @Test
    void theScannerFindsTheTestsThatAreThere() throws IOException {
        assertTrue(scan().size() > 100,
                "the source scan found suspiciously few tests: " + scan().size());
    }

    /** One test as the scan found it: where it is, its name, and whether a doc comment sits above. */
    private record Found(Path file, int line, String name, boolean documented) {
        @Override
        public String toString() {
            return SOURCES.relativize(file) + ":" + line + " " + name;
        }
    }

    private List<Found> scan() throws IOException {
        List<Found> found = new ArrayList<>();
        try (Stream<Path> files = Files.walk(SOURCES)) {
            for (Path file : files.filter(p -> p.toString().endsWith(".java")).toList()) {
                List<String> lines = Files.readAllLines(file);
                for (int i = 0; i < lines.size(); i++) {
                    if (TEST.matcher(lines.get(i)).find()) {
                        found.add(new Found(file, i + 1, nameAfter(lines, i), documentedAbove(lines, i)));
                    }
                }
            }
        }
        return found;
    }

    /**
     * Skips the annotations stacked with the test's own, then wants the line
     * above them to close a comment that opened with {@code /**}. A
     * {@code //} line or a plain block comment does not count.
     */
    private static boolean documentedAbove(List<String> lines, int at) {
        int above = at - 1;
        while (above >= 0 && ANNOTATION.matcher(lines.get(above)).find()) {
            above--;
        }
        if (above < 0 || !lines.get(above).strip().endsWith("*/")) {
            return false;
        }
        for (int i = above; i >= 0; i--) {
            String line = lines.get(i).strip();
            if (line.contains("/*")) {
                return line.startsWith("/**");
            }
        }
        return false;
    }

    private static String nameAfter(List<String> lines, int at) {
        for (int i = at + 1; i < Math.min(lines.size(), at + 6); i++) {
            Matcher method = METHOD.matcher(lines.get(i));
            if (method.find()) {
                return method.group(1);
            }
        }
        return "(method not found)";
    }
}
