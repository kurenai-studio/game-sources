package com.tomer.scoundrel.audio;

import com.tomer.scoundrel.audio.MusicDirector.Cue;
import com.tomer.scoundrel.audio.MusicDirector.Track;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.TreeMap;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The streamed music, cue and torch files, and which of them loop. */
class StreamFileTest {

    /** The contract, by hand: docs/audio.md's five streamed files. */
    @Test
    void theStreamedFilesAreExactlyTheContract() {
        Map<String, String> paths = new TreeMap<>();
        for (StreamFile stream : StreamFile.values()) {
            paths.put(stream.name(), stream.path());
        }
        assertEquals(Map.of(
                "MENU", "audio/music/menu.ogg",
                "RUN", "audio/music/run.ogg",
                "WIN", "audio/music/win.ogg",
                "DEATH", "audio/music/death.ogg",
                "TORCH", "audio/ambience/torch.ogg"), paths);
    }

    /** The menu and run tracks and the torch loop; the win and death cues play once. */
    @Test
    void theTracksAndTheTorchLoopAndTheCuesPlayOnce() {
        assertTrue(StreamFile.MENU.loops());
        assertTrue(StreamFile.RUN.loops());
        assertTrue(StreamFile.TORCH.loops());
        assertFalse(StreamFile.WIN.loops());
        assertFalse(StreamFile.DEATH.loops());
    }

    /** Each music track has its own stream. */
    @Test
    void eachTrackHasItsStream() {
        assertEquals(StreamFile.MENU, StreamFile.of(Track.MENU));
        assertEquals(StreamFile.RUN, StreamFile.of(Track.RUN));
    }

    /** The win and death cues have streams, and asking for the chime's throws IllegalArgumentException. */
    @Test
    void theEndOfRunCuesHaveStreamsButTheChimeIsASoundEffect() {
        assertEquals(StreamFile.WIN, StreamFile.of(Cue.WIN));
        assertEquals(StreamFile.DEATH, StreamFile.of(Cue.DEATH));
        assertThrows(IllegalArgumentException.class, () -> StreamFile.of(Cue.CHIME));
    }
}
