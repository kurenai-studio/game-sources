package dev.luchoc.littlespaceship.game.adapter.audio;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.files.FileHandle;
import dev.luchoc.littlespaceship.game.GameSettings;
import java.util.EnumMap;
import java.util.Map;

/**
 * Owns every {@link Sound} and {@link Music} the game plays, loaded once at startup and mixed
 * against {@link GameSettings}'s three sliders — master, music, effects — read live on every play
 * so a slider dragged mid-run takes effect on the very next sound, and mid-playback for whatever
 * {@link Music} track is currently looping.
 *
 * <p><b>The browser gesture rule this class exists to satisfy:</b> a browser refuses to start audio
 * before a user gesture — a click, a key press, a touch — and {@code CLAUDE.md}'s own pitfall list
 * repeats it. Loading {@link Sound}/{@link Music} needs no gesture, only playing one does, so {@link
 * #unlock()} — called once, the first time any menu button fires, from {@code MenuEntries} — is
 * the single place that flips {@link #unlocked} to true. Every {@link #playSfx} and {@link
 * #playMusic} call before that is a silent no-op rather than a crash, which is what lets {@code
 * MenuScreen}'s very first show — reached from {@code LittleSpaceshipGame.create()}, with no
 * gesture behind it yet — ask for nothing and get exactly that.
 *
 * <p>{@link Sfx#EXPLOSION} and the boss music swap are both driven by {@link AudioDirector}: the
 * former from {@code core}'s {@code EnemyDestroyed} event, the latter from a {@code
 * WorldView.bossStatus().present()} diff. Everything else in the MVP's audio list — shots, the
 * player's own hits, all six pickup kinds, the bomb, and UI — is driven off frame-over-frame
 * differences in {@link dev.luchoc.littlespaceship.core.port.PlayerStatus} and {@link
 * dev.luchoc.littlespaceship.core.port.InputFrame}, which already say enough.
 *
 * <p>Not per-frame allocation: every {@link Sound}/{@link Music} is loaded once in the constructor
 * and looked up from an {@link EnumMap} on each play; {@link Sound#play(float)} itself is
 * libGDX's own call, made at most a handful of times a second in response to real gameplay events,
 * nowhere near the render loop's per-frame budget.
 */
public final class AudioSystem {

    private final GameSettings settings;
    private final Map<Sfx, Sound> sounds = new EnumMap<>(Sfx.class);
    private final Map<MusicTrack, Music> tracks = new EnumMap<>(MusicTrack.class);

    private boolean unlocked;
    private Music currentMusic;

    public AudioSystem(GameSettings settings) {
        this.settings = settings;
        for (Sfx sfx : Sfx.values()) {
            FileHandle handle = Gdx.files.internal("audio/sfx/" + sfx.fileName());
            if (handle.exists()) {
                sounds.put(sfx, Gdx.audio.newSound(handle));
            } else {
                Gdx.app.error("AudioSystem", "missing sfx asset '" + handle.path()
                    + "', run ./gradlew :game:generateAudio");
            }
        }
        for (MusicTrack track : MusicTrack.values()) {
            FileHandle handle = Gdx.files.internal("audio/music/" + track.fileName());
            if (handle.exists()) {
                Music music = Gdx.audio.newMusic(handle);
                music.setLooping(true);
                tracks.put(track, music);
            } else {
                Gdx.app.error("AudioSystem", "missing music asset '" + handle.path()
                    + "', run ./gradlew :game:generateAudio");
            }
        }
    }

    /** Allows playback from now on. Idempotent; see the class javadoc for why this exists at all. */
    public void unlock() {
        unlocked = true;
    }

    /** Plays a one-shot effect at {@code master * effects} volume. Does nothing before {@link
     * #unlock()}, and nothing if the asset failed to load. */
    public void playSfx(Sfx sfx) {
        if (!unlocked) {
            return;
        }
        Sound sound = sounds.get(sfx);
        if (sound != null) {
            sound.play(settings.masterVolume() * settings.effectsVolume());
        }
    }

    /**
     * Starts {@code track} looping, stopping whatever was already playing first. Calling this with
     * the track already playing does nothing — restarting a loop that is already going would be an
     * audible stutter for no reason.
     */
    public void playMusic(MusicTrack track) {
        if (!unlocked) {
            return;
        }
        Music music = tracks.get(track);
        if (music == null) {
            return;
        }
        if (currentMusic == music && music.isPlaying()) {
            return;
        }
        stopMusic();
        currentMusic = music;
        music.setVolume(settings.masterVolume() * settings.musicVolume());
        music.play();
    }

    /** Stops whatever is currently looping, if anything. The audible "return to menu" cue is this
     * call, per {@link MusicTrack}'s javadoc: silence is the change. */
    public void stopMusic() {
        if (currentMusic != null) {
            currentMusic.stop();
            currentMusic = null;
        }
    }

    /** Re-applies the current volume sliders to whatever is playing right now. Call after a slider
     * changes; {@link #playSfx} already reads live volumes on its own, so only {@link Music}, which
     * holds its volume until told otherwise, needs this nudge. */
    public void refreshVolume() {
        if (currentMusic != null) {
            currentMusic.setVolume(settings.masterVolume() * settings.musicVolume());
        }
    }

    public void dispose() {
        for (Sound sound : sounds.values()) {
            sound.dispose();
        }
        for (Music music : tracks.values()) {
            music.dispose();
        }
    }
}
