package com.micro1.cookiesort;

import com.badlogic.gdx.utils.TimeUtils;

import java.util.Random;

/**
 * GL-free simulation core: layout, the plate-assignment rules, the drag lifecycle, the timer, win/loss,
 * and metrics accumulation. No {@code Gdx.graphics}/{@code Gdx.input} statics are touched here, so the
 * whole mechanic is unit-testable without a live window. See BUILD-PLAN.md for the exact rules.
 */
public class CookieSortWorld {

    public enum State { PLAYING, WON, LOST }

    public static final int COOKIE_COUNT = 40;
    public static final float COUNTDOWN_SECONDS = 60f;

    public static final float WINDOW_W = 1600f;
    public static final float WINDOW_H = 1200f;

    public static final float CENTER_CX = 800f;
    public static final float CENTER_CY = 560f;
    public static final float CENTER_PACK_RADIUS = 190f;

    public static final float CORNER_PACK_RADIUS = 75f;

    // Visual radii derived from the supplied PNGs' measured solid-circle fraction of texture width, at the
    // on-screen draw sizes chosen in BUILD-PLAN.md (center cookie 90px, corner plate 260px).
    public static final float COOKIE_HIT_RADIUS = 26.1f;
    public static final float CORNER_HIT_RADIUS = 91.3f;

    private static final double GOLDEN_ANGLE = Math.PI * (3.0 - Math.sqrt(5.0));

    public final Cookie[] cookies = new Cookie[COOKIE_COUNT];
    public final CornerPlate[] corners = new CornerPlate[Corner.values().length];
    public final Metrics metrics = new Metrics();

    public State state = State.PLAYING;
    public float remainingSeconds = COUNTDOWN_SECONDS;

    private final Random random;
    private int lightAssignedCount;
    private int darkAssignedCount;
    private int placedCount;

    private int draggingCookieId = -1;
    private long dragStartTimeMs;
    private float currentDragDistance;
    private float lastDragX;
    private float lastDragY;
    private long lastActionEndTimeMs;
    private boolean logPending;

    public CookieSortWorld() {
        this(new Random());
    }

    public CookieSortWorld(Random random) {
        this.random = random;
        corners[Corner.TOP_LEFT.ordinal()] = new CornerPlate(Corner.TOP_LEFT, 230f, 980f);
        corners[Corner.TOP_RIGHT.ordinal()] = new CornerPlate(Corner.TOP_RIGHT, 1370f, 980f);
        corners[Corner.BOTTOM_LEFT.ordinal()] = new CornerPlate(Corner.BOTTOM_LEFT, 230f, 220f);
        corners[Corner.BOTTOM_RIGHT.ordinal()] = new CornerPlate(Corner.BOTTOM_RIGHT, 1370f, 220f);
        reset();
    }

    /** Starts a fresh session: empty/unassigned corners, a new shuffled 40-cookie deck, zeroed metrics. */
    public void reset() {
        state = State.PLAYING;
        remainingSeconds = COUNTDOWN_SECONDS;
        metrics.reset();
        lightAssignedCount = 0;
        darkAssignedCount = 0;
        placedCount = 0;
        draggingCookieId = -1;
        logPending = false;
        lastActionEndTimeMs = TimeUtils.millis();
        for (CornerPlate plate : corners) {
            plate.reset();
        }

        CookieType[] types = new CookieType[COOKIE_COUNT];
        int lightCount = 0;
        int darkCount = 0;
        for (int i = 0; i < COOKIE_COUNT; i++) {
            boolean light = random.nextBoolean();
            types[i] = light ? CookieType.LIGHT : CookieType.DARK;
            if (light) lightCount++;
            else darkCount++;
        }
        // Guarantee at least one of each (rubric item 26); at n=40 both cannot legitimately be zero at once.
        if (lightCount == 0) types[0] = CookieType.LIGHT;
        if (darkCount == 0) types[0] = CookieType.DARK;
        for (int i = types.length - 1; i > 0; i--) {
            int j = random.nextInt(i + 1);
            CookieType tmp = types[i];
            types[i] = types[j];
            types[j] = tmp;
        }

        float[] slot = new float[2];
        for (int i = 0; i < COOKIE_COUNT; i++) {
            sunflowerSlot(i, CENTER_PACK_RADIUS, CENTER_CX, CENTER_CY, slot);
            cookies[i] = new Cookie(i, types[i], slot[0], slot[1]);
        }
    }

    public void update(float dt) {
        if (state != State.PLAYING) return;
        remainingSeconds -= dt;
        if (remainingSeconds <= 0f) {
            remainingSeconds = 0f;
            clearActiveDrag();
            state = State.LOST;
            logPending = true;
        }
    }

    /** Topmost (highest-index) center-plate cookie whose visible circle contains the point, or -1. */
    public int hitTestCenterCookie(float px, float py) {
        for (int i = COOKIE_COUNT - 1; i >= 0; i--) {
            Cookie cookie = cookies[i];
            if (cookie.isOnCenterPlate() && dist(px, py, cookie.x, cookie.y) <= COOKIE_HIT_RADIUS) {
                return i;
            }
        }
        return -1;
    }

    public boolean isDragging() {
        return draggingCookieId >= 0;
    }

    public Cookie draggedCookie() {
        return draggingCookieId >= 0 ? cookies[draggingCookieId] : null;
    }

    /** Starts a drag if the game is live, no drag is already active, and the point hits a center cookie. */
    public boolean beginDrag(float px, float py, long nowMs) {
        if (state != State.PLAYING || isDragging()) return false;
        int hit = hitTestCenterCookie(px, py);
        if (hit < 0) return false;
        metrics.addIdleTime(nowMs - lastActionEndTimeMs);
        draggingCookieId = hit;
        dragStartTimeMs = nowMs;
        currentDragDistance = 0f;
        lastDragX = px;
        lastDragY = py;
        return true;
    }

