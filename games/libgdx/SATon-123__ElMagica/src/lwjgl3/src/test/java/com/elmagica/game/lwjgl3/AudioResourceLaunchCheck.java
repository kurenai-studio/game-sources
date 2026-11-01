package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.elmagica.game.GameAudio;

public class AudioResourceLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(640, 360); config.setInitialVisible(false); config.setForegroundFPS(60);
        new Lwjgl3Application(new ApplicationAdapter() {
            GameAudio audio; int frame;
            Music music(String name) {
                try { var field = GameAudio.class.getDeclaredField(name); field.setAccessible(true); return (Music) field.get(audio); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            @Override public void create() { audio = new GameAudio(); audio.setVolumes(0, 0); audio.update(false); }
            @Override public void render() {
                if (frame == 10) {
                    if (!music("menuMusic").isPlaying() || !music("menuMusic").isLooping()) throw new AssertionError("Menu WAV playback or looping failed");
                    audio.update(true);
                }
                if (frame == 15) {
                    if (music("menuMusic").isPlaying() || !music("combatMusic").isPlaying()) throw new AssertionError("Music switching failed");
                    audio.update(GameAudio.Track.BOSS);
                }
                if (frame == 20) {
                    if (music("combatMusic").isPlaying() || !music("bossMusic").isPlaying() || !music("bossMusic").isLooping()) throw new AssertionError("Boss loop failed");
                    music("bossMusic").stop(); audio.setVolumes(0.7f, 0.2f);
                    if (music("menuMusic").getVolume() != 0.7f || audio.getEffectsVolume() != 0.2f) throw new AssertionError("Separate volumes failed");
                    audio.setVolumes(0, 0); for (GameAudio.Cue cue : GameAudio.Cue.values()) GameAudio.play(cue);
                }
                if (++frame == 30) { System.out.println("Real audio check passed silently: all effects decoded, three music loops played, volumes and disposal"); Gdx.app.exit(); }
            }
            @Override public void dispose() { audio.dispose(); GameAudio.play(GameAudio.Cue.CLICK); }
        }, config);
    }
}
