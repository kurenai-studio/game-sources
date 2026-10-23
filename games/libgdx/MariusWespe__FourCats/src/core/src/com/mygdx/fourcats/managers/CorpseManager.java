package com.mygdx.fourcats.managers;

import com.mygdx.fourcats.events.IMouseCaughtEventListener;
import com.mygdx.fourcats.events.MouseCaughtEvent;
import com.mygdx.fourcats.renderers.CorpseRenderer;

import java.util.LinkedList;

public class CorpseManager implements IManager, IMouseCaughtEventListener
{
    Spatial2DData corpsePositions;

    LinkedList<Integer> spawnTimes;
    CorpseRenderer renderer;

    int ticker = 0;

    int DECAY_TIME = 300;

    int VANISHING_TIME = 600;



    public CorpseManager(CorpseRenderer renderer)
    {
        this.renderer = renderer;
        corpsePositions = new Spatial2DData();
        spawnTimes = new LinkedList<>();
    }

    @Override
    public void handleEvent(MouseCaughtEvent event)
    {
        corpsePositions.addMouse(event.posX, event.posY);
        spawnTimes.add(ticker);
    }

    @Override
    public void updateMovement()
    {
        while (spawnTimes.size()>0 && ticker - spawnTimes.getFirst() > VANISHING_TIME)
        {
            spawnTimes.remove(0);
            corpsePositions.removeMouseByIndex(0);
        }
        ticker++;
    }

    @Override
    public void renderObjects()
    {
        int firstUndecayedCorpseIndex = getFirstUndecayedIndex();
        renderer.drawCorpses(corpsePositions, firstUndecayedCorpseIndex);
    }

    @Override
    public void renderEffects() {
    }

    private int getFirstUndecayedIndex()
    {
        int index = Integer.MAX_VALUE;
        for (int i = 0; i < spawnTimes.size(); i++)
        {
            if (ticker - spawnTimes.get(i) < DECAY_TIME)
            {
                index = i;
                break;
            }
        }
        return index;
    }
}
