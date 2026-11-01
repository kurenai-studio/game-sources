package com.tomer.scoundrel.audio;

import java.util.ArrayList;
import java.util.List;

/**
 * Which music is playing, how loud, and when the one-shot cues fire — as a pure
 * function of what the screens report and the time that has passed. The
 * streams themselves are played elsewhere; this only answers, every frame, how
 * loud each track should be ({@link #gain}) and what to start
 * ({@link #tick}'s {@link Command}s).
 *
 * <p>It lives in the navigator, not a screen, so the music outlives the screen
 * changes that would otherwise restart it: the menu track plays on across the
 * title, mode select, ledger and trophies. Screens cut; the music crossfades.
 * Audio is the deliberate exception to the cut rule, like the torch light,
 * because a hard cut in music sounds like a fault where a cut in the picture
 * does not.
 *
 * <p>The end of a run is sequenced here:
 * <ul>
 *   <li><b>Death</b> — the run music is left alone through the flare, the shake
 *       and the settle, then dies with the torch over the window the death
 *       cinematic passes in, and the death cue plays as YOU DIED grows in.
 *       Clicking through fades quickly and plays the cue at once if it has not
 *       played — never twice.</li>
 *   <li><b>Win</b> — the end panel is up at once, but the winning blow is
 *       still landing, so the music waits for the board to go idle, fades, and
 *       only then cues.</li>
 *   <li><b>The chime</b> — trophies unlocked — waits for both the end panel
 *       and the cue to have finished, so it never lands on top of either.</li>
 * </ul>
 * After that the panel is quiet but for the torch, until the player leaves.
 *
 * <p>The death's timing is passed in rather than read, because it belongs to
 * the death cinematic in the screens, which this package may not import.
 */
public final class MusicDirector {

    /** The two looping streams; at most one is heard at a time, except while crossfading. */
    public enum Track {
        /** Title, mode select, ledger, trophies, and the sprite lab. */
        MENU,
        /** A run or the tutorial, from the deal through the end panel. */
        RUN
    }

    /** The one-shots: the two end-of-run cues, and the trophy chime. */
    public enum Cue {
        /** The run was won; plays once the winning blow has landed and the music faded. */
        WIN,
        /** The run was lost; plays as YOU DIED grows in. */
        DEATH,
        /** Trophies were unlocked; plays after the end cue has finished. */
        CHIME
    }

    /** Something to start. Volumes are not commands; they are read every frame from {@link #gain}. */
    public sealed interface Command {
    }

    /**
     * Start a track from its beginning.
     *
     * @param track the track to rewind and play
     */
    public record Restart(Track track) implements Command {
    }

    /**
     * Play a one-shot.
     *
     * @param cue the cue to play once
     */
    public record Play(Cue cue) implements Command {
    }

    /** Creates a director in silence; the first screen shown starts the music. */
    public MusicDirector() {
    }

    /** Menu to run and back. A starting value, tuned by ear in listening round 3. */
    static final float CROSSFADE = 1f;
    /** The run music giving way to the win cue once the board is idle. */
    static final float WIN_FADE = 0.5f;
    /** A click through the death: fast, but a fade, because a cut clicks. */
    static final float SETTLE_FADE = 0.1f;

    private enum State { SILENT, MENUS, RUN, DYING, WINNING, ENDED }

    private State state = State.SILENT;
    /** Each track's linear level, 0..1, before the equal-power curve. */
    private final float[] level = new float[Track.values().length];
    private final float[] target = new float[Track.values().length];
    /** How fast each level moves toward its target, per second. */
    private final float[] rate = new float[Track.values().length];
    private final List<Command> pending = new ArrayList<>();

    private float deathClock;
    private float fadeStart;
    private float fadeEnd;
    private float cueAt;
    private float levelAtDeath;
    private boolean winFading;

    /** The cue this run's end played, if any; a stale cue ending is recognised by it. */
    private Cue endCue;
    private boolean cueFinished;
    private boolean panelUp;
    private boolean trophies;
    private boolean chimed;

    /**
     * A menu screen is showing. Nothing happens if one already was: moving
     * between menus does not restart the track. From silence, the menu track
     * starts from the top.
     */
    public void enterMenus() {
        if (state == State.MENUS) {
            return;
        }
        if (level(Track.MENU) == 0f) {
            pending.add(new Restart(Track.MENU));
        }
        fadeTo(Track.MENU, 1f, CROSSFADE);
        fadeTo(Track.RUN, 0f, CROSSFADE);
        state = State.MENUS;
        forgetRunEnd();
    }

    /** A run began: the run track always starts from the top, fading in. */
    public void enterRun() {
        pending.add(new Restart(Track.RUN));
        level[Track.RUN.ordinal()] = 0f;
        fadeTo(Track.RUN, 1f, CROSSFADE);
        fadeTo(Track.MENU, 0f, CROSSFADE);
        state = State.RUN;
        forgetRunEnd();
    }

