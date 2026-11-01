/**
 * Run recording and the local history: high scores and lifetime stats.
 *
 * <p>A {@link com.tomer.scoundrel.runs.RunRecorder} watches one game from
 * outside the engine, fed every {@code MoveResult} by the screen, and turns
 * the events into a {@link com.tomer.scoundrel.runs.RunRecord}. The
 * {@link com.tomer.scoundrel.runs.RunLog} appends each record as one line of
 * {@code ~/.scoundrel/runs.log}. {@link com.tomer.scoundrel.runs.HighScores}
 * and {@link com.tomer.scoundrel.runs.RunTotals} are pure views over the list
 * it reads back. Only finished games are recorded. A game left partway is
 * never counted.
 *
 * <p>The file format is tolerant and versioned: tab-separated
 * {@code key=value} pairs, unknown keys ignored, and a line that will not parse
 * is skipped rather than thrown on. Erasing moves the file aside to a
 * {@code .bak} instead of deleting it.
 *
 * <p>Pure Java with no LibGDX, and gated by the coverage check. This package
 * reads the engine's events but the engine never imports it, and it never
 * imports {@code achievements}.
 *
 * @see java.nio.file.Files
 */
package com.tomer.scoundrel.runs;
