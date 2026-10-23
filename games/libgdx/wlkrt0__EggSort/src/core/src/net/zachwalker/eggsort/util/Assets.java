package net.zachwalker.eggsort.util;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetDescriptor;
import com.badlogic.gdx.assets.AssetErrorListener;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureAtlas.AtlasRegion;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;

public class Assets implements Disposable, AssetErrorListener{

    public static final Assets singleton = new Assets();

    private AssetManager manager;
    public Sounds sounds;
    public Images images;

    private Assets() {
        //private constructor (singleton)
    }

    public void init() {
        manager = new AssetManager();
        manager.setErrorListener(this);
        manager.load(Constants.SOUND_FARM_AMBIENCE, Music.class);
        manager.load(Constants.SOUND_NEW_LEVEL, Music.class);
        manager.load(Constants.SOUND_POWERUP, Music.class);
        manager.load(Constants.SOUND_NEW_EGG, Sound.class);
        manager.load(Constants.SOUND_VALVE, Sound.class);
        manager.load(Constants.SOUND_MISSED, Sound.class);
        manager.load(Constants.SOUND_GAME_OVER, Sound.class);
        manager.load(Constants.SOUND_FULL, Sound.class);

        manager.load(Constants.SOUND_BUTTON, Sound.class);
        for (int i = 0; i < Constants.SOUND_CAUGHT_COUNT; i++) {
            manager.load(
                    Constants.SOUND_CAUGHT_PREFIX + Integer.toString(i + 1) + Constants.SOUND_CAUGHT_SUFFIX,
                    Sound.class);
        }
        manager.load(Constants.PACKED_TEXTURE_ATLAS, TextureAtlas.class);
        //set loading to be synchronous
        manager.finishLoading();
        //initialize inner classes
        sounds = new Sounds(manager);
        images = new Images(manager);
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
        public Music farmAmbience;
        public Music newLevel;
        public Music powerup;
        public Sound newEgg;
        public Sound valve;
        public Sound missed;
        public Sound gameOver;
        public Sound full;
        public Sound button;
        public Array<Sound> caught;

        public Sounds(AssetManager manager) {
            farmAmbience = manager.get(Constants.SOUND_FARM_AMBIENCE, Music.class);
            newLevel = manager.get(Constants.SOUND_NEW_LEVEL, Music.class);
            powerup = manager.get(Constants.SOUND_POWERUP, Music.class);
            newEgg = manager.get(Constants.SOUND_NEW_EGG, Sound.class);
            valve = manager.get(Constants.SOUND_VALVE, Sound.class);
            missed = manager.get(Constants.SOUND_MISSED, Sound.class);
            gameOver = manager.get(Constants.SOUND_GAME_OVER, Sound.class);
            full = manager.get(Constants.SOUND_FULL, Sound.class);
            button = manager.get(Constants.SOUND_BUTTON, Sound.class);
            caught = new Array<Sound>();
            for (int i = 0; i < Constants.SOUND_CAUGHT_COUNT; i++) {
                caught.insert(i, manager.get(
                        Constants.SOUND_CAUGHT_PREFIX + Integer.toString(i + 1) + Constants.SOUND_CAUGHT_SUFFIX,
                        Sound.class));
            }
            farmAmbience.setLooping(true);
            farmAmbience.setVolume(0.5f);
            farmAmbience.play();

        }

        public void playSound(Sound sound) {
            if(!soundMuted) sound.play();
        }

        public void playMusic(Music music) {
            if(!soundMuted) {
                music.stop();
                music.play();
            }
        }

        public void toggleMute() {
            soundMuted = !soundMuted;
            if (soundMuted) {
                powerup.stop();
                newLevel.stop();
                farmAmbience.stop();
            } else {
                farmAmbience.play();
            }
        }

        public boolean isMuted() {
            return soundMuted;
        }

    }

    /* Inner class to provide a convenient namespace for image assets*/
    public class Images {

