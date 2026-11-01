package com.alligatorX.game;

// Import other classes
import com.alligatorX.game.view.MainMenuScreen;
import com.badlogic.gdx.Game;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.math.MathUtils;

// Game for managing and swaping Screen
public class TypeHigher extends Game {
    // batch is public since creating batch for every screen waste memory
    public SpriteBatch batch;
    public Sound typingSound; // Global sound variable
    public Sound errorSound;
    public Sound speedUpSound;
    public Sound systemSound;
    public Sound winSound;
    public Sound loseSound;
    public Music menuMusic;
    public Music unlimitedMusic;
    public Music[] limitedMusic; // Array to hold 3 random bgm
    public Music currentMusic; // Track the music that is playing so we can stop it


    @Override
    // Load assets
    public void create() {
        batch = new SpriteBatch();

        // Load sound effect once
        typingSound = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/game/type.wav"));
        errorSound = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/game/typo.wav"));
        speedUpSound = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/game/speedUp.wav"));
        systemSound = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/ui/button.wav"));
        winSound = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/game/survived.mp3"));
        loseSound = Gdx.audio.newSound(Gdx.files.internal("audio/sfx/game/fell.mp3"));

        // Load all music
        menuMusic = Gdx.audio.newMusic(Gdx.files.internal("audio/bgm/menu.mp3"));
        menuMusic.setLooping(true);
        menuMusic.setVolume(0.3f);

        unlimitedMusic = Gdx.audio.newMusic(Gdx.files.internal("audio/bgm/unlimited.mp3"));
        unlimitedMusic.setLooping(true);
        unlimitedMusic.setVolume(0.3f);

        limitedMusic = new Music[3];
        limitedMusic[0] = Gdx.audio.newMusic(Gdx.files.internal("audio/bgm/game1.mp3"));
        limitedMusic[1] = Gdx.audio.newMusic(Gdx.files.internal("audio/bgm/game2.mp3"));
        limitedMusic[2] = Gdx.audio.newMusic(Gdx.files.internal("audio/bgm/game3.mp3"));

        for (Music m : limitedMusic) {
            m.setLooping(true);
            m.setVolume(0.3f);
        }

        playMenuMusic();

        this.setScreen(new MainMenuScreen(this)); // Create screen, default at main menu
    }

    // Smart Switcher
    public void switchMusic(Music newMusic) {
        // If the song we want to play is already playing, do nothing
        if (currentMusic == newMusic) {
            return;
        }

        // Stop old song if one is playing
        if (currentMusic != null) {
            currentMusic.stop();
        }

        // Play the new song and track it
        currentMusic = newMusic;
        currentMusic.play();
    }

    // Public trigger
    public void playMenuMusic() {
        switchMusic(menuMusic);
    }

    public void playUnlimitedGameMusic() {
        switchMusic(unlimitedMusic);
    }

    public void playLimitedGameMusic() {
        int randomIndex = MathUtils.random(0, 2); // Pick a random number from 0 to 2
        switchMusic(limitedMusic[randomIndex]);
    }

    // Create helper method
    public void playTypingSound() {
        // Volume: 50%
        // Pitch: random number between 0.8(deep) and 1.2(high)
        // Pan: 0 (center of the speakers)
        float randomPitch = MathUtils.random(0.8f, 1.2f);
        typingSound.play(0.5f, randomPitch, 0);
    }

    public void playTypoSound() {
        errorSound.play(0.5f);
    }

    public void playSpeedUpSound() {
        speedUpSound.play(0.5f);
    }

    public void playSystemSound() {
        systemSound.play(0.5f);
    }

    public void playWinSound() {
        winSound.play(0.7f); // Louder for celebration
    }

    public void playLoseSound() {
        loseSound.play(0.7f);
    }

    @Override
    // Game loop
    public void render() {
        // Clean previous frame and draw new frame with BGRA
        // Open the batch and tells what to draw
        super.render();
    }

    @Override
    // Destroys assets to free up memory
    public void dispose() {
        batch.dispose();
        typingSound.dispose();
        errorSound.dispose();
        speedUpSound.dispose();
        systemSound.dispose();
        winSound.dispose();
        loseSound.dispose();
        menuMusic.dispose();
        unlimitedMusic.dispose();
        for (Music m : limitedMusic) {
            m.dispose();
        }

    }
}
