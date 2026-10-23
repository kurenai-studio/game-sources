package com.jgarivera.blitzbit.input.actions;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.math.Vector3;
import com.jgarivera.blitzbit.input.action.Action;
import com.jgarivera.blitzbit.world.World;
import com.jgarivera.blitzbit.world.npcs.entities.Minion;

public class SpawnMinion implements Action {

    public boolean enter(World world) {
        float x = Gdx.input.getX();
        float y = Gdx.input.getY();

        Vector3 mouseClickPosition = world.getCamera().unproject(new Vector3(x, y, 0));
        world.addEntity(new Minion(mouseClickPosition.x, mouseClickPosition.y));

        return true;
    }

    public boolean exit(World world) {
        return true;
    }
}
