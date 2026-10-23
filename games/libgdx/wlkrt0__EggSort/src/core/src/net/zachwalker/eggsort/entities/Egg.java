package net.zachwalker.eggsort.entities;


import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.TimeUtils;

import net.zachwalker.eggsort.EggSortScreen;
import net.zachwalker.eggsort.util.Assets;
import net.zachwalker.eggsort.util.Constants;
import net.zachwalker.eggsort.util.DrawingHelpers;
import net.zachwalker.eggsort.util.Enums;

public class Egg {

    private Enums.EggType eggType;
    public Enums.EggState eggState;
    public Enums.EggFellThru fellThru;
    private Vector2 position;
    private Vector2 velocity;
    private EggSortScreen eggSortScreen;
    private long createdTime;

    //note that we are passing the BallSortScreen class to the ball constructor so that balls can get and set powerup status
    public Egg(EggSortScreen eggSortScreen) {
        this.eggSortScreen = eggSortScreen;
        setEggType();
        //each new egg gets the same starting position with zero velocity and ballState = CHUTE
        position = new Vector2(Constants.EGG_SPAWN);
        velocity = new Vector2();
        eggState = Enums.EggState.CHUTE;
        createdTime = TimeUtils.nanoTime();
    }

    public void update(float delta, Valve leftValve, Valve rightValve) {
        switch (eggState) {
            case CHUTE:
                moveInChute(delta);
                break;
            case RAMP:
                moveOnRamp(delta, leftValve, rightValve);
                break;
            case FALLING:
                moveWhileFalling(delta);
                break;
        }
    }

    public void render(SpriteBatch batch) {
        float elapsedTime = DrawingHelpers.secondsSince(createdTime);
        switch(eggType) {
            case WHITE:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.eggWhite, position);
                break;
            case BROWN:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.eggBrown, position);
                break;
            case CHICK:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.eggChick, position);
                break;
            case POWERUP:
                DrawingHelpers.drawSprite(batch, Assets.singleton.images.eggPowerup.getKeyFrame(elapsedTime, true), position);
                break;
        }
    }

    /* each new ball gets a random type. regular balls are equal probability. powerup is rare. */
    private void setEggType() {
        float randomNumber = MathUtils.random();
        if (randomNumber < 0.01f) {
            eggType = Enums.EggType.POWERUP;
        } else if (randomNumber >= 0.01f && randomNumber < 0.34f) {
            eggType = Enums.EggType.WHITE;
        } else if (randomNumber >= 0.34f && randomNumber < 0.67f) {
            eggType = Enums.EggType.BROWN;
        } else {
            eggType = Enums.EggType.CHICK;
        }
    }

    private void moveInChute(float delta) {
        velocity.x = 0.0f;
        velocity.y = Constants.EGG_SPEED;
        position.mulAdd(velocity, delta);
        //start moving to the right if the ball has reached the top of the chute
        if (position.y > Constants.CHUTE_HEIGHT) {
            eggState = Enums.EggState.RAMP;
        }
    }

    private void moveOnRamp(float delta, Valve leftValve, Valve rightValve) {
        velocity.x = Constants.EGG_SPEED;
        velocity.y = 0.0f;
        position.mulAdd(velocity, delta);
        //automate the valves if a powerup is active
        if (eggSortScreen.isPowerupActive()) automateValves(leftValve, rightValve);
        //automateValves(leftValve, rightValve);
        //start falling if the ball is on top of an open valve or at the end of the ramp
        if (fellThroughGap(leftValve, rightValve)) {
            eggState = Enums.EggState.FALLING;
        }
    }

    private void moveWhileFalling(float delta) {
        velocity.x = 0.0f;
        velocity.y -= Constants.GRAVITY;
        position.mulAdd(velocity, delta);
        //flag the ball for removal by BallSortScreen if it's caught or missed
        //BallSortScreen handles any scoring that's needed
        if (position.y <= Constants.BUCKET_TOP) {
            if (inCorrectBucket()) {
                eggState = Enums.EggState.CAUGHT;
            } else {
                eggState = Enums.EggState.MISSED;
            }
        }
    }

    private boolean fellThroughGap(Valve leftValve, Valve rightValve) {
        //if it fell through the left valve
        if (overLeftValve() && leftValve.valveState == Enums.ValveState.OPEN) {
            fellThru = Enums.EggFellThru.LEFT_VALVE;
            return true;
        }
        //if it fell through the right valve
        else if (overRightValve() && rightValve.valveState == Enums.ValveState.OPEN) {
            fellThru = Enums.EggFellThru.RIGHT_VALVE;
            return true;
        }
        //if it fell off the end of the ramp
        else if (position.x > Constants.RAMP_END) {
            fellThru = Enums.EggFellThru.END;
            return true;
        }
        //if it hasn't fallen off of anything yet
        else {
            return false;
        }
    }

    private boolean overLeftValve() {
        return position.x > (Constants.VALVE_LEFT_POSITION.x + Constants.EGG_SIZE) &&
                position.x < (Constants.VALVE_LEFT_POSITION.x + Constants.VALVE_WIDTH);
    }

    private boolean overRightValve() {
        return position.x > (Constants.VALVE_RIGHT_POSITION.x + Constants.EGG_SIZE) &&
                position.x < (Constants.VALVE_RIGHT_POSITION.x + Constants.VALVE_WIDTH);
    }

    //TODO try to declare the match between left bucket and white egg type ONCE, globally
    private void automateValves(Valve leftValve, Valve rightValve) {
        //only switch valves if the ball is sitting on top of a valve AND the valve is in the wrong position
        if (overLeftValve()) {
            if (eggType.equals(Enums.EggType.WHITE)) {
                if (leftValve.valveState == Enums.ValveState.CLOSED) leftValve.switchValveState();
            } else {
                if (leftValve.valveState == Enums.ValveState.OPEN) leftValve.switchValveState();
            }
        } else if (overRightValve()) {
            if (eggType.equals(Enums.EggType.BROWN)) {
                if (rightValve.valveState == Enums.ValveState.CLOSED) rightValve.switchValveState();
            } else {
                if (rightValve.valveState == Enums.ValveState.OPEN) rightValve.switchValveState();
            }
        }
    }

    private boolean inCorrectBucket() {
        //powerups are always in the correct bucket
        if (eggType == Enums.EggType.POWERUP) {
            eggSortScreen.startPowerup();
            return true;
        } else {
            switch (fellThru) {
                case LEFT_VALVE:
                    return eggType.equals(Enums.EggType.WHITE);
                case RIGHT_VALVE:
                    return eggType.equals(Enums.EggType.BROWN);
                case END:
                    return eggType.equals(Enums.EggType.CHICK);
                default:
                    return false;
            }
        }
    }

}
