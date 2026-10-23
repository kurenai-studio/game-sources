package com.mygdx.fourcats.managers.movement;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.Config;

import static com.mygdx.fourcats.Config.*;

public class CiccioMovementHandler extends MovementHandler {
    private CiccioChargingState state;

    int chargingCounter;

    int jumpingCounter;

    final int chargingTime = CICCIO_CHARGING_TIME;

    final int jumpingTime = CICCIO_JUMPING_TIME;

    final int jumpSpeed = CICCIO_JUMP_SPEED;


    public CiccioMovementHandler(Animal animal) {
        super(animal);
        state = CiccioChargingState.REGULAR;
        chargingCounter = 0;
        jumpingCounter = jumpingTime;
    }

    @Override
    public void handleSpeed()
    {
        if (state == CiccioChargingState.REGULAR)
        {
            if (Gdx.input.isKeyPressed(Input.Keys.SPACE))
            {
                animal.speedX = 0;
                animal.speedY = 0;
                state = CiccioChargingState.CHARGING;
                return;
            }

            doBaseSpeedHandling(Config.CAT_SPEED);
            return;
        }

        if (state == CiccioChargingState.CHARGING)
        {
            if (chargingCounter >= chargingTime)
            {
                state = CiccioChargingState.CHARGED;
                return;
            }

            if (Gdx.input.isKeyPressed(Input.Keys.SPACE))
            {
                chargingCounter++;
                return;
            }

            state = CiccioChargingState.REGULAR;
        }

        if (state == CiccioChargingState.CHARGED)
        {
            if (Gdx.input.isKeyPressed(Input.Keys.SPACE))
            {
                return;
            }

            chargingCounter = 0;
            determineJump();
            jumpingCounter = jumpingTime;
            return;
        }

        if (state == CiccioChargingState.JUMPING)
        {
            if (isBoundaryReached())
            {
                state = CiccioChargingState.REGULAR;
                doBaseSpeedHandling(Config.CAT_SPEED);
                return;
            }

            if (jumpingCounter > 0)
            {
                jumpingCounter--;
                return;
            }

            state = CiccioChargingState.REGULAR;
            doBaseSpeedHandling(Config.CAT_SPEED);
        }
    }

    @Override
    public ISpecialEffectTrigger getSpecialEffectTrigger() {
        return new ChargedStateEffectTrigger();
    }

    private void determineJump()
    {
        if (noDirectionKeyPressed())
        {
            state = CiccioChargingState.REGULAR;
            jumpingCounter = jumpingTime;
            doBaseSpeedHandling(Config.CAT_SPEED);
        }

        state = CiccioChargingState.JUMPING;

        if (Gdx.input.isKeyPressed((Input.Keys.A)))
            {
                animal.speedX = - jumpSpeed;
            } else if (Gdx.input.isKeyPressed(Input.Keys.D))
            {
                animal.speedX = jumpSpeed;
            }

        if (Gdx.input.isKeyPressed((Input.Keys.W)))
        {
            animal.speedY = jumpSpeed;
        } else if (Gdx.input.isKeyPressed(Input.Keys.S))
        {
            animal.speedY = -jumpSpeed;
        }

    }

    private boolean noDirectionKeyPressed()
    {
        boolean noKeyPressed = !(isAPressed() || isSPressed() || isWPressed() || isDPressed());
        return noKeyPressed;
    }

    private boolean noVerticalKeyPressed()
    {
        boolean noKeyPressed = !(isSPressed() || isWPressed());
        return noKeyPressed;
    }

    private boolean noHorizontalKeyPressed()
    {
        boolean noKeyPressed = !(isAPressed() || isDPressed());
        return noKeyPressed;
    }


    private boolean isAPressed()
    {
        var isAPressed = Gdx.input.isKeyPressed(Input.Keys.A);
        return isAPressed;
    }

    private boolean isDPressed()
    {
        var isDPressed = Gdx.input.isKeyPressed(Input.Keys.D);
        return isDPressed;
    }

    private boolean isSPressed()
    {
        var isPressed = Gdx.input.isKeyPressed(Input.Keys.S);
        return isPressed;
    }
    private boolean isWPressed()
    {
        var isPressed = Gdx.input.isKeyPressed(Input.Keys.W);
        return isPressed;
    }

    private class ChargedStateEffectTrigger implements ISpecialEffectTrigger
    {
        @Override
        public boolean triggerSpecialEffect() {
            return state == CiccioChargingState.CHARGED;
        }
    }
}
