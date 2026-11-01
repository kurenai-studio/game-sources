package com.tomer.scoundrel;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/**
 * {@code ScoundrelGame}'s {@code @version} tag is a second copy of the release
 * number, and the original is {@code projectVersion} in {@code gradle.properties},
 * which every release bumps. A copy nobody checks goes stale on the first release
 * after it is written: the Javadoc would go on naming a version that shipped
 * long ago, and nothing would say so.
 *
 * <p>So the copy is checked against the original rather than remembered, like the
 * coverage badge's package list in {@link CoverageGateTest}. A release that bumps
 * one and not the other fails here.
 */
class VersionTagTest {

    private static final Path GAME =
            Path.of("src", "main", "java", "com", "tomer", "scoundrel", "ScoundrelGame.java");
    private static final Path PROPERTIES = Path.of("..", "gradle.properties");

    private static final Pattern VERSION_TAG =
            Pattern.compile("^\\s*\\*\\s*@version\\s+(\\S+)\\s*$", Pattern.MULTILINE);
    private static final Pattern PROJECT_VERSION =
            Pattern.compile("^projectVersion\\s*=\\s*(\\S+)\\s*$", Pattern.MULTILINE);

    /**
     * {@code ScoundrelGame}'s {@code @version} tag matches {@code projectVersion}
     * in {@code gradle.properties}.
     */
    @Test
    void theVersionTagIsTheProjectVersion() throws IOException {
        assertEquals(find(PROJECT_VERSION, PROPERTIES), find(VERSION_TAG, GAME),
                "ScoundrelGame's @version must match projectVersion in gradle.properties — "
                        + "bump both when releasing");
    }

    private static String find(Pattern pattern, Path file) throws IOException {
        Matcher m = pattern.matcher(Files.readString(file));
        assertTrue(m.find(), "no " + pattern.pattern() + " in " + file
                + " — the format changed and this test is no longer reading it");
        return m.group(1);
    }
}
