package com.jgarivera.blitzbit.world.view;

import com.badlogic.ashley.core.Entity;
import com.jgarivera.blitzbit.world.view.components.ViewComponentMapper;

import java.util.Comparator;

public class RenderOrderComparator implements Comparator<Entity> {

    @Override
    public int compare(Entity e1, Entity e2) {
        return ViewComponentMapper.RENDER_ORDER.get(e1).zIndex - ViewComponentMapper.RENDER_ORDER.get(e2).zIndex;
    }
}
