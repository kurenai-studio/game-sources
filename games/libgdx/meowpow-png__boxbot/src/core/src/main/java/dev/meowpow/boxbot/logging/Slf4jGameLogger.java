package dev.meowpow.boxbot.logging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * {@link GameLogger} implementation backed by SLF4J.
 */
public final class Slf4jGameLogger implements GameLogger {

    @Override
    public void debug(LogTag tag, String message) {
        logger(tag).debug(message);
    }

    @Override
    public void info(LogTag tag, String message) {
        logger(tag).info(message);
    }

    @Override
    public void warn(LogTag tag, String message) {
        logger(tag).warn(message);
    }

    @Override
    public void error(LogTag tag, String message) {
        logger(tag).error(message);
    }

    @Override
    public void error(LogTag tag, String message, Throwable throwable) {
        logger(tag).error(message, throwable);
    }

    @Override
    public boolean isDebugEnabled(LogTag tag) {
        return logger(tag).isDebugEnabled();
    }

    @Override
    public boolean isInfoEnabled(LogTag tag) {
        return logger(tag).isInfoEnabled();
    }

    @Override
    public boolean isWarnEnabled(LogTag tag) {
        return logger(tag).isWarnEnabled();
    }

    @Override
    public boolean isErrorEnabled(LogTag tag) {
        return logger(tag).isErrorEnabled();
    }

    private static Logger logger(LogTag tag) {
        return LoggerFactory.getLogger(tag.label);
    }
}
