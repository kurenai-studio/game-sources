package dev.meowpow.boxbot.logging;

/**
 * {@link GameLogger} implementation
 * that discards all log messages.
 */
public final class NoOpGameLogger implements GameLogger {

    @Override
    public void debug(LogTag tag, String message) {}

    @Override
    public void info(LogTag tag, String message) {}

    @Override
    public void warn(LogTag tag, String message) {}

    @Override
    public void error(LogTag tag, String message) {}

    @Override
    public void error(LogTag tag, String message, Throwable throwable) {}

    @Override
    public boolean isDebugEnabled(LogTag tag) {
        return false;
    }

    @Override
    public boolean isInfoEnabled(LogTag tag) {
        return false;
    }

    @Override
    public boolean isWarnEnabled(LogTag tag) {
        return false;
    }

    @Override
    public boolean isErrorEnabled(LogTag tag) {
        return false;
    }
}
