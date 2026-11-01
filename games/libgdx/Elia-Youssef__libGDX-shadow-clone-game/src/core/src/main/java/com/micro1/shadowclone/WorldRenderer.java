package com.micro1.shadowclone;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;

/**
 * Draws the facility and every entity in the dark sci-fi / neon-cyan style of the reference pack.
 * Three passes keep the ShapeRenderer types clean: {@link #fillPass} (backdrop + solid shapes),
 * {@link #linePass} (outlines), and {@link #textPass} (labels via the game font). The player is an
 * opaque dark figure; clones are translucent glowing cyan holograms (rubric item 28).
 */
public final class WorldRenderer {

    private final ShadowCloneGame game;

    public WorldRenderer(ShadowCloneGame game) {
        this.game = game;
    }

    // Core status panel (shown on the Clone Core level), in the clear upper-left band.
    private static final float[] CORE_PANEL = {40f, 350f, 290f, 160f};

    // ===================================================================== FILL PASS ==========
    public void fillPass(ShapeRenderer sr, Level level, Player player, Array<Clone> clones, float time) {
        backdrop(sr, level, time);
        for (Platform p : level.platforms) platformFill(sr, p, time);
        for (Laser l : level.lasers) laserFill(sr, l, time);
        for (Switch s : level.switches) switchFill(sr, s);
        if (level.core != null) { coreFill(sr, level.core, time); coreStatusFill(sr, level); }
        for (Door d : level.doors) doorFill(sr, d);
        for (SecurityCamera c : level.cameras) cameraFill(sr, c);
        for (Clone c : clones) figureFill(sr, c.x, c.y, c.w, c.h, true, time);
        figureFill(sr, player.x, player.y, player.w, player.h, false, time);
        if (level.escaping) collapseFx(sr, level, time);
    }

    private void coreStatusFill(ShapeRenderer sr, Level level) {
        float[] r = CORE_PANEL;
        Draw.panel(sr, r[0], r[1], r[2], r[3], Theme.PANEL_FILL);
        // Stability bar: red under 40, amber otherwise, cyan once stabilized.
        Core core = level.core;
        float frac = MathUtils.clamp(core.stability / 100f, 0f, 1f);
        Color bar = core.stabilized ? Theme.CORE_HOT : (core.stability < 40f ? Theme.LASER : Theme.WARN);
        float bx = r[0] + 20f, by = r[1] + r[3] - 78f, bw = r[2] - 40f;
        sr.setColor(0.15f, 0.18f, 0.25f, 1f);
        sr.rect(bx, by, bw, 14f);
        sr.setColor(bar);
        sr.rect(bx, by, bw * frac, 14f);
    }

    private void backdrop(ShapeRenderer sr, Level level, float time) {
        // Vertical gradient wall.
        sr.rect(0, 0, Theme.WORLD_W, Theme.WORLD_H,
            Theme.BG_BOTTOM, Theme.BG_BOTTOM, Theme.BG_TOP, Theme.BG_TOP);
        // Panel grid on the back wall.
        Color line = Theme.WALL_LINE;
        sr.setColor(line.r, line.g, line.b, 0.5f);
        for (float x = 0; x <= Theme.WORLD_W; x += 160f) sr.rect(x, 120f, 2f, Theme.WORLD_H - 120f);
        for (float y = 200f; y < Theme.WORLD_H; y += 130f) sr.rect(0, y, Theme.WORLD_W, 2f);
        // Pipes down the far sides.
        Draw.fill(sr, 24f, 120f, 14f, Theme.WORLD_H - 120f, Theme.PIPE);
        Draw.fill(sr, Theme.WORLD_W - 38f, 120f, 14f, Theme.WORLD_H - 120f, Theme.PIPE);
        // Two holographic cloning pods (sci-fi element, item 17).
        cloningPod(sr, 120f, 300f, time);
        cloningPod(sr, Theme.WORLD_W - 170f, 300f, time + 1.3f);
    }

