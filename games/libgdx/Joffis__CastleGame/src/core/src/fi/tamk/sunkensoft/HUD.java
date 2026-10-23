package fi.tamk.sunkensoft;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;

public class HUD {
    CastleGame game;
    private BitmapFont MyBitmapFont;
    private Texture topHUD;
    private Texture comboBar;

    public int overAllScore = 0;
    private int currentLevel = 1;
    private int comboBarWidth = 0;

    public int comboValue = 0;

    /**
     * Create Textures and font
     * @param gam is part of Screens and it's needed here to use variables
     *            from CastleGame class
     */
    public HUD(CastleGame gam){
        game = gam;
        topHUD = new Texture("ylapalkki.jpg");
        comboBar = new Texture("combo_fill.png");

        MyBitmapFont = new BitmapFont();
        MyBitmapFont.scale(1.0f);
    }

    /**
     * Render everything needed on HUD in the game.
     */
    public void update(){
        game.batch.draw(topHUD, 0, 1200);
        game.batch.draw(comboBar,330, 1230, comboBarWidth, 30);
        MyBitmapFont.draw(game.batch,game.bundle.get("hud-score")+" "+overAllScore,30,1260);
        MyBitmapFont.draw(game.batch,game.bundle.get("hud-combo"),210,1260);
        MyBitmapFont.draw(game.batch,game.bundle.get("hud-level")+" "+ currentLevel, 570, 1260);

        if(comboValue <= 10){
            comboBarWidth = 18*comboValue;
        }else{
            MyBitmapFont.draw(game.batch,game.bundle.get("hud-maxcombo"),340, 1260);
        }

    }

    /**
     * Basic setter for the score on the hud
     * @param score for player's current score
     */
    public void setScore(int score){
        overAllScore = score;
    }

    /**
     * Basic setter for the level on the hud
     */
    public void setLevel(){
        currentLevel = currentLevel+1;
    }

    /**
     * Basic getter of the level from hud
     * @return current level the player is on
     */
    public int getLevel(){
        return currentLevel;
    }


    public void dispose(){
        MyBitmapFont.dispose();
        topHUD.dispose();
        comboBar.dispose();
    }
}
