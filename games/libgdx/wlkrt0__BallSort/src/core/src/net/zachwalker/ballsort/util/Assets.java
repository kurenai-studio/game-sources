package net.zachwalker.ballsort.util;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetDescriptor;
import com.badlogic.gdx.assets.AssetErrorListener;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;

public class Assets implements Disposable, AssetErrorListener {

    private AssetManager manager;
    public Sounds sounds;

    public Assets() {
        manager = new AssetManager();
        manager.setErrorListener(this);
        manager.load(Constants.SOUND_NEWBALL, Sound.class);
        manager.load(Constants.SOUND_VALVE, Sound.class);
        manager.load(Constants.SOUND_MISSED, Sound.class);
        manager.load(Constants.SOUND_GAME_OVER, Sound.class);
        manager.load(Constants.SOUND_FULL, Sound.class);
        manager.load(Constants.SOUND_NEW_LEVEL, Sound.class);
        manager.load(Constants.SOUND_POWERUP, Sound.class);
        manager.load(Constants.SOUND_BUTTON, Sound.class);
        for (int i = 0; i < Constants.SOUND_CAUGHT_COUNT; i++) {
            manager.load(
                    Constants.SOUND_CAUGHT_PREFIX + Integer.toString(i + 1) + Constants.SOUND_CAUGHT_SUFFIX,
                    Sound.class);
        }
        //set loading to be synchronous
        manager.finishLoading();
        //initialize inner classes
        sounds = new Sounds(manager);
    }

    @Override
    public void error(AssetDescriptor asset, Throwable throwable) {
        Gdx.app.error(Constants.LOG_TAG, "Couldn't load asset: " + asset.fileName, throwable);
    }

    @Override
    public void dispose() {
        manager.dispose();
    }

    /* Inner class to provide a convenient namespace for sound assets*/
    public class Sounds {

        private boolean soundMuted;
        public Sound newBall;
        public Sound valve;
        public Sound missed;
        public Sound gameOver;
        public Sound full;
        public Sound newLevel;
        public Sound powerup;
        public Sound button;
        public Array<Sound> caught;

        public Sounds(AssetManager manager) {
            newBall = manager.get(Constants.SOUND_NEWBALL, Sound.class);
            valve = manager.get(Constants.SOUND_VALVE, Sound.class);
            missed = manager.get(Constants.SOUND_MISSED, Sound.class);
            gameOver = manager.get(Constants.SOUND_GAME_OVER, Sound.class);
            full = manager.get(Constants.SOUND_FULL, Sound.class);
            newLevel = manager.get(Constants.SOUND_NEW_LEVEL, Sound.class);
            powerup = manager.get(Constants.SOUND_POWERUP, Sound.class);
            button = manager.get(Constants.SOUND_BUTTON, Sound.class);

            caught = new Array<Sound>();
            for (int i = 0; i < Constants.SOUND_CAUGHT_COUNT; i++) {
                caught.insert(i, manager.get(
                        Constants.SOUND_CAUGHT_PREFIX + Integer.toString(i + 1) + Constants.SOUND_CAUGHT_SUFFIX,
                        Sound.class));
            }
        }

        public void playSound(Sound sound)
        {
            if(!soundMuted) sound.play();
        }

        public void toggleMute() {
            soundMuted = !soundMuted;
        }

    }

}
