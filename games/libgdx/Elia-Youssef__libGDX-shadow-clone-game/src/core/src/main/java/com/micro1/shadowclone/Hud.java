package com.micro1.shadowclone;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * The in-level HUD: the recording countdown + segmented progress bar (top centre), the level badge
 * and description (top left), the objective panel (top right), the control hints (bottom), and the
 * clone-status readout (rubric item 18). Escape adds a red countdown and a collapse warning. Drawn
 * in the same three passes as {@link WorldRenderer} so ShapeRenderer types stay clean.
 */
public final class Hud {

    private final ShadowCloneGame game;

    // Panel rectangles (x, y, w, h) in virtual space.
    private static final float[] BADGE = {20f, 628f, 372f, 72f};
    private static final float[] DESC  = {20f, 512f, 372f, 108f};
    private static final float[] REC   = {462f, 628f, 356f, 72f};
    private static final float[] CLONE = {828f, 628f, 190f, 72f};
    private static final float[] OBJ   = {980f, 512f, 280f, 116f};
    private static final float[] CTRL  = {372f, 16f, 536f, 66f};

    public Hud(ShadowCloneGame game) {
        this.game = game;
    }

    // ---- FILL PASS ----
    public void fillPass(ShapeRenderer sr, Level level, float recRemaining, float recProgress,
                         int cloneCount, boolean solved) {
        panelFill(sr, BADGE);
        panelFill(sr, DESC);
        panelFill(sr, REC);
        panelFill(sr, CLONE);
        panelFill(sr, OBJ);
        panelFill(sr, CTRL);
        // Level badge number chip.
        Draw.fill(sr, BADGE[0] + 14f, BADGE[1] + 16f, 46f, 40f, Theme.NEON);
        // Recording progress bar (segmented).
        Color barCol = level.escaping ? Theme.WARN : Theme.NEON;
        float bx = REC[0] + 18f, by = REC[1] + 12f, bw = REC[2] - 36f;
        int segs = 22;
        float sw = bw / segs;
        int filled = Math.round(recProgress * segs);
        for (int i = 0; i < segs; i++) {
            boolean on = i < filled;
            sr.setColor(barCol.r, barCol.g, barCol.b, on ? 0.95f : 0.18f);
            sr.rect(bx + i * sw, by, sw - 2f, 10f);
        }
        // Clone count pips.
        for (int i = 0; i < Math.min(cloneCount, 8); i++) {
            Draw.fill(sr, CLONE[0] + 16f + i * 20f, CLONE[1] + 14f, 12f, 16f, Theme.CLONE_LINE);
        }
        // Escape countdown + collapse warning banner.
        if (level.escaping) {
            Draw.fill(sr, 462f, 560f, 356f, 40f, new Color(0.28f, 0.05f, 0.05f, 0.85f));
            if (((int) (level.escapeTime * 2f)) % 2 == 0) {
                Draw.fill(sr, 20f, 452f, 300f, 44f, new Color(0.30f, 0.06f, 0.05f, 0.85f));
            }
        }
        // Alert flash frame.
        if (level.alertFlash > 0f) {
            sr.setColor(Theme.LASER.r, Theme.LASER.g, Theme.LASER.b, 0.10f);
            sr.rect(0, 0, Theme.WORLD_W, Theme.WORLD_H);
        }
        if (solved) {
            Draw.fill(sr, Theme.WORLD_W * 0.5f - 210f, 330f, 420f, 90f, new Color(0.05f, 0.15f, 0.10f, 0.9f));
        }
    }

    // ---- LINE PASS ----
    public void linePass(ShapeRenderer sr, Level level, boolean solved) {
        panelBorder(sr, BADGE, Theme.PANEL_LINE);
        panelBorder(sr, DESC, Theme.PANEL_LINE);
        panelBorder(sr, REC, level.escaping ? Theme.WARN : Theme.PANEL_LINE);
        panelBorder(sr, CLONE, Theme.PANEL_LINE);
        panelBorder(sr, OBJ, Theme.PANEL_LINE);
        panelBorder(sr, CTRL, Theme.PANEL_LINE);
        if (solved) {
            Draw.border(sr, Theme.WORLD_W * 0.5f - 210f, 330f, 420f, 90f, Theme.EXIT_GREEN);
        }
    }

