package com.jgarivera.blitzbit.input.action;

import com.jgarivera.blitzbit.world.World;

public interface Action {
    boolean enter(World world);

    boolean exit(World world);
}
