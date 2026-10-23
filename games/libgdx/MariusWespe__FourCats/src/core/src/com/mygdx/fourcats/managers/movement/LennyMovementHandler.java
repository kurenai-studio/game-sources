package com.mygdx.fourcats.managers.movement;

import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.Config;

import java.util.Random;

public class LennyMovementHandler extends MovementHandler
{
    int coolDownCounter;
    int berserkCounter;

    final int berserkSpeed = Config.LENNY_BERSERK_SPEED;

    final int MAXCOOLDOWN = Config.LENNY_MAX_COOLDOWN;
    final int MAXBERSERK = Config.LENNY_MAX_BERSERK;
    Random rnd;

    public LennyMovementHandler(Animal animal) {
        super(animal);
        rnd = new Random();
        coolDownCounter = MAXCOOLDOWN;
        berserkCounter = MAXBERSERK;
    }

    @Override
    public void handleSpeed()
    {
        if (coolDownCounter > 0)
        {
            coolDownCounter--;
            doBaseSpeedHandling(Config.CAT_SPEED);
            return;
        }

        doBaseSpeedHandling(berserkSpeed);
        berserkCounter--;
        if (berserkCounter == 0)
        {
            berserkCounter = rnd.nextInt(MAXBERSERK);
            coolDownCounter = rnd.nextInt(MAXCOOLDOWN);
        }
    }

    @Override
    public ISpecialEffectTrigger getSpecialEffectTrigger() {
        return new BerserkEffectTrigger();
    }

    private class BerserkEffectTrigger implements ISpecialEffectTrigger{
        @Override
        public boolean triggerSpecialEffect() {
            return (coolDownCounter == 0);
        }
    }
}
