package com.tomer.scoundrel.audio;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Sounds waiting for their beat. A move is settled the instant it is pressed,
 * but its animation is not, and a sound played on the press arrives before the
 * blade does — so each sound is held until its effect's clock reaches its beat.
 *
 * <p>Every click during an animation skips it, and in fast play that is most
 * clicks. A skipped animation must still sound: {@link #flush()} hands over
 * everything pending at once, so every action is heard exactly once however
 * fast the player goes. The same rule the board already follows for the heal a
 * skipped drink still pours.
 *
 * <p>Times are on whatever clock the caller keeps — the board runs one per
 * effect — so a slowed effect (the killing blow runs at half speed) slows its
 * sounds with it.
 */
public final class PendingCues {

    private record Entry(Sfx sfx, float at, long order) {
    }

    /** Beat first; on a shared beat, the order they were scheduled in. */
    private static final Comparator<Entry> PLAY_ORDER =
            Comparator.comparingDouble(Entry::at).thenComparingLong(Entry::order);

    private final List<Entry> pending = new ArrayList<>();
    private long scheduled;

    /** Creates an empty queue; the board keeps two, one for the effects and one for the deal. */
    public PendingCues() {
    }

    /**
     * Holds a sound until the clock reaches {@code at}.
     *
     * @param sfx the sound, already chosen
     * @param at  its beat, in seconds on the caller's clock; 0 plays on the next {@link #due}
     */
    public void schedule(Sfx sfx, float at) {
        pending.add(new Entry(sfx, at, scheduled++));
    }

    /**
     * Holds several sounds for the same beat, in order — a blade, then its thud.
     *
     * @param sounds the sounds, in the order they should play
     * @param at     their shared beat, in seconds on the caller's clock
     */
    public void scheduleAll(List<Sfx> sounds, float at) {
        for (Sfx sfx : sounds) {
            schedule(sfx, at);
        }
    }

    /**
     * The sounds whose beat has come by {@code elapsed}, in play order. Each is handed over once.
     *
     * @param elapsed the caller's clock now, in seconds
     * @return the sounds due, earliest beat first; empty if none
     */
    public List<Sfx> due(float elapsed) {
        List<Entry> ready = new ArrayList<>();
        for (Entry entry : pending) {
            if (entry.at() <= elapsed) {
                ready.add(entry);
            }
        }
        pending.removeAll(ready);
        return sfxOf(ready);
    }

    /**
     * Everything still pending, at once, in play order, and the queue emptied —
     * what a skip plays. A sound that {@link Sound#collapsesOnSkip() collapses}
     * is kept only once: a skipped deal lands every card on the same instant,
     * and four flips on one instant are one louder noise, not four cards.
     *
     * @return every pending sound, earliest beat first, collapsing sounds kept once
     */
    public List<Sfx> flush() {
        List<Entry> all = new ArrayList<>(pending);
        pending.clear();
        all.sort(PLAY_ORDER);
        Set<Sound> collapsed = EnumSet.noneOf(Sound.class);
        List<Sfx> sounds = new ArrayList<>();
        for (Entry entry : all) {
            Sound sound = entry.sfx().sound();
            if (sound.collapsesOnSkip() && !collapsed.add(sound)) {
                continue;
            }
            sounds.add(entry.sfx());
        }
        return sounds;
    }

    /**
     * Whether any sound is still waiting for its beat.
     *
     * @return true when nothing is pending
     */
    public boolean isEmpty() {
        return pending.isEmpty();
    }

    private static List<Sfx> sfxOf(List<Entry> entries) {
        entries.sort(PLAY_ORDER);
        List<Sfx> sounds = new ArrayList<>();
        for (Entry entry : entries) {
            sounds.add(entry.sfx());
        }
        return sounds;
    }
}
