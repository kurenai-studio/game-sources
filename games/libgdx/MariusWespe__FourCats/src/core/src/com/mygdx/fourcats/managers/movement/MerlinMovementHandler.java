package com.mygdx.fourcats.managers.movement;

import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.Config;

public class MerlinMovementHandler extends MovementHandler {

    public MerlinMovementHandler(Animal cat)
    {
        super(cat);
    }

    @Override
    public void handleSpeed()
    {
        doBaseSpeedHandling(Config.CAT_SPEED);
    }

    @Override
    public ISpecialEffectTrigger getSpecialEffectTrigger() {
        return new NullEffectTrigger();
    }
}
