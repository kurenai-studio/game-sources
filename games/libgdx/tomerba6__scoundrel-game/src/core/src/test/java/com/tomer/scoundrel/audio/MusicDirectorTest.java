package com.tomer.scoundrel.audio;

import com.tomer.scoundrel.audio.MusicDirector.Command;
import com.tomer.scoundrel.audio.MusicDirector.Cue;
import com.tomer.scoundrel.audio.MusicDirector.Play;
import com.tomer.scoundrel.audio.MusicDirector.Restart;
import com.tomer.scoundrel.audio.MusicDirector.Track;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** What the music does across menus, runs, deaths and wins, and when the cues and the chime play. */
class MusicDirectorTest {

    private static final float FRAME = 1f / 60f;
    private static final float EPSILON = 1e-4f;
    /** DeathCinematic's timings, as GameScreen will pass them in. */
    private static final float FADE_START = 1.25f;
    private static final float FADE_END = 2.75f;
    private static final float CUE_AT = 3.4167f;

    private final MusicDirector director = new MusicDirector();

    /** Ticks at 60 fps for {@code seconds}, collecting everything the director asked for. */
    private List<Command> play(float seconds, boolean boardIdle) {
        List<Command> commands = new ArrayList<>();
        int frames = Math.round(seconds / FRAME);
        for (int i = 0; i < frames; i++) {
            commands.addAll(director.tick(FRAME, boardIdle));
        }
        return commands;
    }

    private List<Command> play(float seconds) {
        return play(seconds, true);
    }

    private static long count(List<Command> commands, Command wanted) {
        return commands.stream().filter(wanted::equals).count();
    }

    private void settledInRun() {
        director.enterRun();
        play(MusicDirector.CROSSFADE + 0.1f);
    }

    // --- menus and runs -----------------------------------------------------

    /** A fresh director plays nothing, and both tracks are silent. */
    @Test
    void itStartsSilent() {
        assertEquals(0f, director.gain(Track.MENU), 0f);
        assertEquals(0f, director.gain(Track.RUN), 0f);
        assertEquals(List.of(), play(1f));
    }

    /** Entering the menus restarts the menu track and fades it in over the crossfade. */
    @Test
    void theMenusStartTheMenuTrackAndFadeItIn() {
        director.enterMenus();
        List<Command> first = director.tick(0f, true);
        assertEquals(List.of(new Restart(Track.MENU)), first);
        play(MusicDirector.CROSSFADE / 2);
        float halfway = director.gain(Track.MENU);
        assertTrue(halfway > 0f && halfway < 1f, "halfway " + halfway);
        play(MusicDirector.CROSSFADE / 2 + 0.05f);
        assertEquals(1f, director.gain(Track.MENU), EPSILON);
    }

    /** Moving between menu screens carries the menu track on without a restart. */
    @Test
    void theMenuTrackCarriesOnAcrossMenuScreens() {
        director.enterMenus();
        play(2f);
        director.enterMenus(); // title -> ledger
        director.enterMenus(); // ledger -> trophies
        assertEquals(List.of(), play(1f), "no restart between menu screens");
        assertEquals(1f, director.gain(Track.MENU), EPSILON);
    }

    /** Starting a run restarts the run track and crossfades to it at constant power. */
    @Test
    void startingARunCrossfadesAtConstantPower() {
        director.enterMenus();
        play(2f);
        director.enterRun();
        assertEquals(List.of(new Restart(Track.RUN)), director.tick(0f, true));
        play(MusicDirector.CROSSFADE / 2);
        float menu = director.gain(Track.MENU);
        float run = director.gain(Track.RUN);
        assertTrue(menu > 0f && menu < 1f && run > 0f && run < 1f, menu + " / " + run);
        // Equal power: the two together are as loud as either one alone.
        assertEquals(1f, menu * menu + run * run, 0.01f);
        play(MusicDirector.CROSSFADE / 2 + 0.05f);
        assertEquals(0f, director.gain(Track.MENU), EPSILON);
        assertEquals(1f, director.gain(Track.RUN), EPSILON);
    }

    /** Returning to the menus mid-crossfade fades back without restarting the menu track. */
    @Test
    void changingYourMindMidFadeTurnsItBackWithoutARestart() {
        director.enterMenus();
        play(2f);
        director.enterRun();
        play(MusicDirector.CROSSFADE / 2);
        director.enterMenus();
        List<Command> commands = play(MusicDirector.CROSSFADE + 0.1f);
        assertEquals(0, count(commands, new Restart(Track.MENU)), "the menu track never went silent");
        assertEquals(1f, director.gain(Track.MENU), EPSILON);
        assertEquals(0f, director.gain(Track.RUN), EPSILON);
    }

    // --- death --------------------------------------------------------------

