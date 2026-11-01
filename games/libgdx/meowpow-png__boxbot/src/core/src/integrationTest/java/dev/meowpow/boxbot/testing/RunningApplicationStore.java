package dev.meowpow.boxbot.testing;

import org.jspecify.annotations.Nullable;

import org.junit.jupiter.api.extension.ExtensionContext;

/**
 * Holds the {@link RunningApplication} that
 * {@link HeadlessGameExtension} boots for each test,
 * keyed off the extension's own JUnit store namespace.
 */
final class RunningApplicationStore {

    private static final ExtensionContext.Namespace NAMESPACE =
            ExtensionContext.Namespace.create(RunningApplicationStore.class);

    private RunningApplicationStore() {}

    static void put(ExtensionContext context, RunningApplication application) {
        context.getStore(NAMESPACE).put(
                RunningApplication.class,
                application
        );
    }

    @Nullable
    static RunningApplication get(ExtensionContext context) {
        return context.getStore(NAMESPACE).get(
                RunningApplication.class,
                RunningApplication.class
        );
    }

    @Nullable
    static RunningApplication remove(ExtensionContext context) {
        return context.getStore(NAMESPACE).remove(
                RunningApplication.class,
                RunningApplication.class
        );
    }
}
