package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;

public class HighScoreScreen implements Screen {
    private CastleGame game;
    OrthographicCamera camera;

    Texture highScoreBG;
    Texture backButton;

    // Scores
    int currentScore = GameScreen.currentScore;
    boolean justScored = false;
    int hScore;

    /**
     * Create textures and everything need for highscore screen, also reads prefs file
     * and gets the top record from the file.
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public HighScoreScreen(CastleGame gam){
        this.game = gam;

        camera = new OrthographicCamera();
        camera.setToOrtho(false, game.WORLD_WIDTH, game.WORLD_HEIGHT);

        highScoreBG = new Texture("highscorebg.png");
        backButton = new Texture("backbutton.png");

        Preferences prefs = Gdx.app.getPreferences("highscore");
        hScore = prefs.getInteger("score", 0);
        if(currentScore > hScore){
            prefs.putInteger("score", currentScore);
            hScore = currentScore;
            prefs.flush();
        }
        game.medFont.setScale(2.0f);
    }

    @Override
    public void show() {

    }

    /**
     * Render everything needed on Score screen.
     * @param delta for delta time
     */
    @Override
    public void render(float delta) {
        Gdx.gl.glClearColor(0, 0, 0.2f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        camera.update();
        game.batch.setProjectionMatrix(camera.combined);

        game.batch.begin();
        game.batch.draw(highScoreBG,0,0);
        game.batch.draw(backButton,50,50);

        game.medFont.draw(game.batch,game.bundle.get("top-record")+" "+hScore,120,690);
        game.medFont.draw(game.batch,game.bundle.get("your-score")+" "+currentScore,135,600);

        game.batch.end();

        if(Gdx.input.isTouched())
        {
            Vector3 tmp=new Vector3(Gdx.input.getX(),Gdx.input.getY(),1);
            camera.unproject(tmp);
            Rectangle backButtonBounds = new Rectangle(50,50,250,145);
            if(backButtonBounds.contains(tmp.x,tmp.y)){
                game.setScreen(new MainMenuScreen(game));
                dispose();
            }
        }

        if(game.backKeyCatched){
            game.backKeyCatched = false;
            game.setScreen(new MainMenuScreen(game));
            dispose();
        }
    }

    /**
     * Basic setter for score system.
     *
     * @param score for player's current score
     */
    public void setScore(int score){
        currentScore = score;
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
        hScore = 0;
        currentScore = 0;
        justScored = false;
        highScoreBG.dispose();
        backButton.dispose();
    }
}