    private void cloningPod(ShapeRenderer sr, float x, float y, float time) {
        float pulse = 0.35f + 0.15f * MathUtils.sinDeg(time * 120f);
        Draw.fill(sr, x, y, 50f, 150f, Theme.WALL);
        Draw.fill(sr, x + 8f, y + 10f, 34f, 130f, new Color(0.10f, 0.30f, 0.45f, 0.55f));
        sr.setColor(Theme.NEON.r, Theme.NEON.g, Theme.NEON.b, pulse);
        sr.rect(x + 18f, y + 20f, 14f, 110f);
        Draw.fill(sr, x - 4f, y - 8f, 58f, 12f, Theme.WALL_LINE);
        Draw.fill(sr, x - 4f, y + 150f, 58f, 12f, Theme.WALL_LINE);
    }

    private void platformFill(ShapeRenderer sr, Platform p, float time) {
        switch (p.kind) {
            case CONVEYOR: {
                Draw.fill(sr, p.x, p.y, p.w, p.h, Theme.FLOOR_EDGE);
                Draw.fill(sr, p.x, p.y + p.h - 10f, p.w, 10f, Theme.FLOOR);
                // Scrolling chevrons showing the belt direction.
                int dir = p.surfaceVX >= 0 ? 1 : -1;
                float spacing = 46f;
                float scroll = (time * 90f * dir) % spacing;
                for (float cx = p.x - spacing; cx < p.x + p.w + spacing; cx += spacing) {
                    float fx = cx + scroll;
                    if (fx < p.x + 6f || fx > p.x + p.w - 20f) continue;
                    Draw.triRight(sr, dir > 0 ? fx : fx + 16f, p.y + p.h - 5f, dir * 14f, 7f, Theme.HAZARD_STRIPE);
                }
                break;
            }
            case BRIDGE: {
                if (p.solid) {
                    Draw.glow(sr, p.x, p.y, p.w, p.h, Theme.NEON, 6f);
                    int tiles = Math.max(1, (int) (p.w / 60f));
                    float tw = p.w / tiles;
                    for (int i = 0; i < tiles; i++) {
                        Draw.fill(sr, p.x + i * tw + 2f, p.y, tw - 4f, p.h, new Color(0.20f, 0.55f, 0.85f, 0.9f));
                        Draw.fill(sr, p.x + i * tw + 2f, p.y + p.h - 5f, tw - 4f, 5f, Theme.NEON);
                    }
                } else {
                    // Ghost outline showing where the bridge will appear.
                    sr.setColor(Theme.NEON_FAINT.r, Theme.NEON_FAINT.g, Theme.NEON_FAINT.b, 0.25f);
                    int tiles = Math.max(1, (int) (p.w / 60f));
                    float tw = p.w / tiles;
                    for (int i = 0; i < tiles; i++) sr.rect(p.x + i * tw + 6f, p.y + p.h * 0.5f - 2f, tw - 12f, 3f);
                }
                break;
            }
            case ELEVATOR: {
                Draw.fill(sr, p.x, p.y, p.w, p.h, Theme.FLOOR);
                // Hazard stripes on top.
                for (float sx = p.x; sx < p.x + p.w - 10f; sx += 20f) {
                    Draw.fill(sr, sx, p.y + p.h - 6f, 10f, 6f, Theme.HAZARD_STRIPE);
                }
                Draw.fill(sr, p.x, p.y + p.h - 3f, p.w, 3f, Theme.NEON);
                break;
            }
            case MOVING: {
                Draw.fill(sr, p.x, p.y, p.w, p.h, Theme.FLOOR);
                Draw.fill(sr, p.x, p.y + p.h - 3f, p.w, 3f, Theme.NEON);
                break;
            }
            default: {
                Draw.fill(sr, p.x, p.y, p.w, p.h, Theme.FLOOR);
                Draw.fill(sr, p.x, p.y + p.h - 6f, p.w, 6f, Theme.FLOOR_TOP);
                // Neon underlighting strip.
                sr.setColor(Theme.NEON.r, Theme.NEON.g, Theme.NEON.b, 0.18f);
                sr.rect(p.x, p.y + p.h - 8f, p.w, 2f);
            }
        }
    }

