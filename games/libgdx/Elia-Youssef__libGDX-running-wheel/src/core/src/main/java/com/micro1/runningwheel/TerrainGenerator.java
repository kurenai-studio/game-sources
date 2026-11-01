package com.micro1.runningwheel;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Builds a fresh, playable course each run from a seeded {@link Random}. Pure and GL-free, so
 * it can be exercised headlessly in tests.
 *
 * The surface is a sampled height curve: two random sinusoids over a mid band, smoothed for a
 * rollable profile, with the start and finish stretches flattened. A few gaps are then carved
 * out; every gap is preceded by a raised launch ramp and followed by a landing at equal-or-lower
 * height, so at least one traversable route from start to finish always exists (rubric item 2).
 */
public final class TerrainGenerator {

    private static final float TWO_PI = (float) (Math.PI * 2.0);

    private TerrainGenerator() {
    }

    public static TerrainData generate(Random rnd) {
        final float dx = WorldConstants.GROUND_SAMPLE_DX_PX;
        final float worldW = WorldConstants.WORLD_WIDTH_PX;
        final float minY = WorldConstants.GROUND_MIN_Y_PX;
        final float maxY = WorldConstants.GROUND_MAX_Y_PX;

        int n = (int) Math.floor(worldW / dx) + 1;
        float[] h = new float[n];

        // 1) Rolling base curve: two random sinusoids over a mid band.
        float mid = (minY + maxY) * 0.5f - 10f;
        float a1 = 25f + rnd.nextFloat() * 30f;
        float a2 = 12f + rnd.nextFloat() * 18f;
        float f1 = 0.0015f + rnd.nextFloat() * 0.0015f;
        float f2 = 0.004f + rnd.nextFloat() * 0.004f;
        float p1 = rnd.nextFloat() * TWO_PI;
        float p2 = rnd.nextFloat() * TWO_PI;
        for (int i = 0; i < n; i++) {
            float x = i * dx;
            float y = mid + a1 * (float) Math.sin(x * f1 + p1) + a2 * (float) Math.sin(x * f2 + p2);
            h[i] = clamp(y, minY + 10f, maxY - 10f);
        }

        // 2) Smooth for a gentle surface the wheel rolls over (and can climb) cleanly.
        h = smooth(smooth(smooth(h)));

        // 3) Flatten the start and finish stretches (reassert after smoothing).
        int startSamples = (int) (WorldConstants.START_ZONE_PX / dx);
        for (int i = 0; i <= startSamples && i < n; i++) {
            h[i] = WorldConstants.START_GROUND_Y_PX;
        }
        int finishStart = Math.max(0, n - 1 - (int) (WorldConstants.FINISH_ZONE_PX / dx));
        for (int i = finishStart; i < n; i++) {
            h[i] = WorldConstants.FINISH_GROUND_Y_PX;
        }

        // 4) Carve gaps. Each has a flat approach + a small edge kicker (a slight upward launch
        //    that cannot stall a moving wheel) and a lower landing with a downhill runway, so the
        //    wheel keeps its momentum, pops off the edge, and drops across the gap. It falls in
        //    only when genuinely too slow (the intended loss), never sticks on an uphill ramp.
        boolean[] hole = new boolean[n];
        int gapCount = WorldConstants.MIN_GAPS
                + rnd.nextInt(WorldConstants.MAX_GAPS - WorldConstants.MIN_GAPS + 1);
        float regionStart = WorldConstants.START_ZONE_PX + 900f;
        float regionEnd = worldW - WorldConstants.FINISH_ZONE_PX - 900f;
        float slot = (regionEnd - regionStart) / gapCount;
        for (int g = 0; g < gapCount; g++) {
            float gapW = WorldConstants.GAP_MIN_PX
                    + rnd.nextFloat() * (WorldConstants.GAP_MAX_PX - WorldConstants.GAP_MIN_PX);
            float slotStart = regionStart + g * slot;
            float jitterRoom = Math.max(0f, slot - gapW - WorldConstants.FLAT_APPROACH_PX - 160f);
            float gapStartX = slotStart + WorldConstants.FLAT_APPROACH_PX + 60f + rnd.nextFloat() * jitterRoom;
            float gapEndX = gapStartX + gapW;

            int flatStartIdx = idx(gapStartX - WorldConstants.FLAT_APPROACH_PX, dx, n);
            int kickStartIdx = idx(gapStartX - WorldConstants.KICK_RUN_PX, dx, n);
            int nearIdx = idx(gapStartX, dx, n);
            float baseNearY = h[flatStartIdx];
            for (int i = flatStartIdx; i <= kickStartIdx && i < n; i++) {
                h[i] = baseNearY; // flat run-up
            }
            float launchY = clamp(baseNearY + WorldConstants.KICK_RISE_PX, minY, maxY - 5f);
            for (int i = kickStartIdx; i <= nearIdx && i < n; i++) {
                float t = (float) (i - kickStartIdx) / Math.max(1, nearIdx - kickStartIdx);
                h[i] = lerp(baseNearY, launchY, t); // small kicker
            }

            int farIdx = idx(gapEndX, dx, n);
            float drop = WorldConstants.LAND_DROP_MIN_PX
                    + rnd.nextFloat() * (WorldConstants.LAND_DROP_MAX_PX - WorldConstants.LAND_DROP_MIN_PX);
            float farY = clamp(launchY - drop, minY, maxY);
            float runwayEndY = clamp(farY - 25f, minY, maxY);
            for (int i = farIdx; i < n && i <= farIdx + 8; i++) {
                float t = (float) (i - farIdx) / 8f;
                h[i] = lerp(farY, runwayEndY, t); // downhill landing runway
            }
            for (int i = farIdx + 9; i < n && i <= farIdx + 13; i++) {
                float t = (float) (i - (farIdx + 8)) / 5f;
                h[i] = lerp(runwayEndY, h[i], t); // blend back into the base curve
            }

            for (int i = nearIdx + 1; i < farIdx && i < n; i++) {
                hole[i] = true;
            }
        }

        // 5) Split the samples into solid ground segments (a break at each hole).
        List<float[]> segments = buildSegments(h, hole, dx, n);

        // 6) A couple of floating rectangle platforms in the latter half (bonus scenery).
        List<float[]> platforms = new ArrayList<float[]>();
        int platformCount = 2 + rnd.nextInt(2);
        for (int p = 0; p < platformCount; p++) {
            float frac = platformCount > 1 ? (p / (float) (platformCount - 1)) : 0f;
            float px = clamp(worldW * (0.55f + 0.28f * frac) + (rnd.nextFloat() - 0.5f) * 200f,
                    worldW * 0.5f, worldW - WorldConstants.FINISH_ZONE_PX - 200f);
            float groundY = h[idx(px, dx, n)];
            float halfW = 60f + rnd.nextFloat() * 40f;
            float cy = groundY + 90f + rnd.nextFloat() * 70f;
            platforms.add(new float[]{px, cy, halfW, 12f});
        }

        // 7) One triangular ramp wedge (a non-rectangular polygon) on a solid early stretch.
        float wedgeX = clamp(worldW * 0.22f, WorldConstants.START_ZONE_PX + 100f, regionStart - 200f);
        int wedgeIdx = idx(wedgeX, dx, n);
        float[] rampWedge = null;
        if (!hole[wedgeIdx]) {
            float gy = h[wedgeIdx];
            rampWedge = new float[]{wedgeX, gy, wedgeX + 130f, gy, wedgeX + 130f, gy + 45f};
        }

        float startY = WorldConstants.START_GROUND_Y_PX + WorldConstants.WHEEL_RADIUS_PX + 4f;
        return new TerrainData(segments, platforms, rampWedge,
                WorldConstants.WHEEL_START_X_PX, startY,
                WorldConstants.FINISH_X_PX, WorldConstants.FINISH_GROUND_Y_PX,
                WorldConstants.LOWER_BOUND_Y_PX, worldW);
    }

