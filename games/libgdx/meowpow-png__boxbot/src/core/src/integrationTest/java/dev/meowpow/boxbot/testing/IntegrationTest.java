package dev.meowpow.boxbot.testing;

import dev.meowpow.boxbot.BoxbotGame;

import org.junit.jupiter.api.extension.ExtendWith;

import java.lang.annotation.*;

/**
 * Marks a test class as an integration test
 * that boots a real {@link BoxbotGame}
 * under a headless libGDX backend.
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@ExtendWith(HeadlessGameExtension.class)
public @interface IntegrationTest {}