    private void switchFill(ShapeRenderer sr, Switch s) {
        if (s.hidden) return;
        Color glow = s.active ? Theme.SWITCH_ON : Theme.SWITCH_OFF;
        if (s.kind == Switch.Kind.PLATE) {
            Draw.glow(sr, s.rect.x, s.rect.y, s.rect.width, s.rect.height, glow, 5f);
            Draw.fill(sr, s.rect.x, s.rect.y, s.rect.width, s.rect.height, Theme.SWITCH_BASE);
            Draw.fill(sr, s.rect.x + 4f, s.rect.y + s.rect.height - 6f, s.rect.width - 8f, 5f, glow);
        } else {
            // Terminal console.
            Draw.glow(sr, s.rect.x, s.rect.y, s.rect.width, s.rect.height, glow, 4f);
            Draw.fill(sr, s.rect.x, s.rect.y, s.rect.width, s.rect.height, Theme.SWITCH_BASE);
            Draw.fill(sr, s.rect.x + 5f, s.rect.y + 12f, s.rect.width - 10f, s.rect.height - 22f, glow);
        }
    }

    private void doorFill(ShapeRenderer sr, Door d) {
        if (d.open) {
            if (d.isExit) {
                Draw.glow(sr, d.rect.x, d.rect.y, d.rect.width, d.rect.height, Theme.EXIT_GLOW, 8f);
                Draw.fill(sr, d.rect.x, d.rect.y, d.rect.width, d.rect.height, new Color(0.10f, 0.28f, 0.45f, 0.7f));
                Draw.fill(sr, d.rect.x + 6f, d.rect.y, d.rect.width - 12f, d.rect.height, new Color(0.16f, 0.42f, 0.62f, 0.55f));
            }
        } else {
            Draw.fill(sr, d.rect.x, d.rect.y, d.rect.width, d.rect.height, Theme.DOOR_FRAME);
            Draw.fill(sr, d.rect.x + 6f, d.rect.y + 6f, d.rect.width - 12f, d.rect.height - 12f, new Color(0.13f, 0.16f, 0.22f, 1f));
            // Locked bar.
            Draw.fill(sr, d.rect.x + 8f, d.rect.y + d.rect.height - 22f, d.rect.width - 16f, 10f, Theme.DOOR_LOCKED);
        }
    }

    private void laserFill(ShapeRenderer sr, Laser l, float time) {
        boolean live = l.lethal();
        if (live) {
            Draw.glow(sr, l.rect.x, l.rect.y, l.rect.width, l.rect.height, Theme.LASER_GLOW, 6f);
            float flick = 0.85f + 0.15f * MathUtils.sinDeg(time * 900f);
            sr.setColor(Theme.LASER.r * flick, Theme.LASER.g, Theme.LASER.b, 1f);
            sr.rect(l.rect.x, l.rect.y, l.rect.width, l.rect.height);
            // Emitter caps.
            Draw.fill(sr, l.rect.x - 8f, l.rect.y - 6f, l.rect.width + 16f, 6f, Theme.WALL_LINE);
        } else {
            sr.setColor(Theme.LASER_OFF.r, Theme.LASER_OFF.g, Theme.LASER_OFF.b, 0.5f);
            sr.rect(l.rect.x + l.rect.width * 0.5f - 1f, l.rect.y, 2f, l.rect.height);
        }
    }

    private void cameraFill(ShapeRenderer sr, SecurityCamera c) {
        // Cone.
        Color cone = c.disabled ? new Color(0.3f, 0.3f, 0.35f, 0.06f)
            : (c.alerted ? Theme.CAM_ALERT : (c.distracted ? new Color(0.3f, 0.9f, 1f, 0.10f) : Theme.CAM_CONE));
        float a0 = c.angle - c.halfAngle, a1 = c.angle + c.halfAngle;
        float x1 = c.mountX + MathUtils.cosDeg(a0) * c.range, y1 = c.mountY + MathUtils.sinDeg(a0) * c.range;
        float x2 = c.mountX + MathUtils.cosDeg(a1) * c.range, y2 = c.mountY + MathUtils.sinDeg(a1) * c.range;
        sr.setColor(cone);
        sr.triangle(c.mountX, c.mountY, x1, y1, x2, y2);
        // Camera body.
        Draw.fill(sr, c.mountX - 16f, c.mountY - 8f, 32f, 16f, Theme.WALL_LINE);
        Color led = c.disabled ? Theme.INK_DIM : (c.alerted ? Theme.LASER : Theme.EXIT_GREEN);
        Draw.fill(sr, c.mountX - 4f, c.mountY - 4f, 8f, 8f, led);
    }

