package fi.tamk.sunkensoft;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.I18NBundle;

import java.util.Locale;

public class CastleGame extends Game {
    private OrthographicCamera camera;
    public SpriteBatch batch;

    // World size (720p)
    public float WORLD_WIDTH = 720;
    public float WORLD_HEIGHT = 1280;

    // Fonts
    public BitmapFont calcFont;
    public BitmapFont medFont;
    public BitmapFont font;

    // Muting can be found from SettingsScreen.java
    public float VOLUME = 1.0f;

    // For finnish and english languages..
    I18NBundle fiBundle;
    I18NBundle enBundle;
    I18NBundle bundle;

    // If player presses back key on android or ESC on PC.
    public boolean backKeyCatched = false;

    public void create() {
        batch = new SpriteBatch();
        font = new BitmapFont();
        font.scale(3.0f);
        this.setScreen(new SplashScreen(this));

        camera = new OrthographicCamera();
        camera.setToOrtho(false, WORLD_WIDTH, WORLD_HEIGHT);

        // Fonts
        calcFont = new BitmapFont(Gdx.files.internal("font.txt"));
        medFont = new BitmapFont(Gdx.files.internal("font2.txt"));

        Locale enLocale = new Locale("en");
        Locale fiLocale = new Locale("fi");

        enBundle = I18NBundle.createBundle(Gdx.files.internal("MyBundle"), enLocale);
        fiBundle = I18NBundle.createBundle(Gdx.files.internal("MyBundle"), fiLocale);

        // Selected language
        bundle = enBundle;

        Gdx.input.setCatchBackKey(true);
    }

    /**
     * Checks if player have pressed back key on android or ESC on PC
     * we also need render stuff from Game so super.render() is important.
     */
    public void render() {
        super.render(); //important!
        if(Gdx.input.isKeyPressed(Input.Keys.BACK) && !backKeyCatched || Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE) && !backKeyCatched){
            backKeyCatched = true;
        }
    }

    public void dispose() {
        batch.dispose();
        font.dispose();
        calcFont.dispose();
        medFont.dispose();
    }
}
