package com.elmagica.game;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.math.MathUtils;

public class GameAudio {
    public enum Cue { SHOOT, HIT, HURT, DEATH, PICKUP, BUY, BOSS, ENEMY_SHOT, CLICK, FLOOR, DODGE }
    private static GameAudio current;
    private final Sound[] sounds = new Sound[Cue.values().length];
    private final long[] lastPlayed = new long[sounds.length];
    private final Music menuMusic;
    private final Music combatMusic;
    private final Music bossMusic;
    public enum Track { CALM, COMBAT, BOSS }
    public static Track trackFor(boolean alive, boolean merchant, boolean boss) {
        return !alive || merchant ? Track.CALM : boss ? Track.BOSS : Track.COMBAT;
    }
    private Music playing;
    private float musicVolume = 0.35f;
    private float effectsVolume = 0.65f;

    public GameAudio() {
        for (Cue cue : Cue.values()) {
            String name = cue == Cue.BOSS ? "boss_cue" : cue.name().toLowerCase(java.util.Locale.ROOT);
            sounds[cue.ordinal()] = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/" + name + ".wav"));
        }
        menuMusic = Gdx.audio.newMusic(Gdx.files.internal("audio/music/menu.wav"));
        combatMusic = Gdx.audio.newMusic(Gdx.files.internal("audio/music/combat.wav"));
        bossMusic = Gdx.audio.newMusic(Gdx.files.internal("audio/music/boss.wav"));
        menuMusic.setLooping(true); combatMusic.setLooping(true); bossMusic.setLooping(true);
        current = this;
    }
    public float getMusicVolume() { return musicVolume; }
    public float getEffectsVolume() { return effectsVolume; }
    public void setVolumes(float music, float effects) {
        musicVolume = MathUtils.clamp(music, 0, 1);
        effectsVolume = MathUtils.clamp(effects, 0, 1);
        if (effectsVolume == 0) for (Sound sound : sounds) sound.stop();
        menuMusic.setVolume(musicVolume); combatMusic.setVolume(musicVolume); bossMusic.setVolume(musicVolume);
    }
    public void update(boolean combat) {
        update(combat ? Track.COMBAT : Track.CALM);
    }
    public void update(Track track) {
        Music next = track == Track.BOSS ? bossMusic : track == Track.COMBAT ? combatMusic : menuMusic;
        if (playing == next) return;
        if (playing != null) playing.stop();
        playing = next; playing.setVolume(musicVolume); playing.play();
    }
    public static void play(Cue cue) {
        // В тестах звук не создан; при нулевой громкости тоже ничего не запускаем.
        if (current == null || current.effectsVolume == 0) return;
        int index = cue.ordinal(); long now = System.nanoTime();
        // Взрыв может задеть толпу — не накладываем кучу одинаковых звуков.
        if (now - current.lastPlayed[index] < 45000000L) return;
        current.lastPlayed[index] = now;
        current.sounds[index].play(current.effectsVolume);
    }
    public void dispose() {
        if (current == this) current = null;
        menuMusic.dispose(); combatMusic.dispose(); bossMusic.dispose();
        for (Sound sound : sounds) sound.dispose();
    }
}
