package com.mygdx.fourcats.managers;

import com.mygdx.fourcats.Config;
import com.mygdx.fourcats.Position;
import com.mygdx.fourcats.events.IMouseCaughtEventListener;
import com.mygdx.fourcats.events.MouseCaughtEvent;
import com.mygdx.fourcats.events.MouseSpawnEvent;
import com.mygdx.fourcats.events.IMouseSpawnEventListener;
import com.mygdx.fourcats.renderers.MouseRenderer;


import java.util.ArrayList;
import java.util.List;

public class SimpleMouseManager implements
        IManager,
        IMouseSpawnEventListener,
        IMouseCaughtEventListener
{
    Spatial2DData mousePositions = new Spatial2DData();

    Spatial2DData mouseSpeeds = new Spatial2DData();

    private final MouseRenderer renderer;
    int spawnOffset;
    boolean canSpawn;

    public SimpleMouseManager(int spawnOffset, MouseRenderer renderer) {
        this.spawnOffset = spawnOffset;
        canSpawn = mousePositions.size() < Config.MAX_MICE;
        this.renderer = renderer;
    }

    @Override
    public void updateMovement()
    {
        despawnMice();
        moveMouse();
    }

    @Override
    public void renderObjects()
    {
        ArrayList<Boolean> isLeftFacing = checkLeftFacings();
        renderer.drawMice(mousePositions, isLeftFacing);
    }

    @Override
    public void renderEffects() {
    }

    private ArrayList<Boolean> checkLeftFacings()
    {
        int size = mousePositions.size();
        ArrayList<Boolean> result = new ArrayList<>(size);
        for (int i = 0; i < size; i++)
        {
            result.add(mouseSpeeds.getXByIndex(i) < 0);
        }
        return result;
    }

    @Override
    public void handleEvent(MouseSpawnEvent event)
    {
        if (canSpawn)
        {
            mousePositions.addMouse(event.posX, event.posY);
            mouseSpeeds.addMouse(event.speedX, event.speedY);
            canSpawn = mousePositions.size() < Config.MAX_MICE;
        }
    }

    @Override
    public void handleEvent(MouseCaughtEvent event)
    {
        mousePositions.removeMouseByIndex(event.mouseIndex);
        mouseSpeeds.removeMouseByIndex(event.mouseIndex);
    }

    public List<Position> getPositionList()
    {
        ArrayList<Position> result = new ArrayList<>();
        for (int i = 0; i < mousePositions.size(); i++)
        {
            result.add(new Position(mousePositions.getXByIndex(i), mousePositions.getYByIndex(i)));
        }

        return result;
    }

    private void despawnMice() {
        for (int i = 0; i< mousePositions.size(); i++) {
            if (isOutOfBoundary(i))
            {
                mousePositions.removeMouseByIndex(i);
                mouseSpeeds.removeMouseByIndex(i);
                i--;
            }
        }
        canSpawn = mousePositions.size() < Config.MAX_MICE;
    }

    private boolean isOutOfBoundary(int index)
    {
        if (mousePositions.getXByIndex(index)< -Config.MOUSE_SIZE)
        {
            return true;
        }

        if (mousePositions.getYByIndex(index) < -Config.MOUSE_SIZE)
        {
            return true;
        }

        if (mousePositions.getXByIndex(index) > Config.WORLD_SIZE_X - Config.MOUSE_SIZE)
        {
            return true;
        }

        return mousePositions.getYByIndex(index) > Config.WORLD_SIZE_Y - Config.MOUSE_SIZE;
    }

    private void moveMouse()
    {
        for (int i = 0; i < mousePositions.size(); i++)
        {
            mousePositions.setXByIndex(i, mousePositions.getXByIndex(i) + mouseSpeeds.getXByIndex(i));
            mousePositions.setYByIndex(i, mousePositions.getYByIndex(i) + mouseSpeeds.getYByIndex(i));
        }
    }
}
