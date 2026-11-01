package com.micro1.shadowclone;

/**
 * Factory for the twelve gameplay levels (scenes 2..13). {@code build(index)} returns a fresh
 * {@link Level}, so rebuilding a level is a full, pristine reset (used for Backspace restart, deaths
 * and escape-timer failures - rubric item 19). Coordinates are in the 1280x720 virtual space with
 * the origin at bottom-left; the ground surface sits at y = 120 unless a level says otherwise.
 */
public final class Levels {

    public static final int COUNT = 12;
    private static final float GTOP = 120f;      // ground surface y
    private static final float DOOR_W = 78f;
    private static final float DOOR_H = 138f;

    private Levels() {}

    public static Level build(int index) {
        switch (index) {
            case 0:  return tutorial();
            case 1:  return dualSwitch();
            case 2:  return bridge();
            case 3:  return elevator();
            case 4:  return laserCorridor();
            case 5:  return tripleClone();
            case 6:  return conveyor();
            case 7:  return timingChamber();
            case 8:  return security();
            case 9:  return master();
            case 10: return core();
            default: return escape();
        }
    }

    // --- Shared bits. ------------------------------------------------------------------------
    private static void groundFloor(Level l) {
        l.add(Platform.solid(0f, 0f, Theme.WORLD_W, GTOP));
    }

    private static Door exit(float x, float y, Door.Mode mode, String... req) {
        return new Door(mode, true, x, y, DOOR_W, DOOR_H, req);
    }

    // --- 02 Clone Tutorial Room. -------------------------------------------------------------
    private static Level tutorial() {
        Level l = new Level(2, Level.Kind.TUTORIAL, "CLONE TUTORIAL",
            new String[]{"Every 5 seconds your actions", "are recorded, then a clone", "replays them exactly."},
            new String[]{"Stand on the pad and let your", "clone hold it, then reach the exit."});
        groundFloor(l);
        l.spawnX = 130f; l.spawnY = GTOP;
        l.add(Switch.plate("P", "SWITCH", 430f, GTOP, 58f));
        l.add(exit(1140f, GTOP, Door.Mode.GATED, "P"));
        return l;
    }

    // --- 03 Dual Switch Puzzle. --------------------------------------------------------------
    private static Level dualSwitch() {
        Level l = new Level(3, Level.Kind.DUAL, "DUAL SWITCH",
            new String[]{"One person cannot hold both", "switches. Let a clone hold one", "while you hold the other."},
            new String[]{"Activate both switches at once", "to unlock the door."});
        groundFloor(l);
        l.spawnX = 150f; l.spawnY = GTOP;
        l.add(Switch.plate("A", "SWITCH A", 250f, GTOP, 58f));
        l.add(Switch.plate("B", "SWITCH B", 760f, GTOP, 58f));
        // Both switches sit LEFT of the exit so the player can reach each one (the door is a solid
        // barrier while closed). It latches open the instant both are active - which needs a clone,
        // since one person cannot stand on two switches at once - then you cross to it.
        l.add(exit(1120f, GTOP, Door.Mode.LATCH, "A", "B"));
        return l;
    }

    // --- 04 Clone Bridge. --------------------------------------------------------------------
    private static Level bridge() {
        Level l = new Level(4, Level.Kind.BRIDGE, "CLONE BRIDGE",
            new String[]{"A pressure plate builds a bridge", "only while it is held. Let a clone", "hold it and cross."},
            new String[]{"Cross the gap on the clone bridge", "and reach the exit."});
        // Left ledge + right ledge, a gap between.
        l.add(Platform.solid(0f, 0f, 400f, GTOP));
        l.add(Platform.solid(820f, 0f, Theme.WORLD_W - 820f, GTOP));
        // Bridge spanning the gap; solid only while "BP" is held.
        l.add(Platform.bridge(400f, GTOP - 16f, 420f, 16f).controlledBy("BP"));
        l.spawnX = 120f; l.spawnY = GTOP;
        l.add(Switch.plate("BP", "PLATE", 180f, GTOP, 58f));
        l.add(exit(1150f, GTOP, Door.Mode.LATCH));   // no requirement: crossing is the challenge
        return l;
    }

