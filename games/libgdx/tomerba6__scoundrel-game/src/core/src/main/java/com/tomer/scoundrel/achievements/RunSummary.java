package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.model.Status;

/**
 * The notable facts of one finished game, richer than a persisted
 * {@link com.tomer.scoundrel.runs.RunRecord}: it also carries final health and
 * the bare-handed-kill and flawless-room facts the achievement rules test.
 * Built by {@link AchievementTracker} from the event stream and never itself
 * persisted — only the unlocked latch outlives a session.
 *
 * @param outcome               {@link Status#WON} or {@link Status#LOST}
 * @param score                 the final score, as the engine computed it
 * @param finalHealth           health after the last move; zero or below on a loss
 * @param seconds               wall-clock length of the run, from the run timer
 * @param highestBarehandedKill the highest monster value killed barehanded (2–14), 0 if none
 * @param barehandedKillCount   monsters killed barehanded, 0 or more
 * @param flawlessRoom          true if some full turn killed at least one monster and took
 *                              no damage
 */
public record RunSummary(
        Status outcome,
        int score,
        int finalHealth,
        long seconds,
        int highestBarehandedKill,
        int barehandedKillCount,
        boolean flawlessRoom) {
}
