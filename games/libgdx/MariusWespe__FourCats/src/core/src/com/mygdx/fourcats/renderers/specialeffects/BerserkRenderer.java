package com.mygdx.fourcats.renderers.specialeffects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.mygdx.fourcats.managers.movement.ISpecialEffectTrigger;

public class BerserkRenderer implements ISpecialEffectRenderer {

    private final ISpecialEffectTrigger trigger;
    private final ShapeRenderer shape;

    private int radius = 0;

    private int counter;

    public BerserkRenderer(ShapeRenderer shape, ISpecialEffectTrigger trigger) {
        counter = 0;
        this.shape = shape;
        this.trigger = trigger;
    }

    @Override
    public void renderSpecialEffect(int posX, int posY, int size) {

        counter++;
        if (!trigger.triggerSpecialEffect())
        {
            counter = 0;
            return;
        }


        if (counter == 30)
        {
            counter = 0;
        }

        if (counter / 10 == 2)
        {
            return;
        }

        radius = size/2;
        float increment = size/(2*10f);

        if(counter < 10)
        {
            radius = Math.round(size/2 + counter * increment);
        }
        else {
            radius = Math.round(size / 2 + (20 - counter) * increment);
        }
        shape.setColor(Color.RED);
        shape.circle(posX + size/2, posY + size/2, radius);

    }
}
