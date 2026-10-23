package com.mygdx.fourcats.managers.movement;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.Config;

public class ArchieMovementHandler extends MovementHandler{

    private boolean isJumping;

    private final int jumpSpeed = Config.ARCHIE_JUMPING_SPEED;

    public ArchieMovementHandler(Animal animal) {
        super(animal);
        isJumping = false;
    }

    @Override
    public void handleSpeed()
    {
        if (isJumping)
        {
            if (isBoundaryReached())
            {
                isJumping = false;
                doBaseSpeedHandling(Config.CAT_SPEED);
                return;
            }
            else
            {
                return;
            }
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.SPACE))
        {
            double diffCenterToCatX = Config.WORLD_SIZE_X / 2d - (animal.x + Config.CAT_SIZE / 2d);
            double diffCenterToCatY = Config.WORLD_SIZE_Y / 2d - (animal.y + Config.CAT_SIZE / 2d);

            double diffCenterLength = Math.sqrt(diffCenterToCatX * diffCenterToCatX + diffCenterToCatY * diffCenterToCatY);

            animal.speedX = Math.toIntExact(Math.round(jumpSpeed * (diffCenterToCatX / diffCenterLength)));
            animal.speedY = Math.toIntExact(Math.round(jumpSpeed * (diffCenterToCatY / diffCenterLength)));
            isJumping = true;
            return;
        }

        doBaseSpeedHandling(Config.CAT_SPEED);
    }

    @Override
    public ISpecialEffectTrigger getSpecialEffectTrigger() {
        return new NullEffectTrigger();
    }
}
