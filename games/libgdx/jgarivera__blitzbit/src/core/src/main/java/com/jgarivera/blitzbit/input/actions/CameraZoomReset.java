package com.jgarivera.blitzbit.input.actions;

import com.jgarivera.blitzbit.input.action.Action;
import com.jgarivera.blitzbit.world.World;

public class CameraZoomReset implements Action {

    @Override
    public boolean enter(World world) {
        world.getCamera().resetZoom();
        return true;
    }

    @Override
    public boolean exit(World world) {
        return true;
    }
}
