package dev.meowpow.boxbot.testing;

import com.badlogic.gdx.backends.headless.HeadlessApplication;

import java.util.concurrent.CountDownLatch;

/**
 * A booted headless application, tracked so
 * {@link HeadlessGameExtension} can shut it down
 * after the test and hand its harness to the test method.
 *
 * @param app the booted application
 * @param shutdown counts down once the application has fully disposed
 * @param harness the harness handed to the test
 */
record RunningApplication(
        HeadlessApplication app,
        CountDownLatch shutdown,
        IntegrationHarness harness
) {}