    private void coreFill(ShapeRenderer sr, Core core, float time) {
        Color base = core.stabilized ? Theme.CORE_HOT : Theme.CORE;
        float pulse = 0.6f + 0.4f * MathUtils.sinDeg(time * 200f);
        Draw.glow(sr, core.rect.x, core.rect.y, core.rect.width, core.rect.height, base, 14f);
        Draw.fill(sr, core.rect.x, core.rect.y, core.rect.width, core.rect.height, new Color(0.08f, 0.10f, 0.20f, 0.8f));
        float cx = core.rect.x + core.rect.width * 0.5f, cy = core.rect.y + core.rect.height * 0.5f;
        sr.setColor(base.r, base.g, base.b, pulse);
        // Diamond core.
        sr.triangle(cx, cy + 46f, cx - 34f, cy, cx + 34f, cy);
        sr.triangle(cx, cy - 46f, cx - 34f, cy, cx + 34f, cy);
    }

    private void figureFill(ShapeRenderer sr, float x, float y, float w, float h, boolean clone, float time) {
        figure(sr, x, y, w, h, clone, time);
    }

    /** Reusable figure fill (also used by the menu and victory screens). */
    public static void figure(ShapeRenderer sr, float x, float y, float w, float h, boolean clone, float time) {
        if (clone) {
            float sh = 0.6f + 0.4f * MathUtils.sinDeg(time * 260f);
            Draw.glow(sr, x, y, w, h, Theme.CLONE_LINE, 5f);
            fillHumanoid(sr, x, y, w, h,
                new Color(Theme.CLONE_FILL.r, Theme.CLONE_FILL.g, Theme.CLONE_FILL.b, 0.30f + 0.12f * sh),
                new Color(Theme.CLONE_FILL.r, Theme.CLONE_FILL.g, Theme.CLONE_FILL.b, 0.30f),
                new Color(Theme.CLONE_LINE.r, Theme.CLONE_LINE.g, Theme.CLONE_LINE.b, 0.4f));
        } else {
            fillHumanoid(sr, x, y, w, h, Theme.PLAYER_BODY, Theme.PLAYER_SKIN, Theme.PLAYER_HAIR);
        }
    }

    private static void fillHumanoid(ShapeRenderer sr, float x, float y, float w, float h,
                              Color body, Color head, Color hair) {
        // legs
        Draw.fill(sr, x + 4f, y, 8f, 20f, body);
        Draw.fill(sr, x + w - 12f, y, 8f, 20f, body);
        // torso
        Draw.fill(sr, x + 2f, y + 16f, w - 4f, 20f, body);
        Draw.fill(sr, x + 2f, y + 30f, w - 4f, 4f, Theme.PLAYER_TRIM);
        // head + hair
        Draw.fill(sr, x + 7f, y + 34f, w - 14f, 11f, head);
        Draw.fill(sr, x + 6f, y + 42f, w - 12f, 5f, hair);
    }

    private void collapseFx(ShapeRenderer sr, Level level, float time) {
        // Falling debris streaks (collapse effect #2; shake is #1, warning flash is #3).
        sr.setColor(Theme.EMBER.r, Theme.EMBER.g, Theme.EMBER.b, 0.8f);
        for (int i = 0; i < 22; i++) {
            float seed = i * 97.13f;
            float px = (seed * 13.7f) % Theme.WORLD_W;
            float drop = (time * (120f + (seed % 60f))) % (Theme.WORLD_H + 120f);
            float py = Theme.WORLD_H - drop;
            sr.rect(px, py, 3f, 12f);
        }
    }

    // ===================================================================== LINE PASS ==========
    public void linePass(ShapeRenderer sr, Level level, Player player, Array<Clone> clones, float time) {
        for (Platform p : level.platforms) {
            if (p.kind == Platform.Kind.BRIDGE && !p.solid) continue;
            Draw.border(sr, p.x, p.y, p.w, p.h, Theme.WALL_LINE);
        }
        for (Switch s : level.switches) {
            if (s.hidden) continue;
            Color c = s.active ? Theme.SWITCH_ON : Theme.NEON_DIM;
            Draw.border(sr, s.rect.x, s.rect.y, s.rect.width, s.rect.height, c);
        }
        for (Door d : level.doors) {
            Color c = d.open ? (d.isExit ? Theme.EXIT_GREEN : Theme.NEON_DIM) : Theme.DOOR_LOCKED;
            Draw.border(sr, d.rect.x, d.rect.y, d.rect.width, d.rect.height, c);
        }
        for (Clone c : clones) humanoidOutline(sr, c.x, c.y, c.w, c.h, Theme.CLONE_LINE);
        if (level.core != null) {
            Draw.border(sr, level.core.rect.x, level.core.rect.y, level.core.rect.width, level.core.rect.height,
                level.core.stabilized ? Theme.CORE_HOT : Theme.CORE);
            Draw.border(sr, CORE_PANEL[0], CORE_PANEL[1], CORE_PANEL[2], CORE_PANEL[3],
                level.core.stabilized ? Theme.CORE_HOT : Theme.PANEL_LINE);
        }
    }

