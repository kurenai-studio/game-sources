package com.micro1.shadowclone;

import com.badlogic.gdx.graphics.Color;

/**
 * Palette, layout metrics and the shared tuning constants for Shadow Clone. Built fresh for this
 * game (a dark sci-fi facility: charcoal panels, neon cyan accents, holographic cyan clones, red
 * hazards). Kept as one place so the whole look can be read and adjusted at a glance.
 */
public final class Theme {

    private Theme() {}

    // --- Virtual resolution (world units = virtual pixels, origin bottom-left). --------------
    public static final float WORLD_W = 1280f;
    public static final float WORLD_H = 720f;

    // --- Simulation tuning. ------------------------------------------------------------------
    public static final float DT = 1f / 60f;            // fixed physics step
    public static final float RECORD_SECONDS = 5.0f;    // rolling recording window
    public static final float GRAVITY = -2100f;         // px / s^2
    public static final float MOVE_SPEED = 265f;        // px / s
    public static final float JUMP_VELOCITY = 760f;     // px / s  (~137px apex, ~3 tiles)
    public static final float MAX_FALL = -1500f;        // terminal fall speed
    public static final int MAX_CLONES = 24;            // render/logic cap; oldest dropped past this

    public static final float PLAYER_W = 30f;
    public static final float PLAYER_H = 46f;
    public static final float TILE = 40f;               // nominal platform thickness / grid unit

    // --- Backdrop + panels. ------------------------------------------------------------------
    public static final Color BG_TOP     = new Color(0.05f, 0.07f, 0.11f, 1f);
    public static final Color BG_BOTTOM  = new Color(0.02f, 0.03f, 0.06f, 1f);
    public static final Color WALL       = new Color(0.09f, 0.12f, 0.17f, 1f);
    public static final Color WALL_LINE  = new Color(0.14f, 0.19f, 0.28f, 1f);
    public static final Color PIPE       = new Color(0.11f, 0.15f, 0.22f, 1f);

    // --- Neon / UI. --------------------------------------------------------------------------
    public static final Color NEON       = new Color(0.28f, 0.82f, 1.00f, 1f);
    public static final Color NEON_DIM   = new Color(0.16f, 0.45f, 0.66f, 1f);
    public static final Color NEON_FAINT = new Color(0.14f, 0.30f, 0.44f, 1f);
    public static final Color PANEL_FILL = new Color(0.05f, 0.09f, 0.14f, 0.82f);
    public static final Color PANEL_LINE = new Color(0.24f, 0.55f, 0.78f, 1f);
    public static final Color INK        = new Color(0.78f, 0.90f, 0.98f, 1f);
    public static final Color INK_DIM    = new Color(0.50f, 0.66f, 0.78f, 1f);

    // --- Platforms / floor. ------------------------------------------------------------------
    public static final Color FLOOR      = new Color(0.16f, 0.20f, 0.26f, 1f);
    public static final Color FLOOR_TOP  = new Color(0.24f, 0.30f, 0.38f, 1f);
    public static final Color FLOOR_EDGE = new Color(0.10f, 0.13f, 0.18f, 1f);
    public static final Color HAZARD_STRIPE = new Color(0.85f, 0.72f, 0.20f, 1f);

    // --- Player + clone. ---------------------------------------------------------------------
    public static final Color PLAYER_BODY = new Color(0.15f, 0.18f, 0.27f, 1f);
    public static final Color PLAYER_TRIM = new Color(0.30f, 0.42f, 0.62f, 1f);
    public static final Color PLAYER_SKIN = new Color(0.83f, 0.66f, 0.53f, 1f);
    public static final Color PLAYER_HAIR = new Color(0.08f, 0.09f, 0.13f, 1f);
    public static final Color CLONE_FILL   = new Color(0.30f, 0.85f, 1.00f, 0.35f);
    public static final Color CLONE_LINE   = new Color(0.55f, 0.95f, 1.00f, 0.95f);

    // --- Interactables. ----------------------------------------------------------------------
    public static final Color SWITCH_BASE  = new Color(0.20f, 0.28f, 0.36f, 1f);
    public static final Color SWITCH_OFF   = new Color(0.22f, 0.55f, 0.78f, 1f);
    public static final Color SWITCH_ON    = new Color(0.35f, 1.00f, 0.72f, 1f);
    public static final Color DOOR_FRAME   = new Color(0.20f, 0.25f, 0.33f, 1f);
    public static final Color DOOR_LOCKED  = new Color(1.00f, 0.28f, 0.30f, 1f);
    public static final Color EXIT_GREEN   = new Color(0.38f, 0.95f, 0.48f, 1f);
    public static final Color EXIT_GLOW    = new Color(0.30f, 0.70f, 1.00f, 1f);

    // --- Hazards / fx. -----------------------------------------------------------------------
    public static final Color LASER       = new Color(1.00f, 0.24f, 0.26f, 1f);
    public static final Color LASER_GLOW  = new Color(1.00f, 0.30f, 0.30f, 0.35f);
    public static final Color LASER_OFF   = new Color(0.45f, 0.16f, 0.18f, 1f);
    public static final Color CAM_CONE    = new Color(1.00f, 0.95f, 0.80f, 0.10f);
    public static final Color CAM_ALERT   = new Color(1.00f, 0.30f, 0.30f, 0.18f);
    public static final Color WARN        = new Color(1.00f, 0.52f, 0.16f, 1f);
    public static final Color EMBER       = new Color(1.00f, 0.55f, 0.20f, 1f);
    public static final Color CORE        = new Color(0.55f, 0.40f, 1.00f, 1f);
    public static final Color CORE_HOT    = new Color(0.45f, 0.85f, 1.00f, 1f);
    public static final Color GOLD        = new Color(1.00f, 0.82f, 0.28f, 1f);

    /** Returns a copy of {@code base} with alpha multiplied by {@code a} (never mutates the input). */
    public static Color alpha(Color base, float a) {
        return new Color(base.r, base.g, base.b, base.a * a);
    }
}