    // --- 05 Elevator Puzzle. -----------------------------------------------------------------
    private static Level elevator() {
        Level l = new Level(5, Level.Kind.ELEVATOR, "ELEVATOR",
            new String[]{"A clone holds the call plate to", "unlock the exit. A lift platform", "ferries you across the gap."},
            new String[]{"Hold the plate with a clone, then", "ride the lift across to the exit."});
        // Left floor, a gap, and the exit floor. A moving lift platform ferries across the gap; a
        // clone on the call plate unlocks the (gated) exit.
        l.add(Platform.solid(0f, 0f, 500f, GTOP));
        l.add(Platform.solid(760f, 0f, Theme.WORLD_W - 760f, GTOP));
        l.spawnX = 120f; l.spawnY = GTOP;
        l.add(Switch.plate("EP", "CALL PLATE", 280f, GTOP, 58f));
        // The lift rides back and forth on its own, pausing at each dock. At the left dock it is
        // flush with the left floor (walk aboard); at the right dock, flush with the exit floor
        // (walk off). It carries whoever stands on it - no plate to hold, no timing trap.
        l.add(Platform.moving(500f, GTOP - 24f, 140f, 24f, 620f, GTOP - 24f, 95f).withDwell(1.4f));
        l.add(exit(1150f, GTOP, Door.Mode.GATED, "EP"));
        return l;
    }

    // --- 06 Laser Corridor (clone sacrifice). ------------------------------------------------
    private static Level laserCorridor() {
        Level l = new Level(6, Level.Kind.LASER, "LASER CORRIDOR",
            new String[]{"The beam blocks you but not a", "clone. Send a clone through it to", "trip the switch, even at its cost."},
            new String[]{"Sacrifice a clone on the laser", "switch to open the door."});
        groundFloor(l);
        l.spawnX = 120f; l.spawnY = GTOP;
        // Tall beam curtain: blocks the player, destroys clones. Disabled for good once LS trips.
        Laser beam = Laser.beam(560f, GTOP, 96f, 210f);
        beam.id = "L";
        beam.controlId = "LS";
        beam.latchDisable = true;
        l.add(beam);
        // The switch's left edge is aligned with the beam's, so a clone is inside the lethal beam on
        // the exact step it first touches the switch: it trips the door and is destroyed together,
        // with no earlier "safe" step that would let it survive.
        l.add(Switch.plate("LS", "LASER SWITCH", 560f, GTOP, 60f));
        l.add(exit(1150f, GTOP, Door.Mode.LATCH, "LS"));
        return l;
    }

    // --- 07 Triple Clone Puzzle. -------------------------------------------------------------
    private static Level tripleClone() {
        Level l = new Level(7, Level.Kind.TRIPLE, "TRIPLE CLONE",
            new String[]{"Three switches, three clones.", "Record three takes so a clone", "holds each one at once."},
            new String[]{"Hold all three switches together", "to open the door."});
        groundFloor(l);
        l.spawnX = 120f; l.spawnY = GTOP;
        l.add(Switch.plate("A", "SWITCH A", 280f, GTOP, 56f));
        l.add(Switch.plate("B", "SWITCH B", 620f, GTOP, 56f));
        l.add(Switch.plate("C", "SWITCH C", 960f, GTOP, 56f));
        l.add(exit(1170f, GTOP, Door.Mode.GATED, "A", "B", "C"));
        return l;
    }

