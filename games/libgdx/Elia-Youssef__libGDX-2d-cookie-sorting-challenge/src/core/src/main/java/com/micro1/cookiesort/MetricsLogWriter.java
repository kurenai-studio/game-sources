package com.micro1.cookiesort;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Pure formatting helper (no {@code Gdx.*} statics, unit-testable): the log file name and body. Actually
 * writing the file (via {@code Gdx.files.local(...)}) is done by the caller ({@link CookieSortGame}), which
 * is the one place that needs a live libGDX context.
 */
public final class MetricsLogWriter {

    private MetricsLogWriter() {
    }

    /** dd-MM-yyyy-HH-mm-ss-metrics.log, e.g. 27-05-2026-11-45-01-metrics.log for the reference sample. */
    public static String fileName(Date when) {
        SimpleDateFormat format = new SimpleDateFormat("dd-MM-yyyy-HH-mm-ss");
        return format.format(when) + "-metrics.log";
    }

    /** The full log body: one labeled key:value line per metric, newline-terminated. */
    public static String body(Metrics metrics) {
        StringBuilder sb = new StringBuilder();
        for (String line : metrics.toLogLines()) {
            sb.append(line).append('\n');
        }
        return sb.toString();
    }
}