        public AtlasRegion background;
        public AtlasRegion buttonGotoLevel;
        public AtlasRegion buttonMute;
        public AtlasRegion buttonUnMute;
        public AtlasRegion buttonWhiteDown;
        public AtlasRegion buttonWhiteRight;
        public AtlasRegion buttonBrownDown;
        public AtlasRegion buttonBrownRight;
        public AtlasRegion eggWhite;
        public AtlasRegion eggBrown;
        public AtlasRegion eggChick;
        public Animation eggPowerup;
        public Array<AtlasRegion> bucketLeft;
        public Array<AtlasRegion> bucketMiddle;
        public Array<AtlasRegion> bucketRight;
        public Array<AtlasRegion> bucketsFilled;
        public Array<AtlasRegion> bucketsToFill;
        public AtlasRegion valveLeftOpen;
        public AtlasRegion valveLeftClosed;
        public AtlasRegion valveRightOpen;
        public AtlasRegion valveRightClosed;
        public Animation chickenWhite;
        public Animation chickenBrown;

        public Images(AssetManager manager) {
            TextureAtlas atlas = manager.get(Constants.PACKED_TEXTURE_ATLAS, TextureAtlas.class);

            background = atlas.findRegion(Constants.TEXTURE_BACKGROUND);

            buttonGotoLevel = atlas.findRegion(Constants.TEXTURE_BUTTON_GOTO_LEVEL);

            buttonMute = atlas.findRegion(Constants.TEXTURE_BUTTON_MUTE);
            buttonUnMute = atlas.findRegion(Constants.TEXTURE_BUTTON_UNMUTE);

            buttonWhiteDown = atlas.findRegion(Constants.TEXTURE_BUTTON_WHITE_DOWN);
            buttonWhiteRight = atlas.findRegion(Constants.TEXTURE_BUTTON_WHITE_RIGHT);
            buttonBrownDown = atlas.findRegion(Constants.TEXTURE_BUTTON_BROWN_DOWN);
            buttonBrownRight = atlas.findRegion(Constants.TEXTURE_BUTTON_BROWN_RIGHT);

            valveLeftOpen = atlas.findRegion(Constants.TEXTURE_VALVE_LEFT_OPEN);
            valveLeftClosed = atlas.findRegion(Constants.TEXTURE_VALVE_LEFT_CLOSED);
            valveRightOpen = atlas.findRegion(Constants.TEXTURE_VALVE_RIGHT_OPEN);
            valveRightClosed = atlas.findRegion(Constants.TEXTURE_VALVE_RIGHT_CLOSED);

            eggWhite = atlas.findRegion(Constants.TEXTURE_EGG_WHITE);
            eggBrown = atlas.findRegion(Constants.TEXTURE_EGG_BROWN);
            eggChick = atlas.findRegion(Constants.TEXTURE_EGG_CHICK);
            //note use of findRegions (with an s) below ---------------------------------------
            eggPowerup = new Animation(Constants.POWERUP_ANIMATION_DELAY,
                    atlas.findRegions(Constants.TEXTURES_EGG_POWERUP));

            bucketLeft = atlas.findRegions(Constants.TEXTURES_BUCKET_LEFT);
            bucketMiddle = atlas.findRegions(Constants.TEXTURES_BUCKET_MIDDLE);
            bucketRight = atlas.findRegions(Constants.TEXTURES_BUCKET_RIGHT);

            bucketsFilled = atlas.findRegions(Constants.TEXTURES_BUCKETS_FILLED);
            bucketsToFill = atlas.findRegions(Constants.TEXTURES_BUCKETS_TO_FILL);

            chickenWhite = new Animation(Constants.CHICKEN_ANIMATION_DELAY,
                    atlas.findRegions(Constants.TEXTURES_CHICKEN_WHITE));

            chickenBrown = new Animation(Constants.CHICKEN_ANIMATION_DELAY,
                    atlas.findRegions(Constants.TEXTURES_CHICKEN_BROWN));
        }
    }

}