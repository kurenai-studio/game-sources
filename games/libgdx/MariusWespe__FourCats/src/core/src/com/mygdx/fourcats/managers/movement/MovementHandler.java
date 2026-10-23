package com.mygdx.fourcats.managers.movement;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.CatName;
import com.mygdx.fourcats.Config;

public abstract class MovementHandler
{
    protected Animal animal;

    public MovementHandler(Animal animal)
    {
        this.animal = animal;
    }

    public static MovementHandler createHandlerForCat(Animal cat, CatName name)
    {
        switch (name)
        {
            case LENNY:
                return new LennyMovementHandler(cat);
            case CICCIO:
                return new CiccioMovementHandler(cat);
            case ARCHIE:
                return new ArchieMovementHandler(cat);
            default:
                return new MerlinMovementHandler(cat);
        }
    }

    public abstract void handleSpeed();

    public abstract ISpecialEffectTrigger getSpecialEffectTrigger();

    public final void updatePosition()
    {
        animal.x+= animal.speedX;
        animal.y+= animal.speedY;
    }

    protected final void doBaseSpeedHandling(int speed)
    {
        boolean headingRight = Gdx.input.isKeyPressed(Input.Keys.D);
        boolean headingLeft = Gdx.input.isKeyPressed(Input.Keys.A);
        boolean headingUpwards = Gdx.input.isKeyPressed(Input.Keys.W);
        boolean headingDownwards = Gdx.input.isKeyPressed(Input.Keys.S);

        animal.speedX = 0;
        animal.speedY = 0;

        if (headingRight && !headingLeft)
        {
            animal.speedX = speed;
        }

        if (headingLeft && !headingRight)
        {
            animal.speedX = -speed;
        }

        if (headingUpwards && !headingDownwards)
        {
            animal.speedY = speed;
        }

        if (headingDownwards && !headingUpwards)
        {
            animal.speedY = -speed;
        }
    }

    protected final boolean isBoundaryReached()
    {
        return animal.x <= 0
                || animal.x >= Config.WORLD_SIZE_X - Config.CAT_SIZE
                || animal.y <= 0
                || animal.y >= Config.WORLD_SIZE_Y - Config.CAT_SIZE;
    }

}
