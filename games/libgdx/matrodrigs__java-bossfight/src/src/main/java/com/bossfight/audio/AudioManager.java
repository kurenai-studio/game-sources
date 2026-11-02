package com.bossfight.audio;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.AudioDevice;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;

import java.util.concurrent.ConcurrentLinkedQueue;

public class AudioManager {
    public enum Cue {
        MENU_MOVE(520f, 0.045f, 0.12f, 1.25f),
        MENU_CONFIRM(390f, 0.08f, 0.16f, 1.85f),
        MENU_BACK(260f, 0.08f, 0.13f, 0.62f),
        PLAYER_SHOOT(860f, 0.035f, 0.09f, 1.18f),
        PLAYER_SPECIAL(280f, 0.18f, 0.18f, 2.35f),
        DASH(170f, 0.07f, 0.11f, 2.1f),
        PLAYER_HIT(160f, 0.12f, 0.2f, 0.48f),
        BOSS_HIT(560f, 0.045f, 0.12f, 0.72f),
        BOSS_VINE_CHARGE(145f, 0.16f, 0.13f, 1.9f, 0.12f),
        BOSS_VINE_STRIKE(190f, 0.14f, 0.2f, 0.28f, 0.42f),
        BOSS_MAGIC_CHARGE(360f, 0.18f, 0.11f, 1.75f, 0.05f),
        BOSS_MAGIC_VOLLEY(760f, 0.1f, 0.15f, 0.62f, 0.08f),
        BOSS_POLLEN_CHARGE(250f, 0.22f, 0.1f, 1.3f, 0.22f),
        BOSS_POLLEN_DROP(125f, 0.16f, 0.16f, 0.5f, 0.3f),
        BOSS_STAGGER(118f, 0.18f, 0.17f, 0.42f, 0.36f),
        BOSS_CHAIN_WARNING(440f, 0.16f, 0.14f, 1.65f, 0.12f),
        BOSS_FINAL_RAGE(72f, 0.42f, 0.23f, 0.28f, 0.52f),
        BOSS_PHASE_ROAR(88f, 0.48f, 0.24f, 0.34f, 0.58f),
        BOSS_PHASE_SHOCKWAVE(64f, 0.18f, 0.2f, 0.2f, 0.48f),
        BOSS_DEFEAT_EXPLOSION(96f, 0.085f, 0.21f, 0.24f, 0.82f),
        DEFEAT(190f, 0.22f, 0.16f, 0.55f);

        private final float frequency;
        private final float duration;
        private final float volume;
        private final float sweep;
        private final float noiseMix;

        Cue(float frequency, float duration, float volume, float sweep) {
            this(frequency, duration, volume, sweep, 0f);
        }

        Cue(float frequency, float duration, float volume, float sweep, float noiseMix) {
            this.frequency = frequency;
            this.duration = duration;
            this.volume = volume;
            this.sweep = sweep;
            this.noiseMix = noiseMix;
        }
    }

    private static final int SAMPLE_RATE = 44100;
    private static final String BOSS_PHASE_ROAR_PATH = "audio/sfx/boss_phase_roar.mp3";
    private static final float BOSS_PHASE_ROAR_VOLUME = 0.36f;

    private final ConcurrentLinkedQueue<Tone> tones = new ConcurrentLinkedQueue<>();
    private Thread proceduralThread;
    private volatile boolean proceduralAudioRunning;
    private Sound bossPhaseRoar;
    private final MusicChannel musicChannel = new MusicChannel();
    private final MusicChannel voiceChannel = new MusicChannel();
    private final MusicChannel ambienceChannel = new MusicChannel();

    public AudioManager() {
        this(true);
    }

    AudioManager(boolean proceduralAudioEnabled) {
        if (proceduralAudioEnabled) {
            startProceduralAudio();
        }
    }

    public void playMusic(String path, boolean looping, float volume) {
        playChannel(musicChannel, path, looping, volume, false);
    }

    public void stopMusic() {
        musicChannel.stop();
    }

    public void setMusicVolume(float volume) {
        musicChannel.setVolume(clampVolume(volume));
    }

    public void playVoice(String path, float volume) {
        playChannel(voiceChannel, path, false, volume, false);
    }

    public void stopVoice() {
        voiceChannel.stop();
    }

    public void playAmbience(String path, float volume) {
        playChannel(ambienceChannel, path, true, volume, true);
    }

    public void setAmbienceVolume(float volume) {
        ambienceChannel.setVolume(clampVolume(volume));
    }

    public void stopAmbience() {
        ambienceChannel.stop();
    }

    public void playCue(Cue cue) {
        if (cue == null || !proceduralAudioRunning) {
            return;
        }

        tones.offer(createTone(cue));
    }

    public void playBossPhaseRoar() {
        if (!exists(BOSS_PHASE_ROAR_PATH)) {
            playCue(Cue.BOSS_PHASE_ROAR);
            return;
        }

        try {
            if (bossPhaseRoar == null) {
                bossPhaseRoar = Gdx.audio.newSound(Gdx.files.internal(BOSS_PHASE_ROAR_PATH));
            }
            bossPhaseRoar.stop();
            bossPhaseRoar.play(BOSS_PHASE_ROAR_VOLUME);
        } catch (RuntimeException exception) {
            Gdx.app.log("AudioManager", "Boss phase roar unavailable: " + exception.getMessage());
            playCue(Cue.BOSS_PHASE_ROAR);
        }
    }

