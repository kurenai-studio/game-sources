package com.jgarivera.blitzbit.input.actions;

import com.jgarivera.blitzbit.input.action.Action;
import com.jgarivera.blitzbit.input.ToggleManager;
import com.jgarivera.blitzbit.world.World;

public class ToggleDebugMode implements Action {

    public boolean enter(World world) {
        ToggleManager toggleManager = world.getToggleManager();
        boolean isDebugMode = toggleManager.getToggle(ToggleManager.DEBUG_MODE);

        toggleManager.setToggle(ToggleManager.DEBUG_MODE, !isDebugMode);

        return true;
    }

    public boolean exit(World world) {
        return true;
    }
}
