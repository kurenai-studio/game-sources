package ru.samsung.gamestudio.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.ScreenUtils;

import ru.samsung.gamestudio.components.MovingBackground;
import ru.samsung.gamestudio.MyGdxGame;
import ru.samsung.gamestudio.components.PointCounter;
import ru.samsung.gamestudio.components.TextButton;

public class ScreenRestart implements Screen {

    MyGdxGame myGdxGame;

    MovingBackground background;
    PointCounter pointCounter;
    PointCounter bestScoreCounter;
    PointCounter medalCounter;
    TextButton buttonRestart;
    TextButton buttonMenu;

    int gamePoints;
    int bestScore;

    public ScreenRestart(MyGdxGame myGdxGame) {
        this.myGdxGame = myGdxGame;

        pointCounter     = new PointCounter(750, 530);
        bestScoreCounter = new PointCounter(750, 440);
        medalCounter     = new PointCounter(750, 350);
        buttonRestart    = new TextButton(100, 400, "Заново");
        buttonMenu       = new TextButton(100, 150, "Меню");
        background       = new MovingBackground("backgrounds/restart_bg.png");
    }

    public void setGamePoints(int points, int best) {
        this.gamePoints = points;
        this.bestScore = best;
    }

    @Override
    public void show() {

    }

    @Override
    public void render(float delta) {

        if (Gdx.input.justTouched()) {

            Vector3 touch = myGdxGame.camera.unproject(
                    new Vector3(Gdx.input.getX(), Gdx.input.getY(), 0)
            );

            if (buttonRestart.isHit((int) touch.x, (int) touch.y)) {
                myGdxGame.setScreen(myGdxGame.screenGame);
            }
            if (buttonMenu.isHit((int) touch.x, (int) touch.y)) {
                myGdxGame.setScreen(myGdxGame.screenMenu);
            }
        }

        ScreenUtils.clear(1, 0, 0, 1);
        myGdxGame.camera.update();
        myGdxGame.batch.setProjectionMatrix(myGdxGame.camera.combined);
        myGdxGame.batch.begin();

        background.draw(myGdxGame.batch);
        buttonMenu.draw(myGdxGame.batch);
        buttonRestart.draw(myGdxGame.batch);
        pointCounter.draw(myGdxGame.batch, gamePoints);
        bestScoreCounter.drawBest(myGdxGame.batch, bestScore);
        medalCounter.drawText(myGdxGame.batch, getMedal(gamePoints));

        myGdxGame.batch.end();
    }

    private String getMedal(int score) {
        if (score >= 30) return "Медаль: Платина";
        if (score >= 15) return "Медаль: Золото";
        if (score >= 5)  return "Медаль: Серебро";
        return "Медаль: Бронза";
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
        background.dispose();
        buttonRestart.dispose();
        buttonMenu.dispose();
        pointCounter.dispose();
        bestScoreCounter.dispose();
        medalCounter.dispose();
    }
}