    public void updateDrag(float px, float py) {
        if (state != State.PLAYING || !isDragging()) return;
        currentDragDistance += dist(lastDragX, lastDragY, px, py);
        lastDragX = px;
        lastDragY = py;
        Cookie cookie = cookies[draggingCookieId];
        cookie.x = px;
        cookie.y = py;
    }

    /** Ends the active drag: a placement attempt if released over a corner plate, else a cancellation. */
    public void endDrag(float px, float py, long nowMs) {
        if (state != State.PLAYING || !isDragging()) return;
        updateDrag(px, py);
        Cookie cookie = cookies[draggingCookieId];
        Corner target = hitTestCorner(px, py);
        if (target != null) {
            CornerPlate plate = corners[target.ordinal()];
            boolean accepted = attemptPlacement(cookie, plate);
            if (!accepted) cookie.returnHome();
            metrics.recordPlacementAttempt(target, accepted, nowMs - dragStartTimeMs, currentDragDistance);
            if (accepted && placedCount == COOKIE_COUNT) {
                state = State.WON;
                logPending = true;
            }
        } else {
            cookie.returnHome();
            metrics.recordCancellation();
        }
        draggingCookieId = -1;
        lastActionEndTimeMs = nowMs;
    }

    /**
     * QA-only shortcut (never called from real input handling) that forces a terminal state so the
     * launcher's offscreen capture path can screenshot the win/loss overlay without playing a full round.
     * On a forced win, cookies are round-robined across BOTH plates assigned to their type (not dumped
     * onto whichever plate claimed that type first), so the screenshot is representative of a real win
     * where all four corner plates end up populated.
     */
    public void forceTerminalForQA(boolean win) {
        if (win) {
            for (CornerPlate plate : corners) plate.reset();
            lightAssignedCount = 0;
            darkAssignedCount = 0;
            placedCount = 0;
            for (Cookie cookie : cookies) {
                place(cookie, pickOrAssignPlateForQA(cookie.type));
            }
            state = State.WON;
        } else {
            remainingSeconds = 0f;
            state = State.LOST;
        }
        logPending = true;
    }

    /** QA-only helper: the emptier of a type's two plates, assigning a second/first plate on demand. */
    private CornerPlate pickOrAssignPlateForQA(CookieType type) {
        CornerPlate first = null;
        CornerPlate second = null;
        for (CornerPlate plate : corners) {
            if (plate.assignedType == type) {
                if (first == null) first = plate;
                else second = plate;
            }
        }
        if (first != null && second != null) {
            return (first.placedCookieIds.size() <= second.placedCookieIds.size()) ? first : second;
        }
        for (CornerPlate plate : corners) {
            if (!plate.isAssigned()) {
                plate.assignedType = type;
                if (type == CookieType.LIGHT) lightAssignedCount++;
                else darkAssignedCount++;
                return (first == null || plate.placedCookieIds.size() <= first.placedCookieIds.size())
                    ? plate : first;
            }
        }
        return first; // no unassigned plate left; both plates for this type already exist and were handled above
    }

    /** True exactly once per win/loss transition; the caller should write the metrics log on this edge. */
    public boolean consumeLogPending() {
        if (logPending) {
            logPending = false;
            return true;
        }
        return false;
    }

    private boolean attemptPlacement(Cookie cookie, CornerPlate plate) {
        if (plate.isAssigned()) {
            if (plate.assignedType != cookie.type) return false;
            place(cookie, plate);
            return true;
        }
        int assignedForType = (cookie.type == CookieType.LIGHT) ? lightAssignedCount : darkAssignedCount;
        if (assignedForType >= 2) {
            // Both plates for this type are already spoken for; accepting here would leave the other
            // type with only one plate. Reject so the required 2-plates-per-type split always holds.
            return false;
        }
        plate.assignedType = cookie.type;
        if (cookie.type == CookieType.LIGHT) lightAssignedCount++;
        else darkAssignedCount++;
        place(cookie, plate);
        return true;
    }

    private void place(Cookie cookie, CornerPlate plate) {
        cookie.placedOn = plate.corner;
        plate.placedCookieIds.add(cookie.id);
        float[] slot = new float[2];
        sunflowerSlot(plate.placedCookieIds.size() - 1, CORNER_PACK_RADIUS, plate.cx, plate.cy, slot);
        cookie.x = slot[0];
        cookie.y = slot[1];
        placedCount++;
    }

    private void clearActiveDrag() {
        if (!isDragging()) return;
        cookies[draggingCookieId].returnHome();
        draggingCookieId = -1;
        currentDragDistance = 0f;
    }

    private Corner hitTestCorner(float px, float py) {
        for (CornerPlate plate : corners) {
            if (dist(px, py, plate.cx, plate.cy) <= CORNER_HIT_RADIUS) {
                return plate.corner;
            }
        }
        return null;
    }

    private static void sunflowerSlot(int i, float packRadius, float cx, float cy, float[] out) {
        double r = packRadius * Math.sqrt((i + 0.5) / COOKIE_COUNT);
        double theta = i * GOLDEN_ANGLE;
        out[0] = cx + (float) (r * Math.cos(theta));
        out[1] = cy + (float) (r * Math.sin(theta));
    }

    private static float dist(float x1, float y1, float x2, float y2) {
        float dx = x1 - x2;
        float dy = y1 - y2;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }
}
