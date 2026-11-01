package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;

/**
 * One playable level: the entity data (platforms, switches, doors, lasers, cameras, core) plus its
 * metadata and its per-step logic. {@link PlayScreen} drives a level each fixed step as:
 * {@code advanceHazards -> recomputeSwitches -> updateCarriers -> (move bodies) ->
 * blockPlayerAtLasers -> recomputeSwitches -> updateSystems -> (hazards) -> exitReached}.
 * Switches are recomputed twice: once before the move (so carriers and physics use a settled state)
 * and once after (so a clone that just stepped onto a switch registers it before hazards run, which
 * is what lets a sacrificing clone trip its switch on the very step the beam destroys it).
 */
public final class Level {

    public enum Kind {
        TUTORIAL, DUAL, BRIDGE, ELEVATOR, LASER, TRIPLE, CONVEYOR, TIMING, SECURITY, MASTER, CORE, ESCAPE
    }

    public final int number;
    public final Kind kind;
    public final String name;
    public final String[] descLines;
    public final String[] objectiveLines;
    public float spawnX, spawnY;

    public final Array<Platform> platforms = new Array<>();
    public final Array<Switch> switches = new Array<>();
    public final Array<Door> doors = new Array<>();
    public final Array<Laser> lasers = new Array<>();
    public final Array<SecurityCamera> cameras = new Array<>();
    public Core core;

    private final ObjectMap<String, Switch> switchById = new ObjectMap<>();
    private final ObjectMap<String, Laser> laserById = new ObjectMap<>();

    // Escape sequence state.
    public boolean escaping;
    public float escapeTime;
    public float escapeLimit;
    public boolean escapeFailed;

    // Security / camera feedback.
    public float alertFlash;               // seconds remaining on the DETECTED banner
    public boolean recordingFailRequested; // a camera saw the player this step

    public Level(int number, Kind kind, String name, String[] descLines, String[] objectiveLines) {
        this.number = number;
        this.kind = kind;
        this.name = name;
        this.descLines = descLines;
        this.objectiveLines = objectiveLines;
    }

    // --- Builder helpers (used by Levels). ---------------------------------------------------
    public Platform add(Platform p) { platforms.add(p); return p; }
    public Switch add(Switch s) { switches.add(s); switchById.put(s.id, s); return s; }
    public Door add(Door d) { doors.add(d); return d; }
    public Laser add(Laser l) { lasers.add(l); if (l.id != null) laserById.put(l.id, l); return l; }
    public SecurityCamera add(SecurityCamera c) { cameras.add(c); return c; }

    public boolean isSwitchActive(String id) {
        Switch s = switchById.get(id);
        return s != null && s.active;
    }

    public boolean isLaserOn(String id) {
        Laser l = laserById.get(id);
        return l != null && l.enabled && l.on;
    }

    // --- Per-step logic. ---------------------------------------------------------------------

    /** Advance timed hazards, snapshot per-step lethality, sweep cameras, tick the escape clock. */
    public void advanceHazards(float dt) {
        for (Laser l : lasers) {
            l.update(dt);
            l.lethalAtStepStart = l.lethal();
        }
        for (SecurityCamera c : cameras) c.advance(dt);
        if (escaping && !escapeFailed) {
            escapeTime -= dt;
            if (escapeTime <= 0f) {
                escapeTime = 0f;
                escapeFailed = true;
            }
        }
        if (alertFlash > 0f) alertFlash -= dt;
    }

    /** Recompute plate/terminal activation from the current body positions. */
    public void recomputeSwitches(Player player, Array<Clone> clones) {
        for (Switch s : switches) {
            if (s.hidden) continue;
            boolean was = s.active;
            s.justActivated = false;
            if (s.kind == Switch.Kind.PLATE) {
                s.active = player.overlaps(s.rect) || anyCloneOn(clones, s.rect);
            } else { // TERMINAL
                if (!s.latched) {
                    boolean gateOk = s.requiresLaserOff == null || !isLaserOn(s.requiresLaserOff);
                    if (gateOk) {
                        boolean pressed =
                            (player.overlaps(s.rect) && player.interactedThisStep) ||
                            anyCloneInteract(clones, s.rect);
                        if (pressed) s.latched = true;
                    }
                }
                s.active = s.latched;
            }
            if (s.active && !was) s.justActivated = true;
        }
    }

    /**
     * Pre-physics: set bridge/elevator state from the (pre-move) switches and advance platform
     * motion so the carry deltas are ready for {@link Physics} to move riders this step.
     */
    public void updateCarriers(float dt) {
        for (Platform p : platforms) {
            if (p.controlId == null) continue;
            boolean ctl = isSwitchActive(p.controlId);
            if (p.kind == Platform.Kind.BRIDGE) p.solid = ctl;
            else if (p.kind == Platform.Kind.ELEVATOR) p.active = ctl;
        }
        for (Platform p : platforms) p.update(dt);
    }

    /**
     * Post-physics: react to this step's final body positions. Cameras, laser disables (so a clone
     * that just stepped onto a laser switch drops the beam), the core, and doors are all resolved
     * here, before hazards run, so a sacrificing clone still trips its switch on the step it dies.
     */
    public void updateSystems(float dt, Player player, Array<Clone> clones) {
        // Security cameras: a clone holding the control plate takes the camera offline (the clean
        // bypass); a clone in the cone also distracts/locks it. Otherwise it may flag the player,
        // which fails the current recording rather than killing.
        for (SecurityCamera c : cameras) {
            c.disabled = c.controlId != null && isSwitchActive(c.controlId);
            c.distracted = false;
            for (Clone cl : clones) {
                if (c.sees(cl.centerX(), cl.centerY())) { c.distracted = true; break; }
            }
            c.alerted = false;
            if (!c.disabled && !c.distracted && c.sees(player.centerX(), player.centerY())) {
                c.alerted = true;
                recordingFailRequested = true;
                alertFlash = 1.2f;
            }
        }
        // Lasers disabled by a controlling switch (grid held down, or a latched corridor trip).
        for (Laser l : lasers) {
            if (l.controlId == null) continue;
            boolean ctl = isSwitchActive(l.controlId);
            if (l.latchDisable) {
                if (ctl) l.disabledLatched = true;
                l.enabled = !l.disabledLatched;
            } else {
                l.enabled = !ctl;
            }
        }
        // Core state (Clone Core level).
        if (core != null) {
            int overloads = 0;
            if (isSwitchActive("A")) overloads++;
            if (isSwitchActive("B")) overloads++;
            if (isSwitchActive("C")) overloads++;
            if (isSwitchActive("D")) overloads++;
            core.update(overloads, isSwitchActive("REDIRECT"), dt);
            Switch done = switchById.get("CORE_DONE");
            if (done != null && core.stabilized) {
                done.latched = true;
                done.active = true;
            }
        }
        // Doors follow the fresh switch states.
        for (Door d : doors) d.recompute(this);
    }

    /** True once the player has walked into an open exit door. */
    public boolean exitReached(Player player) {
        for (Door d : doors) {
            if (d.isExit && d.open && player.overlaps(d.rect)) return true;
        }
        return false;
    }

    private static boolean anyCloneOn(Array<Clone> clones, Rectangle r) {
        for (Clone c : clones) {
            if (c.overlaps(r)) return true;
        }
        return false;
    }

    private static boolean anyCloneInteract(Array<Clone> clones, Rectangle r) {
        for (Clone c : clones) {
            if (c.interactedThisStep && c.overlaps(r)) return true;
        }
        return false;
    }
}
