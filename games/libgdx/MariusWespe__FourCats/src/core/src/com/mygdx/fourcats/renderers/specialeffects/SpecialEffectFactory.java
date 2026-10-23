package com.mygdx.fourcats.renderers.specialeffects;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.mygdx.fourcats.Animal;
import com.mygdx.fourcats.CatName;
import com.mygdx.fourcats.managers.movement.ISpecialEffectTrigger;

public class SpecialEffectFactory
{
    private static final SpecialEffectFactory instance = new SpecialEffectFactory();

    public static SpecialEffectFactory getInstance()
    {
        return instance;
    }

    public ISpecialEffectRenderer getSpecialEffectRendererByCatname(CatName name, ShapeRenderer shape,  ISpecialEffectTrigger trigger)
    {
        switch (name)
        {
            case LENNY:
                return new BerserkRenderer(shape, trigger);
            case CICCIO:
                return new ChargedStateRenderer(shape, trigger);
            default:
                return new NullEffectRenderer();
        }
    }
}