    /**
     * The death cinematic began. Times are seconds from now: the music fades
     * between {@code fadeStart} and {@code fadeEnd}, and the cue plays at
     * {@code cueAt}.
     *
     * @param fadeStart seconds from now until the run music starts to fade, 0 or more
     * @param fadeEnd   seconds from now until it is silent; equal to {@code fadeStart} for a cut
     * @param cueAt     seconds from now until the death cue plays
     */
    public void dying(float fadeStart, float fadeEnd, float cueAt) {
        beginRunEnd();
        this.fadeStart = fadeStart;
        this.fadeEnd = fadeEnd;
        this.cueAt = cueAt;
        deathClock = 0f;
        levelAtDeath = level(Track.RUN);
        fadeTo(Track.MENU, 0f, CROSSFADE);
        state = State.DYING;
    }

    /** The death is over, played out or clicked through: the end panel is up. */
    public void settled() {
        if (state != State.DYING) {
            return;
        }
        if (endCue == null) {
            playCue(Cue.DEATH);
        }
        fadeTo(Track.RUN, 0f, SETTLE_FADE);
        state = State.ENDED;
        panelUp = true;
        chimeIfReady();
    }

    /** The run was won. The end panel is up already; the music waits for the board. */
    public void won() {
        beginRunEnd();
        state = State.WINNING;
        winFading = false;
        panelUp = true;
    }

    /** This run unlocked a trophy, so its end chimes. */
    public void trophiesUnlocked() {
        trophies = true;
        chimeIfReady();
    }

    /**
     * A one-shot finished playing. Only this run's own end cue counts.
     *
     * @param cue the cue whose stream just ended; a stale one from an earlier end is ignored
     */
    public void cueEnded(Cue cue) {
        if (endCue != null && cue == endCue) {
            cueFinished = true;
            chimeIfReady();
        }
    }

    /**
     * Moves time on and returns what to start. {@code boardIdle} is whether the
     * board has finished animating, which only a win waits for.
     *
     * @param delta     seconds since the last tick, 0 or more
     * @param boardIdle whether the board has finished animating; true on any non-run screen
     * @return what to start this frame, in order; usually empty
     */
    public List<Command> tick(float delta, boolean boardIdle) {
        for (Track track : Track.values()) {
            if (!(state == State.DYING && track == Track.RUN)) {
                step(track, delta);
            }
        }
        if (state == State.DYING) {
            deathClock += delta;
            level[Track.RUN.ordinal()] = levelAtDeath * (1f - deathFade());
            if (endCue == null && deathClock >= cueAt) {
                playCue(Cue.DEATH);
            }
        } else if (state == State.WINNING) {
            if (!winFading && boardIdle) {
                fadeTo(Track.RUN, 0f, WIN_FADE);
                winFading = true;
            }
            if (winFading && level(Track.RUN) == 0f) {
                playCue(Cue.WIN);
                state = State.ENDED;
            }
        }
        List<Command> commands = List.copyOf(pending);
        pending.clear();
        return commands;
    }

    /**
     * How loud a track should play right now, 0..1, before the player's volume.
     * On an equal-power curve, so a crossfade does not dip in the middle: two
     * unrelated tracks at half amplitude each sound quieter than either alone.
     *
     * @param track the track to ask about
     * @return its gain, 0 (silent) to 1 (full), to multiply by the player's music gain
     */
    public float gain(Track track) {
        return (float) Math.sin(level(track) * Math.PI / 2);
    }

    /** How far through the death's fade window the clock is, 0..1. A zero-length window is a cut. */
    private float deathFade() {
        float window = fadeEnd - fadeStart;
        if (window <= 0f) {
            return deathClock >= fadeStart ? 1f : 0f;
        }
        return Math.max(0f, Math.min(1f, (deathClock - fadeStart) / window));
    }

    private void playCue(Cue cue) {
        pending.add(new Play(cue));
        endCue = cue;
    }

    private void chimeIfReady() {
        if (trophies && panelUp && cueFinished && !chimed) {
            pending.add(new Play(Cue.CHIME));
            chimed = true;
        }
    }

    /**
     * A run's end begins: whatever the last end cued, and whether it chimed, is
     * forgotten - but not the trophies, which the game reports just before the end
     * it belongs to. In the game an end always follows a new run, which forgets
     * everything anyway; the lab can end twice in a row, and a remembered win cue
     * once left a death silent.
     */
    private void beginRunEnd() {
        endCue = null;
        cueFinished = false;
        panelUp = false;
        chimed = false;
    }

    private void forgetRunEnd() {
        endCue = null;
        cueFinished = false;
        panelUp = false;
        trophies = false;
        chimed = false;
        winFading = false;
    }

    /** Heads for {@code value} so as to arrive in {@code seconds}, from wherever it is now. */
    private void fadeTo(Track track, float value, float seconds) {
        int i = track.ordinal();
        target[i] = value;
        rate[i] = Math.abs(value - level[i]) / seconds;
    }

    private void step(Track track, float delta) {
        int i = track.ordinal();
        float move = rate[i] * delta;
        if (level[i] < target[i]) {
            level[i] = Math.min(target[i], level[i] + move);
        } else {
            level[i] = Math.max(target[i], level[i] - move);
        }
    }

    private float level(Track track) {
        return level[track.ordinal()];
    }
}
