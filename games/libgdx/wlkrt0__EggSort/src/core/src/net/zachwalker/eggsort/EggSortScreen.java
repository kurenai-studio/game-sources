package net.zachwalker.eggsort;


import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.DelayedRemovalArray;
import com.badlogic.gdx.utils.TimeUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import net.zachwalker.eggsort.entities.Bucket;
import net.zachwalker.eggsort.entities.Buttons;
import net.zachwalker.eggsort.entities.Chicken;
import net.zachwalker.eggsort.entities.Egg;
import net.zachwalker.eggsort.entities.ScoreText;
import net.zachwalker.eggsort.entities.Valve;
import net.zachwalker.eggsort.util.Assets;
import net.zachwalker.eggsort.util.Constants;
import net.zachwalker.eggsort.util.DrawingHelpers;
import net.zachwalker.eggsort.util.Enums;

public class EggSortScreen extends ScreenAdapter {

    private Viewport viewport;
    private SpriteBatch batch;
    private DelayedRemovalArray<Egg> eggs;
    private Bucket bucketLeft;
    private Bucket bucketMiddle;
    private Bucket bucketRight;
    private Valve leftValve;
    private Valve rightValve;
    private Buttons buttons;
    private ScoreText scoreText;
    private Chicken chickenWhite;
    private Chicken chickenBrown;
    private Enums.GameState gameState;
    private long currentScore;
    private long highScore;
    private int level;
    private int highLevel;
    private long lastPowerupStartedTime;
    private long lastEggSpawnedTime;
    private float nextEggSpawnInterval;
    private int combo;
    private long levelChangeStartedTime;
    private Preferences preferences;

    public EggSortScreen() {
        //the superclass doesn't do anything in its constructor either
        //the superclass is really just an interface
        super();
    }

    @Override
    public void show() {
        level = 1;
        Assets.singleton.init();
        viewport = new FitViewport(Constants.WORLD_WIDTH, Constants.WORLD_HEIGHT);
        batch = new SpriteBatch();
        eggs = new DelayedRemovalArray<Egg>();
        chickenWhite = new Chicken(Constants.CHICKEN_WHITE_POSITION, Enums.ChickenColor.WHITE);
        chickenBrown = new Chicken(Constants.CHICKEN_BROWN_POSITION, Enums.ChickenColor.BROWN);
        //note that level must be set before initializing buckets since they use it to calc goal
        bucketLeft = new Bucket(Constants.BUCKET_LEFT_POSITION, Enums.EggType.WHITE);
        bucketMiddle = new Bucket(Constants.BUCKET_MIDDLE_POSITION, Enums.EggType.BROWN);
        bucketRight = new Bucket(Constants.BUCKET_RIGHT_POSITION, Enums.EggType.CHICK);
        leftValve = new Valve(Constants.VALVE_LEFT_POSITION, Enums.EggType.WHITE);
        rightValve = new Valve(Constants.VALVE_RIGHT_POSITION, Enums.EggType.BROWN);
        /*
        Note that Buttons must be initialized AFTER valves AND assets.
        Also note that we need to pass the viewport to the Buttons class since Buttons will be
            receiving touches and will need to unproject the touch input using the viewport.
        Also need to pass in BallSortScreen so Buttons can call gotoHighLevel() when its button is clicked.
        */
        buttons = new Buttons(this, viewport, leftValve, rightValve);
        Gdx.input.setInputProcessor(buttons);
        scoreText = new ScoreText();
        gameState = Enums.GameState.PLAYING_NORMAL;
        //lastEggSpawnedTime = TimeUtils.nanoTime();
        preferences = Gdx.app.getPreferences(Constants.PREFERENCES_FILE_NAME);
        highScore = preferences.getLong(Constants.PREF_KEY_HIGH_SCORE);
        highLevel = preferences.getInteger(Constants.PREF_KEY_HIGH_LEVEL);
        Assets.singleton.sounds.playMusic(Assets.singleton.sounds.newLevel);
        gotoLevel(level);
    }

