package com.mygdx.fourcats.managers;

import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.CatName;
import com.mygdx.fourcats.Config;
import com.mygdx.fourcats.Position;
import com.mygdx.fourcats.managers.movement.*;
import com.mygdx.fourcats.renderers.CatRenderer;
import com.mygdx.fourcats.renderers.specialeffects.ISpecialEffectRenderer;

public class CatManager implements IManager {

    private final CatRenderer renderer;

    private final ISpecialEffectRenderer specialEffects;

    private final MovementHandler movementHandler;

    public Animal Cat;

    private boolean isLeftFacing = true;

    public CatManager(Animal cat, CatName name, MovementHandler movementHandler,  CatRenderer Renderer, ISpecialEffectRenderer specialEffects) {
        Cat = cat;
        renderer = Renderer;
        this.specialEffects = specialEffects;
        this.movementHandler = movementHandler;
    }

    @Override
    public void updateMovement()
    {
        movementHandler.handleSpeed();

        movementHandler.updatePosition();

        sortOutFacedDirection();

        enforceBoundary();
    }

    public Position getCatPositon()
    {
        return new Position(Cat.x, Cat.y);
    }


    private void sortOutFacedDirection()
    {
        if (Cat.speedX != 0)
        {
            isLeftFacing = Cat.speedX <= 0;
        }
    }

    @Override
    public void renderObjects()
    {

        renderer.renderCat(Cat.x, Cat.y, Cat.size, isLeftFacing);
    }

    @Override
    public void renderEffects() {
        specialEffects.renderSpecialEffect(Cat.x, Cat.y, Cat.size);
    }

    private void enforceBoundary() {
        if (Cat.x < 0)
        {
            Cat.x = 0;
        }

        if (Cat.x > Config.WORLD_SIZE_X - Cat.size)
        {
            Cat.x= Config.WORLD_SIZE_X - Cat.size;
        }

        if (Cat.y < 0)
        {
            Cat.y = 0;
        }

        if (Cat.y > Config.WORLD_SIZE_Y - Cat.size)
        {

            Cat.y = Config.WORLD_SIZE_Y -  Cat.size;
        }
    }
}
