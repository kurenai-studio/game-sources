package com.jgarivera.blitzbit.world.player.listeners;

import com.jgarivera.blitzbit.input.action.Action;
import com.jgarivera.blitzbit.input.action.ActionListener;
import com.jgarivera.blitzbit.input.action.ActionType;
import com.jgarivera.blitzbit.world.World;

public class PlayerActionListener implements ActionListener {

    private final World world;

    public PlayerActionListener(World world) {
        this.world = world;
    }

    @Override
    public boolean onActionEntered(ActionType actionType) {
        Action action = actionType.getAction();

        if (action != null) {
            return action.enter(world);
        }

        return true;
    }

    @Override
    public boolean onActionExited(ActionType actionType) {
        Action action = actionType.getAction();

        if (action != null) {
            return action.exit(world);
        }

        return true;
    }
}
