package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

/**
 *
 */
public class MainMenuScreen implements Screen {

    private CastleGame game;
    OrthographicCamera camera;

    Texture MainMenuBG;
    Texture playButton;
    Texture scoreButton;
    Texture settingsButton;

    //Music mainMenuMusic;

    int moveFont = 0;

    /**
     * Create textures and everything needed for Main Menu screen.
     *
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public MainMenuScreen(CastleGame gam) {
        game = gam;
        camera = new OrthographicCamera();
        camera.setToOrtho(false, game.WORLD_WIDTH, game.WORLD_HEIGHT);
        MainMenuBG = new Texture("mainmenubg.jpg");
        playButton = new Texture("playbutton.png");
        scoreButton = new Texture("scorebutton.png");
        settingsButton = new Texture("settingsbutton.png");
        game.font.setScale(2.0f);

        /*mainMenuMusic = Gdx.audio.newMusic(Gdx.files.internal("main_menu.ogg"));
        mainMenuMusic.setLooping(true);
        mainMenuMusic.setVolume(game.VOLUME-0.6f);
        mainMenuMusic.play();*/

        if(game.bundle != game.enBundle){
            moveFont = 15;
        }
    }

    @Override
    public void show() {
    }

    /**
     * Renders everything needed in Main menu and checks if player touches any of the buttons
     * on the screen. If player presses back button in main menu game closes, everywhere else
     * it backs up to main menu.
     *
     * @param delta for Delta Time
     */
    @Override
    public void render(float delta) {
        Gdx.gl.glClearColor(0, 0, 0.2f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        camera.update();
        game.batch.setProjectionMatrix(camera.combined);
        game.batch.begin();
        game.batch.draw(MainMenuBG, 0, 0);
        game.batch.draw(playButton, (game.WORLD_WIDTH/2)-(playButton.getWidth()/2), 550);
        game.batch.draw(scoreButton, (game.WORLD_WIDTH/2)-(playButton.getWidth()/2)+150, 300);
        game.batch.draw(settingsButton, (game.WORLD_WIDTH/2)-(playButton.getWidth()/2)-150, 300);
        //game.font.draw(game.batch,game.bundle.get("main-play"),((game.WORLD_WIDTH/2)-35)-moveFont, 750);
        //game.font.draw(game.batch,game.bundle.get("main-score"),(game.WORLD_WIDTH/2)+95, 500);
        //game.font.draw(game.batch,game.bundle.get("main-settings"),((game.WORLD_WIDTH/2)-221)-moveFont, 500);
        game.batch.end();

        if(Gdx.input.justTouched())
        {
            Vector3 tmp=new Vector3(Gdx.input.getX(),Gdx.input.getY(),1);
            camera.unproject(tmp);
            Rectangle playButtonBounds = new Rectangle((game.WORLD_WIDTH/2)-(playButton.getWidth()/2), 550,200,221);
            Rectangle scoreButtonBounds = new Rectangle((game.WORLD_WIDTH/2)-(playButton.getWidth()/2)+150, 300,200,221);
            Rectangle settingsButtonBounds = new Rectangle((game.WORLD_WIDTH/2)-(playButton.getWidth()/2)-150, 300,200,221);
            if(playButtonBounds.contains(tmp.x,tmp.y)){
                game.setScreen(new GameScreen(game));
                dispose();
            }
            if(scoreButtonBounds.contains(tmp.x,tmp.y)){
                game.setScreen(new HighScoreScreen(game));
                dispose();
            }
            if(settingsButtonBounds.contains(tmp.x,tmp.y)){
                game.setScreen(new SettingsScreen(game));
                dispose();
            }
        }
        if(game.backKeyCatched){
            game.backKeyCatched = false;
            dispose();
            Gdx.app.exit();
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
        Gdx.app.log("LOG","MainMenu disposed");
        //mainMenuMusic.dispose();
        MainMenuBG.dispose();
        playButton.dispose();
        scoreButton.dispose();
        settingsButton.dispose();
    }
}