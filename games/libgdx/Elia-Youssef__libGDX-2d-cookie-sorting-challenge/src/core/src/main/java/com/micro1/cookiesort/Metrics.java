package com.micro1.cookiesort;

/**
 * Every analytics counter collected during a session, plus the fixed key:value log line format.
 * {@code totalCookiesMoved} counts only real placement attempts (a drag released over a corner plate,
 * whether accepted or rejected) - a cancellation (released outside every corner plate) is tracked
 * separately in {@code dragCancellations} and does not add to totalCookiesMoved, totalMovementTimeMs, or
 * totalDragDistancePx. This matches the reference log, where totalCookiesMoved (45) equals
 * successfulPlacements (35) + failedPlacements (10) exactly, with dragCancellations (5) sitting outside
 * that sum. See BUILD-PLAN.md -> "Metrics model".
 */
public class Metrics {
    public int totalCookiesMoved;
    public int successfulPlacements;
    public int failedPlacements;
    public long totalMovementTimeMs;
    public float totalDragDistancePx;
    public final int[] cornerUsageCount = new int[Corner.values().length];
    public long idleTimeMs;
    public int dragCancellations;

    public void reset() {
        totalCookiesMoved = 0;
        successfulPlacements = 0;
        failedPlacements = 0;
        totalMovementTimeMs = 0L;
        totalDragDistancePx = 0f;
        for (int i = 0; i < cornerUsageCount.length; i++) cornerUsageCount[i] = 0;
        idleTimeMs = 0L;
        dragCancellations = 0;
    }

    public void recordPlacementAttempt(Corner target, boolean accepted, long movementTimeMs, float dragDistancePx) {
        totalCookiesMoved++;
        if (accepted) successfulPlacements++;
        else failedPlacements++;
        totalMovementTimeMs += movementTimeMs;
        totalDragDistancePx += dragDistancePx;
        cornerUsageCount[target.ordinal()]++;
    }

    public void recordCancellation() {
        dragCancellations++;
    }

    public void addIdleTime(long ms) {
        if (ms > 0) idleTimeMs += ms;
    }

    public long averageMovementTimeMs() {
        return totalCookiesMoved == 0 ? 0L : totalMovementTimeMs / totalCookiesMoved;
    }

    /** The corner label(s) with the highest usage count, comma-joined on a tie. Empty if never used. */
    public String mostFrequentlyUsedCorners() {
        int max = 0;
        for (int count : cornerUsageCount) {
            if (count > max) max = count;
        }
        if (max == 0) return "none";
        StringBuilder sb = new StringBuilder();
        Corner[] corners = Corner.values();
        for (int i = 0; i < corners.length; i++) {
            if (cornerUsageCount[i] == max) {
                if (sb.length() > 0) sb.append(", ");
                sb.append(corners[i].label);
            }
        }
        return sb.toString();
    }

    /** The fixed, labeled key:value lines written to the metrics log (rubric item 22's stable format). */
    public String[] toLogLines() {
        return new String[] {
            "total_cookies_moved: " + totalCookiesMoved,
            "number_of_successful_placements: " + successfulPlacements,
            "number_of_failed_placements: " + failedPlacements,
            "average_movement_time_per_cookie: " + averageMovementTimeMs() + "ms",
            "total_drag_distance: " + Math.round(totalDragDistancePx) + "px",
            "most_frequently_used_corner_plates: " + mostFrequentlyUsedCorners(),
            "idle_time_between_actions: " + idleTimeMs + "ms",
            "number_of_drag_cancellations: " + dragCancellations
        };
    }
}
