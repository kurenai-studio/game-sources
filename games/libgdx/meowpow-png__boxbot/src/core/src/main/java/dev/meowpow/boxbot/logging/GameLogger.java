package dev.meowpow.boxbot.logging;

/**
 * Logging backend used by {@link GameLog}.
 */
public interface GameLogger {

    /**
     * Logs a debug message.
     *
     * @param tag log category
     * @param message message to log
     */
    void debug(LogTag tag, String message);

    /**
     * Logs an informational message.
     *
     * @param tag log category
     * @param message message to log
     */
    void info(LogTag tag, String message);

    /**
     * Logs a warning message.
     *
     * @param tag log category
     * @param message message to log
     */
    void warn(LogTag tag, String message);

    /**
     * Logs an error message.
     *
     * @param tag log category
     * @param message message to log
     */
    void error(LogTag tag, String message);

    /**
     * Logs an error message with an associated throwable.
     *
     * @param tag log category
     * @param message message to log
     * @param throwable associated throwable
     */
    void error(LogTag tag, String message, Throwable throwable);

    /**
     * Checks whether debug logging
     * is enabled for the given category.
     *
     * @param tag log category
     *
     * @return whether debug logging is enabled
     */
    boolean isDebugEnabled(LogTag tag);

    /**
     * Checks whether informational logging
     * is enabled for the given category.
     *
     * @param tag log category
     *
     * @return whether informational logging is enabled
     */
    boolean isInfoEnabled(LogTag tag);

    /**
     * Checks whether warning logging
     * is enabled for the given category.
     *
     * @param tag log category
     *
     * @return whether warning logging is enabled
     */
    boolean isWarnEnabled(LogTag tag);

    /**
     * Checks whether error logging
     * is enabled for the given category.
     *
     * @param tag log category
     *
     * @return whether error logging is enabled
     */
    boolean isErrorEnabled(LogTag tag);
}
