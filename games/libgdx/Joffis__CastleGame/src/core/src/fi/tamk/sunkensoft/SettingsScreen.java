package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

public class SettingsScreen implements Screen {

    private CastleGame game;
    OrthographicCamera camera;

    Texture backGround;
    Texture backButton;
    Texture langFinButton;
    Texture langEngButton;
    Texture soundOnButton;
    Texture soundOffButton;
    Texture selectedBG;

    int langButtonX = 120;
    int soundButtonX = 120;

    /**
     * Create all textures etc. needed for Settings Screen.
     *
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public SettingsScreen(CastleGame gam){
        this.game = gam;

        camera = new OrthographicCamera();
        camera.setToOrtho(false, game.WORLD_WIDTH, game.WORLD_HEIGHT);

        backGround = new Texture("settingsbg.png");
        backButton = new Texture("backbutton.png");

        langEngButton = new Texture("langeng.png");
        langFinButton = new Texture("langfin.png");
        soundOffButton = new Texture("speakeroff.png");
        soundOnButton = new Texture("speakeron.png");
        selectedBG = new Texture("selectedbg.png");
        game.font.setScale(1.5f);

        if(game.bundle == game.fiBundle){
            langButtonX = 380;
        }
        if(game.VOLUME > 0.0f){
            soundButtonX = 380;
        }
    }

    @Override
    public void show() {

    }

    /**
     * Renders all textures and buttons of Settings Screen, also does
     * checks if player touched one of the buttons.
     *
     * @param delta for delta time
     */
    @Override
    public void render(float delta) {
        Gdx.gl.glClearColor(0, 0, 0.2f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        camera.update();
        game.batch.setProjectionMatrix(camera.combined);

        game.batch.begin();
        game.batch.draw(backGround,0,0);
        game.batch.draw(backButton,50,50);
        game.batch.draw(selectedBG,langButtonX,515);
        game.batch.draw(selectedBG,soundButtonX,330);
        game.batch.draw(langEngButton,140,560);
        game.batch.draw(langFinButton,400,560);
        game.batch.draw(soundOffButton,170,370);
        game.batch.draw(soundOnButton,430,370);

        game.font.draw(game.batch,game.bundle.get("english"),185,555);
        game.font.draw(game.batch,game.bundle.get("finnish"),445,555);

        game.font.draw(game.batch,game.bundle.get("soundoff"),160,365);
        game.font.draw(game.batch,game.bundle.get("soundon"),420,365);

        game.batch.end();

        if(Gdx.input.justTouched())
        {
            Vector3 tmp=new Vector3(Gdx.input.getX(),Gdx.input.getY(),1);
            camera.unproject(tmp);

            Rectangle engButtonBounds = new Rectangle(140,560,180,110);
            Rectangle finButtonBounds = new Rectangle(400,560,180,110);

            Rectangle sOffButtonBounds = new Rectangle(170,370,140,120);
            Rectangle sOnButtonBounds = new Rectangle(430,370,140,120);

            Rectangle backButtonBounds = new Rectangle(50,50,250,145);
            if(backButtonBounds.contains(tmp.x,tmp.y)){
                game.setScreen(new MainMenuScreen(game));
                dispose();
            }
            if(engButtonBounds.contains(tmp.x,tmp.y)){
                Gdx.app.log("LOG","Language: english");
                game.bundle = game.enBundle;
                langButtonX = 120;
            }
            if(finButtonBounds.contains(tmp.x,tmp.y)){
                Gdx.app.log("LOG","Language: finnish");
                game.bundle = game.fiBundle;
                langButtonX = 380;
            }
            if(sOffButtonBounds.contains(tmp.x,tmp.y)){
                Gdx.app.log("LOG","Sounds: Off");
                game.VOLUME = 0.0f;
                soundButtonX = 120;
            }
            if(sOnButtonBounds.contains(tmp.x,tmp.y)){
                Gdx.app.log("LOG","Sounds: On");
                game.VOLUME = 1.0f;
                soundButtonX = 380;
            }
        }
        if(game.backKeyCatched){
            game.backKeyCatched = false;
            game.setScreen(new MainMenuScreen(game));
            dispose();
        }
    }

    @Override
    public void resize(int width, int height) {

    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {

    }

    @Override
    public void hide() {
    }

    @Override
    public void dispose() {
        backGround.dispose();
        backButton.dispose();
        langFinButton.dispose();
        langEngButton.dispose();
        soundOnButton.dispose();
        soundOffButton.dispose();
        selectedBG.dispose();
    }
}