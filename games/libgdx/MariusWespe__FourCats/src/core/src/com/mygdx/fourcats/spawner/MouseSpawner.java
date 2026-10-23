package com.mygdx.fourcats.spawner;

import com.mygdx.fourcats.Config;
import com.mygdx.fourcats.events.MouseSpawnEvent;
import com.mygdx.fourcats.events.EventBroker;

import java.util.Random;

public class MouseSpawner
{
    Random random = new Random();

    int ticker = 0;

    int spawnOffset = 0;

    public void update()
    {
        trySpawnMouse();
        ticker++;
    }

    private void trySpawnMouse()
    {
        if (ticker<spawnOffset)
        {
            return;
        }

        int direction = random.nextInt(4);

        double spawnLocation = random.nextDouble(1.0);

        int sidespeed = 0;

        int speedX=0, speedY=0, posX=0, posY = 0;

        // heading right;
        if (direction == 0)
        {
            posX = 0;
            posY = (int) Math.round((Config.WORLD_SIZE_Y - Config.MOUSE_SIZE) * spawnLocation);
            speedX = Config.MOUSE_SPEED;
            speedY = sidespeed;

        }

        // heading lefts;
        if (direction == 1)
        {
            posX = Config.WORLD_SIZE_X - Config.MOUSE_SIZE - 1;
            posY = (int) Math.round((Config.WORLD_SIZE_Y - Config.MOUSE_SIZE) * spawnLocation);
            speedX = -Config.MOUSE_SPEED;
            speedY = sidespeed;
        }

        // heading upwards;
        if (direction == 2)
        {
            posX = (int) Math.round((Config.WORLD_SIZE_X - Config.MOUSE_SIZE) * spawnLocation);
            posY = 0;
            speedX = sidespeed;
            speedY = Config.MOUSE_SPEED;
        }

        // heading downwards;
        if (direction == 3)
        {
            posX = (int) Math.round((Config.WORLD_SIZE_X - Config.MOUSE_SIZE) * spawnLocation);
            posY = Config.WORLD_SIZE_Y - Config.MOUSE_SIZE -1;
            speedX = sidespeed;
            speedY = - Config.MOUSE_SPEED;
        }

        MouseSpawnEvent event = new MouseSpawnEvent();
        event.posX = posX;
        event.posY = posY;
        event.speedX = speedX;
        event.speedY = speedY;

        ticker = 0;

        EventBroker.getInstance().transmitMouseSpawn(event);
    }
}
