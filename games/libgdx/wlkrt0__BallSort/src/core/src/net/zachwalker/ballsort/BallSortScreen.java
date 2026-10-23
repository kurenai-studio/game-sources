package net.zachwalker.ballsort;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.DelayedRemovalArray;
import com.badlogic.gdx.utils.TimeUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import net.zachwalker.ballsort.entities.Bucket;
import net.zachwalker.ballsort.entities.Rectangle;
import net.zachwalker.ballsort.entities.TouchTargets;
import net.zachwalker.ballsort.entities.Valve;
import net.zachwalker.ballsort.overlays.Score;
import net.zachwalker.ballsort.util.Assets;
import net.zachwalker.ballsort.util.Constants;
import net.zachwalker.ballsort.entities.Ball;
import net.zachwalker.ballsort.util.Enums;


public class BallSortScreen extends ScreenAdapter {

    private Assets assets;
    private Viewport viewport;
    private ShapeRenderer renderer;
    private SpriteBatch batch;
    private DelayedRemovalArray<Ball> balls;
    private Array<Rectangle> chutes;
    private Array<Bucket> buckets;
    private Array<Valve> valves;
    private TouchTargets touchTargets;
    private Score score;
    private Enums.GameState gameState;
    private long currentScore;
    private long highScore;
    private int level;
    private int highLevel;
    private long lastPowerupStartedTime;
    private long lastBallSpawnedTime;
    private float nextBallSpawnInterval;
    private int combo;
    private long levelChangeStartedTime;
    private Preferences preferences;

    public BallSortScreen() {
        //the superclass doesn't do anything in its constructor either
        //the superclass is really just an interface
        super();
    }

    @Override
    public void show() {
        level = 1;
        assets = new Assets();
        viewport = new FitViewport(Constants.WORLD_WIDTH, Constants.WORLD_HEIGHT);
        renderer = new ShapeRenderer();
        batch = new SpriteBatch();
        balls = new DelayedRemovalArray<Ball>();
        chutes = new Array<Rectangle>();
        initializeChutes();
        buckets = new Array<Bucket>();
        //note that level must be set before initializing buckets since they use it to calc goal
        //note that this method initalizes static (empty outline) buckets in the Chutes array as well
        initializeBuckets();
        valves = new Array<Valve>();
        initializeValves();
        //note that touch targets must be initalized AFTER valves AND assets
        //also note that we need to pass the viewport to the touchtargets class since it will be
        //receiving touches and will need to unproject the touch input using the viewport
        //also need to pass in assets since it will be playing sounds when valves are toggled
        //also need to pass in this instance of BallSortScreen so it can call gotoHighLevel()
        touchTargets = new TouchTargets(viewport, valves, assets, this);
        Gdx.input.setInputProcessor(touchTargets);
        score = new Score();
        gameState = Enums.GameState.PLAYING_NORMAL;
        lastBallSpawnedTime = TimeUtils.nanoTime();
        preferences = Gdx.app.getPreferences(Constants.PREFERENCES_FILE_NAME);
        highScore = preferences.getLong(Constants.PREF_KEY_HIGH_SCORE);
        highLevel = preferences.getInteger(Constants.PREF_KEY_HIGH_LEVEL);
    }

    @Override
    public void render(float delta) {
        //all game logic except touch inputs. update everything's position, visibility, scores, etc.
        switch(gameState) {
            case PLAYING_NORMAL:
                addNewBall();
                removeBalls(delta);
                break;
            case GOTO_NEXT_LEVEL:
                assets.sounds.playSound(assets.sounds.newLevel);
                gotoLevel(level + 1);
                saveGame(); //save AFTER we increment the level
                break;
            case STARTING_NEXT_LEVEL:
                //just wait and increment the timer
                float elapsedSeconds = MathUtils.nanoToSec * (TimeUtils.nanoTime() - levelChangeStartedTime);
                if (elapsedSeconds >= Constants.LEVEL_START_DELAY) gameState = Enums.GameState.PLAYING_NORMAL;
                break;
            case GAME_OVER:
                assets.sounds.playSound(assets.sounds.gameOver);
                //similar to GOTO_NEXT_LEVEL, but saveGame is called BEFORE we reset the level
                saveGame();
                currentScore = 0;
                gotoLevel(1);
                break;
        }

        //clear the screen in preparation for rendering the updated positions / visibility of objects
        Gdx.gl.glClearColor(
                Constants.BACKGROUND_COLOR.r,
                Constants.BACKGROUND_COLOR.g,
                Constants.BACKGROUND_COLOR.b,
                Constants.BACKGROUND_COLOR.a);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        //render everything that is still visible in its updated position
        viewport.apply();
        renderer.setProjectionMatrix(viewport.getCamera().combined);

        for (Ball ball : balls) {
            ball.render(renderer);
        }

        for (Rectangle rectangle : chutes) {
            rectangle.render(renderer);
        }

        for (Bucket bucket : buckets) {
            bucket.render(renderer);
        }

        for (Valve valve : valves) {
            valve.render(renderer);
        }

        touchTargets.render(renderer);

        //draw sprites (including BitmapFonts)
        batch.setProjectionMatrix(viewport.getCamera().combined);
        batch.begin();
        score.render(batch, currentScore, highScore, level, combo);
        batch.end();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        renderer.dispose();
        batch.dispose();
        score.dispose();
    }

