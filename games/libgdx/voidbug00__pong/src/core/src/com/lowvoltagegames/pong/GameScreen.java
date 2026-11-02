package com.lowvoltagegames.pong;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.ScreenUtils;
import com.lowvoltagegames.pong.ai.AiObserver;
import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.GraphicsComponent;
import com.lowvoltagegames.pong.entity.PhysicsComponent;
import com.lowvoltagegames.pong.entity.ball.Ball;
import com.lowvoltagegames.pong.entity.ball.BallPhysics;
import com.lowvoltagegames.pong.entity.generic.NullInput;
import com.lowvoltagegames.pong.entity.generic.RectangleGraphics;
import com.lowvoltagegames.pong.entity.paddle.AiPaddleInput;
import com.lowvoltagegames.pong.entity.paddle.Paddle;
import com.lowvoltagegames.pong.entity.paddle.PaddleInput;
import com.lowvoltagegames.pong.entity.paddle.PaddlePhysics;

import java.util.ArrayList;

/**
 * Screen representing main playing screen of a Pong game
 */
public class GameScreen implements Screen {
    private final Pong game;
    private final ArrayList<GameObject> objects;
    private final AiObserver observer;
    private final ShapeRenderer shape;
    private final GraphicsComponent graphics;
    private final NullInput nullInput;

    public int player1Score = 0;
    public int player2Score = 0;

    public float width;
    public float height;

    /**
     * Create new screen with basic Pong objects; human vs AI
     * @param game lidgx Game representing the current window
     */
    public GameScreen(final Pong game) {
        this.game = game;

        this.shape = new ShapeRenderer();
        this.objects = new ArrayList<>();
        this.observer = new AiObserver();

        this.width = Gdx.graphics.getWidth();
        this.height = Gdx.graphics.getHeight();

        graphics = new RectangleGraphics();
        nullInput = new NullInput();
        PhysicsComponent paddlePhysics = new PaddlePhysics();

        GameObject obj = new Paddle(new PaddleInput(), paddlePhysics, graphics);
        addObject(obj, obj.width * 5, height / 2 - obj.height / 2);

        obj = new Paddle(new AiPaddleInput(observer), paddlePhysics, graphics);
        addObject(obj, width - obj.width * 5, height / 2 - obj.height / 2);

        obj = new Ball(nullInput, new BallPhysics(), graphics);
        observer.attach(obj);
        addObject(obj, width / 2 - obj.width / 2, height / 2 - obj.height / 2);
    }

    @Override
    public void show() {

    }

    /**
     * Update and render each object on the screen
     * @param delta Time since last render in millis
     */
    @Override
    public void render(float delta) {
        ScreenUtils.clear(0, 0, 0, 1);

        for (GameObject obj : objects) {
            obj.update(this, delta);
        }

        shape.begin(ShapeRenderer.ShapeType.Filled);
        for (GameObject obj : objects) {
            obj.render(shape);
        }
        shape.end();

        game.batch.begin();

        game.font.getData().setScale(3);
        game.font.draw(game.batch, Integer.toString(player1Score), width / 4, height * 3 / 4);
        game.font.draw(game.batch, Integer.toString(player2Score), width - width / 4, height * 3 / 4);

        game.batch.end();
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
        shape.dispose();
    }

    /**
     * Check obj against other objects on screen and resolve collisions
     * @param obj1 current GameObject
     * @see PhysicsComponent#collision(GameObject, GameObject)
     */
    public void resolveCollisions(GameObject obj1) {
        for (GameObject obj2 : objects) {
            if (obj1 != obj2) {
                if (obj1.x < obj2.x + obj2.width &&
                        obj1.x + obj1.width > obj2.x &&
                        obj1.y < obj2.y + obj2.height &&
                        obj1.y + obj1.height > obj2.y) {
                    obj1.collision(obj2);
                }
            }
        }
    }

    /**
     * Handle goal scored on right side of screen
     * @param ball Current ball
     * @see GameScreen#goalScored(GameObject)
     */
    public void goalScoredRight(GameObject ball) {
        player1Score++;
        goalScored(ball);
    }

    /**
     * Handle goal scored on left side of screen
     * @param ball Current ball
     * @see GameScreen#goalScored(GameObject)
     */
    public void goalScoredLeft(GameObject ball) {
        player2Score++;
        goalScored(ball);
    }

    /**
     * Handle goal being scored. Create new ball and update observer
     * @param ball Current ball
     */
    public void goalScored(GameObject ball) {
        objects.remove(ball);
        GameObject newBall = new Ball(nullInput, new BallPhysics(), graphics);
        observer.attach(newBall);
        addObject(newBall, width / 2 - newBall.width / 2, height / 2 - newBall.height / 2);
    }

    /**
     * Helper method to add an object to the screen
     * @param obj GameObject to add
     * @param x x position
     * @param y y position
     */
    private void addObject(GameObject obj, float x, float y) {
        obj.x = x;
        obj.y = y;
        objects.add(obj);
    }
}