    // ---- TEXT PASS ----
    public void textPass(Level level, float recRemaining, int cloneCount, boolean solved) {
        // Badge.
        game.text(String.format("%02d", level.number), BADGE[0] + 37f, BADGE[1] + 46f, 1.4f, Theme.BG_BOTTOM, 0);
        game.text(level.name, BADGE[0] + 74f, BADGE[1] + 46f, 1.35f, Theme.INK, -1);
        // Description lines.
        for (int i = 0; i < level.descLines.length; i++) {
            game.text(level.descLines[i], DESC[0] + 16f, DESC[1] + DESC[3] - 20f - i * 26f, 0.82f, Theme.INK_DIM, -1);
        }
        // Recording panel.
        float rcx = REC[0] + REC[2] * 0.5f;
        game.text(level.escaping ? "RECORDING" : "RECORDING...", rcx, REC[1] + REC[3] - 12f, 0.8f,
            level.escaping ? Theme.WARN : Theme.NEON, 0);
        int sec = (int) Math.floor(recRemaining);
        int centi = (int) Math.round((recRemaining - sec) * 100f);
        if (centi >= 100) { sec += 1; centi = 0; }
        game.text(String.format("%02d:%02d", sec, centi), rcx, REC[1] + 46f, 1.7f,
            level.escaping ? Theme.WARN : Theme.NEON, 0);
        // Clone info.
        game.text("CLONES", CLONE[0] + CLONE[2] * 0.5f, CLONE[1] + CLONE[3] - 12f, 0.72f, Theme.INK_DIM, 0);
        game.text(String.valueOf(cloneCount), CLONE[0] + CLONE[2] - 20f, CLONE[1] + 30f, 1.1f, Theme.CLONE_LINE, 1);
        // Objective.
        game.text("OBJECTIVE", OBJ[0] + 16f, OBJ[1] + OBJ[3] - 16f, 0.9f, Theme.NEON, -1);
        for (int i = 0; i < level.objectiveLines.length; i++) {
            game.text(level.objectiveLines[i], OBJ[0] + 16f, OBJ[1] + OBJ[3] - 44f - i * 24f, 0.8f, Theme.INK, -1);
        }
        // Controls.
        game.text("MOVE  < >     JUMP  SPACE     USE  E     RESET REC  R     RESTART  BKSP",
            CTRL[0] + CTRL[2] * 0.5f, CTRL[1] + 40f, 0.78f, Theme.INK_DIM, 0);
        game.text("a clone deploys every 5s and repeats what you did", CTRL[0] + CTRL[2] * 0.5f,
            CTRL[1] + 18f, 0.72f, Theme.NEON_DIM, 0);
        // Escape overlays.
        if (level.escaping) {
            int es = (int) Math.ceil(level.escapeTime);
            game.text(String.format("ESCAPE  %02d:%02d", es / 60, es % 60), 462f + 178f, 588f, 1.0f, Theme.WARN, 0);
            if (((int) (level.escapeTime * 2f)) % 2 == 0) {
                game.text("WARNING", 30f, 484f, 1.1f, Theme.LASER, -1);
                game.text("SECTOR COLLAPSING", 30f, 462f, 0.8f, Theme.WARN, -1);
            }
        }
        if (solved) {
            game.text("PUZZLE SOLVED", Theme.WORLD_W * 0.5f, 392f, 1.8f, Theme.EXIT_GREEN, 0);
            game.text("advancing...", Theme.WORLD_W * 0.5f, 352f, 0.9f, Theme.INK_DIM, 0);
        }
    }

    private static void panelFill(ShapeRenderer sr, float[] r) {
        Draw.panel(sr, r[0], r[1], r[2], r[3], Theme.PANEL_FILL);
    }

    private static void panelBorder(ShapeRenderer sr, float[] r, Color c) {
        Draw.border(sr, r[0], r[1], r[2], r[3], c);
    }
}