    public void gotoHighLevel() {
        //only go to the highlevel if it's higher than the current level
        if (highLevel > level) {
            //increment level to one less than highlevel since GOTO_NEXT_LEVEL will add one
            level = highLevel - 1;
            gameState = Enums.GameState.GOTO_NEXT_LEVEL;
        }
    }

    public void startPowerup() {
        assets.sounds.playSound(assets.sounds.powerup);
        lastPowerupStartedTime = TimeUtils.nanoTime();
    }

    public boolean isPowerupActive() {
        return ((TimeUtils.nanoTime() - lastPowerupStartedTime) * MathUtils.nanoToSec) <= Constants.POWERUP_DURATION;
    }

    private void gotoLevel(int level) {
        this.level = level;
        combo = 0;
        balls.clear();
        for (Bucket bucket : buckets) {
            bucket.reset(level * Constants.BUCKET_GOAL_PER_LEVEL);
        }
        levelChangeStartedTime = TimeUtils.nanoTime();
        gameState = Enums.GameState.STARTING_NEXT_LEVEL;
    }

    private void saveGame() {
        if (currentScore > highScore) {
            preferences.putLong(Constants.PREF_KEY_HIGH_SCORE, currentScore);
            highScore = currentScore;
        }
        if (level > highLevel) {
            preferences.putInteger(Constants.PREF_KEY_HIGH_LEVEL, level);
            highLevel = level;
        }
        preferences.flush();
    }

    private void addNewBall() {
        float elapsedSeconds = MathUtils.nanoToSec * (TimeUtils.nanoTime() - lastBallSpawnedTime);
        if (elapsedSeconds >= nextBallSpawnInterval) {
            //note that we are passing this class to the ball constructor so that balls can get and set powerup status
            balls.add(new Ball(this));
            assets.sounds.playSound(assets.sounds.newBall);
            lastBallSpawnedTime = TimeUtils.nanoTime();
            double x = (double) level;
            //refer to google sheets spreadsheet for origin of these two ugly formulas (curve fit)
            double nextMinBallSpawnInterval = Math.max(-0.01d * Math.pow(x, 3.0d) + 0.291d * Math.pow(x, 2.0d) - 2.796d * x + 10.516d, Constants.BALL_SPAWN_INTERVAL_MIN);
            double nextMaxBallSpawnInterval = Math.max(8.849d * Math.pow(Math.E, (x * -0.094d)), Constants.BALL_SPAWN_INTERVAL_MIN);
            nextBallSpawnInterval = MathUtils.random((float) nextMinBallSpawnInterval, (float) nextMaxBallSpawnInterval);
        }
    }

    private void removeBalls(float delta) {
        balls.begin();
        for (Ball ball : balls) {
            //note that we need to pass the valves to each ball so that the balls can check whether
            //they've arrived at a valve which is open
            ball.update(delta, valves);
            if (ball.ballState == Enums.BallState.CAUGHT) {
                combo += 1;
                currentScore += combo;
                playComboSound();
                balls.removeValue(ball, false);

                //increment ballcount on the bucket that matches the fellthru enum and play a sound if it's now full
                if (buckets.get(ball.fellThru.ordinal()).caughtBall()) assets.sounds.playSound(assets.sounds.full);

                //if all three buckets are now full, start a new level
                boolean allBucketsFull = true;
                for (Bucket bucket : buckets) {
                    if (!bucket.isFull()) allBucketsFull = false;
                }
                if (allBucketsFull) gameState = Enums.GameState.GOTO_NEXT_LEVEL;

            } else if (ball.ballState == Enums.BallState.MISSED) {
                assets.sounds.playSound(assets.sounds.missed);
                balls.removeValue(ball, false);
                combo = 0;
                currentScore = Math.max(0, currentScore - 25);
                //decrement ballcount on the bucket that matches the fellthru enum and end the game if it's below empty
                if (buckets.get(ball.fellThru.ordinal()).missedBall()) gameState = Enums.GameState.GAME_OVER;
            }
        }
        balls.end();
    }