    // --- 08 Clone Conveyor Room. -------------------------------------------------------------
    private static Level conveyor() {
        Level l = new Level(8, Level.Kind.CONVEYOR, "CONVEYOR ROOM",
            new String[]{"The belt carries you and your", "clones alike. Your recording", "replays under the same drift."},
            new String[]{"Use the conveyor and a clone", "to reach the exit."});
        // Left ledge, conveyor belt, right ledge.
        l.add(Platform.solid(0f, 0f, 300f, GTOP));
        l.add(Platform.conveyor(300f, 0f, 680f, GTOP, 150f));   // pushes right
        l.add(Platform.solid(980f, 0f, Theme.WORLD_W - 980f, GTOP));
        l.spawnX = 120f; l.spawnY = GTOP;
        l.add(Switch.plate("CS", "SWITCH", 1050f, GTOP, 56f));
        l.add(exit(1190f, GTOP, Door.Mode.GATED, "CS"));
        return l;
    }

    // --- 09 Clone Timing Chamber. ------------------------------------------------------------
    private static Level timingChamber() {
        Level l = new Level(9, Level.Kind.TIMING, "TIMING CHAMBER",
            new String[]{"Timed lasers pulse on a steady", "beat. Plan a take that jumps,", "waits, and triggers on time."},
            new String[]{"Clear both lasers, arm the timed", "switch, and reach the exit."});
        groundFloor(l);
        l.spawnX = 120f; l.spawnY = GTOP;
        // Period 2.5s divides the 5s window, so every clone replays perfectly laser-aligned.
        Laser low = Laser.timed(360f, GTOP, 96f, 40f, 1.25f, 1.25f, 0f);
        low.id = "L1";
        l.add(low);
        Laser curtain = Laser.timed(720f, GTOP, 24f, 210f, 1.25f, 1.25f, 0.9f);
        curtain.id = "L2";
        l.add(curtain);
        // Timed switch: only arms while L1 is off.
        Switch ta = Switch.terminal("TA", "TIMED SWITCH", 560f, GTOP);
        ta.requiresLaserOff = "L1";
        l.add(ta);
        // Hold plate past the timed curtain.
        l.add(Switch.plate("TP", "HOLD PLATE", 940f, GTOP, 56f));
        l.add(exit(1170f, GTOP, Door.Mode.GATED, "TA", "TP"));
        return l;
    }

    // --- 10 Security Facility. ---------------------------------------------------------------
    private static Level security() {
        Level l = new Level(10, Level.Kind.SECURITY, "SECURITY FACILITY",
            new String[]{"Two systems guard the exit: a", "sweeping camera and a laser grid.", "Let clones take the risks."},
            new String[]{"Disable the camera and grid with", "clones, arm both terminals, exit."});
        groundFloor(l);
        l.spawnX = 120f; l.spawnY = GTOP;
        // System 1: a sweeping camera, taken offline while a clone holds the decoy plate. The plate
        // sits left of the camera's cone so you can record its clone without being detected first.
        SecurityCamera cam = new SecurityCamera(560f, 560f, 270f, 26f, 30f, 470f, 4.0f);
        cam.controlId = "DP";
        l.add(cam);
        l.add(Switch.plate("DP", "DECOY PLATE", 180f, GTOP, 56f));
        // System 2: a three-beam laser grid, dropped while a clone holds the grid plate.
        for (int i = 0; i < 3; i++) {
            Laser g = Laser.beam(760f, GTOP + 30f + i * 60f, 210f, 20f);
            g.controlId = "GP";
            l.add(g);
        }
        l.add(Switch.plate("GP", "GRID PLATE", 690f, GTOP, 56f));
        // Two required terminals past the grid, then the exit.
        l.add(Switch.terminal("TA", "TERMINAL A", 1000f, GTOP));
        l.add(Switch.terminal("TB", "TERMINAL B", 1085f, GTOP));
        l.add(exit(1185f, GTOP, Door.Mode.LATCH, "TA", "TB"));
        return l;
    }