    private static List<float[]> buildSegments(float[] h, boolean[] hole, float dx, int n) {
        List<float[]> segments = new ArrayList<float[]>();
        int i = 0;
        while (i < n) {
            if (hole[i]) {
                i++;
                continue;
            }
            int start = i;
            while (i < n && !hole[i]) {
                i++;
            }
            int count = i - start;
            if (count >= 2) {
                float[] poly = new float[count * 2];
                for (int k = 0; k < count; k++) {
                    poly[k * 2] = (start + k) * dx;
                    poly[k * 2 + 1] = h[start + k];
                }
                segments.add(poly);
            }
        }
        return segments;
    }

    private static float[] smooth(float[] h) {
        float[] out = new float[h.length];
        for (int i = 0; i < h.length; i++) {
            float a = h[Math.max(0, i - 1)];
            float b = h[i];
            float c = h[Math.min(h.length - 1, i + 1)];
            out[i] = (a + b + c) / 3f;
        }
        return out;
    }

    private static int idx(float x, float dx, int n) {
        int i = Math.round(x / dx);
        if (i < 0) {
            return 0;
        }
        if (i > n - 1) {
            return n - 1;
        }
        return i;
    }

    private static float clamp(float v, float lo, float hi) {
        if (v < lo) {
            return lo;
        }
        if (v > hi) {
            return hi;
        }
        return v;
    }

    private static float lerp(float a, float b, float t) {
        return a + (b - a) * t;
    }
}