    private void humanoidOutline(ShapeRenderer sr, float x, float y, float w, float h, Color c) {
        sr.setColor(c);
        sr.rect(x + 2f, y, w - 4f, 46f);
    }

    // ===================================================================== TEXT PASS ==========
    public void textPass(Level level, Player player, Array<Clone> clones) {
        if (level.core == null) {
            // Faint ghost level number on the back wall.
            game.text(String.format("%02d", level.number), 70f, 470f, 5.2f, Theme.alpha(Theme.NEON_FAINT, 0.5f), -1);
        } else {
            coreStatusText(level);
        }
        for (Switch s : level.switches) {
            if (s.hidden || s.label.isEmpty()) continue;
            float lx = s.rect.x + s.rect.width * 0.5f;
            float ly = s.rect.y + (s.kind == Switch.Kind.PLATE ? 58f : s.rect.height + 26f);
            game.text(s.label, lx, ly, 0.85f, s.active ? Theme.SWITCH_ON : Theme.NEON, 0);
        }
        for (Door d : level.doors) {
            float lx = d.rect.x + d.rect.width * 0.5f;
            if (d.open && d.isExit) {
                game.text("EXIT", lx, d.rect.y + d.rect.height + 20f, 1.0f, Theme.EXIT_GREEN, 0);
            } else if (!d.open) {
                game.text("LOCKED", lx, d.rect.y + d.rect.height + 20f, 0.9f, Theme.DOOR_LOCKED, 0);
            }
        }
        for (SecurityCamera c : level.cameras) {
            if (c.alerted) game.text("DETECTED", c.mountX, c.mountY - 26f, 0.9f, Theme.LASER, 0);
            else if (c.disabled) game.text("OFFLINE", c.mountX, c.mountY - 26f, 0.85f, Theme.INK_DIM, 0);
        }
        if (level.core != null) {
            game.text("CORE", level.core.rect.x + level.core.rect.width * 0.5f,
                level.core.rect.y + level.core.rect.height * 0.5f + 6f, 0.9f,
                level.core.stabilized ? Theme.CORE_HOT : Theme.INK, 0);
        }
    }

    /** The CORE STATUS readout: stability, protectors held, and the core's current state (item 13). */
    private void coreStatusText(Level level) {
        Core core = level.core;
        float[] r = CORE_PANEL;
        int held = 0;
        if (level.isSwitchActive("A")) held++;
        if (level.isSwitchActive("B")) held++;
        if (level.isSwitchActive("C")) held++;
        if (level.isSwitchActive("D")) held++;
        Color stateCol = core.stabilized ? Theme.CORE_HOT : (core.allOverloaded ? Theme.WARN : Theme.INK_DIM);
        game.text("CORE STATUS", r[0] + 18f, r[1] + r[3] - 16f, 1.0f, Theme.NEON, -1);
        game.text("STABILITY", r[0] + 18f, r[1] + r[3] - 50f, 0.85f, Theme.INK_DIM, -1);
        game.text(((int) core.stability) + "%", r[0] + r[2] - 18f, r[1] + r[3] - 50f, 0.95f,
            core.stability < 40f ? Theme.LASER : Theme.INK, 1);
        game.text("PROTECTORS", r[0] + 18f, r[1] + 52f, 0.85f, Theme.INK_DIM, -1);
        game.text(held + " / 4", r[0] + r[2] - 18f, r[1] + 52f, 0.95f,
            held >= 4 ? Theme.SWITCH_ON : Theme.INK, 1);
        game.text(core.statusLabel(), r[0] + 18f, r[1] + 24f, 0.9f, stateCol, -1);
    }
}
