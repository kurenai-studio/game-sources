package dev.meowpow.boxbot.logging;

import org.jspecify.annotations.NullUnmarked;

import java.util.Locale;
import java.util.Objects;
import java.util.function.LongSupplier;

/**
 * Global logging facade for this game.
 * <p>
 * <strong>API Note:</strong>
 * Logging must be initialized once before use.
 * Every emitted message includes the current simulation tick.
 */
@NullUnmarked
public final class GameLog {

    private static GameLogger logger;
    private static LongSupplier tickSupplier;

    private GameLog() {}

    /**
     * Initializes the logging system.
     *
     * @param logger logging backend
     * @param tickSupplier supplier of the current simulation tick
     *
     * @throws IllegalStateException if logging has already been initialized
     * @throws NullPointerException if {@code logger} or {@code tickSupplier} is null
     */
    public static void init(GameLogger logger, LongSupplier tickSupplier) {
        if (GameLog.logger != null) {
            throw new IllegalStateException("GameLog is already initialized");
        }
        Objects.requireNonNull(logger, "logger must not be null");
        Objects.requireNonNull(tickSupplier, "tickSupplier must not be null");

        GameLog.logger = logger;
        GameLog.tickSupplier = tickSupplier;
    }

    /**
     * Logs a debug message.
     *
     * @param tag log category
     * @param message message to log
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code message} is null
     */
    public static void debug(LogTag tag, String message) {
        var logger = logger();

        if (logger.isDebugEnabled(tag)) {
            logger.debug(tag, withTick(message));
        }
    }

    /**
     * Logs a formatted debug message.
     *
     * @param tag log category
     * @param format format string
     * @param args format arguments
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code format} or {@code args} is null
     */
    public static void debugf(LogTag tag, String format, Object... args) {
        var logger = logger();

        if (logger.isDebugEnabled(tag)) {
            logger.debug(tag, withTick(format(format, args)));
        }
    }

    /**
     * Logs an informational message.
     *
     * @param tag log category
     * @param message message to log
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code message} is null
     */
    public static void info(LogTag tag, String message) {
        var logger = logger();

        if (logger.isInfoEnabled(tag)) {
            logger.info(tag, withTick(message));
        }
    }

    /**
     * Logs a formatted informational message.
     *
     * @param tag log category
     * @param format format string
     * @param args format arguments
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code format} or {@code args} is null
     */
    public static void infof(LogTag tag, String format, Object... args) {
        var logger = logger();

        if (logger.isInfoEnabled(tag)) {
            logger.info(tag, withTick(format(format, args)));
        }
    }

    /**
     * Logs a warning message.
     *
     * @param tag log category
     * @param message message to log
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code message} is null
     */
    public static void warn(LogTag tag, String message) {
        var logger = logger();

        if (logger.isWarnEnabled(tag)) {
            logger.warn(tag, withTick(message));
        }
    }

    /**
     * Logs a formatted warning message.
     *
     * @param tag log category
     * @param format format string
     * @param args format arguments
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code format} or {@code args} is null
     */
    public static void warnf(LogTag tag, String format, Object... args) {
        var logger = logger();

        if (logger.isWarnEnabled(tag)) {
            logger.warn(tag, withTick(format(format, args)));
        }
    }

    /**
     * Logs an error message.
     *
     * @param tag log category
     * @param message message to log
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code message} is null
     */
    public static void error(LogTag tag, String message) {
        var logger = logger();

        if (logger.isErrorEnabled(tag)) {
            logger.error(tag, withTick(message));
        }
    }

    /**
     * Logs an error message with an associated throwable.
     *
     * @param tag log category
     * @param message message to log
     * @param throwable associated throwable
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code message} or {@code throwable} is null
     */
    public static void error(LogTag tag, String message, Throwable throwable) {
        var logger = logger();

        if (logger.isErrorEnabled(tag)) {
            Objects.requireNonNull(throwable, "throwable must not be null");
            logger.error(tag, withTick(message), throwable);
        }
    }

    /**
     * Logs a formatted error message.
     *
     * @param tag log category
     * @param format format string
     * @param args format arguments
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if {@code format} or {@code args} is null
     */
    public static void errorf(LogTag tag, String format, Object... args) {
        var logger = logger();

        if (logger.isErrorEnabled(tag)) {
            logger.error(tag, withTick(format(format, args)));
        }
    }

    /**
     * Logs a formatted error message with an associated throwable.
     *
     * @param tag log category
     * @param throwable associated throwable
     * @param format format string
     * @param args format arguments
     *
     * @throws IllegalStateException if logging has not been initialized
     * @throws NullPointerException if any argument is null
     */
    public static void errorf(
            LogTag tag,
            Throwable throwable,
            String format,
            Object... args
    ) {
        var logger = logger();

        if (!logger.isErrorEnabled(tag)) {
            Objects.requireNonNull(throwable, "throwable must not be null");
            logger.error(tag, withTick(format(format, args)), throwable);
        }
    }

    private static GameLogger logger() {
        if (logger == null) {
            throw new IllegalStateException("GameLog must be initialized before use");
        }
        return logger;
    }

    private static String withTick(String message) {
        var ticks = tickSupplier.getAsLong();
        return String.format(Locale.ENGLISH, "[T:%04d] ", ticks) + message;
    }

    private static String format(String format, Object... args) {
        return String.format(Locale.ENGLISH, format, args);
    }
}