    public void dispose() {
        proceduralAudioRunning = false;
        Thread audioThread = proceduralThread;
        if (audioThread != null) {
            audioThread.interrupt();
            try {
                audioThread.join(1_000L);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
            }
        }
        proceduralThread = null;
        tones.clear();
        if (bossPhaseRoar != null) {
            bossPhaseRoar.dispose();
            bossPhaseRoar = null;
        }
        stopMusic();
        stopVoice();
        stopAmbience();
    }

    private void playChannel(MusicChannel channel, String path, boolean looping, float volume, boolean reuseCurrent) {
        if (!exists(path)) {
            return;
        }

        channel.play(path, looping, clampVolume(volume), reuseCurrent);
    }

    private boolean exists(String path) {
        return Gdx.files.internal(path).exists();
    }

    private void startProceduralAudio() {
        AudioDevice audioDevice = null;
        try {
            audioDevice = Gdx.audio.newAudioDevice(SAMPLE_RATE, true);
            proceduralAudioRunning = true;
            AudioDevice ownedDevice = audioDevice;
            proceduralThread = new Thread(() -> runProceduralAudio(ownedDevice), "bossfight-procedural-audio");
            proceduralThread.setDaemon(true);
            proceduralThread.start();
        } catch (RuntimeException exception) {
            proceduralAudioRunning = false;
            if (audioDevice != null) {
                audioDevice.dispose();
            }
            proceduralThread = null;
            Gdx.app.log("AudioManager", "Procedural audio unavailable: " + exception.getMessage());
        }
    }

    private Tone createTone(Cue cue) {
        return new Tone(cue.frequency, cue.duration, cue.volume, cue.sweep, cue.noiseMix);
    }

    private void runProceduralAudio(AudioDevice audioDevice) {
        try {
            while (proceduralAudioRunning) {
                Tone tone = tones.poll();
                if (tone == null) {
                    sleepQuietly(4L);
                    continue;
                }

                writeTone(audioDevice, tone);
            }
        } finally {
            proceduralAudioRunning = false;
            tones.clear();
            audioDevice.dispose();
        }
    }

    private void writeTone(AudioDevice audioDevice, Tone tone) {
        int sampleCount = Math.max(1, (int) (SAMPLE_RATE * tone.duration));
        float[] samples = new float[sampleCount];
        double phase = 0.0;
        int noiseState = 0x6D2B79F5 ^ Float.floatToIntBits(tone.frequency);

        for (int i = 0; i < sampleCount; i++) {
            float t = sampleCount == 1 ? 1f : (float) i / (sampleCount - 1);
            float frequency = tone.frequency * lerp(1f, tone.sweep, t);
            phase += Math.PI * 2.0 * frequency / SAMPLE_RATE;
            float attack = Math.min(1f, t / 0.12f);
            float decay = 1f - t;
            float envelope = attack * decay * decay;
            float sine = (float) Math.sin(phase);
            float square = sine >= 0f ? 1f : -1f;
            noiseState = noiseState * 1664525 + 1013904223;
            float noise = ((noiseState >>> 8) / 16777215f) * 2f - 1f;
            float tonal = sine * 0.72f + square * 0.28f;
            float mixedWave = tonal * (1f - tone.noiseMix) + noise * tone.noiseMix;
            samples[i] = mixedWave * envelope * tone.volume;
        }

        if (proceduralAudioRunning) {
            audioDevice.writeSamples(samples, 0, samples.length);
        }
    }

    private float lerp(float from, float to, float alpha) {
        return from + (to - from) * alpha;
    }

    private float clampVolume(float volume) {
        return Math.max(0f, Math.min(1f, volume));
    }

    private void sleepQuietly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
        }
    }

    private static final class Tone {
        private final float frequency;
        private final float duration;
        private final float volume;
        private final float sweep;
        private final float noiseMix;

        private Tone(float frequency, float duration, float volume, float sweep, float noiseMix) {
            this.frequency = frequency;
            this.duration = duration;
            this.volume = volume;
            this.sweep = sweep;
            this.noiseMix = noiseMix;
        }
    }

    private static final class MusicChannel {
        private Music music;
        private String path;

        private void play(String path, boolean looping, float volume, boolean reuseCurrent) {
            if (reuseCurrent && music != null && path.equals(this.path)) {
                music.setVolume(volume);
                if (!music.isPlaying()) {
                    music.play();
                }
                return;
            }

            stop();
            music = Gdx.audio.newMusic(Gdx.files.internal(path));
            this.path = path;
            music.setLooping(looping);
            music.setVolume(volume);
            music.play();
        }

        private void setVolume(float volume) {
            if (music != null) {
                music.setVolume(volume);
            }
        }

        private void stop() {
            if (music == null) {
                return;
            }

            music.stop();
            music.dispose();
            music = null;
            path = null;
        }
    }
}
