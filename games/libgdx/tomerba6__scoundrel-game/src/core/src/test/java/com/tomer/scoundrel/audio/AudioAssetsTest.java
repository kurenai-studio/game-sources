package com.tomer.scoundrel.audio;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.UnsupportedAudioFileException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The shipped sound-effect files against the contract in {@link Sound}.
 *
 * <p>The files are rendered by Python ({@code audio-source/}) and committed, not
 * built, so nothing else stops a missing, stray or malformed one reaching a
 * player. Everything under {@code assets/} ships — a stray file is a failure
 * too, not just a missing one.
 *
 * <p>Per file it checks what the game relies on: the format LibGDX is handed,
 * a peak under −1 dBFS, and an attack inside the first 5 ms, because every
 * sound is played on its animation's beat and a late start lands off it. The
 * rest of the measuring (loudness, tails, loop seams) is {@code check.py}'s,
 * which needs numpy.
 *
 * <p>JDK-only ({@code javax.sound.sampled}); no LibGDX. Tests run from
 * {@code core/}, so the assets are one level up.
 */
class AudioAssetsTest {

    private static final Path SFX = Path.of("..", "assets").resolve(Sfx.DIRECTORY);
    private static final float SAMPLE_RATE = 44100f;
    /** −1 dBFS, in 16-bit sample units. */
    private static final int PEAK_LIMIT = (int) Math.floor(32767 * Math.pow(10, -1 / 20.0));
    /** −40 dBFS: where a sound counts as having started. */
    private static final int ONSET = (int) Math.ceil(32768 * 0.01);
    private static final int LEAD_LIMIT_SAMPLES = Math.round(SAMPLE_RATE * 0.005f);

    /**
     * Every sound-effect file the contract names, without its extension, one per parameterised run.
     *
     * @return the names, from {@link Sound#allFiles()}
     */
    static Stream<String> files() {
        return Sound.allFiles().stream();
    }

    /** The sound-effect folder holds exactly the contract's files, none missing and none stray. */
    @Test
    void theFolderHoldsExactlyTheContract() throws IOException {
        Set<String> expected = Sound.allFiles().stream()
                .map(name -> name + Sfx.EXTENSION)
                .collect(Collectors.toCollection(TreeSet::new));
        Set<String> present;
        try (Stream<Path> listing = Files.list(SFX)) {
            present = listing.map(p -> p.getFileName().toString()).collect(Collectors.toCollection(TreeSet::new));
        }
        Set<String> missing = new TreeSet<>(expected);
        missing.removeAll(present);
        Set<String> stray = new TreeSet<>(present);
        stray.removeAll(expected);
        assertTrue(missing.isEmpty() && stray.isEmpty(),
                "assets/" + Sfx.DIRECTORY + " must hold exactly Sound.allFiles(). Missing: " + missing
                        + "; stray (these would ship): " + stray);
    }

    /** Each sound effect is 16-bit mono PCM at 44.1 kHz, peaks under −1 dBFS and starts within 5 ms. */
    @ParameterizedTest(name = "{0}")
    @MethodSource("files")
    void eachFileIsWhatTheGameExpects(String name) throws IOException, UnsupportedAudioFileException {
        Path file = SFX.resolve(name + Sfx.EXTENSION);
        assertTrue(Files.isRegularFile(file), file + " is missing");
        short[] pcm;
        AudioFormat format;
        try (AudioInputStream in = AudioSystem.getAudioInputStream(file.toFile())) {
            format = in.getFormat();
            pcm = samples(in.readAllBytes());
        }
        assertEquals(List.of(AudioFormat.Encoding.PCM_SIGNED, 16, 1, SAMPLE_RATE, false),
                List.of(format.getEncoding(), format.getSampleSizeInBits(), format.getChannels(),
                        format.getSampleRate(), format.isBigEndian()),
                name + ": 16-bit signed little-endian mono PCM at 44.1 kHz");
        assertTrue(pcm.length > 0, name + " is empty");

        int peak = 0;
        int onset = -1;
        for (int i = 0; i < pcm.length; i++) {
            int magnitude = Math.abs((int) pcm[i]);
            peak = Math.max(peak, magnitude);
            if (onset < 0 && magnitude >= ONSET) {
                onset = i;
            }
        }
        assertTrue(peak <= PEAK_LIMIT, name + ": peak " + peak + " is over -1 dBFS (" + PEAK_LIMIT + ")");
        assertTrue(onset >= 0 && onset <= LEAD_LIMIT_SAMPLES,
                name + ": starts at sample " + onset + ", later than 5 ms, so it would land off its beat");
    }

    // --- the streams: music, cues, the torch loop ----------------------------

    private static final Path AUDIO = Path.of("..", "assets").resolve(StreamFile.ROOT);

    /**
     * The JDK cannot decode Vorbis, so the measuring (peak, loudness, seams) is
     * check.py's; this holds the folder to {@link StreamFile} and each file to being
     * an Ogg stream at all.
     */
    @Test
    void everyStreamIsThereAndIsAnOggStream() throws IOException {
        for (StreamFile stream : StreamFile.values()) {
            Path file = Path.of("..", "assets").resolve(stream.path());
            assertTrue(Files.isRegularFile(file), file + " is missing");
            byte[] head = new byte[4];
            try (var in = Files.newInputStream(file)) {
                assertEquals(4, in.read(head), file + " is empty");
            }
            assertEquals("OggS", new String(head, java.nio.charset.StandardCharsets.US_ASCII),
                    file + " is not an Ogg stream");
        }
    }

    /**
     * The audio folder holds only the effect and stream folders, and each stream
     * folder exactly its streams.
     */
    @Test
    void theStreamFoldersHoldNothingElseAndTheAudioFolderNothingElseAtAll() throws IOException {
        Set<String> expected = new TreeSet<>();
        Set<String> folders = new TreeSet<>(Set.of(Sfx.DIRECTORY.substring(StreamFile.ROOT.length(),
                Sfx.DIRECTORY.length() - 1)));
        for (StreamFile stream : StreamFile.values()) {
            String relative = stream.path().substring(StreamFile.ROOT.length());
            expected.add(relative);
            folders.add(relative.substring(0, relative.indexOf('/')));
        }
        Set<String> present = new TreeSet<>();
        Set<String> topLevel = new TreeSet<>();
        try (Stream<Path> listing = Files.list(AUDIO)) {
            listing.forEach(p -> topLevel.add(p.getFileName().toString()));
        }
        assertEquals(folders, topLevel, "assets/audio/ holds only these folders; anything else ships");
        for (String folder : folders) {
            if (Sfx.DIRECTORY.endsWith(folder + "/")) {
                continue; // the sound effects are held to Sound above
            }
            try (Stream<Path> listing = Files.list(AUDIO.resolve(folder))) {
                listing.forEach(p -> present.add(folder + "/" + p.getFileName()));
            }
        }
        assertEquals(expected, present, "the stream folders must hold exactly StreamFile's files");
    }

    private static short[] samples(byte[] bytes) {
        short[] out = new short[bytes.length / 2];
        for (int i = 0; i < out.length; i++) {
            out[i] = (short) ((bytes[2 * i] & 0xff) | (bytes[2 * i + 1] << 8));
        }
        return out;
    }
}