    /** On a death the run music holds until the fade starts, then fades out with the torch. */
    @Test
    void theRunMusicDiesWithTheTorch() {
        settledInRun();
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(FADE_START - 0.05f);
        assertEquals(1f, director.gain(Track.RUN), EPSILON, "untouched through the flare, shake and settle");
        play((FADE_END - FADE_START) / 2 + 0.05f);
        assertEquals((float) Math.sin(Math.PI / 4), director.gain(Track.RUN), 0.02f, "halfway out");
        play((FADE_END - FADE_START) / 2 + 0.05f);
        assertEquals(0f, director.gain(Track.RUN), EPSILON, "gone as the torch is");
    }

    /** The death cue plays once, on the frame YOU DIED starts to grow in. */
    @Test
    void theDeathCueLandsAsYouDiedGrowsInAndOnlyOnce() {
        settledInRun();
        director.dying(FADE_START, FADE_END, CUE_AT);
        float elapsed = 0f;
        float heardAt = -1f;
        int heard = 0;
        while (elapsed < 10f) {
            List<Command> commands = director.tick(FRAME, true);
            elapsed += FRAME;
            if (commands.contains(new Play(Cue.DEATH))) {
                heard++;
                heardAt = elapsed;
            }
        }
        assertEquals(1, heard);
        assertTrue(heardAt >= CUE_AT && heardAt < CUE_AT + FRAME + EPSILON, "heard at " + heardAt);
    }

    /**
     * Clicking through the death plays the cue at once, fades the music quickly,
     * and never plays the cue again.
     */
    @Test
    void clickingThroughTheDeathPlaysTheCueAtOnceAndNeverAgain() {
        settledInRun();
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(1f);
        director.settled();
        List<Command> next = director.tick(FRAME, true);
        assertEquals(1, count(next, new Play(Cue.DEATH)));
        play(MusicDirector.SETTLE_FADE + FRAME);
        assertEquals(0f, director.gain(Track.RUN), EPSILON, "a quick fade, not a click");
        assertEquals(0, count(play(10f), new Play(Cue.DEATH)));
    }

    /** Settling after the death cue has played does not play it again. */
    @Test
    void settlingAfterTheCueDoesNotReplayIt() {
        settledInRun();
        director.dying(FADE_START, FADE_END, CUE_AT);
        assertEquals(1, count(play(4f), new Play(Cue.DEATH)));
        director.settled();
        assertEquals(0, count(play(1f), new Play(Cue.DEATH)));
    }

    /** A zero-length fade cuts the music at its start and still plays the cue. */
    @Test
    void aZeroLengthFadeCutsTheMusicAtItsStart() {
        settledInRun();
        director.dying(1f, 1f, 1f);
        play(0.9f);
        assertEquals(1f, director.gain(Track.RUN), EPSILON);
        List<Command> commands = play(0.2f);
        assertEquals(0f, director.gain(Track.RUN), EPSILON);
        assertEquals(1, count(commands, new Play(Cue.DEATH)));
    }

    // --- winning ------------------------------------------------------------

    /** A win waits for the board to go idle, then fades the run music and plays the win cue once. */
    @Test
    void aWinWaitsForTheBoardThenFadesThenCues() {
        settledInRun();
        director.won();
        List<Command> busy = play(1f, false);
        assertEquals(0, count(busy, new Play(Cue.WIN)), "the winning blow is still landing");
        assertEquals(1f, director.gain(Track.RUN), EPSILON);
        List<Command> idle = play(MusicDirector.WIN_FADE + 0.1f, true);
        assertEquals(1, count(idle, new Play(Cue.WIN)));
        assertEquals(0f, director.gain(Track.RUN), EPSILON);
        assertEquals(0, count(play(5f), new Play(Cue.WIN)));
    }

    // --- the chime ----------------------------------------------------------

    /** With trophies unlocked, the chime plays once after the win cue ends, and never again. */
    @Test
    void theChimeFollowsTheWinCue() {
        settledInRun();
        director.trophiesUnlocked();
        director.won();
        List<Command> commands = play(MusicDirector.WIN_FADE + 0.1f);
        assertEquals(1, count(commands, new Play(Cue.WIN)));
        assertEquals(0, count(commands, new Play(Cue.CHIME)), "not on top of the cue");
        director.cueEnded(Cue.WIN);
        assertEquals(List.of(new Play(Cue.CHIME)), director.tick(FRAME, true));
        assertEquals(0, count(play(2f), new Play(Cue.CHIME)));
        // A completion reported twice, or the trophy news again, chimes nothing more.
        director.cueEnded(Cue.WIN);
        director.trophiesUnlocked();
        assertEquals(0, count(play(1f), new Play(Cue.CHIME)));
    }

    /** With no trophies unlocked there is no chime. */
    @Test
    void noTrophiesNoChime() {
        settledInRun();
        director.won();
        play(MusicDirector.WIN_FADE + 0.1f);
        director.cueEnded(Cue.WIN);
        assertEquals(0, count(play(2f), new Play(Cue.CHIME)));
    }

    /** After a death the chime waits for the end panel, not just the cue. */
    @Test
    void afterADeathTheChimeWaitsForThePanel() {
        settledInRun();
        director.trophiesUnlocked();
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(4f);
        director.cueEnded(Cue.DEATH);
        assertEquals(0, count(play(1f), new Play(Cue.CHIME)), "YOU DIED is still growing in");
        director.settled();
        assertEquals(1, count(play(FRAME), new Play(Cue.CHIME)));
    }

