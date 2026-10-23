package com.mygdx.fourcats.renderers.specialeffects;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.mygdx.fourcats.managers.movement.ISpecialEffectTrigger;

public class ChargedStateRenderer implements ISpecialEffectRenderer {

    private final ISpecialEffectTrigger trigger;
    private final ShapeRenderer shape;

    private int counter;

    public ChargedStateRenderer(ShapeRenderer shape, ISpecialEffectTrigger trigger)
    {
        this.shape = shape;
        this.trigger = trigger;
        counter = 0;
    }
    @Override
    public void renderSpecialEffect(int posX, int posY, int size) {
        {
            if (!trigger.triggerSpecialEffect())
            {
                counter = 0;
                return;
            }
            if (counter == 60)
            {
                counter = 0;
            }

            boolean showEffect = (counter / 15 == 0) || (counter / 15 == 2);

            if (showEffect)
            {
                shape.setColor(Color.YELLOW);
                shape.circle(posX + size/2, posY + size/2, size/2);
            }

            counter++;
        }
    }
}
