package ru.samsung.gamestudio.screens;

import static ru.samsung.gamestudio.MyGdxGame.SCR_HEIGHT;
import static ru.samsung.gamestudio.MyGdxGame.SCR_WIDTH;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.ScreenUtils;

import ru.samsung.gamestudio.characters.Bird;
import ru.samsung.gamestudio.components.MovingBackground;
import ru.samsung.gamestudio.MyGdxGame;
import ru.samsung.gamestudio.components.PointCounter;
import ru.samsung.gamestudio.characters.Tube;

public class ScreenGame implements Screen {

    final int pointCounterMarginTop = 60;
    final int pointCounterMarginRight = 400;

    static final int BASE_TUBE_SPEED = 10;
    static final int MAX_TUBE_SPEED = 28;
    static final int SPEED_STEP = 2;
    static final int POINTS_PER_SPEED_STEP = 5;

    static final float DYING_DURATION = 1.0f;
    static final float FLASH_DURATION = 0.4f;

    enum GameState { PLAYING, DYING, GAME_OVER }

    MyGdxGame myGdxGame;

    Bird bird;
    PointCounter pointCounter;
    MovingBackground background;
    ShapeRenderer shapeRenderer;

    int tubeCount = 3;
    Tube[] tubes;

    int gamePoints;
    GameState gameState;
    float dyingTimer;
    float flashTimer;

    public ScreenGame(MyGdxGame myGdxGame) {
        this.myGdxGame = myGdxGame;

        initTubes();
        background = new MovingBackground("backgrounds/game_bg.png");
        bird = new Bird(20, SCR_HEIGHT / 2, 10, 250, 200);
        pointCounter = new PointCounter(SCR_WIDTH - pointCounterMarginRight, SCR_HEIGHT - pointCounterMarginTop);
        shapeRenderer = new ShapeRenderer();
    }

    @Override
    public void show() {
        gamePoints = 0;
        gameState = GameState.PLAYING;
        dyingTimer = 0;
        flashTimer = 0;
        bird.reset(SCR_HEIGHT / 2);
        disposeTubes();
        initTubes();
    }

    @Override
    public void render(float delta) {
        if (gameState == GameState.GAME_OVER) {
            myGdxGame.updateBestScore(gamePoints);
            myGdxGame.screenRestart.setGamePoints(gamePoints, myGdxGame.getBestScore());
            myGdxGame.setScreen(myGdxGame.screenRestart);
            return;
        }

        if (gameState == GameState.PLAYING) {
            if (Gdx.input.justTouched()) {
                bird.onClick();
            }

            background.move();
            bird.fly();

            if (!bird.isInField()) {
                startDying();
            }

            for (Tube tube : tubes) {
                tube.move();
                if (tube.isHit(bird)) {
                    startDying();
                } else if (tube.needAddPoint(bird)) {
                    gamePoints += 1;
                    tube.setPointReceived();
                    applyProgressiveDifficulty();
                }
            }
        } else if (gameState == GameState.DYING) {
            bird.fly();
            dyingTimer += delta;
            if (dyingTimer >= DYING_DURATION) {
                gameState = GameState.GAME_OVER;
            }
        }

        if (flashTimer > 0) {
            flashTimer -= delta;
        }

        ScreenUtils.clear(1, 0, 0, 1);
        myGdxGame.camera.update();
        myGdxGame.batch.setProjectionMatrix(myGdxGame.camera.combined);
        myGdxGame.batch.begin();

        background.draw(myGdxGame.batch);
        bird.draw(myGdxGame.batch);
        for (Tube tube : tubes) tube.draw(myGdxGame.batch);
        pointCounter.draw(myGdxGame.batch, gamePoints);

        myGdxGame.batch.end();

        if (flashTimer > 0) {
            float alpha = (flashTimer / FLASH_DURATION) * 0.55f;
            shapeRenderer.setProjectionMatrix(myGdxGame.camera.combined);
            Gdx.gl.glEnable(GL20.GL_BLEND);
            Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
            shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
            shapeRenderer.setColor(1f, 0f, 0f, alpha);
            shapeRenderer.rect(0, 0, SCR_WIDTH, SCR_HEIGHT);
            shapeRenderer.end();
            Gdx.gl.glDisable(GL20.GL_BLEND);
        }
    }

    private void startDying() {
        if (gameState == GameState.PLAYING) {
            gameState = GameState.DYING;
            dyingTimer = 0;
            flashTimer = FLASH_DURATION;
            bird.setDead(true);
        }
    }

    private void applyProgressiveDifficulty() {
        int newSpeed = BASE_TUBE_SPEED + (gamePoints / POINTS_PER_SPEED_STEP) * SPEED_STEP;
        newSpeed = Math.min(newSpeed, MAX_TUBE_SPEED);
        for (Tube tube : tubes) {
            tube.setSpeed(newSpeed);
        }
    }

    @Override
    public void resize(int width, int height) {}

    @Override
    public void pause() {}

    @Override
    public void resume() {}

    @Override
    public void hide() {}

    @Override
    public void dispose() {
        bird.dispose();
        background.dispose();
        pointCounter.dispose();
        shapeRenderer.dispose();
        disposeTubes();
    }

    void disposeTubes() {
        if (tubes == null) return;
        for (Tube tube : tubes) {
            if (tube != null) tube.dispose();
        }
    }

    void initTubes() {
        tubes = new Tube[tubeCount];
        for (int i = 0; i < tubeCount; i++) {
            tubes[i] = new Tube(tubeCount, i);
        }
    }
}