    private void playComboSound() {
        if (combo >= Constants.SOUND_CAUGHT_COUNT) {
            assets.sounds.playSound(assets.sounds.caught.get(Constants.SOUND_CAUGHT_COUNT - 1));
        } else {
            assets.sounds.playSound(assets.sounds.caught.get(combo - 1));
        }
    }

    private void initializeValves() {
        //draw the left valve
        valves.add(new Valve(Constants.CHUTE_MARGIN + Constants.RAMP_WIDTH));
        //draw the right valve
        valves.add(new Valve(Constants.CHUTE_MARGIN + (2.0f * Constants.RAMP_WIDTH) + Constants.VALVE_WIDTH));
    }

    private void initializeBuckets() {
        //NOTE: this method initalizes static (empty outline) buckets in the Chutes array as well
        //draw the left DYNAMIC bucket (progress bar)
        float leftBucketX = Constants.CHUTE_MARGIN + Constants.RAMP_WIDTH + Constants.BALL_SIZE -
                (Constants.BUCKET_WIDTH / 2.0f);

        buckets.add(new Bucket(leftBucketX, Constants.BUCKET_LEFT_COLOR, level * Constants.BUCKET_GOAL_PER_LEVEL));

        //draw the middle DYNAMIC bucket (progress bar)
        float middleBucketX = Constants.CHUTE_MARGIN + (2.0f * Constants.RAMP_WIDTH) +
                Constants.VALVE_WIDTH + Constants.BALL_SIZE - (Constants.BUCKET_WIDTH / 2.0f);

        buckets.add(new Bucket(middleBucketX, Constants.BUCKET_MIDDLE_COLOR, level * Constants.BUCKET_GOAL_PER_LEVEL));

        //draw the right DYNAMIC bucket (progress bar)
        float rightBucketX = Constants.CHUTE_MARGIN + (3.0f * Constants.RAMP_WIDTH) +
                (2.0f * Constants.VALVE_WIDTH) + Constants.BALL_SIZE - (Constants.BUCKET_WIDTH / 2.0f);

        buckets.add(new Bucket(rightBucketX, Constants.BUCKET_RIGHT_COLOR, level * Constants.BUCKET_GOAL_PER_LEVEL));

        //draw the left STATIC (empty outline) bucket
        chutes.add(new Rectangle(
                leftBucketX,
                0.0f,
                Constants.BUCKET_WIDTH,
                Constants.BUCKET_HEIGHT,
                ShapeType.Line,
                Constants.BUCKET_LEFT_COLOR)
        );
        //draw the middle STATIC (empty outline) bucket
        chutes.add(new Rectangle(
                middleBucketX,
                0.0f,
                Constants.BUCKET_WIDTH,
                Constants.BUCKET_HEIGHT,
                ShapeType.Line,
                Constants.BUCKET_MIDDLE_COLOR)
        );
        //draw the right STATIC (empty outline) bucket
        chutes.add(new Rectangle(
                rightBucketX,
                0.0f,
                Constants.BUCKET_WIDTH,
                Constants.BUCKET_HEIGHT,
                ShapeType.Line,
                Constants.BUCKET_RIGHT_COLOR)
        );
    }

    private void initializeChutes() {
        //draw the vertical chute
        chutes.add(new Rectangle(
                Constants.CHUTE_MARGIN,
                0.0f,
                Constants.CHUTE_WIDTH,
                Constants.CHUTE_HEIGHT,
                ShapeType.Line,
                Constants.CHUTE_COLOR)
        );
        //draw the left horizontal chute (ramp)
        chutes.add(new Rectangle(
                Constants.CHUTE_MARGIN,
                Constants.CHUTE_HEIGHT,
                Constants.RAMP_WIDTH,
                Constants.CHUTE_WIDTH,
                ShapeType.Line,
                Constants.CHUTE_COLOR)
        );
        //draw the middle horizontal chute (ramp)
        chutes.add(new Rectangle(
                Constants.CHUTE_MARGIN + Constants.RAMP_WIDTH + Constants.VALVE_WIDTH,
                Constants.CHUTE_HEIGHT,
                Constants.RAMP_WIDTH,
                Constants.CHUTE_WIDTH,
                ShapeType.Line,
                Constants.CHUTE_COLOR)
        );
        //draw the right horizontal chute (ramp)
        chutes.add(new Rectangle(
                Constants.CHUTE_MARGIN + (2.0f * (Constants.RAMP_WIDTH + Constants.VALVE_WIDTH)),
                Constants.CHUTE_HEIGHT,
                Constants.RAMP_WIDTH,
                Constants.CHUTE_WIDTH,
                ShapeType.Line,
                Constants.CHUTE_COLOR)
        );
        //draw the ground
        chutes.add(new Rectangle(
                0.0f,
                0.0f,
                Constants.WORLD_WIDTH,
                0.0f,
                ShapeType.Line,
                Constants.CHUTE_COLOR)
        );
    }

}
