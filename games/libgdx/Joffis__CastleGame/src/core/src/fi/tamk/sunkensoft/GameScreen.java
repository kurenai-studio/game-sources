package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.utils.TimeUtils;

public class GameScreen implements Screen {
    private CastleGame game;
    private OrthographicCamera camera;
    public static World world;

    Calculator calculator;
    Player player;
    Knight knight;
    Ground ground;
    Level levels;
    HUD topHUD;

    Texture cLives;
    Texture Background;

    // Player clicked calculator
    boolean clickedCalc = false;

    // For time steps
    private double accumulator;
    private double currentTime;
    private float timeStep = 1 / 60f;

    // DeathCount & Score
    private int deathCount = 0;
    public static int currentScore;

    // For Box2D Debugging
    //Box2DDebugRenderer debugRenderer;

    /**
     * GameScreen is needed to create everything happening when player starts
     * the game.
     *
     * @param gam is part of Screens and it's needed here to use variables
     *            from CastleGame class.
     */
    public GameScreen(CastleGame gam){
        this.game = gam;
        camera = new OrthographicCamera();
        camera.setToOrtho(false, game.WORLD_WIDTH, game.WORLD_HEIGHT);

        world = new World(new Vector2(0, -9.21f), false);

        calculator = new Calculator();
        player = new Player();
        knight = new Knight(game);
        ground = new Ground(game);
        topHUD = new HUD(game);
        levels = new Level(game);

        Background = new Texture("calcbackground5.jpg");
        cLives = new Texture("heart.png");

        //debugRenderer = new Box2DDebugRenderer();
    }

    /**
     * Needed to render everything on game screen.
     *
     * @param delta for delta time
     */
    @Override
    public void render(float delta) {
        camera.update();
        game.batch.setProjectionMatrix(camera.combined);
        Gdx.gl.glClearColor(0.3f, 0.3f, 0.3f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // ----- Time step calculation -----
        double newTime = TimeUtils.millis() / 1000.0;
        double deltaTime = newTime - currentTime;

        currentTime = newTime;

        if (deltaTime > 0.25) {
            deltaTime = 0.25;
        }

        accumulator += deltaTime;
        while (accumulator >= timeStep) {
            world.step(timeStep, 6, 2);
            accumulator -= timeStep;
        }
        // ----------------------------------

        game.batch.begin();
        levels.update(game.batch);
        game.batch.draw(Background, 0, 0);
        knight.cLevel = topHUD.getLevel();

        calculator.update(game);
        if (calculator.correct == 1) {
            player.scored = 1;
            calculator.correct = 0;
        }

        player.score = calculator.score;
        currentScore = calculator.score;
        player.update(game.batch);

        knight.update(game.batch);

        topHUD.update();
        topHUD.setScore(calculator.score);
        topHUD.comboValue = calculator.comboValue;
        //debugRenderer.render(world, camera.combined);
        if(deathCount < 2){
            game.batch.draw(cLives, 10,1145);
            if(deathCount < 1){
                game.batch.draw(cLives, 60,1145);
            }
        }
        game.batch.end();

        userInputCheck();
        player.playerComboValue = calculator.comboValue;
        Reset();
        if(deathCount >= 2){
            deathCount = 0;
            game.setScreen(new HighScoreScreen(game));
            dispose();
        }

        if(game.backKeyCatched){
            game.backKeyCatched = false;
            game.setScreen(new HighScoreScreen(game));
            dispose();
        }
    }


    /**
     * Checks which buttons player presses
     */
    private void userInputCheck() {
        if (Gdx.input.justTouched() && !calculator.timerTriggered) {
            Vector3 tmp = new Vector3(Gdx.input.getX(), Gdx.input.getY(), 1);
            camera.unproject(tmp);

            if (calculator.num1Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 1) {
                Gdx.app.log("LOG", "Clicked number 1");
                calculator.lastClick = 1;
                calculator.numSelection(calculator.num1, calculator.num1Rect);
                clickedCalc = true;
            }
            if (calculator.num2Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 2) {
                Gdx.app.log("LOG", "Clicked number 2");
                calculator.lastClick = 2;
                calculator.numSelection(calculator.num2, calculator.num2Rect);
                clickedCalc = true;
            }
            if (calculator.num3Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 3) {
                Gdx.app.log("LOG", "Clicked number 3");
                calculator.lastClick = 3;
                calculator.numSelection(calculator.num3, calculator.num3Rect);
                clickedCalc = true;
            }
            if (calculator.num4Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 4) {
                Gdx.app.log("LOG", "Clicked number 4");
                calculator.lastClick = 4;
                calculator.numSelection(calculator.num4, calculator.num4Rect);
                clickedCalc = true;
            }
            if (calculator.num5Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 5) {
                Gdx.app.log("LOG", "Clicked number 5");
                calculator.lastClick = 5;
                calculator.numSelection(calculator.num5, calculator.num5Rect);
                clickedCalc = true;
            }
            if (calculator.num6Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 6) {
                Gdx.app.log("LOG", "Clicked number 6");
                calculator.lastClick = 6;
                calculator.numSelection(calculator.num6, calculator.num6Rect);
                clickedCalc = true;
            }
            if (calculator.num7Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 7) {
                Gdx.app.log("LOG", "Clicked number 7");
                calculator.lastClick = 7;
                calculator.numSelection(calculator.num7, calculator.num7Rect);
                clickedCalc = true;
            }
            if (calculator.num8Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 8) {
                Gdx.app.log("LOG", "Clicked number 8");
                calculator.lastClick = 8;
                calculator.numSelection(calculator.num8, calculator.num8Rect);
                clickedCalc = true;
            }
            if (calculator.num9Rect.contains(tmp.x, tmp.y) && calculator.lastClick != 9) {
                Gdx.app.log("LOG", "Clicked number 9");
                calculator.lastClick = 9;
                calculator.numSelection(calculator.num9, calculator.num9Rect);
                clickedCalc = true;
                Gdx.input.vibrate(10);
            }
            if(!clickedCalc){
                Gdx.app.log("LOG", "Reset selection");
                calculator.resetSelection();
            }else{
                Gdx.input.vibrate(15);
            }
            clickedCalc = false;
        }
        if(Gdx.input.isKeyJustPressed(Input.Keys.DPAD_RIGHT)){
            knight.Restart();
            player.Restart();
            topHUD.setLevel();
            levels.changeLevel();
        }
    }

    /**
     * When player or enemy gets to the border of screen we need to reset things and change level etc.
     */
    private void Reset() {
        if (knight.Location() > game.WORLD_WIDTH) {
            knight.Restart();
            player.Restart();
            topHUD.setLevel();
            levels.changeLevel();
        }

        if (player.Location() < 0) {
            knight.Restart();
            player.Restart();
            deathCount++;
            calculator.comboValue = 0;

        }
    }

    @Override
    public void show() {
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
        Background.dispose();
        cLives.dispose();
        world.dispose();

        calculator.dispose();
        levels.dispose();
        player.dispose();
        knight.dispose();
        topHUD.dispose();
        //debugRenderer.dispose();
    }

}