    @Override
    public void render(float delta) {
        //all game logic except touch inputs. update everything's position, visibility, scores, etc.
        switch(gameState) {
            case PLAYING_NORMAL:
                addNewEgg();
                removeEggs(delta);
                break;
            case GOTO_NEXT_LEVEL:
                Assets.singleton.sounds.playMusic(Assets.singleton.sounds.newLevel);
                gotoLevel(level + 1);
                saveGame(); //save AFTER we increment the level
                break;
            case STARTING_NEXT_LEVEL:
                //just wait and increment the timer
                float elapsedSeconds = MathUtils.nanoToSec * (TimeUtils.nanoTime() - levelChangeStartedTime);
                if (elapsedSeconds >= Constants.LEVEL_START_DELAY) gameState = Enums.GameState.PLAYING_NORMAL;
                break;
            case GAME_OVER:
                Assets.singleton.sounds.playSound(Assets.singleton.sounds.gameOver);
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
        batch.setProjectionMatrix(viewport.getCamera().combined);
        batch.begin();

        DrawingHelpers.drawSprite(batch, Assets.singleton.images.background, 0.0f, 0.0f);

        for (Egg egg : eggs) {
            egg.render(batch);
        }

        bucketLeft.render(batch);
        bucketMiddle.render(batch);
        bucketRight.render(batch);

        leftValve.render(batch);
        rightValve.render(batch);

        chickenWhite.render(batch);
        chickenBrown.render(batch);

        buttons.render(batch);

        scoreText.render(batch, currentScore, highScore, level, combo);

        batch.end();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        batch.dispose();
        scoreText.dispose();
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
        Assets.singleton.sounds.playMusic(Assets.singleton.sounds.powerup);
        lastPowerupStartedTime = TimeUtils.nanoTime();
    }

    public boolean isPowerupActive() {
        return ((TimeUtils.nanoTime() - lastPowerupStartedTime) * MathUtils.nanoToSec) <= Constants.POWERUP_DURATION;
    }

    private void gotoLevel(int level) {
        this.level = level;
        combo = 0;
        eggs.clear();
        int caughtEggsGoal;
        if (level <= 6) {
            caughtEggsGoal = 12;
        } else if (level <= 12) {
            caughtEggsGoal = 24;
        } else if (level <= 18) {
            caughtEggsGoal = 36;
        } else if (level <= 24) {
            caughtEggsGoal = 48;
        } else {
            caughtEggsGoal = 60;
        }
        int startingEggs;
        if (level * Constants.BUCKET_GOAL_PER_LEVEL % 12 == 0) {
            startingEggs = 0;
        } else {
            startingEggs = 12 - (level * Constants.BUCKET_GOAL_PER_LEVEL % 12);
        }
        bucketLeft.reset(startingEggs, caughtEggsGoal);
        bucketMiddle.reset(startingEggs, caughtEggsGoal);
        bucketRight.reset(startingEggs, caughtEggsGoal);
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

    private void addNewEgg() {
        float elapsedSeconds = MathUtils.nanoToSec * (TimeUtils.nanoTime() - lastEggSpawnedTime);
        if (elapsedSeconds >= nextEggSpawnInterval) {
            //note that we are passing this class to the ball constructor so that balls can get and set powerup status
            eggs.add(new Egg(this));
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.newEgg);
            lastEggSpawnedTime = TimeUtils.nanoTime();
            double x = (double) level;
            //refer to google sheets spreadsheet for origin of these two ugly formulas (curve fit)
            double nextMinEggSpawnInterval = Math.max(-0.01d * Math.pow(x, 3.0d) + 0.291d * Math.pow(x, 2.0d) - 2.796d * x + 10.516d, Constants.EGG_SPAWN_INTERVAL_MIN);
            double nextMaxEggSpawnInterval = Math.max(8.849d * Math.pow(Math.E, (x * -0.094d)), Constants.EGG_SPAWN_INTERVAL_MIN);
            nextEggSpawnInterval = MathUtils.random((float) nextMinEggSpawnInterval, (float) nextMaxEggSpawnInterval);
        }
    }

    private void removeEggs(float delta) {
        eggs.begin();
        for (Egg egg : eggs) {
            //note that we need to pass the valves to each egg so that the eggs can check whether
            //it has arrived at a valve which is open
            egg.update(delta, leftValve, rightValve);
            if (egg.eggState == Enums.EggState.CAUGHT) {
                combo += 1;
                currentScore += combo;
                playComboSound();
                eggs.removeValue(egg, false);

                //increment eggcount on the bucket that matches the fellthru enum and play a sound if it's now full TODO refactor
                switch (egg.fellThru) {
                    case LEFT_VALVE:
                        bucketLeft.caughtEgg();
                        break;
                    case RIGHT_VALVE:
                        bucketMiddle.caughtEgg();
                        break;
                    case END:
                        bucketRight.caughtEgg();
                        break;
                }

                //if all three buckets are now full, start a new level
                if (bucketLeft.isFull() && bucketMiddle.isFull() && bucketRight.isFull()) {
                    gameState = Enums.GameState.GOTO_NEXT_LEVEL;
                }

            } else if (egg.eggState == Enums.EggState.MISSED) {
                Assets.singleton.sounds.playSound(Assets.singleton.sounds.missed);
                eggs.removeValue(egg, false);
                combo = 0;
                currentScore = Math.max(0, currentScore - 25);
                //if the players score is now zero, end the game
                if (currentScore == 0) gameState = Enums.GameState.GAME_OVER;

                //decrement ballcount on the bucket that matches the fellthru enum and end the game if it's below empty TODO refactor
                switch (egg.fellThru) {
                    case LEFT_VALVE:
                        if (bucketLeft.missedBall()) gameState = Enums.GameState.GAME_OVER;
                        break;
                    case RIGHT_VALVE:
                        if (bucketMiddle.missedBall()) gameState = Enums.GameState.GAME_OVER;
                        break;
                    case END:
                        if (bucketRight.missedBall()) gameState = Enums.GameState.GAME_OVER;
                        break;
                }

            }
        }
        eggs.end();
    }

    private void playComboSound() {
        if (combo >= Constants.SOUND_CAUGHT_COUNT) {
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.caught.get(Constants.SOUND_CAUGHT_COUNT - 1));
        } else {
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.caught.get(combo - 1));
        }
    }

}
