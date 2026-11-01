package dev.meowpow.boxbot.testing;

import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.NoOpGameLogger;

import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

public final class GameLogExtension implements BeforeAllCallback {

    private static final ExtensionContext.Namespace NAMESPACE =
            ExtensionContext.Namespace.create(GameLogExtension.class);

    @Override
    public void beforeAll(ExtensionContext context) {
        context.getRoot()
                .getStore(NAMESPACE)
                .computeIfAbsent(GameLogInitializer.class);
    }

    private static final class GameLogInitializer {

        private GameLogInitializer() {
            GameLog.init(new NoOpGameLogger(), () -> 0L);
        }
    }
}