    // --- 11 Master Puzzle Room. --------------------------------------------------------------
    private static Level master() {
        Level l = new Level(11, Level.Kind.MASTER, "MASTER PUZZLE",
            new String[]{"Everything at once: switches, two", "lasers, a conveyor and a camera.", "Stage several clones, then go."},
            new String[]{"Drop both lasers with clones,", "cross past the camera, then exit."});
        // Left floor, conveyor mid-section, right floor. Two laser gates each need a held plate.
        l.add(Platform.solid(0f, 0f, 500f, GTOP));
        l.add(Platform.conveyor(500f, 0f, 260f, GTOP, 140f));   // pushes right
        l.add(Platform.solid(760f, 0f, Theme.WORLD_W - 760f, GTOP));
        l.spawnX = 120f; l.spawnY = GTOP;
        // (1) switch + (2) laser: a clone on P1 drops the first curtain.
        l.add(Switch.plate("P1", "LASER PLATE", 250f, GTOP, 56f));
        Laser ml = Laser.beam(430f, GTOP, 46f, 200f);
        ml.id = "ML"; ml.controlId = "P1";
        l.add(ml);
        // (3) camera over the right walkway, offline while a clone holds P2 (P2 sits on the left
        // floor, outside the cone, so it can be recorded safely).
        SecurityCamera cam = new SecurityCamera(880f, 560f, 270f, 22f, 30f, 470f, 3.4f);
        cam.controlId = "P2";
        l.add(cam);
        l.add(Switch.plate("P2", "CAM PLATE", 340f, GTOP, 56f));
        // (4) conveyor already placed. A second laser gate past the camera needs a clone on P3;
        // recording P3 is only reliable once the camera is offline, so it chains the mechanics.
        l.add(Switch.plate("P3", "GATE PLATE", 1000f, GTOP, 56f));
        Laser ml2 = Laser.beam(1090f, GTOP, 46f, 200f);
        ml2.id = "ML2"; ml2.controlId = "P3";
        l.add(ml2);
        l.add(exit(1200f, GTOP, Door.Mode.LATCH));
        return l;
    }

    // --- 12 Clone Core. ----------------------------------------------------------------------
    private static Level core() {
        Level l = new Level(12, Level.Kind.CORE, "CLONE CORE",
            new String[]{"Overload all four protectors with", "clones, then redirect power to", "stabilize the core."},
            new String[]{"Hold A, B, C, D, then press E on", "the redirect terminal."});
        groundFloor(l);
        l.spawnX = 120f; l.spawnY = GTOP;
        l.core = new Core(560f, 300f, 160f, 200f);
        l.add(Switch.plate("A", "OVERLOAD A", 200f, GTOP, 54f));
        l.add(Switch.plate("B", "OVERLOAD B", 380f, GTOP, 54f));
        l.add(Switch.plate("C", "OVERLOAD C", 900f, GTOP, 54f));
        l.add(Switch.plate("D", "OVERLOAD D", 1080f, GTOP, 54f));
        l.add(Switch.terminal("REDIRECT", "REDIRECT", 620f, GTOP));
        // Synthetic switch flipped when the core stabilizes; drives the exit door.
        Switch done = Switch.terminal("CORE_DONE", "", -100f, -100f);
        done.hidden = true;
        l.add(done);
        l.add(exit(1180f, GTOP, Door.Mode.LATCH, "CORE_DONE"));
        return l;
    }

    // --- 13 Escape Sequence. -----------------------------------------------------------------
    private static Level escape() {
        Level l = new Level(13, Level.Kind.ESCAPE, "ESCAPE SEQUENCE",
            new String[]{"The facility is collapsing. A clone", "holds the route open. Beat the", "countdown to the exit."},
            new String[]{"Cross the clone bridge and reach", "the exit before time runs out."});
        l.escaping = true;
        l.escapeLimit = 45f;
        l.escapeTime = 45f;
        l.add(Platform.solid(0f, 0f, 400f, GTOP));
        l.add(Platform.solid(760f, 0f, Theme.WORLD_W - 760f, GTOP));
        l.add(Platform.bridge(400f, GTOP - 16f, 360f, 16f).controlledBy("RP"));
        l.spawnX = 120f; l.spawnY = GTOP;
        l.add(Switch.plate("RP", "ROUTE PLATE", 220f, GTOP, 56f));
        l.add(exit(1180f, GTOP, Door.Mode.LATCH));
        return l;
    }
}
