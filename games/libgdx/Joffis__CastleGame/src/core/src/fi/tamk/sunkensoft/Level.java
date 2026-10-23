package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;

/**
 *
 */
public class Level {
    CastleGame game;
    Texture level1;
    Texture level2;
    Texture level3;
    Texture level4;
    Texture levelSign;

    Music level1Music;
    Music level2Music;
    Music level3Music;
    Music level4Music;

    int levelHeight;
    int levelAmount = 5;
    int startingPlacement = 850;
    int currentMap = 1;
    int currentLevel = 1;

    int bannerY = 1200;
    int speed = 1;
    int lastMusic;

    boolean levelChange = false;

    /**
     * Create textures, musics and correct level sign.
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public Level(CastleGame gam) {
        game = gam;
        level1 = new Texture("level1.png");
        level2 = new Texture("level2.png");
        level3 = new Texture("level3.png");
        level4 = new Texture("level4.png");

        level1Music = Gdx.audio.newMusic(Gdx.files.internal("kek1.ogg"));
        level2Music = Gdx.audio.newMusic(Gdx.files.internal("kek2.ogg"));
        level3Music = Gdx.audio.newMusic(Gdx.files.internal("kek3.ogg"));
        level4Music = Gdx.audio.newMusic(Gdx.files.internal("kek4.ogg"));

        level1Music.setLooping(true);
        level2Music.setLooping(true);
        level3Music.setLooping(true);
        level4Music.setLooping(true);

        level1Music.setVolume(game.VOLUME);
        level2Music.setVolume(game.VOLUME);
        level3Music.setVolume(game.VOLUME);
        level4Music.setVolume(game.VOLUME);

        changeMusic();

        if(game.bundle == game.fiBundle){
            levelSign = new Texture("levelsign_fi.png");
        }else{
            levelSign = new Texture("levelsign.png");
        }
        levelHeight = level1.getHeight() / levelAmount;
    }

    /**
     * Renders background of the level and changes it when needed.
     *
     * @param batch SpriteBatch is needed to draw textures
     */
    public void update(SpriteBatch batch) {
        if(currentMap == 1){
            batch.draw(level1, 0, startingPlacement);
        }
        if(currentMap == 2){
            batch.draw(level2, 0, startingPlacement);
        }
        if(currentMap == 3){
            batch.draw(level3, 0, startingPlacement);
        }
        if(currentMap >= 4){
            batch.draw(level4, 0, startingPlacement);
        }
        if(levelChange){
            batch.draw(levelSign, game.WORLD_WIDTH / 2 - (levelSign.getWidth() / 2), bannerY);
            if(bannerY<=1030){
                speed = -speed;
                bannerY+=5;
            }
            bannerY -= speed;
            if(bannerY>=1210){
                levelChange = false;
                bannerY = 1200;
                speed = -speed;
            }
        }
    }

    /**
     * Changes level of the game
     */
    public void changeLevel(){
        startingPlacement = startingPlacement - levelHeight;
        currentLevel++;
        if(currentLevel > 5){
            currentMap++;
            currentLevel = 1;
            startingPlacement = 850;
            changeMusic();
        }
        levelChange = true;
    }

    /**
     * Randomizes new music when changeLevel calls it after 5 levels.
     */
    public void changeMusic(){
        level1Music.stop();
        level2Music.stop();
        level3Music.stop();
        level4Music.stop();

        int music;
        music = MathUtils.random(1, 4);

        while(music == lastMusic){
            music = MathUtils.random(1, 4);
            Gdx.app.log("While loop","");
        }
        if(music == 1){
                level1Music.play();
                Gdx.app.log("LOG", "SONG1");
                lastMusic = music;
        }

        if(music == 2){
                level2Music.play();
                Gdx.app.log("LOG", "SONG2");
                lastMusic = music;
        }

        if(music == 3){
                level3Music.play();
                Gdx.app.log("LOG", "SONG3");
                lastMusic = music;
        }

        if(music >= 4){
                level4Music.play();
                Gdx.app.log("LOG", "SONG4");
                lastMusic = music;
        }

        Gdx.app.log("LOG","Changed Song");
    }

    public void dispose(){
        level1Music.dispose();
        level2Music.dispose();
        level3Music.dispose();
        level4Music.dispose();
        level1.dispose();
        level2.dispose();
        level3.dispose();
        level4.dispose();
        levelSign.dispose();
    }
}
