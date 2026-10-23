package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;

public class SplashScreen implements Screen {

    private CastleGame game;
    OrthographicCamera camera;

    Texture logoEng;
    Texture logoFin;

    float ColorX = 1.0f;
    long startTime;

    /**
     * Create everything needed in the splash screen.
     *
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public SplashScreen(CastleGame gam) {
        game = gam;
        camera = new OrthographicCamera();
        camera.setToOrtho(false, game.WORLD_WIDTH, game.WORLD_HEIGHT);
        logoEng = new Texture("entamklogo.png");
        logoFin = new Texture("fitamklogo.png");
        startTime = System.currentTimeMillis();
    }

    @Override
    public void show() {
    }

    /**
     * Renders all textures of the splash screen and does small color
     * change.
     *
     * @param delta for delta time
     */
    @Override
    public void render(float delta) {
        Gdx.gl.glClearColor(ColorX, ColorX, ColorX, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        camera.update();
        game.batch.setProjectionMatrix(camera.combined);

        game.batch.begin();
        game.batch.draw(logoEng, game.WORLD_WIDTH / 2 - logoEng.getWidth() / 2, game.WORLD_HEIGHT/2-logoEng.getHeight()/2);
        if(ColorX<=0.0f){
            game.batch.draw(logoFin, game.WORLD_WIDTH / 2 - logoFin.getWidth() / 2, game.WORLD_HEIGHT/2-logoFin.getHeight()/2);
        }
        game.batch.end();

        if(ColorX>0.0f){
            ColorX = ColorX-0.005f;
        }

        if(Gdx.input.justTouched())
        {
            game.setScreen(new MainMenuScreen(game));
            dispose();
        }

        if((System.currentTimeMillis() - startTime) >= 6000){
            Gdx.app.log("TIMER","Splash screen ends");
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
    public void dispose(){
        logoEng.dispose();
        logoFin.dispose();
    }
}