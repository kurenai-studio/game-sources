/**
 * Achievements: the catalog, the end-of-run evaluation and the unlocked latch.
 *
 * <p>An {@link com.tomer.scoundrel.achievements.AchievementTracker} watches one
 * game's events and distils a {@link com.tomer.scoundrel.achievements.RunSummary}.
 * When the run ends,
 * {@link com.tomer.scoundrel.achievements.AchievementService#newlyEarned} tests
 * every rule in {@link com.tomer.scoundrel.achievements.Achievements} against
 * that summary and the run history, and the caller latches what is new in the
 * {@link com.tomer.scoundrel.achievements.AchievementStore}
 * ({@code ~/.scoundrel/achievements.log}). Only the unlocks are stored.
 * Progress toward a milestone is derived from the run history each time,
 * never kept.
 *
 * <p>Only runs in a mode that
 * {@link com.tomer.scoundrel.rules.GameMode#tracksAchievements() tracks achievements}
 * (Standard) are evaluated, and the catalog's thresholds assume the standard
 * ruleset.
 *
 * <p>Pure Java with no LibGDX, and gated by the coverage check. It reads the
 * engine's events and the {@code runs} history. The engine never imports it,
 * and neither does {@code runs}.
 */
package com.tomer.scoundrel.achievements;