    /** After a click-through the chime waits for the death cue to end. */
    @Test
    void afterAClickThroughTheChimeWaitsForTheCue() {
        settledInRun();
        director.trophiesUnlocked();
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(1f);
        director.settled();
        List<Command> commands = play(1f);
        assertEquals(1, count(commands, new Play(Cue.DEATH)));
        assertEquals(0, count(commands, new Play(Cue.CHIME)), "not on top of the death cue");
        director.cueEnded(Cue.DEATH);
        assertEquals(1, count(play(FRAME), new Play(Cue.CHIME)));
    }

    /** A cue ending left over from an earlier run, or the chime's own, does not release this run's chime. */
    @Test
    void aCueEndingFromAnEarlierRunIsIgnored() {
        settledInRun();
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(1f);
        director.settled();
        play(FRAME);
        director.enterRun(); // NEW GAME while the death cue is still playing
        play(MusicDirector.CROSSFADE + 0.1f);
        director.cueEnded(Cue.DEATH); // ...and it finishes during the next run
        director.trophiesUnlocked();
        director.won();
        List<Command> commands = play(MusicDirector.WIN_FADE + 0.1f);
        assertEquals(1, count(commands, new Play(Cue.WIN)));
        assertEquals(0, count(commands, new Play(Cue.CHIME)), "the old cue's end is not this one's");
        director.cueEnded(Cue.CHIME); // not a cue that gates anything
        assertEquals(0, count(play(FRAME), new Play(Cue.CHIME)));
        director.cueEnded(Cue.WIN);
        assertEquals(1, count(play(FRAME), new Play(Cue.CHIME)));
    }

    /** A death straight after a win, with no new run between them, still plays its cue. */
    @Test
    void anEndThatFollowsAnotherWithoutANewRunStillPlaysItsCue() {
        // Only the lab does this - V, then X - but a run's end starts afresh either
        // way: if the win's cue were still remembered, the death would think it
        // had already cued and stay silent.
        settledInRun();
        director.won();
        play(MusicDirector.WIN_FADE + 0.1f);
        director.cueEnded(Cue.WIN);
        director.dying(FADE_START, FADE_END, CUE_AT);
        assertEquals(1, count(play(4f), new Play(Cue.DEATH)));
    }

    /** A second end's chime waits for its own panel and cue. */
    @Test
    void aSecondEndsChimeWaitsForItsOwnPanelAndCue() {
        settledInRun();
        director.trophiesUnlocked();
        director.won();
        play(MusicDirector.WIN_FADE + 0.1f);
        director.cueEnded(Cue.WIN);
        assertEquals(1, count(play(FRAME), new Play(Cue.CHIME)));
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(4f);
        director.cueEnded(Cue.DEATH);
        assertEquals(0, count(play(1f), new Play(Cue.CHIME)), "the death's panel is not up yet");
        director.settled();
        assertEquals(1, count(play(FRAME), new Play(Cue.CHIME)));
    }

    // --- the end panel and after --------------------------------------------

    /** Both tracks stay silent while the end panel is up. */
    @Test
    void theEndPanelIsQuiet() {
        settledInRun();
        director.won();
        play(MusicDirector.WIN_FADE + 0.1f);
        play(5f);
        assertEquals(0f, director.gain(Track.RUN), EPSILON);
        assertEquals(0f, director.gain(Track.MENU), EPSILON);
    }

    /** NEW GAME from the end panel restarts the run track and fades it in. */
    @Test
    void newGameFromTheEndPanelRestartsTheRunTrack() {
        settledInRun();
        director.won();
        play(MusicDirector.WIN_FADE + 0.1f);
        director.enterRun();
        List<Command> commands = play(MusicDirector.CROSSFADE + 0.1f);
        assertEquals(1, count(commands, new Restart(Track.RUN)));
        assertEquals(1f, director.gain(Track.RUN), EPSILON);
    }

    /** MAIN MENU from the end panel restarts the menu track and fades it in. */
    @Test
    void mainMenuFromTheEndPanelRestartsTheMenuTrack() {
        settledInRun();
        director.dying(FADE_START, FADE_END, CUE_AT);
        play(6f);
        director.settled();
        director.enterMenus();
        List<Command> commands = play(MusicDirector.CROSSFADE + 0.1f);
        assertEquals(1, count(commands, new Restart(Track.MENU)));
        assertEquals(1f, director.gain(Track.MENU), EPSILON);
        assertEquals(0f, director.gain(Track.RUN), EPSILON);
    }

    /** Settling, or a cue ending, outside a run changes nothing. */
    @Test
    void settlingOrWinningOutsideARunChangesNothing() {
        director.enterMenus();
        play(2f);
        director.settled();
        director.cueEnded(Cue.DEATH);
        assertEquals(List.of(), play(1f));
        assertEquals(1f, director.gain(Track.MENU), EPSILON);
    }
}
